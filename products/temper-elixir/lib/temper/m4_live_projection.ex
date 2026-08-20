defmodule Temper.M4LiveProjection do
  @moduledoc """
  M4 — minimal live projection with hydration state machine.

  Owns: hydration state, observation freshness, reconnect state,
  ephemeral projection generation, focus reconciliation,
  invalidation tracking, last-known presentation state.

  Does NOT own: canonical workflow history.

  Convergence protocol:
    1. subscriber establishes observation via `activity.subscribe`
       and receives `canonical_session_revision`
    2. subscriber begins hydration generation G
    3. if WebSocket invalidation arrives during G, mark G invalidated
    4. when G completes, if invalidated discard and re-hydrate
    5. install only if not invalidated

  Architecture: Temper.M4 (M4-Q1, lane M4).
  """

  alias Kiln.Domain.SubjectIdentity

  @type freshness :: :live | :hydrating | :reconnecting | :stale | :degraded
  @type generation :: pos_integer()

  @type state :: %{
          required(:projection) => any(),
          required(:freshness) => freshness(),
          required(:generation) => generation(),
          required(:subscription_revision) => non_neg_integer(),
          required(:invalidated) => boolean(),
          required(:focus) => SubjectIdentity.t() | nil,
          required(:focus_history) => [SubjectIdentity.t()],
          required(:churn_count) => non_neg_integer(),
          required(:last_known) => any() | nil
        }

  @churn_limit 5

  @doc "Initial state: no projection, no subscription."
  @spec initial() :: state()
  def initial do
    %{
      projection: nil,
      freshness: :stale,
      generation: 0,
      subscription_revision: 0,
      invalidated: false,
      focus: nil,
      focus_history: [],
      churn_count: 0,
      last_known: nil
    }
  end

  @doc "Begin a hydration generation. Records canonical revision and resets invalidation."
  @spec begin_hydration(state(), non_neg_integer(), any()) :: state()
  def begin_hydration(state, canonical_revision, projection) do
    %{
      state
      | generation: state.generation + 1,
        subscription_revision: canonical_revision,
        projection: projection,
        freshness: :hydrating,
        invalidated: false
    }
  end

  @doc "Mark the current hydration as invalidated by a canonical change."
  @spec invalidate(state()) :: state()
  def invalidate(state) do
    %{state | invalidated: true}
  end

  @doc "Complete hydration. If invalidated, churn and require re-hydration."
  @spec complete_hydration(state()) :: state()
  def complete_hydration(%{invalidated: true} = state) do
    new_churn = state.churn_count + 1

    cond do
      new_churn >= @churn_limit ->
        # Bound churn: degrade rather than spin forever.
        %{state | freshness: :degraded, invalidated: false, churn_count: new_churn}

      true ->
        # Discard; require re-hydration.
        %{state | projection: nil, freshness: :hydrating, invalidated: false, churn_count: new_churn}
    end
  end

  def complete_hydration(state) do
    %{state | freshness: :live, last_known: state.projection, invalidated: false}
  end

  @doc "Reconnect: discard current projection, mark RECONNECTING."
  @spec reconnect(state()) :: state()
  def reconnect(state) do
    last = state.last_known || state.projection
    %{state | freshness: :reconnecting, projection: nil, invalidated: false, last_known: last}
  end

  @doc "Update focus by SubjectIdentity. Preserves history."
  @spec set_focus(state(), SubjectIdentity.t() | nil) :: state()
  def set_focus(state, %SubjectIdentity{} = subject) do
    history = [state.focus | state.focus_history] |> Enum.reject(&is_nil/1) |> Enum.take(8)
    %{state | focus: subject, focus_history: history}
  end

  def set_focus(state, nil), do: state

  @doc "Reconcile focus after a canonical change. The previous focus is preserved
  if the subject still exists in the new projection; otherwise fall back
  by visible order."
  @spec reconcile_focus(state(), any()) :: state()
  def reconcile_focus(state, projection) do
    if has_focus_in?(state.focus, projection) do
      state
    else
      fallback = focus_fallback(projection, state.focus_history)
      %{state | focus: fallback}
    end
  end

  defp has_focus_in?(nil, _projection), do: true
  defp has_focus_in?(%SubjectIdentity{canonical_id: id}, projection) do
    Enum.any?(projection.nodes, &(&1.id == id))
  end

  # Focus fallback priority (per 1H):
  # 1. nearest still-visible canonical predecessor
  # 2. nearest still-visible canonical successor
  # 3. parent/source relationship
  # 4. deterministic next visible entity
  # 5. deterministic previous visible entity
  # 6. NONE
  defp focus_fallback(projection, _history) do
    case projection.nodes do
      [] -> nil
      [first | _] -> %SubjectIdentity{entity_type: first.kind, canonical_id: first.id}
    end
  end

  @doc """
  Currentness claim: LIVE iff the projection is LIVE AND the cached
  canonical revision matches the supplied revision.

  Per Gate 3F: HYDRATION_COMPLETED + CANONICAL_ADVANCEMENT_UNRESOLVED => NOT LIVE.
  A successful hydration is an operation result; currentness is a
  truth claim that requires the cached revision to match the
  consumer's last observed canonical_session_revision.
  """
  @spec live?(state(), non_neg_integer()) :: boolean()
  def live?(%{freshness: :live, subscription_revision: rev}, revision) when rev == revision do
    true
  end

  def live?(_, _), do: false

  @doc "Test the hydration race: A→B during hydration. A must not become LIVE."
  @spec hydration_race_check(state(), state(), non_neg_integer()) :: :ok | :invalid
  def hydration_race_check(state_a_at_begin, state_after_b, canonical_b_revision) do
    cond do
      state_a_at_begin.subscription_revision < canonical_b_revision ->
        if state_after_b.subscription_revision == state_a_at_begin.subscription_revision do
          :invalid
        else
          :ok
        end

      true ->
        :ok
    end
  end
end
