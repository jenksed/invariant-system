# Slice Acceptance Gates

**Document type:** Verification and integration authority  
**Decision status:** Accepted by Prompt 8-A for P1-S01  
**Integration status:** Effective after Prompt 8-A merges at an exact green head  
**Implementation status:** Gate scripts do not yet exist  
**Slice authority:** `docs/IMPLEMENTATION-SLICES.md`

## Purpose

This document defines the aggregate proof required for authorized implementation slices.

A gate name is a planned executable contract. It is not an implemented command until Repository source and current CI prove the path exists and passes.

Only P1-S01 gates are authorized by Prompt 8-A. P1-S02 gates remain planned and P1-S03 through P1-S05 remain blocked behind Wave B planning and authorization.

## Gate rules

1. Every gate runs against an exact commit or head plus dirty fingerprint.
2. Deterministic fixtures and controlled time are required.
3. Required CI gates do not depend on a live provider, public network, external protocol server, language server, or container.
4. Optional live smoke tests remain separately labeled and cannot replace deterministic tests.
5. A required unavailable control produces `BLOCKED`, not a silent skip or `PASS`.
6. Gate output records command, exit status, duration, structured result, relevant output, Artifacts, warnings, and Environment fingerprint.
7. A demo cannot substitute for a deterministic gate.
8. An implementation Evidence manifest cannot make a failed, blocked, stale, contradictory, unknown, or missing gate pass.
9. A product Receipt cannot create or change Evidence, completion, or integration authority.
10. Mutation, verification, and completion Evidence bind to exact Repository state when those capabilities are authorized.
11. The final slice gate evaluates projected merged state when trunk interaction can affect behavior.
12. Gate scripts live under `scripts/gates/` only when their owning authorized ticket implements them.
13. A slice verification manifest references exact gate and demo Evidence. It is not a product Receipt.

# P1-S01 gates — Durable single-Run foundation

**Authorization:** Active only after Prompt 8-A merges.

| Gate | Proof |
| --- | --- |
| P1-S01-G01 | identifier, Project observation, Session, initial Task, Root Run, and no-Root-Task invariants |
| P1-S01-G02 | exact P0-W21 actions and lifecycle accept valid transitions and reject invalid transitions |
| P1-S01-G03 | store startup, migration checksums, integrity, journal append, expected revision, idempotency, and transaction rollback |
| P1-S01-G04 | duplicate, stale, and out-of-order actions do not create duplicate or false state |
| P1-S01-G05 | current projections rebuild deterministically from zero |
| P1-S01-G06 | transcript records cannot alter objective, Task, Run, decision, operation, or completion state |
| P1-S01-G07 | restart reconstructs objective, criteria, Task, Root Run, revision, decisions, operations, warnings, and unknowns |
| P1-S01-G08 | CLI text and structured outputs describe equivalent state and correct exit status |
| P1-S01-G09 | no permanent process exists merely because a Project, Session, Task, Run, decision, operation, journal entry, projection, or verification manifest exists |
| P1-S01-G10 | P1-S01-D01 and P1-S01-V01 bind the exact integrated state, migrations, fixtures, owner-machine checks, warnings, and exclusions |
| P1-S01-G11 | provider, Repository source read, Context, Tool, Patch, Command, completion Evidence, product Receipt, release, Child, TUI, and Wave B paths are absent or explicitly unsupported |

**Planned aggregate command:** `scripts/gates/slice-01`

The aggregate command is created only by P1-S01-T05.

## Required owner-machine Evidence

P1-S01-T02 and T05 must prove on the OD-02 validation host:

- Apple Silicon architecture and exact macOS version and build;
- local APFS for `$KILN_HOME` and the fixture Repository;
- exact Erlang, Elixir, Exqlite, and SQLite versions;
- bundled SQLite is 3.51.3 or newer;
- WAL and `synchronous=FULL` are effective;
- one-writer immediate transaction behavior;
- no dependency on nested first-month transactions or nested savepoints;
- migration and restart behavior;
- corruption and unsupported-version blocking;
- filesystem and sync limitations reported honestly.

Unsupported or unavailable controls produce `BLOCKED` or an explicit warning. They do not become silent success.

## P1-S01 verification manifest

**P1-S01-V01 — Durable single-Run verification manifest**

It contains references to:

```text
slice identifier and revision
exact integrated commit and dirty fingerprint
required ticket and PR commits
aggregate gate command and structured result
restart demo output
migration, journal, and projection fixture digests
owner-machine Environment and version facts
warnings, exclusions, unknowns, and unsupported paths
manifest digest and creation time
```

A changed gate, fixture, source state, warning, Evidence item, or decision creates a new manifest.

P1-S01-V01 cannot satisfy a Task, complete a Run, authorize integration, or act as a product Receipt.

# P1-S02 gates — Planned, not authorized

These gates describe the accepted Single-Run Alpha target but cannot be implemented until P1-S01 passes and later authorization confirms the P1-S02 handoff.

| Gate | Proof |
| --- | --- |
| P1-S02-G01 | Repository root, path, exclude, symlink, special-file, size, encoding, and source-state controls |
| P1-S02-G02 | Context ordering, provenance, disclosure, digest, budgets, exclusions, and four-Tool maximum |
| P1-S02-G03 | fake-provider streaming, timeout, cancellation, limits, malformed results, and optional live-provider separation |
| P1-S02-G04 | exact MiniMax M3 account and endpoint smoke gate proves required fields without fallback |
| P1-S02-G05 | secret canaries and denied paths never enter provider payloads, normal logs, or unauthorized Artifacts |
| P1-S02-G06 | source observations remain distinct from model Claims and bind exact content and Repository state |
| P1-S02-G07 | complete-text Patch, exact base, preview, Approval digest, path scope, conflict, and dirty-overlap controls |
| P1-S02-G08 | Patch apply, rollback data, partial failure, result observation, and unknown-effect state are accurate |
| P1-S02-G09 | registered Command executable, argv, cwd, environment, timeout, output, process-group cleanup, and structured result controls |
| P1-S02-G10 | criterion `PASS`, `FAIL`, `BLOCKED`, stale, contradictory, incomplete, and orphaned outcomes control completion correctly |
| P1-S02-G11 | user acceptance and P0-W21 atomic completion precede product Receipt sealing |
| P1-S02-G12 | restart recovery and the complete Single-Run Alpha demo prove one real source change |

**Planned aggregate command:** `scripts/gates/slice-02`

## P1-S02 product Receipt

The P1-S02 product Receipt is sealed only after:

- the current aggregate evaluation is ready;
- the user accepts it;
- P0-W21 atomically completes the Run, Task, and Session.

It references immutable provider, Context, Patch, Approval, mutation, Command, Artifact, Evidence, acceptance, completion, warning, and host-profile facts.

It has no authority and cannot make a failed or missing gate pass.

# Wave B gates — Not authorized

P1-S03, P1-S04, P1-S05, and the version 0.1 delegated aggregate gate are not executable planning under Prompt 8-A.

Their older gate names remain historical planning references only until:

1. the Single-Run Alpha provides accepted runtime Evidence;
2. P0-W26 and P0-W27 are integrated;
3. Prompt 6-B scaffolding is accepted;
4. Prompt 7-B independent review completes;
5. Prompt 8-B authorizes bounded delegated work.

Do not create empty gate scripts to reserve Wave B names.

# Later-slice gate policy

Later gates are not numbered until their entry conditions are proven:

- TUI requires stable CLI operations and useful work to project;
- managed worktrees require a measured isolation or concurrency need;
- delegated Patch proposal requires stable delegation and mutation boundaries;
- code intelligence requires measured search, latency, or token failures;
- interoperability requires one concrete external need;
- local project intelligence requires stable active-Repository retrieval and accepted adversarial controls.
