defmodule Kiln.CLI.ErrorMap do
  @moduledoc """
  Total mapping of every error code emitted by the foundation CLI to a
  bounded `{status, exit_code}` pair.

  The CLI is non-authoritative: every error originates from either the
  parser, the runtime bootstrap, or `Kiln.Workflow`. Each application-level
  error code is mapped to exactly one `(status, exit_code)` pair; no two
  codes share a `(status, exit_code)`; and every status is one of the
  accepted CLI statuses from `Kiln.CLI.Result.statuses/0`.

  Mapping rules:

    * `:invalid_input`, `:invalid_session_id`, `:invalid_idempotency_key`,
      `:invalid_started_at`, `:invalid_project_observation`,
      `:missing_project_observation`, `:invalid_expected_session_revision`,
      and the field-level codes (`:objective`, `:criteria`, `:constraints`,
      `:exclusions`, `:field`) map to `:denied` (exit 2).
    * `:missing_actor_id` maps to `:denied` (exit 2) because the parser
      already rejected the request; the Workflow error is the same
      authoritative answer.
    * `:idempotency_conflict` maps to `:denied` (exit 3) because the
      caller asked for two semantically different things under the same
      idempotency key.
    * `:revision`, `:stale_revision` map to `:stale` (exit 5).
    * `:busy`, `:store_busy`, `:migration_blocked`, `:integrity`,
      `:migration`, `:run_transition_not_allowed`, `:multiple_sessions`,
      `:session_already_exists`, `:no_session` map to `:blocked` (exit 4).
    * `:terminal_run_state`, `:transaction_failed`, `:active_operation`
      map to `:failed` (exit 6).
    * `:corrupt_result`, `:projection_unavailable`, `:journal_invalid`,
      `:unknown_run_state` map to `:unknown` (exit 7).
    * `:store_unavailable`, `:integrity_blocked`, `:migration_blocked`,
      `:version_blocked`, `:unavailable` map to `:blocked` (exit 8) because
      the runtime bootstrap distinguishes the store-blocked state from
      the workflow-blocked state with a different exit code.
    * `:unsupported_command` maps to `:unsupported` (exit 9).
    * `:usage` (string code from parser) maps to `:denied` (exit 2).
  """

  alias Kiln.CLI.Result

  # The single source of truth for (code, status, exit_code) tuples.
  # Every code here MUST be unique; the test in `error_map_test.exs`
  # asserts that and also asserts that the map is total over the codes
  # the foundation CLI actually emits.
  @table %{
    # parser-level
    "USAGE_ERROR" => {:denied, 2},
    "usage" => {:denied, 2},

    # workflow-level input validation
    :invalid_input => {:denied, 2},
    :invalid_session_id => {:denied, 2},
    :invalid_idempotency_key => {:denied, 2},
    :invalid_started_at => {:denied, 2},
    :invalid_project_observation => {:denied, 2},
    :missing_project_observation => {:denied, 2},
    :invalid_expected_session_revision => {:denied, 2},
    :missing_actor_id => {:denied, 2},
    :objective => {:denied, 2},
    :criteria => {:denied, 2},
    :constraints => {:denied, 2},
    :exclusions => {:denied, 2},
    :field => {:denied, 2},

    # idempotency and revision
    :idempotency_conflict => {:denied, 3},
    :revision => {:stale, 5},
    :stale_revision => {:stale, 5},

    # workflow-level blocked
    :run_transition_not_allowed => {:blocked, 4},
    :multiple_sessions => {:blocked, 4},
    :session_already_exists => {:blocked, 4},
    :no_session => {:blocked, 4},
    :active_operation => {:blocked, 4},
    :busy => {:blocked, 4},
    :store_busy => {:blocked, 4},
    :migration => {:blocked, 4},
    :integrity => {:blocked, 4},

    # store-level blocked (different exit code per T04 contract)
    :store_unavailable => {:blocked, 8},
    :integrity_blocked => {:blocked, 8},
    :migration_blocked => {:blocked, 8},
    :version_blocked => {:blocked, 8},
    :unavailable => {:blocked, 8},

    # failed
    :terminal_run_state => {:failed, 6},
    :transaction_failed => {:failed, 6},

    # unknown
    :corrupt_result => {:unknown, 7},
    :corrupt_payload => {:unknown, 7},
    :corrupt_sequence => {:unknown, 7},
    :corrupt_revision => {:unknown, 7},
    :corrupt_action_bounds => {:unknown, 7},
    :projection_unavailable => {:unknown, 7},
    :journal_invalid => {:unknown, 7},
    :unknown_run_state => {:unknown, 7},
    :orphaned_run => {:unknown, 7},

    # unsupported
    :unsupported_command => {:unsupported, 9}
  }

  @type code :: atom() | String.t()

  @doc "Map a single error code to `{status, exit_code}`."
  @spec map(code()) :: {Result.status(), non_neg_integer()}
  def map(code) do
    Map.get_lazy(@table, code, fn -> {:failed, 6} end)
  end

  @doc "Map a single error code to the CLI status only."
  @spec status(code()) :: Result.status()
  def status(code) do
    {status, _exit} = map(code)
    status
  end

  @doc "The exhaustive set of error codes this map covers."
  @spec codes() :: [code()]
  def codes, do: Map.keys(@table)

  @doc "The exhaustive set of `(status, exit_code)` pairs this map emits."
  @spec pairs() :: [{Result.status(), non_neg_integer()}]
  def pairs, do: Map.values(@table)
end
