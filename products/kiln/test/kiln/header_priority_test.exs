defmodule Kiln.HeaderPriorityTest do
  @moduledoc """
  M4 — header/footer priority tests.

  P0 items must never be truncated while lower-priority items
  remain. At narrow widths, lower-priority items disappear
  cleanly rather than getting squished.
  """

  use ExUnit.Case, async: true

  alias Kiln.HeaderPriority

  test "P0 items are kept at narrow widths" do
    state = %{
      freshness: :stale,
      current_lifecycle_needs_you: true,
      needs_you: 2,
      failed: 1,
      mode: "MAP",
      counts: %{working: 5, complete: 3, blocked: 1},
      secondary: ["foo", "bar", "baz", "qux"]
    }

    out = HeaderPriority.render_header(state, 30)
    assert out =~ "◌ STALE"
    assert out =~ "★ YOUR CALL"
    # At 30 cols the top 2 P0 items fit; the rest are dropped or
    # joined via the separator. We assert the high-priority glyphs
    # come BEFORE the lower-priority items.
    stale_idx = :binary.match(out, "◌ STALE") |> elem(0)
    call_idx = :binary.match(out, "★ YOUR CALL") |> elem(0)
    assert stale_idx < call_idx
    refute byte_size(out) > 30
  end

  test "P0 failure is kept at narrow widths" do
    state = %{
      freshness: :live,
      current_lifecycle_needs_you: false,
      needs_you: 0,
      failed: 3,
      mode: "MAP",
      counts: %{working: 99, complete: 99, blocked: 99},
      secondary: ["foo", "bar", "baz", "qux"]
    }

    out = HeaderPriority.render_header(state, 20)
    assert out =~ "✗ 3 failed"
    # counts and secondary should be dropped.
    refute out =~ "99 working"
    refute out =~ "foo"
    refute byte_size(out) > 20
  end

  test "truncation drops secondary first" do
    state = %{
      freshness: :live,
      your_call: false,
      needs_you: 0,
      failed: 0,
      mode: nil,
      counts: %{},
      secondary: ["long-extra-info", "more-extra-info", "yet-more"]
    }

    out = HeaderPriority.render_header(state, 20)
    assert out != ""
    # Secondary dropped at narrow widths.
    refute out =~ "long-extra-info"
    refute out =~ "more-extra-info"
  end

  test "freshness glyph distinguishes GOVERNED+STALE" do
    out = HeaderPriority.render_header(%{freshness: :stale}, 80)
    assert out =~ "◌ STALE"
  end

  test "footer carries failure before shortcuts" do
    state = %{
      failed: 2,
      shortcuts: ["↑↓ select"]
    }

    out = HeaderPriority.render_footer(state, 40)
    fail_idx = :binary.match(out, "failed") |> elem(0)
    sc_idx = :binary.match(out, "select") |> elem(0)
    assert fail_idx < sc_idx
  end
end
