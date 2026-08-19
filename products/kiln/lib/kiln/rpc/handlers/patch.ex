defmodule Kiln.RPC.Handlers.Patch do
  @moduledoc """
  M12-D WP-08 Lane 3: bounded RPC handler for `patch.apply`.

  Wraps `Kiln.PatchService.apply/3` with Workflow-driven intent/observation
  journaling (P2). The handler commits an `external_operation_intent_recorded/v1`
  journal entry BEFORE the patch applies, and commits an
  `external_operation_observed/v1` entry AFTER with the terminal state
  in `{succeeded, failed, unknown}`.

  This handler does NOT add a Store dependency to `Kiln.PatchService`.
  The service remains a pure repository-mutation function; the journaling
  lives here. The handler calls `Kiln.Store.Journal.commit/4` directly
  with the same Action+Entry shape that `Kiln.Test.JournalBuilder` uses
  (test/support/journal_builder.ex:108-139). The entry types and reducer
  entries already exist (`external_operation_intent_recorded/v1` at
  `journal/entry.ex:32`, reducers at `journal/reducer.ex:161, 179`).

  Errors from PatchService that carry a bounded `:code` atom pass through
  unchanged so the router preserves them (P5). Errors without a `:code`
  are wrapped in `:E_DISPATCH_FAILED` at the router layer.

  Required envelope fields (P2 + Operation `@enforce_keys`):

      params:
        proposal              — M0PatchProposal-shaped map
        decision              — M0PatchDecision-shaped map (APPROVE_EXACT_BYTES)
        operations_with_bytes — bounded ops list consumed by PatchService.apply/3
        session_id            — ses_<32hex>  (operation + action identity)
        run_id                — run_<32hex>
        operation_id          — opn_<32hex>  (the patch_application op)
        subject_id            — non-empty string (default: proposal.repository)
        subject_revision      — non-negative integer (default: 0)
        expected_session_revision — non-negative integer (default: 0)
        actor_id              — non-empty string
        actor_kind            — :system | :local_user (default: :system)
        idempotency_key       — idem_<32hex>  (or inherited from envelope)
        request_digest        — sha256:<64hex>  (or inherited from envelope)
        recorded_at           — ISO 8601 string (default: now)
  """

  alias Kiln.Domain.{Action, Operation}
  alias Kiln.Domain.Error, as: DomainError
  alias Kiln.{M0PatchDecision, M0PatchProposal}
  alias Kiln.PatchService
  alias Kiln.Store.Journal, as: StoreJournal

  @intent_entry_type "external_operation_intent_recorded/v1"
  @observation_entry_type "external_operation_observed/v1"

  @required_param_keys [
    "decision",
    "proposal",
    "operations_with_bytes",
    "session_id",
    "run_id",
    "operation_id",
    "subject_id",
    "actor_id",
    "idempotency_key",
    "request_digest"
  ]

  @doc """
  Dispatch `patch.apply`. Returns `{:ok, result}` or `{:error, %{code: ...}}`.
  """
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()} | {:error, %{required(:code) => atom()}}
  def handle("patch.apply", params, opts) when is_map(params) and is_list(opts) do
    with :ok <- require_all(params, @required_param_keys),
         :ok <- validate_subject_revision(params["subject_revision"]),
         {:ok, idempotency_key, request_digest} <- resolve_idempotency(params, opts),
         :ok <- validate_id(idempotency_key, :idempotency),
         :ok <- validate_id(params["session_id"], :session),
         :ok <- validate_id(params["run_id"], :run),
         :ok <- validate_id(params["operation_id"], :operation),
         :ok <- validate_digest(request_digest),
         :ok <- validate_actor_kind(params["actor_kind"]),
         {:ok, recorded_at} <- coerce_recorded_at(params["recorded_at"]),
         {:ok, intent_action_id} <- generate_id(:action),
         {:ok, observe_action_id} <- generate_id(:action),
         {:ok, observation_idempotency_key} <- generate_id(:idempotency),
         {:ok, operation} <-
           Operation.intent(%{
             id: params["operation_id"],
             session_id: params["session_id"],
             run_id: params["run_id"],
             class: :patch_application,
             subject_id: params["subject_id"],
             subject_revision: Map.get(params, "subject_revision", 0),
             idempotency_key: idempotency_key,
             request_digest: request_digest,
             recorded_at: recorded_at
           }),
         {:ok, action} <-
           Action.new(%{
             id: intent_action_id,
             session_id: params["session_id"],
             run_id: params["run_id"],
             expected_session_revision: Map.get(params, "expected_session_revision", 0),
             idempotency_key: idempotency_key,
             actor_kind: Map.get(params, "actor_kind", :system),
             actor_id: params["actor_id"],
             kind: :record_operation_intent,
             request_digest: request_digest,
             payload: %{
               operation: %{id: operation.id, class: "patch_application"},
               workflow_step: "application"
             },
             causation_action_id: nil,
             correlation_id: params["correlation_id"],
             requested_at: recorded_at
           }) do
      commit_intent_and_apply(
        operation,
        action,
        observe_action_id,
        observation_idempotency_key,
        params,
        opts
      )
    end
  end

  def handle(_method, _params, _opts) do
    {:error, %{code: :E_UNKNOWN_METHOD}}
  end

  # -- commit intent + apply + observe --

  defp commit_intent_and_apply(
         operation,
         intent_action,
         observe_action_id,
         observation_idempotency_key,
         params,
         opts
       ) do
    conn = Process.whereis(Kiln.Store.Connection)

    if is_nil(conn) do
      {:error, %{code: :E_STORE_UNAVAILABLE, reason: "Kiln.Store.Connection is not registered"}}
    else
      intent_entry = build_intent_entry(operation)
      commit_opts = [now: now_iso8601()] ++ opts

      case StoreJournal.commit(conn, intent_action, [intent_entry], commit_opts) do
        {:ok, _commit} ->
          apply_and_observe(
            operation,
            intent_action,
            observe_action_id,
            observation_idempotency_key,
            params,
            commit_opts
          )

        {:error, reason} ->
          {:error, normalize_store_error(reason)}
      end
    end
  end

  defp apply_and_observe(
         operation,
         intent_action,
         observe_action_id,
         observation_idempotency_key,
         params,
         commit_opts
       ) do
    decision = coerce_decision(params["decision"])
    proposal = coerce_proposal(params["proposal"])
    ops_with_bytes = atomize_ops(params["operations_with_bytes"])

    case PatchService.apply(proposal, decision, ops_with_bytes) do
      {:ok, evidence} ->
        _ =
          commit_observation(
            operation,
            intent_action,
            observe_action_id,
            observation_idempotency_key,
            "succeeded",
            "ready",
            commit_opts
          )

        {:ok, %{evidence: serialize_evidence(evidence)}}

      {:error, %{code: :E_MUTATION_UNKNOWN_EFFECT} = err} ->
        _ =
          commit_observation(
            operation,
            intent_action,
            observe_action_id,
            observation_idempotency_key,
            "unknown",
            "orphaned",
            commit_opts
          )

        {:error, err}

      {:error, %{code: code} = err}
      when code in [
             :E_PATCH_PREIMAGE_MISMATCH,
             :E_PATCH_AFTER_IMAGE_MISMATCH,
             :E_PATCH_BASE_MISMATCH,
             :E_PATCH_DECISION_INVALID,
             :E_PATCH_DECISION_NOT_APPROVE,
             :E_PATCH_REPOSITORY_INVALID,
             :E_PATCH_POSTIMAGE_MISMATCH
           ] ->
        _ =
          commit_observation(
            operation,
            intent_action,
            observe_action_id,
            observation_idempotency_key,
            "failed",
            "failed",
            commit_opts
          )

        {:error, err}

      {:error, %{code: _} = err} ->
        {:error, err}

      {:error, reason} ->
        {:error, %{code: :E_PATCH_INTERNAL, reason: inspect(reason)}}
    end
  end

  defp commit_observation(
         operation,
         intent_action,
         observe_action_id,
         observation_idempotency_key,
         op_state,
         run_to,
         commit_opts
       ) do
    conn = Process.whereis(Kiln.Store.Connection)
    observed_at = now()

    case Action.new(%{
           id: observe_action_id,
           session_id: operation.session_id,
           run_id: operation.run_id,
           expected_session_revision: intent_action.expected_session_revision + 1,
           idempotency_key: observation_idempotency_key,
           actor_kind: intent_action.actor_kind,
           actor_id: intent_action.actor_id,
           kind: :observe_operation,
           request_digest: intent_action.request_digest,
           payload: %{
             operation: %{id: operation.id, state: op_state},
             run: %{to: run_to},
             workflow_step: "application"
           },
           causation_action_id: intent_action.id,
           correlation_id: nil,
           requested_at: observed_at
         }) do
      {:ok, action} ->
        entry = %{
          type: @observation_entry_type,
          payload_schema: @observation_entry_type,
          payload: %{
            "operation" => %{"id" => operation.id, "state" => op_state},
            "run" => %{"to" => run_to},
            "workflow_step" => "application"
          }
        }

        StoreJournal.commit(
          conn,
          action,
          [entry],
          Keyword.put_new(commit_opts, :now, now_iso8601())
        )

      {:error, _} = err ->
        err
    end
  end

  # -- entry / action builders --

  defp build_intent_entry(%Operation{} = op) do
    %{
      type: @intent_entry_type,
      payload_schema: @intent_entry_type,
      payload: %{
        "operation" => %{"id" => op.id, "class" => "patch_application"},
        "workflow_step" => "application"
      }
    }
  end

  # Mints a fresh id that satisfies the canonical `<prefix>_<32hex>`
  # opaque format. Each commit MUST use a fresh id so the action_commits
  # unique constraint is satisfied.
  defp generate_id(kind) do
    Kiln.Domain.Id.generate(kind)
  end

  # -- coercion --

  defp coerce_proposal(%M0PatchProposal{} = proposal), do: proposal
  defp coerce_proposal(%{} = proposal_map), do: struct(M0PatchProposal, atomize_keys(proposal_map))
  defp coerce_proposal(_), do: nil

  defp coerce_decision(%M0PatchDecision{} = decision), do: decision

  defp coerce_decision(%{} = decision_map) do
    decision_map
    |> atomize_keys()
    |> then(&struct(M0PatchDecision, &1))
  end

  defp coerce_decision(_), do: nil

  # Convert known top-level string keys to atoms so `struct/2` populates
  # the struct fields. Unknown keys are dropped. This mirrors the
  # bounded envelope contract — the handler never invents fields.
  defp atomize_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      atom_key =
        case key do
          k when is_atom(k) -> k
          k when is_binary(k) -> safe_to_existing_atom(k)
          _ -> nil
        end

      case atom_key do
        nil -> acc
        atom -> Map.put(acc, atom, value)
      end
    end)
  end

  defp safe_to_existing_atom(key) when is_binary(key) do
    String.to_existing_atom(key)
  rescue
    ArgumentError -> nil
  end

  # Convert a JSON-decoded operations list (string-keyed maps) into the
  # atom-keyed shape that `Kiln.PatchService.apply/3` consumes. The
  # op `kind` arrives as a string ("add" | "replace" | "delete") and
  # is converted to the corresponding atom. Unknown keys are dropped.
  defp atomize_ops(ops) when is_list(ops) do
    Enum.map(ops, fn op -> atomize_op(op) end)
  end

  defp atomize_ops(_), do: []

  defp atomize_op(%{} = op) do
    Enum.reduce(op, %{}, fn {key, value}, acc ->
      atom_key =
        case key do
          k when is_atom(k) -> k
          k when is_binary(k) -> safe_to_existing_atom(k)
          _ -> nil
        end

      case atom_key do
        nil -> acc
        :op -> Map.put(acc, :op, coerce_op_kind(value))
        atom -> Map.put(acc, atom, value)
      end
    end)
  end

  defp atomize_op(other), do: other

  defp coerce_op_kind("add"), do: :add
  defp coerce_op_kind("replace"), do: :replace
  defp coerce_op_kind("delete"), do: :delete
  defp coerce_op_kind(:add), do: :add
  defp coerce_op_kind(:replace), do: :replace
  defp coerce_op_kind(:delete), do: :delete
  defp coerce_op_kind(_), do: :replace

  defp serialize_evidence(%{} = evidence) do
    evidence
    |> Map.from_struct()
    |> stringify_patch_ref()
  end

  defp serialize_evidence(evidence), do: evidence

  defp stringify_patch_ref(%{patch_ref: ref} = evidence) when is_map(ref) do
    Map.put(evidence, :patch_ref, stringify_keys(ref))
  end

  defp stringify_patch_ref(evidence), do: evidence

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
  end

  defp stringify_keys(value), do: value

  # -- error normalization --

  # WP-09 Repair-13: normalize_store_error now returns a single MAP,
  # NOT a `{:error, map}` tuple. The previous implementation returned
  # a tuple, and the caller wrapped it again as `{:error, normalize_store_error(reason)}`,
  # producing a double tuple `{:error, {:error, %{...}}}` that propagated
  # into the bounded error envelope's `reason` field. Jason.Encoder
  # then crashed with Protocol.UndefinedError: protocol Jason.Encoder
  # not implemented for Tuple, and the response body was empty
  # (HTTP 500). The handler spec is
  # `{:ok, term()} | {:error, %{required(:code) => atom()}}` — the
  # caller wraps the map into a tuple, normalize_store_error owns
  # only the map shape.
  #
  # The second clause also accepts `:reason` (not `:message`) because
  # the canonical journal error envelope uses `:reason`, not the
  # `:message` field from Domain.Error. When the journal returns
  # `%{code: :invalid_entry, reason: "...", details: %{...}}`,
  # this clause now matches it and preserves the original error.
  defp normalize_store_error(%DomainError{code: code, message: message, details: details}) do
    %{code: code, reason: message, details: details}
  end

  defp normalize_store_error(%{code: code, reason: message} = error) do
    %{code: code, reason: message, details: Map.get(error, :details, %{})}
  end

  defp normalize_store_error(reason) do
    %{code: :E_JOURNAL_COMMIT_FAILED, reason: inspect(reason)}
  end

  # -- validators --

  defp require_all(params, keys) do
    missing = Enum.filter(keys, fn k -> not Map.has_key?(params, k) end)

    case missing do
      [] ->
        :ok

      _ ->
        {:error, %{code: :E_MISSING_FIELDS, reason: "missing required fields", fields: missing}}
    end
  end

  defp resolve_idempotency(params, opts) do
    param_idem = Map.get(params, "idempotency_key")
    opt_idem = Keyword.get(opts, :idempotency_key)
    param_req = Map.get(params, "request_digest")
    opt_req = Keyword.get(opts, :request_digest)

    idem = param_idem || opt_idem
    req = param_req || opt_req

    case {idem, req} do
      {id, r} when is_binary(id) and is_binary(r) ->
        {:ok, id, r}

      _ ->
        {:error,
         %{code: :E_MISSING_FIELDS, reason: "idempotency_key + request_digest required (envelope or params)"}}
    end
  end

  defp validate_id(value, kind) when is_binary(value) do
    case Kiln.Domain.Id.validate(kind, value) do
      :ok -> :ok
      {:error, %DomainError{} = err} -> {:error, %{code: err.code, reason: err.message, details: err.details}}
    end
  end

  defp validate_id(_value, _kind),
    do: {:error, %{code: :E_INVALID_FIELD, reason: "id must be a non-empty string"}}

  defp validate_digest(value) when is_binary(value) do
    if Regex.match?(~r/^sha256:[0-9a-f]{64}$/, value) do
      :ok
    else
      {:error, %{code: :E_INVALID_DIGEST, reason: "request_digest must be sha256:<64hex>"}}
    end
  end

  defp validate_actor_kind(nil), do: :ok
  defp validate_actor_kind(kind) when kind in [:system, :local_user], do: :ok

  defp validate_actor_kind(_),
    do: {:error, %{code: :E_INVALID_FIELD, reason: "actor_kind must be :system or :local_user"}}

  defp validate_subject_revision(nil), do: :ok

  defp validate_subject_revision(value) when is_integer(value) and value >= 0, do: :ok

  defp validate_subject_revision(_) do
    {:error, %{code: :E_INVALID_FIELD, reason: "subject_revision must be a non-negative integer"}}
  end

  defp coerce_recorded_at(nil), do: {:ok, now()}

  defp coerce_recorded_at(%DateTime{} = dt), do: {:ok, dt}

  defp coerce_recorded_at(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> {:ok, dt}
      _ -> {:error, %{code: :E_INVALID_FIELD, reason: "recorded_at must be ISO 8601"}}
    end
  end

  defp coerce_recorded_at(_) do
    {:error, %{code: :E_INVALID_FIELD, reason: "recorded_at must be a DateTime or ISO 8601 string"}}
  end

  defp now, do: DateTime.utc_now()

  defp now_iso8601, do: DateTime.utc_now() |> DateTime.to_iso8601()
end
