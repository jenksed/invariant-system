defmodule Kiln.M12DScopeRegressionTest do
  @moduledoc """
  WP-09 exact-scope authorization regression guard.

  History: Repair-3 + Repair-4 revealed that the WP-09-introduced
  review.propose handler was being reached with the
  orchestration:operate token and being rejected at the scope
  check, NOT at the bounded review validation. The router must
  enforce the frozen exact-match scope table — never accept a
  broader superset scope for a more-restrictive method.

  This test asserts that:

  1. review.propose CANNOT be reached with orchestration:operate
     (must require review:write exactly).
  2. terminal.attach CANNOT be reached with orchestration:operate
     (must require terminal:operate exactly).
  3. project.list (orchestration:read) CANNOT be reached with
     orchestration:operate — the exact-match check must NOT
     silently accept a superset scope as a substitute.

  Each assertion matches the frozen WP-09 scope table verbatim
  (LANE-EVIDENCE-WP09-CONTRACTS.md §4).
  """

  use ExUnit.Case, async: false

  import Plug.Test

  alias Kiln.{Service, Store}

  setup do
    previous = Application.get_env(:kiln, :scoped_tokens)

    read_token = Base.encode16(:crypto.strong_rand_bytes(32))
    operate_token = Base.encode16(:crypto.strong_rand_bytes(32))
    review_write_token = Base.encode16(:crypto.strong_rand_bytes(32))
    terminal_operate_token = Base.encode16(:crypto.strong_rand_bytes(32))

    Application.put_env(
      :kiln,
      :scoped_tokens,
      %{
        read_token => "orchestration:read",
        operate_token => "orchestration:operate",
        review_write_token => "review:write",
        terminal_operate_token => "terminal:operate"
      }
    )

    dir = Path.join(System.tmp_dir!(), "kiln-wp09-scope-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    {:ready, _store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "wp09_scope_#{System.unique_integer([:positive])}",
        name: Kiln.Store.Connection
      )

    on_exit(fn ->
      case Process.whereis(Kiln.Store.Connection) do
        nil -> :ok
        pid -> Process.unlink(pid)
      end

      try do
        GenServer.stop(Kiln.Store.Connection, :normal, 1_000)
      catch
        :exit, _ -> :ok
      end

      case previous do
        nil -> Application.delete_env(:kiln, :scoped_tokens)
        value -> Application.put_env(:kiln, :scoped_tokens, value)
      end

      File.rm_rf!(dir)
    end)

    %{
      read_token: read_token,
      operate_token: operate_token,
      review_write_token: review_write_token,
      terminal_operate_token: terminal_operate_token
    }
  end

  defp post_rpc(token, body) do
    json = Jason.encode!(body)
    conn = conn(:post, "/api/rpc", json) |> Plug.Conn.put_req_header("content-type", "application/json")
    conn = Plug.Conn.put_req_header(conn, "authorization", "Bearer #{token}")
    Service.call(conn, Service.init([]))
  end

  # Exact scope enforcement — frozen WP-09 contract freeze §4.

  test "orchestration:operate CANNOT reach review.propose",
       %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "review.propose", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_SCOPE_INSUFFICIENT",
           "review.propose with orchestration:operate must be scope-rejected"
    assert body["method"] == "review.propose"
  end

  test "review:write CAN reach review.propose", %{review_write_token: tok} do
    conn = post_rpc(tok, %{method: "review.propose", params: %{}})
    body = Jason.decode!(conn.resp_body)
    refute body["code"] == "E_SCOPE_INSUFFICIENT",
           "review.propose with review:write must NOT be scope-rejected"
  end

  test "orchestration:operate CANNOT reach terminal.attach", %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "terminal.attach", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_SCOPE_INSUFFICIENT",
           "terminal.attach with orchestration:operate must be scope-rejected"
    assert body["method"] == "terminal.attach"
  end

  test "terminal:operate CAN reach terminal.attach", %{terminal_operate_token: tok} do
    conn = post_rpc(tok, %{method: "terminal.attach", params: %{}})
    body = Jason.decode!(conn.resp_body)
    refute body["code"] == "E_SCOPE_INSUFFICIENT"
  end

  test "orchestration:read CAN reach activity.subscribe (read-only)",
       %{read_token: tok} do
    conn = post_rpc(tok, %{method: "activity.subscribe", params: %{subscription_id: "sub_x"}})
    body = Jason.decode!(conn.resp_body)
    refute body["code"] == "E_SCOPE_INSUFFICIENT"
  end

  test "orchestration:operate CANNOT reach project.list (exact-match, not superset)",
       %{operate_token: tok} do
    conn = post_rpc(tok, %{method: "project.list", params: %{}})
    body = Jason.decode!(conn.resp_body)
    assert body["code"] == "E_SCOPE_INSUFFICIENT",
           "project.list with orchestration:operate must be scope-rejected " <>
             "(exact-match, not superset)"
  end
end
