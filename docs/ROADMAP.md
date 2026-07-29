# Roadmap

**Document type:** Implementation-order authority  
**Decision status:** Accepted by Prompt 8-A  
**Integration status:** Authorization becomes effective when the Prompt 8-A pull request merges at an exact green head  
**Implementation status:** No product slice implemented  
**Authorization level:** Vertical Slice Authorized for P1-S01 only

## Roadmap rule

Kiln is implemented through bounded vertical user workflows.

A slice must produce usable behavior, deterministic tests, an explicit security boundary, a demo, and a slice verification manifest. A product Receipt is different: it is sealed only after committed product completion under P0-W24.

A slice does not complete a subsystem merely because the long-term architecture describes it.

Prompt 8-A is the sole current build-authorization authority. Older roadmap prose, broad Schemas, and planned ticket names do not independently authorize work.

## Owner schedule adjudication

The Single-Run Change Alpha remains an aggressive first-month execution target.

The owner accepts uncertainty in that estimate and rejects schedule pessimism as a reason to remove accepted safety, durability, recovery, Evidence, CLI, packaging, or delivery requirements.

Rules:

- implementation remains divided into bounded tickets with exact gates;
- a missed time target causes replanning;
- missed timing does not silently weaken behavior;
- no accepted feature is removed solely because a reviewer predicts a longer schedule.

## Product sequence

```text
P1-S01 durable single-Run foundation
→ P1-S02 evidence-backed Single-Run Change Alpha
→ accepted runtime Evidence
→ P0-W26 interruption reconciliation planning
→ P0-W27 bounded delegation planning
→ Prompt 6-B
→ Prompt 7-B
→ Prompt 8-B
→ only the delegated work authorized by Prompt 8-B
```

Later evidence-gated expansion can add TUI projection, managed mutation isolation, code intelligence, interoperability, local project intelligence, telemetry, or remote execution.

## Phase 0 — Complete on Prompt 8-A merge

Integrated shaping:

- Prompts 1 through 4;
- OD-01;
- P0-W21 through P0-W25;
- OD-02;
- Prompt 6-A;
- independent Prompt 7-A review;
- Prompt 8-A adjudication and authorization.

Phase 0 exits only when the Prompt 8-A branch merges after exact-head CI succeeds.

## Phase 1 — Change-loop-first slices

# P1-S01 — Durable single-Run foundation

**Status:** Authorized after Prompt 8-A merges  
**Purpose:** establish the smallest durable Kiln work boundary before provider, Repository-source, mutation, Command, or completion complexity.

## User-visible outcome

A developer can select one Repository, record one objective and criteria, create one Session, initial Task, and Root Run, inspect status through a minimal CLI, stop Kiln, restart it, and return to the same durable work state.

## Authorized delivery

- accepted identifiers and first-month state types;
- one active Project and Repository observation boundary;
- Session, initial Task, and Root Run invariants;
- exact P0-W21 lifecycle transition validation;
- direct Exqlite state store;
- forward migrations and integrity checks;
- append-oriented journal;
- expected revision and idempotency behavior;
- rebuildable current projections;
- transcript records separate from domain events;
- deterministic restart reconstruction;
- durable user-decision and external-operation intent and terminal-or-unknown record shapes;
- minimal CLI start, status, inspect, cancel, resume, and structured result surface;
- aggregate deterministic gate, demo, and slice verification manifest.

## Authorized ticket sequence

| Order | Ticket | Branch | Outcome |
| --- | --- | --- | --- |
| 1 | P1-S01-T01 | `work/p1-s01-t01-domain-foundation` | identifiers, state types, constructors, invariants, pure lifecycle transitions |
| 2 | P1-S01-T02 | `work/p1-s01-t02-durable-store` | Exqlite, store startup, migrations, integrity, journal transaction, revision and idempotency boundary |
| 3 | P1-S01-T03 | `work/p1-s01-t03-replay-projections` | deterministic replay, projections, restart, duplicate and out-of-order handling |
| 4 | P1-S01-T04 | `work/p1-s01-t04-foundation-cli` | minimal foreground CLI and structured output over implemented P1-S01 actions |
| 5 | P1-S01-T05 | `work/p1-s01-t05-slice-gate` | aggregate gate, restart demo, corruption fixtures, and P1-S01-V01 verification manifest |

Each ticket begins only after its dependency merges and its exact gate is accepted.

## P1-S01 exclusions

P1-S01 does not authorize:

- real or fake provider execution;
- Repository source reads or disclosure;
- Context package construction;
- model-facing Tools;
- source mutation;
- Patch proposal, Approval, application, or rollback;
- external Command execution;
- native macOS helper execution;
- criterion completion Evidence;
- user completion acceptance;
- product Receipt sealing;
- release packaging or installation;
- Child Runs;
- TUI;
- worktrees;
- protocols;
- Wave B work.

The deterministic fake provider remains planned for P1-S02 and is not required to prove P1-S01.

## P1-S01 exit

P1-S01 passes only when the exact integrated state proves:

- one Session starts atomically with one `in_progress` Task and one `ready` Root Run;
- invalid lifecycle transitions fail;
- expected revision and idempotency prevent false or duplicate state;
- journal transactions roll back atomically;
- migrations and integrity checks behave deterministically;
- projections rebuild from zero;
- transcript records cannot alter work state;
- restart reconstructs objective, criteria, Task, Run, decisions, operations, warnings, and revision;
- the minimal CLI's text and structured outputs describe the same state;
- no excluded capability is reachable;
- P1-S01-D01 and P1-S01-V01 bind the exact integrated commit and Evidence.

# P1-S02 — Evidence-backed Single-Run Change Alpha

**Status:** Planned but not authorized  
**Entry gate:** P1-S01 must merge and pass its aggregate gate and owner-machine Evidence.

## Intended outcome

A developer can ask MiniMax M3 to investigate the active Repository, inspect one exact Patch, approve and apply it, run one registered verification Command, accept completion only when current Evidence passes, and inspect a post-completion product Receipt.

## Planned subsystems

- bounded Repository reads and search;
- accepted disclosure policy and sealed Context;
- four-Tool maximum;
- deterministic fake provider and one real MiniMax M3 adapter;
- exact complete-text Patch and user Approval;
- one mutation owner with rollback and uncertain-effect handling;
- registered non-shell Command and macOS process-group helper;
- Artifacts, criterion Evidence, aggregate evaluation, user acceptance, atomic completion, and post-completion Receipt;
- remaining CLI commands;
- arm64 macOS local release and delivery.

P1-S02 requires a later authorization confirmation after P1-S01 Evidence. Its current ticket names are planning aids only.

## First-month milestone

The owner retains this aggressive target:

```text
open Repository
→ record objective and criteria
→ investigate through bounded reads
→ propose exact Patch
→ approve Patch digest
→ apply Patch
→ run registered verification
→ inspect current Evidence
→ accept completion
→ seal and verify the product Receipt
→ restart and restore the record
```

Failure to meet the calendar target causes replanning, not scope weakening.

# Wave B — Not authorized

P0-W26 and P0-W27 do not run until the authorized Single-Run Alpha provides accepted runtime Evidence showing:

- one real source change;
- durable restart behavior;
- controlled Patch authority;
- registered verification;
- criterion-bound Evidence;
- a valid post-completion Receipt;
- observed runtime failure or interruption behavior.

Only then can Wave B plan:

- one read-only Scout Child;
- one independent Verifier Child;
- maximum depth one;
- maximum one active Child;
- no writing Child;
- no peer communication;
- no shared mutable Context;
- no permission expansion;
- bounded result delivery and CLI navigation.

No P1-S03, P1-S04, or P1-S05 implementation is authorized by Prompt 8-A.

# Phase 2 — Evidence-gated expansion

These items remain deferred until measured need and accepted planning exist:

- TUI projection;
- managed mutation isolation;
- delegated Patch proposal;
- code intelligence;
- Capability interoperability;
- local project intelligence;
- telemetry and attestations;
- remote execution.

## Pause and return-to-planning conditions

Development pauses when:

- an authorized ticket requires an excluded external effect;
- a focused authority conflict is discovered;
- store corruption or migration behavior cannot be classified safely;
- the selected Exqlite/SQLite line cannot meet the accepted durability baseline;
- implementation would require nested first-month transactions;
- revision, idempotency, replay, or restart invariants cannot be proved;
- a ticket would introduce provider, mutation, Command, completion, product Receipt, release, Child, TUI, or Wave B behavior early;
- deterministic gates cannot reproduce the claimed result;
- the exact merge head is not green.

## Exact next action

After Prompt 8-A merges, begin only:

```text
work/p1-s01-t01-domain-foundation
```

Use `docs/work/P1-S01-T01-domain-foundation.md` as the accepted ticket plan.
