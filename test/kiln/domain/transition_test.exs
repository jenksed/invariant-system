defmodule Kiln.Domain.TransitionTest do
  use ExUnit.Case, async: true

  alias Kiln.Domain.{Run, Transition}

  @states [:ready, :running, :waiting_for_user, :orphaned, :completed, :failed, :canceled]
  @allowed MapSet.new([
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

  test "matches the complete accepted Root Run transition matrix" do
    for from <- @states, to <- @states do
      if MapSet.member?(@allowed, {from, to}) do
        assert :ok = Transition.validate_run(from, to), "expected #{from} -> #{to} to pass"
      else
        assert {:error, %{code: :invalid_run_transition}} = Transition.validate_run(from, to),
               "expected #{from} -> #{to} to fail"
      end
    end

    assert Transition.allowed_run_transitions() == @allowed
  end

  test "rejects unsupported states, terminal escape, and direct orphan completion" do
    assert {:error, %{code: :unsupported_run_state}} = Transition.validate_run(:created, :ready)

    assert {:error, %{code: :invalid_run_transition}} =
             Transition.validate_run(:completed, :ready)

    assert {:error, %{code: :invalid_run_transition}} = Transition.validate_run(:failed, :running)
    assert {:error, %{code: :invalid_run_transition}} = Transition.validate_run(:canceled, :ready)

    assert {:error, %{code: :invalid_run_transition}} =
             Transition.validate_run(:orphaned, :completed)
  end

  test "Run transitions keep decision and operation references separate from state" do
    run = %Run{
      id: id("run", 1),
      session_id: id("ses", 2),
      task_id: id("tsk", 3),
      root_run_id: id("run", 1),
      state: :running,
      workflow_step: :approval,
      pending_decision_id: nil,
      active_operation_id: id("opn", 4),
      revision: 2,
      created_at: ~U[2026-07-29 13:30:00Z]
    }

    assert {:error, %{code: :missing_pending_decision}} =
             Run.transition(run, :waiting_for_user, active_operation_id: nil)

    assert {:ok, waiting} =
             Run.transition(run, :waiting_for_user,
               pending_decision_id: id("dec", 5),
               active_operation_id: nil
             )

    assert waiting.state == :waiting_for_user
    assert waiting.workflow_step == :approval
    assert waiting.pending_decision_id == id("dec", 5)
    assert waiting.active_operation_id == nil
    assert waiting.revision == 3
  end

  defp id(prefix, byte) do
    prefix <> "_" <> Base.encode16(:binary.copy(<<byte>>, 16), case: :lower)
  end
end
