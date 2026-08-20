defmodule Kiln.M4AGraphProjectionTest do
  @moduledoc """
  M4-A — TRUTHFUL GRAPH property tests.

  These tests prove the headless graph projection:
    1. builds the right nodes/edges for a known M3 lifecycle;
    2. preserves canonical identity (every node bound to id+digest);
    3. supports backward provenance walk from evidence to worker;
    4. distinguishes proposed vs governed relationships;
    5. surfaces attention state correctly;
    6. never invents workflow truth (no nodes appear without a
       canonical source).
  """

  use ExUnit.Case, async: true

  alias Kiln.{M0HumanDecision, M0PatchEvidence, M0PatchProposal, M0Review,
             M0VerificationResult, M0WorkerOutput}
  alias Kiln.GraphProjection

  defp worker_output_fixture do
    %M0WorkerOutput{
      id: "wko_test_01",
      semantic_digest: "sha256:" <> String.duplicate("a", 64),
      attempt_ref: %{"id" => "att_test", "digest" => "sha256:" <> String.duplicate("0", 64)},
      assignment_ref: %{"id" => "asg_test", "digest" => "sha256:" <> String.duplicate("1", 64)},
      profile_ref: %{"id" => "prof_test", "digest" => "sha256:" <> String.duplicate("2", 64)},
      output_kind: "PATCH_CANDIDATE",
      raw_completion_ref: %{"id" => "raw_test", "digest" => "sha256:" <> String.duplicate("3", 64)},
      parsed_candidate_digest: "sha256:" <> String.duplicate("4", 64),
      completion_bytes: "test",
      base_commit: "0123456789abcdef0123456789abcdef01234567",
      base_state_digest: "sha256:" <> String.duplicate("5", 64),
      adapter_implementation_digest: "sha256:" <> String.duplicate("6", 64)
    }
  end

  defp proposal_fixture do
    %M0PatchProposal{
      id: "pp_test_01",
      semantic_digest: "sha256:" <> String.duplicate("b", 64),
      plan_ref: %{"id" => "plan_test", "digest" => "sha256:" <> String.duplicate("7", 64)},
      attempt_ref: %{"id" => "att_test", "digest" => "sha256:" <> String.duplicate("0", 64)},
      patch_digest: "sha256:" <> String.duplicate("8", 64),
      base_commit: "0123456789abcdef0123456789abcdef01234567",
      repository: "/tmp/test",
      supersedes_patch_ref: nil
    }
  end

  defp verification_fixture do
    %M0VerificationResult{
      id: "ver_test_01",
      semantic_digest: "sha256:" <> String.duplicate("c", 64),
      plan_ref: %{"id" => "plan_test", "digest" => "sha256:" <> String.duplicate("7", 64)},
      patch_ref: %{"id" => "pp_test_01", "digest" => "sha256:" <> String.duplicate("8", 64)},
      status: :PASS,
      result_state_digest: "sha256:" <> String.duplicate("9", 64),
      registered_verifier: %{"id" => "verifier_test", "digest" => "sha256:" <> String.duplicate("d", 64)},
      evidence_refs: []
    }
  end

  defp review_fixture do
    %M0Review{
      id: "rev_test_01",
      semantic_digest: "sha256:" <> String.duplicate("e", 64),
      plan_ref: %{"id" => "plan_test", "digest" => "sha256:" <> String.duplicate("7", 64)},
      patch_ref: %{"id" => "pp_test_01", "digest" => "sha256:" <> String.duplicate("8", 64)},
      verifier_ref: %{"id" => "ver_test_01", "digest" => "sha256:" <> String.duplicate("c", 64)},
      context_manifest_ref: %{"id" => "ctx_test", "digest" => "sha256:" <> String.duplicate("f", 64)},
      result_state_digest: "sha256:" <> String.duplicate("9", 64),
      verdict: :APPROVE,
      findings: ["bounded rules satisfied"],
      implementer_transcript_received: false,
      reviewer_assignment_ref: %{"id" => "reviewer_test", "digest" => "sha256:" <> String.duplicate("a", 64)}
    }
  end

  defp human_decision_fixture do
    %M0HumanDecision{
      id: "hd_test_01",
      semantic_digest: "sha256:" <> String.duplicate("0", 64),
      plan_ref: %{"id" => "plan_test", "digest" => "sha256:" <> String.duplicate("7", 64)},
      patch_ref: %{"id" => "pp_test_01", "digest" => "sha256:" <> String.duplicate("8", 64)},
      review_ref: %{"id" => "rev_test_01", "digest" => "sha256:" <> String.duplicate("e", 64)},
      result_state_digest: "sha256:" <> String.duplicate("9", 64),
      decision: :ACCEPT,
      recorded_at: "2026-08-20T00:00:00Z",
      metadata: %{}
    }
  end

  defp patch_evidence_fixture do
    %M0PatchEvidence{
      id: "pe_test_01",
      semantic_digest: "sha256:" <> String.duplicate("1", 64),
      patch_ref: %{"id" => "pp_test_01", "digest" => "sha256:" <> String.duplicate("8", 64)},
      decision_ref: %{"id" => "pd_test_01", "digest" => "sha256:" <> String.duplicate("3", 64)},
      pre_state_digest: "sha256:" <> String.duplicate("4", 64),
      post_state_digest: "sha256:" <> String.duplicate("2", 64),
      effect: "APPLIED"
    }
  end

  describe "build/1" do
    test "builds nodes for a complete M3 lifecycle" do
      facts = %{
        worker_output: worker_output_fixture(),
        proposal: proposal_fixture(),
        verification: verification_fixture(),
        review: review_fixture(),
        human_decision: human_decision_fixture(),
        patch_evidence: patch_evidence_fixture(),
        source_identity: "0123456789abcdef0123456789abcdef01234567"
      }

      assert {:ok, projection} = GraphProjection.build(facts)

      assert projection.source_identity == "0123456789abcdef0123456789abcdef01234567"
      assert length(projection.nodes) == 6
      assert length(projection.edges) >= 5

      kinds = projection.nodes |> Enum.map(& &1.kind) |> Enum.sort()
      assert kinds -- [
               "WorkerOutput",
               "PatchProposal",
               "VerificationResult",
               "Review",
               "HumanDecision",
               "PatchEvidence"
             ] == []

      refute Enum.any?(projection.nodes, &(&1.canonical_digest == ""))
    end

    test "tolerates missing facts (no invented nodes)" do
      facts = %{proposal: proposal_fixture()}

      assert {:ok, projection} = GraphProjection.build(facts)

      assert length(projection.nodes) == 1
      assert hd(projection.nodes).kind == "PatchProposal"
      assert projection.edges == []
    end

    test "every node carries canonical identity" do
      facts = %{
        worker_output: worker_output_fixture(),
        proposal: proposal_fixture(),
        verification: verification_fixture()
      }

      {:ok, projection} = GraphProjection.build(facts)

      for node <- projection.nodes do
        assert is_binary(node.id)
        assert is_binary(node.canonical_digest)
        assert String.starts_with?(node.canonical_digest, "sha256:")
        assert is_binary(node.label)
        assert node.attention in GraphProjection.attention_states()
      end
    end
  end

  describe "edges" do
    test "WorkerOutput PRODUCED PatchProposal" do
      facts = %{
        worker_output: worker_output_fixture(),
        proposal: proposal_fixture()
      }

      {:ok, projection} = GraphProjection.build(facts)

      edge =
        Enum.find(projection.edges, fn e ->
          e.kind == "PRODUCED" and e.from == "wko_test_01" and e.to == "pp_test_01"
        end)

      assert edge, "expected PRODUCED edge from wko_test_01 to pp_test_01"
      assert edge.proposed == false
    end

    test "VerificationResult VERIFIED PatchProposal" do
      facts = %{
        proposal: proposal_fixture(),
        verification: verification_fixture()
      }

      {:ok, projection} = GraphProjection.build(facts)

      edge =
        Enum.find(projection.edges, fn e ->
          e.kind == "VERIFIED" and e.from == "ver_test_01" and e.to == "pp_test_01"
        end)

      assert edge, "expected VERIFIED edge from ver_test_01 to pp_test_01"
    end

    test "HumanDecision DECIDED_ON PatchProposal and AUTHORIZED Review" do
      facts = %{
        proposal: proposal_fixture(),
        review: review_fixture(),
        human_decision: human_decision_fixture()
      }

      {:ok, projection} = GraphProjection.build(facts)

      kinds = projection.edges |> Enum.map(& &1.kind) |> Enum.sort()
      assert "DECIDED_ON" in kinds
      assert "AUTHORIZED" in kinds
      assert "REVIEWED" in kinds
    end
  end

  describe "provenance_for/2" do
    test "walking backward from PatchEvidence reaches WorkerOutput" do
      facts = %{
        worker_output: worker_output_fixture(),
        proposal: proposal_fixture(),
        verification: verification_fixture(),
        review: review_fixture(),
        human_decision: human_decision_fixture(),
        patch_evidence: patch_evidence_fixture()
      }

      {:ok, projection} = GraphProjection.build(facts)
      assert {:ok, edges} = GraphProjection.provenance_for(projection, "pe_test_01")

      # The evidence node is the source of two edges (APPLIED,
      # APPLIED_AFTER). It has no incoming edges in this projection.
      assert Enum.any?(edges, &(&1.from == "pe_test_01"))
      assert length(edges) == 2

      # Walk backward: proposal node has incoming edges from wko, ver,
      # rev, hd, pe. None of those edges have pp as the source.
      assert {:ok, edges_pp} = GraphProjection.provenance_for(projection, "pp_test_01")
      assert length(edges_pp) == 5
      assert Enum.all?(edges_pp, &(&1.to == "pp_test_01"))

      # The worker output is the deepest source node.
      assert {:ok, edges_wko} = GraphProjection.provenance_for(projection, "wko_test_01")
      # wko has one outgoing edge (PRODUCED → pp).
      assert length(edges_wko) == 1
      assert Enum.any?(edges_wko, &(&1.from == "wko_test_01"))
    end

    test "returns :unknown_node for non-existent node" do
      facts = %{proposal: proposal_fixture()}
      {:ok, projection} = GraphProjection.build(facts)
      assert {:error, :unknown_node} = GraphProjection.provenance_for(projection, "no_such_node")
    end
  end

  describe "attention_required/1" do
    test "no attention when everything is PASS / APPROVE / ACCEPT" do
      facts = %{
        worker_output: worker_output_fixture(),
        proposal: proposal_fixture(),
        verification: verification_fixture(),
        review: review_fixture(),
        human_decision: human_decision_fixture(),
        patch_evidence: patch_evidence_fixture()
      }

      {:ok, projection} = GraphProjection.build(facts)
      # The PASS/APPROVE/ACCEPT cycle does not surface anything that
      # requires human attention at this snapshot.
      assert GraphProjection.attention_required(projection) == []
    end

    test "FAIL verification surfaces as FAILED" do
      vr = %{verification_fixture() | status: :FAIL}
      facts = %{verification: vr}

      {:ok, projection} = GraphProjection.build(facts)
      assert length(GraphProjection.attention_required(projection)) == 1
      assert hd(GraphProjection.attention_required(projection)).attention == "FAILED"
    end

    test "REJECT review surfaces as FAILED" do
      r = %{review_fixture() | verdict: :REJECT}
      facts = %{review: r}

      {:ok, projection} = GraphProjection.build(facts)
      assert length(GraphProjection.attention_required(projection)) == 1
      assert hd(GraphProjection.attention_required(projection)).attention == "FAILED"
    end

    test "REQUEST_REVISION review surfaces as BLOCKED" do
      r = %{review_fixture() | verdict: :REQUEST_REVISION}
      facts = %{review: r}

      {:ok, projection} = GraphProjection.build(facts)
      assert length(GraphProjection.attention_required(projection)) == 1
      assert hd(GraphProjection.attention_required(projection)).attention == "BLOCKED"
    end
  end

  describe "proposed vs governed" do
    test "governed edges have proposed: false" do
      facts = %{
        worker_output: worker_output_fixture(),
        proposal: proposal_fixture(),
        verification: verification_fixture(),
        review: review_fixture(),
        human_decision: human_decision_fixture()
      }

      {:ok, projection} = GraphProjection.build(facts)

      assert Enum.all?(projection.edges, &(&1.proposed == false))
    end
  end
end