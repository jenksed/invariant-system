defmodule Kiln.Conformance.FirstMonth do
  @moduledoc """
  Executable constants for the accepted first-month planning contract.

  This module is conformance scaffolding. It does not start a Session, persist
  state, invoke a provider, read a Repository, apply a Patch, execute a Command,
  evaluate Evidence, or expose a CLI.
  """

  @run_states [:ready, :running, :waiting_for_user, :orphaned, :completed, :failed, :canceled]
  @terminal_run_states [:completed, :failed, :canceled]
  @workflow_steps [
    :intent,
    :investigation,
    :proposal,
    :approval,
    :application,
    :verification,
    :acceptance,
    :reconciliation
  ]
  @operation_states [:intent_recorded, :started, :succeeded, :failed, :canceled, :unknown]

  @allowed_transitions MapSet.new([
                         {:ready, :running},
                         {:running, :ready},
                         {:running, :waiting_for_user},
                         {:waiting_for_user, :ready},
                         {:ready, :completed},
                         {:ready, :failed},
                         {:running, :failed},
                         {:ready, :canceled},
                         {:running, :canceled},
                         {:waiting_for_user, :canceled},
                         {:running, :orphaned},
                         {:ready, :orphaned},
                         {:orphaned, :ready},
                         {:orphaned, :failed},
                         {:orphaned, :canceled}
                       ])

  @tools ["repo.search", "repo.read", "artifact.read", "change.propose"]
  @patch_operations [:add, :replace, :delete]
  @evidence_statuses [:pass, :fail, :blocked, :unknown]
  @freshness_states [:current, :stale, :unknown]
  @completeness_states [:complete, :partial, :truncated, :missing, :unknown]
  @contradiction_states [:none, :present, :unknown]
  @criterion_results [:pass, :fail, :blocked, :unknown, :stale, :contradicted]
  @command_statuses [:succeeded, :failed, :timed_out, :canceled, :blocked, :unknown]
  @cli_statuses [:ok, :denied, :blocked, :stale, :failed, :unknown, :unsupported]

  @cli_exit_codes %{
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

  @context_limits %{
    maximum_estimated_input_tokens: 32_000,
    maximum_output_tokens: 8_192,
    maximum_tool_schemas: 4,
    maximum_tool_calls: 12,
    maximum_provider_turns: 8
  }

  @patch_limits %{
    maximum_operations: 32,
    maximum_paths: 32,
    maximum_single_after_image_bytes: 1_048_576,
    maximum_total_after_image_bytes: 4_194_304,
    maximum_total_rollback_bytes: 4_194_304
  }

  @type run_state ::
          :ready
          | :running
          | :waiting_for_user
          | :orphaned
          | :completed
          | :failed
          | :canceled

  @type workflow_step ::
          :intent
          | :investigation
          | :proposal
          | :approval
          | :application
          | :verification
          | :acceptance
          | :reconciliation

  @type operation_state ::
          :intent_recorded | :started | :succeeded | :failed | :canceled | :unknown

  @type patch_operation :: :add | :replace | :delete
  @type evidence_status :: :pass | :fail | :blocked | :unknown
  @type criterion_result :: :pass | :fail | :blocked | :unknown | :stale | :contradicted

  @spec scaffold_status() :: :contracts_only
  def scaffold_status, do: :contracts_only

  @spec run_states() :: [run_state()]
  def run_states, do: @run_states

  @spec terminal_run_states() :: [run_state()]
  def terminal_run_states, do: @terminal_run_states

  @spec workflow_steps() :: [workflow_step()]
  def workflow_steps, do: @workflow_steps

  @spec operation_states() :: [operation_state()]
  def operation_states, do: @operation_states

  @spec allowed_transition?(run_state(), run_state()) :: boolean()
  def allowed_transition?(from, to), do: MapSet.member?(@allowed_transitions, {from, to})

  @spec tools() :: [String.t()]
  def tools, do: @tools

  @spec tools_for_step(workflow_step()) :: [String.t()]
  def tools_for_step(step) when step in [:investigation, :proposal], do: @tools
  def tools_for_step(:verification), do: ["artifact.read"]
  def tools_for_step(step) when step in @workflow_steps, do: []

  @spec patch_operations() :: [patch_operation()]
  def patch_operations, do: @patch_operations

  @spec evidence_statuses() :: [evidence_status()]
  def evidence_statuses, do: @evidence_statuses

  @spec freshness_states() :: [atom()]
  def freshness_states, do: @freshness_states

  @spec completeness_states() :: [atom()]
  def completeness_states, do: @completeness_states

  @spec contradiction_states() :: [atom()]
  def contradiction_states, do: @contradiction_states

  @spec criterion_results() :: [criterion_result()]
  def criterion_results, do: @criterion_results

  @spec command_statuses() :: [atom()]
  def command_statuses, do: @command_statuses

  @spec cli_statuses() :: [atom()]
  def cli_statuses, do: @cli_statuses

  @spec cli_exit_codes() :: %{required(atom()) => non_neg_integer()}
  def cli_exit_codes, do: @cli_exit_codes

  @spec context_limits() :: %{required(atom()) => pos_integer()}
  def context_limits, do: @context_limits

  @spec patch_limits() :: %{required(atom()) => pos_integer()}
  def patch_limits, do: @patch_limits
end
