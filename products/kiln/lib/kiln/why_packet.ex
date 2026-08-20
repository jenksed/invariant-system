defmodule Kiln.WhyPacket do
  @moduledoc """
  M4 — deterministic WhyPacket/v0.

  A WhyPacket is derived from ONE canonical SubjectIdentity or
  CanonicalGraphEdge. It carries only structured canonical data —
  no generated prose.

  Same canonical input → structurally equivalent WhyPacket.

  The packet is the contract that any bounded intelligence
  (M4-LI0) must consume and any deterministic renderer must
  produce. It is the smallest bounded surface that survives
  provider absence.

  Architecture: Kiln.M4 (M4-A, lane M4).
  """

  alias Kiln.Domain.SubjectIdentity

  @schema_version "WhyPacket/v0"

  @type t :: %__MODULE__{
          version: String.t(),
          subject_identity: SubjectIdentity.t() | nil,
          relationship: String.t() | nil,
          source_subject: SubjectIdentity.t() | nil,
          target_subject: SubjectIdentity.t() | nil,
          direction: :forward | :backward | :self | nil,
          canonical_basis: String.t() | nil,
          relevant_status: map() | nil,
          allowed_evidence_refs: [String.t()],
          lifecycle_scope: String.t() | nil,
          provenance_backward_chain: [SubjectIdentity.t()],
          siblings: [SubjectIdentity.t()]
        }

  defstruct version: @schema_version,
            subject_identity: nil,
            relationship: nil,
            source_subject: nil,
            target_subject: nil,
            direction: nil,
            canonical_basis: nil,
            relevant_status: nil,
            allowed_evidence_refs: [],
            lifecycle_scope: nil,
            provenance_backward_chain: [],
            siblings: []

  @doc "Schema version string for serialization compatibility."
  @spec version() :: String.t()
  def version, do: @schema_version

  @doc """
  Build a WhyPacket from a graph projection and a subject identity.

  The packet is canonical and deterministic: same projection +
  same subject ⇒ equivalent packet.
  """
  @spec for_subject(Kiln.GraphProjection.projection(), SubjectIdentity.t() | nil) :: t()
  def for_subject(projection, %SubjectIdentity{} = subject) do
    node = Enum.find(projection.nodes, &(&1.id == subject.canonical_id))
    incoming = Enum.filter(projection.edges, &(&1.to == subject.canonical_id))
    outgoing = Enum.filter(projection.edges, &(&1.from == subject.canonical_id))

    %{
      __struct__: __MODULE__,
      version: @schema_version,
      subject_identity: subject,
      relationship: nil,
      source_subject: nil,
      target_subject: subject,
      direction: :self,
      canonical_basis: nil,
      relevant_status: node && node.metadata,
      allowed_evidence_refs: allowed_evidence_refs_for(node),
      lifecycle_scope: node && node.lifecycle_scope,
      provenance_backward_chain: backward_chain_for(projection, subject),
      siblings: siblings_for(projection, incoming, outgoing, subject)
    }
  end

  def for_subject(_projection, nil) do
    %__MODULE__{}
  end

  @doc """
  Build a WhyPacket from a graph projection and a graph edge
  (identified by edge_id).
  """
  @spec for_edge(Kiln.GraphProjection.projection(), String.t()) :: t()
  def for_edge(projection, edge_id) do
    edge = Enum.find(projection.edges, &(&1.id == edge_id))
    by_id = Map.new(projection.nodes, &{&1.id, &1})

    case edge do
      nil ->
        %__MODULE__{}

      e ->
        %{
          __struct__: __MODULE__,
          version: @schema_version,
          subject_identity: nil,
          relationship: e.kind,
          source_subject: subject_of(Map.get(by_id, e.from)),
          target_subject: subject_of(Map.get(by_id, e.to)),
          direction: e.direction,
          canonical_basis: e.canonical_basis,
          relevant_status: nil,
          allowed_evidence_refs: [],
          lifecycle_scope: e.lifecycle_scope,
          provenance_backward_chain: [],
          siblings: []
        }
    end
  end

  @doc "Stable digest of a WhyPacket for input-digest comparison."
  @spec digest(t()) :: String.t()
  def digest(packet) do
    fields = [
      packet.version,
      packet.relationship || "",
      packet.canonical_basis || "",
      packet.direction,
      packet.lifecycle_scope || "",
      digest_subject(packet.source_subject),
      digest_subject(packet.target_subject),
      digest_subject(packet.subject_identity),
      packet.allowed_evidence_refs |> Enum.sort() |> Enum.join(","),
      packet.provenance_backward_chain |> Enum.map(&SubjectIdentity.digest/1) |> Enum.join(","),
      packet.siblings |> Enum.map(&SubjectIdentity.digest/1) |> Enum.sort() |> Enum.join(",")
    ]

    "sha256:" <> Base.encode16(:crypto.hash(:sha256, Enum.join(fields, "|")), case: :lower)
  end

  # --- private ---

  defp subject_of(nil), do: nil
  defp subject_of(%{id: id, kind: kind}), do: %SubjectIdentity{entity_type: kind, canonical_id: id}

  defp digest_subject(nil), do: ""
  defp digest_subject(%SubjectIdentity{entity_type: t, canonical_id: id}), do: t <> "/" <> id

  defp allowed_evidence_refs_for(nil), do: []
  defp allowed_evidence_refs_for(node) do
    # The node's canonical digest is the primary evidence ref.
    if is_binary(node.canonical_digest) and byte_size(node.canonical_digest) > 0 do
      [node.canonical_digest]
    else
      []
    end
  end

  defp backward_chain_for(projection, %SubjectIdentity{} = subject) do
    by_id = Map.new(projection.nodes, &{&1.id, &1})

    projection.edges
    |> Enum.filter(&(&1.to == subject.canonical_id))
    |> Enum.flat_map(fn edge ->
      case Map.get(by_id, edge.from) do
        nil -> []
        from_node -> [subject_of(from_node)]
      end
    end)
    |> Enum.uniq()
  end

  defp backward_chain_for(_projection, _), do: []

  defp siblings_for(_projection, incoming, outgoing, %SubjectIdentity{} = subject) do
    edges = incoming ++ outgoing

    edges
    |> Enum.flat_map(fn edge ->
      other_id = if edge.from == subject.canonical_id, do: edge.to, else: edge.from

      if other_id == subject.canonical_id do
        []
      else
        [%SubjectIdentity{entity_type: "EdgeEndpoint", canonical_id: other_id}]
      end
    end)
    |> Enum.uniq()
  end
end
