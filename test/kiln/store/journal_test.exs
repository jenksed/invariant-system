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

    state_path = Path.join(dir, "state.sqlite3")

    {:ready, store} =
      Store.start(path: state_path, store_id: "store_fixture", now: @now)

    entropy = fn 16 -> :binary.copy(<<1>>, 16) end
    {:ok, po} = ProjectObservation.new(observation(), entropy)

    {:ok, %{session: session, task: task, run: run}} =
      Session.start(intent(po), entropy_source: entropy)

    {:ok, conn: store.conn, session: session, task: task, run: run, path: state_path}
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

  # -- precondition: Store-owned transaction guard --

  describe ":no_existing_session precondition" do
    test "a fresh start_session commit with no existing Session commits normally", ctx do
      {:ok, action} = start_action(ctx, idem(11), @digest_a)

      assert {:ok, result} =
               Journal.commit(ctx.conn, action, start_entries(ctx),
                 now: @now,
                 precondition: :no_existing_session
               )

      assert result.status == :committed
      assert count(ctx.conn, "journal_entries") == 1
      assert count(ctx.conn, "action_commits") == 1
      assert count(ctx.conn, "session_projections") == 1
    end

    test "a second distinct start commit with the precondition rolls back with a Store error",
         ctx do
      {:ok, first_action} = start_action(ctx, idem(12), @digest_a)

      assert {:ok, _} =
               Journal.commit(ctx.conn, first_action, start_entries(ctx),
                 now: @now,
                 precondition: :no_existing_session
               )

      # Same precondition, different idempotency key, same fixture.
      {:ok, second_action} = start_action(ctx, idem(13), @digest_b)

      assert {:error, %Kiln.Store.Error{class: :precondition, code: :session_already_exists}} =
               Journal.commit(ctx.conn, second_action, start_entries(ctx),
                 now: @now,
                 precondition: :no_existing_session
               )

      # Zero new writes — the rollback must be total.
      assert count(ctx.conn, "journal_entries") == 1
      assert count(ctx.conn, "action_commits") == 1
      assert count(ctx.conn, "session_projections") == 1
    end

    test "the same idempotency key still replays even with the precondition set", ctx do
      {:ok, action} = start_action(ctx, idem(14), @digest_a)

      assert {:ok, _first} =
               Journal.commit(ctx.conn, action, start_entries(ctx),
                 now: @now,
                 precondition: :no_existing_session
               )

      # Retry of the same key — must replay, not fail the precondition.
      assert {:ok, replay} =
               Journal.commit(ctx.conn, action, start_entries(ctx),
                 now: @now,
                 precondition: :no_existing_session
               )

      assert replay.status == :replayed
      assert count(ctx.conn, "journal_entries") == 1
      assert count(ctx.conn, "action_commits") == 1
    end

    test "an unsupported precondition atom is rejected before any transaction opens",
         ctx do
      {:ok, action} = start_action(ctx, idem(15), @digest_a)

      assert {:error, %Kiln.Store.Error{class: :precondition, code: :unsupported_precondition}} =
               Journal.commit(ctx.conn, action, start_entries(ctx),
                 now: @now,
                 precondition: :unknown_atom
               )

      assert count(ctx.conn, "journal_entries") == 0
      assert count(ctx.conn, "action_commits") == 0
      assert count(ctx.conn, "session_projections") == 0
    end

    test "passing nil precondition is equivalent to omitting it", ctx do
      # Without the precondition, a second commit attempt for a Session
      # that already exists is rejected by the reducer (the session_id
      # is already recorded as started), not by the precondition. The
      # precondition only fires when the caller explicitly opts in via
      # `:no_existing_session`; `nil` and omission are equivalent.
      {:ok, action} = start_action(ctx, idem(16), @digest_a)

      assert {:ok, _} =
               Journal.commit(ctx.conn, action, start_entries(ctx),
                 now: @now,
                 precondition: nil
               )

      assert count(ctx.conn, "journal_entries") == 1
    end
  end

  # -- precondition: independent SQLite connection contention --

  describe "independent SQLite connection contention" do
    test "two independent Store connections to the same DB file produce exactly one Session",
         ctx do
      # Open a second, independent Store connection to the same DB file
      # the test setup opened. The two connections run on independent
      # Exqlite handles; neither shares an Elixir process or a
      # DBConnection pool with the other. SQLite's file-level
      # writer-lock serialization is the only mechanism coordinating
      # them. This is the architecture-level proof of the
      # one-Session invariant; the same-connection Task test only
      # exercises concurrent Workflow callers through one pool.
      path = ctx.path

      {:ready, second_store} =
        Store.start(path: path, store_id: "store_writer_b", now: @now)

      try do
        # Both connections share a synchronization barrier so they
        # pass their idempotency-key classifier before either acquires
        # the IMMEDIATE write lock. The first to acquire the lock
        # commits; the second observes the committed session inside
        # its own IMMEDIATE transaction and rolls back via the
        # `:no_existing_session` precondition.
        parent = self()
        barrier_a = :erlang.unique_integer([:positive])
        barrier_b = :erlang.unique_integer([:positive])

        task_a =
          Task.async(fn ->
            send(parent, {:ready, self(), barrier_a})

            receive do
              :go -> attempt_commit(second_store.conn, ctx, idem(31), @digest_a, barrier_a)
            end
          end)

        task_b =
          Task.async(fn ->
            send(parent, {:ready, self(), barrier_b})

            receive do
              :go -> attempt_commit(second_store.conn, ctx, idem(32), @digest_b, barrier_b)
            end
          end)

        # Wait until both tasks are inside their pre-Write sections,
        # then release both simultaneously.
        receive do
          {:ready, _, ^barrier_a} ->
            receive do
              {:ready, _, ^barrier_b} ->
                send(task_a.pid, :go)
                send(task_b.pid, :go)
            end
        end

        result_a = Task.await(task_a)
        result_b = Task.await(task_b)

        outcomes = [result_a, result_b]
        successes = Enum.filter(outcomes, &match?({:ok, _}, &1))
        rejections = Enum.filter(outcomes, &match?({:error, _}, &1))

        # Exactly one commit, exactly one rejection. The rejection
        # is a typed Store error from the precondition path; the
        # second writer never produces arbitrary terms.
        assert length(successes) == 1,
               "exactly one independent-connection start must commit; got #{inspect(outcomes)}"

        assert length(rejections) == 1,
               "exactly one independent-connection start must be rejected; got #{inspect(outcomes)}"

        [{:error, %Kiln.Store.Error{class: :precondition, code: :session_already_exists}}] =
          rejections

        # Read durable counts via the test-setup connection. Both
        # connections see the same committed state once the IMMEDIATE
        # locks release.
        entries_count = count(ctx.conn, "journal_entries")
        commits_count = count(ctx.conn, "action_commits")
        projections_count = count(ctx.conn, "session_projections")

        assert entries_count == 1,
               "exactly one session_started entry must persist; got journal_entries=#{entries_count}, " <>
                 "action_commits=#{commits_count}, session_projections=#{projections_count}, " <>
                 "successes=#{length(successes)}, rejections=#{length(rejections)}, " <>
                 "outcomes=#{inspect(outcomes)}"

        assert commits_count == 1
        assert projections_count == 1
      after
        GenServer.stop(second_store.conn, :normal, 1_000)
      end
    end
  end

  defp attempt_commit(conn, ctx, idem_byte, digest, _barrier) do
    {:ok, action} = start_action(ctx, idem_byte, digest)

    Journal.commit(conn, action, start_entries(ctx),
      now: @now,
      precondition: :no_existing_session
    )
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
