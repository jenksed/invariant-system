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

  alias Kiln.{Restart, Workflow}
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
