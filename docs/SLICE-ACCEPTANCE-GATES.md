# Slice Acceptance Gates

**Document type:** Verification and integration plan  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Gate scripts do not exist  
**Slice authority:** `docs/IMPLEMENTATION-SLICES.md`

## Purpose

This document defines the aggregate proof required for each reconciled slice.

A gate name is a planned executable contract. It is not an implemented command until Repository source and current CI prove that the path exists and passes.

Prompt 3 must classify the existing absent gate scaffolding. Prompt 6 can add only justified conformance work.

## Gate rules

1. Every gate runs against an exact commit or head plus dirty fingerprint.
2. Deterministic fixtures and controlled time are required.
3. Required CI gates must not depend on a live provider, public network, protocol server, language server, or container.
4. Optional live smoke tests remain separately labeled and cannot replace deterministic tests.
5. A required unavailable control produces `BLOCKED`, not a silent skip or `PASS`.
6. Gate output records command, exit status, duration, structured result, relevant output, Artifacts, warnings, and Environment fingerprint.
7. A demo cannot substitute for a deterministic gate.
8. A Receipt cannot make a failed, blocked, stale, contradictory, or missing gate pass.
9. Mutation, verification, and completion Evidence bind to exact Repository state.
10. The final slice gate evaluates projected merged state when trunk interaction can affect behavior.
11. Planned gate scripts live under `scripts/gates/` and emit human-readable output plus one machine-readable result Artifact.
12. No gate script is created by P0-W18.

# P1-S01 gates — Durable single-Run CLI

| Gate | Proof |
| --- | --- |
| P1-S01-G01 | Project subset, Session, Task, Root Run, identifier, and no-Root-Task invariants |
| P1-S01-G02 | Minimum Run lifecycle accepts valid transitions and rejects invalid transitions |
| P1-S01-G03 | Journal append, expected revision, transaction rollback, and migration behavior |
| P1-S01-G04 | Duplicate and out-of-order events do not create duplicate or false state |
| P1-S01-G05 | Current projections rebuild deterministically from zero |
| P1-S01-G06 | Transcript records cannot alter objective, Task, Run, or completion state |
| P1-S01-G07 | Restart reconstructs objective, criteria, Task, Root Run, current status, warnings, and decisions |
| P1-S01-G08 | CLI human and structured outputs describe equivalent state and correct exit status |
| P1-S01-G09 | No process exists merely because a Project, Session, Task, Run, Event, projection, or Receipt exists |
| P1-S01-G10 | `P1-S01-D01` and `P1-S01-R01` bind exact state, migrations, fixtures, warnings, and exclusions |

**Planned aggregate command:** `scripts/gates/slice-01`

# P1-S02 gates — Evidence-backed single-Run change loop

| Gate | Proof |
| --- | --- |
| P1-S02-G01 | Repository root, path, exclude, symlink, special-file, size, encoding, and source-state controls |
| P1-S02-G02 | Context package ordering, provenance, disclosure, digest, budgets, exclusions, and four-Tool maximum |
| P1-S02-G03 | Fake-provider streaming, timeout, cancellation, limits, malformed results, and optional live-provider separation |
| P1-S02-G04 | Secret canaries and denied paths never enter provider payloads, normal logs, or unauthorized Artifacts |
| P1-S02-G05 | Source observations remain distinct from model Claims and bind to exact path, content, and Repository state |
| P1-S02-G06 | Patch proposal, exact base, preview, Approval digest, path scope, conflict, and dirty-overlap controls |
| P1-S02-G07 | Patch apply, rollback reference, partial failure, result observation, and unknown-effect state are accurate |
| P1-S02-G08 | Registered Command executable, argv, cwd, environment, timeout, output, cleanup, and structured result controls |
| P1-S02-G09 | Criterion `PASS`, `FAIL`, `BLOCKED`, stale, contradictory, and orphaned outcomes control completion correctly |
| P1-S02-G10 | User acceptance, restart recovery, `P1-S02-D01`, and `P1-S02-R01` prove one complete real change |

**Planned aggregate command:** `scripts/gates/slice-02`

# P1-S03 gates — Interruption and unknown-effect recovery

| Gate | Proof |
| --- | --- |
| P1-S03-G01 | Model and Command cancellation target the owned live operation |
| P1-S03-G02 | Primary-platform process-tree timeout and cleanup observations are accurate |
| P1-S03-G03 | Unsupported process controls are reported as unavailable rather than enforced |
| P1-S03-G04 | Patch interruption resolves to applied, failed, rolled back, or orphaned based on observation |
| P1-S03-G05 | External-effect idempotency keys prevent automatic duplicate requests after restart |
| P1-S03-G06 | Unknown descendants or effects cannot become canceled, verified, or complete |
| P1-S03-G07 | Repository mutation invalidates affected Evidence and preserves unrelated current Evidence |
| P1-S03-G08 | Dirty or uncertain work is retained until accepted reconciliation or cleanup |
| P1-S03-G09 | Crash injection at each effect boundary reconstructs the last durable known state |
| P1-S03-G10 | `P1-S03-D01` and `P1-S03-R01` prove conservative recovery without hidden repetition |

**Planned aggregate command:** `scripts/gates/slice-03`

# P1-S04 gates — One bounded Scout Child

| Gate | Proof |
| --- | --- |
| P1-S04-G01 | Child exists before delegated execution and has one Root, one Parent, depth one, and one bounded purpose |
| P1-S04-G02 | Maximum one active Child and no nested delegation are enforced |
| P1-S04-G03 | Child Context, grants, limits, transcript, Artifacts, Evidence, and accounting are independent |
| P1-S04-G04 | Child authority can only narrow Project, Session, and Root maximums |
| P1-S04-G05 | No Parent transcript, secrets, write scope, provider cache, sibling state, or ambient Tools transfer |
| P1-S04-G06 | Background execution does not change CLI focus and remains visible from Root status |
| P1-S04-G07 | Blocking question, permission, failure, and completion records create Root-visible Attention without silent grant |
| P1-S04-G08 | Child cancellation does not cancel Root and records cleanup or orphan state accurately |
| P1-S04-G09 | Result delivery is bounded and idempotent and copies references rather than the Child transcript |
| P1-S04-G10 | Before and after Repository fingerprints, `P1-S04-D01`, and `P1-S04-R01` prove read-only delegated value |

**Planned aggregate command:** `scripts/gates/slice-04`

# P1-S05 gates — Independent Verifier Child

| Gate | Proof |
| --- | --- |
| P1-S05-G01 | Verifier receives independent criteria, state, Context, grants, limits, and accounting |
| P1-S05-G02 | Initial Verifier Context excludes author confidence narrative and write, Patch, install, and repair Tools |
| P1-S05-G03 | Registered Commands run against exact current Repository and Environment state |
| P1-S05-G04 | `PASS` requires current reproduced Evidence for every required criterion |
| P1-S05-G05 | `FAIL` identifies reproduced defects and affected criteria |
| P1-S05-G06 | Missing tool, Environment, state, access, or requirement information produces `BLOCKED` |
| P1-S05-G07 | Completed Verifier Run can carry `PASS`, `FAIL`, or `BLOCKED` without satisfying the Task automatically |
| P1-S05-G08 | Source fingerprints prove the Verifier did not repair the evaluated change |
| P1-S05-G09 | Root recommendation, Verifier result, user acceptance, and Receipt remain separate decisions and facts |
| P1-S05-G10 | Version 0.1 aggregate restart, Scout, Attention, Verifier, demo, and Receipt proof passes against exact final state |

**Planned aggregate command:** `scripts/gates/slice-05`

# Version 0.1 aggregate gate

Version 0.1 requires one aggregate command after all P1-S01 through P1-S05 tickets integrate.

**Planned command:** `scripts/gates/version-0-1`

It shall prove:

- one real source change through the single-Run workflow;
- explicit Patch Approval and exact application;
- deterministic verification and completion blocking;
- cancellation, timeout, rollback, stale Evidence, and orphan recovery;
- one no-write Scout Child;
- one independent Verifier Child with `PASS`, `FAIL`, and `BLOCKED` fixtures;
- maximum depth one and one-active-Child limits;
- Root-visible Attention;
- restart reconstruction of Root, Child, Attention, Artifacts, Evidence, Receipts, and decisions;
- complete CLI action coverage;
- absence or unreachability of deferred TUI, nested delegation, writing Child, worktree, code-intelligence, protocol, knowledge, telemetry, and remote-execution paths;
- one aggregate Receipt bound to the exact final state.

# Later-slice gate policy

P2 gates are not numbered or named until an accepted slice plan enters the implementation blast radius.

Entry conditions must be proven before planning an executable gate:

- TUI requires stable CLI commands and one real Child workflow;
- managed worktrees require a demonstrated isolation need;
- delegated Patch proposal requires stable Child and mutation boundaries;
- code intelligence requires measured search or token failures;
- interoperability requires a concrete external Client, capability, service, or Environment;
- local project intelligence requires stable active-Repository retrieval and accepted adversarial security controls.

Do not create empty future gate scripts to reserve names.

# Slice Receipt manifest

Every aggregate slice Receipt contains:

```text
slice identifier and revision
exact Repository state
required ticket and integration references
gate command and structured result
demo and transcript Artifact
security and recovery Evidence
Artifacts and structured reports
warnings, exclusions, unknowns, and unsupported paths
acceptance decision when required
manifest digest and seal time
```

A changed gate, fixture, demo, source state, warning, Evidence item, or decision creates a new Receipt.

A Receipt cannot alter the underlying result or authorize integration.
