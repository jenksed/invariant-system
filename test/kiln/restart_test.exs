defmodule Kiln.RestartTest do
  use ExUnit.Case, async: true

  alias Kiln.{Restart, Store}
  alias Kiln.Journal.Replay
  alias Kiln.Projections.Session
  alias Kiln.Store.Connection
  alias Kiln.Test.JournalBuilder, as: JB

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-restart-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, path: Path.join(dir, "state.sqlite3")}
  end

  test "restores the full Session state after a restart", %{path: path} do
    store = JB.store(path)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3)
    {:ok, _} = JB.commit_decision(store, d, 1, 5)
    {:ok, _} = JB.commit_answer(store, d, 2, 6)

    {:ok, before} = Replay.rebuild(store.conn, d.session.id)
    GenServer.stop(store.conn)

    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop(restarted.conn) end)

    assert {:ok, recon} = Restart.reconstruct(restarted.conn)
    assert recon.session_revision == 3
    assert recon.compare == :match
    assert recon.orphaned == false
    assert recon.projection["run"]["state"] == "ready"
    assert recon.projection["pending_decision"] == nil
    assert Session.digest(recon.projection) == Session.digest(before.projection)
  end

  test "reconstructs a nonterminal operation as an orphaned Run without dispatching", %{
    path: path
  } do
    store = JB.store(path)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)

    entries_before = count(store.conn, "journal_entries")
    GenServer.stop(store.conn)

    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop(restarted.conn) end)

    assert {:ok, recon} = Restart.reconstruct(restarted.conn)
    assert recon.orphaned == true
    assert recon.projection["run"]["state"] == "orphaned"
    assert recon.projection["operation"]["state"] == "unknown"
    assert recon.projection["unknowns"] != []

    # Reconstruction dispatches and appends nothing: the journal is unchanged.
    assert count(restarted.conn, "journal_entries") == entries_before
  end

  test "reports an empty store", %{path: path} do
    store = JB.store(path)
    on_exit(fn -> stop(store.conn) end)
    assert {:ok, :empty} = Restart.reconstruct(store.conn)
  end

  test "blocks reconstruction on a corrupt journal", %{path: path} do
    store = JB.store(path)
    on_exit(fn -> stop(store.conn) end)
    d = JB.domain()
    {:ok, _} = JB.commit_start(store, d)

    Connection.query!(
      store.conn,
      ~s|UPDATE journal_entries SET payload = '{"tampered":true}' WHERE session_revision = 0|
    )

    assert {:error, %{block: %{code: :corrupt_payload}}} = Restart.reconstruct(store.conn)
  end

  defp count(conn, table) do
    [[n]] = Connection.query!(conn, "SELECT count(*) FROM #{table}")
    n
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
