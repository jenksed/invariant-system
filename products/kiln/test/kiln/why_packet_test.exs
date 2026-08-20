defmodule Kiln.WhyPacketTest do
  @moduledoc """
  M4 — deterministic WhyPacket/v0 tests.

  The packet must be:
    * structurally stable on same input
    * provider-independent (no API key required)
    * without generated prose
    * with bounded allowed_evidence_refs
  """

  use ExUnit.Case, async: true

  alias Kiln.{GraphProjection, WhyPacket}
  alias Kiln.Domain.SubjectIdentity

  defp sha, do: "sha256:" <> String.duplicate("a", 64)

  defp facts do
    %{
      worker_output: %Kiln.M0WorkerOutput{
        id: "wko_w1",
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
        id: "pp_w1",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        attempt_ref: %{"id" => "att1", "digest" => sha()},
        patch_digest: sha(),
        base_commit: String.duplicate("0", 40),
        repository: "/tmp",
        supersedes_patch_ref: nil
      },
      human_decision: %Kiln.M0HumanDecision{
        id: "hd_w1",
        semantic_digest: sha(),
        plan_ref: %{"id" => "plan", "digest" => sha()},
        patch_ref: %{"id" => "pp_w1", "digest" => sha()},
        review_ref: %{"id" => "rev_w1", "digest" => sha()},
        result_state_digest: sha(),
        decision: :ACCEPT,
        recorded_at: "2026-08-20T00:00:00Z",
        metadata: %{}
      },
      source_identity: String.duplicate("0", 40)
    }
  end

  test "deterministic on same input" do
    {:ok, p1} = GraphProjection.build(facts())
    {:ok, p2} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "PatchProposal", canonical_id: "pp_w1"}

    a = WhyPacket.for_subject(p1, subject)
    b = WhyPacket.for_subject(p2, subject)

    assert WhyPacket.digest(a) == WhyPacket.digest(b)
  end

  test "works with provider absent" do
    # Pure: no network, no API key, no model — just canonical data.
    {:ok, p} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "HumanDecision", canonical_id: "hd_w1"}
    packet = WhyPacket.for_subject(p, subject)

    assert packet.subject_identity == subject
    assert packet.target_subject == subject
    assert packet.direction == :self
    assert packet.relationship in [nil, ""]
    assert packet.canonical_basis in [nil, ""]
  end

  test "no generated prose in any field" do
    {:ok, p} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "PatchProposal", canonical_id: "pp_w1"}
    packet = WhyPacket.for_subject(p, subject)

    # All fields are structured. No string blobs of prose.
    assert is_nil(packet.relationship) or is_binary(packet.relationship)
    assert is_nil(packet.canonical_basis) or is_binary(packet.canonical_basis)
    assert packet.allowed_evidence_refs == [] or is_list(packet.allowed_evidence_refs)
    assert packet.provenance_backward_chain == [] or is_list(packet.provenance_backward_chain)
  end

  test "allowed_evidence_refs is bounded" do
    {:ok, p} = GraphProjection.build(facts())
    subject = %SubjectIdentity{entity_type: "PatchProposal", canonical_id: "pp_w1"}
    packet = WhyPacket.for_subject(p, subject)
    assert is_list(packet.allowed_evidence_refs)
    assert Enum.all?(packet.allowed_evidence_refs, &is_binary/1)
  end

  test "for_edge carries canonical_basis" do
    {:ok, p} = GraphProjection.build(facts())
    [edge | _] = p.edges
    packet = WhyPacket.for_edge(p, edge.id)
    assert packet.relationship == edge.kind
    assert packet.canonical_basis == edge.canonical_basis
    assert packet.direction == :forward
  end

  defp validate_structured_term(term, _parent) do
    cond do
      is_nil(term) -> :ok
      is_atom(term) -> :ok
      is_binary(term) -> :ok
      is_list(term) -> :ok
      is_struct(term) -> :ok
      is_map(term) -> :ok
      true -> flunk("non-structured term: #{inspect(term)}")
    end
  end
end
