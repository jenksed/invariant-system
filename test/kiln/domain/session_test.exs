defmodule Kiln.Domain.SessionTest do
  use ExUnit.Case, async: true

  alias Kiln.Domain.{ProjectObservation, Session}

  @now ~U[2026-07-29 13:30:00Z]
  @digest "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  test "constructs one active Session, initial Task, and ready Root Run" do
    entropy_source = fn 16 -> :binary.copy(<<1>>, 16) end

    assert {:ok, project_observation} =
             ProjectObservation.new(
               %{
                 repository_root: "/tmp/kiln-fixture",
                 repository_fingerprint: @digest,
                 observed_at: @now
               },
               entropy_source
             )

    assert {:ok, %{session: session, task: task, run: run}} =
             Session.start(
               %{
                 project_observation: project_observation,
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 constraints: ["Do not change dependencies"],
                 exclusions: ["No provider access"],
                 started_at: @now
               },
               entropy_source: entropy_source
             )

    assert session.state == :active
    assert session.revision == 0
    assert session.criteria_revision == 0
    assert session.project_observation_id == project_observation.id

    assert task.state == :in_progress
    assert task.session_id == session.id
    assert task.statement == session.objective
    assert task.criteria == ["The focused test passes"]

    assert run.state == :ready
    assert run.workflow_step == :intent
    assert run.session_id == session.id
    assert run.task_id == task.id
    assert run.root_run_id == run.id

    assert session.initial_task_id == task.id
    assert session.root_run_id == run.id
    assert MapSet.size(MapSet.new([session.id, task.id, run.id])) == 3
    refute Map.has_key?(Map.from_struct(task), :root_task_id)
  end

  test "rejects incomplete accepted intent" do
    entropy_source = fn 16 -> :binary.copy(<<2>>, 16) end

    assert {:ok, project_observation} =
             ProjectObservation.new(
               %{
                 repository_root: "/tmp/kiln-fixture",
                 repository_fingerprint: @digest,
                 observed_at: @now
               },
               entropy_source
             )

    assert {:error, %{code: :invalid_field, field: :criteria}} =
             Session.start(
               %{
                 project_observation: project_observation,
                 objective: "Correct one bounded defect",
                 criteria: [],
                 started_at: @now
               },
               entropy_source: entropy_source
             )
  end
end
