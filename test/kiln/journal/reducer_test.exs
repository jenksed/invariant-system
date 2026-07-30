defmodule Kiln.Journal.ReducerTest do
  use ExUnit.Case, async: true

  alias Kiln.Journal.Reducer

  test "builds the initial projection from session_started" do
    entry = %{
      type: "session_started/v1",
      payload: %{
        "session" => %{"id" => "ses_1", "state" => "active"},
        "task" => %{"id" => "tsk_1", "state" => "in_progress"},
        "run" => %{"id" => "run_1", "state" => "ready", "root_run_id" => "run_1"},
        "workflow_step" => "intent",
        "objective" => "Build the feature",
        "criteria" => ["The feature works"],
        "constraints" => [],
        "exclusions" => [],
        "objective_revision" => 0,
        "criteria_revision" => 0,
        "references" => %{"project_observation_id" => "pro_1"}
      }
    }

    assert {:ok, projection} = Reducer.reduce(nil, entry)
    assert projection["session"]["state"] == "active"
    assert projection["run"]["state"] == "ready"
    assert projection["pending_decision"] == nil
    assert projection["operation"] == nil
  end

  test "session start projects objective, criteria, constraints, and exclusions for restart" do
    assert {:ok, projection} = Reducer.reduce(nil, session_started())
    assert projection["objective"] == "Build the feature"
    assert projection["criteria"] == ["The feature works"]
    assert projection["constraints"] == []
    assert projection["exclusions"] == []
  end

  test "the first entry must start the Session" do
    assert {:error, %{code: :missing_session_start}} =
             Reducer.reduce(nil, %{type: "run_transitioned/v1", payload: %{}})
  end

  test "a terminal known operation permits recording the next operation intent" do
    for state <- ["succeeded", "failed", "canceled"] do
      {:ok, projection} = Reducer.reduce(nil, session_started())
      terminal = %{"id" => "opn_old", "class" => "command_execution", "state" => state}
      projection = Map.put(projection, "operation", terminal)

      assert {:ok, next} =
               Reducer.reduce(projection, %{
                 type: "external_operation_intent_recorded/v1",
                 payload: %{"operation" => %{"id" => "opn_new", "class" => "command_execution"}}
               })

      assert next["operation"] == %{
               "id" => "opn_new",
               "class" => "command_execution",
               "state" => "intent_recorded"
             }
    end
  end

  test "accepts a valid Run transition and rejects an invalid one" do
    {:ok, projection} = Reducer.reduce(nil, session_started())

    assert {:ok, running} =
             Reducer.reduce(projection, %{
               type: "run_transitioned/v1",
               payload: %{"run" => %{"from" => "ready", "to" => "running"}}
             })

    assert running["run"]["state"] == "running"

    assert {:error, %{code: :invalid_transition}} =
             Reducer.reduce(projection, %{
               type: "run_transitioned/v1",
               payload: %{"run" => %{"from" => "ready", "to" => "waiting_for_user"}}
             })
  end

  test "rejects an unknown entry kind and a missing payload key" do
    {:ok, projection} = Reducer.reduce(nil, session_started())

    assert {:error, %{code: :unknown_entry_type}} =
             Reducer.reduce(projection, %{type: "mystery/v9", payload: %{}})

    assert {:error, %{code: :invalid_payload, detail: %{missing: "criteria_revision"}}} =
             Reducer.reduce(projection, %{type: "criteria_revised/v1", payload: %{}})
  end

  test "a terminal Run transition coordinates Task and Session state" do
    {:ok, projection} = Reducer.reduce(nil, session_started())

    assert {:ok, completed} = transition(projection, "ready", "completed")
    assert completed["run"]["state"] == "completed"
    assert completed["task"]["state"] == "satisfied"
    assert completed["session"]["state"] == "completed"

    {:ok, fresh} = Reducer.reduce(nil, session_started())
    assert {:ok, failed} = transition(fresh, "ready", "failed")
    assert failed["task"]["state"] == "abandoned"
    assert failed["session"]["state"] == "abandoned"
  end

  test "a raw transition cannot leave a pending decision attached to ready" do
    {:ok, waiting} = to_waiting()

    assert {:error, %{code: :unexpected_pending_decision}} =
             transition(waiting, "waiting_for_user", "ready")
  end

  test "a raw transition cannot leave a nonterminal operation attached to ready" do
    {:ok, running} = with_operation()

    assert {:error, %{code: :unexpected_active_operation}} =
             transition(running, "running", "ready")
  end

  test "recording a pending decision while an operation is active blocks" do
    {:ok, running} = with_operation()

    assert {:error, %{code: :operation_active}} =
             Reducer.reduce(running, %{
               type: "pending_decision_recorded/v1",
               payload: %{"decision" => decision()}
             })
  end

  test "an unpermitted decision response blocks" do
    {:ok, waiting} = to_waiting()

    assert {:error, %{code: :decision_response_not_permitted}} =
             Reducer.reduce(waiting, %{
               type: "user_decision_recorded/v1",
               payload: %{"decision_id" => "dec_1", "response" => "banana"}
             })

    assert {:ok, ready} =
             Reducer.reduce(waiting, %{
               type: "user_decision_recorded/v1",
               payload: %{"decision_id" => "dec_1", "response" => "approve"}
             })

    assert ready["run"]["state"] == "ready"
    assert ready["pending_decision"] == nil
  end

  test "a started observation keeps the Run running; a regression blocks" do
    {:ok, running} = with_operation()

    assert {:ok, started} =
             Reducer.reduce(running, %{
               type: "external_operation_observed/v1",
               payload: %{
                 "operation" => %{"id" => "opn_1", "state" => "started"},
                 "run" => %{"to" => "running"}
               }
             })

    assert started["run"]["state"] == "running"
    assert started["operation"]["state"] == "started"

    {:ok, succeeded} =
      Reducer.reduce(started, %{
        type: "external_operation_observed/v1",
        payload: %{
          "operation" => %{"id" => "opn_1", "state" => "succeeded"},
          "run" => %{"to" => "ready"}
        }
      })

    assert {:error, %{code: :operation_state_regression}} =
             Reducer.reduce(succeeded, %{
               type: "external_operation_observed/v1",
               payload: %{
                 "operation" => %{"id" => "opn_1", "state" => "started"},
                 "run" => %{"to" => "running"}
               }
             })
  end

  test "an unknown operation observation forces the Run to orphaned" do
    {:ok, running} = with_operation()

    assert {:ok, orphaned} =
             Reducer.reduce(running, %{
               type: "external_operation_observed/v1",
               payload: %{
                 "operation" => %{"id" => "opn_1", "state" => "unknown"},
                 "run" => %{"to" => "orphaned"}
               }
             })

    assert orphaned["run"]["state"] == "orphaned"
    assert orphaned["operation"]["state"] == "unknown"
  end

  test "an unknown operation observation rejects a non-orphaned Run target" do
    {:ok, running} = with_operation()

    assert {:error, %{code: :unknown_operation_requires_orphaned}} =
             Reducer.reduce(running, %{
               type: "external_operation_observed/v1",
               payload: %{
                 "operation" => %{"id" => "opn_1", "state" => "unknown"},
                 "run" => %{"to" => "ready"}
               }
             })
  end

  test "failure and cancellation block while an operation remains unknown" do
    {:ok, unknown} = unknown_operation()

    for terminal <- ["failed", "canceled"] do
      assert {:error, %{code: :operation_unknown_on_terminal_failure}} =
               transition(unknown, "orphaned", terminal)
    end
  end

  defp transition(projection, from, to) do
    Reducer.reduce(projection, %{
      type: "run_transitioned/v1",
      payload: %{"run" => %{"from" => from, "to" => to}}
    })
  end

  defp to_waiting do
    with {:ok, projection} <- Reducer.reduce(nil, session_started()),
         {:ok, running} <- transition(projection, "ready", "running") do
      Reducer.reduce(running, %{
        type: "pending_decision_recorded/v1",
        payload: %{"decision" => decision()}
      })
    end
  end

  defp with_operation do
    with {:ok, projection} <- Reducer.reduce(nil, session_started()) do
      Reducer.reduce(projection, %{
        type: "external_operation_intent_recorded/v1",
        payload: %{"operation" => %{"id" => "opn_1", "class" => "command_execution"}}
      })
    end
  end

  defp unknown_operation do
    with {:ok, running} <- with_operation() do
      Reducer.reduce(running, %{
        type: "external_operation_observed/v1",
        payload: %{
          "operation" => %{"id" => "opn_1", "state" => "unknown"},
          "run" => %{"to" => "orphaned"}
        }
      })
    end
  end

  defp decision do
    %{
      "id" => "dec_1",
      "subject_kind" => "run",
      "subject_id" => "run_1",
      "subject_revision" => 0,
      "requested_actor" => "local_user",
      "permitted_responses" => ["approve", "deny"]
    }
  end

  defp session_started do
    %{
      type: "session_started/v1",
      payload: %{
        "session" => %{"id" => "ses_1", "state" => "active"},
        "task" => %{"id" => "tsk_1", "state" => "in_progress"},
        "run" => %{"id" => "run_1", "state" => "ready", "root_run_id" => "run_1"},
        "workflow_step" => "intent",
        "objective" => "Build the feature",
        "criteria" => ["The feature works"],
        "constraints" => [],
        "exclusions" => [],
        "objective_revision" => 0,
        "criteria_revision" => 0,
        "references" => %{}
      }
    }
  end
end
