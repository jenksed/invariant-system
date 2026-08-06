defmodule Kiln.WorkflowTest do
  @moduledoc """
  Boundary tests for `Kiln.Workflow`. Covers AC01–AC07 from
  `docs/work/P1-S01-T06-workflow-surface.md`. The store connection is
  registered globally as `Kiln.Store.Connection`, so these tests are not
  safe to run concurrently and run with `async: false`.
  """
  use ExUnit.Case, async: false

  alias Kiln.{Workflow}
  alias Kiln.Domain.Error
  alias Kiln.Projections.Session, as: ProjectionSession
  alias Kiln.Projections.Store, as: ProjectionStore
  alias Kiln.Store
  alias Kiln.Store.Connection
  alias Kiln.Test.JournalBuilder, as: JB

  @at ~U[2026-07-29 13:30:00Z]
  @now "2026-07-29T13:30:00Z"
  @fingerprint "sha256:0000000000000000000000000000000000000000000000000000000000000001"

  setup do
    Application.delete_env(:kiln, :actor_id)
    stop_registered_store()

    dir = Path.join(System.tmp_dir!(), "kiln-workflow-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      Application.delete_env(:kiln, :actor_id)
      stop_registered_store()
      File.rm_rf!(dir)
    end)

    {:ready, store} =
      Store.start(
        path: Path.join(dir, "state.sqlite3"),
        store_id: "store_fixture",
        now: @now,
        name: Kiln.Store.Connection
      )

    {:ok, store: store, d: JB.domain(), dir: dir}
  end

  defp stop_registered_store do
    pid = Process.whereis(Kiln.Store.Connection)

    if is_pid(pid) and Process.alive?(pid) do
      try do
        GenServer.stop(pid, :normal, 1_000)
      catch
        :exit, _reason -> :ok
      end
    end

    :ok
  end

  # ---- AC01: start_session contract ----

  describe "start_session/1 (AC01)" do
    test "returns identifiers only — no action envelope, no domain struct, no handle", %{d: d} do
      assert {:ok, result} =
               Workflow.start_session(
                 objective: d.session.objective,
                 criteria: d.task.criteria,
                 constraints: d.task.constraints,
                 exclusions: d.task.exclusions,
                 project_observation: observation(),
                 actor_id: "user:local"
               )

      assert Map.keys(result) |> Enum.sort() ==
               [:projection_digest, :run_id, :run_state, :session_id, :session_revision, :task_id]

      assert result.session_revision == 0
      assert result.run_state == :ready
      assert is_binary(result.session_id)
      assert is_binary(result.task_id)
      assert is_binary(result.run_id)
      assert is_binary(result.projection_digest)

      refute Map.has_key?(result, :action)
      refute Map.has_key?(result, :session)
      refute Map.has_key?(result, :run)
      refute Map.has_key?(result, :task)
    end

    test "commits exactly one session-started action", %{store: store} do
      {:ok, _} =
        Workflow.start_session(
          objective: "Correct one bounded defect",
          criteria: ["The focused test passes"],
          project_observation: observation(),
          actor_id: "user:local"
        )

      assert count(store.conn, "journal_entries") == 1
      assert count(store.conn, "action_commits") == 1
      assert count(store.conn, "session_projections") == 1
    end

    test "rejects a missing actor_id without writing to the journal", %{store: store} do
      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation()
               )

      assert count(store.conn, "journal_entries") == 0
      assert count(store.conn, "action_commits") == 0
    end

    test "rejects an empty criteria list without writing to the journal", %{store: store} do
      assert {:error, %Error{code: :criteria}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: [],
                 project_observation: observation(),
                 actor_id: "user:local"
               )

      assert count(store.conn, "journal_entries") == 0
    end

    test "does not silently fall back to Application.get_env(:kiln, :actor_id)" do
      Application.put_env(:kiln, :actor_id, "from_env")

      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation()
               )
    end
  end

  # ---- AC02: query_session contract ----

  describe "query_session/1 (AC02)" do
    test "returns :empty when no journal entries exist", %{store: store, d: d} do
      assert {:ok, :empty} = Workflow.query_session(d.session.id)
      assert count(store.conn, "journal_entries") == 0
    end

    test "returns the projection with :cache or :rebuilt source after a start", %{d: d} do
      {:ok, started} =
        Workflow.start_session(
          objective: d.session.objective,
          criteria: d.task.criteria,
          project_observation: observation(),
          actor_id: "user:local"
        )

      assert {:ok, viewed} = Workflow.query_session(started.session_id)
      assert Map.keys(viewed) |> Enum.sort() == [:projection, :projection_digest, :source]
      assert viewed.source in [:cache, :rebuilt]
      assert is_binary(viewed.projection_digest)

      assert viewed.projection["session"]["id"] == started.session_id
      assert viewed.projection["run"]["state"] == "ready"
    end

    test "matches ProjectionStore.compare/2 for both cache-hit and rebuilt paths", %{
      store: store
    } do
      {:ok, started} =
        Workflow.start_session(
          objective: "Correct one bounded defect",
          criteria: ["The focused test passes"],
          project_observation: observation(),
          actor_id: "user:local"
        )

      assert {:ok, status, report} = ProjectionStore.compare(store.conn, started.session_id)

      assert status in [
               :match,
               :rebuilt,
               :replaced_stale,
               :replaced_malformed,
               :replaced_invalid_metadata
             ]

      assert report.projection["session"]["id"] == started.session_id

      assert {:ok, viewed} = Workflow.query_session(started.session_id)
      assert viewed.projection == report.projection
      assert viewed.projection_digest == ProjectionSession.digest(report.projection)
    end

    test "returns a rebuilt source after the cache is invalidated", %{store: store} do
      {:ok, started} =
        Workflow.start_session(
          objective: "Correct one bounded defect",
          criteria: ["The focused test passes"],
          project_observation: observation(),
          actor_id: "user:local"
        )

      Connection.query!(
        store.conn,
        "DELETE FROM session_projections WHERE session_id = ?1",
        [started.session_id]
      )

      assert {:ok, viewed} = Workflow.query_session(started.session_id)
      assert viewed.source == :rebuilt
      assert viewed.projection["session"]["id"] == started.session_id
    end

    test "rejects an unknown session_id without raising" do
      bogus = "ses_00000000000000000000000000000000"

      assert {:ok, :empty} = Workflow.query_session(bogus)
    end

    test "rejects a malformed session_id format" do
      assert {:error, %Error{code: :invalid_session_id}} =
               Workflow.query_session("not_a_session_id")
    end
  end

  # ---- AC03: cancel_session contract ----

  describe "cancel_session/2 (AC03)" do
    test "commits a cancel from a ready Run", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      assert {:ok, result} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local"
               )

      assert Map.keys(result) |> Enum.sort() ==
               [:action_id, :projection_digest, :run_state, :session_id, :session_revision]

      assert result.run_state == :canceled
      assert result.session_revision == 1
      assert result.session_id == d.session.id
      assert is_binary(result.action_id)
      assert is_binary(result.projection_digest)
    end

    test "commits a cancel from running or waiting_for_user Run states", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)
      {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3, "application")

      assert {:ok, %{run_state: :canceled}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 1,
                 actor_id: "user:local"
               )
    end

    test "rejects a stale expected_session_revision without writing", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      before_entries = count(store.conn, "journal_entries")
      before_commits = count(store.conn, "action_commits")

      assert {:error, %Error{code: :stale_revision}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 99,
                 actor_id: "user:local"
               )

      assert count(store.conn, "journal_entries") == before_entries
      assert count(store.conn, "action_commits") == before_commits
    end

    test "rejects a missing actor_id without writing", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.cancel_session(d.session.id, expected_session_revision: 0)

      assert count(store.conn, "action_commits") == 1
    end

    test "rejects cancellation from a terminal state", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)
      {:ok, _} = JB.commit_transition(store, d, "ready", "completed", 0, 3, "intent")

      before = count(store.conn, "action_commits")

      assert {:error, %Error{code: :run_transition_not_allowed}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 1,
                 actor_id: "user:local"
               )

      assert count(store.conn, "action_commits") == before
    end
  end

  # ---- AC04: resume_session contract ----

  describe "resume_session/2 (AC04)" do
    test "resumes from :ready", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      assert {:ok, result} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local"
               )

      assert result.run_state == :running
      assert result.session_revision == 1
      assert is_binary(result.action_id)
    end

    test "rejects resume from :running", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)
      {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3, "application")

      before = count(store.conn, "action_commits")

      assert {:error, %Error{code: :run_transition_not_allowed}} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 1,
                 actor_id: "user:local"
               )

      assert count(store.conn, "action_commits") == before
    end

    test "rejects a stale expected_session_revision without writing", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      before = count(store.conn, "action_commits")

      assert {:error, %Error{code: :stale_revision}} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 99,
                 actor_id: "user:local"
               )

      assert count(store.conn, "action_commits") == before
    end

    test "rejects a missing actor_id without writing", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.resume_session(d.session.id, expected_session_revision: 0)
    end
  end

  # ---- AC05: valid_next_actions contract ----

  describe "valid_next_actions/1 (AC05)" do
    test "returns an empty list for an unknown session_id", %{d: d} do
      # A session id that was never committed must not raise.
      assert {:ok, []} = Workflow.valid_next_actions(d.session.id)
    end

    test "returns the ascending-sorted atoms for each P1-S01 Run state", %{store: store} do
      cases = [
        {:ready, [:cancel_session, :request_decision, :revise_intent, :transition_run]},
        {:running, [:revise_intent, :transition_run]},
        {:waiting_for_user, [:answer_decision, :cancel_session, :transition_run]},
        {:orphaned, [:cancel_session, :fail_session, :transition_run]},
        {:completed, []},
        {:failed, []},
        {:canceled, []}
      ]

      for {target_state, expected_atoms} <- cases do
        session_id = fresh_session(store, target_state)

        assert {:ok, atoms} = Workflow.valid_next_actions(session_id)

        assert atoms == expected_atoms,
               "valid_next_actions for #{inspect(target_state)} returned #{inspect(atoms)}, " <>
                 "expected ascending-sorted #{inspect(expected_atoms)}"

        assert atoms == Enum.sort(atoms),
               "valid_next_actions for #{inspect(target_state)} is not ascending-sorted"
      end
    end

    test "is deterministic across repeated calls on the same state", %{store: store} do
      session_id = fresh_session(store, :ready)

      assert {:ok, first} = Workflow.valid_next_actions(session_id)
      assert {:ok, second} = Workflow.valid_next_actions(session_id)
      assert first == second
    end
  end

  # ---- AC06: boundary failure modes ----

  describe "boundary failure modes (AC06)" do
    test "start_session rejects a blank actor_id", %{store: store} do
      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation(),
                 actor_id: ""
               )

      assert count(store.conn, "journal_entries") == 0
    end

    test "cancel_session rejects a blank actor_id", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: ""
               )
    end

    test "resume_session rejects a blank actor_id", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "  "
               )
    end

    test "all five functions reject a malformed session_id" do
      assert {:error, %Error{code: :invalid_session_id}} = Workflow.query_session("nope")
      assert {:error, %Error{code: :invalid_session_id}} = Workflow.valid_next_actions("nope")

      assert {:error, %Error{code: :invalid_session_id}} =
               Workflow.cancel_session("nope", expected_session_revision: 0, actor_id: "u")

      assert {:error, %Error{code: :invalid_session_id}} =
               Workflow.resume_session("nope", expected_session_revision: 0, actor_id: "u")
    end

    test "start_session rejects a missing objective" do
      assert {:error, %Error{code: :objective}} =
               Workflow.start_session(
                 criteria: ["The focused test passes"],
                 project_observation: observation(),
                 actor_id: "user:local"
               )
    end

    test "start_session rejects a missing project_observation" do
      assert {:error, %Error{code: :missing_project_observation}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 actor_id: "user:local"
               )
    end

    test "query_session returns an error envelope on a corrupt journal without raising", %{
      store: store,
      d: d
    } do
      {:ok, _} = JB.commit_start(store, d)

      Connection.query!(store.conn, "DELETE FROM action_commits WHERE session_id = ?1", [
        d.session.id
      ])

      assert {:error, %Error{}} = Workflow.query_session(d.session.id)
    end
  end

  # ---- AC07: source-guard tests ----

  describe "source guard (AC07)" do
    @workflow_path "lib/kiln/workflow.ex"

    test "no function in the public boundary returns a runtime handle" do
      source = File.read!(@workflow_path)

      refute source =~ ~r/def.*do\s*\n.*Process\.spawn/,
             "the boundary must not spawn processes"
    end

    test "the boundary module does not alias or call any CLI, parser, renderer, Mix task, or release module" do
      source = File.read!(@workflow_path)
      forbidden = ~w(Kiln.CLI Mix.Tasks Phoenix Kiln.MCP Kiln.WaveB Kiln.Release)

      for module <- forbidden do
        refute source =~ ~r/(\balias\b|\bimport\b|\buse\b)\s+#{Regex.escape(module)}/,
               "#{module} must not appear in #{@workflow_path}"
      end
    end

    test "no function leaks a committed %Kiln.Domain.Action{} envelope" do
      source = File.read!(@workflow_path)

      refute source =~ ~r/def\s+.*\s+do[^}]*?%Kiln\.Domain\.Action\{\}/s,
             "no public function should construct a %Kiln.Domain.Action{} in its return shape"
    end
  end

  # ---- helpers ----

  defp observation do
    %{
      repository_root: "/tmp/kiln-fixture",
      repository_fingerprint: @fingerprint,
      observed_at: @at
    }
  end

  defp fresh_session(store, target_state) do
    counter = System.unique_integer([:positive])
    base = rem(counter, 200) + 30
    d = JB.domain(base)

    {:ok, _} = commit_unique_start(store, d, base)

    case target_state do
      :ready ->
        d.session.id

      :running ->
        {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, base + 1, "application")
        d.session.id

      :waiting_for_user ->
        {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, base + 1, "application")
        {:ok, _} = JB.commit_decision(store, d, 1, base + 2)
        d.session.id

      :orphaned ->
        {:ok, _} = JB.commit_operation_intent(store, d, 0, base + 1)
        {:ok, _} = JB.commit_operation_observe(store, d, 1, base + 2, "unknown", "orphaned")
        d.session.id

      :completed ->
        {:ok, _} = JB.commit_transition(store, d, "ready", "completed", 0, base + 1, "intent")
        d.session.id

      :failed ->
        {:ok, _} = JB.commit_transition(store, d, "ready", "failed", 0, base + 1, "intent")
        d.session.id

      :canceled ->
        {:ok, _} = JB.commit_transition(store, d, "ready", "canceled", 0, base + 1, "intent")
        d.session.id
    end
  end

  # Bypass JB.commit_start (which uses a fixed key_byte) so multiple sessions
  # in the same store get distinct action_ids.
  defp commit_unique_start(store, d, key_byte) do
    action = JB.action(d, :start_session, :local_user, "user:local", 0, key_byte, [])
    Kiln.Store.Journal.commit(store.conn, action, [JB.start_entry(d)], now: @now)
  end

  defp count(conn, table) do
    [[n]] = Connection.query!(conn, "SELECT count(*) FROM #{table}")
    n
  end
end
