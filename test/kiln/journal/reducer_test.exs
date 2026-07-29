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

  test "the first entry must start the Session" do
    assert {:error, %{code: :missing_session_start}} =
             Reducer.reduce(nil, %{type: "run_transitioned/v1", payload: %{}})
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

  defp session_started do
    %{
      type: "session_started/v1",
      payload: %{
        "session" => %{"id" => "ses_1", "state" => "active"},
        "task" => %{"id" => "tsk_1", "state" => "in_progress"},
        "run" => %{"id" => "run_1", "state" => "ready", "root_run_id" => "run_1"},
        "workflow_step" => "intent",
        "objective_revision" => 0,
        "criteria_revision" => 0,
        "references" => %{}
      }
    }
  end
end
