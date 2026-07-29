# P0-W24: Command execution, Evidence, Artifacts, Receipts, and acceptance

**Document type:** Focused planning work package  
**Status:** Implemented and verified on branch  
**Branch:** `work/p0-w24-command-evidence-acceptance`  
**Depends on:** P0-W21 through P0-W23 and OD-02 integrated  
**Scope:** Registered Command execution, macOS process ownership, output Artifacts, criterion Evidence, Receipt aggregation, user acceptance, and completion blocking only  
**Build authorization:** Not issued

## Objective

Define one non-shell registered Command path and one truthful proof path from execution through criterion-bound Evidence, user acceptance, completion, and Receipt delivery.

## Accepted planning decisions

P0-W24 proposes:

1. Execute only versioned registered Commands.
2. Use absolute executable identity, validated argv, registered cwd, and a minimal constructed environment.
3. Prohibit shell strings, interpolation, arbitrary model Commands, and full environment inheritance.
4. Use one active Command on the OD-02 host.
5. Use a small bundled macOS helper to create and control a new process group.
6. Use SIGTERM, five-second grace, SIGKILL, five-second grace, and final group probe for timeout and cancellation.
7. Classify unproved descendant cleanup as unknown under P0-W21.
8. Capture bounded stdout and stderr and externalize retained output as immutable Artifacts.
9. Retain first-month Artifacts, Evidence, evaluations, and Receipts without automatic deletion.
10. Bind Evidence to one criterion, exact Repository state, host profile, method, and observations.
11. Keep status, freshness, completeness, and contradiction separate.
12. Require every required criterion to be current, complete, non-contradicted, and passing.
13. Treat exit zero, model confidence, summaries, and Receipts as insufficient proof by themselves.
14. Bind user acceptance to the exact current aggregate evaluation.
15. Preserve P0-W21 as the sole atomic completion owner.
16. Seal the Receipt after completion; Receipt failure blocks delivery and the aggregate demo, not committed completion truth.

## Files changed

- `docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md`
- `docs/decisions/0026-use-registered-process-group-commands-on-macos.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W24-command-evidence-acceptance.md`

Review-head compare against `main`:

- five Markdown files;
- 1,172 additions and 56 deletions;
- no production source, tests, dependencies, configuration, JSON Schemas, CI, scripts, preflight, Skills, prompts, agents, helper binary, or scaffolding.

## Acceptance evidence

| Criterion | Result | Evidence |
| --- | --- | --- |
| Registered Command and Worker contract | Pass | Command sections 2 and 3 |
| macOS process-group launch and cleanup | Pass | process helper and cancellation sections |
| Argument, environment, cwd, write, network, secret, and output rules | Pass | registration and policy sections |
| Artifact capture, integrity, trust, sensitivity, completeness, and retention | Pass | Artifact section |
| Criterion-bound Evidence and exact state binding | Pass | Evidence section |
| Freshness, contradiction, incompleteness, blocked, unknown, and failure blocking | Pass | evaluation and failure sections |
| Acceptance binds current aggregate proof | Pass | acceptance section |
| P0-W21 finalization remains authoritative | Pass | finalization section |
| Receipt has no authority and delivery is separate | Pass | Receipt section |
| Upstream and OD-02 authority unchanged | Pass | ownership audit |
| Review-head validation | Pass | CI `30422362363` on `24d5202eefb3eca59d2b70cb587159b2adcdaeac` |
| Exact closeout-head validation | Pending | final CI after this update |

## External evidence

Apple documentation supports process-group creation through `posix_spawnattr_setpgroup`, group signaling through `killpg`, negative process identifiers for group signaling, and signal `0` for validity checks. These APIs support the planned helper boundary but do not prove Kiln behavior.

## Verification

Review head `24d5202eefb3eca59d2b70cb587159b2adcdaeac` passed GitHub CI run `30422362363`.

The run passed Vale, current preflight behavior tests, Project agent-asset validation, dependency installation, formatting, warnings-as-errors compilation, compile-connected cycle detection, and ExUnit.

The current preflight result proves obsolete P0 mechanics only. It does not prove P1 ticket compatibility.

## Explicit exclusions

P0-W24 did not implement Commands or add a helper; alter lifecycle, provider, Context, Patch, or mutation authority; define CLI syntax; add shell, arbitrary command execution, container, sandbox, remote Worker, telemetry exporter, attestation, or Wave B scope; or issue build authorization.

## Gate verdict

P0-W24 passes on this branch after exact closeout-head CI.

Owner acceptance and integration remain required.

## Exact next action

After final CI passes, merge P0-W24 and run P0-W25 on current `main`.
