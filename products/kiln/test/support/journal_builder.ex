defmodule Kiln.Test.JournalBuilder do
  @moduledoc """
  Deterministic journal construction for T03 replay, projection, and restart
  tests. Every action uses fixed identifiers, revisions, and timestamps so
  fixtures are byte-stable.
  """

  alias Kiln.Domain.{Action, Id, ProjectObservation, Session}
  alias Kiln.Store
  alias Kiln.Store.{Connection, Journal}

  @at ~U[2026-07-29 13:30:00Z]
  @now "2026-07-29T13:30:00Z"
  @fingerprint "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  @doc "Start a ready store at `path` with a fixed store id and clock."
  def store(path) do
    {:ready, store} = Store.start(path: path, store_id: "store_fixture", now: @now)
    store
  end

  @doc "Build the domain Session, Task, and Run with fixed entropy."
  def domain(byte \\ 1) do
    entropy = fn 16 -> :binary.copy(<<byte>>, 16) end
    {:ok, po} = ProjectObservation.new(observation(), entropy)

    {:ok, %{session: session, task: task, run: run}} =
      Session.start(intent(po), entropy_source: entropy)

    %{session: session, task: task, run: run}
  end

  @doc "Commit `session_started/v1` at revision 0."
  def commit_start(store, d, opts \\ []) do
    action = action(d, :start_session, :local_user, "user:local", 0, 2, opts)
    Journal.commit(store.conn, action, [start_entry(d)], now: @now)
  end

  @doc "Commit `run_transitioned/v1` from `from` to `to`."
  def commit_transition(store, d, from, to, expected, key_byte, step \\ "application") do
    action = action(d, :transition_run, :system, "kiln:workflow", expected, key_byte, [])

    entry =
      entry("run_transitioned/v1", %{
        "run" => %{"from" => from, "to" => to},
        "workflow_step" => step
      })

    Journal.commit(store.conn, action, [entry], now: @now)
  end

  @doc "Commit `criteria_revised/v1` with the new criteria list and revision."
  def commit_criteria(store, d, expected, key_byte, criteria_revision, criteria)
      when is_list(criteria) do
    action = action(d, :revise_intent, :local_user, "user:local", expected, key_byte, [])

    entry =
      entry("criteria_revised/v1", %{
        "criteria" => criteria,
        "criteria_revision" => criteria_revision
      })

    Journal.commit(store.conn, action, [entry], now: @now)
  end

  @doc "Commit `pending_decision_recorded/v1`, moving the Run to waiting_for_user."
  def commit_decision(store, d, expected, key_byte) do
    action = action(d, :request_decision, :system, "kiln:workflow", expected, key_byte, [])

    decision = %{
      "id" => id(:decision, 30),
      "subject_kind" => "run",
      "subject_id" => d.run.id,
      "subject_revision" => expected,
      "requested_actor" => "local_user",
      "permitted_responses" => ["approve", "deny"]
    }

    entry =
      entry("pending_decision_recorded/v1", %{
        "decision" => decision,
        "workflow_step" => "approval"
      })

    Journal.commit(store.conn, action, [entry], now: @now)
  end

  @doc "Commit `user_decision_recorded/v1`, clearing the decision and moving the Run to ready."
  def commit_answer(store, d, expected, key_byte) do
    action = action(d, :answer_decision, :local_user, "user:local", expected, key_byte, [])

    entry =
      entry("user_decision_recorded/v1", %{
        "decision_id" => id(:decision, 30),
        "response" => "approve",
        "workflow_step" => "intent"
      })

    Journal.commit(store.conn, action, [entry], now: @now)
  end

  @doc "Commit several entries as one accepted action (the multi-entry batch path)."
  def commit_entries(store, d, kind, expected, key_byte, entries) do
    action = action(d, kind, :system, "kiln:workflow", expected, key_byte, [])
    Journal.commit(store.conn, action, entries, now: @now)
  end

  @doc "Commit `external_operation_intent_recorded/v1`, moving the Run to running."
  def commit_operation_intent(store, d, expected, key_byte) do
    action = action(d, :record_operation_intent, :system, "kiln:workflow", expected, key_byte, [])

    operation = %{"id" => id(:operation, 40), "class" => "command_execution"}

    entry =
      entry("external_operation_intent_recorded/v1", %{
        "operation" => operation,
        "workflow_step" => "application"
      })

    Journal.commit(store.conn, action, [entry], now: @now)
  end

  @doc "Commit `external_operation_observed/v1` with a terminal state and Run target."
  def commit_operation_observe(store, d, expected, key_byte, state, run_to) do
    action = action(d, :observe_operation, :system, "kiln:workflow", expected, key_byte, [])

    entry =
      entry("external_operation_observed/v1", %{
        "operation" => %{"id" => id(:operation, 40), "state" => state},
        "run" => %{"to" => run_to},
        "workflow_step" => "intent"
      })

    Journal.commit(store.conn, action, [entry], now: @now)
  end

  @doc """
  Insert a fully specified journal row for crafted unsafe fixtures.

  `spec` requires `:session_id`, `:sequence`, `:revision`, `:type`, `:payload`,
  `:idempotency_key`, and `:request_digest`.
  """
  def insert_entry_row(conn, spec) do
    payload = spec.payload
    schema = spec.type

    Connection.query!(
      conn,
      """
      INSERT INTO journal_entries
        (sequence, entry_id, entry_schema, entry_type, payload_schema, session_id, session_revision,
         action_id, actor_kind, actor_id, idempotency_key, request_digest,
         causation_entry_id, correlation_id, recorded_at, payload, payload_digest)
      VALUES (?1, ?2, 'journal_entry/v1', ?3, ?4, ?5, ?6, ?7, 'system', 'kiln:workflow', ?8, ?9, NULL, NULL, ?10, ?11, ?12)
      """,
      [
        spec.sequence,
        Kiln.Store.Uuid.v7(),
        spec.type,
        schema,
        spec.session_id,
        spec.revision,
        Map.get(spec, :action_id, id(:action, 90 + spec.revision)),
        spec.idempotency_key,
        spec.request_digest,
        @now,
        Kiln.Store.Canonical.encode(payload),
        Kiln.Store.Canonical.digest(schema, payload)
      ]
    )
  end

  @doc "A two-entry batch: transition ready to running, then revise criteria."
  def two_entry_batch(revision) do
    [
      entry("run_transitioned/v1", %{
        "run" => %{"from" => "ready", "to" => "running"},
        "workflow_step" => "application"
      }),
      entry("criteria_revised/v1", %{
        "criteria" => ["The revised criterion passes"],
        "criteria_revision" => revision
      })
    ]
  end

  @doc "Insert an action_commit row for crafted fixtures."
  def insert_action_commit(conn, spec) do
    Connection.query!(
      conn,
      """
      INSERT INTO action_commits
        (action_id, session_id, idempotency_key, request_digest, expected_session_revision,
         first_sequence, last_sequence, result_schema, result, result_digest, committed_at)
      VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, 'action_result/v1', '{}', 'x', ?8)
      """,
      [
        spec.action_id,
        spec.session_id,
        spec.idempotency_key,
        spec.request_digest,
        spec.expected_session_revision,
        spec.first_sequence,
        spec.last_sequence,
        @now
      ]
    )
  end

  @doc "Insert a transcript record that must not affect the projection."
  def insert_transcript(conn, session_id, transcript_id, content) do
    Connection.query!(
      conn,
      "INSERT INTO transcript_records (transcript_id, session_id, recorded_at, content) VALUES (?1, ?2, ?3, ?4)",
      [transcript_id, session_id, @now, content]
    )
  end

  @doc "The `session_started/v1` entry payload for `d`."
  def start_entry(d) do
    entry("session_started/v1", %{
      "session" => %{"id" => d.session.id, "state" => "active"},
      "task" => %{"id" => d.task.id, "state" => "in_progress"},
      "run" => %{"id" => d.run.id, "state" => "ready", "root_run_id" => d.run.root_run_id},
      "workflow_step" => "intent",
      "objective" => d.session.objective,
      "criteria" => d.task.criteria,
      "constraints" => d.task.constraints,
      "exclusions" => d.task.exclusions,
      "objective_revision" => d.session.revision,
      "criteria_revision" => d.session.criteria_revision,
      "references" => %{"project_observation_id" => d.session.project_observation_id}
    })
  end

  @doc "Build a domain action with a fixed digest derived from `key_byte`."
  def action(d, kind, actor_kind, actor_id, expected, key_byte, opts) do
    {:ok, action} =
      Action.new(%{
        id: id(:action, 10 + key_byte),
        session_id: d.session.id,
        run_id: d.run.id,
        expected_session_revision: expected,
        idempotency_key: Keyword.get(opts, :key, id(:idempotency, key_byte)),
        actor_kind: actor_kind,
        actor_id: actor_id,
        kind: kind,
        request_digest: Keyword.get(opts, :digest, digest(key_byte)),
        payload: %{},
        causation_action_id: nil,
        correlation_id: nil,
        requested_at: @at
      })

    action
  end

  @doc "Build a domain action with explicit identifiers, used by tests that need to plant fixture state directly."
  def test_action(
        action_id,
        session_id,
        run_id,
        expected_revision,
        idempotency_key,
        request_digest,
        kind,
        actor_id
      ) do
    Action.new(%{
      id: action_id,
      session_id: session_id,
      run_id: run_id,
      expected_session_revision: expected_revision,
      idempotency_key: idempotency_key,
      actor_kind: :system,
      actor_id: actor_id,
      kind: kind,
      request_digest: request_digest,
      payload: %{},
      causation_action_id: nil,
      correlation_id: nil,
      requested_at: @at
    })
  end

  def entry(type, payload), do: %{type: type, payload_schema: type, payload: payload}

  def digest(byte) do
    "sha256:" <> Base.encode16(:binary.copy(<<byte>>, 32), case: :lower)
  end

  def id(kind, byte) do
    {:ok, value} = Id.generate(kind, fn 16 -> :binary.copy(<<byte>>, 16) end)
    value
  end

  defp observation do
    %{
      repository_root: "/tmp/kiln-fixture",
      repository_fingerprint: @fingerprint,
      observed_at: @at
    }
  end

  defp intent(po) do
    %{
      project_observation: po,
      objective: "Correct one bounded defect",
      criteria: ["The focused test passes"],
      constraints: ["Do not change dependencies"],
      exclusions: ["No provider access"],
      started_at: @at
    }
  end
end
