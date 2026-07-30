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

    test "validates the required session objective" do
      payload = session_started_payload()

      assert {:error, %{code: :invalid_payload, detail: %{field: "objective"}}} =
               Entry.decode("session_started/v1", Map.delete(payload, "objective"))

      assert {:error, %{code: :invalid_payload, detail: %{field: "objective"}}} =
               Entry.decode("session_started/v1", Map.put(payload, "objective", 1))

      assert {:error, %{code: :invalid_payload, detail: %{field: "objective"}}} =
               Entry.decode("session_started/v1", Map.put(payload, "objective", ""))
    end

    test "validates the required non-empty session criteria list" do
      payload = session_started_payload()

      for criteria <- [nil, "criteria", [], [""], [1]] do
        candidate =
          if is_nil(criteria),
            do: Map.delete(payload, "criteria"),
            else: Map.put(payload, "criteria", criteria)

        assert {:error, %{code: :invalid_payload, detail: %{field: "criteria"}}} =
                 Entry.decode("session_started/v1", candidate)
      end
    end

    test "validates the required session constraints list while allowing an empty list" do
      payload = session_started_payload()
      assert {:ok, _} = Entry.decode("session_started/v1", Map.put(payload, "constraints", []))

      for constraints <- [nil, "constraints", [""], [1]] do
        candidate =
          if is_nil(constraints),
            do: Map.delete(payload, "constraints"),
            else: Map.put(payload, "constraints", constraints)

        assert {:error, %{code: :invalid_payload, detail: %{field: "constraints"}}} =
                 Entry.decode("session_started/v1", candidate)
      end
    end

    test "validates the required session exclusions list while allowing an empty list" do
      payload = session_started_payload()
      assert {:ok, _} = Entry.decode("session_started/v1", Map.put(payload, "exclusions", []))

      for exclusions <- [nil, "exclusions", [""], [1]] do
        candidate =
          if is_nil(exclusions),
            do: Map.delete(payload, "exclusions"),
            else: Map.put(payload, "exclusions", exclusions)

        assert {:error, %{code: :invalid_payload, detail: %{field: "exclusions"}}} =
                 Entry.decode("session_started/v1", candidate)
      end
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
                 "operation" => %{"id" => gid(:operation, 1), "class" => "mining"}
               })

      assert {:error, %{code: :invalid_payload, detail: %{field: "state"}}} =
               Entry.decode("external_operation_observed/v1", %{
                 "operation" => %{"id" => gid(:operation, 1), "state" => "vibing"},
                 "run" => %{"to" => "ready"}
               })
    end

    test "rejects a negative revision and a non-integer revision" do
      assert {:error, %{code: :invalid_payload, detail: %{field: "criteria_revision"}}} =
               Entry.decode("criteria_revised/v1", %{"criteria_revision" => -1})

      assert {:error, %{code: :invalid_payload, detail: %{field: "criteria_revision"}}} =
               Entry.decode("criteria_revised/v1", %{"criteria_revision" => "one"})
    end

    test "rejects a blank permitted response" do
      decision = Map.put(decision_payload(), "permitted_responses", [""])

      assert {:error,
              %{
                code: :invalid_payload,
                detail: %{field: "permitted_responses", reason: :empty_response}
              }} =
               Entry.decode("pending_decision_recorded/v1", %{"decision" => decision})
    end

    test "rejects an empty permitted-responses list" do
      decision = Map.put(decision_payload(), "permitted_responses", [])

      assert {:error, %{code: :invalid_payload, detail: %{field: "permitted_responses"}}} =
               Entry.decode("pending_decision_recorded/v1", %{"decision" => decision})
    end

    test "rejects a mixed permitted-responses list containing a blank" do
      decision = Map.put(decision_payload(), "permitted_responses", ["approve", ""])

      assert {:error,
              %{
                code: :invalid_payload,
                detail: %{field: "permitted_responses", reason: :empty_response}
              }} =
               Entry.decode("pending_decision_recorded/v1", %{"decision" => decision})
    end

    test "accepts non-empty permitted responses" do
      decision = Map.put(decision_payload(), "permitted_responses", ["approve", "deny"])
      assert {:ok, _} = Entry.decode("pending_decision_recorded/v1", %{"decision" => decision})
    end

    test "rejects a malformed permitted-responses list and unexpected null" do
      decision = %{
        "id" => gid(:decision, 1),
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
                 "decision_id" => gid(:decision, 1),
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
                 payload: %{"decision_id" => gid(:decision, 1), "response" => "approve"}
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
                 session_id: payload["session"]["id"]
               })
    end

    test "rejects an operation observation for the wrong current operation" do
      {:ok, projection} = Reducer.reduce(nil, started())

      {:ok, running} =
        Reducer.reduce(projection, %{
          type: "external_operation_intent_recorded/v1",
          payload: %{"operation" => %{"id" => gid(:operation, 1), "class" => "command_execution"}}
        })

      assert {:error, %{code: :operation_mismatch}} =
               Reducer.reduce(running, %{
                 type: "external_operation_observed/v1",
                 payload: %{
                   "operation" => %{"id" => gid(:operation, 2), "state" => "succeeded"},
                   "run" => %{"to" => "ready"}
                 }
               })
    end
  end

  defp decision_payload do
    %{
      "id" => gid(:decision, 1),
      "subject_kind" => "run",
      "subject_id" => "run_1",
      "subject_revision" => 0,
      "requested_actor" => "local_user",
      "permitted_responses" => ["approve"]
    }
  end

  defp session_started_payload do
    %{
      "session" => %{"id" => gid(:session, 1), "state" => "active"},
      "task" => %{"id" => gid(:task, 1), "state" => "in_progress"},
      "run" => %{"id" => gid(:run, 1), "state" => "ready", "root_run_id" => gid(:run, 1)},
      "workflow_step" => "intent",
      "objective" => "Build the feature",
      "criteria" => ["The feature works"],
      "constraints" => [],
      "exclusions" => [],
      "objective_revision" => 0,
      "criteria_revision" => 0,
      "references" => %{}
    }
  end

  defp started do
    %{type: "session_started/v1", payload: session_started_payload()}
  end

  defp gid(kind, byte) do
    {:ok, value} = Kiln.Domain.Id.generate(kind, fn 16 -> :binary.copy(<<byte>>, 16) end)
    value
  end
end
