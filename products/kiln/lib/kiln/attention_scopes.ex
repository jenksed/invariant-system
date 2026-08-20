defmodule Kiln.AttentionScopes do
  @moduledoc """
  M4 — three explicit attention scopes.

  All three derive from the same canonical pending-decision facts
  at their explicit scope. None is independently computed in
  render code.

    SESSION_NEEDS_YOU_COUNT
      Number of canonical pending human decisions in the
      session/workspace. Drives the "needs you: N" header.

    CURRENT_LIFECYCLE_NEEDS_YOU
      The currently visible/selected lifecycle contains a pending
      human decision. Drives the "★ YOUR CALL" header.

    SELECTED_ITEM_NEEDS_YOU
      The selected canonical subject itself is bound to a pending
      human decision. Drives the inspector's "NEEDS YOUR DECISION"
      banner.

  The interface must never confuse:
    "something needs you" (SESSION)
  with
    "this thing needs you" (SELECTED).

  Architecture: Kiln.M4 (M4-A, lane M4).

  ## Ownership classification (M4-Q1C Gate 4)

  This module is a **pure projection** over canonical pending-decision
  facts. It does NOT own selection (the caller passes selection in),
  hydration state, or canonical workflow truth. It is correctly
  classified as PLACEMENT_SMELL: the module name `Kiln.AttentionScopes`
  is misleading because the projection is consumed by Temper's operator
  attention surface. Renaming is deferred — it requires coordinated
  updates across tests and consumers and is not low-risk for Q1C.
  """

  alias Kiln.Domain.SubjectIdentity

  @type pending_decision :: %{
          required(:id) => String.t(),
          required(:subject_id) => String.t(),
          required(:subject_kind) => String.t(),
          required(:lifecycle_scope) => String.t() | nil,
          required(:actionable) => boolean(),
          required(:requested_actor) => String.t()
        }

  @type scope_summary :: %{
          required(:session_needs_you_count) => non_neg_integer(),
          required(:current_lifecycle_needs_you) => boolean(),
          required(:pending_decisions) => [pending_decision()]
        }

  @type selection_summary :: %{
          required(:selected_item_needs_you) => boolean(),
          required(:selected_actionable_decision) => pending_decision() | nil
        }

  @doc """
  Compute the three attention scopes for a session.

  `pending_decisions` is the canonical list of pending-decision
  envelopes in the current session/workspace. The function is
  pure: same input -> same output.
  """
  @spec session_scope([pending_decision()]) :: scope_summary()
  def session_scope(pending_decisions) do
    actionable = Enum.filter(pending_decisions, & &1.actionable)

    %{
      session_needs_you_count: length(actionable),
      current_lifecycle_needs_you:
        Enum.any?(actionable, &(&1.lifecycle_scope == "current")),
      pending_decisions: pending_decisions
    }
  end

  @doc """
  Compute the selection-level attention scope for a single
  selected SubjectIdentity.
  """
  @spec selection_scope(SubjectIdentity.t() | nil, [pending_decision()]) :: selection_summary()
  def selection_scope(nil, _pending_decisions), do: %{selected_item_needs_you: false, selected_actionable_decision: nil}

  def selection_scope(%SubjectIdentity{} = subject, pending_decisions) do
    matching =
      Enum.find(pending_decisions, fn pd ->
        pd.subject_id == subject.canonical_id and pd.actionable
      end)

    %{
      selected_item_needs_you: matching != nil,
      selected_actionable_decision: matching
    }
  end

  @doc "True iff the lifecycle scope identifier marks this as the current visible lifecycle."
  @spec current_lifecycle?(String.t() | nil) :: boolean()
  def current_lifecycle?("current"), do: true
  def current_lifecycle?(_), do: false
end
