# Vertical Implementation Slices

**Document type:** Implementation roadmap detail  
**Decision status:** Accepted by Prompt 8-A  
**Integration status:** Authorization becomes effective when the Prompt 8-A pull request merges at an exact green head  
**Implementation status:** No product slice implemented  
**Order authority:** `docs/ROADMAP.md`

## Purpose

This document defines the bounded vertical workflows that implement Kiln.

A slice must produce usable behavior. It must not complete a horizontal framework merely because later architecture describes it.

The first two slices form the accepted Single-Run product. Prompt 8-A authorizes only P1-S01. P1-S02 remains planned but unauthorized until P1-S01 passes its aggregate gate and owner-machine checks.

Child Runs enter only after accepted Single-Run Alpha Evidence and Wave B planning and authorization.

## Slice identifiers

```text
P1-S01       slice
P1-S01-T01   ticket
P1-S01-G01   aggregate gate item
P1-S01-D01   demo
P1-S01-V01   slice verification manifest
```

A slice verification manifest is an implementation Evidence record. It is not a product Receipt.

A product Receipt is sealed only after committed product completion under P0-W24.

## Cross-slice rules

Every authorized slice shall:

1. introduce only the contract subset required by its demo;
2. preserve Task, Run, provider invocation, Tool, Patch, Command, process, and protocol distinctions;
3. use pure functions for static concepts and transformations;
4. create processes only for live Resources, concurrency, timing, cancellation, streaming, subscriptions, external communication, or fault isolation;
5. keep Git and the filesystem authoritative for Repository state;
6. record material work facts and external-effect boundaries durably before reporting them as durable;
7. bind mutation and verification to exact Repository state when those effects are authorized;
8. keep model Claims separate from deterministic Evidence;
9. make permission, mutation, acceptance, and delivery explicit;
10. keep large or sensitive content in Artifacts;
11. include deterministic tests that do not require a live provider or public network;
12. label optional live smoke tests separately;
13. create a bounded slice verification manifest from exact implementation Evidence;
14. preserve failures, warnings, exclusions, and unknowns;
15. leave unauthorized capabilities unreachable or absent.

# P1-S01 — Durable single-Run foundation

**Status:** Authorized after Prompt 8-A merges  
**Milestone:** Durable work boundary  
**Target:** aggressive first foundation sequence; timing does not weaken gates

## User-visible value

A developer can select one local Repository, record one objective and criteria, create one Session, initial Task, and Root Run, inspect current status through a minimal CLI, stop Kiln, restart it, and return to the same durable work state.

## Concepts introduced

- generated identifiers;
- one active Project and Repository observation boundary;
- Session;
- initial Task;
- Root Run;
- exact P0-W21 persisted lifecycle;
- append-oriented journal;
- expected revision and idempotency;
- current projections;
- transcript records separate from domain events;
- durable decisions and external-operation intent and observation records;
- minimal CLI request and result boundary;
- slice verification manifest.

## Authorized responsibilities

Exact module and file names are selected by the ticket that owns them. Responsibilities include:

```text
identifier generation and validation
Project observation metadata
Session, Task, and Root Run domain records
pure lifecycle and action validation
store startup, migrations, integrity, and transactions
journal append and replay
current projections
minimal foreground CLI
P1-S01 aggregate gate and verification manifest
```

No Session, Task, Run, decision, operation, event, projection, or verification-manifest record requires its own process.

## Security boundary

- one canonical selected Repository root;
- metadata observation only; no Repository source read;
- no source write;
- no provider or public network;
- no model-facing Tool;
- no secret access;
- no shell or external Command;
- no Child Run;
- no product completion or Receipt;
- CLI state is not domain authority;
- unknown or corrupt state blocks progress rather than returning success.

## Authorized tickets

| Order | Ticket | Deliverable |
| --- | --- | --- |
| 1 | P1-S01-T01 | identifiers, first-month state records, constructors, invariants, pure actions and transitions |
| 2 | P1-S01-T02 | direct Exqlite, store startup, migrations, integrity checks, journal append, revision and idempotency transactions |
| 3 | P1-S01-T03 | deterministic replay, rebuildable projections, restart, duplicate and out-of-order behavior |
| 4 | P1-S01-T04 | minimal foreground CLI start, status, inspect, cancel, resume, and structured output |
| 5 | P1-S01-T05 | aggregate gate, restart demo, corruption and migration fixtures, and P1-S01-V01 |

The accepted plans are under `docs/work/P1-S01-T01-*.md` through `T05`.

Each ticket begins only after its predecessor merges and its exact acceptance Evidence is accepted.

## Acceptance criteria

- one Session has one initial Task and exactly one Root Run;
- Session start creates `active`, `in_progress`, and `ready` atomically;
- no separate Root Task exists;
- Run identity is independent of process, provider, branch, worktree, and transcript;
- objective and criteria revisions are durable;
- the exact seven-state lifecycle rejects invalid transitions;
- expected revision rejects stale writes;
- idempotency prevents duplicate effects;
- transaction failure leaves no partial durable action;
- forward migrations and unsupported future versions behave deterministically;
- projections rebuild deterministically from zero;
- transcript records cannot alter authoritative state;
- restart reconstructs the same current work state;
- text and structured CLI outputs describe equivalent state;
- no unauthorized capability is reachable.

## Deterministic tests

- identifiers and constructor validation;
- Session, Task, and Root Run invariants;
- accepted action and transition table;
- journal append and rollback;
- expected-revision conflict;
- idempotent duplicate submission;
- migration forward and unsupported-version behavior;
- integrity and corruption fixtures;
- deterministic replay and projection rebuild;
- duplicate and out-of-order action handling;
- transcript separation;
- CLI result and exit mapping;
- restart from exact fixture state;
- absence or explicit unsupported result for every excluded action.

## Slice verification manifest

**P1-S01-V01 — Durable single-Run verification manifest**

It references:

- exact integrated commit;
- required ticket and PR commits;
- accepted objective and criteria fixture;
- Repository observation metadata;
- migration and SQLite versions;
- journal and projection fixture digests;
- gate command and structured result;
- restart demo output;
- owner-machine Evidence;
- warnings, exclusions, unsupported paths, and unknowns;
- manifest digest and creation time.

It cannot satisfy a Task, complete a Run, or act as a product Receipt.

## Demo

**P1-S01-D01 — Durable single-Run foundation**

1. Select one fixture Repository without reading source content.
2. Start one Session with objective and criteria.
3. Show the initial Task and Root Run.
4. Show current revision and durable state.
5. Record bounded transcript metadata without changing domain state.
6. Record one supported decision or cancellation action.
7. Stop Kiln.
8. Restart Kiln.
9. Show the reconstructed objective, criteria, Task, Run, decision, warnings, and revision.
10. Verify P1-S01-V01 against the exact integrated state.

## Exit

Kiln has a durable work foundation that survives restart without reconstructing truth from conversation text.

## Explicit exclusions

- provider behavior or fake-provider execution;
- Repository source reads or search;
- Context packages and model-facing Tools;
- Patch proposal, Approval, mutation, or rollback;
- external Commands or native helper;
- criterion completion Evidence;
- user completion acceptance;
- product Receipt sealing;
- release packaging or installation;
- Child Runs or Attention;
- TUI;
- managed worktrees;
- protocols;
- Wave B work.

# P1-S02 — Evidence-backed Single-Run Change Alpha

**Status:** Planned; not authorized  
**Entry gate:** P1-S01 aggregate gate, demo, verification manifest, owner-machine Evidence, and Prompt 8-A authorization conditions remain satisfied.

## User-visible value

A developer can ask MiniMax M3 to investigate the active Repository, inspect an exact Patch proposal, approve it, apply it, run one registered verification Command, and accept completion only when current Evidence passes.

## Planned concepts

- bounded Repository observation, read, and exact search;
- disclosure policy and sealed Context package;
- four phase-specific model-facing Tools;
- deterministic fake provider;
- one real MiniMax M3 adapter after live capability proof;
- model Claims separate from source observations;
- complete-text Patch and exact user Approval;
- one mutation owner, rollback data, and exact target or unknown observation;
- registered non-shell Command and macOS process-group helper;
- Artifacts and criterion-bound Evidence;
- aggregate completion evaluation and user acceptance;
- P0-W21 atomic completion;
- post-completion product Receipt;
- remaining product CLI and local arm64 macOS delivery.

## Planned security boundary

- one approved active Repository root;
- exact path, symlink, special-file, encoding, size, and secret controls;
- only sealed Context may leave the machine;
- no fallback provider;
- no direct model write Tool;
- exact Approval before mutation;
- no fuzzy Patch;
- no shell;
- no dependency installation, Git publication, deployment, or remote execution;
- unknown external effects block completion and are never retried automatically.

## Product Receipt

P1-S02 can seal the first product Receipt only after:

1. every required criterion has current passing Evidence;
2. no contradiction, blocking decision, or unknown operation remains;
3. the user accepts the current aggregate evaluation;
4. P0-W21 atomically completes the Run, Task, and Session.

The Receipt aggregates immutable references afterward and has no authority.

## Exit

One real source change moves from accepted intent to user-accepted verified completion. Failed, blocked, stale, contradictory, incomplete, or orphaned proof prevents completion.

# Wave B — Planned only after runtime Evidence

P0-W26 and P0-W27 remain blocked until the Single-Run Alpha provides accepted runtime Evidence for a real change, restart, Patch authority, registered verification, criterion Evidence, a valid product Receipt, and observed interruption behavior.

No Child, Scout, Verifier, Attention, or P1-S03 through P1-S05 implementation is authorized.

# Later evidence-gated slices

The following remain deferred:

- TUI projection;
- managed mutation isolation;
- delegated Patch proposal;
- code intelligence;
- interoperability;
- local project intelligence;
- telemetry and attestations;
- remote execution.
