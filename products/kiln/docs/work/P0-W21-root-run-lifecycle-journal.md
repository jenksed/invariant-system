# P0-W21: Root Run lifecycle and durable journal

**Document type:** Focused planning work package  
**Status:** Implemented, verified, accepted, and integrated  
**Integrated through:** Pull request 27, merge commit `ca21d0bbc25ddf5861191f8bde374e0761d86c0a`  
**Design head:** `7cc2a0f769e947353be287e486be4f0acebba6de`  
**Scope:** Root work state, transition authority, durable journal, restart reconstruction, and external-effect boundaries only  
**Build authorization:** Not issued

## Objective

Define the exact first-month Root Run transition contract and the smallest SQLite journal that reconstructs durable work without asking implementation to invent state, recovery, or persistence semantics.

## Entry evidence

- Prompt 4 integrated at merge commit `45acc2ed575957c53a8c57195d99c82965e9d48e`.
- OD-01 integrated at merge commit `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1` but did not constrain this round.
- The OD-01 merge was current `main` when W21 began.
- Production source contained no Session, Task, Run, journal, migration, projection, or restart behavior.
- Prompt 3 marked IU-02, IU-06, IU-07, and IU-13 planning-dependent.

## Accepted decisions

P0-W21 established:

1. Session states `active`, `completed`, and `abandoned`.
2. Task states `in_progress`, `satisfied`, and `abandoned`.
3. Root Run states `ready`, `running`, `waiting_for_user`, `orphaned`, `completed`, `failed`, and `canceled`.
4. Workflow step, pending decision, external-operation state, and Evidence state remain separate from Run status.
5. Session, initial Task, and Root Run start atomically in usable states.
6. `completed`, `failed`, and `canceled` are terminal.
7. `orphaned` can leave only through explicit reconciliation.
8. Every state-changing action uses expected revision, action identity, idempotency key, and canonical request digest.
9. One immutable append-oriented journal and one rebuildable Session projection own durable work state.
10. Direct Exqlite provides one supervised connection and one writer.
11. The first store uses WAL, `synchronous=FULL`, foreign keys, a two-second busy timeout, and immediate write transactions on a local filesystem.
12. Kiln owns forward SQL migrations with stable checksums.
13. External-operation intent is durable before dispatch, and uncertain effects are never repeated automatically.
14. Completion atomically aligns Session, Task, Root Run, user acceptance, current state, and the proof reference later defined by P0-W24.

## Files integrated

- `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`
- `docs/decisions/0022-use-exqlite-for-the-first-state-store.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W21-root-run-lifecycle-journal.md`

The integrated design diff contained five Markdown files, 1,268 additions, and seven deletions. It changed no production source, tests, dependency, lockfile, migration, runtime configuration, JSON Schema, CI workflow, script, preflight behavior, Skill, prompt, agent, executable scaffold, or product gate.

## Acceptance evidence

| Criterion | Result | Evidence |
| --- | --- | --- |
| Every first-month Run state is named and defined | Pass | lifecycle specification sections 1 and 2 |
| Every valid transition is defined | Pass | transition table |
| Invalid, duplicate, stale, denied, and uncertain requests are defined | Pass | invalid-request and failure matrices |
| Transition authority and expected revision are explicit | Pass | transition and authority matrices |
| Session and Task terminal alignment is explicit | Pass | atomic failure, cancellation, and completion transactions |
| Workflow, decision, operation, and proof state do not duplicate Run state | Pass | state-separation section |
| Journal envelope, idempotency, sequence, and causation are defined | Pass | journal and action-commit contracts |
| Atomic transaction groups are defined | Pass | transaction sections |
| Projection rebuild and transcript separation are defined | Pass | projection and transcript sections |
| SQLite boundary is selected | Pass | ADR-0022 and SQLite section |
| Migration, corruption, busy, startup, and unsupported-version behavior are explicit | Pass | startup and failure matrices |
| Restart and unknown-effect behavior are explicit | Pass | restart matrix |
| No later-round authority or implementation scope entered | Pass | authority and exclusion sections |

## Verification

Design head `7cc2a0f769e947353be287e486be4f0acebba6de` passed GitHub CI run `30419722173` before merge.

The run passed:

- Vale;
- current agent-preflight behavior tests;
- Project agent-asset validation;
- dependency installation;
- formatting;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit.

The preflight result proves current P0 mechanics only. It does not prove accepted P1 ticket compatibility.

This closeout correction receives its own exact-head CI through the closeout pull request.

## W22 ownership handoff

P0-W22 can consume:

- Run and operation identity;
- the common operation states;
- intent-before-dispatch;
- terminal or unknown result recording;
- expected revision and idempotency principles;
- conservative restart and orphan rules.

P0-W22 cannot add or change:

- Session, Task, or Run states;
- transition authority;
- journal entry envelope or projection ownership;
- migrations or store startup;
- completion transaction semantics.

P0-W22 must be based on the integrated P0-W21 result and pass an explicit lifecycle and persistence ownership audit before integration.

## Explicit exclusions

P0-W21 did not:

- implement source, tests, migrations, dependencies, Schemas, scripts, or scaffolding;
- define MiniMax, Context, Tools, Repository reads, or disclosure;
- define Patch representation or Approval;
- define registered Command or process-tree semantics;
- define criterion Evidence, Receipt aggregation, or CLI presentation;
- define Child Runs, Attention, TUI, worktrees, protocols, telemetry, remote execution, or attestations;
- issue build authorization.

## Gate verdict

**P0-W21 passed and is integrated.**

Build authorization remains denied.

## Exact next action

Rebuild or rebase P0-W22 on the integrated and closed P0-W21 baseline. Audit it for lifecycle and persistence overlap, validate its exact final head, and integrate it second.
