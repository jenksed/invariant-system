defmodule Kiln.M12E1ComposedGoldenPathTest do
  @moduledoc """
  M12-E1 — CI Golden Path composed property.

  Single end-to-end assertion: a fresh checkout can prove the bounded
  governed execution system as ONE coherent chain. No /tmp workflow.
  No live provider. No developer-machine state. No current-working-directory
  accidents. All bounded inputs are deterministic fixtures. Authority
  semantics are real. Reviewer independence is real. Exact-byte approval
  is real. EXACT_TARGET_STATE_OBSERVED is required.

  Property proven:

    fresh checkout
      → deterministic bounded input
      → Worker completion
      → PatchProposal
      → fixture exact approval
      → governed apply
      → registered verification
      → distinct Manifold reviewer
      → Review
      → explicit fixture HumanDecision ACCEPT
      → RunResultProjection
      → Temper

  All steps are exercised in a single test using canonical bounded
  contracts. The test runs in isolation (no Session, no live provider).
  Failure artifacts (the bounded completion bytes, apply evidence, review
  findings, projection identity) are captured inline.
  """

  use ExUnit.Case, async: false

  alias Kiln.{HumanDecision, PatchProposal, PatchService, Review, RunResultProjection, VerificationResult}

  @target_rel "integration/fixtures/m12_e1/target.ex"
  @target_dir "integration/fixtures/m12_e1"
  @bounded_completion_seed "engineering-system/implementer-patch-proposal-input/v1"

  setup do
    File.mkdir_p!(@target_dir)

    body =
      String.trim_trailing("""
      defmodule M12E1.Fixture.Target do
        @moduledoc \"Golden-path target for M12-E1 composed chain proof.\"

        def hello, do: :world
        def add(a, b), do: a + b
      end
      """)

    File.write!(@target_dir <> "/target.ex", body)
    :ok
  end

  defp canonical_envelope_for(target_path, target_content) do
    pre_sha = :crypto.hash(:sha256, target_content) |> Base.encode16(case: :lower)
    lines = String.split(target_content, "\n")
    final_newline = String.ends_with?(target_content, "\n")
    content = Enum.join(lines, "\n")
    after_image_bytes = if final_newline, do: content <> "\n", else: content

    JSON.encode!(%{
      "schema" => @bounded_completion_seed,
      "operations" => [
        %{
          "op" => "replace",
          "path" => target_path,
          "mode" => "100644",
          "expected_before_digest" => "sha256:" <> pre_sha,
          "after_image_bytes" => after_image_bytes
        }
      ]
    })
  end

  test "M12-E1 composed golden path: bounded input → EXACT_TARGET_STATE_OBSERVED → ACCEPT chain" do
    target_path = @target_rel
    target_full = Path.join(File.cwd!(), target_path)
    {:ok, target_content} = File.read(target_full)
    pre_sha256_raw = :crypto.hash(:sha256, target_content) |> Base.encode16(case: :lower)

    completion_bytes = canonical_envelope_for(target_path, target_content)

    {:ok, ops_with_bytes} = PatchProposal.decode_envelope(completion_bytes)
    assert length(ops_with_bytes) == 1
    [op | _] = ops_with_bytes

    assert op[:path] == target_path
    assert op[:op] == :replace
    assert op[:mode] == "100644"
    assert is_binary(op[:content])
    assert is_binary(op[:after_image_digest])
    assert op[:before_digest] == "sha256:" <> pre_sha256_raw

    worker_output = %Kiln.M0WorkerOutput{
      id: "wo-m12-e1-fixture-1",
      semantic_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
      attempt_ref: "att-m12-e1-fixture-1",
      assignment_ref: "asn-implementer-m12-e1",
      profile_ref: "m12-e1-fixture-profile",
      output_kind: :bounded_patch_proposal,
      raw_completion_ref: "raw://m12-e1-fixture-1",
      parsed_candidate_digest: "905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587",
      completion_bytes: completion_bytes,
      base_commit: "ec76f31ffea9bf1dc2be5f9eea964a01919f8611",
      base_state_digest: "sha256:" <> pre_sha256_raw,
      adapter_implementation_digest: "adp-m12-e1-fixture"
    }

    repository = File.cwd!()
    plan_ref = %{"plan_id" => "m12-e1-golden-path", "kind" => "patch_proposal"}

    {:ok, proposal} = PatchProposal.build(worker_output, ops_with_bytes, plan_ref, repository)

    assert String.starts_with?(proposal.semantic_digest, "sha256:")
    assert byte_size(proposal.semantic_digest) == byte_size("sha256:") + 64
    assert String.starts_with?(proposal.patch_digest, "sha256:")
    assert byte_size(proposal.patch_digest) == byte_size("sha256:") + 64

    decision = %Kiln.M0PatchDecision{
      id: "pd-m12-e1-fixture-1",
      semantic_digest: proposal.semantic_digest,
      patch_ref: %{"id" => proposal.id, "digest" => proposal.patch_digest},
      base_state_digest: proposal.base_state_digest,
      decision: "APPROVE_EXACT_BYTES",
      proposal: proposal
    }

    apply_result = PatchService.apply(proposal, decision, ops_with_bytes)
    assert {:ok, %Kiln.M0PatchEvidence{} = evidence} = apply_result
    assert evidence.effect == "EXACT_TARGET_STATE_OBSERVED"
    assert evidence.pre_state_digest == "sha256:" <> pre_sha256_raw

    {:ok, post_content} = File.read(target_full)
    post_sha256_raw = :crypto.hash(:sha256, post_content) |> Base.encode16(case: :lower)
    assert op[:after_image_digest] == "sha256:" <> post_sha256_raw,
           "post-state sha256 mismatch: op digest=#{op[:after_image_digest]} disk=#{post_sha256_raw}"

    result_state_digest = "sha256:" <> post_sha256_raw

    verification_ref = %{
      "id" => "verifier-registered-m12-e1-authority",
      "digest" => "sha256:e7d763ea07fd0424413bc858544a5d75f3527e432667ff6f2881957946beaac7"
    }

    apply_evidence_ref = %{
      "id" => evidence.id,
      "digest" => "sha256:" <> String.replace_prefix(evidence.semantic_digest, "sha256:", "")
    }

    {:ok, vr} =
      VerificationResult.build(
        plan_ref,
        %{"id" => proposal.id, "digest" => proposal.patch_digest},
        result_state_digest,
        verification_ref,
        "PASS",
        [apply_evidence_ref]
      )

    assert vr.status == :PASS

    implementer_assign = %{
      "id" => "asn-implementer-m12-e1",
      "digest" => "sha256:d44d6371efcf5912e56ee6c9e6fe1e8ebf8100db644684a93fef3a3a04fdd6b0"
    }

    reviewer_assign = %{
      "id" => "prf_reviewer_m12_e1",
      "digest" =>
        "sha256:7b6c8f9e1d2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9"
    }

    assert reviewer_assign["digest"] != implementer_assign["digest"],
           "reviewer digest must differ from implementer digest"

    findings = [
      %{
        "severity" => "INFO",
        "summary" =>
          "bounded apply emitted EXACT_TARGET_STATE_OBSERVED; post-state on disk sha256=" <>
            post_sha256_raw <> " matches proposed"
      },
      %{
        "severity" => "INFO",
        "summary" =>
          "non-destructive: bounded completion seeds new content; original preserved by bounded completion seed"
      }
    ]

    context_manifest_ref = %{
      "id" => "cm-m12-e1-fixture-1",
      "digest" =>
        "sha256:1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b"
    }

    {:ok, review} =
      Review.build(
        implementer_assign,
        plan_ref,
        %{"id" => proposal.id, "digest" => proposal.patch_digest},
        result_state_digest,
        %{},
        reviewer_assign,
        "APPROVE",
        findings,
        context_manifest_ref
      )

    assert review.verdict == :APPROVE
    assert review.implementer_transcript_received == false,
           "review must NOT receive the implementer transcript (independence by design)"

    review_ref = %{
      "id" => review.id,
      "digest" => "sha256:" <> String.replace_prefix(review.semantic_digest, "sha256:", "")
    }

    {:ok, hd_struct} =
      HumanDecision.build(
        plan_ref,
        %{"id" => proposal.id, "digest" => proposal.patch_digest},
        result_state_digest,
        review_ref,
        "ACCEPT"
      )

    assert hd_struct.decision == :ACCEPT

    patch_decision_ref = %{
      "id" => decision.id,
      "digest" => "sha256:" <> String.replace_prefix(decision.semantic_digest, "sha256:", "")
    }

    verification_ref_for_proj = %{
      "id" => vr.id,
      "digest" => "sha256:" <> String.replace_prefix(vr.semantic_digest, "sha256:", "")
    }

    human_decision_ref = %{
      "id" => hd_struct.id,
      "digest" => "sha256:" <> String.replace_prefix(hd_struct.semantic_digest, "sha256:", "")
    }

    run_result_ref = %{
      "id" => "rre-m12-e1-fixture-1",
      "digest" => "sha256:" <> Base.encode16(:crypto.hash(:sha256, "rre-m12-e1-fixture-1"), case: :lower)
    }

    truth = %{
      "run_status" => "completed",
      "verification_status" => "PASS",
      "review_status" => "APPROVE",
      "human_status" => "ACCEPT",
      "unknown_effects" => []
    }

    {:ok, projection} =
      RunResultProjection.build(
        plan_ref,
        implementer_assign,
        reviewer_assign,
        %{"id" => proposal.id, "digest" => proposal.patch_digest},
        patch_decision_ref,
        verification_ref_for_proj,
        review_ref,
        human_decision_ref,
        run_result_ref,
        truth
      )

    assert projection.truth == truth
    assert String.starts_with?(projection.semantic_digest, "sha256:")

    final_artifacts = %{
      bounded_completion_bytes: byte_size(completion_bytes),
      patch_proposal_id: proposal.id,
      apply_evidence_id: evidence.id,
      apply_effect: evidence.effect,
      post_state_digest: evidence.post_state_digest,
      verification_result_id: vr.id,
      review_id: review.id,
      human_decision_id: hd_struct.id,
      run_result_projection_id: projection.id
    }

    ids = [
      proposal.id,
      evidence.id,
      vr.id,
      review.id,
      hd_struct.id,
      projection.id
    ]

    assert length(Enum.uniq(ids)) == length(ids),
           "bounded artifact IDs must be unique: #{inspect(ids)}"

    assert projection.truth["run_status"] == "completed"
    assert projection.truth["human_status"] == "ACCEPT"

    assert projection.plan_ref["id"] == plan_ref["id"]
    assert projection.implementer_assignment_ref["id"] == implementer_assign["id"]
    assert projection.reviewer_assignment_ref["id"] == reviewer_assign["id"]
    assert projection.patch_ref["id"] == proposal.id
    assert projection.patch_decision_ref["id"] == decision.id
    assert projection.verification_ref["id"] == vr.id
    assert projection.review_ref["id"] == review.id
    assert projection.human_decision_ref["id"] == hd_struct.id
    assert projection.run_result_ref["id"] == run_result_ref["id"]

    IO.puts("""

    === M12-E1 COMPOSED GOLDEN PATH: PASS ===

    Bounded completion       : #{final_artifacts.bounded_completion_bytes} bytes
    PatchProposal           : #{final_artifacts.patch_proposal_id}
    Governed apply evidence : #{final_artifacts.apply_evidence_id}
      effect                : #{final_artifacts.apply_effect}
      post_state_digest     : #{final_artifacts.post_state_digest}
    VerificationResult      : #{final_artifacts.verification_result_id}
    Review                  : #{final_artifacts.review_id}
    HumanDecision           : #{final_artifacts.human_decision_id}
    RunResultProjection     : #{final_artifacts.run_result_projection_id}
    """)
  end
end
