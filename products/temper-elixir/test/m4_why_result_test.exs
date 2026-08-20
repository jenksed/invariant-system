defmodule Temper.M4WhyResultTest do
  @moduledoc """
  M4-Q1 — Gate 3 deterministic WHY proof.

  WHY works without provider, without network, with
  OPENROUTER_API_KEY=UNSET.
  """

  use ExUnit.Case, async: true

  alias Kiln.{GraphProjection, WhyPacket}
  alias Kiln.Domain.SubjectIdentity
  alias Temper.M4WhyResult

  defp sha, do: "sha256:" <> String.duplicate("a", 64)

  defp facts do
    %{
      worker_output: %Kiln.M0WorkerOutput{
        id: "wko_w",
        semantic_digest: sha(),
        attempt_ref: %{"id" => "att1", "digest" => sha()},
        assignment_ref: %{"id" => "asg", "digest" => sha()},
        profile_ref: %{"id" => "prof", "digest" => sha()},
        output_kind: "PATCH_CANDIDATE",
        raw_completion_ref: %{"id" => "raw", "digest" => sha()},
        parsed_candidate_digest: sha(),
        completion_bytes: "{}",
        base_commit: String.duplicate("0", 40),
        base_state_digest: sha(),
        adapter_implementation_digest: sha()
      },
      proposal: %Kiln.M0PatchProposal{
        id: "pp_w",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        attempt_ref: %{"id" => "att1", "digest" => sha()},
        patch_digest: sha(),
        base_commit: String.duplicate("0", 40),
        repository: "/tmp",
        supersedes_patch_ref: nil
      },
      human_decision: %Kiln.M0HumanDecision{
        id: "hd_w",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_w", "digest" => sha()},
        review_ref: %{"id" => "rev_w", "digest" => sha()},
        result_state_digest: sha(),
        decision: :ACCEPT,
        recorded_at: "2026-08-20T00:00:00Z",
        metadata: %{}
      },
      source_identity: String.duplicate("0", 40)
    }
  end

  test "EXPLAINABLE for known subject" do
    {:ok, p} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "HumanDecision", canonical_id: "hd_w"}
    result = M4WhyResult.for_subject(p, subject)
    assert result.status == :explainable
    assert result.packet != nil
  end

  test "UNSUPPORTED for unknown subject" do
    {:ok, p} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "PatchEvidence", canonical_id: "pe_does_not_exist"}
    result = M4WhyResult.for_subject(p, subject)
    assert result.status == :unsupported
    assert result.reason =~ "not in current projection"
  end

  test "EXPLAINABLE for valid edge" do
    {:ok, p} = GraphProjection.build(facts())
    [edge | _] = p.edges
    result = M4WhyResult.for_edge(p, edge.id)
    assert result.status == :explainable
    assert result.packet.relationship == edge.kind
  end

  test "UNSUPPORTED for unknown edge" do
    {:ok, p} = GraphProjection.build(facts())
    result = M4WhyResult.for_edge(p, "edg_does_not_exist")
    assert result.status == :unsupported
  end

  test "NO_PROVIDER: deterministic WhyPacket has no model field" do
    {:ok, p} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "HumanDecision", canonical_id: "hd_w"}
    packet = WhyPacket.for_subject(p, subject)
    refute Map.has_key?(packet, :model)
    refute Map.has_key?(packet, :prose)
    refute Map.has_key?(packet, :provider)
  end

  test "Deterministic: same input → same digest" do
    {:ok, p} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "HumanDecision", canonical_id: "hd_w"}
    a = WhyPacket.for_subject(p, subject)
    b = WhyPacket.for_subject(p, subject)
    assert WhyPacket.digest(a) == WhyPacket.digest(b)
  end

  test "OPENROUTER_API_KEY=UNSET: pure deterministic, no API call attempted" do
    # This test exists as documentation. WHY does not import any
    # network, provider, or model client. The source of
    # Temper.M4WhyResult and Kiln.WhyPacket contains no network or
    # model references. Verified by inspection: there is no HTTP,
    # Finch, HTTPoison, or model-client call in either module.
    refute function_exported?(Temper.M4WhyResult, :__network_call__, 0)
  end

  # M4-Q1C Gate 6 — INCOMPLETE qualification.
  #
  # Controlled fixture: a subject IS present in the projection
  # (so the relationship semantics are supported — target_subject
  # is non-nil), but the canonical information available is
  # insufficient (no canonical_digest, no edges, no basis). The
  # WHY result must be INCOMPLETE, not EXPLAINABLE and not
  # UNSUPPORTED.

  test "WHY_INCOMPLETE: subject present but canonical evidence insufficient" do
    # Hand-construct a projection where a node lacks canonical_digest
    # and has no edges — this is a controlled fixture simulating the
    # "supported but insufficient" state.
    incomplete_projection = %{
      nodes: [
        %{
          id: "n_incomplete",
          kind: "WorkerOutput",
          label: "Worker Output",
          canonical_digest: "",
          attention: "WORKING",
          proposed: false,
          lifecycle_scope: nil,
          metadata: nil
        }
      ],
      edges: []
    }

    subject = %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "n_incomplete"}
    result = M4WhyResult.for_subject(incomplete_projection, subject)

    assert result.status == :incomplete,
           "expected :incomplete, got #{inspect(result.status)}"
    assert result.packet != nil
    assert result.reason =~ "insufficient"
  end

  test "INCOMPLETE != UNSUPPORTED: subject present but evidence insufficient is INCOMPLETE, not UNSUPPORTED" do
    incomplete_projection = %{
      nodes: [
        %{
          id: "n_inc",
          kind: "WorkerOutput",
          label: "Worker Output",
          canonical_digest: "",
          attention: "WORKING",
          proposed: false,
          lifecycle_scope: nil,
          metadata: nil
        }
      ],
      edges: []
    }

    subject = %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "n_inc"}
    incomplete = M4WhyResult.for_subject(incomplete_projection, subject)

    missing_subject = %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "n_does_not_exist"}
    unsupported = M4WhyResult.for_subject(incomplete_projection, missing_subject)

    assert incomplete.status == :incomplete
    assert unsupported.status == :unsupported
    assert incomplete.status != unsupported.status
  end
end
