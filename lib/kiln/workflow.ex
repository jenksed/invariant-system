defmodule Kiln.Workflow do
  @moduledoc """
  The single public application boundary for P1-S01 session operations.

  `Kiln.Workflow` composes the existing `Kiln.Domain.Session`,
  `Kiln.Domain.Action`, `Kiln.Domain.Transition`, `Kiln.Store.Journal.commit/4`,
  and `Kiln.Projections.Store.compare/2` modules without redefining domain or
  persistence semantics and without exposing their internals. CLI, TUI, ACP,
  and other clients call this module directly rather than reaching into
  domain or store modules.

  ## Public contract

    * `start_session/1` — atomic Session creation. Required: `:objective`,
      `:criteria` (≥1), `:actor_id`, `:project_observation`. Optional:
      `:constraints`, `:exclusions`, `:started_at` (caller-supplied values
      participate in the request digest; omitted values are auto-generated
      and excluded), `:idempotency_key`.

    * `query_session/1` — current projection for a `session_id`.

    * `cancel_session/2` — atomic cancellation. Required: `:actor_id`,
      `:expected_session_revision`. Permitted from `:ready` and `:running`
      Run states. Cancel from `:waiting_for_user` is not yet wired because
      the accepted projection invariant requires a `:waiting_for_user` Run
      to retain its pending decision until a paired clearing entry lands.

    * `resume_session/2` — atomic resumption. Required: `:actor_id`,
      `:expected_session_revision`. Permitted only from `:ready` in this
      slice; resume from `:waiting_for_user` and `:orphaned` is deferred
      to a future ticket. The journal records the resumption under the
      internal action kind `:transition_run`; the public operation is
      `:resume_session`.

    * `valid_next_actions/1` — bounded atoms naming the application-facing
      workflow operations currently permitted from the current Run state,
      deterministically ascending-sorted. `[]` is returned for an unknown
      or empty session and for terminal Run states.

    * `current_session/0` — single-Session resolution for clients that do
      not carry a `session_id`. Returns `{:ok, :empty}` when the journal
      holds no Session, the authoritative `{:ok, query_result()}` when
      exactly one Session exists, or `{:error, %Error{code: :multiple_sessions}}`
      when the journal holds more than one Session. The CLI, TUI, and
      other clients that operate against a single current Session use
      this function in place of a `query_session/1` call when no
      `session_id` is yet known.

  Every return is `{:ok, _}` or `{:error, %Kiln.Domain.Error{}}`. Mutating
  operations perform no journal write when validation or input checking
  fails. Return shapes carry only identifiers, revision, run state, and
  projection digest; the committed `Kiln.Domain.Action{}` envelope and the
  raw `%Kiln.Domain.Session{}` / `%Kiln.Domain.Run{}` / `%Kiln.Domain.Task{}`
  structs never appear in any return value.

  ## Capability authority

  `valid_next_actions/1` and the mutating operations share one capability
  matrix (`@capability_matrix/0`). Every advertised operation is executable
  from its advertised Run state; every unadvertised operation is rejected
  before any journal write. Terminal Run states advertise nothing. Internal
  journal action kinds (such as `:transition_run`) are never exposed.

  ## Idempotency

  Each mutating operation finds an existing commit by `idempotency_key`
  alone. A retry with the same key and the same request digest returns the
  original stable result without performing any additional journal write or
  action commit. A retry with the same key but a different request digest
  returns an `idempotency_conflict` error. The replay-boundary validator
  rebuilds the authoritative Session journal inside one `BEGIN IMMEDIATE`
  transaction before returning the stored application result, so a deleted
  or corrupt journal cannot masquerade as accepted recorded truth. The
  durable application result (session, task, run, action identifiers,
  revision, run state, projection digest) is stored with the action commit
  and replayed verbatim. The workflow's `commit/4` and `lookup_commit/3`
  paths share the same classifier, so a check/use race cannot interleave
  between the pre-lookup and the eventual write.

  ## Configuration

  Configuration enters through the registered `Kiln.Store.Connection`
  process. Domain and store modules remain configuration-free. `actor_id`
  is required explicitly and is never read from configuration.
  """

  alias Kiln.Domain.{Action, Error, Id, ProjectObservation, Session, Transition}
  alias Kiln.Journal.Replay
  alias Kiln.Projections.Session, as: SessionProjection
  alias Kiln.Projections.Store, as: ProjectionStore
  alias Kiln.Store.{Canonical, Journal}

  @type start_opts :: keyword() | map()

  @type start_result :: %{
          session_id: String.t(),
          task_id: String.t(),
          run_id: String.t(),
          action_id: String.t(),
          session_revision: non_neg_integer(),
          run_state: :ready,
          projection_digest: String.t()
        }

  @type cancel_result :: %{
          session_id: String.t(),
          action_id: String.t(),
          session_revision: non_neg_integer(),
          run_state: :canceled,
          projection_digest: String.t()
        }

  @type resume_result :: %{
          session_id: String.t(),
          action_id: String.t(),
          session_revision: non_neg_integer(),
          run_state: :running,
          projection_digest: String.t()
        }

  @type query_result :: %{
          projection: map(),
          source: :cache | :rebuilt,
          projection_digest: String.t(),
          journal_head_digest: String.t() | nil,
          orphaned: boolean(),
          session_id: String.t()
        }

  @request_digest_schema "kiln.workflow.request_digest/v1"
  @application_result_schema "kiln.workflow.application_result/v1"

  # Single capability authority for application-facing operations. Every
  # operation advertised here is the set the workflow accepts from the
  # corresponding Run state, and the set `valid_next_actions/1` returns.
  # `cancel_session` is permitted from `:ready` and `:running`; `resume_session`
  # is permitted from `:ready` only. `:waiting_for_user` is not in the cancel
  # set because the accepted projection invariant requires a `:waiting_for_user`
  # Run to retain its pending decision until a `user_decision_recorded/v1`
  # entry clears it; canceling a Session that still holds a pending decision
  # without a paired clearing entry would violate the invariant. Terminal
  # states advertise nothing. Internal journal action kinds such as
  # `:transition_run` are never exposed by this boundary.
  @capability_matrix %{
    ready: [:cancel_session, :resume_session],
    running: [:cancel_session]
  }

  @doc """
  Start a new durable Root Session.

  Accepts a keyword list or a map. Required: `:objective` (binary),
  `:criteria` (non-empty list of binaries), `:actor_id` (non-empty binary),
  `:project_observation` (a `%ProjectObservation{}` or a map with
  `:repository_root`, `:repository_fingerprint` (sha256:...), `:observed_at`).
  Optional: `:constraints`, `:exclusions` (default `[]`), `:started_at`
  (default `DateTime.utc_now/0`; a supplied value participates in the
  request digest while an auto-generated value is excluded), `:idempotency_key`
  (auto-generated when omitted).

  Returns the application-facing identifiers and the resulting revision,
  run state, and projection digest. Performs no journal write on any
  validation failure.
  """
  @spec start_session(start_opts()) :: {:ok, start_result()} | {:error, Error.t()}
  def start_session(opts) do
    with {:ok, normalized} <- normalize_start_opts(opts),
         {:ok, idempotency_key} <- resolve_idempotency_key(normalized),
         {:ok, request_digest} <- build_start_request_digest(normalized),
         {:ok, conn} <- store_conn() do
      run_start_commit(conn, normalized, idempotency_key, request_digest)
    end
  end

  @doc """
  Return the current projection for `session_id`.

  Returns `{:ok, %{projection, source, projection_digest}}` when the
  Session exists, `{:ok, :empty}` when no journal entries exist, or
  `{:error, %Error{}}` for expected malformed input or an invalid journal.
  """
  @spec query_session(term()) ::
          {:ok, query_result()} | {:ok, :empty} | {:error, Error.t()}
  def query_session(session_id) do
    with :ok <- require_session_id_format(session_id),
         {:ok, conn} <- store_conn() do
      load_projection(conn, session_id)
    end
  end

  @doc """
  Cancel a Root Session at `session_id`.

  Required options: `:actor_id` (non-empty binary) and
  `:expected_session_revision` (non-negative integer). Rejected when the
  current projection is missing, the revision is stale, the current Run
  state does not permit cancellation, or the journal does not validate.
  Performs no journal write on any validation failure.
  """
  @spec cancel_session(term(), keyword() | map()) ::
          {:ok, cancel_result()} | {:error, Error.t()}
  def cancel_session(session_id, opts) do
    run_transition(session_id, opts, public_relation: :cancel_session)
  end

  @doc """
  Resume a Root Session at `session_id` from an eligible Run state.

  Required options: `:actor_id` (non-empty binary) and
  `:expected_session_revision` (non-negative integer). Permitted only when
  the current Run state is `:ready` in this slice; resume from
  `:waiting_for_user` and `:orphaned` is deferred to a future ticket.
  Performs no journal write on any validation failure.
  """
  @spec resume_session(term(), keyword() | map()) ::
          {:ok, resume_result()} | {:error, Error.t()}
  def resume_session(session_id, opts) do
    run_transition(session_id, opts, public_relation: :resume_session)
  end

  @doc """
  Return the ascending-sorted list of bounded atoms currently permitted
  from the current Run state for `session_id`.

  The atoms name application-facing workflow operations owned by this
  boundary. Internal journal action kinds (such as `:transition_run`) are
  never exposed. The result is `[]` for an unknown session, an empty
  Session, or any terminal Run state.
  """
  @spec valid_next_actions(term()) :: {:ok, [atom()]} | {:error, Error.t()}
  def valid_next_actions(session_id) do
    with :ok <- require_session_id_format(session_id),
         {:ok, conn} <- store_conn() do
      case load_projection(conn, session_id) do
        {:ok, :empty} -> {:ok, []}
        {:ok, %{projection: projection}} -> {:ok, capability_for(projection)}
        {:error, _} = error -> error
      end
    end
  end

  @doc """
  Resolve the single current Session for clients that do not carry a
  `session_id`.

  Returns `{:ok, :empty}` when the journal holds no Session, the
  authoritative `{:ok, query_result()}` when exactly one Session exists,
  or `{:error, %Error{code: :multiple_sessions}}` when the journal holds
  more than one Session. A corrupt journal that fails to enumerate the
  Session list returns `{:error, %Error{code: :journal_invalid}}` and
  does not fall back to `query_session/1`.

  The first-month contract is exactly one Session. The CLI, TUI, and
  other single-Session clients use this entry point in place of a
  `query_session/1` call. Multi-Session clients must call
  `query_session/1` per Session.
  """
  @spec current_session() ::
          {:ok, :empty}
          | {:ok, query_result()}
          | {:error, Error.t()}
  def current_session() do
    with {:ok, conn} <- store_conn() do
      case Replay.sessions(conn) do
        [] ->
          {:ok, :empty}

        [session_id] ->
          load_projection(conn, session_id)

        session_ids ->
          {:error,
           Error.new(
             :multiple_sessions,
             "more than one Session exists; the foundation CLI supports exactly one",
             nil,
             %{count: length(session_ids), sessions: session_ids}
           )}
      end
    end
  end

  # ---- transition path (cancel + resume) ----

  defp run_transition(session_id, opts, public_relation: public_relation) do
    with :ok <- require_session_id_format(session_id),
         {:ok, normalized} <- normalize_transition_opts(opts),
         {:ok, idempotency_key} <- resolve_idempotency_key(normalized),
         {:ok, request_digest} <-
           build_transition_request_digest(public_relation, normalized, session_id),
         {:ok, conn} <- store_conn() do
      run_transition_commit(
        conn,
        session_id,
        normalized,
        idempotency_key,
        request_digest,
        public_relation
      )
    end
  end

  # ---- start commit orchestrator ----

  defp run_start_commit(conn, normalized, idempotency_key, request_digest) do
    # Pre-lookup by idempotency_key alone so a retry returns the stored
    # session_id, task_id, run_id, and action_id verbatim. The retry's
    # freshly generated identifiers must not become a second Session. The
    # journal's classifier rebuilds the authoritative Session journal
    # before returning success so a deleted or corrupt journal cannot
    # masquerade as accepted recorded truth.
    case Journal.classify_commit(conn, idempotency_key, request_digest) do
      :none ->
        start_session_build_and_commit(conn, normalized, idempotency_key, request_digest)

      {:replay, replay} ->
        apply_stored_start_result(atomize_replay(replay))

      {:conflict, error} ->
        {:error, classify_error(error)}

      {:error, %Kiln.Store.Error{} = error} ->
        {:error, store_error_to_domain(error)}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp start_session_build_and_commit(conn, normalized, idempotency_key, request_digest) do
    case Session.start(start_attrs(normalized)) do
      {:ok, %{session: session, task: task, run: run}} ->
        {:ok, action_id} = Id.generate(:action, strong_rand_bytes())

        result_map = build_start_result_map(session, task, run, action_id)

        case build_start_action(
               action_id,
               session,
               run,
               idempotency_key,
               request_digest,
               normalized
             ) do
          {:ok, action} ->
            entry = build_start_entry(session, task, run)

            commit(
              conn,
              action,
              [entry],
              result_map,
              &start_result_from_stored/1,
              expected_revision: 0,
              session_id: session.id
            )

          {:error, _} = error ->
            error
        end

      {:error, _} = error ->
        error
    end
  end

  # ---- transition commit orchestrator ----

  defp run_transition_commit(
         conn,
         session_id,
         normalized,
         idempotency_key,
         request_digest,
         public_relation
       ) do
    # Pre-lookup by idempotency_key alone so a retry replays without the
    # Run state transition check firing on the post-commit state. The
    # journal's classifier validates the stored boundary against the
    # authoritative journal before returning success, and `commit/4`
    # performs the same classification inside its `BEGIN IMMEDIATE`
    # transaction so a check/use race cannot interleave.
    case Journal.classify_commit(conn, idempotency_key, request_digest) do
      :none ->
        run_transition_validate_and_commit(
          conn,
          session_id,
          normalized,
          idempotency_key,
          request_digest,
          public_relation
        )

      {:replay, replay} ->
        apply_stored_transition_result(public_relation, atomize_replay(replay))

      {:conflict, error} ->
        {:error, classify_error(error)}

      {:error, %Kiln.Store.Error{} = error} ->
        {:error, store_error_to_domain(error)}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  defp run_transition_validate_and_commit(
         conn,
         session_id,
         normalized,
         idempotency_key,
         request_digest,
         public_relation
       ) do
    with {:ok, %{projection: projection}} <- load_projection(conn, session_id),
         :ok <- capability_authorize(public_relation, projection) do
      run_id = run_id_from_projection(projection)
      {:ok, action_id} = Id.generate(:action, strong_rand_bytes())
      from_state = run_state_from_projection(projection)

      case build_transition_action(
             action_id,
             session_id,
             run_id,
             normalized,
             idempotency_key,
             request_digest,
             public_relation,
             from_state
           ) do
        {:ok, action} ->
          target_state = target_state_for(public_relation)

          entry =
            build_run_transitioned_entry(
              from_state,
              target_state,
              reducer_step_for(public_relation)
            )

          placeholder = build_transition_placeholder(session_id, action.id, target_state)

          commit(
            conn,
            action,
            [entry],
            placeholder,
            &transition_result_from_stored(public_relation, &1),
            expected_revision: normalized.expected_session_revision,
            session_id: session_id
          )

        {:error, _} = error ->
          error
      end
    else
      {:error, _} = error ->
        error
    end
  end

  # ---- commit (handles replay vs new commit) ----

  # The journal commits the action atomically. If the classifier finds an
  # existing commit with the same request digest, the journal returns the
  # stored application result verbatim after rebuilding the authoritative
  # Session journal. If the digest differs, the journal returns an
  # idempotency conflict.
  defp commit(conn, action, entries, result_map, result_fun, opts) do
    expected_revision = Keyword.fetch!(opts, :expected_revision)
    session_id = Keyword.fetch!(opts, :session_id)

    case Journal.commit(
           conn,
           action,
           entries,
           now: now_iso(),
           result: result_map,
           result_schema: @application_result_schema
         ) do
      {:ok, %{status: :committed, session_revision: revision, projection: projection}} ->
        committed = committed_result(result_map, revision, projection)
        rebuild_digest = projection_digest_of(projection)

        fresh_boundary = fresh_action_boundary(action, revision, rebuild_digest)

        replay = %{
          session_id: action.session_id,
          action_id: action.id,
          result: committed,
          result_schema: @application_result_schema,
          boundary: fresh_boundary,
          rebuild_digest: rebuild_digest,
          # The fresh-commit path does not need an authority check against
          # the replay's target projection because the journal just wrote
          # the result with the freshly computed values; pass nil so the
          # validators skip the projection-based identity comparison.
          target_projection: nil
        }

        case result_fun.(replay) do
          {:ok, _} = ok -> ok
          {:error, %Error{} = error} -> {:error, error}
        end

      {:ok, %{status: :replayed, result: stored_result, session_id: stored_session_id} = replayed} ->
        # The journal already validated the stored boundary against the
        # authoritative journal; convert the stored result into the public
        # shape and re-validate semantic completeness so a corrupt stored
        # map cannot leak through the replay path. Use the stored
        # `session_id` so the retry's freshly generated candidate never
        # collides with the original Session under a concurrent retry race.
        # `boundary`, `rebuild_digest`, and `target_projection` are carried
        # by the journal's replay tuple and bind the stored result to its
        # exact action boundary inside the journal. `target_projection` is
        # the projection at the target action's commit point (not the
        # Session's current head) so identity fields (task_id, run_id)
        # can be authority-checked against the durable state at the time
        # of the stored action.
        replay = %{
          session_id: stored_session_id,
          action_id: action.id,
          result: string_keyed_to_atom(stored_result),
          result_schema: Map.get(replayed, :result_schema),
          boundary: Map.get(replayed, :boundary),
          rebuild_digest: Map.get(replayed, :rebuild_digest),
          target_projection: Map.get(replayed, :target_projection)
        }

        case result_fun.(replay) do
          {:ok, _} = ok -> ok
          {:error, %Error{} = error} -> {:error, error}
        end

      {:error, %Kiln.Store.Error{code: code, message: message, details: details}} ->
        {:error, Error.new(code, message, nil, details)}

      {:error, %Error{} = error} ->
        {:error, error}

      {:error, reason} ->
        {:error,
         Error.new(
           :transaction_failed,
           "the append transaction did not commit",
           nil,
           %{reason: inspect(reason)}
         )}

      _ ->
        {:error,
         Error.new(
           :transaction_failed,
           "the append transaction returned an unrecognized outcome",
           nil,
           %{
             expected_revision: expected_revision,
             session_id: session_id
           }
         )}
    end
  end

  defp classify_error(%Kiln.Store.Error{} = error), do: store_error_to_domain(error)
  defp classify_error(%Error{} = error), do: error

  defp store_error_to_domain(%Kiln.Store.Error{code: code, message: message, details: details}) do
    Error.new(code, message, nil, details)
  end

  # ---- capability authority ----

  # The single source of truth for what this boundary exposes from each
  # Run state. `valid_next_actions/1` lists the advertised set; every
  # mutator (cancel/resume) checks `capability_authorize/2` against the
  # same matrix before any journal write.
  defp capability_for(projection) do
    case run_state_from_projection(projection) do
      nil -> []
      state -> capability_for_state(state)
    end
  end

  defp capability_for_state(state) do
    case Map.fetch(@capability_matrix, state) do
      {:ok, actions} -> Enum.sort(actions)
      :error -> []
    end
  end

  defp capability_authorize(public_relation, projection) do
    case run_state_from_projection(projection) do
      nil ->
        {:error, Error.new(:unknown_run_state, "current Run state is not recognized", :run_state)}

      state ->
        if public_relation in Map.get(@capability_matrix, state, []) do
          case Transition.validate_run(state, target_state_for(public_relation)) do
            :ok -> :ok
            {:error, %Error{} = error} -> {:error, transition_domain_error(state, error)}
          end
        else
          {:error,
           Error.new(
             :run_transition_not_allowed,
             "the current Run state does not permit this operation",
             nil,
             %{
               from: Atom.to_string(state),
               operation: Atom.to_string(public_relation),
               permitted_operations: capability_for_state(state)
             }
           )}
        end
    end
  end

  defp transition_domain_error(state, %Error{} = inner) do
    Error.new(
      :run_transition_not_allowed,
      "the Run transition is not in the accepted transition table",
      nil,
      %{from: Atom.to_string(state), inner: inner.code}
    )
  end

  defp target_state_for(:cancel_session), do: :canceled
  defp target_state_for(:resume_session), do: :running

  defp reducer_step_for(:cancel_session), do: "intent"
  defp reducer_step_for(:resume_session), do: "application"

  # ---- input normalization ----

  defp normalize_start_opts(opts) when is_list(opts) do
    opts
    |> Map.new()
    |> normalize_start_opts()
  end

  defp normalize_start_opts(opts) when is_map(opts) do
    with {:ok, actor_id} <- require_actor_id_map(opts),
         {:ok, objective} <- require_nonempty_string_map(opts, :objective, :objective),
         {:ok, criteria} <- require_string_list_map(opts, :criteria, :criteria, minimum: 1),
         {:ok, constraints} <- optional_string_list_map(opts, :constraints, :constraints),
         {:ok, exclusions} <- optional_string_list_map(opts, :exclusions, :exclusions),
         {:ok, started_at, started_at_source} <- require_started_at_map(opts),
         {:ok, project_observation, observation_id_source} <-
           resolve_project_observation_map(opts),
         {:ok, idempotency_key_input} <- optional_idempotency_key_map(opts) do
      {:ok,
       %{
         actor_id: actor_id,
         objective: objective,
         criteria: criteria,
         constraints: constraints,
         exclusions: exclusions,
         started_at: started_at,
         started_at_source: started_at_source,
         project_observation: project_observation,
         observation_id_source: observation_id_source,
         idempotency_key: idempotency_key_input
       }}
    end
  end

  defp normalize_start_opts(_opts),
    do: {:error, Error.new(:invalid_input, "start input must be a keyword list or a map")}

  defp normalize_transition_opts(opts) when is_list(opts) do
    opts
    |> Map.new()
    |> normalize_transition_opts()
  end

  defp normalize_transition_opts(opts) when is_map(opts) do
    with {:ok, actor_id} <- require_actor_id_map(opts),
         {:ok, expected_session_revision} <- require_expected_revision_map(opts),
         {:ok, idempotency_key_input} <- optional_idempotency_key_map(opts) do
      {:ok,
       %{
         actor_id: actor_id,
         expected_session_revision: expected_session_revision,
         idempotency_key: idempotency_key_input
       }}
    end
  end

  defp normalize_transition_opts(_opts),
    do: {:error, Error.new(:invalid_input, "options must be a keyword list or a map")}

  # ---- input validation helpers ----

  defp require_actor_id_map(opts) do
    case fetch_field(opts, :actor_id) do
      {:ok, value} when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, missing_actor_id_error()}
        else
          {:ok, value}
        end

      _ ->
        {:error, missing_actor_id_error()}
    end
  end

  defp require_nonempty_string_map(opts, field, code) do
    case fetch_field(opts, field) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _ ->
        {:error, Error.new(code, "field must be a non-empty string", field)}
    end
  end

  defp require_string_list_map(opts, field, code, minimum: minimum) do
    case Map.fetch(opts, field) do
      {:ok, value} when is_list(value) and length(value) >= minimum ->
        if Enum.all?(value, &(is_binary(&1) and byte_size(&1) > 0)) do
          {:ok, value}
        else
          {:error, Error.new(code, "field must be a list of non-empty strings", field)}
        end

      _ ->
        {:error, Error.new(code, "field must be a list of non-empty strings", field)}
    end
  end

  defp optional_string_list_map(opts, field, code) do
    case Map.fetch(opts, field) do
      {:ok, value} when is_list(value) ->
        if Enum.all?(value, &(is_binary(&1) and byte_size(&1) > 0)) do
          {:ok, value}
        else
          {:error, Error.new(code, "field must be a list of non-empty strings", field)}
        end

      :error ->
        {:ok, []}

      {:ok, _} ->
        {:error, Error.new(code, "field must be a list of non-empty strings", field)}
    end
  end

  # Returns `{:ok, datetime, :caller | :generated}`. The `:caller` vs
  # `:generated` distinction is preserved so the request digest can include
  # a caller-supplied timestamp and exclude an auto-generated one without
  # the caller having to introspect the value.
  defp require_started_at_map(opts) do
    case Map.fetch(opts, :started_at) do
      {:ok, %DateTime{} = value} ->
        {:ok, value, :caller}

      {:ok, _} ->
        {:error, Error.new(:invalid_started_at, "started_at must be a DateTime", :started_at)}

      :error ->
        {:ok, DateTime.utc_now(), :generated}
    end
  end

  defp require_expected_revision_map(opts) do
    case fetch_field(opts, :expected_session_revision) do
      {:ok, value} when is_integer(value) and value >= 0 ->
        {:ok, value}

      _ ->
        {:error,
         Error.new(
           :invalid_expected_session_revision,
           "expected_session_revision is required and must be a non-negative integer",
           :expected_session_revision
         )}
    end
  end

  # Caller-supplied `%ProjectObservation{}` structs carry an explicit `id`
  # that becomes the durable `project_observation_id` referenced by the
  # Session journal; two distinct caller ids therefore represent distinct
  # durable observations and must produce distinct request digests. Map
  # inputs (or omitted maps inside the struct) have their id generated
  # internally by `ProjectObservation.new/1`; that generated id participates
  # only as a one-shot value for this request and is excluded from the
  # digest so two identical map inputs replay idempotently.
  defp resolve_project_observation_map(opts) do
    case Map.fetch(opts, :project_observation) do
      {:ok, %ProjectObservation{} = value} ->
        {:ok, value, :caller}

      {:ok, attrs} when is_map(attrs) ->
        case ProjectObservation.new(attrs) do
          {:ok, observation} -> {:ok, observation, :generated}
          {:error, _} = error -> error
        end

      :error ->
        {:error,
         Error.new(
           :missing_project_observation,
           "project_observation is required (pass a %ProjectObservation{} or a map with :repository_root, :repository_fingerprint, :observed_at)",
           :project_observation
         )}

      {:ok, _} ->
        {:error,
         Error.new(
           :invalid_project_observation,
           "project_observation must be a ProjectObservation struct or a map",
           :project_observation
         )}
    end
  end

  defp optional_idempotency_key_map(opts) do
    case fetch_field(opts, :idempotency_key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 ->
        case Id.validate(:idempotency, value) do
          :ok -> {:ok, value}
          {:error, _} = error -> error
        end

      {:ok, _} ->
        {:error,
         Error.new(
           :invalid_idempotency_key,
           "idempotency_key must be a non-empty string",
           :idempotency_key
         )}

      :error ->
        {:ok, :auto}
    end
  end

  defp fetch_field(opts, key) when is_map(opts) do
    if Map.has_key?(opts, key) do
      {:ok, Map.get(opts, key)}
    else
      :error
    end
  end

  defp require_session_id_format(value) when is_binary(value) do
    if Id.valid?(:session, value) do
      :ok
    else
      invalid_session_id_error()
    end
  end

  defp require_session_id_format(_value), do: invalid_session_id_error()

  defp invalid_session_id_error do
    {:error,
     Error.new(
       :invalid_session_id,
       "session_id must be a session identifier",
       :session_id
     )}
  end

  defp missing_actor_id_error do
    Error.new(
      :missing_actor_id,
      "actor_id is required and must be a non-blank binary",
      :actor_id,
      %{atom: :actor_id}
    )
  end

  # ---- idempotency key resolution ----

  defp resolve_idempotency_key(%{idempotency_key: :auto}) do
    Id.generate(:idempotency, strong_rand_bytes())
  end

  defp resolve_idempotency_key(%{idempotency_key: value}) when is_binary(value) do
    {:ok, value}
  end

  # ---- request digest ----

  # Caller-supplied timestamps participate in the digest; auto-generated
  # timestamps do not, because every auto-generation produces a different
  # value and would defeat idempotency for retries that omit the field.
  defp build_start_request_digest(normalized) do
    attrs = %{
      "operation" => "start_session",
      "actor_id" => normalized.actor_id,
      "objective" => normalized.objective,
      "criteria" => normalized.criteria,
      "constraints" => normalized.constraints,
      "exclusions" => normalized.exclusions,
      "started_at_source" => Atom.to_string(normalized.started_at_source),
      "started_at" => started_at_digest_value(normalized),
      "project_observation" =>
        project_observation_digest_data(
          normalized.project_observation,
          normalized.observation_id_source
        )
    }

    encode_request_digest(attrs)
  end

  defp started_at_digest_value(%{started_at_source: :caller, started_at: value}),
    do: DateTime.to_iso8601(value)

  defp started_at_digest_value(%{started_at_source: :generated}), do: nil

  defp build_transition_request_digest(:cancel_session, normalized, session_id) do
    encode_request_digest(%{
      "operation" => "cancel_session",
      "session_id" => session_id,
      "actor_id" => normalized.actor_id,
      "expected_session_revision" => normalized.expected_session_revision
    })
  end

  defp build_transition_request_digest(:resume_session, normalized, session_id) do
    encode_request_digest(%{
      "operation" => "resume_session",
      "session_id" => session_id,
      "actor_id" => normalized.actor_id,
      "expected_session_revision" => normalized.expected_session_revision
    })
  end

  defp encode_request_digest(attrs) do
    payload = Canonical.encode(attrs)
    raw = :crypto.hash(:sha256, [@request_digest_schema, "\n", payload])
    {:ok, "sha256:" <> Base.encode16(raw, case: :lower)}
  end

  # When the caller supplied a `%ProjectObservation{}` directly, its `id` is
  # the durable `project_observation_id` referenced by the Session journal;
  # two distinct ids therefore represent distinct durable observations and
  # must produce distinct digests so a retry cannot replay the wrong session.
  # When the observation was constructed from a map, `id` was generated
  # internally and is excluded so two identical map inputs replay
  # idempotently.
  defp project_observation_digest_data(%ProjectObservation{} = po, :caller) do
    %{
      "id" => po.id,
      "repository_root" => po.repository_root,
      "repository_fingerprint" => po.repository_fingerprint,
      "observed_at" => DateTime.to_iso8601(po.observed_at)
    }
  end

  defp project_observation_digest_data(%ProjectObservation{} = po, :generated) do
    %{
      "repository_root" => po.repository_root,
      "repository_fingerprint" => po.repository_fingerprint,
      "observed_at" => DateTime.to_iso8601(po.observed_at)
    }
  end

  # ---- domain construction ----

  defp start_attrs(normalized) do
    %{
      project_observation: normalized.project_observation,
      objective: normalized.objective,
      criteria: normalized.criteria,
      constraints: normalized.constraints,
      exclusions: normalized.exclusions,
      started_at: normalized.started_at
    }
  end

  defp build_start_action(action_id, session, run, idempotency_key, request_digest, normalized) do
    Action.new(%{
      id: action_id,
      session_id: session.id,
      run_id: run.id,
      expected_session_revision: 0,
      idempotency_key: idempotency_key,
      actor_kind: :local_user,
      actor_id: normalized.actor_id,
      kind: :start_session,
      request_digest: request_digest,
      payload: %{
        objective: normalized.objective,
        criteria: normalized.criteria
      },
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: normalized.started_at
    })
  end

  defp build_transition_action(
         action_id,
         session_id,
         run_id,
         normalized,
         idempotency_key,
         request_digest,
         public_relation,
         from_state
       ) do
    Action.new(%{
      id: action_id,
      session_id: session_id,
      run_id: run_id,
      expected_session_revision: normalized.expected_session_revision,
      idempotency_key: idempotency_key,
      actor_kind: :local_user,
      actor_id: normalized.actor_id,
      kind: :transition_run,
      request_digest: request_digest,
      payload: %{
        public_relation: Atom.to_string(public_relation),
        from_state: Atom.to_string(from_state),
        to_state: Atom.to_string(target_state_for(public_relation))
      },
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: DateTime.utc_now()
    })
  end

  # ---- result construction ----

  defp build_start_result_map(session, task, run, action_id) do
    %{
      session_id: session.id,
      task_id: task.id,
      run_id: run.id,
      action_id: action_id,
      session_revision: 0,
      run_state: "ready",
      projection_digest: nil
    }
  end

  defp build_transition_placeholder(session_id, action_id, target_state) do
    %{
      session_id: session_id,
      action_id: action_id,
      session_revision: 0,
      run_state: Atom.to_string(target_state),
      projection_digest: nil
    }
  end

  defp committed_result(placeholder, actual_revision, projection) do
    placeholder
    |> Map.put(:session_revision, actual_revision)
    |> Map.put(:projection_digest, projection_digest_of(projection))
  end

  defp projection_digest_of(projection) when is_map(projection) do
    SessionProjection.digest(projection)
  end

  # Convert a string-keyed decoded stored result into the atom-keyed shape
  # the public contract uses. Task and run IDs are present only in start
  # results; for transition results JSON omits them and the atom-keyed map
  # carries nil. The validators below treat `nil` as a missing field for
  # start results and ignore it for transition results.
  defp string_keyed_to_atom(result) when is_map(result) do
    %{
      session_id: result["session_id"],
      task_id: result["task_id"],
      run_id: result["run_id"],
      action_id: result["action_id"],
      session_revision: result["session_revision"],
      run_state: result["run_state"],
      projection_digest: result["projection_digest"]
    }
  end

  defp atomize_replay(replay) do
    %{replay | result: string_keyed_to_atom(replay.result)}
  end

  defp apply_stored_start_result(replay) do
    start_result_from_stored(replay)
  end

  defp apply_stored_transition_result(public_relation, replay) do
    transition_result_from_stored(public_relation, replay)
  end

  # The stored application result is the cached answer, but the rebuild is
  # the source of truth. The validators below prove that every identifier,
  # the revision, the projection digest, and the schema in the stored result
  # all match the authoritative rebuild produced by `Journal.replay/2`.
  # A stored result that passes its own digest check but disagrees with the
  # rebuild is a boundary violation and must never be returned as `{:ok, _}`.
  defp validate_stored_start_result(replay) do
    result = replay.result
    boundary = replay.boundary
    rebuild_digest = replay.rebuild_digest
    target_projection = replay.target_projection
    expected_schema = @application_result_schema

    with :ok <- require_application_result_schema(replay.result_schema, expected_schema),
         :ok <- require_valid_session_id(result.session_id),
         :ok <- require_valid_task_id(result.task_id),
         :ok <- require_valid_run_id(result.run_id),
         :ok <- require_valid_action_id(result.action_id),
         :ok <- require_non_neg_integer(result, :session_revision),
         :ok <- require_run_state(result, "ready"),
         :ok <- require_projection_digest(result),
         :ok <- require_action_boundary(replay.session_id, result.action_id, boundary),
         :ok <- require_revision_matches_boundary(result.session_revision, boundary),
         :ok <- require_digest_matches_rebuild(result.projection_digest, rebuild_digest),
         :ok <- require_task_id_matches_boundary(result.task_id, target_projection),
         :ok <- require_run_id_matches_boundary(result.run_id, target_projection) do
      require_stored_session_matches_id(replay.session_id, result.session_id)
    end
  end

  # Same as `validate_stored_start_result/1` minus the identity validators
  # that the transition result map never carries. The replay-boundary
  # authority check on the stored action_id, revision, digest, and schema
  # still applies, but task_id/run_id are not in the transition result.
  defp validate_stored_transition_result(public_relation, replay) do
    result = replay.result
    boundary = replay.boundary
    rebuild_digest = replay.rebuild_digest
    expected_schema = @application_result_schema

    with :ok <- require_application_result_schema(replay.result_schema, expected_schema),
         :ok <- require_valid_session_id(result.session_id),
         :ok <- require_valid_action_id(result.action_id),
         :ok <- require_non_neg_integer(result, :session_revision),
         :ok <- require_run_state(result, Atom.to_string(target_state_for(public_relation))),
         :ok <- require_projection_digest(result),
         :ok <- require_action_boundary(replay.session_id, result.action_id, boundary),
         :ok <- require_revision_matches_boundary(result.session_revision, boundary),
         :ok <- require_digest_matches_rebuild(result.projection_digest, rebuild_digest) do
      require_stored_session_matches_id(replay.session_id, result.session_id)
    end
  end

  defp require_valid_session_id(value) do
    if Id.valid?(:session, value) do
      :ok
    else
      corrupt_result_error("stored result session_id is not a valid session identifier", %{
        field: :session_id
      })
    end
  end

  defp require_valid_task_id(value) do
    if Id.valid?(:task, value) do
      :ok
    else
      corrupt_result_error("stored result task_id is not a valid task identifier", %{
        field: :task_id
      })
    end
  end

  defp require_valid_run_id(value) do
    if Id.valid?(:run, value) do
      :ok
    else
      corrupt_result_error("stored result run_id is not a valid run identifier", %{
        field: :run_id
      })
    end
  end

  defp require_valid_action_id(value) do
    if Id.valid?(:action, value) do
      :ok
    else
      corrupt_result_error("stored result action_id is not a valid action identifier", %{
        field: :action_id
      })
    end
  end

  # The stored result must carry the same result_schema the workflow writes.
  # An attacker (or a buggy migration) that re-encodes the result under a
  # different schema could otherwise produce a result the workflow refuses to
  # decode, but one that still digest-matches under its own scheme.
  defp require_application_result_schema(actual, expected) do
    if actual == expected do
      :ok
    else
      corrupt_result_error(
        "stored result_schema is not the workflow application-result schema",
        %{
          reason: :corrupt_result_schema,
          expected: expected,
          actual: actual
        }
      )
    end
  end

  # The stored action_id must match the action boundary the journal rebuild
  # produced for the stored session_id. A stored result that agrees with its
  # own digest but disagrees with the authoritative action boundary is a
  # tampering signal and must not be returned as a success.
  defp require_action_boundary(session_id, stored_action_id, boundary) do
    cond do
      is_nil(boundary) ->
        corrupt_result_error(
          "stored session has no authoritative action boundary",
          %{reason: :corrupt_result_boundary, session_id: session_id}
        )

      stored_action_id != boundary.action_id ->
        corrupt_result_error(
          "stored result action_id disagrees with the authoritative action boundary",
          %{
            reason: :corrupt_result_boundary,
            stored_action_id: stored_action_id,
            boundary_action_id: boundary.action_id
          }
        )

      true ->
        :ok
    end
  end

  # The stored session_revision must equal the revision at the action
  # boundary the rebuild produced. A revision that disagrees with the rebuild
  # is a tampering signal even when the stored digest matches.
  defp require_revision_matches_boundary(stored_revision, boundary) do
    cond do
      is_nil(boundary) ->
        corrupt_result_error(
          "stored session has no authoritative action boundary",
          %{reason: :corrupt_result_boundary}
        )

      stored_revision != boundary.last_revision ->
        corrupt_result_error(
          "stored result session_revision disagrees with the authoritative action boundary",
          %{
            reason: :corrupt_result_boundary,
            stored_session_revision: stored_revision,
            boundary_last_revision: boundary.last_revision
          }
        )

      true ->
        :ok
    end
  end

  # The stored projection_digest must equal the digest the journal rebuild
  # produced at the same action boundary. A stored digest that disagrees with
  # the authoritative rebuild is a tampering signal.
  defp require_digest_matches_rebuild(stored_digest, rebuild_digest) do
    cond do
      is_nil(rebuild_digest) ->
        corrupt_result_error(
          "no authoritative rebuild digest is available",
          %{reason: :corrupt_result_boundary}
        )

      stored_digest != rebuild_digest ->
        corrupt_result_error(
          "stored result projection_digest disagrees with the authoritative rebuild digest",
          %{
            reason: :corrupt_result_boundary,
            stored_projection_digest: stored_digest,
            rebuild_digest: rebuild_digest
          }
        )

      true ->
        :ok
    end
  end

  # The stored task_id must equal the task id the rebuild produced at the
  # target action boundary. Format-only validation (require_valid_task_id)
  # accepts any well-formed Kiln identifier; this check binds the value to
  # the authoritative projection so a stored result containing the correct
  # action_id, revision, and digest but a different validly-formatted task_id
  # is still rejected. The fresh-commit path passes nil because the journal
  # already wrote the result with the freshly computed values; skip the
  # projection lookup in that case.
  defp require_task_id_matches_boundary(_stored_task_id, nil), do: :ok

  defp require_task_id_matches_boundary(stored_task_id, target_projection) do
    authoritative_task_id = authoritative_id(target_projection, ["task", "id"])

    cond do
      is_nil(authoritative_task_id) ->
        corrupt_result_error(
          "no authoritative task_id is available at the target action boundary",
          %{reason: :corrupt_result_boundary, field: :task_id}
        )

      stored_task_id != authoritative_task_id ->
        corrupt_result_error(
          "stored result task_id disagrees with the authoritative task_id at the target action boundary",
          %{
            reason: :corrupt_result_boundary,
            field: :task_id,
            stored_task_id: stored_task_id,
            authoritative_task_id: authoritative_task_id
          }
        )

      true ->
        :ok
    end
  end

  # The stored run_id must equal the run id the rebuild produced at the
  # target action boundary. Format-only validation (require_valid_run_id)
  # accepts any well-formed Kiln identifier; this check binds the value to
  # the authoritative projection so a stored result containing the correct
  # action_id, revision, and digest but a different validly-formatted run_id
  # is still rejected. The fresh-commit path passes nil because the journal
  # already wrote the result with the freshly computed values; skip the
  # projection lookup in that case.
  defp require_run_id_matches_boundary(_stored_run_id, nil), do: :ok

  defp require_run_id_matches_boundary(stored_run_id, target_projection) do
    authoritative_run_id = authoritative_id(target_projection, ["run", "id"])

    cond do
      is_nil(authoritative_run_id) ->
        corrupt_result_error(
          "no authoritative run_id is available at the target action boundary",
          %{reason: :corrupt_result_boundary, field: :run_id}
        )

      stored_run_id != authoritative_run_id ->
        corrupt_result_error(
          "stored result run_id disagrees with the authoritative run_id at the target action boundary",
          %{
            reason: :corrupt_result_boundary,
            field: :run_id,
            stored_run_id: stored_run_id,
            authoritative_run_id: authoritative_run_id
          }
        )

      true ->
        :ok
    end
  end

  # Walk the projection map by string key path to extract the authoritative
  # identity at the target action's commit point. Returns `nil` when the
  # path is absent or any intermediate value is not a map.
  defp authoritative_id(projection, path) when is_map(projection) do
    Enum.reduce_while(path, projection, fn key, acc ->
      case is_map(acc) and Map.get(acc, key) do
        nil -> {:halt, nil}
        value -> {:cont, value}
      end
    end)
    |> case do
      value when is_binary(value) -> value
      _ -> nil
    end
  end

  defp corrupt_result_error(message, detail) do
    {:error, Error.new(:corrupt_result, message, nil, Map.put(detail, :reason, :corrupt_result))}
  end

  # The fresh-commit path has not yet passed through `Replay.rebuild`, but the
  # journal has just stamped the freshly computed projection into
  # `session_projections` and the rebuilt digest is the digest of that very
  # projection. Construct a synthetic boundary that matches what the journal
  # would have produced if the classifier had looked the row up after the
  # commit. `last_revision` is the just-committed session revision; the
  # remaining fields mirror the columns `action_commits` just wrote, so the
  # binding validators see the same authoritative values the replay path
  # would have produced.
  defp fresh_action_boundary(action, last_revision, _projection_digest) do
    %{
      action_id: action.id,
      idempotency_key: action.idempotency_key,
      request_digest: action.request_digest,
      first_sequence: nil,
      last_sequence: nil,
      expected_session_revision: action.expected_session_revision,
      first_revision: last_revision,
      last_revision: last_revision
    }
  end

  defp require_non_neg_integer(result, field) do
    case Map.fetch(result, field) do
      {:ok, value} when is_integer(value) and value >= 0 ->
        :ok

      _ ->
        {:error,
         Error.new(
           :corrupt_result,
           "stored result is missing a non-negative integer",
           nil,
           %{reason: :corrupt_result, field: field}
         )}
    end
  end

  defp require_run_state(result, expected) do
    case Map.fetch(result, :run_state) do
      {:ok, ^expected} ->
        :ok

      {:ok, actual} ->
        {:error,
         Error.new(
           :corrupt_result,
           "stored result run_state does not match the requested operation",
           nil,
           %{reason: :corrupt_result, expected: expected, actual: actual}
         )}

      :error ->
        {:error,
         Error.new(
           :corrupt_result,
           "stored result is missing run_state",
           nil,
           %{reason: :corrupt_result}
         )}
    end
  end

  defp require_projection_digest(result) do
    case Map.fetch(result, :projection_digest) do
      {:ok, value} when is_binary(value) ->
        if Regex.match?(~r/^[0-9a-f]{64}$/, value) do
          :ok
        else
          {:error,
           Error.new(
             :corrupt_result,
             "stored result projection_digest is malformed",
             nil,
             %{reason: :corrupt_result, value: value}
           )}
        end

      _ ->
        {:error,
         Error.new(
           :corrupt_result,
           "stored result is missing projection_digest",
           nil,
           %{reason: :corrupt_result}
         )}
    end
  end

  defp require_stored_session_matches_id(stored_session_id, claimed_session_id)
       when stored_session_id == claimed_session_id,
       do: :ok

  defp require_stored_session_matches_id(stored_session_id, claimed_session_id) do
    {:error,
     Error.new(
       :corrupt_result,
       "stored result session_id disagrees with the authoritative journal session",
       nil,
       %{
         reason: :corrupt_result,
         stored_session_id: stored_session_id,
         claimed_session_id: claimed_session_id
       }
     )}
  end

  defp start_result_from_stored(replay) do
    with :ok <- validate_stored_start_result(replay) do
      result = replay.result

      {:ok,
       %{
         session_id: result.session_id,
         task_id: result.task_id,
         run_id: result.run_id,
         action_id: result.action_id,
         session_revision: result.session_revision,
         run_state: :ready,
         projection_digest: result.projection_digest
       }}
    end
  end

  defp transition_result_from_stored(:cancel_session, replay) do
    with :ok <- validate_stored_transition_result(:cancel_session, replay) do
      result = replay.result

      {:ok,
       %{
         session_id: result.session_id,
         action_id: result.action_id,
         session_revision: result.session_revision,
         run_state: :canceled,
         projection_digest: result.projection_digest
       }}
    end
  end

  defp transition_result_from_stored(:resume_session, replay) do
    with :ok <- validate_stored_transition_result(:resume_session, replay) do
      result = replay.result

      {:ok,
       %{
         session_id: result.session_id,
         action_id: result.action_id,
         session_revision: result.session_revision,
         run_state: :running,
         projection_digest: result.projection_digest
       }}
    end
  end

  # ---- entry construction ----

  defp build_start_entry(session, task, run) do
    %{
      type: "session_started/v1",
      payload_schema: "session_started/v1",
      payload: %{
        "session" => %{"id" => session.id, "state" => "active"},
        "task" => %{"id" => task.id, "state" => "in_progress"},
        "run" => %{
          "id" => run.id,
          "state" => "ready",
          "root_run_id" => run.root_run_id
        },
        "workflow_step" => "intent",
        "objective" => session.objective,
        "criteria" => task.criteria,
        "constraints" => task.constraints,
        "exclusions" => task.exclusions,
        "objective_revision" => session.revision,
        "criteria_revision" => session.criteria_revision,
        "references" => %{"project_observation_id" => session.project_observation_id}
      }
    }
  end

  defp build_run_transitioned_entry(from_state, to_state, reducer_step) do
    %{
      type: "run_transitioned/v1",
      payload_schema: "run_transitioned/v1",
      payload: %{
        "run" => %{"from" => Atom.to_string(from_state), "to" => Atom.to_string(to_state)},
        "workflow_step" => reducer_step
      }
    }
  end

  # ---- projection access ----

  defp load_projection(conn, session_id) do
    case ProjectionStore.compare(conn, session_id) do
      {:ok, :empty} ->
        {:ok, :empty}

      {:ok, status, %{projection: projection, journal_head_digest: journal_head_digest}}
      when status in [
             :match,
             :rebuilt,
             :replaced_malformed,
             :replaced_stale,
             :replaced_invalid_metadata
           ] ->
        {:ok,
         %{
           session_id: session_id,
           projection: projection,
           source: source_from_status(status),
           projection_digest: SessionProjection.digest(projection),
           journal_head_digest: journal_head_digest,
           orphaned: orphaned?(projection)
         }}

      {:ok, status, _report} ->
        {:error,
         Error.new(
           :projection_unavailable,
           "the projection could not be classified",
           :session_id,
           %{status: status}
         )}

      {:error, %{code: code, detail: detail}} ->
        {:error, Error.new(code, "the journal does not validate", :session_id, detail)}

      {:error, _block} ->
        {:error, Error.new(:journal_invalid, "the journal does not validate", :session_id)}
    end
  end

  defp source_from_status(:match), do: :cache
  defp source_from_status(_), do: :rebuilt

  # A Root Run is `orphaned` when its projection carries a non-nil
  # operation whose state is nonterminal (e.g. `"intent_recorded"`).
  # This matches `Kiln.Restart.classify/2` so the CLI does not have to
  # alias the Restart module. The classification is derived from the
  # same projection invariant without consulting Transcript or replay
  # internals.
  @nonterminal_operation_states ~w(intent_recorded requested awaiting_response)

  defp orphaned?(projection) when is_map(projection) do
    case projection["operation"] do
      %{"state" => state} when is_binary(state) ->
        state in @nonterminal_operation_states

      _ ->
        false
    end
  end

  defp orphaned?(_), do: false

  defp run_state_from_projection(%{"run" => %{"state" => state}}) when is_binary(state) do
    state_to_atom(state)
  end

  defp run_state_from_projection(_projection), do: nil

  defp state_to_atom("ready"), do: :ready
  defp state_to_atom("running"), do: :running
  defp state_to_atom("waiting_for_user"), do: :waiting_for_user
  defp state_to_atom("orphaned"), do: :orphaned
  defp state_to_atom("completed"), do: :completed
  defp state_to_atom("failed"), do: :failed
  defp state_to_atom("canceled"), do: :canceled
  defp state_to_atom(_), do: nil

  defp run_id_from_projection(%{"run" => %{"id" => id}}) when is_binary(id), do: id
  defp run_id_from_projection(_projection), do: nil

  # ---- connection acquisition ----

  defp store_conn do
    case Process.whereis(Kiln.Store.Connection) do
      nil ->
        {:error,
         Error.new(
           :store_unavailable,
           "the state store connection is not registered; ensure the Kiln application is started"
         )}

      pid when is_pid(pid) ->
        {:ok, pid}
    end
  end

  # ---- entropy source ----

  defp strong_rand_bytes, do: &:crypto.strong_rand_bytes/1

  defp now_iso, do: DateTime.utc_now() |> DateTime.to_iso8601()
end
