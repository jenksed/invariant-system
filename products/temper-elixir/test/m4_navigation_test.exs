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
end
