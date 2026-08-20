defmodule Temper.CellFrame do
  @moduledoc """
  M4 — pure-Elixir cell buffer + diff reference implementation.

  CellFrame is the renderer-independent rasterizer. It paints a
  declarative tree onto a fixed-size grid of cells and computes
  minimal ANSI diffs between successive frames.

  CellFrame MUST know nothing about:
    * WorkerOutput / PatchProposal / VerificationResult / Review /
      HumanDecision / PatchEvidence
    * Authority, providers, graph dependency semantics
    * Specific Temper screens or routes

  Inputs are generic rendering primitives:
    * `:rows`, `:cols` — terminal dimensions
    * a tree of nested `{:box, ...}` / `{:text, ...}` cells

  Outputs are generic:
    * a `%Temper.CellFrame{}` struct (deterministic, snapshot-friendly)
    * `byte_diff/2` that returns ANSI bytes

  Lives in the kiln product under the Temper namespace as a
  temporary location during the M4 evaluation slice. A future
  commit may relocate it to a products/temper-elixir project.
  """

  @style_normal "\x1b[0m"
  @style_bold "\x1b[1m"
  @style_dim "\x1b[2m"
  @style_header "\x1b[1;36m"
  @style_footer "\x1b[2m"
  @style_success "\x1b[32m"
  @style_warn "\x1b[33m"
  @style_error "\x1b[31m"
  @style_muted "\x1b[2m"
  @style_accent "\x1b[1m"
  @style_border "\x1b[2m"

  @styles %{
    "normal" => @style_normal,
    "bold" => @style_bold,
    "dim" => @style_dim,
    "header" => @style_header,
    "footer" => @style_footer,
    "success" => @style_success,
    "warn" => @style_warn,
    "error" => @style_error,
    "muted" => @style_muted,
    "accent" => @style_accent,
    "border" => @style_border
  }

  @type style_name :: String.t()
  @type cell :: %{ch: String.t(), style: style_name()}

  @type t :: %__MODULE__{
          rows: pos_integer(),
          cols: pos_integer(),
          cells: [[cell()]]
        }

  defstruct rows: 0, cols: 0, cells: []

  @doc "Create an empty frame filled with spaces at the normal style."
  @spec new(pos_integer(), pos_integer()) :: t()
  def new(rows, cols) when is_integer(rows) and rows > 0 and is_integer(cols) and cols > 0 do
    blank = %{ch: " ", style: "normal"}
    cells = for _r <- 1..rows, do: List.duplicate(blank, cols)
    %__MODULE__{rows: rows, cols: cols, cells: cells}
  end

  @doc """
  Render a declarative tree onto a frame of the given dimensions.

  Tree primitives:
    * `{:text, row, col, text, style}` — write a string at (row, col).
    * `{:line, row, col, text, style}` — same as :text.
    * `{:box, row, col, height, width, style, [children]}` — bordered
      box with nested children. Children are positioned inside the
      box at coordinates relative to the box origin (after the border).
  """
  @spec render([term()], pos_integer(), pos_integer()) :: t()
  def render(tree, rows, cols) do
    frame = new(rows, cols)
    Enum.reduce(tree, frame, fn node, acc -> paint(acc, node) end)
  end

  @doc """
  Compute the ANSI byte stream to transition from `previous` to
  `current`. If dimensions differ, emits an erase-below before the
  new frame so shorter frames do not leave stale cells.
  """
  @spec byte_diff(t() | nil, t()) :: iodata()
  def byte_diff(nil, current) do
    [move_home(), hide_cursor(), paint_ansi(current), show_cursor()]
  end

  def byte_diff(previous, current) do
    cond do
      previous.rows != current.rows or previous.cols != current.cols ->
        [move_home(), hide_cursor(), erase_below(), paint_ansi(current), show_cursor()]

      true ->
        [move_home(), hide_cursor(), paint_ansi(current), show_cursor()]
    end
  end

  @doc """
  Extract the visible text content of a frame (no ANSI bytes, one
  row per line, trailing spaces trimmed).
  """
  @spec to_text(t()) :: String.t()
  def to_text(%__MODULE__{} = frame) do
    frame.cells
    |> Enum.map(fn row ->
      row
      |> Enum.map(& &1.ch)
      |> List.to_string()
      |> String.replace(~r/\s+$/, "")
    end)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  # --- paint ---

  defp paint(frame, {:text, row, col, text, style}) do
    write_text(frame, row, col, text, style)
  end

  defp paint(frame, {:line, row, col, text, style}) do
    write_text(frame, row, col, text, style)
  end

  defp paint(frame, {:box, row, col, height, width, style, children})
       when is_integer(height) and is_integer(width) do
    frame
    |> draw_box_border(row, col, height, width, style)
    |> paint_children(children, row + 1, col + 2)
  end

  defp paint(frame, _other), do: frame

  defp paint_children(frame, [], _base_row, _base_col), do: frame

  defp paint_children(frame, [child | rest], base_row, base_col) do
    frame
    |> paint_child(child, base_row, base_col)
    |> paint_children(rest, base_row, base_col)
  end

  defp paint_child(frame, {:text, _r, _c, _t, _s} = node, _br, _bc) do
    paint(frame, node)
  end

  defp paint_child(frame, {:line, row, col, text, style}, br, bc) do
    write_text(frame, br + row, bc + col, text, style)
  end

  defp paint_child(frame, {:box, row, col, h, w, s, ch}, br, bc) do
    paint(frame, {:box, br + row, bc + col, h, w, s, ch})
  end

  defp paint_child(frame, _other, _br, _bc), do: frame

  defp draw_box_border(frame, row, col, height, width, style) do
    inner_w = max(width - 2, 0)
    top = "┌" <> String.duplicate("─", inner_w) <> "┐"
    bottom = "└" <> String.duplicate("─", inner_w) <> "┘"

    frame =
      frame
      |> write_text(row, col, top, style)
      |> write_text(row + height - 1, col, bottom, style)

    Enum.reduce(1..(height - 2), frame, fn r, acc ->
      acc
      |> write_text(row + r, col, "│", style)
      |> write_text(row + r, col + width - 1, "│", style)
    end)
  end

  defp write_text(frame, row, col, text, style) do
    cond do
      row < 0 or row >= frame.rows -> frame
      col >= frame.cols -> frame
      col < 0 ->
        # Shift text into view.
        clipped = String.slice(text, -col..-1)
        do_write_text(frame, row, 0, clipped, style)

      true ->
        do_write_text(frame, row, col, text, style)
    end
  end

  defp do_write_text(frame, row, col, text, style) do
    chars = String.graphemes(text)
    available = frame.cols - col
    fitted = Enum.take(chars, max(available, 0))
    cells = List.replace_at(frame.cells, row, write_into_row(Enum.at(frame.cells, row), col, fitted, style))
    %{frame | cells: cells}
  end

  defp write_into_row(row, col, chars, style) do
    {prefix, rest} = Enum.split(row, min(col, length(row)))
    {fitted, suffix_src} = Enum.split(rest, length(chars))
    new_fitted = Enum.map(chars, fn ch -> %{ch: ch, style: style} end)
    prefix ++ new_fitted ++ suffix_src
  end

  # --- ANSI ---

  defp paint_ansi(%__MODULE__{} = frame) do
    Enum.map(frame.cells, fn row ->
      row
      |> Enum.map(fn cell -> [Map.fetch!(@styles, cell.style) || @style_normal, cell.ch] end)
    end)
    |> Enum.map(&IO.iodata_to_binary/1)
    |> Enum.intersperse("\r\n")
  end

  defp move_home, do: "\x1b[H"
  defp hide_cursor, do: "\x1b[?25l"
  defp show_cursor, do: "\x1b[?25h"
  defp erase_below, do: "\x1b[J"
end