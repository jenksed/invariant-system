defmodule Kiln.Journal.ActionBatchTest do
  @moduledoc """
  Protected fixtures for action-batch boundary validation. Each case starts from
  a valid committed journal, then tampers one row or commit to prove replay
  blocks at a stable boundary instead of accepting fabricated durable state.
  """
  use ExUnit.Case, async: true

  alias Kiln.Journal.Replay
  alias Kiln.Store.Connection
  alias Kiln.Test.JournalBuilder, as: JB

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-batch-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    store = JB.store(Path.join(dir, "state.sqlite3"))
    on_exit(fn -> stop(store.conn) end)

    d = JB.domain()
    # Two single-entry actions: start (seq 1, rev 0) then transition (seq 2, rev 1).
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3)

    {:ok, conn: store.conn, store: store, d: d}
  end

  test "blocks a journal row with no action commit", %{conn: conn, d: d} do
    exec(conn, "DELETE FROM action_commits WHERE first_sequence = 2")
    assert {:error, %{code: :missing_action_commit, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks an action commit whose rows are missing", %{conn: conn, d: d} do
    exec(conn, "DELETE FROM journal_entries WHERE session_revision = 1")
    assert {:error, %{code: :missing_journal_rows, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks an extra row using an action id outside its declared range", %{conn: conn, d: d} do
    JB.insert_entry_row(conn, %{
      session_id: d.session.id,
      sequence: 100,
      revision: 2,
      type: "criteria_revised/v1",
      payload: %{"criteria_revision" => 1},
      idempotency_key: JB.id(:idempotency, 3),
      request_digest: JB.digest(3),
      action_id: JB.id(:action, 13)
    })

    assert {:error, %{code: :action_boundary_mismatch, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks an entry with a mismatched idempotency key", %{conn: conn, d: d} do
    # Use a valid Kiln-format idempotency key so the equality check fires; an
    # invalid-format value is caught first by the envelope format check.
    exec(
      conn,
      "UPDATE journal_entries SET idempotency_key = '#{JB.id(:idempotency, 99)}' WHERE session_revision = 1"
    )

    assert {:error, %{code: :idempotency_key_mismatch, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks an entry with a mismatched request digest", %{conn: conn, d: d} do
    # Use a valid Kiln-format sha256 digest so the equality check fires; an
    # invalid-format value is caught first by the envelope format check.
    exec(
      conn,
      "UPDATE journal_entries SET request_digest = '#{JB.digest(99)}' WHERE session_revision = 1"
    )

    assert {:error, %{code: :request_digest_mismatch, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks an action commit with an incorrect first sequence", %{conn: conn, d: d} do
    exec(conn, "UPDATE action_commits SET first_sequence = 0 WHERE first_sequence = 2")
    assert {:error, %{code: :action_boundary_mismatch}} = rebuild(conn, d)
  end

  test "blocks an action commit with an incorrect last sequence", %{conn: conn, d: d} do
    exec(conn, "UPDATE action_commits SET last_sequence = 9 WHERE last_sequence = 2")
    assert {:error, %{code: :action_boundary_mismatch, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks when a later action's revision does not follow the prior one", %{conn: conn, d: d} do
    exec(conn, "UPDATE journal_entries SET session_revision = 5 WHERE session_revision = 1")
    assert {:error, %{code: :revision_discontinuity, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks noncontiguous revisions inside one multi-entry action" do
    dir = Path.join(System.tmp_dir!(), "kiln-batch2-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    store = JB.store(Path.join(dir, "state.sqlite3"))
    on_exit(fn -> stop(store.conn) end)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_entries(store, d, :transition_run, 0, 5, JB.two_entry_batch(1))

    # Batch B holds revisions 1 and 2 at sequences 2 and 3; break contiguity.
    exec(store.conn, "UPDATE journal_entries SET session_revision = 7 WHERE sequence = 3")

    assert {:error, %{code: :revision_discontinuity, boundary: 2}} = rebuild(store.conn, d)
  end

  test "blocks a corrupt huge last sequence without materializing the range", %{conn: conn, d: d} do
    # A corrupt enormous last_sequence must return a bounded error, not allocate
    # a range of that size.
    exec(
      conn,
      "UPDATE action_commits SET last_sequence = 9223372036854775800 WHERE first_sequence = 2"
    )

    assert {:error, %{code: :action_boundary_mismatch, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks a text revision without raising", %{conn: conn, d: d} do
    exec(conn, "UPDATE journal_entries SET session_revision = 'zero' WHERE session_revision = 1")
    assert {:error, %{code: :corrupt_revision}} = rebuild(conn, d)
  end

  test "blocks a negative revision without raising", %{conn: conn, d: d} do
    exec(conn, "UPDATE journal_entries SET session_revision = -1 WHERE session_revision = 1")
    assert {:error, %{code: :corrupt_revision}} = rebuild(conn, d)
  end

  test "blocks a non-integer expected revision", %{conn: conn, d: d} do
    exec(
      conn,
      "UPDATE action_commits SET expected_session_revision = 'later' WHERE first_sequence = 2"
    )

    assert {:error, %{code: :corrupt_action_bounds}} = rebuild(conn, d)
  end

  test "blocks an unsupported entry schema", %{conn: conn, d: d} do
    exec(conn, "UPDATE journal_entries SET entry_schema = 'journal_entry/v9' WHERE sequence = 2")
    assert {:error, %{code: :unsupported_entry_schema, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks a payload schema that mismatches the entry type", %{conn: conn, d: d} do
    exec(
      conn,
      "UPDATE journal_entries SET payload_schema = 'criteria_revised/v1' WHERE sequence = 2"
    )

    assert {:error, %{code: :payload_schema_mismatch, boundary: 2}} = rebuild(conn, d)
  end

  # -- Blocker B5: replay must validate persisted envelope IDs and request-digest
  # format. Consistent corruption across `action_commits` and `journal_entries`
  # would otherwise pass equality and be applied as if it were committed truth.

  test "blocks a commit whose action_id is not a valid Kiln opaque id", %{conn: conn, d: d} do
    corrupt(conn, "act_garbage", :action_id)
    assert {:error, %{code: :invalid_action_id, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks a commit whose idempotency_key is not a valid Kiln opaque id",
       %{conn: conn, d: d} do
    corrupt(conn, "wrong", :idempotency_key)
    assert {:error, %{code: :invalid_idempotency_key, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks a commit whose request_digest is not a sha256 digest",
       %{conn: conn, d: d} do
    corrupt(conn, "not-a-hash", :request_digest)
    assert {:error, %{code: :invalid_request_digest, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks a sha1-shaped digest missing the sha256 prefix", %{conn: conn, d: d} do
    # SHA-1 is 40 hex chars with no algorithm prefix.
    corrupt(conn, String.duplicate("a", 40), :request_digest)
    assert {:error, %{code: :invalid_request_digest, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks a sha256 digest missing the colon separator", %{conn: conn, d: d} do
    # 64 hex chars joined directly to the `sha256` prefix without the `:`
    # separator - looks digest-shaped but is structurally invalid.
    corrupt(conn, "sha256" <> String.duplicate("0", 64), :request_digest)
    assert {:error, %{code: :invalid_request_digest, boundary: 2}} = rebuild(conn, d)
  end

  # Regression guard: the unchanged setup must still replay cleanly through the
  # new envelope format check.
  test "replays a batch whose envelope ids and digests are all valid",
       %{conn: conn, d: d} do
    assert {:ok, report} = rebuild(conn, d)
    assert report.action_count == 2
    assert report.entry_count == 2
    assert report.session_revision == 1
  end

  defp rebuild(conn, d), do: Replay.rebuild(conn, d.session.id)
  defp exec(conn, sql), do: Connection.query!(conn, sql)

  # Apply `value` to `field` on both the action commit and the matching journal
  # entry for the transition action (first_sequence = 2, session_revision = 1).
  defp corrupt(conn, value, field) do
    sql = "UPDATE action_commits SET #{field} = ?1 WHERE first_sequence = 2"
    Connection.query!(conn, sql, [value])

    sql = "UPDATE journal_entries SET #{field} = ?1 WHERE session_revision = 1"
    Connection.query!(conn, sql, [value])
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
