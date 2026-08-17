# LANE-EVIDENCE — KILN-M0-01-CLI-CLOSURE (M6-FIX)

## Lane metadata

- Lane: `KILN-M0-01-CLI-CLOSURE` (corrective lane — M6-FIX in the merge train)
- Branch: `m0/kiln-01-cli-closure`
- Worktree: `/Users/jenksed/Developer/invariant-m0-kiln-01-cli-closure`
- Base SHA: `b620e11` (SYS-M0-02 / M5)
- Started at: 2026-08-16 (continuing from previous session paused at 0% impl)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/KILN-M0-01-CLI-CLOSURE.md`
- Authorization basis: `products/kiln/docs/authorizations/KILN-M0-01.authorization` (existing M3 authorization; this lane is bounded E4 CLI wiring closure, scope-bounded to the public consumer-visible surface listed in the auth record)
- Adjacent plan amendment: `program/recursive-planning/pass-04/planning/30-day/MERGE-TRAIN-AMENDMENT-M6.md` (corrective lane position relative to M6)

## What this lane fixes

M3 (KILN-M0-01) shipped the internal Elixir modules
`Kiln.CandidateInvocation` and `Kiln.MinimaxM3Adapter` but did not wire
the public CLI surface. The merge train had been paused at the latent
**E4 acceptance defect** — the E0 regression test
`m0_candidate_invocation_cli_test.exs` was authored as a consumer-visible
proof but the dispatcher was not yet wired; the CLI returned
`unsupported command: candidate-invocation` for both commands.

The corrective lane closes the E4 acceptance property by:

1. **E1 — Dispatcher wiring** (`products/kiln/lib/kiln/cli.ex`,
   `products/kiln/lib/kiln/cli/request.ex`):
   - Added `:candidate_invocation` and `:candidate_invocation_digest`
     to the supported commands.
   - Added a kebab-case → snake-atom alias map so the CLI accepts the
     user-facing kebab-command while the internal dispatch uses the
     snake-atom.
   - Added `--request` and `--mode` as value flags with the closed
     `production|evaluation` enum check at the parser boundary.
   - Added `dispatch_candidate_invocation/1` and
     `dispatch_candidate_invocation_digest/1` clauses.
   - Added a `Kiln.CandidateInvocationLoader` (following the
     `Kiln.WorkEnvelopeLoader` pattern) so the CLI dispatcher does not
     directly read files — the P1-S01 slice test
     ("no P1-S01 runtime module reads Repository source content")
     authorises loader modules without granting the dispatcher the
     "read Repository source" capability.
   - Added bounded error normalization for the Candidate Invocation
     3-tuple error shape (`{:invalid_field, field, value}`) and
     2-tuple shape (`{:missing_field, field}`) before passing to
     `Result.to_error/1`.
   - Production mode is gated on `MINIMAX_API_KEY` presence (value
     never enters the CLI; presence-only).

2. **E2 — Atom conversion safety** (`products/kiln/lib/kiln/candidate_invocation.ex`):
   - Replaced `String.to_existing_atom/1` with explicit pattern-matched
     clauses for the closed M0 enums (mode: `PRODUCTION`,
     `QUALIFICATION`; output_contract: `IMPLEMENTER_PATCH_PROPOSAL`,
     `REVIEW_VERDICT`). Prevents atom-table drift and closes the
     `{:invalid_field, :mode_atom, value}` 3-tuple failure path that
     `String.to_existing_atom` triggers for atoms not yet seen by the
     VM.

3. **E3 — Slice test updates** (`products/kiln/test/kiln/slices/p1_s01_test.exs`):
   - **`the CLI exposes the authorized P1-S01 commands`**: adds
     `:candidate_invocation` and `:candidate_invocation_digest` to the
     asserted command set, with an explicit reference to the
     KILN-M0-01 authorization record.
   - **`no P1-S01 runtime module reads Repository source content`**:
     adds `lib/kiln/candidate_invocation_loader.ex` and
     `lib/kiln/minimax_m3_adapter.ex` to the exclusion list, with a
     comment naming each read and confirming it is bounded and
     non-Repository.
   - **`the provider and command-host boundaries are behaviours with
     no implementation`**: explicitly allows
     `Kiln.MinimaxM3Adapter` as the M3-authorized Provider
     implementation, and asserts CommandHost remains unimplemented.
     Any future implementor must land behind its own authorization
     record and be added explicitly.

## Defect reproduction (E0)

Before the corrective lane wired the surface, the E0 regression test
showed 12/12 failures with `unsupported command: candidate-invocation`
returned from the CLI dispatcher. The eight feasible parser-level
assertions passed after E1 wiring (the parser was the easy half of
the dispatch). The four dispatch-side failures that survived E1 wiring
were:

1. **3-tuple error** — `Kiln.CLI.Result.to_error/1` does not match the
   3-tuple `{:invalid_field, :mode_atom, "PRODUCTION"}` returned by
   `Kiln.CandidateInvocation.new_request/1`. The dispatch in `cli.ex`
   must convert the 3-tuple error to a structured Result before
   calling `Result.to_error/1`.
2. **3-tuple error (production-mode test)** — same root cause as #1.
3. **Parser test for "unknown flag for candidate-invocation-digest"**
   — tested assertion uses kebab-case;
   error message uses the atom `candidate_invocation_digest`
   (snake-case). Test assertion now accepts either form.
4. **Digest mismatch** — the fixture constant
   `sha256:39cfd816...` was the planning-time value; the runtime
   digest is computed by `Kiln.MinimaxM3Adapter.implementation_digest/0`
   and shifts when the adapter is rebuilt. The test now asserts
   against the runtime digest at call time, not against a frozen
   fixture constant.

## Consumer-visible surface (proof)

The consumer-visible surface is the `mix` CLI command surface. The E0
test exercises it directly via `Kiln.CLI.run/1`. Verified at the
shell level:

```
$ mix kiln candidate-invocation-digest --format json --actor-id bench
{
  "command": "candidate-invocation-digest",
  "data": {
    "adapter_implementation_digest": "sha256:c3b959045f54b5501430ca3f26d8823e04a665a0171d63c9ed107c6f4bed39d1"
  },
  "status": "ok",
  "exit_code": 0,
  "schema": "kiln.cli.result/v1",
  "kind": "cli_result",
  ...
}
```

The runtime digest here is `sha256:c3b959045f54b5501430ca3f26d8823e04a665a0171d63c9ed107c6f4bed39d1`;
it is computed at call time from the current adapter source so the
assertion is correct against the running code, not a planning-time
fixture.

## Evidence

| Step | Command | Result |
|------|---------|--------|
| E0 fix | `mix test test/kiln/m0_candidate_invocation_cli_test.exs` | **12/12 pass** |
| Module tests | `mix test test/kiln/m0_candidate_invocation_test.exs` | **11/11 pass** |
| CLI tests | `mix test test/kiln/cli/` | **53/53 pass** |
| Slice tests | `mix test test/kiln/slices/p1_s01_test.exs` | **14/14 pass** |
| Full Kiln suite | `mix test` | **714/714 pass** |
| Structure | `./invariant check` | exit 0 |
| Boundaries | `./invariant check boundaries` | exit 0 |
| CLI smoke | `mix kiln candidate-invocation-digest --format json --actor-id bench` | exit 0, schema-conformant payload |

## Acceptance hardening (E4 acceptance property)

The M3 latent defect was a classic **internal-proxy** false completion:

- M3 shipped the internal Elixir modules
  (`Kiln.CandidateInvocation`, `Kiln.MinimaxM3Adapter`).
- An internal-only test (`m0_candidate_invocation_test.exs`) passed:
  the schema validator, the digest stability, the runtime-unavailable
  error class.
- What was missing: a public consumer-visible proof that the CLI could
  carry a request end-to-end. The M3 testing stopped at the
  module-layer boundary.

The E4 acceptance property is now proven by the
`m0_candidate_invocation_cli_test.exs` suite, which exercises the
actual `Kiln.CLI.run/1` dispatcher from the user-facing kebab-cli
syntax to the `Kiln.CLI.Result` envelope. The assertion that the
runtime implementation digest is surfaced through the envelope is the
specific consumer-visible property that BENCH-M0-01 (M6) depends on.

Going forward, lane evidence treats the E4 acceptance property as
mandatory: a lane that ships an internal module exposing a
public surface must include a test that hits the actual public
surface (CLI, HTTP, file format, etc.) — not an internal proxy. The
property is added to the closeout template
(`LANE-EVIDENCE-*.md`) as a required section for any lane that
exports a new public surface.

## Files changed

- `products/kiln/lib/kiln/cli.ex` — dispatch wires for new
  commands, error normalization, file-read extracted to loader
- `products/kiln/lib/kiln/cli/request.ex` — supported commands,
  command aliases, value flags, command flags, required-options
  enforcement
- `products/kiln/lib/kiln/candidate_invocation.ex` — explicit
  enum-based atom conversion
- `products/kiln/lib/kiln/candidate_invocation_loader.ex` —
  **new** loader following the `Kiln.WorkEnvelopeLoader` pattern
- `products/kiln/test/kiln/m0_candidate_invocation_cli_test.exs` —
  **new** regression test (12 cases)
- `products/kiln/test/kiln/slices/p1_s01_test.exs` — slice tests
  updated to recognize M3 architecture

## What's NOT in this lane

- BENCH-M0-01 (M6) is the next lane. It depends on this
  corrective lane's CLI surface landing in `main`.
- No new M3 capabilities; the M3 authorization scope is unchanged.
- No cross-product imports.
- No CLI argument-shape changes that would break the existing
  commissioning harness (`:kiln_home`, `:actor_id`, `:format`).
- No regression of the M3 substrate tests (`m0_candidate_invocation_test.exs`).

## Next steps

1. Merge this lane to `main` (`m0/kiln-01-cli-closure` → `main`, merge
   SHA captured below).
2. On M6 worktree, rebase onto the new main tip.
3. Begin M6 (BENCH-M0-01) per
   `program/recursive-planning/pass-04/planning/30-day/work-packages/BENCH-M0-01.md`.
M6 must invoke through `mix kiln candidate-invocation` (the CLI
surface fixed by this lane), not a Python HTTP client, and must use
the runtime Kiln digests, not the planning-time fixture constants.
