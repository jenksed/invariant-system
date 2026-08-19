defmodule Kiln.ActivityWebSocketTest do
  @moduledoc """
  WP-09 Repair-14 regression: ensure the activity WebSocket handler's
  `init/2` returns the correct shape for Cowboy 2.18.

  Cowboy 2.18's `cowboy_handler:execute/2` (cowboy_handler.erl:37-44)
  accepts only two upgrade shapes:
    - 3-tuple `{Mod, Req, State}`
    - 4-tuple `{Mod, Req, State, Opts}`

  The previous 5-tuple `{upgrade, :protocol, :cowboy_websocket, Req, State}`
  is the Cowboy 1.x signature and is no longer accepted. Returning
  the wrong shape raised TryClauseError and crashed every WebSocket
  upgrade. The 3-tuple form delegates to `:cowboy_websocket:upgrade/4`.
  """

  use ExUnit.Case, async: false

  alias Kiln.Activity.WebSocket

  setup do
    previous = Application.get_env(:kiln, :scoped_tokens)
    read_token = Base.encode16(:crypto.strong_rand_bytes(32))
    operate_token = Base.encode16(:crypto.strong_rand_bytes(32))

    Application.put_env(:kiln, :scoped_tokens, %{
      read_token => "orchestration:read",
      operate_token => "orchestration:operate"
    })

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:kiln, :scoped_tokens)
        v -> Application.put_env(:kiln, :scoped_tokens, v)
      end
    end)

    %{read_token: read_token, operate_token: operate_token}
  end

  # Build a minimal Cowboy-style req map with the required fields
  # for authentication. The init function only inspects the
  # authorization header; the rest of the request is irrelevant for
  # this regression test.
  defp build_req(token) do
    %{
      headers: %{
        "authorization" => "Bearer #{token}"
      }
    }
  end

  test "init/2 returns the 3-tuple cowboy_websocket upgrade shape for a valid bearer token",
       %{operate_token: tok} do
    req = build_req(tok)
    assert {:cowboy_websocket, ^req, %{subscription_id: nil}} = WebSocket.init(req, [])
  end

  test "init/2 returns the 3-tuple shape (not the obsolete 5-tuple) for a valid bearer token",
       %{operate_token: tok} do
    req = build_req(tok)
    result = WebSocket.init(req, [])
    # The previous (broken) shape was `{:upgrade, :protocol, :cowboy_websocket, req, state}`.
    # Reject it explicitly so the regression cannot return unnoticed.
    refute match?({:upgrade, :protocol, :cowboy_websocket, _, _}, result),
           "init/2 must NOT return the Cowboy 1.x obsolete 5-tuple"
  end
end
