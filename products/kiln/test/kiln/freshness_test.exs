defmodule Kiln.FreshnessTest do
  @moduledoc """
  M4 — Authority and Freshness are independent dimensions.

  Required: GOVERNED + STALE is a valid state. The text/glyph
  representation must remain unambiguous in monochrome.
  """

  use ExUnit.Case, async: true

  alias Kiln.Freshness

  test "empty projection: authority unknown" do
    assert Freshness.authority(%{nodes: []}) == :unknown
  end

  test "non-empty projection: authority governed" do
    assert Freshness.authority(%{nodes: [%{id: "x"}]}) == :governed
  end

  test "freshness supports all five states" do
    for state <- [:live, :hydrating, :reconnecting, :stale, :degraded] do
      assert Freshness.freshness(state) == state
    end
  end

  test "valid combined state: GOVERNED + STALE" do
    projection = %{nodes: [%{id: "x"}]}
    s = Freshness.status(projection, :stale)
    assert Freshness.governed?(s)
    assert Freshness.stale?(s)
    assert s.authority == :governed
    assert s.freshness == :stale
  end

  test "valid combined state: GOVERNED + LIVE" do
    projection = %{nodes: [%{id: "x"}]}
    s = Freshness.status(projection, :live)
    assert Freshness.governed?(s)
    refute Freshness.stale?(s)
  end

  test "monochrome distinguishability: GOVERNED+STALE is a third class" do
    governed_live = Freshness.status(%{nodes: [%{id: "x"}]}, :live)
    governed_stale = Freshness.status(%{nodes: [%{id: "x"}]}, :stale)
    unknown_stale = Freshness.status(%{nodes: []}, :stale)

    # These three states must be distinct, not collapsed.
    assert governed_live != governed_stale
    assert governed_live != unknown_stale
    assert governed_stale != unknown_stale
  end
end
