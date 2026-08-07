defmodule Kiln.OperationLifecycle do
  @moduledoc """
  Single authoritative vocabulary for the externally observable state of an
  external operation.

  This module is the one source of truth that both the conservative restart
  classifier (`Kiln.Restart.classify/2`) and the application-facing query path
  (`Kiln.Workflow.orphaned?/1`, the CLI orphan rendering) consume. Keeping the
  vocabulary in one place prevents the Restart and Workflow / CLI paths from
  silently diverging on which operation states require conservative treatment.

  The state set is the canonical one declared in
  `Kiln.Conformance.FirstMonth.operation_states/0` and stored in
  `Kiln.Journal.Entry`. The nonterminal subset (intent_recorded, started) is
  the set that conservative restart and the public query path treat as
  unknown / orphaned.

  This module never mutates state, never reads from the Store, and never
  decides application authorization. It only owns the vocabulary.
  """

  alias Kiln.Conformance.FirstMonth

  @operation_states FirstMonth.operation_states()

  @nonterminal_operation_states [:intent_recorded, :started]

  @type operation_state :: atom()

  @doc "All accepted operation states."
  @spec states() :: [operation_state()]
  def states, do: @operation_states

  @doc "The subset of operation states treated as nonterminal by the restart
  classifier and the public query path."
  @spec nonterminal_states() :: [operation_state()]
  def nonterminal_states, do: @nonterminal_operation_states

  @doc "True when `state` is in the nonterminal set used by conservative
  restart and the application-facing orphan classification."
  @spec nonterminal?(term()) :: boolean()
  def nonterminal?(state) when is_atom(state), do: state in @nonterminal_operation_states
  def nonterminal?(_), do: false

  @doc "String-accepting overload that does not allocate atoms at runtime."
  @spec nonterminal_string?(String.t()) :: boolean()
  def nonterminal_string?(state) when is_binary(state),
    do: state in Enum.map(@nonterminal_operation_states, &Atom.to_string/1)

  def nonterminal_string?(_), do: false
end
