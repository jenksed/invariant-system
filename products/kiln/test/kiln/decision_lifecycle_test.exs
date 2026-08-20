defmodule Kiln.DecisionLifecycleTest do
  @moduledoc """
  Repair A — canonical pending-decision lifecycle tests.

  Covers V1–V8 from the Tier-2 directive:

    V1 — record_pending_decision/2 commits the canonical pending
         decision in production code (not just test helpers).
    V2 — session.query returns the canonical pending decision
         and its decision_context.
    V3 — record_user_decision with canonical refs succeeds.
    V4 — record_user_decision with stale or mismatched refs
         returns a bounded error.
    V5 — after a successful decision, the pending decision is
         cleared and the run returns to :ready.
    V6 — replay/reconstruct produces the same canonical state.
    V7 — canonical state is the live surface; Temper cannot
         retain stale locally cached decision context beyond a
         refresh.

  The tests drive the production workflow (`Kiln.Workflow`) directly
  via a real Store. The `Kiln.Test.JournalBuilder` helpers are
  intentionally NOT used: this fixture builds the Session,
  decisions, and reads purely through the public surface
  (`Workflow.record_pending_decision/2` and
  `Workflow.record_user_decision/2`) so that any wiring defect in
  the production path is exposed.

  Architecture: Kiln.M0 (KILN-M0-03 lane M9 bounded operator
  decision surface).
  """

  use ExUnit.Case, async: false

  alias Kiln.Domain.{Id, ProjectObservation, Session}
  alias Kiln.Store
  alias Kiln.Store.Journal
  alias Kiln.Workflow

  @at ~U[2026-08-19 13:30:00Z]
  @now "2026-08-19T13:30:00Z"
  @fingerprint "sha256:" <> String.duplicate("0", 64)

  setup do
    # Each test gets a guaranteed-unique state directory: the per-call
    # `System.unique_integer/1` counter can collide across separate
    # `mix test` invocations on the same host (it does not survive
    # VM restart and can wrap on long-lived VMs), so we also include
    # the test PID and a wall-clock prefix that change per-process
    # and per-second. The directory is removed on teardown.
    test_id = "#{System.os_time()}-#{inspect(self())}-#{System.unique_integer([:positive])}"
    dir = Path.join(System.tmp_dir!(), "kiln-decision-#{test_id}")
    File.mkdir_p!(dir)
    File.rm_rf!(Path.join(dir, "*"))

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "store_fixture",
        now: @now,
        name: Kiln.Store.Connection
      )

    on_exit(fn ->
      # Idempotent teardown: capture the conn under the named
      # registration and stop whatever is there. ExUnit may have
      # already torn it down by the time on_exit fires.
      case Process.whereis(Kiln.Store.Connection) do
        nil -> :ok
        pid -> try do
          GenServer.stop(pid, :normal, 1000)
        catch
          :exit, _ -> :ok
        end
      end
      File.rm_rf!(dir)
    end)

    %{store: store}
  end

  defp decision_context_fixture(overrides \\ %{}) do
    Map.merge(
      %{
        "plan_ref" => %{
          "id" => "pln_test",
          "digest" => "sha256:" <> String.duplicate("a", 64)
        },
        "patch_ref" => %{
          "id" => "pp_test",
          "digest" => "sha256:" <> String.duplicate("b", 64)
        },
        "result_state_digest" => "sha256:" <> String.duplicate("c", 64),
        "review_ref" => %{
          "id" => "rev_test",
          "digest" => "sha256:" <> String.duplicate("d", 64)
        }
      },
      overrides
    )
  end

  defp decision_fixture(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => "dec_" <> short_token(),
        "subject_kind" => "run",
        "subject_id" => "run_test",
        "subject_revision" => 1,
        "requested_actor" => "kiln:test",
        "permitted_responses" => ["ACCEPT", "REJECT", "REQUEST_REVISION"]
      },
      overrides
    )
  end

  defp short_token do
    16 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  # A canonical decision_id that is NOT the one stored by the current
  # pending decision. Used by V4 to exercise the `:decision_mismatch`
  # error path through Workflow, which validates id format before
  # comparing against the canonical pending decision.
  defp other_decision_id do
    "dec_" <> short_token()
  end

  defp setup_session!(ctx) do
    entropy_fn = fn 16 -> :binary.copy(<<1>>, 16) end

    {:ok, po} =
      ProjectObservation.new(%{
        repository_root: "/test/repo",
        repository_fingerprint: @fingerprint,
        observed_at: @at
      })

    {:ok, %{session: session, task: task, run: run}} =
      Session.start(
        %{
          objective: "Build the feature",
          criteria: ["The feature works"],
          actor_id: "kiln:test",
          project_observation: po,
          started_at: @at
        },
        entropy_source: entropy_fn
      )

    {:ok, idempotency_key} = Id.generate(:idempotency, entropy_fn)
    {:ok, action_id} = Id.generate(:action, entropy_fn)

    action =
      Kiln.Domain.Action.new(%{
        id: action_id,
        session_id: session.id,
        run_id: run.id,
        expected_session_revision: 0,
        idempotency_key: idempotency_key,
        actor_kind: :local_user,
        actor_id: "kiln:test",
        kind: :start_session,
        request_digest: "sha256:" <> String.duplicate("1", 64),
        payload: %{objective: "Build the feature", criteria: ["The feature works"]},
        causation_action_id: nil,
        correlation_id: nil,
        requested_at: @at
      })
      |> elem(1)

    start_entry = %{
      type: "session_started/v1",
      payload_schema: "session_started/v1",
      payload: %{
        "session" => %{"id" => session.id, "state" => "active"},
        "task" => %{"id" => task.id, "state" => "in_progress"},
        "run" => %{"id" => run.id, "state" => "ready", "root_run_id" => run.id},
        "workflow_step" => "intent",
        "objective" => session.objective,
        "criteria" => task.criteria,
        "constraints" => [],
        "exclusions" => [],
        "objective_revision" => 0,
        "criteria_revision" => 0,
        "references" => %{"project_observation_id" => po.id}
      }
    }

    Journal.commit(ctx.store.conn, action, [start_entry], now: @now)

    session
  end

  # Transitions the Run from :ready to :running so the canonical
  # pending_decision_recorded/v1 reducer can take it to :waiting_for_user
  # (the only legal transition into waiting_for_user is from running).
  defp setup_run_in_running!(ctx, session) do
    {:ok, idempotency_key} =
      Id.generate(:idempotency, fn 16 -> :crypto.strong_rand_bytes(16) end)

    {:ok, action_id} =
      Id.generate(:action, fn 16 -> :crypto.strong_rand_bytes(16) end)

    action =
      Kiln.Domain.Action.new(%{
        id: action_id,
        session_id: session.id,
        run_id: session.root_run_id,
        expected_session_revision: 0,
        idempotency_key: idempotency_key,
        actor_kind: :local_user,
        actor_id: "kiln:test",
        kind: :transition_run,
        request_digest: "sha256:" <> String.duplicate("2", 64),
        payload: %{public_relation: "cancel_session", from_state: "ready", to_state: "running"},
        causation_action_id: nil,
        correlation_id: nil,
        requested_at: @at
      })
      |> elem(1)

    entry = %{
      type: "run_transitioned/v1",
      payload_schema: "run_transitioned/v1",
      payload: %{"run" => %{"from" => "ready", "to" => "running"}, "workflow_step" => "investigation"}
    }

    {:ok, _} = Journal.commit(ctx.store.conn, action, [entry], now: @now)
  end

  describe "V1 record_pending_decision/2 commits the canonical pending decision" do
    test "via production code path", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      assert {:ok, %{projection: proj}} = Workflow.query_session(session.id)
      assert proj["run"]["state"] == "running"

      result =
        Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
          decision: decision_fixture(%{"subject_id" => session.root_run_id}),
          decision_context: decision_context_fixture()
        })

      assert {:ok, pending_result} = result
      assert pending_result.session_id == session.id
      assert pending_result.run_state == :waiting_for_user
      assert String.starts_with?(pending_result.decision_id, "dec_")
    end
  end

  describe "V2 session.query exposes the canonical pending decision and decision_context" do
    test "decision_context appears under projection.references.decision_envelope", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:ok, _} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(),
                 decision_context: ctx_decision
               })

      assert {:ok, %{projection: projection}} = Workflow.query_session(session.id)

      assert get_in(projection, ["pending_decision", "id"]) =~ ~r/^dec_/

      assert get_in(projection, ["pending_decision", "permitted_responses"]) == [
               "ACCEPT",
               "REJECT",
               "REQUEST_REVISION"
             ]

      envelope = get_in(projection, ["references", "decision_envelope"])
      assert envelope["plan_ref"] == ctx_decision["plan_ref"]
      assert envelope["patch_ref"] == ctx_decision["patch_ref"]
      assert envelope["result_state_digest"] == ctx_decision["result_state_digest"]
      assert envelope["review_ref"] == ctx_decision["review_ref"]
    end
  end

  describe "V3 record_user_decision succeeds with canonical refs" do
    test "valid decision envelope is committed", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:ok, %{decision_id: decision_id}} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(),
                 decision_context: ctx_decision
               })

      assert {:ok, user_result} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 2,
                 decision_id: decision_id,
                 response: "ACCEPT",
                 plan_ref: ctx_decision["plan_ref"],
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })

      assert user_result.run_state == :ready
      assert user_result.response == "ACCEPT"
      assert user_result.decision_id == decision_id
    end
  end

  describe "V4 record_user_decision rejects mismatched bounded refs" do
    test "wrong plan_ref is rejected with decision_context_mismatch", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:ok, %{decision_id: decision_id}} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(),
                 decision_context: ctx_decision
               })

      tampered_plan_ref = %{
        "id" => "pln_attacker",
        "digest" => "sha256:" <> String.duplicate("f", 64)
      }

      assert {:error, %Kiln.Domain.Error{code: :decision_context_mismatch} = err} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 2,
                 decision_id: decision_id,
                 response: "ACCEPT",
                 plan_ref: tampered_plan_ref,
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })

      fields = err.details.fields
      assert Enum.any?(fields, &(&1.field == "plan_ref"))
    end

    test "wrong decision_id is rejected with decision_mismatch", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:ok, _} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(),
                 decision_context: ctx_decision
               })

      assert {:error, %Kiln.Domain.Error{code: :decision_mismatch}} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 2,
                 decision_id: other_decision_id(),
                 response: "ACCEPT",
                 plan_ref: ctx_decision["plan_ref"],
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })
    end

    test "no pending decision is rejected with decision_not_pending", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:error, %Kiln.Domain.Error{code: :decision_not_pending}} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 1,
                 decision_id: other_decision_id(),
                 response: "ACCEPT",
                 plan_ref: ctx_decision["plan_ref"],
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })
    end

    test "response not permitted is rejected by the journal reducer", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      # The decision restricts permitted_responses to a strict subset
      # of the global whitelist so a format-valid response (REJECT)
      # is rejected by the journal reducer as not permitted by THIS
      # decision, exercising the `:decision_response_not_permitted`
      # path through the journal (Reducer.response_permitted/2).
      assert {:ok, %{decision_id: decision_id}} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(%{"permitted_responses" => ["ACCEPT"]}),
                 decision_context: ctx_decision
               })

      assert {:error, %Kiln.Domain.Error{code: :decision_response_not_permitted}} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 2,
                 decision_id: decision_id,
                 response: "REJECT",
                 plan_ref: ctx_decision["plan_ref"],
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })
    end
  end

  describe "V5 user_decision consumes the pending decision and clears canonical state" do
    test "after a valid decision the run is :ready and pending_decision is nil", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:ok, %{decision_id: decision_id}} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(),
                 decision_context: ctx_decision
               })

      assert {:ok, _} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 2,
                 decision_id: decision_id,
                 response: "ACCEPT",
                 plan_ref: ctx_decision["plan_ref"],
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })

      assert {:ok, %{projection: projection}} = Workflow.query_session(session.id)
      assert projection["run"]["state"] == "ready"
      assert projection["pending_decision"] == nil
      assert get_in(projection, ["references", "decision_envelope"]) == nil
    end
  end

  describe "V6 replay after restart reconstructs canonical state" do
    test "pending_decision and decision_envelope are reconstructed from the journal", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:ok, %{decision_id: _decision_id}} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(),
                 decision_context: ctx_decision
               })

      assert {:ok, %{projection: before_replay}} = Workflow.query_session(session.id)

      GenServer.stop(ctx.store.conn, :normal, 1000)

      {:ready, reopened} =
        Store.start(path: ctx.store.state_path, now: @now, name: Kiln.Store.Connection)

      on_exit(fn ->
        case Process.whereis(Kiln.Store.Connection) do
          nil -> :ok
          pid -> try do
            GenServer.stop(pid, :normal, 1000)
          catch
            :exit, _ -> :ok
          end
        end
      end)

      assert {:ok, %{projection: after_replay}} = Workflow.query_session(session.id)
      assert after_replay["pending_decision"] == before_replay["pending_decision"]

      envelope_before = get_in(before_replay, ["references", "decision_envelope"])
      envelope_after = get_in(after_replay, ["references", "decision_envelope"])
      assert envelope_after == envelope_before
      assert envelope_after["plan_ref"] == ctx_decision["plan_ref"]
      assert envelope_after["patch_ref"] == ctx_decision["patch_ref"]
      assert envelope_after["result_state_digest"] == ctx_decision["result_state_digest"]
      assert envelope_after["review_ref"] == ctx_decision["review_ref"]
    end
  end

  describe "V7 stale local decision context cannot be acted upon" do
    test "advancing the canonical session rejects the old decision envelope", ctx do
      session = setup_session!(ctx)
      setup_run_in_running!(ctx, session)

      ctx_decision = decision_context_fixture()

      assert {:ok, %{decision_id: decision_id}} =
               Workflow.record_pending_decision(session.id, %{
                  actor_id: "kiln:test",
                  expected_session_revision: 1,
                 decision: decision_fixture(),
                 decision_context: ctx_decision
               })

      # Consume the first pending decision so the canonical Run returns
      # to :ready and a fresh pending decision can be recorded. This is
      # the canonical way the session advances: a paired
      # `user_decision_recorded/v1` clears the pending envelope.
      assert {:ok, _} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 2,
                 decision_id: decision_id,
                 response: "ACCEPT",
                 plan_ref: ctx_decision["plan_ref"],
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })

      new_ctx = decision_context_fixture(%{
        "result_state_digest" => "sha256:" <> String.duplicate("9", 64)
      })

      assert {:ok, _} =
               Workflow.resume_session(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 3
               })

      assert {:ok, %{decision_id: new_decision_id}} =
               Workflow.record_pending_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 4,
                 decision: decision_fixture(%{"subject_revision" => 2}),
                 decision_context: new_ctx
               })

      assert decision_id != new_decision_id

      # The stale envelope from the first pending decision must be
      # rejected with :decision_mismatch because the canonical session
      # has advanced to a new pending decision.
      assert {:error, %Kiln.Domain.Error{code: :decision_mismatch}} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 5,
                 decision_id: decision_id,
                 response: "ACCEPT",
                 plan_ref: ctx_decision["plan_ref"],
                 patch_ref: ctx_decision["patch_ref"],
                 result_state_digest: ctx_decision["result_state_digest"],
                 review_ref: ctx_decision["review_ref"]
               })

      assert {:ok, _} =
               Workflow.record_user_decision(session.id, %{
                 actor_id: "kiln:test",
                 expected_session_revision: 5,
                 decision_id: new_decision_id,
                 response: "ACCEPT",
                 plan_ref: new_ctx["plan_ref"],
                 patch_ref: new_ctx["patch_ref"],
                 result_state_digest: new_ctx["result_state_digest"],
                 review_ref: new_ctx["review_ref"]
               })
    end
  end
end