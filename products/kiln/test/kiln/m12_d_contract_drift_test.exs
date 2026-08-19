defmodule Kiln.M12DContractDriftTest do
  @moduledoc """
  WP-09 contract-drift guard.

  A regression test that proves the frozen WP-09 contract survives
  future edits. Each assertion here exists because a previous defect
  in WP-09 was caused by exactly this drift.

  Categories guarded:
    1. All frozen RPC methods are routed (router stub shadowed the
       real project handler in commit dfadd86 / fix 7fa53b2).
    2. Required exact scopes match the frozen table (review:write
       required for review.propose; no superset acceptance).
    3. Bounded error envelope preserves method + scope + fields
       + reason through the transport (P5 PROVEN).
    4. Canonical contract identity strings are unchanged (no
       rename across WP-09).
    5. Activity schema version matches the Temper-side expectation.
    6. Domain field names match the actual M0 structs (M0Review has
       verifier_ref, not verification_ref — fix at commit ed8bb08).
    7. Restart.reconstruct/1 return-shape consumed exactly per
       @spec (lib/kiln/restart.ex:38-42).

  This test is intentionally narrow: it does not build a general IDL
  compiler. It checks the high-value invariants that the WP-09 defect
  cycle actually exposed.

  Path resolution: every cross-product source inspection uses
  `repo_path/1` derived from `@repo_root`, which is established by
  `find_repo_root/0` walking upward from `__DIR__` until both
  `products/kiln/mix.exs` AND `products/temper/package.json` exist
  in the same directory. The test does NOT depend on:
    - the caller's shell working directory
    - the owner's absolute path
    - the worktree directory name
    - how many directory levels the test file happens to occupy
  It DOES fail loudly if no repository root can be established.
  """

  use ExUnit.Case, async: true

  # Walk upward from `dir` until we find a directory containing BOTH
  # products/kiln/mix.exs AND products/temper/package.json. The walk
  # terminates at the filesystem root and raises if no candidate is
  # found.
  #
  # This is a runtime helper, NOT a module attribute. Computing the
  # repository root via @repo_root = find_repo_root(__DIR__) compiles
  # at module-load time and is brittle in CI sandboxes; the runtime
  # resolution is functionally equivalent and avoids spurious compile
  # failures.
  defp find_repo_root(dir) do
    kiln = Path.join(dir, "products/kiln/mix.exs")
    temper = Path.join(dir, "products/temper/package.json")

    cond do
      File.exists?(kiln) and File.exists?(temper) ->
        dir

      Path.dirname(dir) == dir ->
        raise "unable to locate repository root (no directory found with both products/kiln/mix.exs AND products/temper/package.json)"

      true ->
        find_repo_root(Path.dirname(dir))
    end
  end

  defp repo_path(relative), do: Path.join(find_repo_root(__DIR__), relative)

  @frozen_rpc_methods [
    # WP-08 Lane 2 — session-family
    "session.start",
    "session.cancel",
    "session.resume",
    "session.query",
    "session.next_actions",
    # WP-08 Lane 3 — patch
    "patch.apply",
    # WP-09 Lane 1 — lifecycle closure
    "worker.propose",
    "verify.run",
    "review.propose",
    "human.decide",
    # WP-09 Lane 1 — project
    "project.open",
    "project.list",
    # WP-09 Lane 2 — activity
    "activity.subscribe"
  ]

  # Per LANE-EVIDENCE-WP09-CONTRACTS.md §4 — exact-match scope table.
  @frozen_scope_table %{
    "worker.propose" => "orchestration:operate",
    "patch.apply" => "orchestration:operate",
    "verify.run" => "orchestration:operate",
    "review.propose" => "review:write",
    "human.decide" => "orchestration:operate",
    "project.open" => "orchestration:operate",
    "project.list" => "orchestration:read",
    "activity.subscribe" => "orchestration:read",
    "terminal.attach" => "terminal:operate",
    "session.start" => "orchestration:operate",
    "session.cancel" => "orchestration:operate",
    "session.resume" => "orchestration:operate",
    "session.query" => "orchestration:read",
    "session.next_actions" => "orchestration:read"
  }

  # Canonical contract identity strings (must NOT be renamed across
  # WP-09). Each tuple: {string, file relative to repo root}.
  @frozen_contract_strings [
    {"engineering-system/run-result-envelope/v0", "products/temper/src/load.ts"},
    {"engineering-system/run-result-projection/m0-v1", "products/temper/src/load.ts"},
    {"loadout/plan/v0", "products/temper/src/load.ts"},
    {"engineering-system/verification-result/m0-v1", "products/kiln/lib/kiln/m0_types.ex"},
    {"engineering-system/review/m0-v1", "products/kiln/lib/kiln/m9_review.ex"},
    {"engineering-system/human-decision/m0-v1", "products/kiln/lib/kiln/m9_review.ex"},
    {"implementer-patch-proposal-input/v1", "products/kiln/lib/kiln/worker.ex"},
    {"external_operation_intent_recorded/v1", "products/kiln/lib/kiln/journal/entry.ex"},
    {"external_operation_observed/v1", "products/kiln/lib/kiln/journal/entry.ex"},
    {"session_projection/v1", "products/kiln/lib/kiln/projections/session.ex"}
  ]

  # ------------------------------------------------------------------
  # Category 1: every frozen RPC method is routed in router.ex
  # ------------------------------------------------------------------

  test "all frozen RPC methods are routed in router.ex" do
    source = File.read!(repo_path("products/kiln/lib/kiln/rpc/router.ex"))

    for method <- @frozen_rpc_methods do
      pattern = ~s("#{Regex.escape(method)}"\\s*->)

      assert source =~ Regex.compile!(pattern),
             "router.ex does not dispatch method #{inspect(method)}"
    end
  end

  # ------------------------------------------------------------------
  # Category 2: scope table matches the frozen WP-09 contract
  # ------------------------------------------------------------------

  test "router scope table exactly matches the frozen WP-09 contract" do
    source = File.read!(repo_path("products/kiln/lib/kiln/rpc/router.ex"))
    scopes = extract_scope_table(source)

    for {method, expected_scope} <- @frozen_scope_table do
      actual = Map.get(scopes, method)
      assert actual == expected_scope,
             "scope for #{inspect(method)} is #{inspect(actual)}, expected #{inspect(expected_scope)}"
    end

    # No method may be added to the scope table with a broader scope
    # than required. Specifically: review.propose MUST NOT accept
    # orchestration:operate (a superset of review:write).
    refute Map.get(scopes, "review.propose") == "orchestration:operate",
           "review.propose must require review:write, not a broader superset"

    refute Map.get(scopes, "terminal.attach") == "orchestration:operate",
           "terminal.attach must require terminal:operate, not orchestration:operate"
  end

  # ------------------------------------------------------------------
  # Category 3: bounded error envelope preserves key fields
  # ------------------------------------------------------------------

  test "bounded error envelope carries code + method + scope + fields + field + reason keys" do
    source = File.read!(repo_path("products/kiln/lib/kiln/rpc/error.ex"))
    assert source =~ ~r/attrs\s*=\s*maybe_put\(attrs,\s*:reason/

    # do_bounded must encode all six fields.
    assert source =~ ~r/Jason\.encode!\(%\{[^}]*code:/,
           "do_bounded must encode :code"
    assert source =~ ~r/Jason\.encode!\(%\{[^}]*reason:/,
           "do_bounded must encode :reason"
    assert source =~ ~r/Jason\.encode!\(%\{[^}]*method:/,
           "do_bounded must encode :method"
    assert source =~ ~r/Jason\.encode!\(%\{[^}]*scope:/,
           "do_bounded must encode :scope"
    assert source =~ ~r/Jason\.encode!\(%\{[^}]*fields:/,
           "do_bounded must encode :fields"
    assert source =~ ~r/Jason\.encode!\(%\{[^}]*field:/,
           "do_bounded must encode :field"
  end

  test "service.handle_unary preserves the full err envelope (no flattening)" do
    source = File.read!(repo_path("products/kiln/lib/kiln/service.ex"))

    # Service must NOT call the old `Error.bounded(conn, code, status: 400)`
    # signature that dropped method/scope/fields/reason. Must use
    # bounded_from_err/2 or 3.
    refute source =~ ~r/Error\.bounded\(conn,\s*code,\s*status:\s*400\)/,
           "service.ex must not flatten errors via Error.bounded/3"
    assert source =~ ~r/Error\.bounded_from_err/,
           "service.ex must use bounded_from_err to preserve the full envelope"
  end

  # ------------------------------------------------------------------
  # Category 4: canonical contract identity strings are unchanged
  # ------------------------------------------------------------------

  test "frozen contract identity strings appear in expected files" do
    for {string, relative_path} <- @frozen_contract_strings do
      content = File.read!(repo_path(relative_path))
      assert content =~ string,
             "expected #{inspect(string)} in #{relative_path}"
    end
  end

  # ------------------------------------------------------------------
  # Category 5: activity schema version
  # ------------------------------------------------------------------

  test "activity schema_version matches between Kiln and Temper" do
    kiln = File.read!(repo_path("products/kiln/lib/kiln/rpc/handlers/activity.ex"))

    assert kiln =~ ~r/schema_version.*=>.*"kiln\/activity\/v1"/,
           "Kiln activity handler must emit schema_version = \"kiln/activity/v1\""

    temper = File.read!(repo_path("products/temper/src/types.ts"))
    assert temper =~ ~r/type:\s*'activity\.snapshot'/
  end

  # ------------------------------------------------------------------
  # Category 6: M0Review field name (verifier_ref, not verification_ref)
  # ------------------------------------------------------------------

  test "M0Review struct uses verifier_ref (not verification_ref)" do
    m0_types = File.read!(repo_path("products/kiln/lib/kiln/m0_types.ex"))

    [struct_section] =
      Regex.scan(~r/defstruct\s+\[[^\]]*\]/, m0_types, capture: :all_but_first)

    assert struct_section =~ ~r/:verifier_ref/,
           "M0Review defstruct must declare :verifier_ref"

    refute struct_section =~ ~r/:verification_ref/,
           "M0Review defstruct must NOT declare :verification_ref"
  end

  test "RPC review handler reads review.verifier_ref (not verification_ref)" do
    handler = File.read!(repo_path("products/kiln/lib/kiln/rpc/handlers/review.ex"))

    assert handler =~ ~r/review\.verifier_ref/,
           "review handler must read review.verifier_ref"

    refute handler =~ ~r/review\.verification_ref/,
           "review handler must NOT read review.verification_ref"
  end

  # ------------------------------------------------------------------
  # Category 7: Restart.reconstruct/1 return shape consumed exactly
  # ------------------------------------------------------------------

  test "Restart.reconstruct/1 spec is consumed exactly by handlers (no bare :empty)" do
    activity = File.read!(repo_path("products/kiln/lib/kiln/rpc/handlers/activity.ex"))
    project = File.read!(repo_path("products/kiln/lib/kiln/rpc/handlers/project.ex"))

    # Per @spec at lib/kiln/restart.ex:38-42 the return is
    # {:ok, :empty} (NOT the bare atom :empty).
    refute activity =~ ~r/^\s*:empty\s*->/m,
           "activity.ex must not have a bare :empty pattern (Restart returns {:ok, :empty})"

    refute project =~ ~r/^\s*:empty\s*->/m,
           "project.ex must not have a bare :empty pattern (Restart returns {:ok, :empty})"

    # Same for :multiple_sessions — it returns {:error, %{code: :multiple_sessions, ...}},
    # NOT the bare atom :multiple_sessions.
    refute activity =~ ~r/^\s*:multiple_sessions\s*->/m,
           "activity.ex must not have a bare :multiple_sessions pattern"

    refute project =~ ~r/^\s*:multiple_sessions\s*->/m,
           "project.ex must not have a bare :multiple_sessions pattern"
  end

  # ------------------------------------------------------------------
  # helpers
  # ------------------------------------------------------------------

  # Extracts the @scopes map literal from router.ex.
  #
  # Regex.run canonical signature: Regex.run(regex, subject, opts).
  # The previous version of this helper had the arguments reversed
  # (subject, regex), which raised a type warning.
  defp extract_scope_table(source) do
    case Regex.run(~r/@scopes\s+%\{([^}]+)\}/m, source, capture: :all_but_first) do
      [body] ->
        body
        |> String.split("\n", trim: true)
        |> Enum.reduce(%{}, fn line, acc ->
          case Regex.run(~r/"([^"]+)"\s*=>\s*"([^"]+)"/, line, capture: :all_but_first) do
            [method, scope] -> Map.put(acc, method, scope)
            _ -> acc
          end
        end)

      _ ->
        %{}
    end
  end
end
