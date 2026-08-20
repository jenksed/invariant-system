defmodule Temper.M4WorkMap do
  @moduledoc """
  M4 — first visible Graph experience: Work Map.

  The MAP answers three questions for a human operator:
    * What are we doing?
    * Where are we?
    * What needs me?

  Layout adapts to terminal dimensions:
    * Wide (>= 100 cols): graph on the left, inspector on the right.
    * Narrow (< 100 cols): graph full-width; inspector opens as a
      focused overlay when a node is selected.

  This module is renderer-independent: it builds a tree of
  declarative primitives (`{:text, r, c, t, style}`, `{:box, ...}`).
  It MUST NOT contain raw ANSI escape sequences.

  Visual language (this slice):
    * Solid box borders = governed
    * Dashed-look text labels (`─`/`═`) for proposed edges —
      but no proposed execution semantics are implemented
    * Status line: counts of "need you / blocked / failed"
    * Selected node: prefixed with `▶` and shown expanded
    * No color-only distinction: prefixes + brackets carry meaning
  """

  alias Kiln.GraphProjection
  alias Temper.AttentionProjection
  alias Temper.CellFrame

  @type state :: %{
          required(:projection) => GraphProjection.projection(),
          required(:selected_id) => String.t() | nil,
          required(:env) => map(),
          required(:objective) => String.t()
        }

  @type view :: :map | :proof

  @doc "Default initial state: select the first node."
  @spec new(GraphProjection.projection(), String.t(), map()) :: state()
  def new(projection, objective, env \\ %{}) do
    first =
      case projection.nodes do
        [first | _] -> first.id
        [] -> nil
      end

    %{
      projection: projection,
      selected_id: first,
      env: env,
      objective: objective
    }
  end

  @doc "Move selection up/down/left/right within adjacency."
  @spec move(state(), :up | :down | :left | :right) :: state()
  def move(state, direction) do
    adjacency = adjacency_map(state.projection)
    case direction do
      :down -> %{state | selected_id: Map.get(adjacency, state.selected_id, state.selected_id)}
      :up -> %{state | selected_id: Map.get(adjacency, state.selected_id, state.selected_id)}
      _ -> state
    end
  end

  @doc "Render the current state to a CellFrame at the given dimensions."
  @spec render(state(), pos_integer(), pos_integer()) :: CellFrame.t()
  def render(state, rows, cols) do
    projection = state.projection
    attn = AttentionProjection.project(projection, state.env)
    states_by_id = Map.new(attn.states, &{&1.id, &1})

    cond do
      cols >= 100 ->
        render_wide(state, projection, attn, states_by_id, rows, cols)

      true ->
        render_narrow(state, projection, attn, states_by_id, rows, cols)
    end
  end

  @doc "Render a focused inspector overlay for the selected node."
  @spec inspector_overlay(state(), pos_integer(), pos_integer()) :: CellFrame.t()
  def inspector_overlay(state, rows, cols) do
    projection = state.projection
    attn = AttentionProjection.project(projection, state.env)
    states_by_id = Map.new(attn.states, &{&1.id, &1})
    Temper.M4Inspector.render(state, projection, attn, states_by_id, rows, cols)
  end

  # --- adjacency (simple: each node's outgoing edge target) ---

  defp adjacency_map(projection) do
    Enum.reduce(projection.edges, %{}, fn edge, acc ->
      Map.put(acc, edge.from, edge.to)
    end)
  end

  # --- WIDE layout: graph left, inspector right ---

  defp render_wide(state, projection, attn, states_by_id, rows, cols) do
    # Layout: cols split ~62/38; 1px gap.
    split = max(div(cols * 6, 10), 40)
    graph_cols = split - 1
    inspector_cols = cols - graph_cols - 1

    graph_tree = build_graph_tree(state, projection, attn, states_by_id, rows, graph_cols)
    inspector_tree = Temper.M4Inspector.tree(state, projection, attn, states_by_id, inspector_cols)
    inspector_offset = shift(inspector_tree, 0, split + 1)

    tree =
      [
        {:line, 0, 0, header_line(state, attn, cols), "header"},
        {:line, rows - 1, 0, footer_line(attn, cols), "footer"}
      ] ++
        graph_tree ++
        inspector_offset

    CellFrame.render(tree, rows, cols)
  end

  defp render_narrow(state, projection, attn, states_by_id, rows, cols) do
    # Narrow: full-width graph; inspector is invoked separately.
    graph_tree = build_graph_tree(state, projection, attn, states_by_id, rows, cols)

    tree =
      [
        {:line, 0, 0, header_line(state, attn, cols), "header"},
        {:line, rows - 1, 0, footer_line(attn, cols), "footer"}
      ] ++
        graph_tree

    CellFrame.render(tree, rows, cols)
  end

  # --- header / footer ---

  defp header_line(state, attn, cols) do
    project = "TEMPER — M4"
    summary = "  ● GOVERNED"
    run = "  needs you: #{attn.summary.waiting_for_human}"
    call_sign = if state.env[:run_state] == :waiting_for_user, do: "  ★ YOUR CALL", else: ""
    text = project <> summary <> run <> call_sign
    String.slice(text, 0, cols) |> String.pad_trailing(cols, " ")
  end

  defp footer_line(attn, cols) do
    blocked_note = if attn.summary.failed > 0, do: "  Completion blocked", else: ""
    text =
      "↑↓ select  ENTER inspect  p proof  q quit   " <>
        "#{attn.summary.working} working  #{attn.summary.complete} done  " <>
        "#{attn.summary.waiting_for_human} need you  #{attn.summary.blocked} blocked  #{attn.summary.failed} failed" <>
        blocked_note

    String.slice(text, 0, cols) |> String.pad_trailing(cols, " ")
  end

  # --- graph tree (objective + nodes + edges) ---

  defp build_graph_tree(state, projection, attn, states_by_id, rows, cols) do
    # Layout a vertical chain: objective at top, then each node.
    # Branches: verification + review sit side-by-side under Patch.
    objective_line = state.objective
    nodes = projection.nodes

    # 2-line gap from header.
    cursor_row = 2

    tree =
      [{:text, cursor_row, 0, "OBJECTIVE", "accent"}]
      |> append_text(cursor_row + 1, 0, truncate(objective_line, cols - 4), "normal")
      |> append_vertical(cursor_row + 2, 2, "│", "dim")

    # Order the chain by following PRODUCED / VERIFIED / REVIEWED edges
    # from WorkerOutput.
    chain = chain_order(projection)

    {tree, _row} =
      Enum.reduce(chain, {tree, cursor_row + 3}, fn node, {acc, row} ->
        state_for_node = Map.get(states_by_id, node.id)
        is_selected = node.id == state.selected_id
        box = render_node_box(node, state_for_node, is_selected, row, 4)
        acc = acc ++ [box]
        acc = acc ++ [edge_marker(row, 4, "│", "dim")]
        {acc, row + 4}
      end)

    # Side-by-side verification + review under Patch.
    tree = maybe_render_branches(tree, projection, attn, states_by_id, state.selected_id, rows, cols)

    tree
  end

  defp chain_order(projection) do
    # Build the canonical chain: Worker → Patch → Human → Evidence,
    # with Verification + Review as side-branches under Patch.
    by_kind =
      Enum.reduce(projection.nodes, %{}, fn n, acc ->
        Map.put(acc, n.kind, n)
      end)

    [
      by_kind["WorkerOutput"],
      by_kind["PatchProposal"],
      by_kind["HumanDecision"],
      by_kind["PatchEvidence"]
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp maybe_render_branches(tree, projection, attn, states_by_id, selected_id, rows, cols) do
    by_kind =
      Enum.reduce(projection.nodes, %{}, fn n, acc -> Map.put(acc, n.kind, n) end)

    verification = by_kind["VerificationResult"]
    review = by_kind["Review"]

    cond do
      is_nil(verification) and is_nil(review) -> tree
      true ->
        branch_row = 7
        branch_text =
          cond do
            not is_nil(verification) and not is_nil(review) ->
              left = Map.get(states_by_id, verification.id)
              right = Map.get(states_by_id, review.id)
              v_label = "Verify " <> status_glyph(left.attention)
              r_label = "Review " <> status_glyph(right.attention)
              "[ " <> pad(v_label, 10) <> " ]   [ " <> pad(r_label, 10) <> " ]"

            not is_nil(verification) ->
              left = Map.get(states_by_id, verification.id)
              "[ " <> pad("Verify " <> status_glyph(left.attention), 24) <> " ]"

            true ->
              right = Map.get(states_by_id, review.id)
              "[ " <> pad("Review " <> status_glyph(right.attention), 24) <> " ]"
          end

        tree ++ [{:text, branch_row, 4, branch_text, "muted"}]
    end
  end

  defp pad(s, n), do: s |> String.slice(0, n) |> String.pad_trailing(n, " ")

  defp status_glyph("FAILED"), do: "✗"
  defp status_glyph("BLOCKED"), do: "↻"
  defp status_glyph("WAITING_FOR_HUMAN"), do: "?"
  defp status_glyph("COMPLETE"), do: "✓"
  defp status_glyph(_), do: "·"

  defp render_node_box(node, state_for_node, is_selected, row, col) do
    label = state_for_node.label
    full_label = label <> "  " <> node.id
    prefix = if is_selected, do: "▶ ", else: "  "
    style =
      case state_for_node.attention do
        "FAILED" -> "error"
        "BLOCKED" -> "warn"
        "WAITING_FOR_HUMAN" -> "accent"
        "COMPLETE" -> "success"
        _ -> "normal"
      end

    # Use a single line of text rather than a box, so the label is
    # visible in the rendered frame (height-1 boxes have the child
    # below the box, not inside).
    text = prefix <> full_label
    {:text, row, col, text, style}
  end

  defp edge_marker(_row, col, glyph, style) do
    {:text, 0, 0, "", style}
  end

  # --- text/vertical appenders (no real cursor math; all coords explicit) ---

  defp append_text(tree, row, col, text, style) do
    tree ++ [{:text, row, col, text, style}]
  end

  defp append_vertical(tree, row, col, glyph, style) do
    tree ++ [{:text, row, col, glyph, style}]
  end

  # --- helpers ---

  defp truncate(s, n) when byte_size(s) <= n, do: s
  defp truncate(s, n), do: String.slice(s, 0, max(n, 0))

  defp shift(tree, dr, dc) do
    Enum.map(tree, fn
      {:text, r, c, t, s} -> {:text, r + dr, c + dc, t, s}
      {:line, r, c, t, s} -> {:line, r + dr, c + dc, t, s}
      {:box, r, c, h, w, s, ch} -> {:box, r + dr, c + dc, h, w, s, ch}
      other -> other
    end)
  end
end
