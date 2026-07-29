defmodule Kiln.Domain.Run do
  @moduledoc """
  Durable Root Run data for the first-month workflow.
  """

  alias Kiln.Domain.{Error, Id, Transition}

  @states [:ready, :running, :waiting_for_user, :orphaned, :completed, :failed, :canceled]
  @workflow_steps [
    :intent,
    :investigation,
    :proposal,
    :approval,
    :application,
    :verification,
    :acceptance,
    :reconciliation
  ]

  @enforce_keys [
    :id,
    :session_id,
    :task_id,
    :root_run_id,
    :state,
    :workflow_step,
    :revision,
    :created_at
  ]
  defstruct [
    :id,
    :session_id,
    :task_id,
    :root_run_id,
    :state,
    :workflow_step,
    :pending_decision_id,
    :active_operation_id,
    :revision,
    :created_at
  ]

  @type state ::
          :ready | :running | :waiting_for_user | :orphaned | :completed | :failed | :canceled
  @type workflow_step ::
          :intent
          | :investigation
          | :proposal
          | :approval
          | :application
          | :verification
          | :acceptance
          | :reconciliation

  @type t :: %__MODULE__{
          id: String.t(),
          session_id: String.t(),
          task_id: String.t(),
          root_run_id: String.t(),
          state: state(),
          workflow_step: workflow_step(),
          pending_decision_id: String.t() | nil,
          active_operation_id: String.t() | nil,
          revision: non_neg_integer(),
          created_at: DateTime.t()
        }

  @spec new_root(map()) :: {:ok, t()} | {:error, Error.t()}
  def new_root(attrs) when is_map(attrs) do
    with :ok <- Id.validate(:run, Map.get(attrs, :id)),
         :ok <- Id.validate(:session, Map.get(attrs, :session_id)),
         :ok <- Id.validate(:task, Map.get(attrs, :task_id)),
         {:ok, created_at} <- datetime(attrs, :created_at) do
      {:ok,
       %__MODULE__{
         id: attrs.id,
         session_id: attrs.session_id,
         task_id: attrs.task_id,
         root_run_id: attrs.id,
         state: :ready,
         workflow_step: :intent,
         pending_decision_id: nil,
         active_operation_id: nil,
         revision: 0,
         created_at: created_at
       }}
    end
  end

  def new_root(_attrs),
    do: {:error, Error.new(:invalid_attributes, "run attributes must be a map")}

  @spec transition(t(), state(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def transition(%__MODULE__{} = run, next_state, opts \\ []) do
    workflow_step = Keyword.get(opts, :workflow_step, run.workflow_step)
    pending_decision_id = Keyword.get(opts, :pending_decision_id, run.pending_decision_id)
    active_operation_id = Keyword.get(opts, :active_operation_id, run.active_operation_id)

    with :ok <- Transition.validate_run(run.state, next_state),
         :ok <- validate_workflow_step(workflow_step),
         :ok <- validate_optional_id(:decision, pending_decision_id),
         :ok <- validate_optional_id(:operation, active_operation_id),
         :ok <- validate_state_references(next_state, pending_decision_id, active_operation_id) do
      {:ok,
       %{
         run
         | state: next_state,
           workflow_step: workflow_step,
           pending_decision_id: pending_decision_id,
           active_operation_id: active_operation_id,
           revision: run.revision + 1
       }}
    end
  end

  @spec states() :: [state()]
  def states, do: @states

  @spec workflow_steps() :: [workflow_step()]
  def workflow_steps, do: @workflow_steps

  defp validate_workflow_step(step) when step in @workflow_steps, do: :ok

  defp validate_workflow_step(_step) do
    {:error, Error.new(:invalid_workflow_step, "workflow step is not supported", :workflow_step)}
  end

  defp validate_optional_id(_kind, nil), do: :ok
  defp validate_optional_id(kind, id), do: Id.validate(kind, id)

  defp validate_state_references(:waiting_for_user, nil, _operation_id) do
    {:error,
     Error.new(
       :missing_pending_decision,
       "waiting_for_user requires a pending decision",
       :pending_decision_id
     )}
  end

  defp validate_state_references(state, decision_id, _operation_id)
       when state != :waiting_for_user and not is_nil(decision_id) do
    {:error,
     Error.new(
       :unexpected_pending_decision,
       "pending decision requires waiting_for_user",
       :pending_decision_id
     )}
  end

  defp validate_state_references(state, _decision_id, operation_id)
       when state in [:ready, :waiting_for_user, :completed, :failed, :canceled] and
              not is_nil(operation_id) do
    {:error,
     Error.new(
       :unexpected_active_operation,
       "run state cannot retain an active operation",
       :active_operation_id
     )}
  end

  defp validate_state_references(_state, _decision_id, _operation_id), do: :ok

  defp datetime(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, %DateTime{} = value} -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a DateTime", field)}
    end
  end
end
