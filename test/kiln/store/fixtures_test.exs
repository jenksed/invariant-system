defmodule Kiln.Store.FixturesTest do
  use ExUnit.Case, async: true

  alias Kiln.Domain.{Action, ProjectObservation, Session}
  alias Kiln.Store
  alias Kiln.Store.Journal

  @now "2026-07-29T13:30:00Z"
  @at ~U[2026-07-29 13:30:00Z]
  @fingerprint "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-fixtures-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, dir: dir, path: Path.join(dir, "state.sqlite3")}
  end

  test "integrity-blocks a corrupt store and preserves the file", %{path: path} do
    garbage = :crypto.strong_rand_bytes(4096)
    File.write!(path, garbage)

    assert {:blocked, :integrity_blocked, %{class: :integrity}} = Store.start(path: path)

    # The corrupt file is preserved, not repaired or replaced.
    assert File.read!(path) == garbage
  end

  test "SQLite rejects a nested transaction, so the store relies on one outer transaction", %{
    path: path
  } do
    {:ok, db} = Exqlite.Sqlite3.open(path)
    :ok = Exqlite.Sqlite3.execute(db, "BEGIN IMMEDIATE")

    assert {:error, reason} = Exqlite.Sqlite3.execute(db, "BEGIN IMMEDIATE")
    assert to_string(reason) =~ "within a transaction"

    :ok = Exqlite.Sqlite3.execute(db, "ROLLBACK")
    :ok = Exqlite.Sqlite3.close(db)
  end

  @tag :slow
  test "classifies a busy writer after the accepted timeout", %{path: path} do
    {:ready, store} = Store.start(path: path, store_id: "store_fixture", now: @now)
    {:ok, action, entries} = start_request(store)

    # A second raw connection holds the WAL write lock for the whole attempt.
    {:ok, blocker} = Exqlite.Sqlite3.open(path)
    :ok = Exqlite.Sqlite3.execute(blocker, "BEGIN IMMEDIATE")

    assert {:error, %{class: :busy, code: :store_busy}} =
             Journal.commit(store.conn, action, entries, now: @now)

    :ok = Exqlite.Sqlite3.execute(blocker, "ROLLBACK")
    :ok = Exqlite.Sqlite3.close(blocker)
  end

  defp start_request(store) do
    entropy = fn 16 -> :binary.copy(<<1>>, 16) end
    {:ok, po} = ProjectObservation.new(observation(), entropy)

    {:ok, %{session: session, task: task, run: run}} =
      Session.start(intent(po), entropy_source: entropy)

    {:ok, action} =
      Action.new(%{
        id: id(:action, 10),
        session_id: session.id,
        run_id: run.id,
        expected_session_revision: 0,
        idempotency_key: id(:idempotency, 2),
        actor_kind: :local_user,
        actor_id: "user:local",
        kind: :start_session,
        request_digest: "sha256:" <> String.duplicate("a", 64),
        payload: %{},
        causation_action_id: nil,
        correlation_id: nil,
        requested_at: @at
      })

    entries = [
      %{
        type: "session_started/v1",
        payload_schema: "session_started/v1",
        payload: %{
          "session" => %{"id" => session.id, "state" => "active"},
          "task" => %{"id" => task.id, "state" => "in_progress"},
          "run" => %{"id" => run.id, "state" => "ready", "root_run_id" => run.root_run_id},
          "workflow_step" => "intent",
          "objective_revision" => session.revision,
          "criteria_revision" => session.criteria_revision,
          "references" => %{"project_observation_id" => session.project_observation_id}
        }
      }
    ]

    _ = store
    {:ok, action, entries}
  end

  defp observation do
    %{
      repository_root: "/tmp/kiln-fixture",
      repository_fingerprint: @fingerprint,
      observed_at: @at
    }
  end

  defp intent(po) do
    %{
      project_observation: po,
      objective: "Correct one bounded defect",
      criteria: ["The focused test passes"],
      started_at: @at
    }
  end

  defp id(kind, byte) do
    {:ok, value} = Kiln.Domain.Id.generate(kind, fn 16 -> :binary.copy(<<byte>>, 16) end)
    value
  end
end
