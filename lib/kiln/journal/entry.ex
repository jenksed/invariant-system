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
  # Derived from the single domain authority so commit and replay validation
  # cannot drift from Kiln.Domain.Run.workflow_steps/0.
  @workflow_steps Enum.map(Kiln.Domain.Run.workflow_steps(), &Atom.to_string/1)
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

  @entry_schema "journal_entry/v1"

  @type decoded :: %{type: String.t(), payload: map()}
  @type block :: %{code: atom(), detail: map()}

  @doc "The entry types this reducer version understands."
  @spec known_types() :: [String.t()]
  def known_types, do: @known_types

  @doc "The supported journal envelope schema."
  @spec entry_schema() :: String.t()
  def entry_schema, do: @entry_schema

  @doc """
  The accepted payload schema for `entry_type`, or `nil` when unknown.

  The v1 mapping is the identity mapping; commit and replay share this one
  authority so a row cannot claim a payload schema that mismatches its type.
  """
  @spec payload_schema(String.t()) :: String.t() | nil
  def payload_schema(type) when type in @known_types, do: type
  def payload_schema(_type), do: nil

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
         :ok <- non_empty_string(p, "objective"),
         :ok <- non_empty_string_list(p, "criteria"),
         :ok <- string_list(p, "constraints"),
         :ok <- string_list(p, "exclusions"),
         :ok <- non_neg_int(p, "objective_revision"),
         :ok <- non_neg_int(p, "criteria_revision"),
         :ok <- is_object(p, "references") do
      :ok
    end
  end

  defp validate("criteria_revised/v1", p) do
    with :ok <- non_empty_string_list(p, "criteria"),
         :ok <- non_neg_int(p, "criteria_revision") do
      :ok
    end
  end

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

  defp session(s), do: with(:ok <- id(s, "id", :session), do: member(s, "state", @session_states))
  defp task(s), do: with(:ok <- id(s, "id", :task), do: member(s, "state", @task_states))

  defp run_identity(r) do
    with :ok <- id(r, "id", :run),
         :ok <- member(r, "state", @run_states),
         :ok <- id(r, "root_run_id", :run) do
      :ok
    end
  end

  defp run_move(r) do
    with :ok <- member(r, "from", @run_states), do: member(r, "to", @run_states)
  end

  defp run_target(r), do: member(r, "to", @run_states)

  # subject_kind and subject_id are free-form references, not opaque Kiln ids in
  # the accepted v1 schema, so they are validated only as strings.
  defp decision(d) do
    with :ok <- id(d, "id", :decision),
         :ok <- string(d, "subject_kind"),
         :ok <- string(d, "subject_id"),
         :ok <- non_neg_int(d, "subject_revision"),
         :ok <- string(d, "requested_actor"),
         :ok <- non_empty_string_list(d, "permitted_responses", :empty_response) do
      :ok
    end
  end

  defp operation_intent(o) do
    with :ok <- id(o, "id", :operation), do: member(o, "class", @operation_classes)
  end

  defp operation_observation(o) do
    with :ok <- id(o, "id", :operation), do: member(o, "state", @operation_states)
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

  defp id(map, key, kind) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) ->
        case Kiln.Domain.Id.validate(kind, value) do
          :ok -> :ok
          {:error, _} -> invalid(key, :invalid_id)
        end

      {:ok, _} ->
        invalid(key, :not_a_string)

      :error ->
        invalid(key, :missing)
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

  defp non_empty_string(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> :ok
      {:ok, value} when is_binary(value) -> invalid(key, :empty_string)
      {:ok, _} -> invalid(key, :not_a_string)
      :error -> invalid(key, :missing)
    end
  end

  defp non_empty_string_list(map, key, empty_reason \\ :empty_string) do
    case Map.fetch(map, key) do
      {:ok, [_ | _] = list} ->
        cond do
          Enum.any?(list, &(is_binary(&1) and byte_size(&1) == 0)) ->
            invalid(key, empty_reason)

          Enum.all?(list, &is_binary/1) ->
            :ok

          true ->
            invalid(key, :not_a_string_list)
        end

      {:ok, _} ->
        invalid(key, :not_a_non_empty_list)

      :error ->
        invalid(key, :missing)
    end
  end

  defp string_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, list} when is_list(list) ->
        cond do
          Enum.any?(list, &(is_binary(&1) and byte_size(&1) == 0)) ->
            invalid(key, :empty_string)

          Enum.all?(list, &is_binary/1) ->
            :ok

          true ->
            invalid(key, :not_a_string_list)
        end

      {:ok, _} ->
        invalid(key, :not_a_list)

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
