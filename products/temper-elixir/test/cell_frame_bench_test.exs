defmodule Temper.CellFrameBenchTest do
  @moduledoc """
  M4 — pure-Elixir CellFrame performance characterisation.

  NOT a benchmark suite optimised for microseconds. This is a
  smoke test that produces measurable numbers on representative
  frames so we can decide whether native Zig earns itself.

  Captured numbers (rough order of magnitude):
    * ordinary 24x80 screen
    * M3 lifecycle graph (6 nodes, 8 edges)
    * 25-node graph
    * 100-node graph
    * 1-node change repaint
    * full redraw of 100 nodes
    * resize 80x24 -> 120x40
    * multiline-heavy 40x120
  """

  use ExUnit.Case, async: false

  alias Temper.CellFrame

  defp time_it(label, fun) do
    # warmup
    fun.()
    fun.()
    {time_us, _} = :timer.tc(fun)
    IO.puts("[bench] #{label}: #{time_us} us")
    time_us
  end

  defp ordinary_screen(rows, cols) do
    [
      {:line, 0, 0, "Temper Workbench — ordinary screen", "header"},
      {:line, 2, 0, "Session: ses_demo    Run: running", "muted"},
      {:line, 4, 0, "Recent activity:", "normal"},
      {:line, 5, 2, "● Worker: bounded source change applied", "success"},
      {:line, 6, 2, "● Reviewer: APPROVE", "success"},
      {:line, 7, 2, "● Human: ACCEPT", "accent"},
      {:line, rows - 1, 0, "q quit | ENTER submit | ? help", "footer"}
    ]
  end

  defp m3_graph(rows, cols) do
    nodes = [
      "Engineering Objective",
      "Worker Output",
      "Patch Proposal",
      "Verification",
      "Review",
      "Human Decision",
      "Patch Evidence"
    ]

    node_boxes =
      nodes
      |> Enum.with_index()
      |> Enum.map(fn {label, i} ->
        {:box, 2 + i * 4, 2, 3, 24, "normal", [{:line, 0, 0, label, "normal"}]}
      end)

    edges =
      Enum.drop(node_boxes, -1)
      |> Enum.with_index()
      |> Enum.map(fn {_, i} -> {:line, 5 + i * 4, 14, "↓", "dim"} end)

    [
      {:line, 0, 0, "M3 Lifecycle Graph", "header"},
      {:line, rows - 1, 0, "↑↓ navigate | ENTER inspect | q quit", "footer"}
    ] ++ node_boxes ++ edges
  end

  defp n_node_graph(n, rows, cols) do
    node_boxes =
      Enum.map(1..n, fn i ->
        row = 2 + rem(i - 1, 22) * 1
        col = 2 + div(i - 1, 22) * 30
        {:box, row, col, 1, 24, "normal", [{:line, 0, 0, "Node #{i}", "normal"}]}
      end)

    edges =
      Enum.drop(node_boxes, -1)
      |> Enum.take(n - 1)
      |> Enum.with_index()
      |> Enum.map(fn {_, i} -> {:line, 2 + rem(i, 22), 14 + div(i, 22) * 30, "→", "dim"} end)

    [
      {:line, 0, 0, "N-Node Graph (#{n})", "header"},
      {:line, rows - 1, 0, "navigate | q quit", "footer"}
    ] ++ node_boxes ++ edges
  end

  defp multiline_heavy(rows, cols) do
    Enum.map(0..(rows - 1), fn r ->
      content = "Line #{r} - " <> String.duplicate("x", rem(r * 7, cols - 15))
      {:line, r, 0, content, if(rem(r, 4) == 0, do: "muted", else: "normal")}
    end)
  end

  test "ordinary 24x80 screen" do
    t = time_it("ordinary 24x80 render", fn ->
      tree = ordinary_screen(24, 80)
      frame = CellFrame.render(tree, 24, 80)
      _ = CellFrame.byte_diff(nil, frame)
    end)
    assert t < 50_000, "expected ordinary screen render < 50ms"
  end

  test "M3 lifecycle graph 30x80" do
    t = time_it("M3 graph 30x80 render", fn ->
      tree = m3_graph(30, 80)
      frame = CellFrame.render(tree, 30, 80)
      _ = CellFrame.byte_diff(nil, frame)
    end)
    assert t < 50_000, "expected M3 graph render < 50ms"
  end

  test "25-node graph 24x80" do
    t = time_it("25-node graph 24x80 render", fn ->
      tree = n_node_graph(25, 24, 80)
      frame = CellFrame.render(tree, 24, 80)
      _ = CellFrame.byte_diff(nil, frame)
    end)
    assert t < 50_000, "expected 25-node graph render < 50ms"
  end

  test "100-node graph 24x120" do
    t = time_it("100-node graph 24x120 render", fn ->
      tree = n_node_graph(100, 24, 120)
      frame = CellFrame.render(tree, 24, 120)
      _ = CellFrame.byte_diff(nil, frame)
    end)
    assert t < 100_000, "expected 100-node graph render < 100ms"
  end

  test "1-node change repaint 30x80" do
    tree = m3_graph(30, 80)
    prev = CellFrame.render(tree, 30, 80)
    # Modify one node label in the tree.
    modified = List.replace_at(tree, 1, {:line, 2, 0, "M3 Lifecycle Graph (modified)", "header"})
    next = CellFrame.render(modified, 30, 80)

    t = time_it("1-node change diff 30x80", fn ->
      _ = CellFrame.byte_diff(prev, next)
    end)
    assert t < 50_000
  end

  test "resize 80x24 -> 120x40" do
    prev = CellFrame.render(m3_graph(24, 80), 24, 80)
    next = CellFrame.render(m3_graph(40, 120), 40, 120)

    t = time_it("resize 80x24 -> 120x40", fn ->
      _ = CellFrame.byte_diff(prev, next)
    end)
    assert t < 50_000
  end

  test "multiline-heavy 40x120" do
    t = time_it("multiline-heavy 40x120 render", fn ->
      tree = multiline_heavy(40, 120)
      frame = CellFrame.render(tree, 40, 120)
      _ = CellFrame.byte_diff(nil, frame)
    end)
    assert t < 100_000
  end
end
