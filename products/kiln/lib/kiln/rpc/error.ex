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

  @doc """
  Bounded error response forwarding the entire bounded error envelope
  from the handler (preserves method, scope, fields, reason, etc.).
  This is the path that keeps P5 — bounded error codes and their
  accompanying metadata reach the client without flattening.
  """
  def bounded_from_err(%Plug.Conn{} = conn, err_map, attrs \\ [])
      when is_map(err_map) and is_list(attrs) do
    err_map = Map.put(err_map, :code, Map.fetch!(err_map, :code))
    attrs = Keyword.put(attrs, :code, err_map.code)
    attrs = maybe_put(attrs, :reason, Map.get(err_map, :reason))
    attrs = maybe_put(attrs, :method, Map.get(err_map, :method))
    attrs = maybe_put(attrs, :scope, Map.get(err_map, :scope))
    attrs = maybe_put(attrs, :fields, Map.get(err_map, :fields))
    attrs = maybe_put(attrs, :field, Map.get(err_map, :field))
    do_bounded(conn, attrs)
  end

  defp maybe_put(attrs, key, nil), do: attrs
  defp maybe_put(attrs, key, value), do: Keyword.put(attrs, key, value)

  defp do_bounded(conn, attrs) do
    code = attrs[:code] || :E_UNKNOWN
    reason = attrs[:reason] || :unspecified
    scope = attrs[:scope]
    method = attrs[:method]

    body =
      Jason.encode!(%{
        code: code,
        reason: reason,
        scope: scope,
        method: method,
        fields: attrs[:fields],
        field: attrs[:field]
      })

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
