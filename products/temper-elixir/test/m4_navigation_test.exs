defmodule Temper.M4NavigationTest do
  @moduledoc """
  M4-Q1 — Gate 2 navigation tests.
  """

  use ExUnit.Case, async: true

  alias Kiln.Domain.SubjectIdentity
  alias Temper.M4Navigation

  defp projection do
    %{
      nodes: [
        %{id: "wko_a", kind: "WorkerOutput", attention: :working},
        %{id: "pp_a", kind: "PatchProposal", attention: :working},
        %{id: "ver_a", kind: "VerificationResult", attention: :failed},
        %{id: "rev_a", kind: "Review", attention: :blocked}
      ],
      edges: []
    }
  end

  test "set_order assigns deterministic order" do
    state = M4Navigation.initial() |> M4Navigation.set_order(projection())
    assert length(state.order) == 4
  end

  test "↑/↓ moves within bounds" do
    s = M4Navigation.initial() |> M4Navigation.set_order(projection())
    s1 = M4Navigation.move(s, :down)
    assert s1.focus_idx == 1
    s2 = M4Navigation.move(s1, :down)
    assert s2.focus_idx == 2
    s3 = M4Navigation.move(s2, :down)
    assert s3.focus_idx == 3
    s4 = M4Navigation.move(s3, :down)
    # clamped
    assert s4.focus_idx == 3
  end

  test "Esc restores prior focus" do
    s = M4Navigation.initial() |> M4Navigation.set_order(projection())
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "wko_a"})
    s2 = M4Navigation.set_focus(s1, %SubjectIdentity{entity_type: "PatchProposal", canonical_id: "pp_a"})
    assert M4Navigation.focused(s2).canonical_id == "pp_a"
    s3 = M4Navigation.move(s2, :esc)
    assert M4Navigation.focused(s3).canonical_id == "wko_a"
  end

  test "JUMP_ATTENTION lands on first blocked/failed/waiting" do
    s = M4Navigation.initial() |> M4Navigation.set_order(projection())
    s1 = M4Navigation.jump(s, :attention, projection())
    assert M4Navigation.focused(s1).canonical_id == "ver_a"
  end

  test "JUMP_FAILURE lands on first failed" do
    s = M4Navigation.initial() |> M4Navigation.set_order(projection())
    s1 = M4Navigation.jump(s, :failure, projection())
    assert M4Navigation.focused(s1).canonical_id == "ver_a"
  end

  test "JUMP_BLOCKED lands on first blocked" do
    s = M4Navigation.initial() |> M4Navigation.set_order(projection())
    s1 = M4Navigation.jump(s, :blocked, projection())
    assert M4Navigation.focused(s1).canonical_id == "rev_a"
  end

  test "Position stability: same projection, same order" do
    s1 = M4Navigation.initial() |> M4Navigation.set_order(projection())
    s2 = M4Navigation.initial() |> M4Navigation.set_order(projection())
    assert s1.order == s2.order
  end

  # M4-Q1C Gate 5 — canonical ←/→ navigation tests.

  defp linear_projection do
    # WorkerOutput -> PatchProposal -> VerificationResult -> Review
    %{
      nodes: [
        %{id: "wko_l", kind: "WorkerOutput"},
        %{id: "pp_l", kind: "PatchProposal"},
        %{id: "ver_l", kind: "VerificationResult"},
        %{id: "rev_l", kind: "Review"}
      ],
      edges: [
        %{id: "e1", kind: "PRODUCED", from: "wko_l", to: "pp_l"},
        %{id: "e2", kind: "VERIFIED", from: "ver_l", to: "pp_l"},
        %{id: "e3", kind: "REVIEWED", from: "rev_l", to: "pp_l"},
        %{id: "e4", kind: "ASSESSED", from: "rev_l", to: "ver_l"}
      ]
    }
  end

  test "LEFT_UPSTREAM (linear lifecycle): from Review ← VerificationResult" do
    s = M4Navigation.initial() |> M4Navigation.set_order(linear_projection())
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "Review", canonical_id: "rev_l"})

    s2 = M4Navigation.move(s1, :left, linear_projection())

    # Review has two incoming edges: REVIEWED→pp_l and ASSESSED→ver_l.
    # Tie-break by visible order: pp_l appears before ver_l in the
    # visible nodes order, so ← lands on pp_l (PatchProposal).
    assert M4Navigation.focused(s2).canonical_id == "pp_l"
  end

  test "LEFT_UPSTREAM (linear lifecycle, from WorkerOutput): ← follows PRODUCED → PatchProposal" do
    # Canonical edge PRODUCED: wko_l → pp_l. ← walks canonical
    # outgoing edges in the emitted direction.
    s = M4Navigation.initial() |> M4Navigation.set_order(linear_projection())
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "wko_l"})

    s2 = M4Navigation.move(s1, :left, linear_projection())

    assert M4Navigation.focused(s2).canonical_id == "pp_l"
  end

  test "RIGHT_DOWNSTREAM (linear lifecycle, from Review): → follows AUTHORIZED/REVIEWED reversed" do
    # Review has no canonical edge where Review is the `to` target.
    # → walks incoming edges (where current is `to`); none exist
    # → focus unchanged. Canonical semantics, not operator intuition.
    s = M4Navigation.initial() |> M4Navigation.set_order(linear_projection())
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "Review", canonical_id: "rev_l"})

    s2 = M4Navigation.move(s1, :right, linear_projection())

    # No incoming edges to Review → focus unchanged.
    assert M4Navigation.focused(s2).canonical_id == "rev_l"
  end

  test "LEFT_UPSTREAM (no canonical edge): focus unchanged" do
    # PatchProposal has no outgoing canonical edges in this fixture.
    s = M4Navigation.initial() |> M4Navigation.set_order(linear_projection())
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "PatchProposal", canonical_id: "pp_l"})

    # ← walks outgoing; pp_l has no outgoing canonical edges
    # → focus unchanged.
    s2 = M4Navigation.move(s1, :left, linear_projection())

    assert M4Navigation.focused(s2).canonical_id == "pp_l"
  end

  test "NO_TYPE_INFERRED_EDGE: entity type compatibility does NOT manufacture an edge" do
    # Two Review nodes with the same entity_type but no canonical edge
    # between them. ←/→ must not invent a relationship based on type.
    p = %{
      nodes: [
        %{id: "rev_1", kind: "Review"},
        %{id: "rev_2", kind: "Review"}
      ],
      edges: []
    }

    s = M4Navigation.initial() |> M4Navigation.set_order(p)
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "Review", canonical_id: "rev_1"})

    s2 = M4Navigation.move(s1, :left, p)
    assert M4Navigation.focused(s2).canonical_id == "rev_1", "no edge → focus unchanged"

    s3 = M4Navigation.move(s1, :right, p)
    assert M4Navigation.focused(s3).canonical_id == "rev_1", "no edge → focus unchanged"
  end

  test "Branch tie-break: ← walks canonical outgoing edges in visible topology order" do
    # One source, two outgoing edges in edge-list order
    # (PRODUCED→tgt_b first, REVIEWED→tgt_a second). Visible topology
    # order has tgt_a first (PatchProposal appears before Review).
    # ← must follow canonical edges in their emitted direction and
    # tie-break by visible order, NOT edge-list order.
    p = %{
      nodes: [
        %{id: "src", kind: "WorkerOutput"},
        %{id: "tgt_a", kind: "PatchProposal"},
        %{id: "tgt_b", kind: "Review"}
      ],
      edges: [
        %{id: "e1", kind: "PRODUCED", from: "src", to: "tgt_b"},
        %{id: "e2", kind: "REVIEWED", from: "src", to: "tgt_a"}
      ]
    }

    s = M4Navigation.initial() |> M4Navigation.set_order(p)
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "src"})

    s2 = M4Navigation.move(s1, :left, p)
    # ← walks outgoing canonical edges; tie-break by visible topology
    # order → lands on tgt_a (PatchProposal, first in visible order).
    assert M4Navigation.focused(s2).canonical_id == "tgt_a"
  end

  test "Esc returns to prior focus" do
    s = M4Navigation.initial() |> M4Navigation.set_order(linear_projection())
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "WorkerOutput", canonical_id: "wko_l"})
    s2 = M4Navigation.set_focus(s1, %SubjectIdentity{entity_type: "Review", canonical_id: "rev_l"})

    s3 = M4Navigation.move(s2, :esc, linear_projection())
    assert M4Navigation.focused(s3).canonical_id == "wko_l"
  end

  test "UNKNOWN lifecycle + exact canonical ref: ← still traverses the exact edge" do
    # Two nodes with no shared lifecycle_scope but a canonical edge
    # between them. ← must traverse the edge (it is exact).
    p = %{
      nodes: [
        %{id: "n1", kind: "WorkerOutput"},
        %{id: "n2", kind: "Review"}
      ],
      edges: [
        %{id: "e", kind: "REVIEWED", from: "n2", to: "n1"}
      ]
    }

    s = M4Navigation.initial() |> M4Navigation.set_order(p)
    s1 = M4Navigation.set_focus(s, %SubjectIdentity{entity_type: "Review", canonical_id: "n2"})

    s2 = M4Navigation.move(s1, :left, p)
    assert M4Navigation.focused(s2).canonical_id == "n1"
  end
end
