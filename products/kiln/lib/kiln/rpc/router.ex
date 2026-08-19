defmodule Kiln.RPC.Router do
  @moduledoc """
  M12-D WP-07/WP-08: bounded per-method RPC router.

  Per Pathfinder WP-02 service boundary decision:
  - Per-method scope (orchestration:read, orchestration:operate, terminal:operate,
    review:write, access:read, access:write)
  - Adapted from T3's scope table (client-server-boundary.md)
  - Bounded dispatch to bounded Kiln machinery
  - Bounded error envelope on any failure

  WP-08 Lane 2 (P1 + P5):
  - `idempotency_key` (optional) and `request_digest` (optional) are read
    from the top-level envelope alongside `method` and `params`, and are
    passed via `opts` to the session-family handlers in
    `Kiln.RPC.Handlers.Session.handle/3` which forwards them to
    `Kiln.Workflow.start_session/1` etc. When omitted, Workflow auto-mints
    (workflow.ex:908-910) — that path must still work.
  - P5: errors whose map carries a `:code` atom field pass through unchanged.
    Only generic errors without a `:code` field are flattened to
    `:E_DISPATCH_FAILED`. This preserves bounded error codes such as
    `:invalid_session_id`, `:missing_actor_id`, `:invalid_idempotency_key`,
    `:E_MISSING_FIELDS`, etc.
  """

  @scopes %{
    # Map method name → required scope
    "worker.propose" => "orchestration:operate",
    "patch.apply" => "orchestration:operate",
    "verify.run" => "orchestration:operate",
    "review.propose" => "review:write",
    "human.decide" => "orchestration:operate",
    "project.open" => "orchestration:operate",
    "project.list" => "orchestration:read",
    "activity.subscribe" => "orchestration:read",
    "terminal.attach" => "terminal:operate",
    # WP-08 Lane 2 — session-family methods
    "session.start" => "orchestration:operate",
    "session.cancel" => "orchestration:operate",
    "session.resume" => "orchestration:operate",
    "session.query" => "orchestration:read",
    "session.next_actions" => "orchestration:read"
  }

  # Bounded dispatch: method → scope → handler
  #
  # Accepts an envelope of shape:
  #   %{
  #     "method"          => String.t(),
  #     "params"          => map(),
  #     "idempotency_key" => optional String.t(),
  #     "request_digest"  => optional String.t()
  #   }
  #
  # P5: errors carrying a `:code` atom field are returned unchanged so
  # bounded error codes (`Kiln.Domain.Error.code`, `:E_MISSING_FIELDS`, …)
  # survive the transport. Only errors without a `:code` field are wrapped
  # in the bounded `:E_DISPATCH_FAILED` envelope.
  def dispatch(scope, %{"method" => method, "params" => params} = envelope) do
    opts = envelope_opts(envelope)

    case authorize(method, scope) do
      :ok ->
        case invoke(method, params, opts) do
          {:ok, result} -> {:ok, result}
          {:error, %{code: _} = err} -> {:error, err}
          {:error, reason} -> {:error, %{code: :E_DISPATCH_FAILED, reason: reason}}
        end

      {:error, %{code: :E_SCOPE_INSUFFICIENT} = err} ->
        bounded_error = Map.put(err, :scope, scope) |> Map.put(:method, method)
        {:error, bounded_error}

      {:error, %{code: :E_UNKNOWN_METHOD} = err} ->
        {:error, err}
    end
  end

  # Malformed body (missing method/params keys) → bounded error envelope
  def dispatch(_scope, _body) do
    {:error, %{code: :E_MALFORMED_REQUEST, reason: :missing_method_or_params}}
  end

  # Extract optional top-level idempotency_key and request_digest from the
  # envelope. Both must be non-empty strings when present; any other shape
  # is ignored so the downstream handler's own validation can produce a
  # bounded error code (P5) instead of the transport flattening it.
  defp envelope_opts(envelope) do
    []
    |> maybe_put_string(envelope, "idempotency_key", :idempotency_key)
    |> maybe_put_string(envelope, "request_digest", :request_digest)
  end

  defp maybe_put_string(opts, envelope, key, opt_key) do
    case Map.get(envelope, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        Keyword.put(opts, opt_key, value)

      _ ->
        opts
    end
  end

  # Bounded scope authorization
  defp authorize(method, scope) do
    required = Map.get(@scopes, method)

    case required do
      nil -> {:error, %{code: :E_UNKNOWN_METHOD, method: method}}
      ^scope -> :ok
      _ -> {:error, %{code: :E_SCOPE_INSUFFICIENT, method: method}}
    end
  end

  # Bounded method invocation.
  #
  # WP-08 Lane 2 — session-family methods are routed to the bounded
  # `Kiln.RPC.Handlers.Session.handle/3`, which in turn calls bounded
  # `Kiln.Workflow.*` and returns bounded error envelopes with `:code`
  # atom fields that the transport preserves unchanged (P5).
  #
  # `opts` carries optional `idempotency_key` / `request_digest` forwarded
  # from the envelope top-level fields. When omitted, Workflow auto-mints.
  defp invoke(method, params, opts) do
    case method do
      "project.list" -> {:ok, %{projects: []}}
      "project.open" -> {:ok, %{status: "opened", path: params["path"]}}

      "session.start" ->
        Kiln.RPC.Handlers.Session.handle("session.start", params, opts)

      "session.query" ->
        Kiln.RPC.Handlers.Session.handle("session.query", params, opts)

      "session.cancel" ->
        Kiln.RPC.Handlers.Session.handle("session.cancel", params, opts)

      "session.resume" ->
        Kiln.RPC.Handlers.Session.handle("session.resume", params, opts)

      "session.next_actions" ->
        Kiln.RPC.Handlers.Session.handle("session.next_actions", params, opts)

      "patch.apply" ->
        Kiln.RPC.Handlers.Patch.handle("patch.apply", params, opts)

      # WP-09 Lane 1: lifecycle closure. Each handler wraps existing
      # bounded Kiln machinery (Worker.propose/5, M0VerificationResult.build/6,
      # Review.build/9, HumanDecision.build/5, Project.open). The RPC
      # layer adapts to existing domain ownership; it does NOT introduce
      # new Worker / verification / review / HumanDecision semantics.
      "worker.propose" ->
        Kiln.RPC.Handlers.Worker.handle("worker.propose", params, opts)

      "verify.run" ->
        Kiln.RPC.Handlers.Verify.handle("verify.run", params, opts)

      "review.propose" ->
        Kiln.RPC.Handlers.Review.handle("review.propose", params, opts)

      "human.decide" ->
        Kiln.RPC.Handlers.HumanDecision.handle("human.decide", params, opts)

      "project.open" ->
        Kiln.RPC.Handlers.Project.handle("project.open", params, opts)

      "project.list" ->
        Kiln.RPC.Handlers.Project.handle("project.list", params, opts)

      # WP-09 Lane 2: activity.subscribe returns the initial
      # canonical projection envelope. The actual notification stream
      # is delivered over WebSocket at /ws (handlers/activity_websocket.ex).
      # This handler exists only for clients that want the initial
      # canonical snapshot without opening a WebSocket.
      "activity.subscribe" ->
        Kiln.RPC.Handlers.Activity.handle("activity.subscribe", params, opts)

      _ ->
        {:error, %{code: :E_NOT_IMPLEMENTED, method: method}}
    end
  end
end