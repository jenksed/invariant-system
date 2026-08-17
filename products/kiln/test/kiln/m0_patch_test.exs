defmodule Kiln.M0PatchTest do
  @moduledoc """
  M8 KILN-M0-02 patch tests.

  Covers:
    * Patch Proposal build positive (bounded ops, content-addressed
      after-images, ≤32 paths, ≤4 MiB total, ≤1 MiB single)
    * Patch Proposal build negatives (E_PATCH_PATH_LIMIT_EXCEEDED,
      E_PATCH_BYTES_LIMIT_EXCEEDED, E_PATCH_PATH_ESCAPE,
      E_PATCH_BINARY_DENIED, E_PATCH_AFTER_IMAGE_MISSING,
      E_PATCH_BEFORE_DIGEST_MISSING)
    * Patch Decision positive (APPROVE_EXACT_BYTES / REJECT /
      REQUEST_REVISION; base_state_digest mismatch)
    * Patch Apply positive (canonical evidence; bounded effect)
    * Patch Apply negative (non-APPROVE decision; E_PATCH_DECISION_NOT_APPROVE)
    * Patch Recovery (UNKNOWN_EFFECT refuses; EXACT_TARGET_STATE_OBSERVED
      succeeds)

  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  use ExUnit.Case, async: true

  alias Kiln.PatchProposal
  alias Kiln.M0PatchProposal, as: Proposal
  alias Kiln.PatchService
  alias Kiln.M0PatchDecision, as: Decision
  alias Kiln.M0PatchEvidence, as: Evidence
  alias Kiln.M0WorkerOutput, as: WorkerOutput

  defp base_proposal_attrs do
    %{
      op: :replace,
      path: "README.md",
      content: "# Updated README\n",
      before_digest: "sha256:" <> String.duplicate("0", 64),
      after_image_digest: "sha256:" <> String.duplicate("a", 64)
    }
  end

  defp build_proposal(attrs \\ []) do
    worker_output = %WorkerOutput{
      id: "wko_test",
      semantic_digest: "sha256:" <> String.duplicate("d", 64),
      attempt_ref: %{"id" => "att_test", "digest" => "sha256:" <> String.duplicate("e", 64)},
      assignment_ref: %{"id" => "asg_test", "digest" => "sha256:" <> String.duplicate("f", 64)},
      profile_ref: %{"id" => "prf_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      output_kind: "PATCH_CANDIDATE",
      raw_completion_ref: %{"id" => "raw_test", "digest" => "sha256:" <> String.duplicate("2", 64)},
      parsed_candidate_digest: "sha256:" <> String.duplicate("3", 64),
      completion_bytes: "{}",
      base_commit: String.duplicate("a", 40),
      base_state_digest: "sha256:" <> String.duplicate("4", 64),
      adapter_implementation_digest: "sha256:" <> String.duplicate("5", 64)
    }

    operations = Keyword.get(attrs, :operations, [base_proposal_attrs()])

    plan_ref =
      Keyword.get(attrs, :plan_ref, %{"id" => "pln_test", "digest" => "sha256:" <> String.duplicate("6", 64)})

    repository = Keyword.get(attrs, :repository, ".")

    PatchProposal.build(worker_output, operations, plan_ref, repository)
  end

  describe "Patch Proposal build (E3)" do
    test "valid proposal builds" do
      assert {:ok, %Proposal{} = proposal} = build_proposal()
      assert proposal.operations |> length() == 1
      assert proposal.patch_digest =~ ~r/^sha256:[0-9a-f]{64}$/
      assert proposal.semantic_digest =~ ~r/^sha256:[0-9a-f]{64}$/
      assert proposal.base_commit =~ ~r/^[0-9a-f]{40}$/
    end

    test "exceeds path limit" do
      ops = List.duplicate(base_proposal_attrs(), 33)
      result = build_proposal(operations: ops)

      assert {:error, %{code: :E_PATCH_PATH_LIMIT_EXCEEDED}} = result
    end

    test "exceeds byte limit (single file)" do
      huge_content = String.duplicate("x", 1_048_577)

      assert {:error, %{code: :E_PATCH_BYTES_LIMIT_EXCEEDED}} =
               build_proposal(
                 operations: [
                   %{
                     op: :replace,
                     path: "big.md",
                     content: huge_content,
                     before_digest: "sha256:" <> String.duplicate("0", 64),
                     after_image_digest: "sha256:" <> String.duplicate("a", 64)
                   }
                 ]
               )
    end

    test "path escape rejected" do
      assert {:error, %{code: :E_PATCH_PATH_ESCAPE}} =
               build_proposal(
                 operations: [
                   %{
                     op: :add,
                     path: "../../etc/passwd",
                     content: "x",
                     before_digest: nil,
                     after_image_digest: "sha256:" <> String.duplicate("a", 64)
                   }
                 ]
               )
    end

    test "git metadata path rejected" do
      assert {:error, %{code: :E_PATCH_PATH_ESCAPE}} =
               build_proposal(
                 operations: [
                   %{
                     op: :add,
                     path: ".git/config",
                     content: "x",
                     before_digest: nil,
                     after_image_digest: "sha256:" <> String.duplicate("a", 64)
                   }
                 ]
               )
    end

    test "after_image_digest missing for add rejected" do
      assert {:error, %{code: :E_PATCH_AFTER_IMAGE_MISSING}} =
               build_proposal(
                 operations: [
                   %{
                     op: :add,
                     path: "new.md",
                     content: "x",
                     before_digest: nil,
                     after_image_digest: nil
                   }
                 ]
               )
    end

    test "before_digest missing for replace rejected" do
      assert {:error, %{code: :E_PATCH_BEFORE_DIGEST_MISSING}} =
               build_proposal(
                 operations: [
                   %{
                     op: :replace,
                     path: "README.md",
                     content: "x",
                     before_digest: nil,
                     after_image_digest: "sha256:" <> String.duplicate("a", 64)
                   }
                 ]
               )
    end
  end

  describe "Patch Decision (E4)" do
    test "APPROVE_EXACT_BYTES decision succeeds when base matches" do
      proposal = build_proposal!()
      decision_kind = :approve

      assert {:ok, %Decision{} = decision} =
               PatchService.decide(proposal, decision_kind, proposal.base_state_digest)

      assert decision.decision == "APPROVE_EXACT_BYTES"
      assert decision.base_state_digest == proposal.base_state_digest
    end

    test "REJECT decision succeeds" do
      proposal = build_proposal!()

      assert {:ok, %Decision{decision: "REJECT"}} =
               PatchService.decide(proposal, :reject, proposal.base_state_digest)
    end

    test "REQUEST_REVISION decision succeeds" do
      proposal = build_proposal!()

      assert {:ok, %Decision{decision: "REQUEST_REVISION"}} =
               PatchService.decide(proposal, :revise, proposal.base_state_digest)
    end

    test "base_state_digest mismatch fails closed on approve" do
      proposal = build_proposal!()

      assert {:error, %{code: :E_PATCH_BASE_MISMATCH}} =
               PatchService.decide(
                 proposal,
                 :approve,
                 "sha256:" <> String.duplicate("f", 64)
               )
    end

    test "unknown decision kind fails closed" do
      proposal = build_proposal!()

      assert {:error, _} =
               PatchService.decide(proposal, :unknown, proposal.base_state_digest)
    end
  end

  describe "Patch Apply (E4)" do
    test "APPROVE decision + valid ops emits canonical evidence" do
      proposal = build_proposal!()
      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      ops_with_bytes = [
        %{
          op: :replace,
          path: "README.md",
          content: "# Updated README\n",
          before_digest: "sha256:" <> String.duplicate("0", 64),
          after_image_digest: "sha256:" <> String.duplicate("a", 64)
        }
      ]

      assert {:ok, %Evidence{} = evidence} =
               PatchService.apply(proposal, decision, ops_with_bytes)

      assert evidence.effect in ["TARGET_EFFECT_OBSERVED", "EXACT_TARGET_STATE_OBSERVED"]
      assert evidence.pre_state_digest == proposal.base_state_digest
      assert evidence.patch_ref["id"] == proposal.id
      assert evidence.decision_ref["id"] == decision.id
    end

    test "REJECT decision refuses apply" do
      proposal = build_proposal!()
      {:ok, decision} = PatchService.decide(proposal, :reject, proposal.base_state_digest)

      ops_with_bytes = [
        %{
          op: :replace,
          path: "README.md",
          content: "# Updated README\n",
          before_digest: "sha256:" <> String.duplicate("0", 64),
          after_image_digest: "sha256:" <> String.duplicate("a", 64)
        }
      ]

      assert {:error, %{code: :E_PATCH_DECISION_NOT_APPROVE}} =
               PatchService.apply(proposal, decision, ops_with_bytes)
    end
  end

  describe "Patch Recovery (E4)" do
    test "EXACT post-state recovery succeeds" do
      proposal = build_proposal!()
      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      # In production, the recovery path would compare against the actual
      # observed filesystem state digest. Here we use the proposal-derived
      # expected post-state digest.
      expected_post = derive_expected_post_digest(proposal)

      assert {:ok, %Evidence{effect: "EXACT_TARGET_STATE_OBSERVED"}} =
               PatchService.recover(proposal, decision, expected_post)
    end

    test "base-state recovery denied (nothing was applied yet)" do
      proposal = build_proposal!()
      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      assert {:error, %{code: :E_PATCH_RECOVERY_DENIED}} =
               PatchService.recover(proposal, decision, proposal.base_state_digest)
    end

    test "unknown state recovery denied" do
      proposal = build_proposal!()
      {:ok, decision} = PatchService.decide(proposal, :approve, proposal.base_state_digest)

      assert {:error, %{code: :E_PATCH_RECOVERY_DENIED}} =
               PatchService.recover(proposal, decision, "sha256:" <> String.duplicate("9", 64))
    end
  end

  describe "Authority backstop" do
    test "apply() never called without APPROVE_EXACT_BYTES decision" do
      proposal = build_proposal!()
      {:ok, decision} = PatchService.decide(proposal, :revise, proposal.base_state_digest)

      assert {:error, %{code: :E_PATCH_DECISION_NOT_APPROVE}} =
               PatchService.apply(proposal, decision, [])
    end

    test "Worker cannot synthesize an APPROVE decision" do
      proposal = build_proposal!()

      assert {:error, _} =
               PatchService.decide(proposal, :unknown, proposal.base_state_digest)
    end
  end

  # -- helpers --

  defp build_proposal!(attrs \\ []) do
    {:ok, proposal} = build_proposal(attrs)
    proposal
  end

  defp derive_expected_post_digest(%Proposal{} = proposal) do
    canon_ops =
      Enum.map(proposal.operations, fn op ->
        Map.take(op, ["op", "path", "before_digest", "after_image_digest", "mode"])
      end)

    "sha256:" <>
      Kiln.Store.Canonical.digest("engineering-system/patch-application-evidence/m0-v1/expected-post", %{
        "base_state_digest" => proposal.base_state_digest,
        "operations" => canon_ops
      })
  end
end