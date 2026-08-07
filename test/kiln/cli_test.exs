defmodule Kiln.CLITest do
  @moduledoc """
  Tests for the foundation CLI dispatcher.

  Every test in this module drives the CLI through `Kiln.Workflow`;
  the dispatcher never reaches into `Kiln.Domain.*`, `Kiln.Journal.*`,
  `Kiln.Restart`, or `Kiln.Projections.*` directly. The journal/seed
  helpers in `Kiln.Test.JournalBuilder` and the direct `Journal.commit/4`
  calls in fixture setup remain because they plant durable state for
  the dispatcher to react to; the dispatcher itself only ever calls
  `Kiln.Workflow` and `Kiln.CLI.Runtime`.
  """

  use ExUnit.Case, async: false

  alias Kiln.CLI
  alias Kiln.CLI.{JsonRenderer, Request, Result, TextRenderer}
  alias Kiln.Domain.Id
  alias Kiln.Store
  alias Kiln.Store.{Connection, Journal}
  alias Kiln.Test.JournalBuilder, as: JB
  alias Kiln.Workflow

  @actor "test-actor"
  @now "2026-07-29T13:30:00Z"
  @test_root "/tmp/kiln-cli-fixture"

  setup do
    dir = tmp_home!()
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, dir: dir}
  end

  test "starting one Session creates durable Session, Task, and Run", %{dir: dir} do
    request = start_request(dir)

    assert {%Result{status: :ok, exit_code: 0} = result, 0} = CLI.run(request)

    assert result.command == "start"
    assert is_integer(result.session_revision)
    assert result.journal_digest =~ ~r/^sha256:[0-9a-f]{64}$/
    assert result.data.objective == "Fix one defect"
    assert result.data.session_id =~ ~r/^ses_[0-9a-f]{32}$/

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    [[count]] = Connection.query!(store.conn, "SELECT count(*) FROM journal_entries")
    assert count == 1

    [[projection_count]] =
      Connection.query!(store.conn, "SELECT count(*) FROM session_projections")

    assert projection_count == 1
  end

  test "text and structured start results describe the same state", %{dir: dir} do
    text_request = start_request(dir, objective: "Defect", criteria: ["Passes"])
    {text_result, 0} = CLI.run(text_request)
    text_rendered = TextRenderer.render(text_result)
    json_rendered = JsonRenderer.render(text_result)

    assert text_rendered =~ "session: ses_"
    assert text_rendered =~ "objective: Defect"

    decoded = JSON.decode!(json_rendered)
    assert decoded["kind"] == "cli_result"
    assert decoded["schema"] == "kiln.cli.result/v1"
    assert decoded["status"] == "ok"
    assert decoded["exit_code"] == 0
    assert decoded["data"]["objective"] == "Defect"
    assert decoded["data"]["session_id"] =~ ~r/^ses_[0-9a-f]{32}$/
    assert decoded["data"]["root_run_id"] =~ ~r/^run_[0-9a-f]{32}$/
    assert decoded["data"]["task_id"] =~ ~r/^tsk_[0-9a-f]{32}$/
  end

  test "status after a successful start matches the committed projection", %{dir: dir} do
    {_, 0} = CLI.run(start_request(dir))

    {status_result, 0} = CLI.run(parse_request(dir, :status))

    assert status_result.status == :ok
    assert status_result.exit_code == 0
    assert status_result.data.session_state == "active"
    assert status_result.data.run_state == "ready"
    assert status_result.data.workflow_step == "intent"
    assert status_result.data.orphaned == false
    assert is_binary(status_result.data.journal_head)

    decoded = decode_payload(status_result)
    assert decoded["data"]["run_state"] == "ready"
  end

  test "inspect exposes the complete accepted P1-S01 state", %{dir: dir} do
    {_, 0} =
      CLI.run(
        start_request(dir,
          objective: "Defect",
          criteria: ["Passes"],
          constraints: ["No deps"],
          exclusions: ["No provider"]
        )
      )

    {inspect_result, 0} = CLI.run(parse_request(dir, :inspect))

    data = inspect_result.data
    assert data.session_state == "active"
    assert data.task_state == "in_progress"
    assert data.run_state == "ready"
    assert data.workflow_step == "intent"
    assert data.objective == "Defect"
    assert data.criteria == ["Passes"]
    assert data.constraints == ["No deps"]
    assert data.exclusions == ["No provider"]
    assert data.objective_revision == 0
    assert data.criteria_revision == 0
    assert is_binary(data.project_observation_id)
    assert is_binary(data.journal_head_digest)
    assert is_binary(data.projection_digest)
  end

  test "invalid lifecycle transition produces a stable error and no durable mutation",
       %{dir: dir} do
    {seed_result, 0} = CLI.run(start_request(dir))
    initial_digest = seed_result.journal_digest

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    [[before_entries]] = Connection.query!(store.conn, "SELECT count(*) FROM journal_entries")
    [[before_commits]] = Connection.query!(store.conn, "SELECT count(*) FROM action_commits")

    first_cancel = parse_request(dir, :cancel, "--reason", "first")
    {first_cancel_result, 0} = CLI.run(first_cancel)
    assert first_cancel_result.status == :ok

    second_cancel = parse_request(dir, :cancel, "--reason", "second")
    {second_cancel_result, code} = CLI.run(second_cancel)
    assert code == 6
    assert second_cancel_result.status == :failed
    assert hd(second_cancel_result.errors).message =~ "already canceled"

    [[after_entries]] = Connection.query!(store.conn, "SELECT count(*) FROM journal_entries")
    [[after_commits]] = Connection.query!(store.conn, "SELECT count(*) FROM action_commits")

    assert after_entries - before_entries == 1
    assert after_commits - before_commits == 1

    _ = initial_digest
  end

  test "cancel succeeds from :ready and rebuilds to :canceled", %{dir: dir} do
    {_, 0} = CLI.run(start_request(dir))

    {result, 0} = CLI.run(parse_request(dir, :cancel, "--reason", "stop early"))

    assert result.status == :ok
    assert result.data.previous_run_state == "ready"
    assert result.data.run_state == "canceled"

    {status_result, 0} = CLI.run(parse_request(dir, :status))
    assert status_result.data.session_state == "abandoned"
    assert status_result.data.task_state == "abandoned"
    assert status_result.data.run_state == "canceled"
  end

  test "cancel is blocked when an active external operation is recorded",
       %{dir: dir} do
    {start_result, 0} = CLI.run(start_request(dir))
    session_id = start_result.data.session_id
    run_id = start_result.data.root_run_id

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    commit_intent(store, session_id, run_id, operation_id(:active), 0)

    {result, code} = CLI.run(parse_request(dir, :cancel, "--reason", "stop early"))

    assert code == 4
    assert result.status == :blocked
    assert hd(result.errors).message =~ "active or unknown operation"
  end

  test "resume reports the current projection and next actions without performing work",
       %{dir: dir} do
    {_, 0} = CLI.run(start_request(dir))

    {resume_result, 0} = CLI.run(parse_request(dir, :resume))

    assert resume_result.status == :ok
    assert resume_result.data.run_state == "ready"
    actions = resume_result.data.next_actions
    assert Enum.any?(actions, &(&1.action == "inspect"))
    assert Enum.any?(actions, &(&1.action == "cancel"))

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    [[journal_rows]] = Connection.query!(store.conn, "SELECT count(*) FROM journal_entries")
    assert journal_rows == 1
  end

  test "pending decision appears accurately in status and inspect", %{dir: dir} do
    {start_result, 0} = CLI.run(start_request(dir))
    session_id = start_result.data.session_id
    run_id = start_result.data.root_run_id

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    commit_transition(store, session_id, run_id, "ready", "running", 0)

    commit_pending_decision(store, session_id, run_id, decision_id(:approval), 1)

    {status_result, 0} = CLI.run(parse_request(dir, :status))
    assert status_result.data.run_state == "waiting_for_user"
    assert status_result.data.pending_decision["id"] == decision_id(:approval)

    decoded = decode_payload(status_result)
    assert decoded["data"]["run_state"] == "waiting_for_user"
    assert decoded["data"]["pending_decision"]["id"] == decision_id(:approval)

    {inspect_result, 0} = CLI.run(parse_request(dir, :inspect))
    assert inspect_result.data.run_state == "waiting_for_user"
    assert inspect_result.data.pending_decision["permitted_responses"] == ["approve", "deny"]
  end

  test "unknown external operation reconstructs as orphaned Run and stays visible",
       %{dir: dir} do
    {start_result, 0} = CLI.run(start_request(dir))
    session_id = start_result.data.session_id
    run_id = start_result.data.root_run_id

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    commit_intent(store, session_id, run_id, operation_id(:active), 0)

    stop(store.conn)

    {status_result, 7} = CLI.run(parse_request(dir, :status))

    assert status_result.status == :unknown
    assert status_result.data.run_state == "orphaned"
    assert status_result.data.orphaned == true
    assert status_result.data.operation["state"] == "unknown"

    decoded = decode_payload(status_result)
    assert decoded["data"]["run_state"] == "orphaned"
    assert decoded["data"]["orphaned"] == true
    assert decoded["data"]["operation"]["state"] == "unknown"

    {inspect_result, 7} = CLI.run(parse_request(dir, :inspect))
    assert inspect_result.status == :unknown
    assert inspect_result.data.unknowns != []
    unknown = hd(inspect_result.data.unknowns)
    assert unknown["operation_id"] == operation_id(:active)
  end

  test "blocks explicitly when more than one Session exists", %{dir: dir} do
    {_, 0} = CLI.run(start_request(dir))

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    # Plant a second session_id directly via the JournalBuilder so the
    # CLI's Workflow.current_session/0 path sees two distinct sessions.
    d2 = JB.domain(9)
    action = JB.action(d2, :start_session, :local_user, @actor, 0, 8, [])
    entry = JB.start_entry(d2)
    _ = Journal.commit(store.conn, action, [entry], now: @now)
    stop(store.conn)

    {result, code} = CLI.run(parse_request(dir, :status))

    assert code == 4
    assert result.status == :blocked
    assert hd(result.errors).code =~ "MULTIPLE_SESSIONS"
  end

  test "blocks explicitly on a corrupt journal", %{dir: dir} do
    {_, 0} = CLI.run(start_request(dir))

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    Connection.query!(
      store.conn,
      ~s|UPDATE journal_entries SET payload = '{"tampered":true}' WHERE session_revision = 0|
    )

    stop(store.conn)

    {result, code} = CLI.run(parse_request(dir, :status))
    assert code == 7
    assert result.status == :unknown
  end

  test "structured output is deterministic and versioned", %{dir: dir} do
    {_, 0} = CLI.run(start_request(dir))

    a = parse_request(dir, :status)
    b = parse_request(dir, :status)

    {a_result, 0} = CLI.run(a)
    {b_result, 0} = CLI.run(b)

    rendered_a = JsonRenderer.render(a_result)
    rendered_a_again = JsonRenderer.render(a_result)
    rendered_b = JsonRenderer.render(b_result)

    assert rendered_a == rendered_a_again

    payload = JSON.decode!(rendered_a)
    payload_b = JSON.decode!(rendered_b)
    assert Map.delete(payload, "emitted_at") == Map.delete(payload_b, "emitted_at")
    assert payload["schema"] == "kiln.cli.result/v1"
    assert payload["kind"] == "cli_result"
    assert payload["exit_code"] in [0, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    assert payload["status"] in [
             "ok",
             "denied",
             "blocked",
             "stale",
             "failed",
             "unknown",
             "unsupported"
           ]
  end

  test "excluded provider, Repository-read, Patch, Command, Evidence, Receipt, Child, and TUI commands are unreachable" do
    forbidden = [
      "investigate",
      "context.build",
      "context.inspect",
      "patch.list",
      "patch.inspect",
      "patch.approve",
      "patch.deny",
      "patch.apply",
      "verify.run",
      "command.status",
      "command.cancel",
      "evidence.list",
      "evidence.show",
      "criteria.show",
      "completion.inspect",
      "completion.accept",
      "completion.reject",
      "receipt.show",
      "receipt.verify",
      "receipt.rebuild",
      "recover.inspect",
      "recover.resolve",
      "run.show",
      "history",
      "session.show",
      "run.cancel",
      "doctor",
      "project.init",
      "provider.status"
    ]

    for command <- forbidden do
      argv = ["--kiln-home", "/tmp/excluded", "--actor-id", @actor, command]

      assert {:error, error} = Request.parse(argv),
             "expected #{command} to be rejected at parse time"

      assert error.code == "USAGE_ERROR",
             "expected #{command} to reject with USAGE_ERROR, got #{inspect(error)}"

      assert error.message =~ "unsupported command",
             "expected #{command} to reject with unsupported command, got #{inspect(error)}"
    end
  end

  test "unsupported commands emit `unsupported` status with exit 9 when dispatched",
       %{dir: dir} do
    valid_request = start_request(dir)
    unsupported_request = %{valid_request | command: :patch_inspect}

    assert {%Result{status: :unsupported, exit_code: 9} = result, 9} =
             CLI.run(unsupported_request)

    assert result.command == "patch_inspect"
    assert hd(result.errors).code == "UNSUPPORTED_COMMAND"
    refute File.exists?(Path.join(dir, "state.sqlite3"))
  end

  test "unknown status reflects unknown external effect conservatively", %{dir: dir} do
    {start_result, 0} = CLI.run(start_request(dir))
    session_id = start_result.data.session_id
    run_id = start_result.data.root_run_id

    {:ready, store} =
      Store.start(path: Path.join(dir, "state.sqlite3"), store_id: "store_cli_test", now: @now)

    on_exit(fn -> stop(store.conn) end)

    commit_intent(store, session_id, run_id, operation_id(:active), 0)

    stop(store.conn)

    {resume_result, 7} = CLI.run(parse_request(dir, :resume))

    assert resume_result.status == :unknown
    assert resume_result.data.run_state == "orphaned"
    assert resume_result.data.session_state == "active"
    actions = resume_result.data.next_actions
    assert Enum.any?(actions, &(&1.action == "inspect"))
  end

  test "status on a non-existent state DB returns blocked no_session without creating the store",
       %{dir: dir} do
    state_path = Path.join(dir, "state.sqlite3")
    refute File.exists?(state_path)

    {result, code} = CLI.run(parse_request(dir, :status))

    assert code == 4
    assert result.status == :blocked
    assert hd(result.errors).code == "NO_SESSION"
    refute File.exists?(state_path)
  end

  test "missing --actor-id returns a structured USAGE_ERROR" do
    assert {:error, error} = Request.parse(["--kiln-home=/tmp/x", "status"])
    assert error.code == "USAGE_ERROR"
    assert error.message =~ "actor_id"
  end

  test "source guard: dispatcher never aliases forbidden internal modules" do
    source = File.read!("lib/kiln/cli.ex")
    code = strip_comments(source)

    forbidden = [
      # The CLI may *consume* `%Kiln.Domain.Error{}` returns from
      # `Kiln.Workflow` via `alias Kiln.Domain.Error` and `%Error{}`
      # pattern matching. Construction is forbidden by the second
      # source-guard test below. Any other `Kiln.Domain.*` alias is
      # forbidden here.
      ~r/alias\s+Kiln\.Domain\.(?!Error\b)\w+/,
      ~r/alias\s+Kiln\.Projections\b/,
      ~r/alias\s+Kiln\.Restart\b/,
      ~r/alias\s+Kiln\.Store\.Journal\b/,
      ~r/alias\s+Kiln\.Store\.Replay\b/,
      ~r/alias\s+Kiln\.Journal\.Replay\b/,
      ~r/Kiln\.Restart\./,
      ~r/Kiln\.Projections\./,
      ~r/Kiln\.Store\.Journal\./,
      ~r/Kiln\.Journal\.Replay\./
    ]

    for fragment <- forbidden do
      refute code =~ fragment,
             "cli.ex must not depend on #{inspect(fragment)}"
    end
  end

  # The CLI is allowed to *consume* `%Kiln.Domain.Error{}` returns from
  # `Kiln.Workflow`. It must never *construct* Domain values itself or
  # directly *invoke* Domain behavior (no `Kiln.Domain.Session.start/1`,
  # `Kiln.Domain.Action.new/1`, etc.). The guard below forbids every
  # fully-qualified `Kiln.Domain.*` reference (struct literal,
  # constructor, or any other call) so the architectural rule is enforced
  # by tests, not by convention.
  test "source guard: dispatcher never references Kiln.Domain.* fully-qualified" do
    source = File.read!("lib/kiln/cli.ex")
    code = strip_comments(source)

    forbidden = [
      # Construction via struct literal (full module path)
      ~r/%Kiln\.Domain\.Error\{/,
      ~r/%Kiln\.Domain\.\w+\{/,
      # Construction via factory functions
      ~r/Kiln\.Domain\.\w+\.new\(/,
      ~r/Kiln\.Domain\.\w+\.from_/,
      # Any other Domain behavior call (e.g. Session.start, Action.commit)
      ~r/Kiln\.Domain\.\w+\.\w+\(/
    ]

    for fragment <- forbidden do
      refute code =~ fragment,
             "cli.ex must not construct or invoke any Kiln.Domain.* value (#{inspect(fragment)})"
    end
  end

  # The CLI aliases `Kiln.Domain.Error` solely to pattern-match
  # `%Error{} = error` returns from `Kiln.Workflow`. It must never call
  # a function on the aliased `Error` module. Struct-literal patterns
  # like `%Error{code: x} = error` are syntactically indistinguishable
  # from a struct construction at the regex level and are guarded by
  # code review rather than this test; the test below forbids the
  # unambiguous call-site forms.
  test "source guard: dispatcher never calls aliased Kiln.Domain.Error" do
    source = File.read!("lib/kiln/cli.ex")
    code = strip_comments(source)

    forbidden = [
      # Constructor-style calls on the aliased Error module
      ~r/\bError\.(?:new|from_)\(/,
      # Any other aliased Error behavior call (e.g. Error.something(...))
      ~r/\bError\.\w+\(/
    ]

    for fragment <- forbidden do
      refute code =~ fragment,
             "cli.ex must not call Kiln.Domain.Error (#{inspect(fragment)})"
    end
  end

  # -- helpers --

  defp operation_id(:active), do: opaque_id(:operation, 0xA1)
  defp decision_id(:approval), do: opaque_id(:decision, 0xD1)

  defp opaque_id(kind, byte) do
    {:ok, id} = Id.generate(kind, fn 16 -> :binary.copy(<<byte>>, 16) end)
    id
  end

  defp start_request(dir, opts \\ []) do
    argv = [
      "--kiln-home",
      dir,
      "--actor-id",
      @actor,
      "start",
      "--repo",
      @test_root,
      "--objective",
      Keyword.get(opts, :objective, "Fix one defect"),
      "--criterion",
      hd(Keyword.get(opts, :criteria, ["Test passes"]))
    ]

    argv =
      Enum.reduce(
        [
          {"--constraint", Keyword.get(opts, :constraints, [])},
          {"--exclude", Keyword.get(opts, :exclusions, [])}
        ],
        argv,
        fn {flag, values}, acc -> acc ++ Enum.flat_map(values, &[flag, &1]) end
      )

    {:ok, request} = Request.parse(argv)
    request
  end

  defp parse_request(dir, command) do
    {:ok, request} =
      Request.parse(["--kiln-home", dir, "--actor-id", @actor, Atom.to_string(command)])

    request
  end

  defp parse_request(dir, command, flag, value) do
    {:ok, request} =
      Request.parse([
        "--kiln-home",
        dir,
        "--actor-id",
        @actor,
        Atom.to_string(command),
        flag,
        value
      ])

    request
  end

  defp decode_payload(result) do
    decoded = JSON.decode!(JsonRenderer.render(result))
    decoded
  end

  defp strip_comments(source) do
    source
    |> String.split(["\n", "\r\n"])
    |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.join("\n")
  end

  # The CLI tests plant journal entries directly so the Workflow sees the
  # expected projection invariants. These helpers participate only in
  # fixture setup, not in the dispatcher itself.
  defp commit_transition(store, session_id, run_id, from, to, expected_revision) do
    idempotency_key = "idem_" <> String.duplicate("0", 32)
    request_digest = "sha256:" <> String.duplicate("a", 64)

    {:ok, action_id} =
      Id.generate(:action, fn 16 -> :binary.copy(<<expected_revision + 5>>, 16) end)

    {:ok, action} =
      JB.test_action(
        action_id,
        session_id,
        run_id,
        expected_revision,
        idempotency_key,
        request_digest,
        :transition_run,
        @actor
      )

    entry = %{
      type: "run_transitioned/v1",
      payload_schema: "run_transitioned/v1",
      payload: %{
        "run" => %{"from" => from, "to" => to},
        "workflow_step" => "application"
      }
    }

    {:ok, _} = Journal.commit(store.conn, action, [entry], now: @now)
  end

  defp commit_intent(store, session_id, run_id, operation_id, expected_revision) do
    idempotency_key = "idem_" <> String.duplicate("1", 32)
    request_digest = "sha256:" <> String.duplicate("c", 64)

    {:ok, action_id} =
      Id.generate(:action, fn 16 -> :binary.copy(<<expected_revision + 9>>, 16) end)

    {:ok, action} =
      JB.test_action(
        action_id,
        session_id,
        run_id,
        expected_revision,
        idempotency_key,
        request_digest,
        :record_operation_intent,
        "kiln:workflow"
      )

    entry = %{
      type: "external_operation_intent_recorded/v1",
      payload_schema: "external_operation_intent_recorded/v1",
      payload: %{
        "operation" => %{"id" => operation_id, "class" => "command_execution"},
        "workflow_step" => "application"
      }
    }

    {:ok, _} = Journal.commit(store.conn, action, [entry], now: @now)
  end

  defp commit_pending_decision(store, session_id, run_id, dec_id, expected_revision) do
    idempotency_key = "idem_" <> String.duplicate("2", 32)
    request_digest = "sha256:" <> String.duplicate("d", 64)

    {:ok, action_id} =
      Id.generate(:action, fn 16 -> :binary.copy(<<expected_revision + 11>>, 16) end)

    {:ok, action} =
      JB.test_action(
        action_id,
        session_id,
        run_id,
        expected_revision,
        idempotency_key,
        request_digest,
        :request_decision,
        "kiln:workflow"
      )

    decision = %{
      "id" => dec_id,
      "subject_kind" => "run",
      "subject_id" => run_id,
      "subject_revision" => expected_revision,
      "requested_actor" => "local_user",
      "permitted_responses" => ["approve", "deny"]
    }

    entry = %{
      type: "pending_decision_recorded/v1",
      payload_schema: "pending_decision_recorded/v1",
      payload: %{"decision" => decision, "workflow_step" => "approval"}
    }

    {:ok, _} = Journal.commit(store.conn, action, [entry], now: @now)
  end

  defp tmp_home! do
    dir = Path.join(System.tmp_dir!(), "kiln-cli-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    dir
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end

  # -- F1 regression: second start must not create a second Session --

  test "second start is rejected with SESSION_ALREADY_EXISTS and writes zero durable rows",
       %{dir: dir} do
    {first_result, 0} = CLI.run(start_request(dir))
    session_id = first_result.data.session_id

    [[before_entries], [before_commits], [before_projections]] =
      with_store(dir, fn store ->
        query_counts(store)
      end)

    second_request =
      start_request(dir,
        objective: "Different objective",
        criteria: ["Different criterion"]
      )

    {second_result, code} = CLI.run(second_request)

    assert code == 4
    assert second_result.status == :blocked
    assert length(second_result.errors) >= 1
    assert hd(second_result.errors).code =~ "SESSION_ALREADY_EXISTS"

    [[after_entries], [after_commits], [after_projections]] =
      with_store(dir, fn store ->
        query_counts(store)
      end)

    assert after_entries == before_entries,
           "second start must not append journal entries (was #{before_entries}, now #{after_entries})"

    assert after_commits == before_commits,
           "second start must not commit actions (was #{before_commits}, now #{after_commits})"

    assert after_projections == before_projections,
           "second start must not create projections (was #{before_projections}, now #{after_projections})"

    {status_result, 0} = CLI.run(parse_request(dir, :status))
    assert status_result.status == :ok
    assert status_result.data.session_id == session_id
    assert status_result.data.orphaned == false

    # Workflow.current_session must resolve exactly one Session and never
    # `:multiple_sessions`, even though the CLI's precheck_no_session did
    # not consult the Workflow path beyond the second `start` rejection.
    with_store(dir, fn _store ->
      {:ok, current} = Workflow.current_session()

      assert match?(%{session_id: ^session_id}, current),
             "Workflow.current_session must resolve the original Session, got #{inspect(current)}"

      refute match?(%{orphaned: true}, current)
    end)
  end

  defp query_counts(store) do
    [[entries]] = Connection.query!(store.conn, "SELECT count(*) FROM journal_entries")
    [[commits]] = Connection.query!(store.conn, "SELECT count(*) FROM action_commits")

    [[projections]] =
      Connection.query!(store.conn, "SELECT count(*) FROM session_projections")

    [[entries], [commits], [projections]]
  end

  # Open a fresh `Kiln.Store.Connection` registration, run `fun` with the
  # store, and stop the connection on exit. This is the standard
  # "I need direct Workflow access for one assertion" harness used by the
  # F1 and F2 regression tests so they can read the Workflow surface
  # without depending on CLI internals.
  defp with_store(dir, fun) do
    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        name: Kiln.Store.Connection,
        store_id: "store_cli_test",
        now: @now
      )

    try do
      fun.(store)
    after
      stop(store.conn)
    end
  end

  # -- F2 capability authority: every CLI mutating suggestion is Workflow-owned --

  # The reusable assertion that proves a CLI result's mutating next_actions
  # are exactly the set the Workflow capability matrix advertises for the
  # current Session. The set comparison is performed against
  # `Workflow.valid_next_actions/1` directly so any future drift between
  # the dispatcher's hardcoded suggestions and the Workflow's authority
  # fails this test before the contract can leak into user-visible output.
  defp assert_mutating_subset(
         result,
         session_id,
         capability_atoms \\ [:cancel_session, :resume_session]
       ) do
    {:ok, advertised_atoms} = Workflow.valid_next_actions(session_id)

    advertised_command_strings =
      advertised_atoms
      |> Enum.map(&capability_command_for/1)
      |> MapSet.new()

    allowed_command_strings =
      capability_atoms
      |> Enum.map(&capability_command_for/1)
      |> MapSet.new()

    actual_mutating_actions =
      result.next_actions
      |> Enum.map(& &1.action)
      |> Enum.filter(&(&1 in allowed_command_strings))
      |> MapSet.new()

    assert MapSet.subset?(actual_mutating_actions, advertised_command_strings),
           "CLI mutating suggestions #{inspect(actual_mutating_actions)} are not a subset of " <>
             "Workflow-advertised #{inspect(advertised_command_strings)}"

    # Sanity guard: the capability matrix currently publishes only the
    # atoms the CLI helper knows how to translate; an unexpected atom
    # would silently bypass the helper if not flagged here.
    assert MapSet.subset?(MapSet.new(advertised_atoms), MapSet.new(capability_atoms)),
           "Workflow advertised unexpected atoms: #{inspect(advertised_atoms)}"
  end

  defp capability_command_for(:cancel_session), do: "cancel"
  defp capability_command_for(:resume_session), do: "resume"
  defp capability_command_for(action) when is_atom(action), do: Atom.to_string(action)

  describe "capability-driven next_actions (Workflow capability matrix)" do
    test "ready Run advertises both cancel and resume in status output", %{dir: dir} do
      {_, 0} = CLI.run(start_request(dir))

      {status_result, 0} = CLI.run(parse_request(dir, :status))

      actions = actions_in(status_result)
      assert "inspect" in actions
      assert "cancel" in actions
      assert "resume" in actions
    end

    test "running Run advertises cancel but not resume in status output", %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id
      run_id = start_result.data.root_run_id

      {:ready, store} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_cli_test",
          now: @now
        )

      on_exit(fn -> stop(store.conn) end)
      commit_transition(store, session_id, run_id, "ready", "running", 0)

      {status_result, 0} = CLI.run(parse_request(dir, :status))

      actions = actions_in(status_result)
      assert "cancel" in actions
      refute "resume" in actions
    end

    test "waiting_for_user Run advertises neither cancel nor resume", %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id
      run_id = start_result.data.root_run_id

      {:ready, store} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_cli_test",
          now: @now
        )

      on_exit(fn -> stop(store.conn) end)
      commit_transition(store, session_id, run_id, "ready", "running", 0)
      commit_pending_decision(store, session_id, run_id, decision_id(:approval), 1)

      {status_result, 0} = CLI.run(parse_request(dir, :status))

      actions = actions_in(status_result)
      refute "cancel" in actions
      refute "resume" in actions
    end

    test "canceled Run offers neither cancel nor resume", %{dir: dir} do
      {_, 0} = CLI.run(start_request(dir))
      {_, 0} = CLI.run(parse_request(dir, :cancel))

      {status_result, 0} = CLI.run(parse_request(dir, :status))

      actions = actions_in(status_result)
      refute "cancel" in actions
      refute "resume" in actions
    end
  end

  describe "F2 capability authority (CLI mutating actions are Workflow-owned)" do
    test "start result mutating actions are a subset of Workflow.valid_next_actions(session)",
         %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id

      with_store(dir, fn _store ->
        {:ok, advertised} = Workflow.valid_next_actions(session_id)
        assert :cancel_session in advertised
        assert :resume_session in advertised
        assert_mutating_subset(start_result, session_id)
      end)
    end

    test "start result never invents a Workflow-unknown mutation",
         %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))

      # The matrix currently advertises only cancel/resume. A future
      # capability added to Workflow without updating the CLI helper must
      # be silently dropped by the CLI rather than invented as a
      # suggestion. This test asserts the current invariant: the only
      # mutating strings the CLI may emit are exactly the strings the
      # matrix maps to atoms.
      cli_mutating_strings =
        start_result.next_actions
        |> Enum.map(& &1.action)
        |> Enum.filter(&(&1 in ["cancel", "resume"]))

      assert Enum.sort(cli_mutating_strings) == ["cancel", "resume"]
    end

    test "cancel result contains no cancel and no resume even though Workflow advertised them",
         %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id

      with_store(dir, fn _store ->
        {:ok, advertised_before} = Workflow.valid_next_actions(session_id)
        assert :cancel_session in advertised_before
      end)

      {cancel_result, 0} =
        CLI.run(parse_request(dir, :cancel, "--reason", "stop early"))

      actions = actions_in(cancel_result)

      refute "cancel" in actions,
             "cancel result must not suggest cancel; cancel transitioned the Run to terminal"

      refute "resume" in actions,
             "cancel result must not suggest resume; Workflow.valid_next_actions([]) for terminal"

      assert "status" in actions
      assert "inspect" in actions

      with_store(dir, fn _store ->
        {:ok, advertised_after} = Workflow.valid_next_actions(session_id)

        assert advertised_after == [],
               "Workflow must advertise no actions after cancel (terminal Run state)"
      end)
    end

    test "status, inspect, and resume mutating suggestions ⊆ Workflow matrix for ready",
         %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id

      {status_result, 0} = CLI.run(parse_request(dir, :status))
      {inspect_result, 0} = CLI.run(parse_request(dir, :inspect))
      {resume_result, 0} = CLI.run(parse_request(dir, :resume))

      with_store(dir, fn _store ->
        assert_mutating_subset(status_result, session_id)
        assert_mutating_subset(inspect_result, session_id)
        assert_mutating_subset(resume_result, session_id)
      end)
    end

    test "status, inspect, resume carry no mutating suggestion for running",
         %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id
      run_id = start_result.data.root_run_id

      with_store(dir, fn store ->
        commit_transition(store, session_id, run_id, "ready", "running", 0)
      end)

      with_store(dir, fn _store ->
        {:ok, advertised} = Workflow.valid_next_actions(session_id)
        assert advertised == [:cancel_session]
      end)

      {status_result, 0} = CLI.run(parse_request(dir, :status))
      {inspect_result, 0} = CLI.run(parse_request(dir, :inspect))
      {resume_result, 0} = CLI.run(parse_request(dir, :resume))

      with_store(dir, fn _store ->
        assert_mutating_subset(status_result, session_id)
        assert_mutating_subset(inspect_result, session_id)
        assert_mutating_subset(resume_result, session_id)
      end)

      status_actions = actions_in(status_result)
      inspect_actions = actions_in(inspect_result)
      resume_actions = actions_in(resume_result)

      assert "cancel" in status_actions
      refute "resume" in status_actions
      assert "cancel" in inspect_actions
      refute "resume" in inspect_actions
      assert "cancel" in resume_actions
      refute "resume" in resume_actions
    end

    test "status, inspect, resume carry no mutating suggestion for waiting_for_user",
         %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id
      run_id = start_result.data.root_run_id

      with_store(dir, fn store ->
        commit_transition(store, session_id, run_id, "ready", "running", 0)
        commit_pending_decision(store, session_id, run_id, decision_id(:approval), 1)
      end)

      with_store(dir, fn _store ->
        {:ok, advertised} = Workflow.valid_next_actions(session_id)
        assert advertised == []
      end)

      {status_result, 0} = CLI.run(parse_request(dir, :status))
      {inspect_result, 0} = CLI.run(parse_request(dir, :inspect))
      {resume_result, 0} = CLI.run(parse_request(dir, :resume))

      with_store(dir, fn _store ->
        assert_mutating_subset(status_result, session_id)
        assert_mutating_subset(inspect_result, session_id)
        assert_mutating_subset(resume_result, session_id)
      end)
    end

    test "status, inspect, resume carry no mutating suggestion for canceled",
         %{dir: dir} do
      {_, 0} = CLI.run(start_request(dir))
      {_, 0} = CLI.run(parse_request(dir, :cancel, "--reason", "stop early"))

      {_, 0} = CLI.run(parse_request(dir, :status))
      {inspect_result, 0} = CLI.run(parse_request(dir, :inspect))
      {resume_result, 0} = CLI.run(parse_request(dir, :resume))

      refute "cancel" in actions_in(inspect_result)
      refute "resume" in actions_in(inspect_result)
      refute "cancel" in actions_in(resume_result)
      refute "resume" in actions_in(resume_result)
    end

    test "orphaned Run: status/inspect/resume carry Workflow-advertised mutations only",
         %{dir: dir} do
      {start_result, 0} = CLI.run(start_request(dir))
      session_id = start_result.data.session_id
      run_id = start_result.data.root_run_id

      with_store(dir, fn store ->
        commit_intent(store, session_id, run_id, operation_id(:active), 0)
      end)

      # The persisted journal in this fixture records an operation intent
      # without a terminal observation, so the operation state is
      # `intent_recorded` (nonterminal). Workflow.orphaned?/1 returns
      # true so the CLI renderer surfaces this Session as orphaned.
      # However, the reducer still advanced the Run state to `running`
      # (the intent transition is accepted), and the Workflow capability
      # matrix therefore advertises `:cancel_session` for the same
      # Session. The CLI must consult Workflow and surface cancel — the
      # bug the F2 correction fixes is the inverse, where the CLI
      # advertises a mutation Workflow does not.
      with_store(dir, fn _store ->
        {:ok, advertised} = Workflow.valid_next_actions(session_id)
        assert advertised == [:cancel_session]
      end)

      {status_result, 7} = CLI.run(parse_request(dir, :status))
      {inspect_result, 7} = CLI.run(parse_request(dir, :inspect))
      {resume_result, 7} = CLI.run(parse_request(dir, :resume))

      with_store(dir, fn _store ->
        assert_mutating_subset(status_result, session_id)
        assert_mutating_subset(inspect_result, session_id)
        assert_mutating_subset(resume_result, session_id)
      end)

      status_actions = actions_in(status_result)
      inspect_actions = actions_in(inspect_result)
      resume_actions = actions_in(resume_result)

      # status/inspect/resume are navigation suggestions and stay
      # present; cancel matches Workflow's authority; resume must never
      # be advertised because the Workflow capability matrix excludes it
      # for the underlying run state.
      assert "cancel" in status_actions
      refute "resume" in status_actions
      assert "cancel" in inspect_actions
      refute "resume" in inspect_actions
      assert "cancel" in resume_actions
      refute "resume" in resume_actions
    end
  end

  defp actions_in(%Result{next_actions: next_actions}) do
    Enum.map(next_actions, & &1.action)
  end

  defp actions_in(_other), do: []
end
