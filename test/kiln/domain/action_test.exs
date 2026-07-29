defmodule Kiln.Domain.ActionTest do
  use ExUnit.Case, async: true

  alias Kiln.Domain.Action

  @now ~U[2026-07-29 13:30:00Z]
  @digest "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  test "constructs a revision-bound idempotent domain action" do
    assert {:ok, action} =
             Action.new(%{
               id: id("act", 1),
               session_id: id("ses", 2),
               run_id: id("run", 3),
               expected_session_revision: 4,
               idempotency_key: id("idem", 5),
               actor_kind: :local_user,
               actor_id: "user:local",
               kind: :transition_run,
               request_digest: @digest,
               payload: %{from: "ready", to: "running"},
               causation_action_id: nil,
               correlation_id: "request:1",
               requested_at: @now
             })

    assert action.expected_session_revision == 4
    assert action.actor_kind == :local_user
    assert action.kind == :transition_run
    assert action.payload == %{from: "ready", to: "running"}
  end

  test "rejects runtime handles and sensitive identity fields in payloads" do
    base = %{
      id: id("act", 1),
      session_id: id("ses", 2),
      run_id: id("run", 3),
      expected_session_revision: 0,
      idempotency_key: id("idem", 5),
      actor_kind: :system,
      actor_id: "kiln:workflow",
      kind: :record_operation_intent,
      request_digest: @digest,
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: @now
    }

    forbidden_payloads = [
      %{pid: "<0.1.0>"},
      %{process_id: 42},
      %{provider_request_id: "provider-1"},
      %{branch: "main"},
      %{worktree: "/tmp/worktree"},
      %{transcript: "complete transcript"},
      %{hidden_reasoning: "private reasoning"},
      %{artifact_payload: "large bytes"}
    ]

    for payload <- forbidden_payloads do
      assert {:error, %{code: :forbidden_payload_field}} = Action.new(Map.put(base, :payload, payload))
    end

    assert {:error, %{code: :invalid_payload}} = Action.new(Map.put(base, :payload, %{handle: self()}))
    assert {:error, %{code: :invalid_payload}} = Action.new(Map.put(base, :payload, %{tuple: {:runtime, 1}}))
  end

  test "rejects unsupported action kinds and stale revision shapes" do
    attrs = %{
      id: id("act", 1),
      session_id: id("ses", 2),
      run_id: nil,
      expected_session_revision: -1,
      idempotency_key: id("idem", 5),
      actor_kind: :system,
      actor_id: "kiln:workflow",
      kind: :deploy,
      request_digest: @digest,
      payload: %{},
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: @now
    }

    assert {:error, %{code: :invalid_revision}} = Action.new(attrs)
    assert {:error, %{code: :invalid_action_kind}} = Action.new(%{attrs | expected_session_revision: 0})
  end

  defp id(prefix, byte) do
    prefix <> "_" <> Base.encode16(:binary.copy(<<byte>>, 16), case: :lower)
  end
end
