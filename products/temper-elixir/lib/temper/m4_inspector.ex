defmodule Temper.M4Inspector do
  @moduledoc """
  M4 — selected-node inspector panel.

  Renders canonical details for the currently selected graph node.
  Subordinate to the graph: id, kind, and refs are visible but
  secondary to the human-readable label.

  No ANSI escape sequences. No invented canonical facts. Reads
  from the canonical graph projection.
  """

  alias Kiln.GraphProjection
  alias Temper.AttentionProjection
  alias Temper.CellFrame

  @type width :: pos_integer()

  @doc "Build the inspector tree (a list of {:text, r, c, t, style} primitives)."
  @spec tree(map(), GraphProjection.projection(), map(), map(), width()) :: [term()]
  def tree(state, projection, attn, states_by_id, width) do
    state_for = Enum.find(attn.states, &(&1.id == state.selected_id))
    selected = Enum.find(projection.nodes, &(&1.id == state.selected_id))

    cond do
      is_nil(state_for) or is_nil(selected) ->
        [{:text, 0, 0, "(no selection)", "muted"}]

      true ->
        explanation =
          if state_for.attention == "WAITING_FOR_HUMAN", do: "YOUR CALL", else: state_for.explanation

        lines = [
          {"INSPECTOR", "header"},
          {"", "normal"},
          {selected.kind, "muted"},
          {state_for.label, "accent"},
          {explanation, attention_style(state_for.attention)},
          {"", "normal"},
          {"id", "muted"},
          {selected.id, "normal"},
          {"", "normal"},
          {"canonical digest", "muted"},
          {selected.canonical_digest, "normal"},
          {"", "normal"},
          {"attention", "muted"},
          {state_for.attention, attention_style(state_for.attention)}
        ]

        lines
        |> Enum.with_index()
        |> Enum.flat_map(fn {{text, style}, idx} ->
          [{:text, idx, 0, fit(text, width - 1), style}]
        end)
    end
  end

  @doc "Render the inspector as a standalone CellFrame."
  @spec render(map(), GraphProjection.projection(), map(), map(), pos_integer(), pos_integer()) :: CellFrame.t()
  def render(state, projection, attn, states_by_id, rows, cols) do
    tree = tree(state, projection, attn, states_by_id, cols)
    CellFrame.render(tree, rows, cols)
  end

  defp fit(s, n) when is_binary(s) and byte_size(s) <= n, do: s
  defp fit(s, n) when is_binary(s), do: String.slice(s, 0, max(n, 0))
  defp fit(_, _), do: ""

  defp attention_style("FAILED"), do: "error"
  defp attention_style("BLOCKED"), do: "warn"
  defp attention_style("WAITING_FOR_HUMAN"), do: "accent"
  defp attention_style("COMPLETE"), do: "success"
  defp attention_style(_), do: "normal"
end
