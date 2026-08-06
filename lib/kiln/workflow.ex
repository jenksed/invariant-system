defmodule Kiln.Workflow do
  @moduledoc """
  The single public application boundary for P1-S01 session operations.

  Composes the existing `Kiln.Domain.Session`, `Kiln.Domain.Action`,
  `Kiln.Domain.Transition`, `Kiln.Store.Journal.commit/4`, and
  `Kiln.Projections.Store.compare/2` modules without redefining domain or
  persistence semantics and without exposing their internals. CLI, TUI, ACP,
  and other clients call this module directly rather than reaching into
  domain or store modules.

  ## Public contract

    * `start_session/1` — atomic Session creation. Required: `:objective`,
      `:criteria` (≥1), `:actor_id`. Optional: `:constraints`,
      `:exclusions`, `:started_at`, `:idempotency_key`, `:project_observation`.

    * `query_session/1` — current projection for a `session_id`.

    * `cancel_session/2` — atomic cancellation. Required:
      `session_id`, `expected_session_revision`, `:actor_id`. Rejected when
      the current Run state does not permit cancellation.

    * `resume_session/2` — atomic resumption. Required: same as
      `cancel_session/2`. Permitted only from `:ready` in this slice;
      resume from `:waiting_for_user` and `:orphaned` is deferred to a
      future ticket. Records as a `:transition_run` action with a
      `run_transitioned/v1` entry so no new action kind is required
      (U01-R2 default).

    * `valid_next_actions/1` — bounded atoms permitted from the current
      state, deterministically ascending-sorted.

  Every return is `{:ok, _}` or `{:error, %Kiln.Domain.Error{}}`. Mutating
  operations perform no journal write when validation or input checking
  fails. Return shapes carry only identifiers, revision, state, and
  projection digest; the committed `Kiln.Domain.Action{}` envelope and the
  raw `%Kiln.Domain.Session{}` / `%Kiln.Domain.Run{}` / `%Kiln.Domain.Task{}`
  structs never appear in any return value.

  Configuration: state path is read through `Application.get_env(:kiln,
  :state_path)` inside this module only; domain and store modules remain
  configuration-free. `actor_id` is required explicitly and is never read
  from configuration.
  """

  alias Kiln.Domain.{Action, Error, Id, ProjectObservation, Session, Transition}
  alias Kiln.Projections.Session, as: SessionProjection
  alias Kiln.Projections.Store, as: ProjectionStore
  alias Kiln.Store.{Canonical, Journal}

  @type start_opts :: keyword()

  @type start_result :: %{
          session_id: String.t(),
          task_id: String.t(),
          run_id: String.t(),
          session_revision: non_neg_integer(),
          run_state: atom(),
          projection_digest: String.t() | nil
        }

  @doc """
  Start a new durable Root Session.

  Required: `:objective` (binary), `:criteria` (non-empty list of binaries),
  `:actor_id` (non-empty binary). Optional: `:constraints`, `:exclusions`
  (default `[]`), `:started_at` (default `DateTime.utc_now/0`), `:idempotency_key`
  (auto-generated when omitted), and `:project_observation` (a struct or a
  map with `:repository_root`, `:repository_fingerprint` (sha256:...), `:observed_at`).

  Returns the application-facing identifiers and the resulting revision,
  run state, and projection digest. Performs no journal write on any
  validation failure.
  """
  @spec start_session(start_opts()) ::
          {:ok, start_result()} | {:error, Error.t()}
  def start_session(opts) when is_list(opts) do
    with {:ok, actor_id} <- require_actor_id(opts),
         {:ok, objective} <- require_nonempty_string(opts, :objective, :objective),
         {:ok, criteria} <- require_string_list(opts, :criteria, :criteria, minimum: 1),
         {:ok, constraints} <-
           require_string_list(opts, :constraints, :constraints, minimum: 0),
         {:ok, exclusions} <-
           require_string_list(opts, :exclusions, :exclusions, minimum: 0),
         {:ok, started_at} <- require_started_at(opts),
         {:ok, project_observation} <- resolve_project_observation(opts),
         {:ok, idempotency_key} <- resolve_idempotency_key(opts),
         {:ok, conn} <- store_conn(),
         {:ok, %{session: session, task: task, run: run}} =
           Session.start(
             %{
               project_observation: project_observation,
               objective: objective,
               criteria: criteria,
               constraints: constraints,
               exclusions: exclusions,
               started_at: started_at
             },
             []
           ),
         {:ok, action_id} <- Id.generate(:action, &:crypto.strong_rand_bytes/1),
         {:ok, request_digest} <-
           build_request_digest(:start_session, %{
             session_id: session.id,
             objective: objective,
             criteria: criteria
           }),
         {:ok, action} <-
           build_action(:start_session, action_id, session.id, run.id, 0,
             idempotency_key: idempotency_key,
             actor_id: actor_id,
             request_digest: request_digest,
             payload: %{
               "objective" => objective,
               "criteria" => criteria
             }
           ),
         {:ok, entry} <- build_start_entry(session, task, run),
         {:ok, committed} <- commit_action(conn, action, [entry], now_iso(started_at)) do
      {:ok,
       %{
         session_id: session.id,
         task_id: task.id,
         run_id: run.id,
         session_revision: committed.session_revision,
         run_state: :ready,
         projection_digest: projection_digest(committed)
       }}
    end
  end

  @spec query_session(String.t()) ::
          {:ok,
           %{
             projection: map(),
             source: :cache | :rebuilt,
             projection_digest: String.t()
           }}
          | {:ok, :empty}
          | {:error, Error.t()}
  def query_session(session_id) when is_binary(session_id) do
    with :ok <- require_session_id_format(session_id),
         {:ok, conn} <- store_conn(),
         {:ok, status, report} <- load_projection(conn, session_id, fn -> {:ok, :empty} end) do
      {:ok,
       %{
         projection: report.projection,
         source: source_from_status(status),
         projection_digest: SessionProjection.digest(report.projection)
       }}
    end
  end

  @doc """
  Cancel a Root Session at `session_id`.

  Required: `:actor_id` (non-empty binary). Rejected when the action's
  `expected_session_revision` does not match the current projection revision,
  or when the current Run state does not allow the transition, or when
  the Run is already terminal.
  """
  @spec cancel_session(String.t(), keyword()) ::
          {:ok,
           %{
             session_id: String.t(),
             action_id: String.t(),
             session_revision: non_neg_integer(),
             run_state: :canceled,
             projection_digest: String.t() | nil
           }}
          | {:error, Error.t()}
  def cancel_session(session_id, opts) when is_binary(session_id) and is_list(opts) do
    execute_transition(
      session_id,
      opts,
      target_state: :canceled,
      transition_action: :cancel_session,
      from_states: [:ready, :running, :waiting_for_user],
      resume_marker: false
    )
  end

  @doc """
  Resume a Root Session at `session_id` from an eligible Run state.

  Required: `:actor_id` (non-empty binary). Permitted only when the current
  Run state is one of `:ready`, `:waiting_for_user`, or `:orphaned`. The
  action is recorded under kind `:transition_run` with a
  `run_transitioned/v1` entry so no new action kind is introduced (U01-R2).
  """
  @spec resume_session(String.t(), keyword()) ::
          {:ok,
           %{
             session_id: String.t(),
             action_id: String.t(),
             session_revision: non_neg_integer(),
             run_state: :running,
             projection_digest: String.t() | nil
           }}
          | {:error, Error.t()}
  def resume_session(session_id, opts) when is_binary(session_id) and is_list(opts) do
    execute_transition(
      session_id,
      opts,
      target_state: :running,
      transition_action: :transition_run,
      from_states: [:ready],
      resume_marker: true
    )
  end

  @doc """
  Return the ascending-sorted list of bounded atoms currently permitted.

  The contract is owned by this boundary and is independent of any text or
  JSON presentation; downstream renderers stringify the atoms as needed.
  """
  @spec valid_next_actions(String.t()) :: {:ok, [atom()]} | {:error, Error.t()}
  def valid_next_actions(session_id) when is_binary(session_id) do
    with :ok <- require_session_id_format(session_id),
         {:ok, conn} <- store_conn(),
         {:ok, _status, report} <-
           load_projection(conn, session_id, fn ->
             {:ok, :empty, %{projection: empty_projection()}}
           end) do
      run_state = run_state_from_projection(report.projection)
      {:ok, permitted_atoms(run_state)}
    end
  end

  # ---- transition path (cancel + resume) ----

  defp execute_transition(session_id, opts,
         target_state: target_state,
         transition_action: transition_action,
         from_states: from_states,
         resume_marker: resume_marker
       ) do
    with :ok <- require_session_id_format(session_id),
         {:ok, actor_id} <- require_actor_id(opts),
         {:ok, expected_revision} <- require_expected_revision(opts),
         {:ok, conn} <- store_conn(),
         {:ok, _status, report} <-
           load_projection(conn, session_id, fn -> {:error, no_projection_error()} end),
         :ok <- require_known_run_state(run_state_from_projection(report.projection)),
         :ok <-
           validate_transition(
             run_state_from_projection(report.projection),
             target_state,
             from_states
           ),
         {:ok, idempotency_key} <- resolve_idempotency_key(opts),
         {:ok, action_id} <- Id.generate(:action, &:crypto.strong_rand_bytes/1),
         {:ok, request_digest} <-
           build_request_digest(transition_action, %{
             session_id: session_id,
             expected_session_revision: expected_revision,
             target_state: Atom.to_string(target_state)
           }),
         {:ok, action} <-
           build_action(
             transition_action,
             action_id,
             session_id,
             run_id_from_projection(report.projection),
             expected_revision,
             idempotency_key: idempotency_key,
             actor_id: actor_id,
             request_digest: request_digest,
             payload: %{}
           ),
         {:ok, entry} <-
           build_run_transitioned_entry(
             run_state_from_projection(report.projection),
             target_state,
             workflow_step: workflow_step_for(resume_marker)
           ),
         {:ok, committed} <- commit_action(conn, action, [entry], now_iso(DateTime.utc_now())) do
      {:ok,
       %{
         session_id: session_id,
         action_id: action.id,
         session_revision: committed.session_revision,
         run_state: target_state,
         projection_digest: projection_digest(committed)
       }}
    end
  end

  defp load_projection(conn, session_id, on_empty) do
    case ProjectionStore.compare(conn, session_id) do
      {:ok, :empty} ->
        on_empty.()

      {:ok, status, report} ->
        {:ok, status, report}

      {:error, %{code: code, detail: detail}} ->
        {:error, Error.new(code, "journal does not validate", :session_id, detail)}

      {:error, _block} ->
        {:error, Error.new(:journal_invalid, "journal does not validate", :session_id)}
    end
  end

  # ---- permitted next actions ----

  defp permitted_atoms(:ready),
    do: Enum.sort([:cancel_session, :transition_run, :revise_intent, :request_decision])

  defp permitted_atoms(:running),
    do: Enum.sort([:transition_run, :revise_intent])

  defp permitted_atoms(:waiting_for_user),
    do: Enum.sort([:transition_run, :answer_decision, :cancel_session])

  defp permitted_atoms(:orphaned),
    do: Enum.sort([:transition_run, :cancel_session, :fail_session])

  defp permitted_atoms(state) when state in [:completed, :failed, :canceled], do: []

  defp permitted_atoms(nil), do: []

  defp empty_projection do
    %{"run" => %{"state" => nil}}
  end

  # ---- journal commit wrapper ----

  defp commit_action(conn, action, entries, now) do
    case Journal.commit(conn, action, entries, now: now) do
      {:ok, committed} ->
        {:ok, committed}

      {:error, %Kiln.Store.Error{code: code, message: message, details: details}} ->
        {:error, Error.new(code, message, nil, details)}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

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

  # ---- input validation ----

  defp require_actor_id(opts) do
    with {:ok, value} when is_binary(value) <- Keyword.fetch(opts, :actor_id),
         false <- String.trim(value) == "" do
      {:ok, value}
    else
      _ ->
        {:error,
         Error.new(
           :missing_actor_id,
           "actor_id is required and must be a non-blank binary",
           :actor_id,
           %{atom: :actor_id}
         )}
    end
  end

  defp require_nonempty_string(opts, key, code) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _ ->
        {:error, Error.new(code, "field must be a non-empty string", key)}
    end
  end

  defp require_string_list(opts, key, code, minimum: minimum) do
    value = Keyword.get(opts, key, [])

    if is_list(value) and length(value) >= minimum and
         Enum.all?(value, &(is_binary(&1) and byte_size(&1) > 0)) do
      {:ok, value}
    else
      {:error, Error.new(code, "field must be a list of non-empty strings", key)}
    end
  end

  defp require_started_at(opts) do
    case Keyword.get(opts, :started_at, DateTime.utc_now()) do
      %DateTime{} = value -> {:ok, value}
      _ -> {:error, Error.new(:invalid_started_at, "started_at must be a DateTime", :started_at)}
    end
  end

  defp require_expected_revision(opts) do
    case Keyword.fetch(opts, :expected_session_revision) do
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

  defp require_known_run_state(state)
       when state in [
              :ready,
              :running,
              :waiting_for_user,
              :orphaned,
              :completed,
              :failed,
              :canceled
            ],
       do: :ok

  defp require_known_run_state(_state),
    do: {:error, Error.new(:unknown_run_state, "current Run state is not recognized")}

  defp require_session_id_format(session_id) do
    case Id.valid?(:session, session_id) do
      true ->
        :ok

      false ->
        {:error,
         Error.new(
           :invalid_session_id,
           "session_id does not match the session identifier format",
           :session_id
         )}
    end
  end

  defp resolve_project_observation(opts) do
    case Keyword.get(opts, :project_observation) do
      %ProjectObservation{} = value ->
        {:ok, value}

      attrs when is_map(attrs) ->
        ProjectObservation.new(attrs)

      nil ->
        {:error,
         Error.new(
           :missing_project_observation,
           "project_observation is required (pass a %ProjectObservation{} or a map with :repository_root, :repository_fingerprint, :observed_at)",
           :project_observation
         )}

      _ ->
        {:error,
         Error.new(
           :invalid_project_observation,
           "project_observation must be a ProjectObservation struct or a map",
           :project_observation
         )}
    end
  end

  defp resolve_idempotency_key(opts) do
    case Keyword.fetch(opts, :idempotency_key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _ ->
        Id.generate(:idempotency, &:crypto.strong_rand_bytes/1)
    end
  end

  # ---- action envelope construction ----

  defp build_action(kind, action_id, session_id, run_id, expected_session_revision, opts) do
    payload = Keyword.fetch!(opts, :payload)
    idempotency_key = Keyword.fetch!(opts, :idempotency_key)
    actor_id = Keyword.fetch!(opts, :actor_id)
    request_digest = Keyword.fetch!(opts, :request_digest)

    Action.new(%{
      id: action_id,
      session_id: session_id,
      run_id: run_id,
      expected_session_revision: expected_session_revision,
      idempotency_key: idempotency_key,
      actor_kind: :local_user,
      actor_id: actor_id,
      kind: kind,
      request_digest: request_digest,
      payload: payload,
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: Keyword.get(opts, :requested_at, DateTime.utc_now())
    })
  end

  # ---- entry payload construction ----

  defp build_start_entry(session, task, run) do
    payload = %{
      "session" => %{"id" => session.id, "state" => Atom.to_string(session.state)},
      "task" => %{"id" => task.id, "state" => "in_progress"},
      "run" => %{
        "id" => run.id,
        "state" => Atom.to_string(run.state),
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

    {:ok, %{type: "session_started/v1", payload: payload, payload_schema: "session_started/v1"}}
  end

  defp build_run_transitioned_entry(from_state, to_state, opts) do
    payload = %{
      "run" => %{"from" => Atom.to_string(from_state), "to" => Atom.to_string(to_state)},
      "workflow_step" => Keyword.fetch!(opts, :workflow_step)
    }

    {:ok, %{type: "run_transitioned/v1", payload: payload, payload_schema: "run_transitioned/v1"}}
  end

  # ---- transition validation ----

  defp validate_transition(from_state, to_state, from_states) do
    cond do
      from_state not in from_states ->
        {:error,
         Error.new(
           :run_transition_not_allowed,
           "the current Run state does not permit this transition",
           nil,
           %{
             from: Atom.to_string(from_state),
             to: Atom.to_string(to_state),
             permitted_from_states: Enum.map(from_states, &Atom.to_string/1)
           }
         )}

      not MapSet.member?(Transition.allowed_run_transitions(), {from_state, to_state}) ->
        {:error,
         Error.new(
           :run_transition_not_allowed,
           "the Run transition is not in the accepted transition table",
           nil,
           %{from: Atom.to_string(from_state), to: Atom.to_string(to_state)}
         )}

      true ->
        :ok
    end
  end

  # ---- projection access helpers ----

  defp run_state_from_projection(%{"run" => %{"state" => state}}) when is_binary(state) do
    String.to_existing_atom(state)
  end

  defp run_state_from_projection(%{"run_state" => state}) when is_binary(state) do
    String.to_existing_atom(state)
  end

  defp run_state_from_projection(_projection), do: nil

  defp run_id_from_projection(%{"run" => %{"id" => id}}), do: id
  defp run_id_from_projection(%{"run_id" => id}), do: id
  defp run_id_from_projection(_projection), do: nil

  defp projection_digest(%{projection: nil}), do: nil
  defp projection_digest(%{projection: projection}), do: digest_or_nil(projection)

  defp digest_or_nil(projection) do
    SessionProjection.digest(projection)
  rescue
    _ -> nil
  end

  defp source_from_status(:match), do: :cache
  defp source_from_status(:rebuilt), do: :rebuilt
  defp source_from_status(:replaced_malformed), do: :rebuilt
  defp source_from_status(:replaced_stale), do: :rebuilt
  defp source_from_status(:replaced_invalid_metadata), do: :rebuilt

  defp no_projection_error do
    Error.new(:no_projection, "no journal entries exist for this Session", :session_id)
  end

  # ---- workflow step ----

  defp workflow_step_for(true), do: "application"
  defp workflow_step_for(false), do: "intent"

  # ---- request digest ----

  defp build_request_digest(kind, attrs) do
    schema = "kiln.workflow.request_digest/v1"

    {:ok, digest} =
      try do
        {:ok,
         "sha256:" <>
           ((schema <>
               "\n" <> Canonical.encode(%{"kind" => Atom.to_string(kind), "attrs" => attrs}))
            |> :crypto.hash(:sha256)
            |> Base.encode16(case: :lower))}

        # Canonical.encode may raise on unexpected shapes, in which case
        # fall through to a defensive default digest.
      rescue
        _ ->
          seed = "{#{inspect(kind)},#{inspect(attrs)}}"
          {:ok, "sha256:" <> (:crypto.hash(:sha256, seed) |> Base.encode16(case: :lower))}
      end

    {:ok, digest}
  end

  # ---- date utilities ----

  defp now_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
end
