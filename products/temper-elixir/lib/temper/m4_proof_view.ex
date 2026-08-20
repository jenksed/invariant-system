defmodule Temper.M4ProofView do
  @moduledoc """
  M4 — PROOF view: backward canonical provenance traversal.

  Walks backward by following the canonical `*_ref` fields in the
  M0 envelopes. The GraphProjection's edges are forward (cause →
  effect); the proof view's reverse walk follows the inverse.

  Example chain for PatchEvidence:

    Worker
      ↓ produced
    Patch
      ├─ verified by → Verification
      ├─ reviewed by → Review
      └─ authorized by → HumanDecision
                              ↓
                         PatchEvidence
  """

  alias Kiln.GraphProjection
  alias Temper.CellFrame

  @type trace :: [String.t()]

  @doc """
  Build the canonical backward trace from a starting node id.
  """
  @spec trace(GraphProjection.projection(), String.t()) :: trace()
  def trace(projection, start_id) do
    by_id = Map.new(projection.nodes, &{&1.id, &1})

    cond do
      not Map.has_key?(by_id, start_id) ->
        ["(unknown starting node)"]

      true ->
        # Build a forward-edge adjacency; the proof walk follows
        # predecessors of the current node, which is the same as
        # the reverse of the forward adjacency.
        forward = build_forward_adjacency(projection)
        backward(forward, by_id, [start_id], [], MapSet.new())
    end
  end

  defp build_forward_adjacency(projection) do
    Enum.reduce(projection.edges, %{}, fn edge, acc ->
      Map.update(acc, edge.from, [edge.to | Map.get(acc, edge.from, [])], fn existing -> existing end)
    end)
  end

  defp backward(_adj, _by_id, [], acc, _seen), do: Enum.reverse(acc)

  defp backward(adj, by_id, [id | rest], acc, seen) do
    node = Map.get(by_id, id)

    cond do
      is_nil(node) -> backward(adj, by_id, rest, acc, seen)
      MapSet.member?(seen, id) -> backward(adj, by_id, rest, acc, seen)
      true ->
        new_seen = MapSet.put(seen, id)
        label = label_for_kind(node.kind)
        acc = [label | acc]
        # Predecessors of X = union of:
        #   - targets of edges FROM X (X depends on Y, e.g.
        #     APPLIED_AFTER pe -> hd means pe depends on hd)
        #   - sources of edges TO X (X was produced by Y, e.g.
        #     PRODUCED wko -> pp means pp was produced by wko)
        predecessors = predecessors_of(adj, id)
        backward(adj, by_id, predecessors ++ rest, acc, new_seen)
    end
  end

  defp predecessors_of(adj, target_id) do
    outgoing = Map.get(adj, target_id, [])
    incoming = sources_pointing_at(adj, target_id)
    Enum.uniq(outgoing ++ incoming)
  end

  defp sources_pointing_at(adj, target_id) do
    Enum.flat_map(adj, fn {from, tos} ->
      if Enum.any?(tos, &(&1 == target_id)), do: [from], else: []
    end)
  end

  defp label_for_kind("WorkerOutput"), do: "Worker"
  defp label_for_kind("PatchProposal"), do: "Patch"
  defp label_for_kind("VerificationResult"), do: "Verification"
  defp label_for_kind("Review"), do: "Review"
  defp label_for_kind("HumanDecision"), do: "HumanDecision"
  defp label_for_kind("PatchEvidence"), do: "PatchEvidence"
  defp label_for_kind("EngineeringObjective"), do: "Objective"
  defp label_for_kind(other), do: other

  @doc "Render the proof view as a CellFrame."
  @spec render(GraphProjection.projection(), String.t(), pos_integer(), pos_integer()) :: CellFrame.t()
  def render(projection, start_id, rows, cols) do
    lines = trace(projection, start_id)

    header = "PROOF — backward trace"
    footer = "back returns to map"

    tree =
      [{:line, 0, 0, header, "header"}] ++
        Enum.with_index(lines, fn line, i ->
          {:line, i + 2, 0, indent_for(i) <> line, "normal"}
        end) ++
        [{:line, rows - 1, 0, footer, "footer"}]

    CellFrame.render(tree, rows, cols)
  end

  defp indent_for(0), do: ""
  defp indent_for(1), do: "  "
  defp indent_for(2), do: "    "
  defp indent_for(_), do: "      "
end
