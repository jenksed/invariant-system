defmodule Kiln.Projections.SessionTest do
  @moduledoc """
  Table-driven invariant validation. A valid projection passes; every listed
  internally impossible projection blocks with a stable code.
  """
  use ExUnit.Case, async: true

  alias Kiln.Projections.Session

  defp base do
    %{
      "session" => %{"id" => "ses_1", "state" => "active"},
      "task" => %{"id" => "tsk_1", "state" => "in_progress"},
      "run" => %{"id" => "run_1", "state" => "ready", "root_run_id" => "run_1"},
      "workflow_step" => "intent",
      "pending_decision" => nil,
      "operation" => nil
    }
  end

  defp decision, do: %{"id" => "dec_1", "permitted_responses" => ["approve"]}
  defp op(state), do: %{"id" => "opn_1", "class" => "command_execution", "state" => state}
  defp run(projection, state), do: put_in(projection, ["run", "state"], state)

  test "a valid nonterminal projection passes" do
    assert :ok = Session.validate(base())
  end

  test "waiting_for_user with its decision passes; without it blocks" do
    waiting = base() |> run("waiting_for_user") |> Map.put("pending_decision", decision())
    assert :ok = Session.validate(waiting)

    assert {:error, %{code: :missing_pending_decision}} =
             Session.validate(run(base(), "waiting_for_user"))
  end

  test "a pending decision outside waiting_for_user blocks" do
    assert {:error, %{code: :unexpected_pending_decision}} =
             Session.validate(Map.put(base(), "pending_decision", decision()))
  end

  test "a nonterminal operation is valid only while running" do
    assert :ok = Session.validate(base() |> run("running") |> Map.put("operation", op("started")))

    assert {:error, %{code: :unexpected_active_operation}} =
             Session.validate(Map.put(base(), "operation", op("started")))
  end

  test "an unknown operation is valid only beside an orphaned Run" do
    unknown = Map.put(base(), "operation", op("unknown"))
    orphaned = run(unknown, "orphaned")
    assert :ok = Session.validate(orphaned)

    for state <- ["ready", "failed", "canceled"] do
      assert {:error, %{code: :operation_unknown_with_non_orphaned_run}} =
               Session.validate(run(unknown, state))
    end
  end

  test "terminal Run state must coordinate Task and Session state" do
    completed =
      base()
      |> run("completed")
      |> put_in(["task", "state"], "satisfied")
      |> put_in(["session", "state"], "completed")

    assert :ok = Session.validate(completed)

    assert {:error, %{code: :uncoordinated_terminal_state}} =
             Session.validate(run(base(), "completed"))

    failed =
      base()
      |> run("failed")
      |> put_in(["task", "state"], "abandoned")
      |> put_in(["session", "state"], "abandoned")

    assert :ok = Session.validate(failed)
  end

  test "the Root Run id must equal its root run id" do
    assert {:error, %{code: :run_identity_mismatch}} =
             Session.validate(put_in(base(), ["run", "root_run_id"], "run_2"))
  end
end
