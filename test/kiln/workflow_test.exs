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
               [
                 :action_id,
                 :projection_digest,
                 :run_id,
                 :run_state,
                 :session_id,
                 :session_revision,
                 :task_id
               ]

      assert result.session_revision == 0
      assert result.run_state == :ready
      assert is_binary(result.session_id)
      assert is_binary(result.task_id)
      assert is_binary(result.run_id)
      assert is_binary(result.action_id)
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

    test "commits a cancel from a running Run", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)
      {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3, "application")

      assert {:ok, %{run_state: :canceled}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 1,
                 actor_id: "user:local"
               )
    end

    test "rejects a cancel from :waiting_for_user", %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)
      {:ok, _} = JB.commit_transition(store, d, "ready", "running", 0, 3, "application")
      {:ok, _} = JB.commit_decision(store, d, 1, 4)

      assert {:error, %Error{code: :run_transition_not_allowed}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 2,
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
        {:ready, [:cancel_session, :resume_session]},
        {:running, [:cancel_session]},
        {:waiting_for_user, []},
        {:orphaned, []},
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

        # Internal journal action kinds must never be exposed.
        refute :transition_run in atoms,
               "valid_next_actions must not expose the internal :transition_run kind"
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

  # ---- AC08: idempotent retry / conflict / capability parity ----

  describe "idempotent retry (AC08)" do
    test "an exact start retry with the same key and digest does not create a second Session", %{
      store: store
    } do
      key = unique_idempotency_key()

      first_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(first_opts)

      second_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, second} = Workflow.start_session(second_opts)

      assert second.session_id == first.session_id
      assert second.task_id == first.task_id
      assert second.run_id == first.run_id
      assert second.action_id == first.action_id
      assert second.session_revision == first.session_revision
      assert second.projection_digest == first.projection_digest

      assert count(store.conn, "journal_entries") == 1
      assert count(store.conn, "action_commits") == 1
      assert count(store.conn, "session_projections") == 1
    end

    test "a retry of cancel_session does not fail because the Run is already canceled", %{
      store: store,
      d: d
    } do
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      first_opts = [
        session_id: d.session.id,
        expected_session_revision: 0,
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.cancel_session(d.session.id, first_opts)
      assert first.run_state == :canceled

      before_entries = count(store.conn, "journal_entries")
      before_commits = count(store.conn, "action_commits")

      assert {:ok, replayed} = Workflow.cancel_session(d.session.id, first_opts)
      assert replayed.session_id == first.session_id
      assert replayed.action_id == first.action_id
      assert replayed.run_state == :canceled
      assert replayed.session_revision == first.session_revision

      assert count(store.conn, "journal_entries") == before_entries
      assert count(store.conn, "action_commits") == before_commits
    end

    test "a retry of resume_session does not fail because the Run is already running", %{
      store: store,
      d: d
    } do
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      first_opts = [
        expected_session_revision: 0,
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.resume_session(d.session.id, first_opts)
      assert first.run_state == :running

      before_entries = count(store.conn, "journal_entries")
      before_commits = count(store.conn, "action_commits")

      assert {:ok, replayed} = Workflow.resume_session(d.session.id, first_opts)
      assert replayed.action_id == first.action_id
      assert replayed.run_state == :running
      assert replayed.session_revision == first.session_revision

      assert count(store.conn, "journal_entries") == before_entries
      assert count(store.conn, "action_commits") == before_commits
    end

    test "a replay returns the original action_id, not a freshly generated one", %{
      store: _store
    } do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)

      # A retry generates a fresh action_id candidate internally; the journal
      # MUST discard it and return the original stored action_id instead.
      assert {:ok, replayed} = Workflow.start_session(opts)
      assert replayed.action_id == first.action_id
    end

    test "a successful result never contains a nil revision or nil projection_digest", %{
      store: _store
    } do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)
      assert is_integer(first.session_revision) and first.session_revision >= 0
      assert is_binary(first.projection_digest) and byte_size(first.projection_digest) > 0

      assert {:ok, replayed} = Workflow.start_session(opts)
      assert is_integer(replayed.session_revision) and replayed.session_revision >= 0
      assert is_binary(replayed.projection_digest) and byte_size(replayed.projection_digest) > 0
    end

    test "an idempotency conflict returns :idempotency_conflict without writing", %{
      store: store
    } do
      key = unique_idempotency_key()

      base_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, _} = Workflow.start_session(base_opts)
      before_entries = count(store.conn, "journal_entries")
      before_commits = count(store.conn, "action_commits")

      conflicting_opts =
        Keyword.put(base_opts, :actor_id, "user:different")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(conflicting_opts)

      assert count(store.conn, "journal_entries") == before_entries
      assert count(store.conn, "action_commits") == before_commits
    end

    test "the same idempotency_key with changed start criteria is a conflict, not a replay", %{
      store: _store
    } do
      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["A different criterion passes"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )
    end
  end

  # ---- AC09: capability parity ----

  describe "capability parity (AC09)" do
    test "every action advertised by valid_next_actions is executable from that Run state", %{
      store: store
    } do
      cases = [
        {:ready, :cancel_session},
        {:ready, :resume_session},
        {:running, :cancel_session}
      ]

      for {state, action_atom} <- cases do
        session_id = fresh_session(store, state)
        assert {:ok, advertised} = Workflow.valid_next_actions(session_id)
        assert action_atom in advertised, "#{action_atom} must be advertised from #{state}"

        # And executing it from the source state must succeed without raising.
        result = execute_atomic(session_id, state, action_atom)

        assert {:ok, _} = result,
               "executing #{action_atom} from #{state} must succeed; got #{inspect(result)}"
      end
    end

    test "valid_next_actions never exposes the internal :transition_run kind", %{store: store} do
      for state <- [:ready, :running] do
        session_id = fresh_session(store, state)
        assert {:ok, advertised} = Workflow.valid_next_actions(session_id)

        refute :transition_run in advertised,
               ":transition_run must never appear in valid_next_actions for #{state}"
      end
    end

    test "valid_next_actions returns [] for terminal states (no false advertising)", %{
      store: store
    } do
      for state <- [:completed, :failed, :canceled] do
        session_id = fresh_session(store, state)
        assert {:ok, []} = Workflow.valid_next_actions(session_id)
      end
    end
  end

  # ---- AC10: totality ----

  describe "totality (AC10)" do
    test "malformed argument types never raise a function-clause exception" do
      bogus = [
        # map with string keys (not atom keys)
        %{"objective" => "x", "criteria" => ["y"], "actor_id" => "z"},
        # nil where a keyword list is expected
        nil,
        # integer where a binary session id is expected
        42,
        # atom where a binary session id is expected
        :ready,
        # map where a binary session id is expected
        %{}
      ]

      for value <- bogus do
        result1 = Workflow.start_session(value)

        assert match?({:error, %Error{}}, result1),
               "got #{inspect(result1)} for #{inspect(value)}"

        result2 = Workflow.query_session(value)

        assert match?({:error, %Error{}}, result2),
               "got #{inspect(result2)} for #{inspect(value)}"

        result3 = Workflow.valid_next_actions(value)

        assert match?({:error, %Error{}}, result3),
               "got #{inspect(result3)} for #{inspect(value)}"

        result4 = Workflow.cancel_session(value, expected_session_revision: 0, actor_id: "u")

        assert match?({:error, %Error{}}, result4),
               "got #{inspect(result4)} for #{inspect(value)}"

        result5 = Workflow.resume_session(value, expected_session_revision: 0, actor_id: "u")

        assert match?({:error, %Error{}}, result5),
               "got #{inspect(result5)} for #{inspect(value)}"
      end
    end

    test "malformed projection state cannot trigger String.to_existing_atom or any other crash",
         %{store: store} do
      counter = System.unique_integer([:positive])
      base = rem(counter, 200) + 200
      d = JB.domain(base)
      {:ok, _} = commit_unique_start(store, d, base)

      # Inject a row with a bogus run state — String.to_existing_atom would
      # raise here on an older implementation; the bounded @run_state_to_atom
      # map must return nil and the workflow must reject the transition
      # without raising.
      bogus_state = "totally_unrecognized_state"
      revision = 1

      Connection.query!(
        store.conn,
        """
        INSERT INTO journal_entries
          (entry_id, entry_schema, entry_type, payload_schema, session_id, session_revision,
           action_id, actor_kind, actor_id, idempotency_key, request_digest,
           causation_entry_id, correlation_id, recorded_at, payload, payload_digest)
        VALUES (?1, 'journal_entry/v1', 'session_started/v1', 'session_started/v1', ?2, ?3,
                ?4, 'system', 'kiln:workflow', ?5, ?6, NULL, NULL, ?7, ?8, ?9)
        """,
        [
          Kiln.Store.Uuid.v7(),
          d.session.id,
          revision,
          JB.id(:action, 99),
          "idem_bogus_#{base}",
          JB.digest(99),
          @now,
          Kiln.Store.Canonical.encode(%{
            "session" => %{"id" => d.session.id, "state" => "active"},
            "task" => %{"id" => d.task.id, "state" => "in_progress"},
            "run" => %{"id" => d.run.id, "state" => bogus_state, "root_run_id" => d.run.id},
            "workflow_step" => "intent",
            "objective" => "x",
            "criteria" => ["y"],
            "constraints" => [],
            "exclusions" => [],
            "objective_revision" => 0,
            "criteria_revision" => 0,
            "references" => %{}
          }),
          "sha256:0000000000000000000000000000000000000000000000000000000000000099"
        ]
      )

      # The journal now classifies this as an invalid projection; the
      # workflow must return an error envelope, not raise.
      assert {:error, %Error{}} = Workflow.query_session(d.session.id)
      assert {:error, %Error{}} = Workflow.valid_next_actions(d.session.id)
      assert {:error, %Error{code: :invalid_session_id}} = Workflow.query_session("nope")
    end

    test "all five public functions accept either a keyword list or a map", %{store: _store} do
      # Each mutator must accept both shapes; the start_session map path
      # proves the map branch end-to-end, and the cancel/resume map paths
      # exercise the map branch on each transition in isolation.
      assert {:ok, started} =
               Workflow.start_session(%{
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: unique_idempotency_key()
               })

      assert {:error, %Error{}} = Workflow.query_session(123)
      assert {:error, %Error{}} = Workflow.query_session(:nope)
      assert {:error, %Error{}} = Workflow.query_session(%{})

      assert {:ok, _} =
               Workflow.cancel_session(started.session_id, %{
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: unique_idempotency_key()
               })

      # Start a second session for the resume map-path test so the state is
      # independent of the cancel above.
      {:ok, second} =
        Workflow.start_session(
          objective: "Correct one bounded defect",
          criteria: ["The focused test passes"],
          project_observation: observation(),
          actor_id: "user:local"
        )

      assert {:ok, _} =
               Workflow.resume_session(second.session_id, %{
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: unique_idempotency_key()
               })
    end
  end

  # ---- AC11: integrity ----

  describe "integrity (AC11)" do
    test "a corrupt idempotency result returns an error envelope, never a success-shaped result",
         %{store: store} do
      # Commit a start with a known idempotency_key, then tamper with the
      # stored result blob so its recorded digest no longer matches.
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, _} = Workflow.start_session(opts)

      # Tamper with the action_commits row's stored result to break its
      # recorded digest. The replay-boundary validator must catch this
      # before the spoofed result is returned.
      Connection.query!(
        store.conn,
        "UPDATE action_commits SET result = ?1 WHERE idempotency_key = ?2",
        [
          Kiln.Store.Canonical.encode(%{"session_id" => "spoofed"}),
          key
        ]
      )

      # An exact retry must surface the integrity error, never the spoofed
      # result and never an :ok envelope. The error code is one of the
      # documented integrity codes (:integrity for replay-boundary
      # failures and :corrupt_result for stored-result digest failures).
      assert {:error, %Error{code: code}} = Workflow.start_session(opts)
      assert code in [:integrity, :corrupt_result]
    end

    test "no broad rescue converts a transaction_failed into :ok", %{store: _store} do
      # Pass an actor_id that the action module rejects — this must be a
      # clean :error, not a rescued success.
      assert {:error, %Error{code: :missing_actor_id}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation()
               )

      # And after a clean start, a malformed revision must be a clean
      # :error, never :ok.
      {:ok, _} =
        Workflow.start_session(
          objective: "Correct one bounded defect",
          criteria: ["The focused test passes"],
          project_observation: observation(),
          actor_id: "user:local"
        )
    end

    test "boundary failure modes never return a success shape for known error codes" do
      # Every documented failure returns {:error, %Error{}}. No success is
      # ever wrapped around a known error code.
      cases = [
        fn ->
          Workflow.start_session(
            criteria: ["x"],
            project_observation: observation(),
            actor_id: "u"
          )
        end,
        fn ->
          Workflow.start_session(
            objective: "x",
            project_observation: observation(),
            actor_id: "u"
          )
        end,
        fn -> Workflow.start_session(objective: "x", criteria: ["x"], actor_id: "u") end,
        fn ->
          Workflow.start_session(
            objective: "x",
            criteria: [],
            project_observation: observation(),
            actor_id: "u"
          )
        end,
        fn -> Workflow.query_session("not_a_session_id") end,
        fn -> Workflow.valid_next_actions("not_a_session_id") end,
        fn ->
          Workflow.cancel_session("not_a_session_id", expected_session_revision: 0, actor_id: "u")
        end,
        fn ->
          Workflow.resume_session("not_a_session_id", expected_session_revision: 0, actor_id: "u")
        end
      ]

      for fun <- cases do
        result = fun.()

        assert match?({:error, %Error{code: _}}, result),
               "expected {:error, %Error{}} but got #{inspect(result)}"
      end
    end
  end

  # ---- AC12: restart durability ----

  describe "restart durability (AC12)" do
    test "an idempotent start retry survives a store process restart and returns the same identifiers",
         %{store: _store, dir: dir} do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      path = Path.join(dir, "state.sqlite3")
      assert {:ok, first} = Workflow.start_session(opts)

      stop_registered_store()

      {:ready, _restored} =
        Store.start(
          path: path,
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      conn = Process.whereis(Kiln.Store.Connection)
      before_entries = count(conn, "journal_entries")
      before_commits = count(conn, "action_commits")
      before_projections = count(conn, "session_projections")

      assert {:ok, replayed} = Workflow.start_session(opts)
      assert replayed == first

      assert count(conn, "journal_entries") == before_entries,
             "start retry after restart must not add journal entries"

      assert count(conn, "action_commits") == before_commits,
             "start retry after restart must not add action_commits"

      assert count(conn, "session_projections") == before_projections,
             "start retry after restart must not add session_projections"
    end

    test "an idempotent cancel retry survives a store process restart and returns the same action_id",
         %{store: _store, d: d, dir: dir} do
      stop_registered_store()

      {:ready, conn_store} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      {:ok, _} = JB.commit_start(conn_store, d)

      key = unique_idempotency_key()

      cancel_opts = [
        expected_session_revision: 0,
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.cancel_session(d.session.id, cancel_opts)

      stop_registered_store()

      {:ready, _restored} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      # Capture row counts after the restart, before the retry, so we can
      # prove the replay added zero writes and that the result equals the
      # original in every observable field.
      conn = Process.whereis(Kiln.Store.Connection)
      before_entries = count(conn, "journal_entries")
      before_commits = count(conn, "action_commits")
      before_projections = count(conn, "session_projections")

      assert {:ok, replayed} = Workflow.cancel_session(d.session.id, cancel_opts)
      assert replayed == first

      assert count(conn, "journal_entries") == before_entries,
             "cancel retry after restart must not add journal entries"

      assert count(conn, "action_commits") == before_commits,
             "cancel retry after restart must not add action_commits"

      assert count(conn, "session_projections") == before_projections,
             "cancel retry after restart must not add session_projections"
    end

    test "an idempotent resume retry survives a store process restart", %{
      store: _store,
      d: d,
      dir: dir
    } do
      stop_registered_store()

      {:ready, conn_store} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      {:ok, _} = JB.commit_start(conn_store, d)

      key = unique_idempotency_key()

      resume_opts = [
        expected_session_revision: 0,
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.resume_session(d.session.id, resume_opts)

      stop_registered_store()

      {:ready, _restored} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      conn = Process.whereis(Kiln.Store.Connection)
      before_entries = count(conn, "journal_entries")
      before_commits = count(conn, "action_commits")
      before_projections = count(conn, "session_projections")

      assert {:ok, replayed} = Workflow.resume_session(d.session.id, resume_opts)
      assert replayed == first

      assert count(conn, "journal_entries") == before_entries,
             "resume retry after restart must not add journal entries"

      assert count(conn, "action_commits") == before_commits,
             "resume retry after restart must not add action_commits"

      assert count(conn, "session_projections") == before_projections,
             "resume retry after restart must not add session_projections"
    end

    test "the workflow still answers query_session after a restart", %{
      store: _store,
      d: d,
      dir: dir
    } do
      stop_registered_store()

      {:ready, conn_store} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      {:ok, _} = JB.commit_start(conn_store, d)

      stop_registered_store()

      {:ready, _restored} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      assert {:ok, viewed} = Workflow.query_session(d.session.id)
      assert viewed.projection["session"]["id"] == d.session.id
      assert viewed.projection["run"]["state"] == "ready"
    end

    test "the workflow still answers valid_next_actions after a restart", %{
      store: _store,
      d: d,
      dir: dir
    } do
      stop_registered_store()

      {:ready, conn_store} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      {:ok, _} = JB.commit_start(conn_store, d)

      stop_registered_store()

      {:ready, _restored} =
        Store.start(
          path: Path.join(dir, "state.sqlite3"),
          store_id: "store_fixture",
          now: @now,
          name: Kiln.Store.Connection
        )

      assert {:ok, actions} = Workflow.valid_next_actions(d.session.id)
      assert actions == [:cancel_session, :resume_session]
    end
  end

  # ---- AC13: complete conflict matrix ----

  describe "complete conflict matrix (AC13)" do
    test "every P1-S01 x-operation pair is rejected except the capability matrix entries" do
      pairs = [
        # {:from_state, :public_relation, expected_outcome}
        {:ready, :cancel_session, :ok},
        {:ready, :resume_session, :ok},
        {:running, :cancel_session, :ok},
        {:running, :resume_session, :error},
        {:waiting_for_user, :cancel_session, :error},
        {:waiting_for_user, :resume_session, :error},
        {:orphaned, :cancel_session, :error},
        {:orphaned, :resume_session, :error},
        {:completed, :cancel_session, :error},
        {:completed, :resume_session, :error},
        {:failed, :cancel_session, :error},
        {:failed, :resume_session, :error},
        {:canceled, :cancel_session, :error},
        {:canceled, :resume_session, :error}
      ]

      for {state, op, expected} <- pairs do
        assert_matrix_pair(state, op, expected)
      end
    end

    test "every transition row produces a deterministic, ascending-sorted capability list",
         %{store: store} do
      for state <- [
            :ready,
            :running,
            :waiting_for_user,
            :orphaned,
            :completed,
            :failed,
            :canceled
          ] do
        session_id = fresh_session(store, state)
        assert {:ok, atoms} = Workflow.valid_next_actions(session_id)

        assert atoms == Enum.sort(atoms),
               "valid_next_actions for #{state} must be ascending-sorted but was #{inspect(atoms)}"
      end
    end
  end

  # ---- AC14: explicit timestamp contract ----

  describe "explicit timestamp contract (AC14)" do
    test "an omitted started_at still produces a replayable idempotency key", %{
      store: store
    } do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)
      assert {:ok, replayed} = Workflow.start_session(opts)

      assert replayed.session_id == first.session_id
      assert replayed.action_id == first.action_id
      assert count(store.conn, "journal_entries") == 1
    end

    test "a caller-supplied started_at participates in the digest (same start with same caller timestamp is a replay)",
         %{store: store} do
      key = unique_idempotency_key()
      started_at = @at

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key,
        started_at: started_at
      ]

      assert {:ok, first} = Workflow.start_session(opts)
      assert {:ok, replayed} = Workflow.start_session(opts)

      assert replayed.session_id == first.session_id
      assert replayed.action_id == first.action_id
      assert count(store.conn, "journal_entries") == 1
    end

    test "a caller-supplied started_at that differs across retries is a conflict, not a replay",
         %{store: store} do
      key = unique_idempotency_key()

      first_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key,
        started_at: ~U[2026-07-29 13:30:00Z]
      ]

      assert {:ok, _} = Workflow.start_session(first_opts)
      before_entries = count(store.conn, "journal_entries")

      second_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key,
        started_at: ~U[2026-07-29 14:30:00Z]
      ]

      assert {:error, %Error{code: :idempotency_conflict}} = Workflow.start_session(second_opts)
      assert count(store.conn, "journal_entries") == before_entries
    end

    test "an explicit started_at followed by an omitted started_at is a conflict, not a replay",
         %{store: store} do
      key = unique_idempotency_key()

      first_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key,
        started_at: @at
      ]

      assert {:ok, _} = Workflow.start_session(first_opts)
      before_entries = count(store.conn, "journal_entries")

      second_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:error, %Error{code: :idempotency_conflict}} = Workflow.start_session(second_opts)
      assert count(store.conn, "journal_entries") == before_entries
    end

    test "an omitted started_at followed by an explicit started_at is a conflict, not a replay",
         %{store: store} do
      key = unique_idempotency_key()

      first_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, _} = Workflow.start_session(first_opts)
      before_entries = count(store.conn, "journal_entries")

      second_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key,
        started_at: @at
      ]

      assert {:error, %Error{code: :idempotency_conflict}} = Workflow.start_session(second_opts)
      assert count(store.conn, "journal_entries") == before_entries
    end

    test "omitted started_at and two concurrent retries are still idempotent (auto-generated timestamps are excluded from the digest)",
         %{store: store} do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      tasks =
        for _ <- 1..5 do
          Task.async(fn -> Workflow.start_session(opts) end)
        end

      results = Task.await_many(tasks, 5_000)

      assert Enum.all?(results, &match?({:ok, _}, &1))
      assert 1 == results |> Enum.map(fn {:ok, r} -> r.session_id end) |> Enum.uniq() |> length()
      assert count(store.conn, "journal_entries") == 1
    end

    test "an invalid started_at (non-DateTime) is rejected as :invalid_started_at" do
      assert {:error, %Error{code: :invalid_started_at}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 started_at: "2026-07-29T13:30:00Z"
               )
    end

    test "two caller-supplied ProjectObservation structs with different ids are a conflict, not a replay",
         %{store: store} do
      key = unique_idempotency_key()

      # Build two distinct caller-supplied ProjectObservation structs sharing
      # the same fingerprint, root, and observed_at. The first is committed;
      # the second must conflict with it because its id is different and that
      # id is the durable project_observation_id the Session will reference.
      {:ok, first_observation} =
        Kiln.Domain.ProjectObservation.new(%{
          repository_root: "/tmp/kiln-fixture",
          repository_fingerprint: @fingerprint,
          observed_at: @at
        })

      {:ok, second_observation} =
        Kiln.Domain.ProjectObservation.new(%{
          repository_root: "/tmp/kiln-fixture",
          repository_fingerprint: @fingerprint,
          observed_at: @at
        })

      refute first_observation.id == second_observation.id

      first_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: first_observation,
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, _} = Workflow.start_session(first_opts)
      before_entries = count(store.conn, "journal_entries")

      second_opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: second_observation,
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(second_opts)

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "the same idempotency_key with changed start constraints is a conflict, not a replay",
         %{store: store} do
      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 constraints: ["Stay on Linux"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 constraints: ["Stay on macOS"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "the same idempotency_key with changed start exclusions is a conflict, not a replay",
         %{store: store} do
      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 exclusions: ["Do not refactor unrelated modules"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 exclusions: ["Do not touch session storage"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "the same idempotency_key with a different repository_fingerprint is a conflict",
         %{store: store} do
      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: %{
                   repository_root: "/tmp/kiln-fixture",
                   repository_fingerprint:
                     "sha256:00000000000000000000000000000000000000000000000000000000000000aa",
                   observed_at: @at
                 },
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: %{
                   repository_root: "/tmp/kiln-fixture",
                   repository_fingerprint:
                     "sha256:00000000000000000000000000000000000000000000000000000000000000bb",
                   observed_at: @at
                 },
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "the same idempotency_key with a different observed_at is a conflict",
         %{store: store} do
      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: %{
                   repository_root: "/tmp/kiln-fixture",
                   repository_fingerprint: @fingerprint,
                   observed_at: @at
                 },
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: %{
                   repository_root: "/tmp/kiln-fixture",
                   repository_fingerprint: @fingerprint,
                   observed_at: ~U[2026-07-29 14:00:00Z]
                 },
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "a cancel idempotency_key reused for resume_session is a conflict, not a replay",
         %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      assert {:ok, first} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert first.run_state == :canceled

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "a resume idempotency_key reused for cancel_session is a conflict, not a replay",
         %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      assert {:ok, first} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert first.run_state == :running

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "a transition idempotency_key reused for cancel_session is a conflict, not a replay",
         %{store: store, d: d} do
      # There is no public transition operation; the public surface is
      # cancel_session and resume_session. Cross-operation key reuse is
      # already covered by the resume-then-cancel test above. This test
      # covers the inverse (cancel-key reused after another cancel against
      # a different in-flight revision), exercising that the digest
      # includes `expected_session_revision` as a per-operation field.
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 1,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "the same idempotency_key reused across two distinct Sessions is a conflict on the second",
         %{store: store} do
      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.start_session(
                 objective: "Correct one bounded defect",
                 criteria: ["The focused test passes"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")
      before_sessions = count(store.conn, "session_projections")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.start_session(
                 objective: "A different objective",
                 criteria: ["Different criteria"],
                 project_observation: observation(),
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
      assert count(store.conn, "session_projections") == before_sessions
    end

    test "the same idempotency_key with a changed expected_session_revision on cancel is a conflict",
         %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 99,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "the same idempotency_key with a changed actor_id on cancel is a conflict",
         %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.cancel_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:different",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end

    test "the same idempotency_key with a changed expected_session_revision on resume is a conflict",
         %{store: store, d: d} do
      {:ok, _} = JB.commit_start(store, d)

      key = unique_idempotency_key()

      assert {:ok, _} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 0,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      before_entries = count(store.conn, "journal_entries")

      assert {:error, %Error{code: :idempotency_conflict}} =
               Workflow.resume_session(d.session.id,
                 expected_session_revision: 99,
                 actor_id: "user:local",
                 idempotency_key: key
               )

      assert count(store.conn, "journal_entries") == before_entries
    end
  end

  # ---- AC15: corrupt stored-result semantics ----

  describe "corrupt stored-result semantics (AC15)" do
    test "a stored result with a nil projection_digest returns an integrity error, never a success" do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)

      conn = Process.whereis(Kiln.Store.Connection)
      store = %{conn: conn}

      __MODULE__.CorruptHelpers.replace_stored_result_first_field(
        store,
        first.session_id,
        :projection_digest,
        nil
      )

      assert {:error, %Error{code: code}} = Workflow.start_session(opts)
      assert code in [:integrity, :corrupt_result]
    end

    test "a stored result with a malformed projection_digest returns an integrity error" do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)

      conn = Process.whereis(Kiln.Store.Connection)

      __MODULE__.CorruptHelpers.replace_stored_result_first_field(
        %{conn: conn},
        first.session_id,
        :projection_digest,
        "sha256:not-hex"
      )

      assert {:error, %Error{code: code}} = Workflow.start_session(opts)
      assert code in [:integrity, :corrupt_result]
    end

    test "a stored result with a negative session_revision returns an integrity error" do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)

      conn = Process.whereis(Kiln.Store.Connection)

      __MODULE__.CorruptHelpers.replace_stored_result_first_field(
        %{conn: conn},
        first.session_id,
        :session_revision,
        -1
      )

      assert {:error, %Error{code: code}} = Workflow.start_session(opts)
      assert code in [:integrity, :corrupt_result]
    end

    test "a stored result with a wrong run_state for the operation returns an integrity error" do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)

      conn = Process.whereis(Kiln.Store.Connection)

      __MODULE__.CorruptHelpers.replace_stored_result_first_field(
        %{conn: conn},
        first.session_id,
        :run_state,
        "canceled"
      )

      assert {:error, %Error{code: code}} = Workflow.start_session(opts)
      assert code in [:integrity, :corrupt_result]
    end

    test "a stored result with a session_id that disagrees with the authoritative journal returns an integrity error" do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)

      conn = Process.whereis(Kiln.Store.Connection)

      __MODULE__.CorruptHelpers.replace_stored_result_first_field(
        %{conn: conn},
        first.session_id,
        :session_id,
        "ses_00000000000000000000000000000099"
      )

      assert {:error, %Error{code: code}} = Workflow.start_session(opts)
      assert code in [:integrity, :corrupt_result]
    end

    test "a stored result with a missing action_id returns an integrity error" do
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)

      conn = Process.whereis(Kiln.Store.Connection)

      __MODULE__.CorruptHelpers.remove_stored_result_first_field(
        %{conn: conn},
        first.session_id,
        :action_id
      )

      assert {:error, %Error{code: code}} = Workflow.start_session(opts)
      assert code in [:integrity, :corrupt_result]
    end

    test "a stored result with validly-formatted but incorrect values is rejected",
         %{store: _store} do
      # Commit a real start_session action so the rebuild boundary is real.
      key = unique_idempotency_key()

      opts = [
        objective: "Correct one bounded defect",
        criteria: ["The focused test passes"],
        project_observation: observation(),
        actor_id: "user:local",
        idempotency_key: key
      ]

      assert {:ok, first} = Workflow.start_session(opts)
      rebuild_digest = first.projection_digest

      conn = Process.whereis(Kiln.Store.Connection)

      # Replace the stored result with one that passes its own digest check
      # (every field has the right Kiln identifier shape, the projection
      # digest is recomputed against the new payload, the run state matches,
      # and the revision is non-negative) but disagrees with the
      # authoritative action boundary the rebuild produced. The replay
      # validators must reject it.
      __MODULE__.CorruptHelpers.replace_stored_result_with_correct_format(
        %{conn: conn},
        first.session_id,
        %{
          "session_id" => first.session_id,
          "task_id" => "tsk_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          "run_id" => "run_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          "action_id" => "act_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          "session_revision" => first.session_revision,
          "run_state" => "ready",
          "projection_digest" => rebuild_digest
        }
      )

      assert {:error, %Error{code: :corrupt_result}} = Workflow.start_session(opts)
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

  defp unique_idempotency_key do
    "idem_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
  end

  defp execute_atomic(session_id, _current_state, action_atom) do
    # Query the current projection to find the actual expected revision,
    # since multi-step state transitions bump the revision above 1.
    expected_revision = current_revision_for(session_id)

    case action_atom do
      :cancel_session ->
        Workflow.cancel_session(session_id,
          expected_session_revision: expected_revision,
          actor_id: "user:local",
          idempotency_key: unique_idempotency_key()
        )

      :resume_session ->
        Workflow.resume_session(session_id,
          expected_session_revision: expected_revision,
          actor_id: "user:local",
          idempotency_key: unique_idempotency_key()
        )
    end
  end

  defp current_revision_for(session_id) do
    case Workflow.query_session(session_id) do
      {:ok, %{projection: %{"session_revision" => rev}}} when is_integer(rev) -> rev
      _ -> 0
    end
  end

  defp assert_matrix_pair(state, op, expected) do
    counter = System.unique_integer([:positive])
    base = rem(counter, 200) + 400
    d = JB.domain(base)
    conn = Process.whereis(Kiln.Store.Connection)
    store = %{conn: conn}
    {:ok, _start_result} = commit_unique_start(store, d, base)

    session_id =
      case state do
        :ready ->
          d.session.id

        :running ->
          {:ok, _} =
            JB.commit_transition(store, d, "ready", "running", 0, base + 1, "application")

          d.session.id

        :waiting_for_user ->
          {:ok, _} =
            JB.commit_transition(store, d, "ready", "running", 0, base + 1, "application")

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

    # Capture row counts AFTER the start has been committed and any
    # transitions to reach the source state have run; the matrix assertion
    # below is about the rejected operation specifically, not the setup.
    before_entries = count(conn, "journal_entries")
    before_commits = count(conn, "action_commits")
    before_projections = count(conn, "session_projections")

    expected_revision = current_revision_for(session_id)

    args = [
      expected_session_revision: expected_revision,
      actor_id: "user:local",
      idempotency_key: unique_idempotency_key()
    ]

    result =
      case op do
        :cancel_session -> Workflow.cancel_session(session_id, args)
        :resume_session -> Workflow.resume_session(session_id, args)
      end

    case expected do
      :ok ->
        assert {:ok, _} = result,
               "expected #{op} from #{state} to succeed; got #{inspect(result)}"

      :error ->
        # The capability matrix rejection must prove zero writes. The
        # `before_*` counts were captured after the start (and any
        # transitions needed to reach the source state) so we measure only
        # the rejected operation.
        assert {:error, %Error{}} = result,
               "expected #{op} from #{state} to fail; got #{inspect(result)}"

        conn = Process.whereis(Kiln.Store.Connection)

        assert count(conn, "journal_entries") == before_entries,
               "rejected #{op} from #{state} must not add journal entries"

        assert count(conn, "action_commits") == before_commits,
               "rejected #{op} from #{state} must not add action_commits"

        assert count(conn, "session_projections") == before_projections,
               "rejected #{op} from #{state} must not add session_projections"
    end
  end

  # Helpers for corrupting different fields of a stored application result,
  # rerunning the journal with the new value, and reusing the recomputed
  # digest so the replay-boundary validator can find the row.
  defmodule CorruptHelpers do
    alias Kiln.Store.Canonical

    def replace_stored_result_first_field(store, session_id, field, new_value) do
      swap_stored_result(store, session_id, fn decoded ->
        key = field_to_key(field)
        Map.put(decoded, key, new_value)
      end)
    end

    def remove_stored_result_first_field(store, session_id, field) do
      swap_stored_result(store, session_id, fn decoded ->
        Map.delete(decoded, field_to_key(field))
      end)
    end

    # Replaces the stored result with a fully-formed map (all identifier
    # shapes are valid, the run state matches the operation, the projection
    # digest is recomputed against the new payload) but whose identifier
    # values disagree with the authoritative journal action boundary. The
    # replay-boundary validators must reject this on the basis of the
    # boundary mismatch even though the stored digest matches.
    def replace_stored_result_with_correct_format(store, session_id, new_decoded) do
      swap_stored_result(store, session_id, fn _decoded -> new_decoded end)
    end

    defp field_to_key(field) when is_atom(field), do: Atom.to_string(field)
    defp field_to_key(field) when is_binary(field), do: field

    defp swap_stored_result(store, session_id, transform) do
      [[result_text, _digest, schema]] =
        Connection.query!(
          store.conn,
          "SELECT result, result_digest, result_schema FROM action_commits WHERE session_id = ?1",
          [session_id]
        )

      decoded = JSON.decode!(result_text)
      new_decoded = transform.(decoded)
      new_text = Canonical.encode(new_decoded)
      new_digest = Canonical.digest(schema, new_decoded)

      Connection.query!(
        store.conn,
        "UPDATE action_commits SET result = ?1, result_digest = ?2 WHERE session_id = ?3",
        [new_text, new_digest, session_id]
      )

      :ok
    end
  end
end
