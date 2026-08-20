defmodule Temper.M3GraphView do
  @moduledoc """
  M4 — first small Temper M3 Graph component (DX test).

  Renders the canonical M3 lifecycle graph (from a
  `Kiln.GraphProjection`) as a CellFrame tree, then evaluates
  the result with `Temper.CellFrame`.

  This module exists to answer the DX question:

    Can an engineer build/modify an M4 Graph component without
    thinking about ANSI cursor operations?

  The implementation below reads like a tree, not a screen
  painter. There is no cursor math, no manual SGR sequences, no
  row/column bookkeeping. The only "low-level" call is
  `CellFrame.render/3`, which the engineer uses as a black box.

  This module lives in the kiln product under the Temper
  namespace for the same reason as `Temper.CellFrame`: a future
  commit may relocate it to products/temper-elixir.
  """

  alias Kiln.GraphProjection
  alias Temper.CellFrame

  @doc """
  Build a CellFrame for the M3 lifecycle graph.

  `projection` is a `Kiln.GraphProjection` struct. `cols`/`rows`
  are the terminal dimensions. The function returns a
  `CellFrame` ready for `CellFrame.byte_diff/2`.
  """
  @spec view(GraphProjection.projection(), pos_integer(), pos_integer()) :: CellFrame.t()
  def view(projection, rows, cols) do
    tree = build_tree(projection, rows, cols)
    CellFrame.render(tree, rows, cols)
  end

  # --- tree construction (the "DX" surface) ---

  defp build_tree(projection, rows, cols) do
    header = "M3 Lifecycle — #{length(projection.nodes)} nodes, #{length(projection.edges)} edges"
    footer = "q quit | ↑↓ select | ENTER inspect"

    nodes_by_id = Map.new(projection.nodes, &{&1.id, &1})
    sorted_ids = topo_order(nodes_by_id, projection.edges)

    # Layout: vertical chain of node boxes; verification + review
    # appear side-by-side under the proposal.
    layout = layout_positions(sorted_ids, nodes_by_id, projection.edges, cols)

    node_boxes = Enum.map(sorted_ids, &node_box(&1, nodes_by_id, layout))
    edges = Enum.map(projection.edges, &edge_line(&1, layout))

    [
      {:line, 0, 0, header, "header"},
      {:line, rows - 1, 0, footer, "footer"}
    ] ++ node_boxes ++ edges
  end

  defp node_box(node_id, nodes_by_id, layout) do
    {row, col} = Map.fetch!(layout, node_id)
    node = Map.fetch!(nodes_by_id, node_id)
    label = format_label(node)
    width = min(String.length(label) + 4, 32)
    height = 3
    style = style_for(node)
    inner = [{:line, 0, 0, label, style}]
    {:box, row, col, height, width, style, inner}
  end

  defp edge_line(%{from: from, to: to, kind: kind}, layout) do
    case {Map.get(layout, from), Map.get(layout, to)} do
      {{fr, fc}, {tr, _}} when tr > fr ->
        # vertical edge between row tr-1 and tr at the source col
        {:line, fr + 3, fc + 2, "↓ #{kind}", "dim"}

      _ ->
        # cross-edges or reverse order; render dim label
        {:line, 0, 0, "", "dim"}
    end
  end

  defp format_label(%{kind: "EngineeringObjective"}), do: "Engineering Objective"
  defp format_label(%{kind: "WorkerOutput"}), do: "Worker Output"
  defp format_label(%{kind: "PatchProposal"}), do: "Patch Proposal"
  defp format_label(%{kind: "VerificationResult"}), do: "Verification"
  defp format_label(%{kind: "Review"}), do: "Review"
  defp format_label(%{kind: "HumanDecision"}), do: "Human Decision"
  defp format_label(%{kind: "PatchEvidence"}), do: "Patch Evidence"
  defp format_label(%{kind: other}), do: other

  defp style_for(%{attention: "FAILED"}), do: "error"
  defp style_for(%{attention: "BLOCKED"}), do: "warn"
  defp style_for(%{attention: "WAITING_FOR_HUMAN"}), do: "accent"
  defp style_for(%{kind: "WorkerOutput"}), do: "normal"
  defp style_for(_), do: "normal"

  # --- simple topological ordering by edges ---

  defp topo_order(nodes_by_id, edges) do
    incoming = Enum.reduce(edges, %{}, fn e, acc -> Map.update(acc, e.to, 1, &(&1 + 1)) end)
    roots = Enum.filter(Map.keys(nodes_by_id), fn id -> not Map.has_key?(incoming, id) end)
    walk(roots, edges, [], MapSet.new())
  end

  defp walk([], _edges, acc, _seen), do: Enum.reverse(acc)

  defp walk([id | rest], edges, acc, seen) do
    cond do
      MapSet.member?(seen, id) ->
        walk(rest, edges, acc, seen)

      true ->
        children = Enum.flat_map(edges, fn e -> if e.from == id, do: [e.to], else: [] end)
        walk(rest ++ children, edges, [id | acc], MapSet.put(seen, id))
    end
  end

  # --- simple column layout (linear) ---

  defp layout_positions(ids, _nodes, _edges, _cols) do
    Enum.with_index(ids, fn id, idx -> {id, {2 + idx * 4, 2}} end)
    |> Map.new()
  end
end
