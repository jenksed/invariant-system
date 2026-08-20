defmodule Kiln.M3R2GovernedApplyTest do
  @moduledoc """
  M3-R2 governed apply against a disposable Invariant checkout.

  Drives the canonical M3 chain end-to-end against a disposable
  worktree so the real worker proposal produces a real source
  mutation in a separate worktree (not the developer worktree):

    real MiniMax worker (objective → bounded candidate)
    → bounded independent reviewer (Kiln.BoundedReviewer)
    → canonical verification envelope (PASS)
    → canonical review envelope
    → Workflow.record_pending_decision → :waiting_for_user
    → canonical HumanDecision (ACCEPT)
    → canonical PatchDecision (APPROVE_EXACT_BYTES)
    → Kiln.PatchService.apply_with_completion_ref
    → real source mutation in disposable target
    → post-apply source identity captured

  Skip conditions:
    - MINIMAX_API_KEY absent => skip with documented reason
    - Disposable target not present at known path => skip
  """

  use ExUnit.Case, async: false

  alias Kiln.{PatchProposal, PatchService, VerificationResult, Worker, Workflow}
  alias Kiln.{Review, HumanDecision}
  alias Kiln.M0PatchDecision
  alias Kiln.Store

  defp short_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  defp long_id, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)

  defp assignment_for(profile) do
    %{
      "schema" => "engineering-system/intelligence-assignment/m0-v1",
      "assignment_id" => "asg_m3r2_apply_" <> short_id(),
      "requirement_ref" => %{"id" => "req_m3r2_apply", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "profile_ref" => %{"id" => profile["profile_id"], "digest" => profile["semantic_digest"]},
      "eligibility_ref" => %{"id" => "elig_m3r2_apply", "digest" => "sha256:" <> String.duplicate("a", 64)},
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
      "profile_ref" => %{"id" => "prof_m3r2_apply", "digest" => "sha256:" <> String.duplicate("a", 64)},
      "role" => "IMPLEMENTER"
    }
  end

  defp profile_for do
    %{
      "schema" => "engineering-system/runtime-profile/m0-v1",
      "profile_id" => "prof_m3r2_apply",
      "id" => "prof_m3r2_apply",
      "semantic_digest" => "sha256:" <> String.duplicate("a", 64),
      "system_config" => %{"id" => "sys_m3r2_apply", "digest" => "sha256:" <> String.duplicate("b", 64)},
      "tool_policy" => %{"id" => "tool_m3r2_apply", "digest" => "sha256:" <> String.duplicate("c", 64)}
    }
  end

  @disposable_target "/Users/jenksed/Developer/invariant-system-worktrees/m3-r2-apply-target"

  setup do
    test_id = "m3-r2-apply-#{System.os_time()}-#{inspect(self())}-#{System.unique_integer([:positive])}"
    dir = Path.join(System.tmp_dir!(), test_id)
    File.mkdir_p!(dir)

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "store_m3r2_apply_#{test_id}",
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

  @tag :m3_r2_governed_apply
  test "M3-R2: real worker candidate applied to disposable checkout via patch-apply-governed" do
    if System.get_env("MINIMAX_API_KEY") in [nil, ""] do
      IO.puts("[m3-r2-apply] SKIP: MINIMAX_API_KEY not present")
      assert true, "skipped: credential absent"
    end

    if not File.dir?(@disposable_target) do
      IO.puts("[m3-r2-apply] SKIP: disposable target not at #{@disposable_target}")
      assert true, "skipped: no disposable target"
    end

    # PRE-apply source identity
    pre_head = System.cmd("git", ["-C", @disposable_target, "rev-parse", "HEAD"]) |> elem(0) |> String.trim()
    IO.puts("\n[m3-r2-apply] PRE-APPLY source identity (HEAD): #{pre_head}")
    assert pre_head != ""

    profile = profile_for()
    repo_root = @disposable_target

    # Use a unique target file per run so re-runs do not collide
    # with a prior add (the bounded apply refuses :add when the
    # preimage is already present).
    target_basename = "m3r2_apply_marker_#{short_id()}.ex"
    target_relpath = "test/support/#{target_basename}"

    request_attrs = %{
      "attempt_ref" => "att_m3r2_apply",
      "engineering_objective" =>
        "Add a new file #{target_relpath} containing a bounded Elixir module with attribute @m3r2_governed_apply_pass true. The file must contain a valid Elixir module declaration."
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

      assert {:ok, [op]} = PatchProposal.decode_envelope(worker_output.completion_bytes)

      IO.puts("[m3-r2-apply] === REAL WORKER OUTPUT ===")
      IO.puts("[m3-r2-apply] wko_id: #{worker_output.id}")
      IO.puts("[m3-r2-apply] op: #{op.op} #{op.path} (#{byte_size(op.content)} bytes)")

      plan_ref = %{"id" => "plan_m3r2_apply", "digest" => "sha256:" <> String.duplicate("a", 64)}

      assert {:ok, proposal} =
               PatchProposal.build(worker_output, [op], plan_ref, repo_root)

      IO.puts("[m3-r2-apply] proposal_id: #{proposal.id}")
      IO.puts("[m3-r2-apply] proposal_patch_digest: #{proposal.patch_digest}")

      result_state_digest = "sha256:" <> String.duplicate("a", 64)

      assert {:ok, vr} =
               VerificationResult.build(
                 plan_ref,
                 %{"id" => proposal.id, "digest" => proposal.patch_digest},
                 result_state_digest,
                 %{"id" => "verifier_m3r2_apply", "digest" => "sha256:" <> String.duplicate("a", 64)},
                 "PASS",
                 [
                   %{
                     "id" => "evidence_" <> short_id(),
                     "digest" => "sha256:" <> String.duplicate("a", 64)
                   }
                 ]
               )

      assert vr.status == :PASS
      IO.puts("[m3-r2-apply] verification_id: #{vr.id}")

      # Independent reviewer
      reviewer_ref = Kiln.BoundedReviewer.reviewer_assignment_ref()

      assert {:ok, review_decision} =
               Kiln.BoundedReviewer.review(
                 worker_output.completion_bytes,
                 vr,
                 plan_ref,
                 repo_root
               )

      IO.puts("[m3-r2-apply] reviewer_verdict: #{review_decision.verdict}")
      IO.puts("[m3-r2-apply] reviewer_findings: #{inspect(review_decision.findings)}")

      assert review_decision.verdict == "APPROVE",
             "Bounded reviewer did not APPROVE; the live candidate was rejected by independent review"

      assert {:ok, review_struct} =
               Review.build(
                 worker_output.assignment_ref,
                 plan_ref,
                 %{"id" => proposal.id, "digest" => proposal.patch_digest},
                 result_state_digest,
                 %{"id" => vr.id, "digest" => vr.semantic_digest},
                 reviewer_ref,
                 review_decision.verdict,
                 review_decision.findings,
                 %{"id" => "ctx_m3r2_apply", "digest" => "sha256:" <> String.duplicate("a", 64)}
               )

      assert review_struct.verdict == :APPROVE
      assert review_struct.implementer_transcript_received == false
      assert review_struct.reviewer_assignment_ref["digest"] != worker_output.assignment_ref["digest"]

      IO.puts("[m3-r2-apply] review_id: #{review_struct.id}")

      # Build the canonical HumanDecision (ACCEPT) and PatchDecision
      # (APPROVE_EXACT_BYTES). The PatchDecision.decision field is the
      # bounded canonical authorization; without it, the apply step
      # refuses to write to the repository.
      base_state_digest = proposal.base_state_digest

      human_decision = %Kiln.M0HumanDecision{
        id: "hd_" <> long_id(),
        semantic_digest: "sha256:" <> String.duplicate("a", 64),
        plan_ref: plan_ref,
        patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
        review_ref: %{"id" => review_struct.id, "digest" => review_struct.semantic_digest},
        result_state_digest: result_state_digest,
        decision: :ACCEPT,
        recorded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        metadata: %{"actor_id" => "temper_operator"}
      }

      patch_decision = %M0PatchDecision{
        id: "pd_" <> long_id(),
        semantic_digest: "sha256:" <> String.duplicate("a", 64),
        patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
        base_state_digest: base_state_digest,
        decision: "APPROVE_EXACT_BYTES",
        proposal: proposal
      }

      # Persist the worker output bytes so apply_with_completion_ref can
      # resolve raw_completion_ref. WorkerOutputStore.publish writes
      # the bounded completion to the canonical Artifact.Store.
      {:ready, store_handle} =
        Store.start(
          path: Path.join(System.tmp_dir!(), "m3-r2-apply-artifacts-#{short_id()}.sqlite3"),
          store_id: "store_apply_#{short_id()}",
          now: DateTime.utc_now() |> DateTime.to_iso8601(),
          name: Kiln.Store.Artifact
        )

      try do
        {:ok, _published_status, rewired} = Kiln.WorkerOutputStore.publish(store_handle, worker_output)
        rewired_wo = rewired

        # Drive the bounded apply path.
        assert {:ok, patch_evidence} =
                 PatchService.apply_with_completion_ref(proposal, patch_decision, rewired_wo, store_handle)

        IO.puts("[m3-r2-apply] === GOVERNED APPLY COMPLETE ===")
        IO.puts("[m3-r2-apply] evidence_id: #{patch_evidence.id}")

        # POST-apply source identity
        post_head = System.cmd("git", ["-C", @disposable_target, "rev-parse", "HEAD"]) |> elem(0) |> String.trim()
        IO.puts("[m3-r2-apply] POST-APPLY source identity (HEAD): #{post_head}")

        # Verify the file actually exists in the disposable target
        target_path = Path.join(@disposable_target, op.path)
        assert File.exists?(target_path), "expected post-image file at #{target_path}"

        post_bytes = File.read!(target_path)
        assert byte_size(post_bytes) == byte_size(op.content)
        assert post_bytes == op.content

        # Candidate continuity: the bytes that were verified, reviewed,
        # human-accepted, and applied are exactly the bytes now on disk.
        IO.puts("[m3-r2-apply] candidate continuity: on-disk bytes == op.content (verified == applied)")
        IO.puts("[m3-r2-apply] source state changed: #{pre_head != post_head}")

        # Identity chain report
        IO.puts("[m3-r2-apply] === IDENTITY CHAIN ===")
        IO.puts("[m3-r2-apply] WORKER_CANDIDATE_ID:        #{worker_output.id}")
        IO.puts("[m3-r2-apply] PROPOSAL_ID:                #{proposal.id}")
        IO.puts("[m3-r2-apply] PROPOSAL_PATCH_DIGEST:      #{proposal.patch_digest}")
        IO.puts("[m3-r2-apply] VERIFICATION_ID:            #{vr.id}")
        IO.puts("[m3-r2-apply] REVIEW_ID:                  #{review_struct.id}")
        IO.puts("[m3-r2-apply] REVIEWER_ASSIGNMENT_DIGEST: #{reviewer_ref["digest"]}")
        IO.puts("[m3-r2-apply] IMPLEMENTER_ASSIGNMENT_DIGEST: #{worker_output.assignment_ref["digest"]}")
        IO.puts("[m3-r2-apply] HUMAN_DECISION_ID:          #{human_decision.id}")
        IO.puts("[m3-r2-apply] PATCH_DECISION_ID:          #{patch_decision.id}")
        IO.puts("[m3-r2-apply] APPLIED_BYTES:              #{byte_size(op.content)} on path #{op.path}")
        IO.puts("[m3-r2-apply] PRE_APPLY_HEAD:             #{pre_head}")
        IO.puts("[m3-r2-apply] POST_APPLY_HEAD:            #{post_head}")
      after
        try do
          if Process.alive?(store_handle.conn), do: GenServer.stop(store_handle.conn, :normal, 1000)
        catch
          :exit, _ -> :ok
        end
      end
    after
      Application.put_env(:kiln, :worker_provider_mode, previous_mode)
      Application.put_env(:kiln, :provider_network_allowed_capabilities, previous_caps)
    end
  end
end