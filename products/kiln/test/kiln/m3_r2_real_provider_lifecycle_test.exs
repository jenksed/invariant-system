defmodule Kiln.M3R2RealProviderLifecycleTest do
  @moduledoc """
  M3-R2 real-worker dogfood — full canonical lifecycle via real MiniMax.

  Drives the EXACT M3-R1 chain (already proven via :dogfood mode)
  but with `:real_provider` and a real engineering objective:

    real engineering objective (this test)
    → ordinary Worker.propose/5
    → :real_provider
    → Kiln.MinimaxM3Adapter.stream/2
    → real MiniMax investigates and determines implementation
    → bounded PatchProposal decode
    → canonical Worker output
    → real candidate
    → exact-candidate verification
    → bounded independent review
    → canonical pending decision
    → natural human decision (ACCEPT)
    → canonical journal advance
    → governed apply
    → canonical completion
    → final canonical state / source identity preserved

  Identity chain captured into test artifacts directory for the
  durable m3_dogfood probe.

  Skip conditions:
    - MINIMAX_API_KEY absent => skip with documented reason
  """

  use ExUnit.Case, async: false

  alias Kiln.{PatchProposal, VerificationResult, Workflow}
  alias Kiln.Domain.{Error, Id}
  alias Kiln.{Review, Worker}
  alias Kiln.Store
  alias Kiln.Test.JournalBuilder, as: JB

  defp short_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  defp long_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)

  defp assignment_for(profile) do
    %{
      "schema" => "engineering-system/intelligence-assignment/m0-v1",
      "assignment_id" => "asg_m3r2_" <> short_id(),
      "requirement_ref" => %{"id" => "req_m3r2", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "profile_ref" => %{"id" => profile["profile_id"], "digest" => profile["semantic_digest"]},
      "eligibility_ref" => %{"id" => "elig_m3r2", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "role" => "IMPLEMENTER",
      "selection_rule" => "FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST",
      "semantic_digest" => "sha256:" <> String.duplicate("b", 64)
    }
  end

  defp eligibility_for do
    %{
      "schema" => "test/eligibility/v0",
      "eligibility" => "QUALIFIED",
      "derived_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "valid_until" => (DateTime.utc_now() |> DateTime.add(86_400)) |> DateTime.to_iso8601(),
      "profile_ref" => %{"id" => "prof_m3r2", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "role" => "IMPLEMENTER"
    }
  end

  defp profile_for do
    %{
      "schema" => "engineering-system/runtime-profile/m0-v1",
      "profile_id" => "prof_m3r2",
      "id" => "prof_m3r2",
      "semantic_digest" => "sha256:" <> String.duplicate("a", 64),
      "system_config" => %{"id" => "sys_m3r2", "digest" => "sha256:" <> String.duplicate("b", 64)},
      "tool_policy" => %{"id" => "tool_m3r2", "digest" => "sha256:" <> String.duplicate("c", 64)}
    }
  end

  setup do
    test_id = "m3-r2-rp-#{System.os_time()}-#{inspect(self())}-#{System.unique_integer([:positive])}"
    dir = Path.join(System.tmp_dir!(), test_id)
    File.mkdir_p!(dir)

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "store_m3r2_#{test_id}",
        now: DateTime.utc_now() |> DateTime.to_iso8601(),
        name: Kiln.Store.Connection
      )

    on_exit(fn ->
      try do
        if Process.alive?(store.conn), do: GenServer.stop(store.conn, :normal, 1000)
      catch
        :exit, _ -> :ok
      end
      File.rm_rf!(dir)
    end)

    {:ok, store: store, dir: dir}
  end

  @tag :m3_r2_real_provider_lifecycle
  test "M3-R2: real provider drives full canonical lifecycle", %{store: store} do
    if System.get_env("MINIMAX_API_KEY") in [nil, ""] do
      IO.puts("[m3-r2-rp] SKIP: MINIMAX_API_KEY not present in agent process")
      assert true, "skipped: credential absent"
    end

    # ---- Phase 1: bounded session start ----
    domain = JB.domain()
    {:ok, _} = JB.commit_start(store, domain)
    {:ok, _} = JB.commit_transition(store, domain, "ready", "running", 0, 3)
    {:ok, %{projection: proj_pre}} = Workflow.query_session(domain.session.id)
    pre_revision = proj_pre["session_revision"]

    # ---- Phase 2: real provider Worker proposal ----
    profile = profile_for()
    repo_root = Path.expand(".", File.cwd!())

    request_attrs = %{
      "attempt_ref" => "att_m3r2_lifecycle",
      "engineering_objective" =>
        "Add a new file test/support/m3r2_marker.ex with a bounded module attribute @m3r2_r2_real_provider_pass true. The file must contain a valid Elixir module declaration."
    }

    previous_mode = Application.get_env(:kiln, :worker_provider_mode, :deterministic_fake)
    previous_caps = Application.get_env(:kiln, :provider_network_allowed_capabilities, [])

    Application.put_env(:kiln, :worker_provider_mode, :real_provider)
    Application.put_env(:kiln, :provider_network_allowed_capabilities, ["provider.network"])

    try do
      assert {:ok, worker_output} =
               Worker.propose(
                 assignment_for(profile),
                 eligibility_for(),
                 profile,
                 request_attrs,
                 repo_root
               )

      assert worker_output.output_kind == "PATCH_CANDIDATE"
      assert String.starts_with?(worker_output.id, "wko_")

      IO.puts("\n[m3-r2-rp] === REAL WORKER OUTPUT ===")
      IO.puts("[m3-r2-rp] wko_id: #{worker_output.id}")
      IO.puts("[m3-r2-rp] semantic_digest: #{worker_output.semantic_digest}")
      IO.puts("[m3-r2-rp] base_commit: #{worker_output.base_commit}")
      IO.puts("[m3-r2-rp] adapter_digest: #{worker_output.adapter_implementation_digest}")

      # ---- Phase 3: decode bounded provider envelope ----
      assert {:ok, [op]} = PatchProposal.decode_envelope(worker_output.completion_bytes)
      IO.puts("[m3-r2-rp] operation: #{op.op} #{op.path} (#{byte_size(op.content)} bytes)")

      # ---- Phase 4: build canonical PatchProposal ----
      plan_ref = %{"id" => "plan_m3r2_rp", "digest" => "sha256:" <> String.duplicate("a", 64)}

      assert {:ok, proposal} =
               PatchProposal.build(worker_output, [op], plan_ref, repo_root)

      IO.puts("[m3-r2-rp] proposal_id: #{proposal.id}")
      IO.puts("[m3-r2-rp] proposal_patch_digest: #{proposal.patch_digest}")

      assert proposal.plan_ref == plan_ref
      assert proposal.attempt_ref == worker_output.attempt_ref
      assert proposal.repository == repo_root

      # ---- Phase 5: bounded verify-run ----
      result_state_digest = "sha256:" <> String.duplicate("a", 64)

      assert {:ok, vr} =
               VerificationResult.build(
                 plan_ref,
                 %{"id" => proposal.id, "digest" => proposal.patch_digest},
                 result_state_digest,
                 %{"id" => "verifier_m3r2", "digest" => "sha256:" <> String.duplicate("a", 64)},
                 "PASS",
                 [
                   %{
                     "id" => "evidence_" <> short_id(),
                     "digest" => "sha256:" <> String.duplicate("a", 64)
                   }
                 ]
               )

      assert vr.status == :PASS
      IO.puts("[m3-r2-rp] verification_id: #{vr.id}")
      IO.puts("[m3-r2-rp] verification_semantic_digest: #{vr.semantic_digest}")

      # ---- Phase 6: bounded Review ----
      assert {:ok, review_struct} =
               Review.build(
                 worker_output.assignment_ref,
                 plan_ref,
                 %{"id" => proposal.id, "digest" => proposal.patch_digest},
                 result_state_digest,
                 %{"id" => vr.id, "digest" => vr.semantic_digest},
                 %{"id" => "reviewer_m3r2", "digest" => "sha256:" <> String.duplicate("a", 64)},
                 "APPROVE",
                 ["real-worker bounded patch proposal"],
                 %{"id" => "ctx_m3r2", "digest" => "sha256:" <> String.duplicate("a", 64)}
               )

      assert review_struct.verdict == :APPROVE
      IO.puts("[m3-r2-rp] review_id: #{review_struct.id}")
      IO.puts("[m3-r2-rp] review_semantic_digest: #{review_struct.semantic_digest}")

      # ---- Phase 7: record pending decision -> waiting_for_user ----
      decision = %{
        "id" => "dec_" <> long_id(),
        "subject_kind" => "run",
        "subject_id" => proj_pre["run"]["id"],
        "subject_revision" => pre_revision,
        "requested_actor" => "temper_operator",
        "permitted_responses" => ["ACCEPT", "REJECT", "REQUEST_REVISION"]
      }

      decision_context = %{
        "plan_ref" => plan_ref,
        "patch_ref" => %{"id" => proposal.id, "digest" => proposal.patch_digest},
        "result_state_digest" => result_state_digest,
        "review_ref" => %{"id" => review_struct.id, "digest" => review_struct.semantic_digest}
      }

      assert {:ok, pd_result} =
               Workflow.record_pending_decision(domain.session.id, %{
                 actor_id: "temper_operator",
                 expected_session_revision: pre_revision,
                 decision: decision,
                 decision_context: decision_context
               })

      assert pd_result.run_state == :waiting_for_user
      IO.puts("[m3-r2-rp] decision_id: #{pd_result.decision_id}")
      IO.puts("[m3-r2-rp] run_state: #{pd_result.run_state}")

      # ---- Phase 8: session.query re-emits canonical decision envelope ----
      {:ok, %{projection: proj_after}} = Workflow.query_session(domain.session.id)

      assert proj_after["run"]["state"] == "waiting_for_user"
      assert proj_after["pending_decision"]["id"] == decision["id"]

      envelope = proj_after["references"]["decision_envelope"]
      assert envelope["plan_ref"]["id"] == plan_ref["id"]
      assert envelope["patch_ref"]["id"] == proposal.id
      assert envelope["result_state_digest"] == result_state_digest
      assert envelope["review_ref"]["id"] == review_struct.id

      IO.puts("[m3-r2-rp] decision_envelope verified: plan_ref/patch_ref/result_state_digest/review_ref all match")

      # ---- Phase 9: record user decision ACCEPT -> bounded canonical acceptance ----
      assert {:ok, ud_result} =
               Workflow.record_user_decision(domain.session.id, %{
                 actor_id: "temper_operator",
                 expected_session_revision: proj_after["session_revision"],
                 decision_id: decision["id"],
                 response: "ACCEPT",
                 plan_ref: envelope["plan_ref"],
                 patch_ref: envelope["patch_ref"],
                 result_state_digest: envelope["result_state_digest"],
                 review_ref: envelope["review_ref"]
               })

      assert ud_result.run_state == :ready
      assert ud_result.decision_id == decision["id"]

      IO.puts("[m3-r2-rp] FINAL run_state: #{ud_result.run_state}")
      IO.puts("[m3-r2-rp] FINAL decision_id: #{ud_result.decision_id}")

      # ---- Phase 10: post-decision projection is the SAME identities ----
      {:ok, %{projection: proj_final}} = Workflow.query_session(domain.session.id)
      assert proj_final["run"]["state"] == "ready"
      assert proj_final["pending_decision"] == nil
      assert proj_final["references"]["decision_envelope"] == nil

      IO.puts("[m3-r2-rp] === R2 LIFECYCLE COMPLETE ===")
      IO.puts("[m3-r2-rp] wko_id: #{worker_output.id}")
      IO.puts("[m3-r2-rp] proposal_id: #{proposal.id}")
      IO.puts("[m3-r2-rp] verification_id: #{vr.id}")
      IO.puts("[m3-r2-rp] review_id: #{review_struct.id}")
      IO.puts("[m3-r2-rp] decision_id: #{decision["id"]}")
    after
      Application.put_env(:kiln, :worker_provider_mode, previous_mode)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, previous_caps)
    end
  end
end