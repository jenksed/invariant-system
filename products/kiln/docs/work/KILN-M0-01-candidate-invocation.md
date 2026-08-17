# KILN-M0-01

**Document type:** Implementation plan
**Status:** Accepted (Pass-04 refined work package, byte-exact copy of program/recursive-planning/pass-04/planning/30-day/work-packages/KILN-M0-01.md)
**Branch:** `m0/kiln-01-candidate-invocation`
**Owner domain:** Kiln
**Merge gate:** M3
**Base condition (monorepo merge gate):** M1 (SYS-M0-00, `18f5c9e`) and M2 (SYS-M0-01, `73a62ef`) and M2-merge (`9adcd1f`) and governance commit (`587867c`) all merged on canonical `main` before this branch opens.
**Contract versions:** `engineering-system/candidate-invocation/m0-v1` (M0 packet byte-exact, ratified at M2 under `contracts/m0/schemas/candidate-invocation.m0-v1.schema.json`).

## ID
`KILN-M0-01`

## OWNER DOMAIN
Kiln

## OBJECTIVE
Implement the canonical Candidate Invocation contract for the MiniMax M3 runtime as
one adapter identity usable in production and evaluation modes, expose the exact
adapter implementation digest, provide the bounded CLI invocation surface Bench will
consume, and repair the dead verification-registry registration (RISK B).

## START GATE
SYS-M0-01 merged (M2). `contracts/m0/schemas/candidate-invocation.m0-v1.schema.json`
present. Worktree based on `main` at M2.

## CONSUMES
- `contracts/m0/schemas/candidate-invocation.m0-v1.schema.json` (read-only)
- `contracts/m0/schemas/worker-output.m0-v1.schema.json` (read-only)
- Pass-02 PROFILE-CONTRACT, EVALUATION-RUNTIME-CONTRACT, CONTEXT-DISCLOSURE-POLICY
- existing Kiln substrate: `Kiln.Conformance.Provider` behaviour
  (`lib/kiln/conformance/provider.ex`), `Kiln.Conformance.FirstMonth` constants,
  `Kiln.Evidence` (producer kinds already include `:provider`),
  `Kiln.Journal.Entry` (operation class `model_invocation` already reserved),
  `Kiln.Artifact`, `Kiln.Store.Canonical`, `Kiln.CLI` dispatch
- ADR-0021/0023 (`products/kiln/docs/decisions/`) for the MiniMax M3
  OpenAI-compatible boundary

## PRIMARY PATHS
- `products/kiln/lib/kiln/candidate_invocation.ex` (new)
- `products/kiln/lib/kiln/minimax_m3_adapter.ex` (new)
- `products/kiln/lib/kiln/verification/registry.ex` (edit: RISK B repair)
- `products/kiln/test/kiln/m0_candidate_invocation_test.exs` (new)
- `products/kiln/test/kiln/verification/registry_paths_test.exs` (new)

## ALLOWED SUPPORTING PATHS
- `products/kiln/lib/kiln/cli.ex`, `products/kiln/lib/kiln/cli/request.ex`,
  `products/kiln/lib/kiln/cli/error_map.ex` (add the two new commands below)
- `products/kiln/docs/` (one implementation note)

## FORBIDDEN PATHS / CHANGES
- no new Mix dependency (HTTP via OTP `:httpc` only; if `:httpc` is demonstrably
  insufficient for streaming SSE, STOP — do not add `req`/`finch` unilaterally)
- no fallback/retry/provider substitution logic
- no Manifold selection logic, no shell authority, no mutation authority
- `contracts/**`, `integration/**`, other products
- no edits to existing verification registry entries other than E3 below

## EXPECTED EDITS (exact)

### E1. `Kiln.CandidateInvocation` (new module)
- Typed struct + validation for `engineering-system/candidate-invocation/m0-v1`
  requests and results, mirroring the ratified schema fields exactly (request:
  profile ref `{id, digest}`, mode `production|evaluation`, compiled context
  manifest ref, bounded tool policy ref, timeout; result: terminal status per the
  frozen failure taxonomy — pre-dispatch unavailable/denied, timeout,
  terminal result, connection-lost/unknown, malformed output, policy rejection).
- Canonical encoding + `semantic_digest` per P02-D013 (reuse
  `Kiln.Store.Canonical` rules: sorted keys, compact UTF-8).

### E2. `Kiln.MinimaxM3Adapter` (new module)
- `@behaviour Kiln.Conformance.Provider` (`stream/2`, `cancel/1`).
- Single endpoint `https://api.minimax.io/v1/chat/completions`
  (OpenAI-compatible chat completions), streaming, reasoning split, standard
  service tier — per PROFILE-CONTRACT.
- Credential: reads ONLY the presence of env var `MINIMAX_API_KEY` through one
  private credential-resolution function; the value never enters Context,
  Artifact, Evidence, manifests, logs, or result payloads (negative-tested).
- `evaluation` vs `production` mode changes authority/limits only; adapter
  identity (module, endpoint family, contract version) is identical (P02-D020).
- No retry, no fallback, no alternate provider; unavailable → terminal
  `E_RUNTIME_UNAVAILABLE` result.
- `implementation_digest/0`: `"sha256:" + lowercase_hex(sha256(source_bytes(this file)
  <> source_bytes(candidate_invocation.ex) <> candidate-invocation schema digest))`.
  Source bytes are read from the compile-time `__DIR__` relative paths; digest is
  stable across BEAM rebuilds unless source changes.

### E3. RISK B repair — `lib/kiln/verification/registry.ex`
- REMOVE the entry `"arsenal.wave6-benchmark" => {"project-arsenal", "python3",
  ["scripts/test-wave6-verify-bench.py"]}` (registry.ex lines 21–22).
  Justification (recorded in Pass-04 SUPERSESSION): the referenced script does not
  exist anywhere in the monorepo (verified at baseline); no test or caller selects
  this command id (grep-verified); `MIGRATION-REPORT.md` records it as a
  pre-existing source inconsistency. Removing a registration for a nonexistent
  verifier is the minimal deterministic repair; repointing to a "nearby" verifier
  is forbidden.
- No other registry entry changes.

### E4. CLI surface (for Bench consumption and operator preflight)
- Add to `@supported_commands` in `lib/kiln/cli/request.ex`:
  - `:candidate_invocation_digest` → prints `{"adapter_implementation_digest": ...}`
  - `:candidate_invocation` with `--request <path> --mode production|evaluation`
    → executes ONE bounded invocation and returns the canonical result JSON.
- Wire through `Kiln.CLI` dispatch + `Kiln.CLI.ErrorMap` following the existing
  `:supervise` command pattern.

### E5. Tests
- `test/kiln/m0_candidate_invocation_test.exs`:
  - schema-conforms a golden request/result pair (fixture-derived);
  - digest stability: `implementation_digest/0` identical across two calls;
  - NEGATIVE runtime-unavailable: no credential present → terminal
    `E_RUNTIME_UNAVAILABLE`, no dispatch attempted;
  - NEGATIVE provider-substitution: request profile digest ≠ adapter-bound profile
    digest → rejected before dispatch (`E_PROFILE_SUBSTITUTION`);
  - NEGATIVE secret-disclosure: with a sentinel credential value set, assert the
    value string appears in NO result/manifest/evidence bytes;
  - all network-independent (no live HTTP in unit tests; streaming client behind
    a function pointer/mocked `:httpc` wrapper is bounded implementation
    discretion).
- `test/kiln/verification/registry_paths_test.exs`:
  - for every `@commands` entry whose argv references a repo-relative script path,
    the path exists on disk (prevents RISK B recurrence);
  - removing a script file in a tmp copy makes the test fail (self-test optional).

## TEST COMMANDS
- `cd products/kiln && mix test test/kiln/m0_candidate_invocation_test.exs test/kiln/verification/registry_paths_test.exs`
- `./invariant test kiln` (jsonschema available — see SOURCE-PREFLIGHT)
- `./invariant check boundaries`

## EVIDENCE PRODUCED
- adapter implementation digest value (recorded in closeout; consumed by BENCH-M0-01)
- Candidate Invocation conformance test log
- registry diff showing only the dead-entry removal
- `./invariant test kiln` transcript

## STOP CONDITIONS
- implementation requires fallback/retry or a new Mix dependency
- a secret must enter Context/Artifact/Evidence to function
- evaluation and production cannot share exact adapter identity
- the candidate-invocation schema appears to need a semantic change

## DOWNSTREAM UNLOCKS
BENCH-M0-01 (adapter digest + CLI invocation surface); KILN-M0-02 (worker invocation)

## COLLISION CLASSIFICATION
KILN-CORE — serialized within LANE-KILN; `registry.ex` also read by KILN-M0-03
later (no overlap in time)

## MERGE GATE
M3: rebase on M2; TEST COMMANDS green; integration authority merges.

## SCOPE CLASS
MUST

## CURRENT IMPLEMENTATION STATUS
PARTIALLY_IMPLEMENTED (behaviour + substrate exist; adapter/invocation greenfield)
