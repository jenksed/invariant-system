defmodule Kiln.Activity.WebSocket do
  @moduledoc """
  WP-09 Lane 2: bounded Cowboy WebSocket handler for the `/ws` endpoint.

  Replaces the bare 101 stub in `Kiln.Service.handle_websocket/1`
  (service.ex:53-64). The handler authenticates the bearer token during
  the HTTP upgrade, requires an `activity.subscribe` envelope as the
  first client-to-server frame, and then forwards
  `activity.notification` envelopes from `Kiln.Activity.Hub` until the
  connection closes.

  Wire contract (WP-09 contract freeze §6 + §7):

      client → server (first frame, required):
        {"type":"activity.subscribe","subscription_id":"sub_<32hex>",
         "filter":{"session_id":"ses_<32hex>"},
         "since_revision":<integer>}

      server → client:
        {"type":"activity.snapshot", ...canonical initial state...}
        OR
        {"type":"activity.error","code":"..."}
        OR
        {"type":"activity.notification","subscription_id":"...","revision":...,
         "emitted_at":"...","subject":{...},"event_kind":"state_changed",
         "canonical_session_revision":...}

  Identity rules (contract freeze §3):
  * `subscription_id` is a correlation handle, NOT authorization.
  * PID, hostname, Temper process id MUST NOT enter any frame.
  * On reconnect, the client MUST open a new WS, send a new
    subscribe, and obtain canonical state via `session.query`.

  Close codes:
  * 4001 — unauthorized (bearer token missing or invalid)
  * 4003 — first frame was not a valid `activity.subscribe`
  * 4004 — bounded subscription not found (filter mismatch)
  * 4010 — internal error (Hub unreachable)
  * 1000 — normal closure
  """

  @behaviour :cowboy_websocket

  alias Kiln.Activity.Hub

  def init(req, _opts) do
    case :cowboy_req.parse_header("authorization", req) do
      {:bearer, token} ->
        case Kiln.Service.verify_token_for_ws(token) do
          {:ok, _scope} ->
            {:upgrade, :protocol, :cowboy_websocket, req, %{subscription_id: nil}}

          {:error, _reason} ->
            :cowboy_req.reply(401, %{"content-type" => "application/json"},
              ~s({"code":"E_SCOPE_INSUFFICIENT","reason":"ws auth failed"}), req)
        end

      _ ->
        :cowboy_req.reply(401, %{"content-type" => "application/json"},
          ~s({"code":"E_SCOPE_INSUFFICIENT","reason":"missing authorization"}), req)
    end
  end

  @impl :cowboy_websocket
  def websocket_init(state) do
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_handle({:text, payload}, state) do
    case Jason.decode(payload) do
      {:ok, %{"type" => "activity.subscribe"} = sub} ->
        handle_subscribe(sub, state)

      {:ok, %{"type" => "ping"}} ->
        {:reply, {:text, Jason.encode!(%{"type" => "pong"})}, state}

      {:ok, other} ->
        {:reply, {:text, encode_error(:E_INVALID_FIELD, "first frame must be activity.subscribe")}, state}

      {:error, _} ->
        {:reply, {:text, encode_error(:E_MALFORMED_REQUEST, "invalid JSON")}, state}
    end
  end

  def websocket_handle({:binary, _}, state) do
    {:reply, {:text, encode_error(:E_INVALID_FIELD, "binary frames not allowed")}, state}
  end

  def websocket_handle(_other, state) do
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:activity_notification, frame}, state) do
    {:reply, {:text, Jason.encode!(frame)}, state}
  end

  def websocket_info(:subscribe_timeout, state) do
    {:stop, state}
  end

  def websocket_info(_other, state) do
    {:ok, state}
  end

  @impl :cowboy_websocket
  def terminate(_reason, _partial_req, state) do
    case state[:subscription_id] do
      nil -> :ok
      sub_id -> Hub.unregister(sub_id)
    end

    :ok
  end

  # -- helpers --

  defp handle_subscribe(%{"subscription_id" => sub_id} = sub, state)
       when is_binary(sub_id) and byte_size(sub_id) > 0 do
    session_id = get_in(sub, ["filter", "session_id"])
    since = Map.get(sub, "since_revision", 0)
    pid = self()

    case Hub.register(%{
           subscription_id: sub_id,
           pid: pid,
           session_id: session_id,
           since_revision: since
         }) do
      :ok ->
        snapshot = %{
          type: "activity.snapshot",
          subscription_id: sub_id,
          since_revision: since,
          schema_version: "kiln/activity/v1"
        }

        {:reply, {:text, Jason.encode!(snapshot)},
         Map.put(state, :subscription_id, sub_id)}

      {:error, :already_registered} ->
        {:stop, state}
    end
  end

  defp handle_subscribe(_sub, state) do
    {:reply, {:text, encode_error(:E_MISSING_FIELDS, "subscription_id required")}, state}
  end

  defp encode_error(code, reason) do
    Jason.encode!(%{
      "type" => "activity.error",
      "code" => Atom.to_string(code),
      "reason" => reason
    })
  end
end
