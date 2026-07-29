defmodule Kiln.Journal.EntryTest do
  @moduledoc """
  Typed payload decoding and reducer state-correspondence. Malformed payloads
  return a deterministic block and never raise; the recorded prior Run state,
  the current decision, and the current operation must correspond.
  """
  use ExUnit.Case, async: true

  alias Kiln.Journal.{Entry, Reducer}

  describe "typed payload decoding" do
    test "accepts a well-formed session_started payload" do
      assert {:ok, %{type: "session_started/v1"}} =
               Entry.decode("session_started/v1", session_started_payload())
    end

    test "rejects a missing nested run field" do
      payload = Map.delete(session_started_payload(), "run")

      assert {:error, %{code: :invalid_payload, detail: %{field: "run", reason: :missing}}} =
               Entry.decode("session_started/v1", payload)
    end

    test "rejects a nested value of the wrong type" do
      payload = put_in(session_started_payload(), ["run"], "not-a-map")

      assert {:error, %{code: :invalid_payload, detail: %{field: "run", reason: :not_a_map}}} =
               Entry.decode("session_started/v1", payload)
    end

    test "rejects an unknown Run state" do
      payload = %{"run" => %{"from" => "ready", "to" => "sideways"}}

      assert {:error, %{code: :invalid_payload, detail: %{field: "to", reason: :not_accepted}}} =
               Entry.decode("run_transitioned/v1", payload)
    end

    test "rejects an unknown workflow step" do
      payload = %{"run" => %{"from" => "ready", "to" => "running"}, "workflow_step" => "wat"}

      assert {:error, %{code: :invalid_payload, detail: %{field: "workflow_step"}}} =
               Entry.decode("run_transitioned/v1", payload)
    end

    test "rejects an invalid operation class and state" do
      assert {:error, %{code: :invalid_payload, detail: %{field: "class"}}} =
               Entry.decode("external_operation_intent_recorded/v1", %{
                 "operation" => %{"id" => "opn_1", "class" => "mining"}
               })

      assert {:error, %{code: :invalid_payload, detail: %{field: "state"}}} =
               Entry.decode("external_operation_observed/v1", %{
                 "operation" => %{"id" => "opn_1", "state" => "vibing"},
                 "run" => %{"to" => "ready"}
               })
    end

    test "rejects a negative revision and a non-integer revision" do
      assert {:error, %{code: :invalid_payload, detail: %{field: "criteria_revision"}}} =
               Entry.decode("criteria_revised/v1", %{"criteria_revision" => -1})

      assert {:error, %{code: :invalid_payload, detail: %{field: "criteria_revision"}}} =
               Entry.decode("criteria_revised/v1", %{"criteria_revision" => "one"})
    end

    test "rejects a malformed permitted-responses list and unexpected null" do
      decision = %{
        "id" => "dec_1",
        "subject_kind" => "run",
        "subject_id" => "run_1",
        "subject_revision" => 0,
        "requested_actor" => "local_user",
        "permitted_responses" => [1, 2]
      }

      assert {:error, %{code: :invalid_payload, detail: %{field: "permitted_responses"}}} =
               Entry.decode("pending_decision_recorded/v1", %{"decision" => decision})

      assert {:error, %{code: :invalid_payload, detail: %{field: "response"}}} =
               Entry.decode("user_decision_recorded/v1", %{
                 "decision_id" => "dec_1",
                 "response" => nil
               })
    end

    test "rejects a payload that is not a map and an unknown type" do
      assert {:error, %{code: :invalid_payload, detail: %{reason: :payload_not_a_map}}} =
               Entry.decode("criteria_revised/v1", "nope")

      assert {:error, %{code: :unknown_entry_type}} = Entry.decode("mystery/v9", %{})
    end
  end

  describe "reducer state correspondence" do
    test "rejects a run_transitioned whose recorded from is not the current state" do
      {:ok, projection} = Reducer.reduce(nil, started())

      # Actual current state is ready; a legal ready->running is claimed, but the
      # recorded from says running, which contradicts the current state.
      assert {:error,
              %{code: :run_from_mismatch, detail: %{recorded: "running", current: "ready"}}} =
               Reducer.reduce(projection, %{
                 type: "run_transitioned/v1",
                 payload: %{"run" => %{"from" => "running", "to" => "waiting_for_user"}}
               })
    end

    test "rejects a user decision with no current pending decision" do
      {:ok, projection} = Reducer.reduce(nil, started())

      assert {:error, %{code: :no_current_decision}} =
               Reducer.reduce(projection, %{
                 type: "user_decision_recorded/v1",
                 payload: %{"decision_id" => "dec_1", "response" => "approve"}
               })
    end

    test "rejects a session start with contradictory durable states" do
      payload = put_in(session_started_payload(), ["session", "state"], "completed")

      assert {:error, %{code: :invalid_session_start, detail: %{field: "session.state"}}} =
               Reducer.reduce(nil, %{type: "session_started/v1", payload: payload})

      run_wrong = put_in(session_started_payload(), ["run", "state"], "orphaned")

      assert {:error, %{code: :invalid_session_start, detail: %{field: "run.state"}}} =
               Reducer.reduce(nil, %{type: "session_started/v1", payload: run_wrong})
    end

    test "binds the payload Session id to the envelope Session id" do
      payload = session_started_payload()

      assert {:error, %{code: :session_id_mismatch}} =
               Reducer.reduce(nil, %{
                 type: "session_started/v1",
                 payload: payload,
                 session_id: "ses_other"
               })

      assert {:ok, _} =
               Reducer.reduce(nil, %{
                 type: "session_started/v1",
                 payload: payload,
                 session_id: "ses_1"
               })
    end

    test "rejects an operation observation for the wrong current operation" do
      {:ok, projection} = Reducer.reduce(nil, started())

      {:ok, running} =
        Reducer.reduce(projection, %{
          type: "external_operation_intent_recorded/v1",
          payload: %{"operation" => %{"id" => "opn_1", "class" => "command_execution"}}
        })

      assert {:error, %{code: :operation_mismatch}} =
               Reducer.reduce(running, %{
                 type: "external_operation_observed/v1",
                 payload: %{
                   "operation" => %{"id" => "opn_OTHER", "state" => "succeeded"},
                   "run" => %{"to" => "ready"}
                 }
               })
    end
  end

  defp session_started_payload do
    %{
      "session" => %{"id" => "ses_1", "state" => "active"},
      "task" => %{"id" => "tsk_1", "state" => "in_progress"},
      "run" => %{"id" => "run_1", "state" => "ready", "root_run_id" => "run_1"},
      "workflow_step" => "intent",
      "objective_revision" => 0,
      "criteria_revision" => 0,
      "references" => %{}
    }
  end

  defp started do
    %{type: "session_started/v1", payload: session_started_payload()}
  end
end
