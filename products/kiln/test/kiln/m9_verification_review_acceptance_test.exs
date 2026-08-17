defmodule Kiln.M0VerificationTest do
  @moduledoc """
  M9 KILN-M0-03 verification result tests.

  Covers the canonical `engineering-system/verification-result/m0-v1`
  envelope:
    * positive: bounded verifier invocation produces PASS/FAIL/TIMEOUT/ERROR
      binding to plan/patch/result_state/registered_verifier
    * negative: invalid status; missing evidence_refs

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  use ExUnit.Case, async: true

  defp base_refs do
    %{
      plan_ref: %{"id" => "pln_test", "digest" => "sha256:" <> String.duplicate("0", 64)},
      patch_ref: %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      result_state_digest: "sha256:" <> String.duplicate("2", 64),
      registered_verifier: %{
        "id" => "verifier_unit_test",
        "digest" => "sha256:" <> String.duplicate("3", 64)
      },
      evidence_refs: [
        %{"id" => "evidence_unit_test_1", "digest" => "sha256:" <> String.duplicate("4", 64)}
      ]
    }
  end

  describe "Kiln.VerificationResult.build/6" do
    test "PASS produces a canonical envelope" do
      r = base_refs()

      assert {:ok, vr} = Kiln.VerificationResult.build(
               r.plan_ref,
               r.patch_ref,
               r.result_state_digest,
               r.registered_verifier,
               "PASS",
               r.evidence_refs
             )

      assert vr.id =~ ~r/^ver_[0-9a-f]+$/
      assert vr.semantic_digest =~ ~r/^sha256:[0-9a-f]{64}$/
      assert vr.status == :PASS
      assert vr.result_state_digest == r.result_state_digest
    end

    test "FAIL is preserved as evidence" do
      r = base_refs()

      assert {:ok, vr} =
               Kiln.VerificationResult.build(
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.registered_verifier,
                 "FAIL",
                 r.evidence_refs
               )

      assert vr.status == :FAIL
    end

    test "TIMEOUT and ERROR are bounded states" do
      r = base_refs()

      for status <- ["TIMEOUT", "ERROR"] do
        assert {:ok, vr} =
                 Kiln.VerificationResult.build(
                   r.plan_ref,
                   r.patch_ref,
                   r.result_state_digest,
                   r.registered_verifier,
                   status,
                   r.evidence_refs
                 )

        assert vr.status == String.to_atom(status)
      end
    end

    test "invalid status fails closed" do
      r = base_refs()

      assert {:error, %{code: :E_VERIFICATION_STATUS_INVALID}} =
               Kiln.VerificationResult.build(
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.registered_verifier,
                 "BOGUS",
                 r.evidence_refs
               )
    end

    test "missing evidence_refs fails closed" do
      r = base_refs()

      assert {:error, %{code: :E_VERIFICATION_EVIDENCE_MISSING}} =
               Kiln.VerificationResult.build(
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.registered_verifier,
                 "PASS",
                 []
               )
    end
  end
end

defmodule Kiln.M0ReviewTest do
  @moduledoc """
  M9 KILN-M0-03 review tests.

  Covers the canonical `engineering-system/review/m0-v1` envelope:
    * positive: bounded Reviewer dispatch with independent assignment;
      `implementer_transcript_received: false` is enforced.
    * negative: Reviewer == Implementer digest → E_REVIEWER_CONTEXT_CONTAMINATED;
      invalid verdict; missing findings.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  use ExUnit.Case, async: true

  defp base_refs do
    %{
      implementer_assignment_ref: %{
        "id" => "asg_impl",
        "digest" => "sha256:" <> String.duplicate("a", 64)
      },
      plan_ref: %{"id" => "pln_test", "digest" => "sha256:" <> String.duplicate("0", 64)},
      patch_ref: %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      result_state_digest: "sha256:" <> String.duplicate("2", 64),
      verification_ref: %{
        "id" => "ver_test",
        "digest" => "sha256:" <> String.duplicate("3", 64)
      },
      reviewer_assignment_ref: %{
        "id" => "asg_reviewer",
        "digest" => "sha256:" <> String.duplicate("b", 64)
      },
      context_manifest_ref: %{
        "id" => "ctx_reviewer_manifest",
        "digest" => "sha256:" <> String.duplicate("c", 64)
      }
    }
  end

  describe "Kiln.Review.build/9" do
    test "APPROVE verdict with independent Reviewer" do
      r = base_refs()

      assert {:ok, review} =
               Kiln.Review.build(
                 r.implementer_assignment_ref,
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.verification_ref,
                 r.reviewer_assignment_ref,
                 "APPROVE",
                 ["bounded finding: lint clean"],
                 r.context_manifest_ref
               )

      assert review.verdict == :APPROVE
      assert review.implementer_transcript_received == false
      assert review.semantic_digest =~ ~r/^sha256:[0-9a-f]{64}$/
    end

    test "REJECT and REQUEST_REVISION are bounded verdicts" do
      r = base_refs()

      for verdict <- ["REJECT", "REQUEST_REVISION"] do
        assert {:ok, review} =
                 Kiln.Review.build(
                   r.implementer_assignment_ref,
                   r.plan_ref,
                   r.patch_ref,
                   r.result_state_digest,
                   r.verification_ref,
                   r.reviewer_assignment_ref,
                   verdict,
                   ["bounded finding"],
                   r.context_manifest_ref
                 )

        assert review.verdict == String.to_atom(verdict)
      end
    end

    test "Reviewer == Implementer digest fails closed (E_REVIEWER_CONTEXT_CONTAMINATED)" do
      r = base_refs()
      same_digest = %{"id" => "asg_reviewer", "digest" => r.implementer_assignment_ref["digest"]}

      assert {:error, %{code: :E_REVIEWER_CONTEXT_CONTAMINATED}} =
               Kiln.Review.build(
                 r.implementer_assignment_ref,
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.verification_ref,
                 same_digest,
                 "APPROVE",
                 ["f"],
                 r.context_manifest_ref
               )
    end

    test "invalid verdict fails closed" do
      r = base_refs()

      assert {:error, %{code: :E_REVIEW_VERDICT_INVALID}} =
               Kiln.Review.build(
                 r.implementer_assignment_ref,
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.verification_ref,
                 r.reviewer_assignment_ref,
                 "BOGUS",
                 ["f"],
                 r.context_manifest_ref
               )
    end

    test "missing findings fails closed" do
      r = base_refs()

      assert {:error, %{code: :E_REVIEW_FINDINGS_MISSING}} =
               Kiln.Review.build(
                 r.implementer_assignment_ref,
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.verification_ref,
                 r.reviewer_assignment_ref,
                 "APPROVE",
                 [],
                 r.context_manifest_ref
               )
    end
  end
end

defmodule Kiln.M0AcceptanceTest do
  @moduledoc """
  M9 KILN-M0-03 acceptance tests — HumanDecision and RunResultProjection.

  Covers:
    * positive: HumanDecision (ACCEPT/REJECT/REQUEST_REVISION) and
      RunResultProjection with bounded truth statuses
    * negative: invalid decision kind; invalid projection statuses

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  use ExUnit.Case, async: true

  defp base_refs do
    %{
      plan_ref: %{"id" => "pln_test", "digest" => "sha256:" <> String.duplicate("0", 64)},
      patch_ref: %{"id" => "pp_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      result_state_digest: "sha256:" <> String.duplicate("2", 64),
      review_ref: %{"id" => "rev_test", "digest" => "sha256:" <> String.duplicate("3", 64)},
      implementer_assignment_ref: %{
        "id" => "asg_impl",
        "digest" => "sha256:" <> String.duplicate("4", 64)
      },
      reviewer_assignment_ref: %{
        "id" => "asg_reviewer",
        "digest" => "sha256:" <> String.duplicate("5", 64)
      },
      patch_decision_ref: %{
        "id" => "dec_test",
        "digest" => "sha256:" <> String.duplicate("6", 64)
      },
      verification_ref: %{
        "id" => "ver_test",
        "digest" => "sha256:" <> String.duplicate("7", 64)
      },
      run_result_ref: %{
        "id" => "rre_test",
        "digest" => "sha256:" <> String.duplicate("8", 64)
      }
    }
  end

  describe "Kiln.HumanDecision.build/5" do
    test "ACCEPT records explicit operator intent" do
      r = base_refs()

      assert {:ok, hd} =
               Kiln.HumanDecision.build(
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.review_ref,
                 "ACCEPT"
               )

      assert hd.decision == :ACCEPT
      assert hd.review_ref["id"] == "rev_test"
      assert hd.recorded_at =~ ~r/^\d{4}-\d{2}-\d{2}T/
    end

    test "REJECT and REQUEST_REVISION are bounded decisions" do
      r = base_refs()

      for decision <- ["REJECT", "REQUEST_REVISION"] do
        assert {:ok, hd} =
                 Kiln.HumanDecision.build(
                   r.plan_ref,
                   r.patch_ref,
                   r.result_state_digest,
                   r.review_ref,
                   decision
                 )

        assert hd.decision == String.to_atom(decision)
      end
    end

    test "review_ref may be nil when no Review has been recorded yet" do
      r = base_refs()

      assert {:ok, hd} =
               Kiln.HumanDecision.build(
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 nil,
                 "REQUEST_REVISION"
               )

      assert hd.review_ref == nil
    end

    test "invalid decision fails closed" do
      r = base_refs()

      assert {:error, %{code: :E_HUMAN_DECISION_INVALID}} =
               Kiln.HumanDecision.build(
                 r.plan_ref,
                 r.patch_ref,
                 r.result_state_digest,
                 r.review_ref,
                 "BOGUS"
               )
    end
  end

  describe "Kiln.RunResultProjection.build/9" do
    test "valid truth statuses produce a canonical envelope" do
      r = base_refs()

      truth = %{
        "run_status" => "completed",
        "verification_status" => "PASS",
        "review_status" => "APPROVE",
        "human_status" => "ACCEPT",
        "unknown_effects" => []
      }

      assert {:ok, p} =
               Kiln.RunResultProjection.build(
                 r.plan_ref,
                 r.implementer_assignment_ref,
                 r.reviewer_assignment_ref,
                 r.patch_ref,
                 r.patch_decision_ref,
                 r.verification_ref,
                 r.review_ref,
                 %{"id" => "hd_test", "digest" => "sha256:" <> String.duplicate("9", 64)},
                 r.run_result_ref,
                 truth
               )

      assert p.truth == truth
      assert p.semantic_digest =~ ~r/^sha256:[0-9a-f]{64}$/
    end

    test "human_decision_ref may be nil" do
      r = base_refs()

      truth = %{
        "run_status" => "unknown",
        "verification_status" => "ERROR",
        "review_status" => "REJECT",
        "human_status" => "REJECT",
        "unknown_effects" => ["hd_pending"]
      }

      assert {:ok, _} =
               Kiln.RunResultProjection.build(
                 r.plan_ref,
                 r.implementer_assignment_ref,
                 r.reviewer_assignment_ref,
                 r.patch_ref,
                 r.patch_decision_ref,
                 r.verification_ref,
                 r.review_ref,
                 nil,
                 r.run_result_ref,
                 truth
               )
    end

    test "invalid run_status fails closed" do
      r = base_refs()

      truth = %{
        "run_status" => "BOGUS",
        "verification_status" => "PASS",
        "review_status" => "APPROVE",
        "human_status" => "ACCEPT",
        "unknown_effects" => []
      }

      assert {:error, %{code: :E_PROJECTION_NOT_CANONICAL}} =
               Kiln.RunResultProjection.build(
                 r.plan_ref,
                 r.implementer_assignment_ref,
                 r.reviewer_assignment_ref,
                 r.patch_ref,
                 r.patch_decision_ref,
                 r.verification_ref,
                 r.review_ref,
                 nil,
                 r.run_result_ref,
                 truth
               )
    end

    test "invalid verification_status fails closed" do
      r = base_refs()

      truth = %{
        "run_status" => "completed",
        "verification_status" => "BOGUS",
        "review_status" => "APPROVE",
        "human_status" => "ACCEPT",
        "unknown_effects" => []
      }

      assert {:error, %{code: :E_PROJECTION_NOT_CANONICAL}} =
               Kiln.RunResultProjection.build(
                 r.plan_ref,
                 r.implementer_assignment_ref,
                 r.reviewer_assignment_ref,
                 r.patch_ref,
                 r.patch_decision_ref,
                 r.verification_ref,
                 r.review_ref,
                 nil,
                 r.run_result_ref,
                 truth
               )
    end
  end
end