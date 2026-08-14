# P4-W01: Wave 6 Registered Verification Execution

**Document type:** Implementation plan
**Status:** Accepted
**Parent slice:** Wave 6 Verify This Change
**Branch:** `work/p4-w01-kil-w6-registered-verification`
**Depends on:** Wave 3 supervision merged at `bd2c9bc`; owner-issued Wave 6 prompt dated 2026-08-13

## Objective

Extend the existing Work Envelope supervision path with the narrowest real
execution model for the immutable registered verification commands carried by
a Loadout Verify This Change Plan. Kiln validates the request, decides exact
command authority, executes without a shell, persists stdout/stderr and command
results as Artifacts, binds Evidence to declared proof obligations, computes
truthful readiness, and reconstructs the same facts after restart.

## Observed current state

| Observation | Evidence | Date |
| --- | --- | --- |
| Wave 3 Work Envelope supervision is on canonical main | `bd2c9bc` | 2026-08-13 |
| Artifact, Evidence, Run, authority, and restart reconstruction exist | `lib/kiln/supervision.ex` | 2026-08-13 |
| Current authority accepts only Repository Recon `git.read` | `lib/kiln/authority.ex` | 2026-08-13 |
| Command host behavior is specified but not implemented | `lib/kiln/conformance/command_host.ex` | 2026-08-13 |
| Accepted ADR requires process-group command isolation without a shell | ADR 0026 | 2026-08-13 |

## Assumptions and unknowns

- The existing Run Result Envelope v0 can represent command effects, Evidence,
  proof-obligation status, unknowns, and readiness without contract evolution.
- Loadout supplies a content-addressed `loadout/verification-change/v0`
  projection beside the Work Envelope; Kiln validates its digest against the
  Work Envelope context reference.
- Toolchain network isolation is not claimed when the registered command does
  not require network and the host does not provide an enforcement primitive.
- Temper can inspect the generic Run Result fields without importing Wave 6
  method-development internals; richer command-to-obligation projection is an
  opportunity, not required implementation.

## Requirements

- **P4-W01-R01:** Accept only `verify-change` plus the existing
  `repository-recon`; do not add generic capability dispatch.
- **P4-W01-R02:** Parse and validate the verification projection, including
  exact base/current state, patch digest, obligations, selected/skipped checks,
  method provenance, and unknowns.
- **P4-W01-R03:** Verify projection content digest, Work Envelope authority
  requests, obligations, repository, and current state before execution.
- **P4-W01-R04:** Resolve command identity through a Kiln-owned static registry.
  Reject executable/argv/cwd/timeout/policy differences and unknown commands.
- **P4-W01-R05:** Execute exact argv with no shell, a fixed repository cwd,
  bounded timeout, separate stdout/stderr capture, and no caller-controlled
  executable beyond the validated registry entry.
- **P4-W01-R06:** Persist request, stdout, stderr, and command result Artifacts;
  create Evidence that binds only each command's declared proof obligations.
- **P4-W01-R07:** A failed, timed-out, denied, corrupt, incomplete, or stale
  command cannot produce READY.
- **P4-W01-R08:** Re-observe repository state around execution and fail closed
  on mid-run state change.
- **P4-W01-R09:** Replay of the same work/request returns the same historical
  Run; conflicting request data for one work id is rejected.
- **P4-W01-R10:** Restart reconstruction retains change identity, authority,
  command Artifacts, Evidence, obligations, unknowns, and readiness.

## Proposed changes

1. Add a verification projection validator and deterministic content digest.
2. Add a fixed command registry covering the Wave 6 Arsenal, Loadout, Kiln,
   Temper dogfood commands.
3. Add a no-shell command host using exact executable plus argv, bounded timeout,
   process-group termination, and separate output capture.
4. Route `verify-change` through a focused verification supervisor while
   preserving Repository Recon behavior.
5. Persist command facts through the existing Artifact/Evidence substrate and
   reconstruct the canonical Run Result from those durable facts.
6. Add fail-closed unit, integration, CLI, restart, and negative tests.

## Expected files or components

| Path or component | Expected change |
| --- | --- |
| `lib/kiln/verification/*` | Request, registry, command host, evaluation |
| `lib/kiln/authority.ex` | Exact registered verification authority |
| `lib/kiln/supervision.ex` | Capability routing and durable result assembly |
| `lib/kiln/cli*.ex` | `--verification-change` intake |
| `test/kiln/verification/*` | Positive and fail-closed cases |
| `test/kiln/supervision_restart_regression_test.exs` | Wave 6 restart truth |

## Acceptance criteria

- A real registered passing command creates durable stdout/stderr/result
  Artifacts and obligation-specific Evidence.
- A required failing command yields NOT READY and never satisfies its obligation.
- Unknown/incomplete obligations yield NOT READY with a specific reason.
- Unregistered commands and shell escape attempts are rejected before spawn.
- Stale/tampered input, denied authority, unavailable Kiln, corrupt Artifact,
  mid-run repository change, and replay conflict fail closed.
- Restart reconstructs semantically identical historical truth.
- Existing Repository Recon supervision remains green.

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
scripts/validate-agent-assets
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

## Required completion Evidence

| Evidence ID | Required fact |
| --- | --- |
| P4-W01-E01 | Registry rejects unknown or altered command definitions |
| P4-W01-E02 | Real passing and failing commands produce truthful durable facts |
| P4-W01-E03 | Obligations determine readiness; run completion does not |
| P4-W01-E04 | Restart reconstruction preserves Wave 6 truth |
| P4-W01-E05 | Four real product dogfood Runs and self-hosting proof |

## Explicit exclusions

- Generic shell authority or caller-defined executables.
- General policy engine, agent runtime, orchestration, or plugin system.
- Loadout or Arsenal runtime imports.
- Temper redesign.
- QMR v0 repair.
- Wave 7.

## Completion record

**Result:** Pending implementation and current Evidence.

## Slice contribution

Provides only the Kiln execution/evidence portion of the owner-directed Wave 6
Verify This Change milestone.

## Security boundary

Kiln owns the static registry and exact execution policy. Loadout may request a
known command identity but cannot provide shell text, change executable/argv,
escape the repository cwd, widen environment/network policy, or bind a passing
command to an unrelated obligation.

## Demo contribution

Runs a real Verify This Change Plan, shows NOT READY for a missing or failed
obligation, supplies the missing proof, shows READY, restarts Kiln, and
reconstructs the same truth for Temper.
