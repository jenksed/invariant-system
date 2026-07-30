defmodule Kiln.Journal.Reducer do
  @moduledoc """
  Pure, versioned reducer from one journal entry to the next Session projection.

  It never touches SQLite, the Repository, a provider, or the transcript. Given
  the current projection (or `nil` before the first entry) and one decoded entry,
  it validates the entry kind, payload shape, and state correspondence, enforces
  the accepted Run transition and operation-state progressions, coordinates
  terminal Run, Task, and Session state, and validates the complete projection
  invariants after every reduction. It returns the next projection or a
  deterministic error (P1-S01-T03-R01, R03). Commit and replay share this one
  reducer, so an accepted projection is always internally valid.
  """

  alias Kiln.Domain.Transition
  alias Kiln.Projections.Session

  @run_states %{
    "ready" => :ready,
    "running" => :running,
    "waiting_for_user" => :waiting_for_user,
    "orphaned" => :orphaned,
    "completed" => :completed,
    "failed" => :failed,
    "canceled" => :canceled
  }

  # Accepted operation-state progressions. Terminal states have no successor.
  @operation_progression %{
    "intent_recorded" => ["started", "succeeded", "failed", "canceled", "unknown"],
    "started" => ["succeeded", "failed", "canceled", "unknown"]
  }

  @nonterminal_operation_states ["intent_recorded", "started"]

  @type projection :: Session.t()
  @type entry :: %{type: String.t(), payload: map()}
  @type error :: %{code: atom(), detail: map()}

  @doc "The journal entry types this reducer version understands."
  @spec known_types() :: [String.t()]
  def known_types do
    [
      "session_started/v1",
      "criteria_revised/v1",
      "run_transitioned/v1",
      "pending_decision_recorded/v1",
      "user_decision_recorded/v1",
      "external_operation_intent_recorded/v1",
      "external_operation_observed/v1"
    ]
  end

  @doc "Fold `entries` over `projection` (or `nil`) in order, stopping on error."
  @spec reduce_all(projection() | nil, [entry()]) :: {:ok, projection()} | {:error, error()}
  def reduce_all(projection, entries) do
    Enum.reduce_while(entries, {:ok, projection}, fn entry, {:ok, acc} ->
      case reduce(acc, entry) do
        {:ok, next} -> {:cont, {:ok, next}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  Apply one entry, then validate the complete projection invariants.

  A successful reduction whose projection is internally impossible returns the
  invariant error rather than the projection.
  """
  @spec reduce(projection() | nil, entry()) :: {:ok, projection()} | {:error, error()}
  def reduce(projection, entry) do
    with {:ok, next} <- do_reduce(projection, entry),
         :ok <- Session.validate(next) do
      {:ok, next}
    end
  end

  # -- per-entry reduction --

  defp do_reduce(nil, %{type: "session_started/v1", payload: payload} = entry) do
    with :ok <- require_keys(payload, ["session", "task", "run", "workflow_step"]),
         :ok <- enforce_start_contract(payload),
         :ok <- bind_session_id(entry, payload) do
      {:ok,
       %{
         "session" => %{"id" => payload["session"]["id"], "state" => "active"},
         "task" => %{"id" => payload["task"]["id"], "state" => "in_progress"},
         "run" => %{
           "id" => payload["run"]["id"],
           "state" => "ready",
           "root_run_id" => payload["run"]["root_run_id"]
         },
         "workflow_step" => "intent",
         "objective" => payload["objective"],
         "criteria" => payload["criteria"],
         "constraints" => payload["constraints"],
         "exclusions" => payload["exclusions"],
         "objective_revision" => payload["objective_revision"] || 0,
         "criteria_revision" => payload["criteria_revision"] || 0,
         "references" => payload["references"] || %{},
         "pending_decision" => nil,
         "operation" => nil,
         "warnings" => [],
         "unknowns" => []
       }}
    end
  end

  defp do_reduce(nil, %{type: type}) do
    {:error, %{code: :missing_session_start, detail: %{type: type}}}
  end

  defp do_reduce(_projection, %{type: "session_started/v1"}) do
    {:error, %{code: :session_already_started, detail: %{}}}
  end

  defp do_reduce(projection, %{type: "criteria_revised/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["criteria_revision"]) do
      {:ok, Map.put(projection, "criteria_revision", payload["criteria_revision"])}
    end
  end

  defp do_reduce(projection, %{type: "run_transitioned/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["run"]),
         :ok <- match_current_run(projection, payload["run"]["from"]),
         {:ok, to} <- transition_run(projection, payload["run"]["to"]),
         {:ok, coordinated} <- coordinate_terminal(put_run_state(projection, to), to) do
      {:ok, maybe_put_step(coordinated, payload["workflow_step"])}
    end
  end

  defp do_reduce(projection, %{type: "pending_decision_recorded/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["decision"]),
         :ok <- no_active_operation(projection),
         {:ok, _to} <- transition_run(projection, "waiting_for_user") do
      {:ok,
       projection
       |> put_run_state("waiting_for_user")
       |> Map.put("pending_decision", payload["decision"])
       |> maybe_put_step(payload["workflow_step"])}
    end
  end

  defp do_reduce(projection, %{type: "user_decision_recorded/v1", payload: payload}) do
    with {:ok, decision} <- current_decision(projection, payload["decision_id"]),
         :ok <- response_permitted(decision, payload["response"]),
         {:ok, _to} <- transition_run(projection, "ready") do
      {:ok,
       projection
       |> put_run_state("ready")
       |> Map.put("pending_decision", nil)
       |> maybe_put_step(payload["workflow_step"])}
    end
  end

  defp do_reduce(projection, %{type: "external_operation_intent_recorded/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["operation"]),
         :ok <- no_current_operation(projection),
         {:ok, _to} <- transition_run(projection, "running") do
      operation = %{
        "id" => payload["operation"]["id"],
        "class" => payload["operation"]["class"],
        "state" => "intent_recorded"
      }

      {:ok,
       projection
       |> put_run_state("running")
       |> Map.put("operation", operation)
       |> maybe_put_step(payload["workflow_step"])}
    end
  end

  defp do_reduce(projection, %{type: "external_operation_observed/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["operation", "run"]),
         {:ok, current} <- current_operation(projection, payload["operation"]["id"]),
         {:ok, next_state} <- operation_progress(current["state"], payload["operation"]["state"]),
         {:ok, observed} <- observe(projection, current, next_state, payload) do
      {:ok, maybe_put_step(observed, payload["workflow_step"])}
    end
  end

  defp do_reduce(_projection, %{type: type}) do
    {:error, %{code: :unknown_entry_type, detail: %{type: type}}}
  end

  # -- operation observation --

  # `started` is an operation-state update, not a Run transition: the Run stays
  # running while dispatch crosses the live boundary.
  defp observe(projection, current, "started", payload) do
    if payload["run"]["to"] == "running" and projection["run"]["state"] == "running" do
      {:ok, Map.put(projection, "operation", Map.put(current, "state", "started"))}
    else
      {:error, %{code: :started_requires_running, detail: %{run_to: payload["run"]["to"]}}}
    end
  end

  defp observe(projection, current, "unknown", payload) do
    if payload["run"]["to"] == "orphaned" do
      with {:ok, _to} <- transition_run(projection, "orphaned") do
        {:ok,
         projection
         |> put_run_state("orphaned")
         |> Map.put("operation", Map.put(current, "state", "unknown"))}
      end
    else
      {:error,
       %{
         code: :unknown_operation_requires_orphaned,
         detail: %{run_to: payload["run"]["to"]}
       }}
    end
  end

  # A terminal observation advances the operation and transitions the Run,
  # preserving the operation identity and class.
  defp observe(projection, current, terminal_state, payload) do
    with {:ok, to} <- transition_run(projection, payload["run"]["to"]),
         {:ok, coordinated} <- coordinate_terminal(put_run_state(projection, to), to) do
      {:ok, Map.put(coordinated, "operation", Map.put(current, "state", terminal_state))}
    end
  end

  defp operation_progress(from, to) do
    if to in Map.get(@operation_progression, from, []) do
      {:ok, to}
    else
      {:error, %{code: :operation_state_regression, detail: %{from: from, to: to}}}
    end
  end

  # -- terminal coordination --

  defp coordinate_terminal(projection, "completed") do
    cond do
      projection["pending_decision"] != nil ->
        {:error, %{code: :completion_pending_decision, detail: %{}}}

      unresolved_operation?(projection["operation"]) ->
        {:error,
         %{code: :completion_unresolved_operation, detail: %{operation: projection["operation"]}}}

      true ->
        {:ok, coordinate(projection, "satisfied", "completed")}
    end
  end

  defp coordinate_terminal(projection, terminal) when terminal in ["failed", "canceled"] do
    if unresolved_operation?(projection["operation"]) do
      {:error,
       %{
         code: :operation_unknown_on_terminal_failure,
         detail: %{operation: projection["operation"], terminal: terminal}
       }}
    else
      {:ok, coordinate(projection, "abandoned", "abandoned")}
    end
  end

  defp coordinate_terminal(projection, _nonterminal), do: {:ok, projection}

  defp coordinate(projection, task_state, session_state) do
    projection
    |> Map.update!("task", &Map.put(&1, "state", task_state))
    |> Map.update!("session", &Map.put(&1, "state", session_state))
  end

  defp unresolved_operation?(nil), do: false

  defp unresolved_operation?(%{"state" => state}),
    do: state in @nonterminal_operation_states or state == "unknown"

  # -- transitions and correspondence --

  defp transition_run(projection, to_string_state) do
    from_string = projection["run"]["state"]

    with {:ok, from} <- run_atom(from_string),
         {:ok, to} <- run_atom(to_string_state) do
      case Transition.validate_run(from, to) do
        :ok ->
          {:ok, to_string_state}

        {:error, _domain_error} ->
          {:error,
           %{code: :invalid_transition, detail: %{from: from_string, to: to_string_state}}}
      end
    end
  end

  defp match_current_run(projection, recorded_from) do
    current = projection["run"]["state"]

    if recorded_from == current do
      :ok
    else
      {:error, %{code: :run_from_mismatch, detail: %{recorded: recorded_from, current: current}}}
    end
  end

  defp current_decision(projection, decision_id) do
    case projection["pending_decision"] do
      %{"id" => ^decision_id} = decision ->
        {:ok, decision}

      nil ->
        {:error, %{code: :no_current_decision, detail: %{decision_id: decision_id}}}

      %{"id" => current} ->
        {:error, %{code: :decision_mismatch, detail: %{recorded: decision_id, current: current}}}
    end
  end

  defp response_permitted(decision, response) do
    permitted = decision["permitted_responses"] || []

    if is_binary(response) and response != "" and response in permitted do
      :ok
    else
      {:error,
       %{
         code: :decision_response_not_permitted,
         detail: %{decision_id: decision["id"], response: response, permitted: permitted}
       }}
    end
  end

  defp no_active_operation(projection) do
    case projection["operation"] do
      %{"state" => state} when state in @nonterminal_operation_states ->
        {:error, %{code: :operation_active, detail: %{operation: projection["operation"]}}}

      _ ->
        :ok
    end
  end

  defp no_current_operation(projection) do
    case projection["operation"] do
      %{"id" => current, "state" => state} when state in @nonterminal_operation_states ->
        {:error, %{code: :operation_already_open, detail: %{current: current}}}

      _ ->
        :ok
    end
  end

  defp current_operation(projection, operation_id) do
    case projection["operation"] do
      %{"id" => ^operation_id} = operation ->
        {:ok, operation}

      nil ->
        {:error, %{code: :no_current_operation, detail: %{operation_id: operation_id}}}

      %{"id" => current} ->
        {:error,
         %{code: :operation_mismatch, detail: %{recorded: operation_id, current: current}}}
    end
  end

  defp run_atom(state) do
    case Map.fetch(@run_states, state) do
      {:ok, atom} -> {:ok, atom}
      :error -> {:error, %{code: :unknown_run_state, detail: %{state: state}}}
    end
  end

  defp put_run_state(projection, state) do
    Map.update!(projection, "run", &Map.put(&1, "state", state))
  end

  defp maybe_put_step(projection, nil), do: projection
  defp maybe_put_step(projection, step), do: Map.put(projection, "workflow_step", step)

  defp require_keys(payload, keys) do
    case Enum.find(keys, fn key -> not Map.has_key?(payload, key) end) do
      nil -> :ok
      missing -> {:error, %{code: :invalid_payload, detail: %{missing: missing}}}
    end
  end

  @start_contract [
    {["session", "state"], "active"},
    {["task", "state"], "in_progress"},
    {["run", "state"], "ready"},
    {["workflow_step"], "intent"}
  ]

  defp enforce_start_contract(payload) do
    Enum.reduce_while(@start_contract, :ok, fn {path, expected}, :ok ->
      if get_in(payload, path) == expected do
        {:cont, :ok}
      else
        {:halt,
         {:error,
          %{
            code: :invalid_session_start,
            detail: %{
              field: Enum.join(path, "."),
              expected: expected,
              actual: get_in(payload, path)
            }
          }}}
      end
    end)
  end

  defp bind_session_id(entry, payload) do
    case Map.get(entry, :session_id) do
      nil ->
        :ok

      session_id ->
        if payload["session"]["id"] == session_id do
          :ok
        else
          {:error,
           %{
             code: :session_id_mismatch,
             detail: %{envelope: session_id, payload: payload["session"]["id"]}
           }}
        end
    end
  end
end
