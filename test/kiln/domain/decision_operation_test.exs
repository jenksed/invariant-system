defmodule Kiln.Domain.DecisionOperationTest do
  use ExUnit.Case, async: true

  alias Kiln.Domain.{Decision, Operation}

  @now ~U[2026-07-29 13:30:00Z]
  @later ~U[2026-07-29 13:31:00Z]
  @digest "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  test "constructs one exact local-user decision" do
    assert {:ok, decision} =
             Decision.new(%{
               id: id("dec", 1),
               session_id: id("ses", 2),
               run_id: id("run", 3),
               subject_kind: :operation,
               subject_id: id("opn", 4),
               subject_revision: 7,
               requested_actor: :local_user,
               permitted_responses: [:approve, :deny],
               resume_action: :answer_decision,
               requested_at: @now
             })

    assert decision.requested_actor == :local_user
    assert decision.permitted_responses == [:approve, :deny]
    assert decision.subject_revision == 7
  end

  test "rejects model authority and duplicate responses" do
    attrs = %{
      id: id("dec", 1),
      session_id: id("ses", 2),
      run_id: id("run", 3),
      subject_kind: :run,
      subject_id: id("run", 3),
      subject_revision: 0,
      requested_actor: :model,
      permitted_responses: [:continue, :continue],
      resume_action: :answer_decision,
      requested_at: @now
    }

    assert {:error, %{code: :invalid_actor}} = Decision.new(attrs)
    assert {:error, %{code: :invalid_responses}} = Decision.new(%{attrs | requested_actor: :local_user})
  end

  test "records intent and terminal observation without dispatching an effect" do
    assert {:ok, operation} =
             Operation.intent(%{
               id: id("opn", 1),
               session_id: id("ses", 2),
               run_id: id("run", 3),
               class: :command_execution,
               subject_id: "command:test",
               subject_revision: 4,
               idempotency_key: id("idem", 5),
               request_digest: @digest,
               recorded_at: @now
             })

    assert operation.state == :intent_recorded
    assert operation.observed_at == nil

    assert {:ok, started} = Operation.observe(operation, :started, %{observed_at: @later})
    assert started.state == :started

    assert {:ok, failed} =
             Operation.observe(started, :failed, %{
               observed_at: @later,
               result_reference: "artifact:command-result"
             })

    assert failed.state == :failed
    assert failed.result_reference == "artifact:command-result"

    assert {:error, %{code: :invalid_operation_transition}} =
             Operation.observe(failed, :succeeded, %{observed_at: @later})
  end

  test "limits external operation classes to the accepted first-month set" do
    attrs = %{
      id: id("opn", 1),
      session_id: id("ses", 2),
      run_id: id("run", 3),
      class: :deployment,
      subject_id: "deployment:1",
      subject_revision: 0,
      idempotency_key: id("idem", 5),
      request_digest: @digest,
      recorded_at: @now
    }

    assert {:error, %{code: :invalid_operation_class}} = Operation.intent(attrs)
    assert Operation.classes() == [:model_invocation, :patch_application, :command_execution]
  end

  defp id(prefix, byte) do
    prefix <> "_" <> Base.encode16(:binary.copy(<<byte>>, 16), case: :lower)
  end
end
