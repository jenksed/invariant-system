defmodule Kiln.Journal.ReplayTest do
  use ExUnit.Case, async: true

  alias Kiln.Journal.Replay
  alias Kiln.Projections.{Session, Store}
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
    {:ok, last} = JB.commit_criteria(store, d, 1, 4, 1)

    assert {:ok, rebuild} = Replay.rebuild(store.conn, d.session.id)
    assert rebuild.session_revision == 2
    assert rebuild.entry_count == 3

    # Byte-for-byte identical to the stored projection produced at commit time.
    assert Session.digest(rebuild.projection) == Session.digest(last.projection)

    assert Session.digest(rebuild.projection) ==
             Session.digest(Store.load(store.conn, d.session.id))
  end

  test "a duplicate identical action produces no extra projected effect", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3)

    # A crafted duplicate of the transition: same key and digest, later revision.
    JB.insert_entry_row(store.conn, %{
      session_id: d.session.id,
      sequence: 100,
      revision: 2,
      type: "run_transitioned/v1",
      payload: %{"run" => %{"from" => "running", "to" => "running"}},
      idempotency_key: JB.id(:idempotency, 3),
      request_digest: JB.digest(3)
    })

    assert {:ok, rebuild} = Replay.rebuild(store.conn, d.session.id)
    # The duplicate is skipped: Run stays running and the revision does not advance.
    assert rebuild.projection["run"]["state"] == "running"
    assert rebuild.session_revision == 1
  end

  test "blocks a conflicting duplicate idempotency key at its boundary", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3)

    JB.insert_entry_row(store.conn, %{
      session_id: d.session.id,
      sequence: 100,
      revision: 2,
      type: "run_transitioned/v1",
      payload: %{"run" => %{"from" => "running", "to" => "failed"}},
      idempotency_key: JB.id(:idempotency, 3),
      request_digest: "sha256:different"
    })

    assert {:error, %{code: :idempotency_conflict, boundary: 100}} =
             Replay.rebuild(store.conn, d.session.id)
  end

  test "blocks a revision discontinuity at its boundary", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3)

    # Corrupt the second entry's revision to create a gap.
    Kiln.Store.Connection.query!(
      store.conn,
      "UPDATE journal_entries SET session_revision = 5 WHERE session_revision = 1"
    )

    assert {:error, %{code: :revision_discontinuity, detail: %{expected: 1, got: 5}}} =
             Replay.rebuild(store.conn, d.session.id)
  end

  test "blocks a corrupt payload at its boundary", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    # Tamper the payload text while leaving the stored digest unchanged.
    Kiln.Store.Connection.query!(
      store.conn,
      ~s|UPDATE journal_entries SET payload = '{"tampered":true}' WHERE session_revision = 0|
    )

    assert {:error, %{code: :corrupt_payload, detail: %{reason: :digest_mismatch}}} =
             Replay.rebuild(store.conn, d.session.id)
  end

  test "blocks an invalid transition recorded in the journal", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    JB.insert_entry_row(store.conn, %{
      session_id: d.session.id,
      sequence: 100,
      revision: 1,
      type: "run_transitioned/v1",
      payload: %{"run" => %{"from" => "ready", "to" => "waiting_for_user"}},
      idempotency_key: JB.id(:idempotency, 7),
      request_digest: JB.digest(7)
    })

    assert {:error, %{code: :invalid_transition, boundary: 100}} =
             Replay.rebuild(store.conn, d.session.id)
  end

  test "transcript records never change the projection", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, before} = Replay.rebuild(store.conn, d.session.id)

    JB.insert_transcript(store.conn, d.session.id, "trx_1", "first note")
    JB.insert_transcript(store.conn, d.session.id, "trx_2", "second note")

    assert {:ok, after_transcripts} = Replay.rebuild(store.conn, d.session.id)
    assert Session.digest(after_transcripts.projection) == Session.digest(before.projection)

    # Transcript ordering is retained separately from work state.
    ids =
      store.conn
      |> Kiln.Store.Connection.query!(
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
