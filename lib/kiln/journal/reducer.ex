defmodule Kiln.Journal.Reducer do
  @moduledoc """
  Pure, versioned reducer from one journal entry to the next Session projection.

  It never touches SQLite, the Repository, a provider, or the transcript. Given
  the current projection (or `nil` before the first entry) and one decoded entry,
  it validates the entry kind and payload shape, enforces the accepted Run
  transition table, and returns the next projection or a deterministic error
  (P1-S01-T03-R01, R03). Sequence and revision bookkeeping belong to the caller;
  this stays a pure function of domain facts.
  """

  alias Kiln.Domain.Transition

  @run_states %{
    "ready" => :ready,
    "running" => :running,
    "waiting_for_user" => :waiting_for_user,
    "orphaned" => :orphaned,
    "completed" => :completed,
    "failed" => :failed,
    "canceled" => :canceled
  }

  @type projection :: Kiln.Projections.Session.t()
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

  @doc "Apply one entry to the projection."
  @spec reduce(projection() | nil, entry()) :: {:ok, projection()} | {:error, error()}
  def reduce(nil, %{type: "session_started/v1", payload: payload} = entry) do
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

  def reduce(nil, %{type: type}) do
    {:error, %{code: :missing_session_start, detail: %{type: type}}}
  end

  def reduce(_projection, %{type: "session_started/v1"}) do
    {:error, %{code: :session_already_started, detail: %{}}}
  end

  def reduce(projection, %{type: "criteria_revised/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["criteria_revision"]) do
      {:ok, Map.put(projection, "criteria_revision", payload["criteria_revision"])}
    end
  end

  def reduce(projection, %{type: "run_transitioned/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["run"]),
         :ok <- match_current_run(projection, payload["run"]["from"]),
         {:ok, to} <- transition_run(projection, payload["run"]["to"]) do
      {:ok,
       projection
       |> put_run_state(to)
       |> maybe_put_step(payload["workflow_step"])}
    end
  end

  def reduce(projection, %{type: "pending_decision_recorded/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["decision"]),
         {:ok, _to} <- transition_run(projection, "waiting_for_user") do
      {:ok,
       projection
       |> put_run_state("waiting_for_user")
       |> Map.put("pending_decision", payload["decision"])
       |> maybe_put_step(payload["workflow_step"])}
    end
  end

  def reduce(projection, %{type: "user_decision_recorded/v1", payload: payload}) do
    with :ok <- match_current_decision(projection, payload["decision_id"]),
         {:ok, _to} <- transition_run(projection, "ready") do
      {:ok,
       projection
       |> put_run_state("ready")
       |> Map.put("pending_decision", nil)
       |> maybe_put_step(payload["workflow_step"])}
    end
  end

  def reduce(projection, %{type: "external_operation_intent_recorded/v1", payload: payload}) do
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

  def reduce(projection, %{type: "external_operation_observed/v1", payload: payload}) do
    with :ok <- require_keys(payload, ["operation", "run"]),
         {:ok, current} <- match_current_operation(projection, payload["operation"]["id"]),
         {:ok, to} <- transition_run(projection, payload["run"]["to"]) do
      # Preserve the operation identity and class; only advance its state.
      operation = Map.put(current, "state", payload["operation"]["state"])

      {:ok,
       projection
       |> put_run_state(to)
       |> Map.put("operation", operation)
       |> maybe_put_step(payload["workflow_step"])}
    end
  end

  def reduce(_projection, %{type: type}) do
    {:error, %{code: :unknown_entry_type, detail: %{type: type}}}
  end

  # -- internals --

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

  # The recorded prior Run state must equal the projection's current Run state,
  # even when the current state could legally transition to the destination.
  defp match_current_run(projection, recorded_from) do
    current = projection["run"]["state"]

    if recorded_from == current do
      :ok
    else
      {:error, %{code: :run_from_mismatch, detail: %{recorded: recorded_from, current: current}}}
    end
  end

  defp match_current_decision(projection, decision_id) do
    case projection["pending_decision"] do
      %{"id" => ^decision_id} ->
        :ok

      nil ->
        {:error, %{code: :no_current_decision, detail: %{decision_id: decision_id}}}

      %{"id" => current} ->
        {:error, %{code: :decision_mismatch, detail: %{recorded: decision_id, current: current}}}
    end
  end

  defp no_current_operation(projection) do
    case projection["operation"] do
      nil ->
        :ok

      %{"id" => current} ->
        {:error, %{code: :operation_already_open, detail: %{current: current}}}
    end
  end

  defp match_current_operation(projection, operation_id) do
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

  # Session start is atomic and fixed: exactly one active Session, in_progress
  # Task, ready Root Run, and intent workflow step (P0-W21 section 5.1).
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

  # Bind the payload Session identity to the envelope Session id when the caller
  # supplies it, so a projection cannot claim a different Session.
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
