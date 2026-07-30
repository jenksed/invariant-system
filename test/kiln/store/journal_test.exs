defmodule Kiln.Store.JournalTest do
  use ExUnit.Case, async: true

  alias Kiln.Domain.{Action, ProjectObservation, Session}
  alias Kiln.Store
  alias Kiln.Store.{Connection, Journal}

  @now "2026-07-29T13:30:00Z"
  @at ~U[2026-07-29 13:30:00Z]
  @digest_a "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  @digest_b "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  @fingerprint "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-journal-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_fixture", now: @now)

    entropy = fn 16 -> :binary.copy(<<1>>, 16) end
    {:ok, po} = ProjectObservation.new(observation(), entropy)

    {:ok, %{session: session, task: task, run: run}} =
      Session.start(intent(po), entropy_source: entropy)

    {:ok, conn: store.conn, session: session, task: task, run: run}
  end

  test "commits a session_started action atomically", ctx do
    {:ok, action} = start_action(ctx, idem(2), @digest_a)

    assert {:ok, result} = Journal.commit(ctx.conn, action, start_entries(ctx), now: @now)
    assert result.status == :committed
    assert result.session_revision == 0
    assert is_integer(result.last_sequence)

    assert result.projection["session"]["state"] == "active"
    assert result.projection["run"]["state"] == "ready"

    assert count(ctx.conn, "journal_entries") == 1
    assert count(ctx.conn, "action_commits") == 1
    assert count(ctx.conn, "session_projections") == 1

    assert [["session_started/v1", 0]] =
             Connection.query!(
               ctx.conn,
               "SELECT entry_type, session_revision FROM journal_entries"
             )
  end

  test "advances the Session revision on a later action", ctx do
    {:ok, start} = start_action(ctx, idem(2), @digest_a)
    {:ok, _} = Journal.commit(ctx.conn, start, start_entries(ctx), now: @now)

    {:ok, transition} = transition_action(ctx, idem(3), @digest_b, 0)

    assert {:ok, result} =
             Journal.commit(ctx.conn, transition, transition_entries(ctx), now: @now)

    assert result.session_revision == 1
    assert result.projection["run"]["state"] == "running"
    assert count(ctx.conn, "journal_entries") == 2
  end

  test "replays a duplicate identical action without a new entry", ctx do
    {:ok, action} = start_action(ctx, idem(2), @digest_a)
    {:ok, _} = Journal.commit(ctx.conn, action, start_entries(ctx), now: @now)

    assert {:ok, replay} = Journal.commit(ctx.conn, action, start_entries(ctx), now: @now)
    assert replay.status == :replayed
    assert count(ctx.conn, "journal_entries") == 1
    assert count(ctx.conn, "action_commits") == 1
  end

  test "rejects a duplicate replay after the stored journal rows are deleted", ctx do
    {:ok, action} = start_action(ctx, idem(2), @digest_a)
    {:ok, _} = Journal.commit(ctx.conn, action, start_entries(ctx), now: @now)

    # Simulate incomplete durable state: the action commit remains but the
    # journal rows it depends on are gone. A duplicate replay must not succeed
    # by trusting the cached idempotency result alone.
    Connection.query!(ctx.conn, "DELETE FROM journal_entries")

    assert {:error, %{class: :integrity, code: :journal_invalid}} =
             Journal.commit(ctx.conn, action, start_entries(ctx), now: @now)

    # Nothing is appended: the transaction rolled back before any write.
    assert count(ctx.conn, "journal_entries") == 0
    assert count(ctx.conn, "action_commits") == 1
  end

  test "rejects a duplicate replay after the stored journal payload is corrupted", ctx do
    {:ok, action} = start_action(ctx, idem(2), @digest_a)
    {:ok, _} = Journal.commit(ctx.conn, action, start_entries(ctx), now: @now)

    # Tamper the persisted payload so its recorded digest no longer matches.
    Connection.query!(
      ctx.conn,
      ~s|UPDATE journal_entries SET payload = '{"tampered":true}'|
    )

    assert {:error, %{class: :integrity, code: :journal_invalid}} =
             Journal.commit(ctx.conn, action, start_entries(ctx), now: @now)

    # The duplicate must not append a new journal row or a new action commit.
    assert count(ctx.conn, "journal_entries") == 1
    assert count(ctx.conn, "action_commits") == 1
  end

  test "rejects a reused idempotency key with a different request", ctx do
    {:ok, start} = start_action(ctx, idem(2), @digest_a)
    {:ok, _} = Journal.commit(ctx.conn, start, start_entries(ctx), now: @now)

    # Same idempotency key, different action and digest.
    {:ok, conflicting} = transition_action(ctx, idem(2), @digest_b, 0)

    assert {:error, %{class: :idempotency_conflict}} =
             Journal.commit(ctx.conn, conflicting, transition_entries(ctx), now: @now)

    assert count(ctx.conn, "journal_entries") == 1
  end

  test "rejects a stale expected revision and makes no durable change", ctx do
    {:ok, start} = start_action(ctx, idem(2), @digest_a)
    {:ok, _} = Journal.commit(ctx.conn, start, start_entries(ctx), now: @now)

    {:ok, stale} = transition_action(ctx, idem(3), @digest_b, 5)

    assert {:error, %{class: :revision, code: :stale_revision, details: %{current: 0}}} =
             Journal.commit(ctx.conn, stale, transition_entries(ctx), now: @now)

    assert count(ctx.conn, "journal_entries") == 1
    assert count(ctx.conn, "session_projections") == 1
  end

  test "leaves no partial state when the transaction faults", ctx do
    {:ok, action} = start_action(ctx, idem(2), @digest_a)

    assert {:error, %{class: :unknown, code: :transaction_failed}} =
             Journal.commit(ctx.conn, action, start_entries(ctx), now: @now, fault: :boom)

    assert count(ctx.conn, "journal_entries") == 0
    assert count(ctx.conn, "action_commits") == 0
    assert count(ctx.conn, "session_projections") == 0
  end

  # -- helpers --

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
      constraints: ["Do not change dependencies"],
      exclusions: ["No provider access"],
      started_at: @at
    }
  end

  defp start_action(ctx, idempotency_key, digest) do
    Action.new(%{
      id: id(:action, 10),
      session_id: ctx.session.id,
      run_id: ctx.run.id,
      expected_session_revision: 0,
      idempotency_key: idempotency_key,
      actor_kind: :local_user,
      actor_id: "user:local",
      kind: :start_session,
      request_digest: digest,
      payload: %{},
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: @at
    })
  end

  defp transition_action(ctx, idempotency_key, digest, expected) do
    Action.new(%{
      id: id(:action, 11),
      session_id: ctx.session.id,
      run_id: ctx.run.id,
      expected_session_revision: expected,
      idempotency_key: idempotency_key,
      actor_kind: :system,
      actor_id: "kiln:workflow",
      kind: :transition_run,
      request_digest: digest,
      payload: %{from: "ready", to: "running"},
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: @at
    })
  end

  defp start_entries(ctx) do
    [
      %{
        type: "session_started/v1",
        payload_schema: "session_started/v1",
        payload: %{
          "session" => %{"id" => ctx.session.id, "state" => "active"},
          "task" => %{"id" => ctx.task.id, "state" => "in_progress"},
          "run" => %{
            "id" => ctx.run.id,
            "state" => "ready",
            "root_run_id" => ctx.run.root_run_id
          },
          "workflow_step" => "intent",
          "objective" => ctx.session.objective,
          "criteria" => ctx.task.criteria,
          "constraints" => ctx.task.constraints,
          "exclusions" => ctx.task.exclusions,
          "objective_revision" => ctx.session.revision,
          "criteria_revision" => ctx.session.criteria_revision,
          "references" => %{"project_observation_id" => ctx.session.project_observation_id}
        }
      }
    ]
  end

  defp transition_entries(ctx) do
    [
      %{
        type: "run_transitioned/v1",
        payload_schema: "run_transitioned/v1",
        payload: %{
          "run" => %{"id" => ctx.run.id, "from" => "ready", "to" => "running"},
          "workflow_step" => "application"
        }
      }
    ]
  end

  defp count(conn, table) do
    [[n]] = Connection.query!(conn, "SELECT count(*) FROM #{table}")
    n
  end

  defp idem(byte), do: id(:idempotency, byte)

  defp id(kind, byte) do
    {:ok, value} = Kiln.Domain.Id.generate(kind, fn 16 -> :binary.copy(<<byte>>, 16) end)
    value
  end
end
