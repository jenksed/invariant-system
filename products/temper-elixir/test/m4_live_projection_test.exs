defmodule Temper.M4LiveProjectionTest do
  @moduledoc """
  M4-Q1 — Gate 1 hydration race test.

  The adversarial case: A→B during hydration. A must NOT become
  falsely LIVE without a guaranteed convergence path.
  """

  use ExUnit.Case, async: true

  alias Kiln.Domain.SubjectIdentity
  alias Temper.M4LiveProjection

  defp projection_a do
    %{nodes: [%{id: "wko_a", kind: "WorkerOutput"}], edges: []}
  end

  defp projection_b do
    %{nodes: [%{id: "wko_b", kind: "WorkerOutput"}], edges: []}
  end

  test "A→B during hydration: A is NOT installed as LIVE" do
    # Begin hydration for A
    s0 = M4LiveProjection.initial()
    s1 = M4LiveProjection.begin_hydration(s0, 1, projection_a())

    # During hydration, canonical advances A→B (revision 2)
    s2 = M4LiveProjection.invalidate(s1)

    # A's hydration completes
    s3 = M4LiveProjection.complete_hydration(s2)

    # A must not be LIVE. Must be in :hydrating (churn) or :degraded.
    refute M4LiveProjection.live?(s3, 2),
           "A must not be LIVE after invalidation; got #{inspect(s3.freshness)}"

    assert s3.freshness in [:hydrating, :degraded]
  end

  test "A→B during hydration: re-hydration installs B" do
    s0 = M4LiveProjection.initial()
    s1 = M4LiveProjection.begin_hydration(s0, 1, projection_a())
    s2 = M4LiveProjection.invalidate(s1)
    s3 = M4LiveProjection.complete_hydration(s2)

    # Re-hydrate with B at revision 2
    s4 = M4LiveProjection.begin_hydration(s3, 2, projection_b())
    s5 = M4LiveProjection.complete_hydration(s4)

    assert M4LiveProjection.live?(s5, 2)
    assert s5.freshness == :live
    assert s5.projection == projection_b()
  end

  test "Bounded churn: after N invalidations, freshness=DEGRADED" do
    s0 = M4LiveProjection.initial()

    final =
      Enum.reduce(1..10, s0, fn i, state ->
        s = M4LiveProjection.begin_hydration(state, i, projection_a())
        s = M4LiveProjection.invalidate(s)
        M4LiveProjection.complete_hydration(s)
      end)

    # Churn limit is 5 in the module. After 10 invalidations,
    # freshness must be DEGRADED.
    assert final.freshness == :degraded,
           "expected DEGRADED after #{final.churn_count} churns, got #{inspect(final.freshness)}"
  end

  test "Reconnect: discard current, mark RECONNECTING" do
    s0 = M4LiveProjection.initial()
    s1 = M4LiveProjection.begin_hydration(s0, 1, projection_a())
    s2 = M4LiveProjection.complete_hydration(s1)

    assert s2.freshness == :live

    s3 = M4LiveProjection.reconnect(s2)
    assert s3.freshness == :reconnecting
    assert s3.projection == nil
  end

  test "Focus preserved when subject survives" do
    s0 = M4LiveProjection.initial()
    s1 = M4LiveProjection.begin_hydration(s0, 1, projection_a())
    s2 = M4LiveProjection.complete_hydration(s1)

    focus = %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "wko_a"}
    s3 = M4LiveProjection.set_focus(s2, focus)

    # Re-hydrate with same projection. Focus is preserved.
    s4 = M4LiveProjection.begin_hydration(s3, 2, projection_a())
    s5 = M4LiveProjection.complete_hydration(s4)
    s6 = M4LiveProjection.reconcile_focus(s5, projection_a())

    assert s6.focus == focus
  end

  test "Focus fallback when subject disappears" do
    s0 = M4LiveProjection.initial()
    s1 = M4LiveProjection.begin_hydration(s0, 1, projection_a())
    s2 = M4LiveProjection.complete_hydration(s1)

    focus = %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "wko_a"}
    s3 = M4LiveProjection.set_focus(s2, focus)

    # Re-hydrate with projection B (no wko_a).
    s4 = M4LiveProjection.begin_hydration(s3, 2, projection_b())
    s5 = M4LiveProjection.complete_hydration(s4)
    s6 = M4LiveProjection.reconcile_focus(s5, projection_b())

    # wko_a is gone. Fallback to first available subject in B.
    assert s6.focus == %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "wko_b"}
  end

  test "Hydration race invariant: A.installed_with_B_revision is :invalid" do
    s0 = M4LiveProjection.initial()
    s1 = M4LiveProjection.begin_hydration(s0, 1, projection_a())
    s2 = M4LiveProjection.invalidate(s1)
    s3 = M4LiveProjection.complete_hydration(s2)

    # Now s3 is in :hydrating (churn) or :degraded. The hydration
    # race check: if someone naively installs A at canonical B
    # revision 2, the check is :invalid.
    state_a_at_begin = s1

    result = M4LiveProjection.hydration_race_check(state_a_at_begin, s3, 2)
    assert result == :invalid
  end
end
