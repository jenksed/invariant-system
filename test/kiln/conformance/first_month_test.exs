defmodule Kiln.Conformance.FirstMonthTest do
  use ExUnit.Case, async: true

  alias Kiln.Conformance.FirstMonth

  test "run states and terminal states match P0-W21" do
    assert FirstMonth.run_states() == [
             :ready,
             :running,
             :waiting_for_user,
             :orphaned,
             :completed,
             :failed,
             :canceled
           ]

    assert FirstMonth.terminal_run_states() == [:completed, :failed, :canceled]

    refute :created in FirstMonth.run_states()
    refute :verifying in FirstMonth.run_states()
    refute :waiting_for_command in FirstMonth.run_states()
  end

  test "transition shapes preserve orphan and terminal rules" do
    assert FirstMonth.allowed_transition?(:ready, :running)
    assert FirstMonth.allowed_transition?(:running, :orphaned)
    assert FirstMonth.allowed_transition?(:orphaned, :ready)

    refute FirstMonth.allowed_transition?(:orphaned, :completed)
    refute FirstMonth.allowed_transition?(:completed, :ready)
    refute FirstMonth.allowed_transition?(:failed, :running)
    refute FirstMonth.allowed_transition?(:canceled, :ready)
  end

  test "workflow Tool projection is fixed and bounded" do
    assert FirstMonth.tools() == [
             "repo.search",
             "repo.read",
             "artifact.read",
             "change.propose"
           ]

    assert length(FirstMonth.tools()) == 4
    assert FirstMonth.tools_for_step(:investigation) == FirstMonth.tools()
    assert FirstMonth.tools_for_step(:proposal) == FirstMonth.tools()
    assert FirstMonth.tools_for_step(:verification) == ["artifact.read"]
    assert FirstMonth.tools_for_step(:approval) == []
    assert FirstMonth.tools_for_step(:application) == []
    assert FirstMonth.tools_for_step(:acceptance) == []
    assert FirstMonth.tools_for_step(:reconciliation) == []
  end

  test "Patch, proof, Command, and CLI constants match focused authorities" do
    assert FirstMonth.patch_operations() == [:add, :replace, :delete]
    assert FirstMonth.evidence_statuses() == [:pass, :fail, :blocked, :unknown]
    assert FirstMonth.freshness_states() == [:current, :stale, :unknown]

    assert FirstMonth.completeness_states() == [
             :complete,
             :partial,
             :truncated,
             :missing,
             :unknown
           ]

    assert FirstMonth.contradiction_states() == [:none, :present, :unknown]

    assert FirstMonth.criterion_results() == [
             :pass,
             :fail,
             :blocked,
             :unknown,
             :stale,
             :contradicted
           ]

    assert FirstMonth.command_statuses() == [
             :succeeded,
             :failed,
             :timed_out,
             :canceled,
             :blocked,
             :unknown
           ]

    assert FirstMonth.cli_exit_codes() == %{
             ok: 0,
             usage: 2,
             denied: 3,
             blocked: 4,
             stale: 5,
             failed: 6,
             unknown: 7,
             store_blocked: 8,
             unsupported_host: 9,
             delivery_failed: 10
           }
  end

  test "initial limits remain narrower than provider and future-system capacity" do
    assert FirstMonth.context_limits() == %{
             maximum_estimated_input_tokens: 32_000,
             maximum_output_tokens: 8_192,
             maximum_tool_schemas: 4,
             maximum_tool_calls: 12,
             maximum_provider_turns: 8
           }

    assert FirstMonth.patch_limits() == %{
             maximum_operations: 32,
             maximum_paths: 32,
             maximum_single_after_image_bytes: 1_048_576,
             maximum_total_after_image_bytes: 4_194_304,
             maximum_total_rollback_bytes: 4_194_304
           }
  end

  test "provider and command host expose behaviours without implementations" do
    assert {:stream, 2} in Kiln.Conformance.Provider.behaviour_info(:callbacks)
    assert {:cancel, 1} in Kiln.Conformance.Provider.behaviour_info(:callbacks)

    callbacks = Kiln.Conformance.CommandHost.behaviour_info(:callbacks)
    assert {:launch, 1} in callbacks
    assert {:signal, 1} in callbacks
    assert {:probe, 1} in callbacks
  end

  test "scaffold cannot be mistaken for product runtime" do
    assert FirstMonth.scaffold_status() == :contracts_only

    absent_runtime_modules = [
      Kiln.Store,
      Kiln.Session,
      Kiln.Run,
      Kiln.Provider.MiniMax,
      Kiln.Context.Builder,
      Kiln.Repository.Reader,
      Kiln.Patch,
      Kiln.Mutation.Worker,
      Kiln.Command.Worker,
      Kiln.Evidence,
      Kiln.Receipt,
      Kiln.CLI
    ]

    for module <- absent_runtime_modules do
      message = "#{inspect(module)} must remain unimplemented in Prompt 6-A"
      refute Code.ensure_loaded?(module), message
    end
  end
end
