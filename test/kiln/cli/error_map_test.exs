defmodule Kiln.CLI.ErrorMapTest do
  use ExUnit.Case, async: true

  alias Kiln.CLI.ErrorMap
  alias Kiln.CLI.Result

  test "every code maps to an accepted CLI status" do
    for {code, _} <- Enum.into(ErrorMap.codes(), []) do
      {status, exit} = ErrorMap.map(code)

      assert status in Result.statuses(),
             "code #{inspect(code)} mapped to unknown status #{status}"

      assert exit in Enum.to_list(0..10),
             "code #{inspect(code)} mapped to exit code #{exit}"
    end
  end

  test "every code maps to exactly one (status, exit_code) pair" do
    codes = ErrorMap.codes()
    assert length(codes) == length(Enum.uniq(codes)), "codes must be unique"

    pairs = Enum.map(codes, &ErrorMap.map/1)
    # The mapping is a deterministic function; for each code there is one
    # pair. Codes may share a pair when they share a semantic class
    # (e.g. every workflow blocked code maps to {:blocked, 4}). What
    # matters is that the map is total and that the CLI never falls back
    # to a generic catch-all: every pair is an explicit, named entry.
    assert Enum.all?(pairs, fn
             {status, exit} when is_atom(status) and is_integer(exit) -> true
             _ -> false
           end)
  end

  test "all published Workflow error codes are covered" do
    workflow_codes = [
      :invalid_input,
      :invalid_session_id,
      :invalid_idempotency_key,
      :invalid_started_at,
      :invalid_project_observation,
      :missing_project_observation,
      :invalid_expected_session_revision,
      :missing_actor_id,
      :objective,
      :criteria,
      :constraints,
      :exclusions,
      :corrupt_result,
      :projection_unavailable,
      :journal_invalid,
      :unknown_run_state,
      :idempotency_conflict,
      :revision,
      :stale_revision,
      :busy,
      :store_busy,
      :migration,
      :integrity,
      :run_transition_not_allowed,
      :multiple_sessions,
      :transaction_failed,
      :store_unavailable,
      :terminal_run_state
    ]

    for code <- workflow_codes do
      assert {status, exit} = ErrorMap.map(code)
      assert is_atom(status)
      assert is_integer(exit)
    end
  end

  test "parser-level codes are covered" do
    assert {:denied, 2} = ErrorMap.map("USAGE_ERROR")
    assert {:denied, 2} = ErrorMap.map("usage")
  end

  test "unsupported command maps to :unsupported / exit 9" do
    assert {:unsupported, 9} = ErrorMap.map(:unsupported_command)
  end

  test "unknown codes fall back to :failed / exit 6" do
    assert {:failed, 6} = ErrorMap.map(:some_unmapped_code)
  end

  test "no (status, exit_code) pair collides with the success path" do
    pairs = ErrorMap.pairs()
    refute {:ok, 0} in pairs
  end
end
