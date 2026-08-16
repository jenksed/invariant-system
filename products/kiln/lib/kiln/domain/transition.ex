defmodule Kiln.Domain.Transition do
  @moduledoc """
  Pure validation for the accepted first-month Root Run transition table.
  """

  alias Kiln.Domain.Error

  @run_states [:ready, :running, :waiting_for_user, :orphaned, :completed, :failed, :canceled]

  @allowed_run_transitions MapSet.new([
                             {:ready, :running},
                             {:running, :ready},
                             {:running, :waiting_for_user},
                             {:waiting_for_user, :ready},
                             {:ready, :completed},
                             {:ready, :failed},
                             {:running, :failed},
                             {:ready, :canceled},
                             {:running, :canceled},
                             {:waiting_for_user, :canceled},
                             {:running, :orphaned},
                             {:ready, :orphaned},
                             {:orphaned, :ready},
                             {:orphaned, :failed},
                             {:orphaned, :canceled}
                           ])

  @spec validate_run(atom(), atom()) :: :ok | {:error, Error.t()}
  def validate_run(from, to) when from in @run_states and to in @run_states do
    if MapSet.member?(@allowed_run_transitions, {from, to}) do
      :ok
    else
      {:error,
       Error.new(:invalid_run_transition, "Root Run transition is not allowed", :state, %{
         from: from,
         to: to
       })}
    end
  end

  def validate_run(from, to) do
    {:error,
     Error.new(:unsupported_run_state, "Root Run state is not supported", :state, %{
       from: from,
       to: to
     })}
  end

  @spec allowed_run_transitions() :: MapSet.t({atom(), atom()})
  def allowed_run_transitions, do: @allowed_run_transitions
end
