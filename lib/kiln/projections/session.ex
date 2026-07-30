defmodule Kiln.Projections.Session do
  @moduledoc """
  The current first-month Session projection: shape, schema, reducer version,
  digest, and revision/sequence stamping.

  A projection is plain string-keyed data so the same logical state always
  encodes to the same canonical bytes. The committer and the replay rebuild both
  stamp the same journal sequence and reducer version, so a stored projection and
  a fresh rebuild are byte-for-byte comparable (P1-S01-T03-R10, R11).
  """

  alias Kiln.Store.Canonical

  @schema "session_projection/v1"
  @reducer_version "1"

  @type t :: %{optional(String.t()) => term()}

  @doc "The projection schema identifier."
  @spec schema() :: String.t()
  def schema, do: @schema

  @doc "The reducer version stamped into every projection it produces."
  @spec reducer_version() :: String.t()
  def reducer_version, do: @reducer_version

  @doc "Canonical SHA-256 digest of a projection."
  @spec digest(t()) :: String.t()
  def digest(projection), do: Canonical.digest(@schema, projection)

  @doc """
  Stamp the journal position and reducer version onto a reduced projection.

  Both the append transaction and the replay rebuild call this so their outputs
  are identical for the same journal prefix.
  """
  @spec stamp(t(), non_neg_integer(), non_neg_integer()) :: t()
  def stamp(projection, session_revision, last_sequence) do
    projection
    |> Map.put("schema", @schema)
    |> Map.put("reducer_version", @reducer_version)
    |> Map.put("session_revision", session_revision)
    |> Map.put("last_sequence", last_sequence)
  end

  @nonterminal_operation_states ["intent_recorded", "started"]

  @doc """
  Validate the complete internal invariants of a reduced projection.

  Applied after every successful reduction, in both commit and replay, so an
  accepted projection can never hold contradictory durable facts: a pending
  decision only while `waiting_for_user`, a nonterminal operation only while
  `running`, terminal Run state coordinated with Task and Session state, and a
  first-month Root Run whose id equals its root run id. Returns a deterministic
  error naming the conflicting field.
  """
  @spec validate(t()) :: :ok | {:error, %{code: atom(), detail: map()}}
  def validate(projection) do
    with :ok <- validate_identity(projection),
         :ok <- validate_decision(projection),
         :ok <- validate_operation(projection) do
      validate_coordination(projection)
    end
  end

  defp validate_identity(projection) do
    run = projection["run"]

    if run["id"] == run["root_run_id"] do
      :ok
    else
      invalid(:run_identity_mismatch, %{id: run["id"], root_run_id: run["root_run_id"]})
    end
  end

  defp validate_decision(projection) do
    run_state = projection["run"]["state"]
    decision = projection["pending_decision"]

    case {run_state, decision} do
      {"waiting_for_user", nil} -> invalid(:missing_pending_decision, %{run_state: run_state})
      {"waiting_for_user", _decision} -> :ok
      {_state, nil} -> :ok
      {state, _decision} -> invalid(:unexpected_pending_decision, %{run_state: state})
    end
  end

  defp validate_operation(projection) do
    run_state = projection["run"]["state"]
    operation = projection["operation"]

    cond do
      is_nil(operation) ->
        :ok

      operation["state"] == "unknown" and run_state == "orphaned" ->
        :ok

      operation["state"] == "unknown" ->
        invalid(:operation_unknown_with_non_orphaned_run, %{run_state: run_state})

      nonterminal_operation?(operation) and run_state == "running" ->
        :ok

      nonterminal_operation?(operation) ->
        invalid(:unexpected_active_operation, %{run_state: run_state})

      true ->
        :ok
    end
  end

  defp nonterminal_operation?(%{"state" => state}), do: state in @nonterminal_operation_states
  defp nonterminal_operation?(_), do: false

  # The first-month contract couples Run, Task, and Session state.
  defp validate_coordination(projection) do
    run_state = projection["run"]["state"]
    task_state = projection["task"]["state"]
    session_state = projection["session"]["state"]

    expected =
      case run_state do
        "completed" -> {"satisfied", "completed"}
        "failed" -> {"abandoned", "abandoned"}
        "canceled" -> {"abandoned", "abandoned"}
        _active_or_uncertain -> {"in_progress", "active"}
      end

    if {task_state, session_state} == expected do
      :ok
    else
      invalid(:uncoordinated_terminal_state, %{
        run: run_state,
        task: task_state,
        session: session_state,
        expected_task: elem(expected, 0),
        expected_session: elem(expected, 1)
      })
    end
  end

  defp invalid(code, detail), do: {:error, %{code: code, detail: detail}}
end
