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
    assert recon.action_count == 4
    assert recon.entry_count == 4
    assert recon.cache_status == :match
    assert recon.orphaned == false
    assert recon.projection["run"]["state"] == "ready"
    assert recon.projection["pending_decision"] == nil
    assert Session.digest(recon.projection) == Session.digest(before.projection)

    # No orphan classification: the two digests agree and describe the returned
    # projection.
    assert recon.reconstructed_projection_digest == Session.digest(recon.projection)
    assert recon.reconstructed_projection_digest == recon.journal_projection_digest
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

    # The reconstructed digest describes the returned orphaned projection, which
    # differs from the pure journal projection digest.
    assert recon.reconstructed_projection_digest == Session.digest(recon.projection)
    assert recon.reconstructed_projection_digest != recon.journal_projection_digest

    # Reconstruction dispatches and appends nothing.
    assert count(restarted.conn, "journal_entries") == entries_before

    # Repeated reconstruction is idempotent: no duplicate unknown marker.
    assert {:ok, again} = Restart.reconstruct(restarted.conn)
    assert length(again.projection["unknowns"]) == 1
    assert again.projection["unknowns"] == recon.projection["unknowns"]
  end

  test "reports an empty store", %{path: path} do
    store = JB.store(path)
    on_exit(fn -> stop(store.conn) end)
    assert {:ok, :empty} = Restart.reconstruct(store.conn)
  end

  test "blocks explicitly when more than one Session exists", %{path: path} do
    store = JB.store(path)
    on_exit(fn -> stop(store.conn) end)

    d1 = JB.domain(1)
    d2 = JB.domain(9)
    {:ok, _} = JB.commit_entries(store, d1, :start_session, 0, 2, [JB.start_entry(d1)])
    {:ok, _} = JB.commit_entries(store, d2, :start_session, 0, 8, [JB.start_entry(d2)])

    assert {:error, %{code: :multiple_sessions, detail: %{count: 2}}} =
             Restart.reconstruct(store.conn)
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

  test "blocks, not empty, when an action commit has no journal rows", %{path: path} do
    store = JB.store(path)
    on_exit(fn -> stop(store.conn) end)
    d = JB.domain()
    {:ok, _} = JB.commit_start(store, d)

    # Remove the journal rows but keep the action commit: incomplete durable state.
    Connection.query!(store.conn, "DELETE FROM journal_entries WHERE session_id = ?1", [
      d.session.id
    ])

    result = Restart.reconstruct(store.conn)
    refute match?({:ok, :empty}, result)
    assert {:error, %{block: %{code: :missing_journal_rows}}} = result
  end

  test "blocks with multiple sessions when one is action-commit-only", %{path: path} do
    store = JB.store(path)
    on_exit(fn -> stop(store.conn) end)

    d1 = JB.domain(1)
    {:ok, _} = JB.commit_start(store, d1)

    d2 = JB.domain(9)

    JB.insert_action_commit(store.conn, %{
      action_id: JB.id(:action, 50),
      session_id: d2.session.id,
      idempotency_key: JB.id(:idempotency, 50),
      request_digest: JB.digest(50),
      expected_session_revision: 0,
      first_sequence: 900,
      last_sequence: 900
    })

    assert {:error, %{code: :multiple_sessions, detail: %{count: 2}}} =
             Restart.reconstruct(store.conn)
  end

  test "a projection-cache-only row is not a Session candidate", %{path: path} do
    store = JB.store(path)
    on_exit(fn -> stop(store.conn) end)

    # A cache row with no journal or action-commit rows must not be authoritative.
    Connection.query!(
      store.conn,
      """
      INSERT INTO session_projections
        (session_id, projection_schema, session_revision, last_sequence, projection, projection_digest, updated_at)
      VALUES ('ses_ghost', 'session_projection/v1', 0, 0, '{}', 'x', '2026-07-29T00:00:00Z')
      """
    )

    assert {:ok, :empty} = Restart.reconstruct(store.conn)
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
