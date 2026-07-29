defmodule Kiln.Store.Projection do
  @moduledoc """
  Pure reducer that folds journal entries into one current Session projection.

  The reducer never touches SQLite, the Repository, a provider, or the
  transcript. It takes the current projection (or `nil` before the first entry)
  plus one validated journal entry and returns the next projection or a
  deterministic error. Revision and sequence bookkeeping are stamped by the
  journal committer, not here, so this stays a pure function of domain facts.
  """

  @schema "session_projection/v1"

  alias Kiln.Store.Error

  @type t :: %{optional(String.t()) => term()}
  @type entry :: %{type: String.t(), payload: map()}

  @doc "The projection schema identifier."
  @spec schema() :: String.t()
  def schema, do: @schema

  @doc "Fold `entries` over `projection` (or `nil`) in order."
  @spec reduce_all(t() | nil, [entry()]) :: {:ok, t()} | {:error, Error.t()}
  def reduce_all(projection, entries) do
    Enum.reduce_while(entries, {:ok, projection}, fn entry, {:ok, acc} ->
      case reduce(acc, entry) do
        {:ok, next} -> {:cont, {:ok, next}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc "Apply one entry to the projection."
  @spec reduce(t() | nil, entry()) :: {:ok, t()} | {:error, Error.t()}
  def reduce(nil, %{type: "session_started/v1", payload: payload}) do
    {:ok,
     %{
       "schema" => @schema,
       "session" => %{"id" => payload["session"]["id"], "state" => payload["session"]["state"]},
       "task" => %{"id" => payload["task"]["id"], "state" => payload["task"]["state"]},
       "run" => %{
         "id" => payload["run"]["id"],
         "state" => payload["run"]["state"],
         "root_run_id" => payload["run"]["root_run_id"]
       },
       "workflow_step" => payload["workflow_step"],
       "objective_revision" => payload["objective_revision"],
       "criteria_revision" => payload["criteria_revision"],
       "references" => payload["references"],
       "pending_decision" => nil,
       "operation" => nil
     }}
  end

  def reduce(nil, %{type: type}) do
    {:error,
     Error.new(:integrity, :missing_session_start, "first entry must start the Session", %{
       type: type
     })}
  end

  def reduce(_projection, %{type: "session_started/v1"}) do
    {:error,
     Error.new(:integrity, :session_already_started, "the Session is already started", %{})}
  end

  def reduce(projection, %{type: "run_transitioned/v1", payload: payload}) do
    run = Map.put(projection["run"], "state", payload["run"]["to"])

    {:ok,
     projection
     |> Map.put("run", run)
     |> Map.put("workflow_step", payload["workflow_step"] || projection["workflow_step"])}
  end

  def reduce(_projection, %{type: type}) do
    {:error,
     Error.new(:integrity, :unknown_entry_type, "no reducer for entry type", %{type: type})}
  end
end
