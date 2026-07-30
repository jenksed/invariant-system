defmodule Kiln.Journal.ReplayTest do
  use ExUnit.Case, async: true

  alias Kiln.Journal.Replay
  alias Kiln.Projections.{Session, Store}
  alias Kiln.Store.Connection
  alias Kiln.Test.JournalBuilder, as: JB

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-replay-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    store = JB.store(Path.join(dir, "state.sqlite3"))
    on_exit(fn -> stop(store.conn) end)

    d = JB.domain()
    {:ok, store: store, d: d}
  end

  test "replays a valid journal into the exact committed projection", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3)
    {:ok, last} = JB.commit_criteria(store, d, 1, 4, 1, ["The revised criterion passes"])

    assert {:ok, report} = Replay.rebuild(store.conn, d.session.id)
    assert report.session_revision == 2
    assert report.action_count == 3
    assert report.entry_count == 3
    assert report.first_sequence == 1
    assert report.last_sequence == 3

    # The revised criteria must be reconstructed by replay, not only the
    # counter. Both commit and replay must agree on the rewritten contract.
    assert report.projection["criteria"] == ["The revised criterion passes"]
    assert report.projection["criteria_revision"] == 1
    assert last.projection["criteria"] == ["The revised criterion passes"]

    assert Session.digest(report.projection) == Session.digest(last.projection)

    assert Session.digest(report.projection) ==
             Session.digest(Store.load(store.conn, d.session.id))
  end

  test "applies every entry of one accepted multi-entry action", %{store: store, d: d} do
    {:ok, start} = JB.commit_start(store, d)
    # One action appends two legitimate entries sharing its idempotency key.
    {:ok, batch} = JB.commit_entries(store, d, :transition_run, 0, 5, JB.two_entry_batch(1))

    # Commit-time projection reflects both entries.
    assert batch.session_revision == 2
    assert batch.projection["run"]["state"] == "running"
    assert batch.projection["criteria_revision"] == 1

    assert {:ok, report} = Replay.rebuild(store.conn, d.session.id)
    assert report.action_count == 2
    assert report.entry_count == 3
    assert report.session_revision == 2

    # Replay is byte-for-byte identical to the commit-time projection: no entry
    # of the multi-entry action is dropped as a duplicate.
    assert Session.digest(report.projection) == Session.digest(batch.projection)
    refute Session.digest(report.projection) == Session.digest(start.projection)
  end

  test "blocks a revision discontinuity at its boundary", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3)

    Connection.query!(
      store.conn,
      "UPDATE journal_entries SET session_revision = 5 WHERE session_revision = 1"
    )

    Connection.query!(
      store.conn,
      "UPDATE action_commits SET first_sequence = 2 WHERE first_sequence = 2"
    )

    assert {:error, %{code: :revision_discontinuity, boundary: 2}} =
             Replay.rebuild(store.conn, d.session.id)
  end

  test "blocks a corrupt payload at its boundary", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    Connection.query!(
      store.conn,
      ~s|UPDATE journal_entries SET payload = '{"tampered":true}' WHERE session_revision = 0|
    )

    assert {:error, %{code: :corrupt_payload, detail: %{reason: :digest_mismatch}}} =
             Replay.rebuild(store.conn, d.session.id)
  end

  test "transcript records never change the projection", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, before} = Replay.rebuild(store.conn, d.session.id)

    JB.insert_transcript(store.conn, d.session.id, "trx_1", "first note")
    JB.insert_transcript(store.conn, d.session.id, "trx_2", "second note")

    assert {:ok, after_transcripts} = Replay.rebuild(store.conn, d.session.id)
    assert Session.digest(after_transcripts.projection) == Session.digest(before.projection)

    ids =
      store.conn
      |> Connection.query!(
        "SELECT transcript_id FROM transcript_records WHERE session_id = ?1 ORDER BY transcript_id",
        [d.session.id]
      )
      |> List.flatten()

    assert ids == ["trx_1", "trx_2"]
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
