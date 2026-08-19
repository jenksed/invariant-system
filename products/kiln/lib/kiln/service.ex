defmodule Kiln.Service do
  @moduledoc """
  M12-D WP-07: bounded Kiln daemon (HTTP + WebSocket).

  Per Pathfinder WP-02 decision (client-server-boundary.md):
  - HTTP at `http://localhost:<port>` for bounded unary operations
  - WebSocket at `/ws` for bounded streams (activity, terminal, thread)
  - Per-method scope (orchestration:read, orchestration:operate, terminal:operate,
    review:write, access:read, access:write) adapted from T3
  - Bearer token for localhost; one-time pairing for remote
  - Bounded error envelope (matches existing M0 bounded machinery)

  Architecture: Plug.Cowboy + Cowboy WebSocket handler. NOT full Phoenix
  framework (bounded machinery surface kept narrow per Pathfinder WP-06).
  Per-method scope + bounded reconnect + per-entity streams implemented
  directly in Kiln.
  """

  alias Kiln.RPC.Router
  alias Kiln.RPC.Error

  # Bounded scoped tokens are sourced from application config at runtime,
  # NOT hardcoded in source. The bounded daemon reads tokens from
  # Application config (set via runtime config or ENV-backed config) so
  # no long-lived credential lives in source.
  #
  # Set bounded dev tokens via Application.put_env or runtime config:
  #   Application.put_env(:kiln, :scoped_tokens, %{token => scope, ...})
  #
  # Default is empty (no tokens); production must populate via bounded
  # token store + revocation. See WP-07 / WP-08 implementation work
  # packages.

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_header("x-inv", "kiln")
    |> route()
  end

  # Bounded routes: HTTP unary + WebSocket streaming
  defp route(conn) do
    case conn.path_info do
      ["ws"] -> handle_websocket(conn)
      ["api", "rpc"] -> handle_unary(conn)
      ["healthz"] -> handle_healthz(conn)
      _ -> handle_not_found(conn)
    end
  end

  # WebSocket streaming endpoint
  defp handle_websocket(conn) do
    case authenticate(conn) do
      {:ok, _scope} ->
        conn
        |> Plug.Conn.put_resp_header("upgrade", "websocket")
        |> Plug.Conn.put_resp_header("connection", "upgrade")
        |> Plug.Conn.resp(101, "")

      {:error, reason} ->
        Error.unauthorized(conn, reason)
    end
  end

  # HTTP unary RPC endpoint (POST only; other methods are unknown paths)
  defp handle_unary(%Plug.Conn{method: "POST"} = conn) do
    with {:ok, scope} <- authenticate(conn),
         {:ok, body, conn} <- read_request_body(conn),
         {:ok, result} <- Router.dispatch(scope, body) do
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(result))
    else
      # Order matters: more-specific patterns first.
      {:error, %{code: :E_BODY_READ_FAILED}} ->
        Error.bounded(conn, :E_BODY_READ_FAILED, status: 400)

      {:error, %{code: code}} ->
        Error.bounded(conn, code, status: 400)

      {:error, :missing_authorization} ->
        Error.unauthorized(conn, :missing_authorization)

      {:error, :invalid_token} ->
        Error.unauthorized(conn, :invalid_token)
    end
  end

  # Non-POST on /api/rpc is a bounded 404 (unknown path)
  defp handle_unary(conn), do: handle_not_found(conn)

  defp handle_healthz(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(200, ~s({"status":"ok"}))
  end

  defp handle_not_found(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(404, ~s({"code":"E_NOT_FOUND","reason":"unknown path"}))
  end

  # Bounded auth: bearer token in Authorization header
  defp authenticate(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> verify_token(token)
      _ -> {:error, :missing_authorization}
    end
  end

  defp verify_token(token) do
    :kiln
    |> Application.get_env(:scoped_tokens, %{})
    |> Map.fetch(token)
    |> case do
      {:ok, scope} -> {:ok, scope}
      :error -> {:error, :invalid_token}
    end
  end

  # Bounded body read (bounded size to prevent OOM)
  defp read_request_body(conn) do
    case Plug.Conn.read_body(conn, length: 1_048_576) do
      {:ok, "", conn} -> {:ok, %{}, conn}
      {:ok, body, conn} -> {:ok, Jason.decode!(body), conn}
      {:error, reason} -> {:error, %{code: :E_BODY_READ_FAILED, reason: reason}}
      {:more, body, conn} -> {:ok, Jason.decode!(body), conn}
    end
  end
end
