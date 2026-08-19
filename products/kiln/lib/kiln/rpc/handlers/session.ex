defmodule Kiln.RPC.Handlers.Session do
  @moduledoc """
  M12-D WP-08 Lane 2: bounded RPC handlers for Session lifecycle methods.

  All handlers in this module call bounded `Kiln.Workflow.*` and return
  bounded `{:error, %{code: atom, reason: binary, ...}}` shapes. The router
  preserves the code through the transport (P5 — no flattening to
  E_DISPATCH_FAILED unless the error is truly generic).

  WP-08 P1 (idempotency-key envelope): `opts[:idempotency_key]` is
  forwarded to Workflow when provided; otherwise the auto-mint path
  inside Workflow generates one (workflow.ex:908-910).

  Scope (router.ex scope table):
    session.start         → orchestration:operate
    session.cancel        → orchestration:operate
    session.resume        → orchestration:operate
    session.query         → orchestration:read
    session.next_actions  → orchestration:read
  """

  alias Kiln.Domain.Error, as: DomainError
  alias Kiln.{Domain.ProjectObservation, Workflow}

  @doc "Dispatch a Session-family method. Returns `{:ok, result}` or `{:error, %{code: ...}}`."
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()} | {:error, %{required(:code) => atom(), required(:reason) => term()}}
  def handle(method, params, opts) when is_map(params) and is_list(opts) do
    case method do
      "session.start" -> session_start(params, opts)
      "session.query" -> session_query(params, opts)
      "session.cancel" -> session_cancel(params, opts)
      "session.resume" -> session_resume(params, opts)
      "session.next_actions" -> session_next_actions(params, opts)
      _ -> {:error, %{code: :E_UNKNOWN_METHOD, method: method}}
    end
  end

  # -- session.start --
  # Requires: objective, criteria, actor_id, project_observation.
  # Optional: constraints, exclusions, idempotency_key, request_digest.
  defp session_start(params, opts) do
    required = ["objective", "criteria", "actor_id", "project_observation"]

    with :ok <- require_all(params, required),
         :ok <- validate_project_observation(params["project_observation"]) do
      wf_opts =
        []
        |> put_idempotency(opts)
        |> Keyword.put(:actor_id, params["actor_id"])
        |> Keyword.put(:objective, params["objective"])
        |> Keyword.put(:criteria, params["criteria"])
        |> maybe_put_constraints(params)
        |> maybe_put_exclusions(params)

      wf_opts =
        case build_project_observation(params["project_observation"]) do
          {:ok, po} -> Keyword.put(wf_opts, :project_observation, po)
          {:error, _} = err -> return_early(err)
        end

      case wf_opts do
        {:error, _} = err -> err
        opts -> normalize(Workflow.start_session(opts))
      end
    end
  end

  # -- session.query --
  defp session_query(params, _opts) do
    with {:ok, session_id} <- require_string(params, "session_id") do
      normalize(Workflow.query_session(session_id))
    end
  end

  # -- session.cancel --
  defp session_cancel(params, opts) do
    with {:ok, session_id} <- require_string(params, "session_id"),
         {:ok, actor_id} <- require_string(params, "actor_id"),
         :ok <- require_integer(params, "expected_session_revision") do
      wf_opts =
        [actor_id: actor_id, expected_session_revision: params["expected_session_revision"]]
        |> put_idempotency(opts)

      normalize(Workflow.cancel_session(session_id, wf_opts))
    end
  end

  # -- session.resume --
  defp session_resume(params, opts) do
    with {:ok, session_id} <- require_string(params, "session_id"),
         {:ok, actor_id} <- require_string(params, "actor_id"),
         :ok <- require_integer(params, "expected_session_revision") do
      wf_opts =
        [actor_id: actor_id, expected_session_revision: params["expected_session_revision"]]
        |> put_idempotency(opts)

      normalize(Workflow.resume_session(session_id, wf_opts))
    end
  end

  # -- session.next_actions --
  defp session_next_actions(params, _opts) do
    with {:ok, session_id} <- require_string(params, "session_id") do
      normalize(Workflow.valid_next_actions(session_id))
    end
  end

  # -- helpers --

  defp normalize({:ok, result}), do: {:ok, result}

  defp normalize({:error, %DomainError{code: code, message: message, field: field, details: details}}) do
    {:error,
     %{
       code: code,
       reason: message,
       field: field,
       details: details
     }}
  end

  defp normalize({:error, %{code: _} = err}), do: {:error, err}

  defp normalize({:error, reason}),
    do: {:error, %{code: :E_DISPATCH_FAILED, reason: reason}}

  defp require_all(params, keys) do
    missing = Enum.filter(keys, fn k -> not Map.has_key?(params, k) end)

    case missing do
      [] ->
        :ok

      _ ->
        {:error,
         %{code: :E_MISSING_FIELDS, reason: "missing required fields", fields: missing}}
    end
  end

  defp require_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, %{code: :E_INVALID_FIELD, reason: "field must be a non-empty string", field: key}}
    end
  end

  defp require_integer(params, key) do
    case Map.get(params, key) do
      value when is_integer(value) and value >= 0 -> :ok
      _ -> {:error, %{code: :E_INVALID_FIELD, reason: "field must be a non-negative integer", field: key}}
    end
  end

  defp validate_project_observation(%{}), do: :ok
  defp validate_project_observation(_), do: {:error, %{code: :E_INVALID_PROJECT_OBSERVATION, reason: "project_observation must be a map"}}

  defp build_project_observation(%{} = attrs) do
    # JSON-decoded envelopes carry string keys + ISO 8601 timestamps; the
    # `Kiln.Domain.ProjectObservation.new/1` validators use atom keys +
    # `%DateTime{}` structs. Normalize the known attribute set here so the
    # RPC handler works for both JSON-decoded (string-keyed, ISO-string
    # timestamp) and direct (atom-keyed, DateTime struct) callers.
    #
    # We return the normalized MAP (not a `%ProjectObservation{}` struct)
    # because Workflow's idempotency-digest logic excludes the
    # internally-generated `id` for map inputs (`observation_id_source` =
    # `:generated`), so two identical map inputs replay idempotently.
    # Passing a struct would force `:caller` source and bake the random
    # id into the request digest, breaking P1 replay.
    attrs = normalize_observation_attrs(attrs)
    case ProjectObservation.new(attrs) do
      {:ok, _struct} -> {:ok, attrs}
      {:error, _} = error -> error
    end
  end

  # Convert the known `ProjectObservation` attribute keys from string to
  # atom and parse `observed_at` from an ISO 8601 string to a
  # `%DateTime{}` when present. Unknown keys are dropped.
  defp normalize_observation_attrs(attrs) do
    %{}
    |> put_observation_field(attrs, :repository_root, "repository_root")
    |> put_observation_field(attrs, :repository_fingerprint, "repository_fingerprint")
    |> put_observation_datetime(attrs, :observed_at, "observed_at")
  end

  defp put_observation_field(acc, attrs, atom_key, string_key) do
    value =
      case Map.fetch(attrs, string_key) do
        {:ok, v} -> v
        :error -> Map.get(attrs, atom_key)
      end

    case value do
      nil -> acc
      v -> Map.put(acc, atom_key, v)
    end
  end

  defp put_observation_datetime(acc, attrs, atom_key, string_key) do
    raw =
      case Map.fetch(attrs, string_key) do
        {:ok, v} -> v
        :error -> Map.get(attrs, atom_key)
      end

    case coerce_observed_at(raw) do
      nil -> acc
      dt -> Map.put(acc, atom_key, dt)
    end
  end

  # Accept either a `%DateTime{}` struct (direct callers) or an ISO 8601
  # string (JSON-decoded envelopes). Anything else is dropped so the
  # downstream validator surfaces a bounded `:invalid_field` error.
  defp coerce_observed_at(%DateTime{} = value), do: value

  defp coerce_observed_at(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp coerce_observed_at(_), do: nil

  defp maybe_put_constraints(opts, params) do
    case Map.get(params, "constraints") do
      nil -> opts
      constraints when is_list(constraints) -> Keyword.put(opts, :constraints, constraints)
      _ -> opts
    end
  end

  defp maybe_put_exclusions(opts, params) do
    case Map.get(params, "exclusions") do
      nil -> opts
      exclusions when is_list(exclusions) -> Keyword.put(opts, :exclusions, exclusions)
      _ -> opts
    end
  end

  defp put_idempotency(opts, env_opts) do
    case Keyword.get(env_opts, :idempotency_key) do
      nil -> opts
      value when is_binary(value) -> Keyword.put(opts, :idempotency_key, value)
      _ -> opts
    end
  end

  defp return_early({:error, _} = err), do: err
end