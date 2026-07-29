defmodule Kiln.Journal.Entry do
  @moduledoc """
  Versioned, non-raising decoding of one journal entry payload.

  Each entry type has an explicit accepted payload shape. Decoding validates
  nested map shapes, required identifiers, known states, workflow steps, and
  operation classes and states, non-negative integer revisions, and list content.
  A malformed payload returns a deterministic `{:error, block}` and never raises,
  so replay can block at the exact entry rather than crash or invent state
  (P1-S01-T03-R03, R05).

  Decoding validates shape only. Correspondence to current projection state - the
  recorded prior Run state, the current pending decision, the current operation -
  is enforced by `Kiln.Journal.Reducer`.
  """

  @run_states ~w(ready running waiting_for_user orphaned completed failed canceled)
  @task_states ~w(in_progress satisfied abandoned)
  @session_states ~w(active completed abandoned)
  @workflow_steps ~w(intent execution approval reconciliation completion)
  @operation_classes ~w(model_invocation patch_application command_execution)
  @operation_states ~w(intent_recorded started succeeded failed canceled unknown)

  @known_types ~w(
    session_started/v1
    criteria_revised/v1
    run_transitioned/v1
    pending_decision_recorded/v1
    user_decision_recorded/v1
    external_operation_intent_recorded/v1
    external_operation_observed/v1
  )

  @type decoded :: %{type: String.t(), payload: map()}
  @type block :: %{code: atom(), detail: map()}

  @doc "The entry types this reducer version understands."
  @spec known_types() :: [String.t()]
  def known_types, do: @known_types

  @doc """
  Decode and validate `payload` for `type`.

  Returns `{:ok, %{type: type, payload: validated}}` or a deterministic
  `{:error, %{code: :invalid_payload | :unknown_entry_type, detail: ...}}`.
  """
  @spec decode(String.t(), term()) :: {:ok, decoded()} | {:error, block()}
  def decode(type, payload) when type in @known_types and is_map(payload) do
    case validate(type, payload) do
      :ok -> {:ok, %{type: type, payload: payload}}
      {:error, _} = error -> error
    end
  end

  def decode(type, payload) when is_map(payload) do
    {:error, %{code: :unknown_entry_type, detail: %{type: type}}}
  end

  def decode(type, _payload) do
    {:error, %{code: :invalid_payload, detail: %{type: type, reason: :payload_not_a_map}}}
  end

  # -- per-type shapes --

  defp validate("session_started/v1", p) do
    with :ok <- object(p, "session", &session/1),
         :ok <- object(p, "task", &task/1),
         :ok <- object(p, "run", &run_identity/1),
         :ok <- member(p, "workflow_step", @workflow_steps),
         :ok <- non_neg_int(p, "objective_revision"),
         :ok <- non_neg_int(p, "criteria_revision"),
         :ok <- is_object(p, "references") do
      :ok
    end
  end

  defp validate("criteria_revised/v1", p), do: non_neg_int(p, "criteria_revision")

  defp validate("run_transitioned/v1", p) do
    with :ok <- object(p, "run", &run_move/1),
         :ok <- optional_step(p) do
      :ok
    end
  end

  defp validate("pending_decision_recorded/v1", p) do
    with :ok <- object(p, "decision", &decision/1),
         :ok <- optional_step(p) do
      :ok
    end
  end

  defp validate("user_decision_recorded/v1", p) do
    with :ok <- string(p, "decision_id"),
         :ok <- string(p, "response"),
         :ok <- optional_step(p) do
      :ok
    end
  end

  defp validate("external_operation_intent_recorded/v1", p) do
    with :ok <- object(p, "operation", &operation_intent/1),
         :ok <- optional_step(p) do
      :ok
    end
  end

  defp validate("external_operation_observed/v1", p) do
    with :ok <- object(p, "operation", &operation_observation/1),
         :ok <- object(p, "run", &run_target/1),
         :ok <- optional_step(p) do
      :ok
    end
  end

  # -- nested shapes --

  defp session(s), do: with(:ok <- string(s, "id"), do: member(s, "state", @session_states))
  defp task(s), do: with(:ok <- string(s, "id"), do: member(s, "state", @task_states))

  defp run_identity(r) do
    with :ok <- string(r, "id"),
         :ok <- member(r, "state", @run_states),
         :ok <- string(r, "root_run_id") do
      :ok
    end
  end

  defp run_move(r) do
    with :ok <- member(r, "from", @run_states), do: member(r, "to", @run_states)
  end

  defp run_target(r), do: member(r, "to", @run_states)

  defp decision(d) do
    with :ok <- string(d, "id"),
         :ok <- string(d, "subject_kind"),
         :ok <- string(d, "subject_id"),
         :ok <- non_neg_int(d, "subject_revision"),
         :ok <- string(d, "requested_actor"),
         :ok <- non_empty_string_list(d, "permitted_responses") do
      :ok
    end
  end

  defp operation_intent(o) do
    with :ok <- string(o, "id"), do: member(o, "class", @operation_classes)
  end

  defp operation_observation(o) do
    with :ok <- string(o, "id"), do: member(o, "state", @operation_states)
  end

  # -- primitives --

  defp object(map, key, validator) do
    case Map.fetch(map, key) do
      {:ok, value} when is_map(value) -> validator.(value)
      {:ok, _} -> invalid(key, :not_a_map)
      :error -> invalid(key, :missing)
    end
  end

  defp is_object(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_map(value) -> :ok
      {:ok, _} -> invalid(key, :not_a_map)
      :error -> invalid(key, :missing)
    end
  end

  defp string(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) -> :ok
      {:ok, _} -> invalid(key, :not_a_string)
      :error -> invalid(key, :missing)
    end
  end

  defp member(map, key, allowed) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) ->
        if value in allowed, do: :ok, else: invalid(key, :not_accepted)

      {:ok, _} ->
        invalid(key, :not_a_string)

      :error ->
        invalid(key, :missing)
    end
  end

  defp non_neg_int(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_integer(value) and value >= 0 -> :ok
      {:ok, _} -> invalid(key, :not_a_non_negative_integer)
      :error -> invalid(key, :missing)
    end
  end

  defp non_empty_string_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, [_ | _] = list} ->
        if Enum.all?(list, &is_binary/1), do: :ok, else: invalid(key, :not_a_string_list)

      {:ok, _} ->
        invalid(key, :not_a_non_empty_list)

      :error ->
        invalid(key, :missing)
    end
  end

  # workflow_step is optional, but when present it must be a known step.
  defp optional_step(map) do
    case Map.fetch(map, "workflow_step") do
      :error -> :ok
      {:ok, nil} -> :ok
      {:ok, _} -> member(map, "workflow_step", @workflow_steps)
    end
  end

  defp invalid(key, reason) do
    {:error, %{code: :invalid_payload, detail: %{field: key, reason: reason}}}
  end
end
