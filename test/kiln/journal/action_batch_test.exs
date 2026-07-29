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
    exec(conn, "UPDATE journal_entries SET idempotency_key = 'wrong' WHERE session_revision = 1")
    assert {:error, %{code: :idempotency_key_mismatch, boundary: 2}} = rebuild(conn, d)
  end

  test "blocks an entry with a mismatched request digest", %{conn: conn, d: d} do
    exec(conn, "UPDATE journal_entries SET request_digest = 'wrong' WHERE session_revision = 1")
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

  defp rebuild(conn, d), do: Replay.rebuild(conn, d.session.id)
  defp exec(conn, sql), do: Connection.query!(conn, sql)

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
