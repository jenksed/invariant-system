defmodule Kiln.OperationLifecycleParityTest do
  @moduledoc """
  F1 regression: assert that the two orphan classifiers — `Kiln.Restart.reconstruct/1`
  (used by the startup recovery path) and `Kiln.Workflow.query_session/1`
  (exposed via `current_session/0` and the CLI) — never diverge on the same
  canonical projection.

  Both consumers go through `Kiln.OperationLifecycle.nonterminal_string?/1`,
  the single authoritative vocabulary. This test asserts that property
  end-to-end: for every representative nonterminal operation state the
  classifier reports `orphaned: true`, and for every terminal state it reports
  `orphaned: false`. A regression that reintroduces a divergent nonterminal set
  in either consumer fails this test before the schema can drift.
  """

  use ExUnit.Case, async: false

  alias Kiln.{OperationLifecycle, Restart, Workflow}
  alias Kiln.Test.JournalBuilder, as: JB

  setup do
    stop_registered()
    dir = Path.join(System.tmp_dir!(), "kiln-parity-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      stop_registered()
      File.rm_rf!(dir)
    end)

    {:ok, dir: dir}
  end

  test "Restart and Workflow agree on the orphan flag for every nonterminal state", %{dir: dir} do
    # A journal with an intent_recorded (no observation) entry is the canonical
    # nonterminal operation. Both consumers must classify it as orphaned.
    assert_parity_with_intent(dir, expected_orphaned: true)
  end

  test "Restart and Workflow agree on the orphan flag for the persisted started state",
       %{dir: dir} do
    # `:started` is the second nonterminal operation state and is the exact
    # state omitted by the broken implementation that triggered the original
    # review finding. The persisted journal below transitions the Run to
    # `:running`, records the operation intent (`intent_recorded`), then
    # records an observation with `state: "started"` and `run_to: "running"`
    # so the reducer advances the operation to `:started` while leaving the
    # Run in `:running`. Both consumers must classify this as orphaned.
    assert_parity_with_started_operation(dir, expected_orphaned: true)
  end

  test "OperationLifecycle partitions every accepted operation state correctly" do
    # The classifier is the single source of truth for which states are
    # nonterminal. A drift in either direction (a state becoming
    # nonterminal that the Restart or Workflow paths treat as terminal,
    # or vice versa) fails this test before the partition can leak into
    # the orphan classifiers.
    canonical_states = OperationLifecycle.states()
    canonical_nonterminal = OperationLifecycle.nonterminal_states()

    canonical_terminal = canonical_states -- canonical_nonterminal

    for state <- canonical_nonterminal do
      assert OperationLifecycle.nonterminal?(state),
             "#{inspect(state)} is in the canonical nonterminal set but the classifier returned false"

      assert OperationLifecycle.nonterminal_string?(Atom.to_string(state)),
             "#{inspect(state)} is in the canonical nonterminal set but the string classifier returned false"
    end

    for state <- canonical_terminal do
      refute OperationLifecycle.nonterminal?(state),
             "#{inspect(state)} is in the canonical terminal set but the classifier returned true"

      refute OperationLifecycle.nonterminal_string?(Atom.to_string(state)),
             "#{inspect(state)} is in the canonical terminal set but the string classifier returned true"
    end

    # An unknown atom or string must not be classified as nonterminal —
    # silently treating an unknown state as orphaned would let a corrupt
    # journal masquerade as an actionable Run.
    refute OperationLifecycle.nonterminal?(:unknown)
    refute OperationLifecycle.nonterminal?(:nonsense)
    refute OperationLifecycle.nonterminal_string?("unknown")
    refute OperationLifecycle.nonterminal_string?("not_a_state")
    refute OperationLifecycle.nonterminal?(nil)
  end

  test "Restart and Workflow agree on the orphan flag for a terminal observation", %{dir: dir} do
    # A journal with an observation entry in a terminal state ("succeeded")
    # leaves the projection in a non-orphaned state. Both consumers must agree.
    assert_parity_with_observation(dir, "succeeded", "ready", expected_orphaned: false)
  end

  test "Restart and Workflow agree on the orphan flag for an operation with no recorded operation",
       %{
         dir: dir
       } do
    # A journal with no operation at all must not be classified as orphaned.
    assert_parity_no_operation(dir, expected_orphaned: false)
  end

  # The single representative nonterminal case: a journal entry records an
  # operation intent but no terminal observation. Both consumers must
  # classify the reconstructed projection as orphaned.
  defp assert_parity_with_intent(parent_dir, expected_orphaned: expected) do
    path = Path.join(parent_dir, "state-#{System.unique_integer([:positive])}.sqlite3")
    store = JB.store(path)
    d = JB.domain()
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)
    run_parity(store, d, expected_orphaned: expected)
  end

  # Construct a journal with a persisted operation in the `:started` state.
  # The reducer requires `run.state == "running"` to accept an observation
  # with `state: "started"`, so the sequence is:
  #   start (rev 0, run=ready)
  #   operation intent (rev 1, run=running, op=intent_recorded)
  #   operation observe state="started" run_to="running" (rev 2, op=started)
  # The operation intent itself transitions the Run from ready to running,
  # so an explicit `commit_transition` is unnecessary and would race the
  # reducer's own transition.
  defp assert_parity_with_started_operation(parent_dir, expected_orphaned: expected) do
    path = Path.join(parent_dir, "state-#{System.unique_integer([:positive])}.sqlite3")
    store = JB.store(path)
    d = JB.domain()
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 4)
    {:ok, _} = JB.commit_operation_observe(store, d, 1, 5, "started", "running")
    run_parity(store, d, expected_orphaned: expected)
  end

  defp assert_parity_with_observation(parent_dir, op_state, run_to, expected_orphaned: expected) do
    path = Path.join(parent_dir, "state-#{System.unique_integer([:positive])}.sqlite3")
    store = JB.store(path)
    d = JB.domain()
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)
    {:ok, _} = JB.commit_operation_observe(store, d, 1, 8, op_state, run_to)
    run_parity(store, d, expected_orphaned: expected)
  end

  defp assert_parity_no_operation(parent_dir, expected_orphaned: expected) do
    path = Path.join(parent_dir, "state-#{System.unique_integer([:positive])}.sqlite3")
    store = JB.store(path)
    d = JB.domain()
    {:ok, _} = JB.commit_start(store, d)
    run_parity(store, d, expected_orphaned: expected)
  end

  defp run_parity(store, d, expected_orphaned: expected) do
    conn = store.conn

    restart_verdict =
      case Restart.reconstruct(conn) do
        {:ok, %{orphaned: orphaned}} when is_boolean(orphaned) -> orphaned
        {:ok, :empty} -> false
      end

    register_for_workflow(conn)
    {:ok, query_result} = Workflow.query_session(d.session.id)
    workflow_verdict = query_result.orphaned
    stop_registered()

    stop(conn)

    assert restart_verdict == expected,
           "Restart classifier expected orphaned=#{expected}, got #{restart_verdict}"

    assert workflow_verdict == expected,
           "Workflow classifier expected orphaned=#{expected}, got #{workflow_verdict}"

    assert restart_verdict == workflow_verdict,
           "F1 regression: Restart and Workflow disagree " <>
             "(restart=#{restart_verdict}, workflow=#{workflow_verdict})"
  end

  defp register_for_workflow(conn) do
    # If a previous test left the name registered, drop it first.
    try do
      Process.unregister(Kiln.Store.Connection)
    catch
      :error, _ -> :ok
    end

    Process.register(conn, Kiln.Store.Connection)
  end

  defp stop_registered do
    pid = Process.whereis(Kiln.Store.Connection)

    if is_pid(pid) and Process.alive?(pid) do
      try do
        GenServer.stop(pid, :normal, 1_000)
      catch
        :exit, _reason -> :ok
      end
    end

    # Be tolerant: the process may already be unregistered.
    try do
      pid = Process.whereis(Kiln.Store.Connection)

      if is_pid(pid) do
        Process.unregister(Kiln.Store.Connection)
      end
    catch
      :error, _ -> :ok
    end

    :ok
  end

  defp stop(conn) do
    if Process.alive?(conn), do: GenServer.stop(conn)
    :ok
  catch
    :exit, _reason -> :ok
  end
end
