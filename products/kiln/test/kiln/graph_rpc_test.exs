defmodule Kiln.GraphRPCTest do
  use ExUnit.Case, async: false

  alias Kiln.{Store, Workflow}

  setup do
    stop_registered_store()
    dir = Path.join(System.tmp_dir!(), "kiln-graph-rpc-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      stop_registered_store()
      File.rm_rf!(dir)
    end)

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "graph_rpc_fixture",
        now: "2026-08-20T20:00:00Z",
        name: Kiln.Store.Connection
      )

    {:ok, store: store}
  end

  test "graph.query projects canonical Session/Task/Run identities without writing", %{store: store} do
    {:ok, started} =
      Workflow.start_session(
        objective: "prove graph transport",
        criteria: ["canonical graph is readable"],
        project_observation: %{
          repository_root: "/tmp/invariant-graph-fixture",
          repository_fingerprint: "sha256:0000000000000000000000000000000000000000000000000000000000000001",
          observed_at: ~U[2026-08-20 20:00:00Z]
        },
        actor_id: "user:test"
      )

    before_count = count(store.conn, "journal_entries")

    assert {:ok, graph} =
             Kiln.RPC.Handlers.Graph.handle(
               "graph.query",
               %{"session_id" => started.session_id},
               []
             )

    assert graph["schema"] == "kiln/session-graph/v1"
    assert graph["session_id"] == started.session_id
    assert graph["revision"] == 0
    assert is_binary(graph["projection_digest"])

    kinds = graph["nodes"] |> Enum.map(& &1["kind"]) |> Enum.sort()
    assert kinds == ["Run", "Session", "Task"]

    edge_kinds = graph["edges"] |> Enum.map(& &1["kind"]) |> Enum.sort()
    assert edge_kinds == ["CONTAINS", "HAS_RUN"]
    assert Enum.all?(graph["edges"], &(&1["proposed"] == false))

    assert count(store.conn, "journal_entries") == before_count
  end

  test "graph.query is authorized only at orchestration:read" do
    assert {:error, %{code: :E_SCOPE_INSUFFICIENT}} =
             Kiln.RPC.Router.dispatch(
               "orchestration:operate",
               %{"method" => "graph.query", "params" => %{"session_id" => "ses_0123456789abcdef0123456789abcdef"}}
             )
  end

  defp count(conn, table) do
    {:ok, %{rows: [[value]]}} = Exqlite.Sqlite3.execute(conn, "SELECT COUNT(*) FROM #{table}")
    value
  end

  defp stop_registered_store do
    case Process.whereis(Kiln.Store.Connection) do
      pid when is_pid(pid) ->
        if Process.alive?(pid), do: GenServer.stop(pid, :normal, 1_000)

      _ ->
        :ok
    end

    :ok
  end
end
