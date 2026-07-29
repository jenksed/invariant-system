# P0-W21: Root Run lifecycle and durable journal

**Document type:** Focused planning work package  
**Status:** In progress  
**Branch:** `work/p0-w21-root-run-lifecycle-journal`  
**Depends on:** P0-W20 integrated through pull request 25  
**Scope:** Root work state, transition authority, durable journal, restart reconstruction, and external-effect boundaries only

## Objective

Define the exact first-month Root Run transition contract and the smallest SQLite journal that reconstructs durable work without asking implementation to invent state, recovery, or persistence semantics.

## Observed current state and evidence

- Prompt 4 is integrated at merge commit `45acc2ed575957c53a8c57195d99c82965e9d48e`.
- OD-01 is integrated at merge commit `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1` but does not constrain this round.
- `docs/RUN-MODEL.md` contains a minimum lifecycle but not a complete transition table or invalid-transition behavior.
- `docs/SESSION-MODEL.md` defines Session and Task concepts but not exact atomic start, completion, abandonment, or restart transactions.
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md` marks IU-02, IU-06, IU-07, and IU-13 as planning-dependent.
- `docs/contracts/kiln-core.schema.json` contains broad Run states, Agent binding, Client state, and deferred fields that are not accepted first-month contracts.
- Production source still contains no Session, Task, Run, journal, migration, projection, or restart behavior.

## Assumptions and unknowns

### Assumptions

- One SQLite file is sufficient for the first local single-user workflow.
- One library-owned connection process and one writer are sufficient.
- Git and the filesystem remain source truth and stay outside the SQLite transaction.
- A small append-oriented domain journal plus rebuildable current projections is sufficient. A general event-sourcing framework is not required.

### Unknowns

- Exact persisted Run, Session, and Task state subsets.
- Exact valid and invalid transition behavior.
- Exact transaction boundaries and idempotency rules.
- Exact journal envelope and projection ownership.
- Exact SQLite driver, connection mode, pragmas, migration mechanism, and startup failure behavior.
- Exact treatment of a crash after an external operation starts but before its result is recorded.

## Requirements

- Define every first-month Run state and transition.
- Define transition authority, prerequisites, expected revision, duplicate behavior, and invalid behavior.
- Separate Run state, workflow step, operation state, and Evidence state.
- Define atomic Session start, revision, cancellation, failure, orphan reconciliation, and completion transactions.
- Define one immutable journal envelope and one current-projection owner.
- Define transcript separation.
- Select one SQLite library and connection model.
- Define migrations, format version, corruption handling, busy behavior, partial write, and restart reconstruction.
- Define the external-effect intent and observation boundary without designing provider, Patch, Command, or Evidence payloads.
- Preserve no-process-per-domain-noun and one-local-writer constraints.

## Proposed changes

1. Create `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md` as focused subject authority.
2. Create an ADR for the SQLite driver and direct persistence boundary if the comparison supports a durable choice.
3. Update planning control to link the focused authority and state that it owns conflicting lifecycle and journal detail.
4. Record exact later-round ownership boundaries.
5. Complete this work record with final Evidence.

## Files or components expected to change

- `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`
- `docs/PLANNING.md`
- `docs/decisions/0022-use-exqlite-for-the-first-state-store.md`
- `docs/decisions/README.md`
- `docs/work/P0-W21-root-run-lifecycle-journal.md`

Existing Run, Session, Architecture, Roadmap, slice, gate, disposition, and Schema documents remain inputs. The focused specification will state exact authority and supersessions. Prompt 6 will normalize machine-readable scaffolds after all first-month rounds.

## Acceptance criteria

- Every first-month Run state is named and defined.
- Every valid transition and invalid request result is defined.
- Transition authority and expected revision are defined.
- Session and Task state changes are defined.
- Completion, failure, cancellation, and orphan rules are defined.
- Workflow step, operation state, and Evidence state do not become duplicate Run states.
- Journal entry, command identity, idempotency, sequence, and causation are defined.
- Atomic transaction groups are defined.
- Projection rebuild and transcript separation are defined.
- SQLite library, connection ownership, transaction mode, pragmas, migration, unsupported-version, corruption, busy, and startup behavior are defined.
- Restart and unknown-effect behavior are explicit.
- No provider, Context, Patch, Command, Evidence, CLI, Child, TUI, protocol, or implementation scope is added.

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Targeted document checks must also prove one transition owner, one journal owner, one SQLite choice, no deferred Run states in the first-month set, and no conflict with P0-W22 ownership.

## Required completion evidence

- P0-W21-E01: Prompt 4 and entry-gate merge Evidence.
- P0-W21-E02: complete transition table and authority matrix.
- P0-W21-E03: journal envelope, transaction, idempotency, and projection contract.
- P0-W21-E04: SQLite driver and configuration comparison from current official sources.
- P0-W21-E05: restart, corruption, migration, duplicate, stale revision, and unknown-effect matrices.
- P0-W21-E06: exact planning-only diff.
- P0-W21-E07: exact final-head CI.

## Explicit exclusions

P0-W21 does not:

- implement source, tests, migrations, dependencies, Schemas, scripts, or scaffolding;
- define MiniMax, Context, Tools, Repository reads, or disclosure;
- define Patch representation or Approval;
- define registered Command or process-tree semantics;
- define criterion Evidence, Receipt aggregation, or CLI presentation;
- define Child Runs, Attention, TUI, worktrees, protocols, telemetry, remote execution, or attestations;
- issue build authorization.
