defmodule Kiln.Domain.Session do
  @moduledoc """
  Pure constructor for one active Session, initial Task, and ready Root Run.
  """

  alias Kiln.Domain.{Error, Id, ProjectObservation, Run, Task}

  @states [:active, :completed, :abandoned]

  @enforce_keys [
    :id,
    :project_observation_id,
    :initial_task_id,
    :root_run_id,
    :objective,
    :criteria_revision,
    :state,
    :revision,
    :started_at
  ]
  defstruct [
    :id,
    :project_observation_id,
    :initial_task_id,
    :root_run_id,
    :objective,
    :criteria_revision,
    :state,
    :revision,
    :started_at
  ]

  @type state :: :active | :completed | :abandoned

  @type t :: %__MODULE__{
          id: String.t(),
          project_observation_id: String.t(),
          initial_task_id: String.t(),
          root_run_id: String.t(),
          objective: String.t(),
          criteria_revision: non_neg_integer(),
          state: state(),
          revision: non_neg_integer(),
          started_at: DateTime.t()
        }

  @type start_result :: %{session: t(), task: Task.t(), run: Run.t()}

  @spec start(map(), keyword()) :: {:ok, start_result()} | {:error, Error.t()}
  def start(attrs, opts \\ [])

  def start(attrs, opts) when is_map(attrs) and is_list(opts) do
    entropy_source = Keyword.get(opts, :entropy_source, &:crypto.strong_rand_bytes/1)

    with {:ok, project_observation} <- project_observation(attrs),
         {:ok, objective} <- nonempty_string(attrs, :objective),
         {:ok, criteria} <- nonempty_string_list(attrs, :criteria, minimum: 1),
         {:ok, constraints} <- nonempty_string_list(attrs, :constraints, minimum: 0),
         {:ok, exclusions} <- nonempty_string_list(attrs, :exclusions, minimum: 0),
         {:ok, started_at} <- datetime(attrs, :started_at),
         {:ok, session_id} <- Id.generate(:session, entropy_source),
         {:ok, task_id} <- Id.generate(:task, entropy_source),
         {:ok, run_id} <- Id.generate(:run, entropy_source),
         {:ok, task} <-
           Task.new(%{
             id: task_id,
             session_id: session_id,
             statement: objective,
             criteria: criteria,
             constraints: constraints,
             exclusions: exclusions,
             created_at: started_at
           }),
         {:ok, run} <-
           Run.new_root(%{
             id: run_id,
             session_id: session_id,
             task_id: task_id,
             created_at: started_at
           }) do
      session = %__MODULE__{
        id: session_id,
        project_observation_id: project_observation.id,
        initial_task_id: task.id,
        root_run_id: run.id,
        objective: objective,
        criteria_revision: 0,
        state: :active,
        revision: 0,
        started_at: started_at
      }

      {:ok, %{session: session, task: task, run: run}}
    end
  end

  def start(_attrs, _opts) do
    {:error,
     Error.new(
       :invalid_attributes,
       "Session start attributes must be a map and options must be a list"
     )}
  end

  @spec states() :: [state()]
  def states, do: @states

  defp project_observation(attrs) do
    case Map.fetch(attrs, :project_observation) do
      {:ok, %ProjectObservation{} = value} ->
        {:ok, value}

      _ ->
        {:error,
         Error.new(
           :invalid_field,
           "project_observation must be a ProjectObservation",
           :project_observation
         )}
    end
  end

  defp nonempty_string(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a non-empty string", field)}
    end
  end

  defp nonempty_string_list(attrs, field, minimum: minimum) do
    value = Map.get(attrs, field, [])

    if is_list(value) and length(value) >= minimum and
         Enum.all?(value, &(is_binary(&1) and byte_size(&1) > 0)) do
      {:ok, value}
    else
      {:error, Error.new(:invalid_field, "field must be a list of non-empty strings", field)}
    end
  end

  defp datetime(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, %DateTime{} = value} -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a DateTime", field)}
    end
  end
end
