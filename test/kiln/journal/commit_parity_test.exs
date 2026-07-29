defmodule Kiln.Journal.CommitParityTest do
  @moduledoc """
  Commit and replay share one entry decoder and one workflow-step authority.
  An entry that cannot replay cannot commit, and the accepted workflow steps are
  exactly `Kiln.Domain.Run.workflow_steps/0`.
  """
  use ExUnit.Case, async: true

  alias Kiln.Domain.Run
  alias Kiln.Journal.{Entry, Replay}
  alias Kiln.Projections.{Session, Store}
  alias Kiln.Store.Connection
  alias Kiln.Test.JournalBuilder, as: JB

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-parity-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    store = JB.store(Path.join(dir, "state.sqlite3"))
    on_exit(fn -> stop(store.conn) end)

    d = JB.domain()
    {:ok, store: store, d: d}
  end

  test "a decoder-invalid entry does not commit and writes nothing", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    before_entries = count(store.conn, "journal_entries")
    before_commits = count(store.conn, "action_commits")
    before_projection = Session.digest(Store.load(store.conn, d.session.id))

    invalid =
      JB.entry("run_transitioned/v1", %{
        "run" => %{"from" => "ready", "to" => "running"},
        "workflow_step" => "execution"
      })

    assert {:error,
            %{class: :unknown, code: :invalid_entry, details: %{type: "run_transitioned/v1"}}} =
             JB.commit_entries(store, d, :transition_run, 0, 3, [invalid])

    assert count(store.conn, "journal_entries") == before_entries
    assert count(store.conn, "action_commits") == before_commits
    assert Session.digest(Store.load(store.conn, d.session.id)) == before_projection
  end

  test "a valid entry produces the same commit-time and replay-time projection", %{
    store: store,
    d: d
  } do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, committed} = JB.commit_transition(store, d, "ready", "running", 0, 3, "application")

    assert {:ok, report} = Replay.rebuild(store.conn, d.session.id)
    assert Session.digest(report.projection) == Session.digest(committed.projection)
  end

  test "the journal decoder accepts exactly the domain workflow steps" do
    for step <- Run.workflow_steps() do
      assert {:ok, _} =
               Entry.decode("run_transitioned/v1", %{
                 "run" => %{"from" => "ready", "to" => "running"},
                 "workflow_step" => Atom.to_string(step)
               })
    end

    for bad <- ["execution", "completion"] do
      assert {:error, %{code: :invalid_payload, detail: %{field: "workflow_step"}}} =
               Entry.decode("run_transitioned/v1", %{
                 "run" => %{"from" => "ready", "to" => "running"},
                 "workflow_step" => bad
               })
    end
  end

  test "each accepted workflow step commits and replays", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3, "investigation")
    {:ok, _} = JB.commit_transition(store, d, "running", "ready", 1, 4, "proposal")
    {:ok, _} = JB.commit_transition(store, d, "ready", "running", 2, 5, "application")
    {:ok, _} = JB.commit_transition(store, d, "running", "ready", 3, 6, "verification")
    {:ok, last} = JB.commit_transition(store, d, "ready", "running", 4, 7, "acceptance")

    assert {:ok, report} = Replay.rebuild(store.conn, d.session.id)
    assert report.session_revision == 5
    assert report.projection["workflow_step"] == "acceptance"
    assert Session.digest(report.projection) == Session.digest(last.projection)
  end

  test "execution and completion are rejected at commit", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    for bad <- ["execution", "completion"] do
      entry =
        JB.entry("run_transitioned/v1", %{
          "run" => %{"from" => "ready", "to" => "running"},
          "workflow_step" => bad
        })

      assert {:error, %{code: :invalid_entry}} =
               JB.commit_entries(store, d, :transition_run, 0, 3, [entry])
    end

    assert count(store.conn, "journal_entries") == 1
  end

  test "a session start with contradictory states does not commit", %{store: store, d: d} do
    invalid_start =
      JB.entry("session_started/v1", %{
        "session" => %{"id" => d.session.id, "state" => "completed"},
        "task" => %{"id" => d.task.id, "state" => "satisfied"},
        "run" => %{"id" => d.run.id, "state" => "orphaned", "root_run_id" => d.run.root_run_id},
        "workflow_step" => "acceptance",
        "objective_revision" => 0,
        "criteria_revision" => 0,
        "references" => %{}
      })

    assert {:error, %{class: :unknown, code: :invalid_entry}} =
             JB.commit_entries(store, d, :start_session, 0, 2, [invalid_start])

    assert count(store.conn, "journal_entries") == 0
    assert count(store.conn, "action_commits") == 0
    assert count(store.conn, "session_projections") == 0
  end

  test "a valid duplicate replays before entry decoding runs", %{store: store, d: d} do
    {:ok, _} = JB.commit_start(store, d)

    # Same action identity (idempotency key and digest) as commit_start, but the
    # resubmission carries a decoder-invalid entry. It must replay the stored
    # result, not fail on the regenerated entry.
    duplicate = JB.action(d, :start_session, :local_user, "user:local", 0, 2, [])

    invalid_entry =
      JB.entry("run_transitioned/v1", %{"run" => %{"from" => "nope", "to" => "nope"}})

    assert {:ok, %{status: :replayed}} =
             Kiln.Store.Journal.commit(store.conn, duplicate, [invalid_entry],
               now: "2026-07-29T13:30:00Z"
             )

    assert count(store.conn, "journal_entries") == 1
    assert count(store.conn, "action_commits") == 1
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
