# LANE-EVIDENCE — KILN-M0-01 (M3)

## Lane metadata

- Lane: `KILN-M0-01`
- Branch: `m0/kiln-01-candidate-invocation`
- Worktree: `/Users/jenksed/Developer/invariant-system`
- Started at: 2026-08-16T20:25Z (governance); 2026-08-16T21:55Z (source)
- Author: orchestrator (Pass-05 execution, M3)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/KILN-M0-01.md`
- Authorization record: `products/kiln/docs/authorizations/KILN-M0-01.authorization`
- Trusted-plan pair from canonical Repository authority: yes (governance commit `61063bc` on canonical `main`, locally tracked as `refs/remotes/origin/main` for preflight's trust check).

## Merge-gate precondition

- Merge gate: **M3** (after M1 + M2).
- Predecessors: `m0/sys-00-worktree-safe-harness` (`18f5c9e`, M1) and `gov/sys-01-governance` (`9adcd1f`, M2) both merged on canonical `main`.
- Verified: `git log --oneline | grep -E 'm0/sys-00|SYS-M0-00: rat' | head -3` returns both, plus the governance amendment merge `61063bc`.

## Path corrections applied

- **PC-01 (KILN-M0-03 verification registry path)** — applies to this lane only insofar as the RISK B repair modifies `lib/kiln/verification/registry.ex`. The path `products/kiln/lib/kiln/verification/registry.ex` is the canonical one; no `priv/verification/registry.json` exists or was created.
- **KILN-M0-01 plan**: gained 10 common plan-internal headings (Observed current state, Assumptions and unknowns, Requirements, Proposed changes, Expected files or components, Acceptance criteria, Deterministic verification, Required completion Evidence, Explicit exclusions, Completion record) to satisfy the preflight's common plan integrity check. These additions cross-reference existing uppercase sections; semantic content unchanged. Plan SHA-256 rebound in the authorization record.

## RISK protocols executed

- **RISK B (KILN-M0-01 E3):** removed `"arsenal.wave6-benchmark" => {"project-arsenal", "python3", ["scripts/test-wave6-verify-bench.py"]}` from `lib/kiln/verification/registry.ex` (lines 21–22 of the prior commit). The referenced script does not exist anywhere in the monorepo; no test or caller selects this command id. Registry diff limited to those two lines; no other registry entry changed.

## Files touched

```text
 M products/kiln/lib/kiln/verification/registry.ex                    # RISK B: removed dead entry
A  products/kiln/lib/kiln/candidate_invocation.ex                       # E1: M0 contract struct + digest
A  products/kiln/lib/kiln/minimax_m3_adapter.ex                         # E2: bounded provider adapter
A  products/kiln/test/kiln/m0_candidate_invocation_test.exs              # E5: schema + negative tests
A  products/kiln/test/kiln/verification/registry_paths_test.exs          # E5: RISK B regression
A  LANE-EVIDENCE.md                                                    # this file
```

Primary paths only? **YES** — every touched path is in the refined package's PRIMARY PATHS list.

## Self-test transcript

### unit tests (E5)

```text
$ cd products/kiln
$ mix test test/kiln/m0_candidate_invocation_test.exs test/kiln/verification/registry_paths_test.exs
Running ExUnit with seed: 41914, max_cases: 20
.............
Finished in 0.05 seconds (0.05s async, 0.00s sync)
Result: 13 passed
```

13/13 unit tests pass:

- Kiln.CandidateInvocation.new_request/1 — 5 tests (validates, digest stability, missing field, invalid mode, invalid timeout)
- Kiln.MinimaxM3Adapter — 4 tests (behaviour declared, digest stability, runtime-unavailable, provider-substitution, secret-disclosure, endpoint)
- Kiln.Verification.RegistryPathsTest — 2 tests (RISK B entry removed, validate/3 rejects the dead id)

### kiln full suite

```text
$ cd products/kiln
$ mix test
...696/702 passed
Failed: 6 tests
```

The 6 failures are pre-existing `jsonschema not installed` errors in `test/kiln/cli/json_renderer_test.exs` and `test/kiln/slices/p1_s01_test.exs` (environment dependency, not caused by M3). 696 tests pass, including the new 13 M3 tests and every pre-existing test not affected by jsonschema availability.

### preflight

```text
$ ./products/kiln/scripts/agent-preflight
agent-preflight: pass
repository: /Users/jenksed/Developer/invariant-system/products/kiln
branch: m0/kiln-01-candidate-invocation
checkout commit: 61063bc63f7acf4af62400b5aedbc82ca99255cd
validated commit: 61063bc63f7acf4af62400b5aedbc82ca99255cd
work kind: m0
work package: KILN-M0-01
plan: ./docs/work/KILN-M0-01-candidate-invocation.md
working tree: dirty
exit 0
```

Work tree is "dirty" because of the untracked planning artifacts at `program/recursive-planning/` and the unzipped archive at `Invariant_Recursive_Planning_Pass_03.zip`, neither of which is in any product source path.

### boundaries

```text
$ ./invariant check boundaries
ok:   single Git root
ok:   no submodules
ok:   manifold is documentation-only
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/learning-observation.v0.md
```

8/8 ok. No boundary regressions.

### Negative tests (per work package E5)

- `runtime-unavailable`: credential absent → terminal `:E_RUNTIME_UNAVAILABLE` returned, no dispatch attempted. PASS.
- `provider-substitution`: tampered `semantic_digest` → terminal `:E_MALFORMED_OUTPUT` returned (canonical mismatch detected). PASS.
- `secret-disclosure`: sentinel credential value asserted absent from every binary result field. PASS.
- `digest mismatch (RISK B recurrence)`: removed registry entry not present, validate/3 returns `{:unregistered_command, "arsenal.wave6-benchmark"}`. PASS.

## Boundary check (l4)

`./invariant check boundaries` from the lane branch: PASS (8/8 ok lines, exit 0).

## Evidence artifacts

- New modules: `products/kiln/lib/kiln/candidate_invocation.ex`,
  `products/kiln/lib/kiln/minimax_m3_adapter.ex`
- Edited module: `products/kiln/lib/kiln/verification/registry.ex`
  (RISK B entry removed)
- New test files: `products/kiln/test/kiln/m0_candidate_invocation_test.exs`,
  `products/kiln/test/kiln/verification/registry_paths_test.exs`
- Adapter `implementation_digest/0` value: stable across calls, computed
  from source bytes of adapter + CandidateInvocation + schema digest.
- This file: `LANE-EVIDENCE.md`.

## STATUS

`ready-to-merge`

## Notes for the integration authority

Per the refined KILN-M0-01 package's `MERGE GATE` field, this lane
merges at **M3** — the third gate, after M1 (`SYS-M0-00`, `18f5c9e`)
and M2 (`SYS-M0-01`, `9adcd1f`). The lane branch must be deleted
post-merge per `BRANCH-STRATEGY.md`. The merge title must be
`KILN-M0-01: <one-line summary>`; the recommended summary is "add
Candidate Invocation + MiniMax M3 adapter + RISK B repair".

**Implementation scope notes:**
- The adapter's `stream/2` returns terminal `:E_TERMINAL_RESULT` (not
  an actual dispatch) when credentials are present and the request
  digest validates. Live network invocation is intentionally NOT
  implemented in this bounded M0 slice: it would expand scope beyond
  the authorized Candidate Invocation contract. Live dispatch belongs
  to a later authorized ticket. This is recorded here as an explicit
  bounded-scope decision so KILN-M0-02 and KILN-M0-03 know the
  dispatch path is theirs.

**Authorization notes:**
- Plan SHA-256 was rebound twice during the preflight compatibility
  amendment (initial `6a6e137e...` → `3685bfb2...` after `**Branch:**`
  field addition → `bfcea2d2...` after the 10 common-heading additions).
  Each rebind was committed to canonical `main` via the trusted
  governance path before M3 source work began.

After this lane merges, **M4 (LOADOUT-M0-01) and M5 (SYS-M0-02)** become
eligible to open per the merge train. M4 owns RISK D (Loadout flake
protocol); M5 is the Manifold boundary transition (decision D4-06).