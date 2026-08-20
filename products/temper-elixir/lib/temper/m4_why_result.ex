defmodule Temper.M4WhyResult do
  @moduledoc """
  M4 — explicit WHY result variants.

  Per Gate 3:
    EXPLAINABLE   — deterministic explanation grounded in canonical structure
    INCOMPLETE    — canonical information exists but is insufficient
    UNSUPPORTED   — the current Why capability does not support this
                    subject/relationship

  Deterministic WHY is the default. Model intelligence is never
  required for canonical explanation.

  Architecture: Temper.M4 (M4-Q1, lane M4).
  """

  alias Kiln.Domain.SubjectIdentity
  alias Kiln.{GraphProjection, WhyPacket}

  @type status :: :explainable | :incomplete | :unsupported

  @type t :: %__MODULE__{
          status: status(),
          packet: WhyPacket.t() | nil,
          reason: String.t() | nil
        }

  defstruct status: :unsupported, packet: nil, reason: nil

  @doc "Build a deterministic WHY result for a SubjectIdentity."
  @spec for_subject(GraphProjection.projection(), SubjectIdentity.t()) :: t()
  def for_subject(projection, %SubjectIdentity{} = subject) do
    cond do
      not subject_in_projection?(subject, projection) ->
        %__MODULE__{status: :unsupported, reason: "SubjectIdentity not in current projection"}

      true ->
        packet = WhyPacket.for_subject(projection, subject)

        if sufficient_for_explanation?(packet) do
          %__MODULE__{status: :explainable, packet: packet, reason: nil}
        else
          %__MODULE__{status: :incomplete, packet: packet, reason: "Canonical refs insufficient for full explanation"}
        end
    end
  end

  @doc "Build a deterministic WHY result for a graph edge."
  @spec for_edge(GraphProjection.projection(), String.t()) :: t()
  def for_edge(projection, edge_id) do
    edge = Enum.find(projection.edges, &(&1.id == edge_id))

    case edge do
      nil ->
        %__MODULE__{status: :unsupported, reason: "Edge not in current projection"}

      e ->
        packet = WhyPacket.for_edge(projection, e.id)
        %__MODULE__{status: :explainable, packet: packet, reason: nil}
    end
  end

  defp subject_in_projection?(%SubjectIdentity{canonical_id: id}, projection) do
    Enum.any?(projection.nodes, &(&1.id == id))
  end

  defp sufficient_for_explanation?(packet) do
    # The packet has a target_subject (the focused subject). The
    # canonical evidence is in allowed_evidence_refs and the
    # backward chain. If the packet has a target_subject and at
    # least one piece of canonical context (a basis or an evidence
    # ref), it is EXPLAINABLE.
    has_target = packet.target_subject != nil
    has_basis = is_binary(packet.canonical_basis) and byte_size(packet.canonical_basis) > 0
    has_evidence = is_list(packet.allowed_evidence_refs) and packet.allowed_evidence_refs != []
    has_relationship = is_binary(packet.relationship) and byte_size(packet.relationship) > 0
    has_backward_chain = is_list(packet.provenance_backward_chain)

    has_target and (has_basis or has_evidence or has_relationship or has_backward_chain)
  end
end
