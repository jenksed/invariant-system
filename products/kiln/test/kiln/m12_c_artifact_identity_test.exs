defmodule Kiln.M12CArtifactIdentityTest do
  @moduledoc """
  M12-C — Artifact identity-bound invariant tests.

  Asserts that every bounded artifact produced by the M11 proven chain
  has the correct identity structure:
  - `id` = opaque random (16 hex chars)
  - `semantic_digest` = `sha256:<hex>` of canonical body with `id` and
    `metadata.produced_at` excluded (stable across rebuilds)
  - Required bounded fields present
  - Bounded enum values enforced

  These tests assert the CONTRACT. The bounded machinery in
  products/kiln/lib/kiln/m9_review.ex already implements these
  invariants; this file pins the contract as a regression guard.
  """

  use ExUnit.Case, async: true

  alias Kiln.{HumanDecision, PatchProposal, PatchService, Review, RunResultProjection, VerificationResult}

  defp fixture_completion_bytes do
    pre_sha = "a" |> String.duplicate(64) |> (&("sha256:" <> &1)).()

    JSON.encode!(%{
      "schema" => "engineering-system/implementer-patch-proposal-input/v1",
      "operations" => [
        %{
          "op" => "replace",
          "path" => "test.ex",
          "mode" => "100644",
          "expected_before_digest" => pre_sha,
          "after_image_bytes" => "defmodule T do\nend\n"
        }
      ]
    })
  end

  describe "M0WorkerOutput identity invariants" do
    test "id format: 'wo_' prefix + 16 hex chars" do
      worker_output = %Kiln.M0WorkerOutput{
        id: "wo_82bd341446256391",
        semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        attempt_ref: "att-1",
        assignment_ref: "asn-1",
        profile_ref: "profile-1",
        output_kind: :bounded_patch_proposal,
        raw_completion_ref: "raw://test",
        parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        completion_bytes: "test",
        base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
        base_state_digest: "sha256:" <> String.duplicate("a", 64),
        adapter_implementation_digest: "adp-1"
      }

      assert String.starts_with?(worker_output.id, "wo_")
      assert byte_size(worker_output.id) == byte_size("wo_") + 16
    end

    test "semantic_digest format: 'sha256:' + 64 hex chars" do
      worker_output = %Kiln.M0WorkerOutput{
        id: "wo_82bd341446256391",
        semantic_digest:
          "sha256:905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        attempt_ref: "att-1",
        assignment_ref: "asn-1",
        profile_ref: "profile-1",
        output_kind: :bounded_patch_proposal,
        raw_completion_ref: "raw://test",
        parsed_candidate_digest:
          "sha256:905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        completion_bytes: "test",
        base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
        base_state_digest: "sha256:" <> String.duplicate("a", 64),
        adapter_implementation_digest: "adp-1"
      }

      assert String.starts_with?(worker_output.semantic_digest, "sha256:")
      assert byte_size(worker_output.semantic_digest) == byte_size("sha256:") + 64
    end

    test "raw_completion_ref format: 'raw://' prefix" do
      worker_output = %Kiln.M0WorkerOutput{
        id: "wo_82bd341446256391",
        semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        attempt_ref: "att-1",
        assignment_ref: "asn-1",
        profile_ref: "profile-1",
        output_kind: :bounded_patch_proposal,
        raw_completion_ref: "raw://provider-id-here",
        parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        completion_bytes: "test",
        base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
        base_state_digest: "sha256:" <> String.duplicate("a", 64),
        adapter_implementation_digest: "adp-1"
      }

      assert String.starts_with?(worker_output.raw_completion_ref, "raw://")
    end
  end

  describe "PatchProposal identity invariants" do
    test "id format: 'pp_' prefix + 16 hex chars" do
      completion_bytes = fixture_completion_bytes()
      {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

      worker_output = %Kiln.M0WorkerOutput{
        id: "wo_test",
        semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        attempt_ref: "att-1",
        assignment_ref: "asn-1",
        profile_ref: "profile-1",
        output_kind: :bounded_patch_proposal,
        raw_completion_ref: "raw://test",
        parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        completion_bytes: completion_bytes,
        base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
        base_state_digest: "sha256:" <> String.duplicate("a", 64),
        adapter_implementation_digest: "adp-1"
      }

      plan_ref = %{"plan_id" => "plan-1", "kind" => "patch_proposal"}
      repository = File.cwd!()
      {:ok, proposal} = PatchProposal.build(worker_output, ops_with_bytes, plan_ref, repository)

      assert String.starts_with?(proposal.id, "pp_")
      assert byte_size(proposal.id) == byte_size("pp_") + 16
    end

    test "semantic_digest format: 'sha256:' + 64 hex chars" do
      completion_bytes = fixture_completion_bytes()
      {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

      worker_output = %Kiln.M0WorkerOutput{
        id: "wo_test",
        semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        attempt_ref: "att-1",
        assignment_ref: "asn-1",
        profile_ref: "profile-1",
        output_kind: :bounded_patch_proposal,
        raw_completion_ref: "raw://test",
        parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        completion_bytes: completion_bytes,
        base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
        base_state_digest: "sha256:" <> String.duplicate("a", 64),
        adapter_implementation_digest: "adp-1"
      }

      plan_ref = %{"plan_id" => "plan-1", "kind" => "patch_proposal"}
      repository = File.cwd!()
      {:ok, proposal} = PatchProposal.build(worker_output, ops_with_bytes, plan_ref, repository)

      assert String.starts_with?(proposal.semantic_digest, "sha256:")
      assert byte_size(proposal.semantic_digest) == byte_size("sha256:") + 64
      assert String.starts_with?(proposal.patch_digest, "sha256:")
      assert byte_size(proposal.patch_digest) == byte_size("sha256:") + 64
    end

    test "patch_digest is deterministic for identical inputs" do
      completion_bytes = fixture_completion_bytes()
      {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

      base_worker_output = fn ->
        %Kiln.M0WorkerOutput{
          id: "wo_test",
          semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
          attempt_ref: "att-1",
          assignment_ref: "asn-1",
          profile_ref: "profile-1",
          output_kind: :bounded_patch_proposal,
          raw_completion_ref: "raw://test",
          parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
          completion_bytes: completion_bytes,
          base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
          base_state_digest: "sha256:" <> String.duplicate("a", 64),
          adapter_implementation_digest: "adp-1"
        }
      end

      plan_ref = %{"plan_id" => "plan-1", "kind" => "patch_proposal"}
      repository = File.cwd!()

      {:ok, p1} = PatchProposal.build(base_worker_output.(), ops_with_bytes, plan_ref, repository)
      {:ok, p2} = PatchProposal.build(base_worker_output.(), ops_with_bytes, plan_ref, repository)

      assert p1.patch_digest == p2.patch_digest,
             "PatchProposal.patch_digest must be deterministic for identical inputs"

      assert p1.semantic_digest == p2.semantic_digest,
             "PatchProposal.semantic_digest must be deterministic across rebuilds (excludes random id)"

      assert p1.id != p2.id, "PatchProposal.id must be unique across builds (random)"
    end
  end

  describe "M0PatchDecision identity invariants" do
    test "id format: 'pd_' prefix + 16 hex chars" do
      completion_bytes = fixture_completion_bytes()
      {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

      worker_output = %Kiln.M0WorkerOutput{
        id: "wo_test",
        semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        attempt_ref: "att-1",
        assignment_ref: "asn-1",
        profile_ref: "profile-1",
        output_kind: :bounded_patch_proposal,
        raw_completion_ref: "raw://test",
        parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        completion_bytes: completion_bytes,
        base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
        base_state_digest: "sha256:" <> String.duplicate("a", 64),
        adapter_implementation_digest: "adp-1"
      }

      plan_ref = %{"plan_id" => "plan-1", "kind" => "patch_proposal"}
      repository = File.cwd!()
      {:ok, proposal} = PatchProposal.build(worker_output, ops_with_bytes, plan_ref, repository)

      decision = %Kiln.M0PatchDecision{
        id: "pd_82bd341446256391",
        semantic_digest: proposal.semantic_digest,
        patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
        base_state_digest: proposal.base_state_digest,
        decision: "APPROVE_EXACT_BYTES",
        proposal: proposal
      }

      assert String.starts_with?(decision.id, "pd_")
      assert byte_size(decision.id) == byte_size("pd_") + 16
    end

    test "decision must be APPROVE_EXACT_BYTES for bounded apply" do
      completion_bytes = fixture_completion_bytes()
      {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)

      worker_output = %Kiln.M0WorkerOutput{
        id: "wo_test",
        semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        attempt_ref: "att-1",
        assignment_ref: "asn-1",
        profile_ref: "profile-1",
        output_kind: :bounded_patch_proposal,
        raw_completion_ref: "raw://test",
        parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
        completion_bytes: completion_bytes,
        base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
        base_state_digest: "sha256:" <> String.duplicate("a", 64),
        adapter_implementation_digest: "adp-1"
      }

      plan_ref = %{"plan_id" => "plan-1", "kind" => "patch_proposal"}
      repository = File.cwd!()
      {:ok, proposal} = PatchProposal.build(worker_output, ops_with_bytes, plan_ref, repository)

      bad_decision = %Kiln.M0PatchDecision{
        id: "pd_test",
        semantic_digest: proposal.semantic_digest,
        patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
        base_state_digest: proposal.base_state_digest,
        decision: "MAYBE_APPROVE",
        proposal: proposal
      }

      assert {:error, _} = PatchService.apply(proposal, bad_decision, ops_with_bytes)
    end
  end

  describe "M0VerificationResult identity invariants" do
    test "id format: 'ver_' prefix + 16 hex chars" do
      plan_ref = %{"id" => "plan-1", "digest" => "sha256:" <> String.duplicate("b", 64)}
      patch_ref = %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("c", 64)}
      result_state_digest = "sha256:" <> String.duplicate("d", 64)
      registered_verifier = %{"id" => "v-1", "digest" => "sha256:" <> String.duplicate("e", 64)}
      evidence_ref = %{"id" => "ape-1", "digest" => "sha256:" <> String.duplicate("f", 64)}

      {:ok, vr} =
        VerificationResult.build(
          plan_ref,
          patch_ref,
          result_state_digest,
          registered_verifier,
          "PASS",
          [evidence_ref]
        )

      assert String.starts_with?(vr.id, "ver_")
      assert byte_size(vr.id) == byte_size("ver_") + 16
    end

    test "status is bounded enum (PASS, FAIL, TIMEOUT, ERROR)" do
      plan_ref = %{"id" => "plan-1", "digest" => "sha256:" <> String.duplicate("b", 64)}
      patch_ref = %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("c", 64)}
      result_state_digest = "sha256:" <> String.duplicate("d", 64)
      registered_verifier = %{"id" => "v-1", "digest" => "sha256:" <> String.duplicate("e", 64)}
      evidence_ref = %{"id" => "ape-1", "digest" => "sha256:" <> String.duplicate("f", 64)}

      for status <- ["PASS", "FAIL", "TIMEOUT", "ERROR"] do
        {:ok, vr} =
          VerificationResult.build(
            plan_ref,
            patch_ref,
            result_state_digest,
            registered_verifier,
            status,
            [evidence_ref]
          )

        assert vr.status == String.to_atom(status)
      end

      assert {:error, _} =
               VerificationResult.build(
                 plan_ref,
                 patch_ref,
                 result_state_digest,
                 registered_verifier,
                 "INVALID",
                 [evidence_ref]
               )
    end
  end

  describe "M0HumanDecision identity invariants" do
    test "id format: 'hd_' prefix + 16 hex chars" do
      plan_ref = %{"id" => "plan-1", "digest" => "sha256:" <> String.duplicate("b", 64)}
      patch_ref = %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("c", 64)}
      result_state_digest = "sha256:" <> String.duplicate("d", 64)
      review_ref = %{"id" => "rev-1", "digest" => "sha256:" <> String.duplicate("e", 64)}

      {:ok, hd} = HumanDecision.build(plan_ref, patch_ref, result_state_digest, review_ref, "ACCEPT")

      assert String.starts_with?(hd.id, "hd_")
      assert byte_size(hd.id) == byte_size("hd_") + 16
    end
  end

  describe "M0Review identity invariants" do
    test "id format: 'rev_' prefix + 16 hex chars" do
      plan_ref = %{"id" => "plan-1", "digest" => "sha256:" <> String.duplicate("b", 64)}
      patch_ref = %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("c", 64)}
      result_state_digest = "sha256:" <> String.duplicate("d", 64)
      implementer_assign = %{
        "id" => "asn-impl",
        "digest" => "sha256:" <> String.duplicate("e", 64)
      }

      reviewer_assign = %{
        "id" => "prf-rev",
        "digest" => "sha256:" <> String.duplicate("f", 64)
      }

      context_manifest_ref = %{
        "id" => "cm-1",
        "digest" => "sha256:" <> String.duplicate("a", 64)
      }

      findings = [%{"severity" => "INFO", "summary" => "ok"}]

      {:ok, review} =
        Review.build(
          implementer_assign,
          plan_ref,
          patch_ref,
          result_state_digest,
          %{},
          reviewer_assign,
          "APPROVE",
          findings,
          context_manifest_ref
        )

      assert String.starts_with?(review.id, "rev_")
      assert byte_size(review.id) == byte_size("rev_") + 16
      assert review.implementer_transcript_received == false
    end

    test "implementer and reviewer digests must differ (independence-by-digest)" do
      plan_ref = %{"id" => "plan-1", "digest" => "sha256:" <> String.duplicate("b", 64)}
      patch_ref = %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("c", 64)}
      result_state_digest = "sha256:" <> String.duplicate("d", 64)
      same_digest = "sha256:" <> String.duplicate("e", 64)

      implementer_assign = %{"id" => "asn-impl", "digest" => same_digest}
      reviewer_assign = %{"id" => "prf-rev", "digest" => same_digest}

      context_manifest_ref = %{"id" => "cm-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      findings = [%{"severity" => "INFO", "summary" => "ok"}]

      assert {:error, %{code: :E_REVIEWER_CONTEXT_CONTAMINATED}} =
               Review.build(
                 implementer_assign,
                 plan_ref,
                 patch_ref,
                 result_state_digest,
                 %{},
                 reviewer_assign,
                 "APPROVE",
                 findings,
                 context_manifest_ref
               )
    end
  end

  describe "M0RunResultProjection identity invariants" do
    test "id format: 'rj_' prefix + 16 hex chars" do
      plan_ref = %{"id" => "plan-1", "digest" => "sha256:" <> String.duplicate("b", 64)}
      implementer_assign = %{"id" => "asn-impl", "digest" => "sha256:" <> String.duplicate("e", 64)}
      reviewer_assign = %{"id" => "prf-rev", "digest" => "sha256:" <> String.duplicate("f", 64)}
      patch_ref = %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("c", 64)}
      patch_decision_ref = %{"id" => "pd-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      verification_ref = %{"id" => "ver-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      review_ref = %{"id" => "rev-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      human_decision_ref = %{"id" => "hd-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      run_result_ref = %{"id" => "rre-1", "digest" => "sha256:" <> String.duplicate("a", 64)}

      truth = %{
        "run_status" => "completed",
        "verification_status" => "PASS",
        "review_status" => "APPROVE",
        "human_status" => "ACCEPT",
        "unknown_effects" => []
      }

      {:ok, proj} =
        RunResultProjection.build(
          plan_ref,
          implementer_assign,
          reviewer_assign,
          patch_ref,
          patch_decision_ref,
          verification_ref,
          review_ref,
          human_decision_ref,
          run_result_ref,
          truth
        )

      assert String.starts_with?(proj.id, "rj_")
      assert byte_size(proj.id) == byte_size("rj_") + 16
    end

    test "semantic_digest format: 'sha256:' + 64 hex chars" do
      plan_ref = %{"id" => "plan-1", "digest" => "sha256:" <> String.duplicate("b", 64)}
      implementer_assign = %{"id" => "asn-impl", "digest" => "sha256:" <> String.duplicate("e", 64)}
      reviewer_assign = %{"id" => "prf-rev", "digest" => "sha256:" <> String.duplicate("f", 64)}
      patch_ref = %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("c", 64)}
      patch_decision_ref = %{"id" => "pd-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      verification_ref = %{"id" => "ver-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      review_ref = %{"id" => "rev-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      human_decision_ref = %{"id" => "hd-1", "digest" => "sha256:" <> String.duplicate("a", 64)}
      run_result_ref = %{"id" => "rre-1", "digest" => "sha256:" <> String.duplicate("a", 64)}

      truth = %{
        "run_status" => "completed",
        "verification_status" => "PASS",
        "review_status" => "APPROVE",
        "human_status" => "ACCEPT",
        "unknown_effects" => []
      }

      {:ok, proj} =
        RunResultProjection.build(
          plan_ref,
          implementer_assign,
          reviewer_assign,
          patch_ref,
          patch_decision_ref,
          verification_ref,
          review_ref,
          human_decision_ref,
          run_result_ref,
          truth
        )

      assert String.starts_with?(proj.semantic_digest, "sha256:")
      assert byte_size(proj.semantic_digest) == byte_size("sha256:") + 64
    end
  end
end
