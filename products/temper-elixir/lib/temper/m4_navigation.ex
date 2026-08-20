defmodule Temper.M4Navigation do
  @moduledoc """
  M4 — stable, learnable navigation.

  Movement grammar (per 2B):
    ↑/↓ — previous/next visible entity in stable visible order
    ←   — upstream/source
    →   — downstream/child
    Enter — inspect
    p    — proof
    w    — deterministic WHY
    Esc  — unwind current overlay and restore prior focus where valid

  Jump scopes (per 2C):
    JUMP_ATTENTION, JUMP_FAILURE, JUMP_BLOCKED — all traverse the
    current session projection.

  Architecture: Temper.M4 (M4-Q1, lane M4).
  """

  alias Kiln.Domain.SubjectIdentity

  @type key :: :up | :down | :left | :right | :enter | :p | :w | :esc

  @type visible_order :: [SubjectIdentity.t()]

  @type state :: %{
          required(:order) => visible_order(),
          required(:focus_idx) => non_neg_integer() | nil,
          required(:focus_history) => [SubjectIdentity.t()]
        }

  @doc "Initial state with no order yet (projection not loaded)."
  @spec initial() :: state()
  def initial do
    %{order: [], focus_idx: nil, focus_history: []}
  end

  @doc "Set the visible order from a projection. Position-stable for the same projection."
  @spec set_order(state(), any()) :: state()
  def set_order(state, projection) do
    order =
      projection.nodes
      |> Enum.with_index()
      |> Enum.map(fn {node, idx} -> %SubjectIdentity{entity_type: node.kind, canonical_id: node.id} end)

    current = focused(state)

    new_idx =
      case current do
        nil -> if order == [], do: nil, else: 0
        c -> Enum.find_index(order, &(&1 == c))
      end

    %{state | order: order, focus_idx: new_idx}
  end

  @doc "Move focus according to a key. ←/→ consume the canonical projection."
  @spec move(state(), key(), any()) :: state()
  def move(state, :up, _projection), do: shift(state, -1)
  def move(state, :down, _projection), do: shift(state, 1)
  def move(state, :left, projection), do: move_upstream(state, projection)
  def move(state, :right, projection), do: move_downstream(state, projection)
  def move(state, :enter, _projection), do: state
  def move(state, :p, _projection), do: state
  def move(state, :w, _projection), do: state
  def move(state, :esc, _projection), do: pop_focus(state)

  # Backward-compatible arity-2 form for tests that don't need projection
  # (only :up/:down/:esc use this path; :left/:right require projection).
  @spec move(state(), key()) :: state()
  def move(state, :up), do: shift(state, -1)
  def move(state, :down), do: shift(state, 1)
  def move(state, :esc), do: pop_focus(state)
  def move(state, _other), do: state

  @doc "Jump to the first node matching a scope. Returns updated state or unchanged."
  @spec jump(state(), :attention | :failure | :blocked, any()) :: state()
  def jump(state, scope, projection) do
    target = find_first_in_scope(scope, projection)

    case target do
      nil -> state
      subj -> set_focus(state, subj)
    end
  end

  @doc "Get the current focus."
  @spec focused(state()) :: SubjectIdentity.t() | nil
  def focused(%{order: [], focus_idx: nil}), do: nil
  def focused(%{focus_idx: nil}), do: nil
  def focused(%{order: order, focus_idx: idx}) when is_integer(idx), do: Enum.at(order, idx)

  @doc "Set focus to a subject. Maintains history."
  @spec set_focus(state(), SubjectIdentity.t()) :: state()
  def set_focus(state, %SubjectIdentity{} = subject) do
    new_idx = Enum.find_index(state.order, &(&1 == subject))
    history = [focused(state) | state.focus_history] |> Enum.reject(&is_nil/1) |> Enum.take(8)
    %{state | focus_idx: new_idx, focus_history: history}
  end

  # --- private ---

  defp shift(state, delta) do
    case state do
      %{order: [], focus_idx: nil} -> state
      %{focus_idx: nil} -> %{state | focus_idx: 0}
      %{focus_idx: idx, order: order} ->
        new_idx = (idx + delta) |> max(0) |> min(length(order) - 1)
        %{state | focus_idx: new_idx}
    end
  end

  # Move to the source of an incoming canonical edge, if any.
  # Semantic law: ← consumes only edges from the canonical projection.
  # Entity type/shape may NOT manufacture topology.
  # Multiple destinations → tie-break by stable visible topology order
  # (the projection's node enumeration order, which is deterministic
  # for the same projection).
  defp move_upstream(state, projection) do
    current = focused(state)

    case current do
      nil ->
        state

      %SubjectIdentity{canonical_id: cid} ->
        # Incoming edges: any edge where `to` == current's id.
        # Move to the `from` of that edge (the upstream/source).
        sources =
          projection.edges
          |> Enum.filter(&(&1.to == cid))
          |> Enum.map(& &1.from)
          |> Enum.uniq()

        # Tie-break by visible order.
        target_id = pick_first_in_visible_order(sources, projection)
        maybe_set_focus_by_id(state, target_id)
    end
  end

  # Move to the first target of an outgoing canonical edge, if any.
  defp move_downstream(state, projection) do
    current = focused(state)

    case current do
      nil ->
        state

      %SubjectIdentity{canonical_id: cid} ->
        targets =
          projection.edges
          |> Enum.filter(&(&1.from == cid))
          |> Enum.map(& &1.to)
          |> Enum.uniq()

        target_id = pick_first_in_visible_order(targets, projection)
        maybe_set_focus_by_id(state, target_id)
    end
  end

  # Pick the first canonical id from `candidates` that appears in the
  # projection's visible topology ordering (projection.nodes order).
  # If no candidate is visible, returns nil.
  defp pick_first_in_visible_order(candidates, projection) do
    visible_ids =
      projection.nodes
      |> Enum.map(& &1.id)
      |> MapSet.new()

    Enum.find(candidates, fn id -> MapSet.member?(visible_ids, id) end)
  end

  defp maybe_set_focus_by_id(state, nil), do: state

  defp maybe_set_focus_by_id(state, target_id) do
    target_node = Enum.find(state.order, &(&1.canonical_id == target_id))

    case target_node do
      nil -> state
      %SubjectIdentity{} = subject -> set_focus(state, subject)
    end
  end

  defp pop_focus(%{focus_history: []} = state), do: state
  defp pop_focus(%{focus_history: [prev | _]} = state) do
    new_idx = Enum.find_index(state.order, &(&1 == prev))
    %{state | focus_idx: new_idx, focus_history: []}
  end

  defp find_first_in_scope(:attention, projection) do
    # First node with attention in {BLOCKED, FAILED, WAITING_FOR_HUMAN}.
    Enum.find_value(projection.nodes, fn node ->
      cond do
        node.attention in [:blocked, :failed, :waiting_for_human] ->
          %SubjectIdentity{entity_type: node.kind, canonical_id: node.id}

        true -> nil
      end
    end)
  end

  defp find_first_in_scope(:failure, projection) do
    Enum.find_value(projection.nodes, fn node ->
      if node.attention == :failed do
        %SubjectIdentity{entity_type: node.kind, canonical_id: node.id}
      else
        nil
      end
    end)
  end

  defp find_first_in_scope(:blocked, projection) do
    Enum.find_value(projection.nodes, fn node ->
      if node.attention == :blocked do
        %SubjectIdentity{entity_type: node.kind, canonical_id: node.id}
      else
        nil
      end
    end)
  end
end
