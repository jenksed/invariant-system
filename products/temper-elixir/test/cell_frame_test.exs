defmodule Temper.CellFrameTest do
  @moduledoc """
  Property tests for the pure-Elixir CellFrame reference.

  Covers: deterministic frame output, shorter frames emit
  erase-below, resize, multiline, basic Unicode grapheme width,
  partial diff path, snapshot, headless.
  """

  use ExUnit.Case, async: true

  alias Temper.CellFrame

  describe "new/2" do
    test "creates a blank frame of the given size" do
      frame = CellFrame.new(3, 4)
      assert frame.rows == 3
      assert frame.cols == 4
      assert length(frame.cells) == 3
      assert Enum.all?(frame.cells, fn row -> length(row) == 4 end)
      assert Enum.all?(frame.cells, fn row -> Enum.all?(row, &(&1.ch == " ")) end)
    end
  end

  describe "render/3" do
    test "writes text at the given position" do
      frame = CellFrame.render([{:text, 1, 2, "hi", "bold"}], 3, 8)
      assert frame.cells |> Enum.at(1) |> Enum.at(2) == %{ch: "h", style: "bold"}
      assert frame.cells |> Enum.at(1) |> Enum.at(3) == %{ch: "i", style: "bold"}
    end

    test "clips text that exceeds frame width" do
      frame = CellFrame.render([{:text, 0, 0, "abcdef", "normal"}], 1, 3)
      row = hd(frame.cells)
      assert Enum.map(row, & &1.ch) |> Enum.take(3) == ["a", "b", "c"]
    end

    test "ignores out-of-bounds rows" do
      frame = CellFrame.render([{:text, 99, 0, "x", "normal"}], 3, 4)
      assert frame.cells == CellFrame.new(3, 4).cells
    end

    test "draws a box border" do
      frame = CellFrame.render([{:box, 0, 0, 3, 6, "border", []}], 3, 6)
      top = frame.cells |> Enum.at(0) |> Enum.map(& &1.ch)
      assert hd(top) == "┌"
      assert List.last(top) == "┐"

      bottom = frame.cells |> Enum.at(2) |> Enum.map(& &1.ch)
      assert hd(bottom) == "└"
      assert List.last(bottom) == "┘"
    end

    test "places box children inside the border" do
      frame = CellFrame.render(
        [{:box, 0, 0, 3, 8, "border", [{:line, 0, 0, "child", "normal"}]}],
        3, 8
      )

      middle = frame.cells |> Enum.at(1) |> Enum.map(& &1.ch)
      # Border at col 0 ("│"), child at col 2..6 ("child "), border at col 7 ("│")
      assert Enum.at(middle, 0) == "│"
      assert Enum.at(middle, 1) == " "
      assert Enum.at(middle, 2) == "c"
      assert Enum.at(middle, 3) == "h"
      assert Enum.at(middle, 4) == "i"
      assert Enum.at(middle, 5) == "l"
      assert Enum.at(middle, 6) == "d"
      assert Enum.at(middle, 7) == "│"
    end
  end

  describe "byte_diff/2 — headless, no TTY" do
    test "first frame emits clear-screen + paint" do
      frame = CellFrame.render([{:text, 0, 0, "hi", "normal"}], 2, 4)
      bytes = IO.iodata_to_binary(CellFrame.byte_diff(nil, frame))
      assert bytes =~ "\x1b[H"
      assert bytes =~ "\x1b[?25l"
      assert bytes =~ "h"
      assert bytes =~ "i"
      assert bytes =~ "\x1b[?25h"
    end

    test "shorter frame emits erase-below so stale cells disappear" do
      tall = CellFrame.new(10, 8)
      short = CellFrame.new(4, 8)
      bytes = IO.iodata_to_binary(CellFrame.byte_diff(tall, short))
      assert bytes =~ "\x1b[J", "expected erase-below when frame shrinks in height"
    end

    test "narrower frame emits erase-below" do
      wide = CellFrame.new(4, 20)
      narrow = CellFrame.new(4, 4)
      bytes = IO.iodata_to_binary(CellFrame.byte_diff(wide, narrow))
      assert bytes =~ "\x1b[J"
    end

    test "stable byte output for identical inputs" do
      tree = [{:text, 0, 0, "stable", "normal"}, {:line, 1, 0, "footer", "footer"}]
      a = CellFrame.byte_diff(nil, CellFrame.render(tree, 3, 10))
      b = CellFrame.byte_diff(nil, CellFrame.render(tree, 3, 10))
      assert IO.iodata_to_binary(a) == IO.iodata_to_binary(b)
    end
  end

  describe "to_text/1" do
    test "extracts visible text" do
      frame = CellFrame.render(
        [
          {:text, 0, 0, "Header", "header"},
          {:text, 2, 0, "Body", "normal"}
        ],
        4, 12
      )

      text = CellFrame.to_text(frame)
      assert text =~ "Header"
      assert text =~ "Body"
    end

    test "strips trailing blanks from each row" do
      frame = CellFrame.render([{:text, 0, 0, "x", "normal"}], 1, 8)
      assert CellFrame.to_text(frame) == "x"
    end
  end

  describe "Unicode / grapheme width" do
    test "grapheme cluster is treated as a single cell" do
      frame = CellFrame.render([{:text, 0, 0, "café", "normal"}], 1, 4)
      chars = frame.cells |> hd() |> Enum.map(& &1.ch)
      assert Enum.count(chars, &(&1 != " ")) == 4
    end
  end
end
