defmodule Kiln.RPC.Error do
  @moduledoc """
  M12-D WP-07: bounded error envelope.

  Per Pathfinder WP-02: bounded error envelope matches existing M0 bounded
  machinery contract. Used for all RPC errors.
  """

  @doc """
  Bounded error response with status code and JSON body.
  """
  def bounded(conn_or_code, attrs \\ []) do
    case conn_or_code do
      %Plug.Conn{} = conn ->
        do_bounded(conn, attrs)

      _ ->
        %{code: conn_or_code, reason: attrs[:reason] || :unknown}
    end
  end

  @doc """
  Bounded error response on a conn with an explicit bounded code.
  """
  def bounded(%Plug.Conn{} = conn, code, attrs) when is_atom(code) and is_list(attrs) do
    do_bounded(conn, Keyword.put(attrs, :code, code))
  end

  defp do_bounded(conn, attrs) do
    code = attrs[:code] || :E_UNKNOWN
    reason = attrs[:reason] || :unspecified
    scope = attrs[:scope]
    method = attrs[:method]
    body = Jason.encode!(%{code: code, reason: reason, scope: scope, method: method})

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(attrs[:status] || 400, body)
  end

  @doc """
  401 Unauthorized for missing/invalid token.
  """
  def unauthorized(conn, reason \\ :missing_authorization) do
    do_bounded(conn, code: :E_UNAUTHORIZED, reason: reason, status: 401)
  end

  @doc """
  403 Forbidden for scope mismatch.
  """
  def forbidden(conn, reason) do
    do_bounded(conn, code: :E_FORBIDDEN, reason: reason, status: 403)
  end
end
