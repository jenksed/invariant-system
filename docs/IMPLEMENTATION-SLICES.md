# Vertical Implementation Slices

**Document type:** Implementation roadmap detail  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Not implemented  
**Order authority:** `docs/ROADMAP.md`

## Purpose

This document defines the minimum vertical workflows that implement Kiln's reconciled product.

A slice must produce usable behavior. It must not complete a horizontal framework merely because later architecture describes it.

The first two slices complete one real source change. Child Runs enter only after the single-Run product works.

## Slice identifiers

```text
P1-S01       slice
P1-S01-T01   ticket
P1-S01-G01   aggregate gate item
P1-S01-D01   demo
P1-S01-R01   Receipt
```

A slice is a planning and delivery boundary. It is not a runtime entity, table, process, API, or protocol object.

## Cross-slice rules

Every slice shall:

1. introduce only the contract subset required by its demo;
2. preserve Task, Run, model invocation, Tool, Command, process, and protocol distinctions;
3. use pure functions for static concepts and transformations;
4. create processes only for live Resources, concurrency, timing, cancellation, streaming, subscriptions, external communication, or fault isolation;
5. keep Git and the filesystem authoritative for Repository state;
6. record material state changes and external effects durably before reporting them as durable;
7. bind mutation and verification to exact Repository state;
8. keep model Claims separate from deterministic Evidence;
9. make permission, mutation, acceptance, and delivery explicit;
10. keep large or sensitive content in Artifacts;
11. include deterministic tests that do not require a live provider or public network;
12. state optional live smoke tests separately;
13. produce a bounded aggregate Receipt;
14. preserve failures, warnings, exclusions, and unknowns;
15. leave later capabilities unreachable or absent.

---

# P1-S01 — Durable single-Run CLI

**Milestone:** Durable work boundary  
**Target window:** Weeks 1–2 after build authorization

## User-visible value

A developer can open one local Repository, record one objective and criteria, create one Session, Task, and Root Run, inspect current status through the CLI, close Kiln, restart it, and return to the same work state.

## Concepts introduced

- configured Workspace maximum path;
- one active Project and Repository observation;
- Session;
- Task;
- Root Run;
- minimum Run lifecycle;
- versioned event envelope;
- append-oriented SQLite journal;
- current projections;
- transcript records separate from domain events;
- CLI request and result boundary;
- bounded acceptance Receipt.

## Required responsibilities

```text
Kiln.Domain.Project
Kiln.Domain.Session
Kiln.Domain.Task
Kiln.Domain.Run
Kiln.Domain.Event
Kiln.Domain.Transition
Kiln.Store
Kiln.Projections
Kiln.CLI
Kiln.Receipt
```

These names describe responsibility. Prompt 3 and the accepted ticket plan determine exact files and public modules.

No Session, Task, Run, Event, projection, or Receipt requires its own process.

## Security boundary

- one canonical approved Repository root;
- no Repository content read beyond initialization observations;
- no source write;
- no provider, network, shell, Command, secret, or protocol access;
- no Child Run;
- no automatic cleanup of dirty work;
- CLI state does not become domain authority.

## Proposed tickets

| Ticket | Deliverable |
| --- | --- |
| P1-S01-T01 | Minimal Project subset, Session, Task, Run, Event, identifiers, and pure transition rules |
| P1-S01-T02 | SQLite dependency, migration owner, append transaction, and current projection boundary |
| P1-S01-T03 | Deterministic replay and invalid, duplicate, and out-of-order transition handling |
| P1-S01-T04 | CLI start, status, inspect, cancel, resume, and structured output |
| P1-S01-T05 | Restart, corruption, migration, and aggregate Receipt fixtures |

No ticket is accepted before Prompt 8.

## Acceptance criteria

- one Session has one initial Task and exactly one Root Run;
- a separate Root Task is not created;
- a Run is identified independently of process, provider, branch, worktree, and transcript;
- accepted objective and criteria revisions are durable;
- the minimum lifecycle rejects invalid transitions;
- restart reconstructs the same current projection from durable state;
- transcript records cannot alter Task or completion state;
- duplicate event submission has no duplicate effect;
- no process exists merely because a domain record exists;
- CLI human and structured outputs describe the same state;
- no product capability beyond this slice is reachable.

## Deterministic tests

- constructors and validation;
- Session, Task, and Root Run invariants;
- lifecycle transition table;
- journal append and transaction rollback;
- migration forward and unsupported-version behavior;
- deterministic replay;
- duplicate and out-of-order event handling;
- transcript versus domain-state separation;
- CLI result and exit-status tests;
- restart from exact fixture state.

## Required Receipt

**P1-S01-R01 — Durable single-Run Receipt**

References:

- exact commit;
- accepted objective and criteria fixture;
- Repository observation;
- event and projection fixture digests;
- migration version;
- restart command and result;
- deterministic test results;
- warnings and exclusions.

## Demo

**P1-S01-D01 — Durable single-Run CLI**

1. Open one fixture Repository.
2. Start one Session with objective and criteria.
3. Show the Task and Root Run.
4. Record bounded transcript activity.
5. Cancel or pause at an accepted point.
6. Stop Kiln.
7. Restart Kiln.
8. Show the reconstructed objective, criteria, Task, Run, status, and Receipt reference.

## Exit

Kiln has a durable work model that survives restart without reconstructing truth from a conversation summary.

## Deferred

- model invocation;
- Repository source reads;
- Patch proposal and mutation;
- Command execution;
- Child Runs;
- TUI;
- general policy language;
- protocols.

---

# P1-S02 — Evidence-backed single-Run change loop

**Milestone:** Single-Run Change Alpha  
**Target window:** Weeks 3–4

## User-visible value

A developer can ask one model to investigate the active Repository, inspect an exact Patch proposal, approve it, apply it, run one registered verification Command, and accept completion only when current Evidence passes.

## Concepts introduced

- one provider-neutral invocation boundary;
- deterministic fake provider;
- one configured real provider adapter;
- explicit Context package and manifest;
- fixed phase-specific Tool set;
- native bounded Repository read and exact search;
- source Evidence and model Claims;
- exact Patch proposal and user Approval;
- transactional Patch application and rollback reference;
- registered non-shell Command;
- model and Command Workers;
- Artifact metadata and storage;
- criterion Evidence;
- completion readiness and Receipt.

## Required responsibilities

```text
Kiln.Workflow
Kiln.Policy.EffectiveAuthority
Kiln.Context.Package
Kiln.Model.Provider
Kiln.Model.InvocationWorker
Kiln.Repository.State
Kiln.Repository.Reader
Kiln.Repository.Patch
Kiln.Execution.Command
Kiln.Execution.CommandWorker
Kiln.Artifacts
Kiln.Evidence
Kiln.Receipt
```

A general model router, Capability broker process, Context retrieval framework, or Patch abstraction hierarchy is not required.

## Initial Tool set

At most four model-facing operations are active:

```text
repo.search
repo.read
artifact.read
change.propose
```

`change.propose` creates an immutable proposal. It cannot mutate source.

## Security boundary

- one approved active Repository root;
- canonical path, exclude, symlink, special-file, encoding, and size checks;
- one configured provider destination;
- only the sealed Context package can leave the machine;
- secret and denied-path screening before disclosure;
- no inherited full user environment;
- no direct model write Tool;
- exact user Approval for the Patch digest;
- one mutation owner in one selected checkout;
- no fuzzy Patch application;
- one registered non-shell verification Command;
- no dependency installation, commit, push, merge, publication, or deployment;
- no fallback provider or Command without a new authority decision.

## Proposed tickets

| Ticket | Deliverable |
| --- | --- |
| P1-S02-T01 | Native Repository observation, bounded read, exact search, path policy, and source Evidence |
| P1-S02-T02 | Fixed authority profiles, Approvals, and explicit Context package with four-Tool maximum |
| P1-S02-T03 | Provider behaviour, fake provider, one real adapter, limits, cancellation, and result Artifact |
| P1-S02-T04 | Exact Patch proposal, base validation, preview, Approval, application, rollback reference, and result observation |
| P1-S02-T05 | Registered Command request, Worker, timeout, output Artifact, cleanup, and normalized result |
| P1-S02-T06 | Criterion Evidence, completion readiness, user acceptance, and aggregate Receipt |
| P1-S02-T07 | Restart and uncertain-effect fixtures across model, Patch, and Command boundaries |

## Acceptance criteria

- objective, criteria, Repository state, and limits determine the Context package;
- every Context item has source, trust, sensitivity, state binding, selection reason, and token estimate;
- no more than four Tool schemas enter one invocation;
- secret canaries and denied paths do not enter provider payloads or normal logs;
- every source observation has path, range or symbol when available, content digest, and Repository fingerprint;
- model inference cannot be labeled as source Evidence;
- the model cannot mutate source directly;
- the Patch proposal is bound to exact base file hashes;
- only explicit user Approval for the exact digest allows application;
- conflict, stale base, path escape, unowned dirty overlap, partial application, or uncertain rollback blocks verification;
- one registered Command runs with fixed executable, argv, working directory, environment, timeout, and output limits;
- unknown process effects or incomplete cleanup cannot produce `PASS`;
- failed, blocked, stale, or contradictory criterion Evidence blocks completion;
- user acceptance is required after current passing Evidence;
- restart never repeats a model invocation, Patch, or Command with uncertain effects automatically.

## Deterministic tests

- Context ordering, digest, budget, exclusion, and provenance;
- fake provider streaming, cancellation, timeout, malformed result, and limit fixtures;
- path traversal, symlink escape, denied file, size, encoding, and secret canary tests;
- Patch stale base, conflict, create, modify, delete, rollback, and partial-failure fixtures;
- Approval digest mismatch and replay rejection;
- registered Command valid, unknown, argv escape, working-directory escape, timeout, cancellation, output limit, and cleanup fixtures;
- criterion `PASS`, `FAIL`, `BLOCKED`, stale, and contradictory Evidence;
- completion rejection without acceptance or current Evidence;
- restart at each external-effect boundary.

## Required Receipt

**P1-S02-R01 — Single-Run Change Receipt**

References:

- Session, Task, and Root Run;
- objective and criteria revisions;
- base and resulting Repository observations;
- Context package digest;
- provider and model when relevant;
- authority and disclosure decisions;
- Patch proposal, Approval, application, changed regions, and rollback reference;
- Command registration, request, result, cleanup, and output Artifacts;
- Evidence by criterion;
- warnings, unknowns, exclusions;
- user acceptance;
- manifest digest.

## Demo

**P1-S02-D01 — Single-Run Change Alpha**

1. Open a fixture Repository with one narrow defect.
2. Start one accepted objective and criteria.
3. Show the sealed Context package summary and Tool set.
4. Run the fake provider in CI or the configured real provider in an optional smoke path.
5. Display one exact Patch proposal.
6. Reject one altered digest.
7. Approve the exact proposal.
8. Apply it and display resulting Repository state.
9. Run one registered verification Command.
10. Demonstrate `FAIL` or `BLOCKED` preventing completion.
11. Run against corrected state and show current passing Evidence.
12. Accept completion and display the Receipt.
13. Restart and inspect the same result.

## Exit

Kiln completes one real source change through explicit authority, controlled effects, current Evidence, user acceptance, and durable recovery.

## Deferred

- Child Runs;
- background work and Attention;
- independent model Verifier;
- TUI;
- managed worktrees;
- arbitrary shell;
- provider routing and fallback;
- runtime Skills;
- code intelligence;
- protocols;
- telemetry.

---

# P1-S03 — Interruption and unknown-effect recovery

**Milestone:** Conservative execution recovery  
**Target window:** Weeks 5–6

## User-visible value

A developer can cancel active model or Command execution, recover from application failure, and reconcile uncertain effects without Kiln guessing, duplicating work, or discarding dirty state.

## Concepts introduced

- operation idempotency keys;
- explicit cancellation decisions;
- process-tree control on the primary supported platform;
- timeout and cleanup Evidence;
- Patch partial-failure and rollback states;
- `orphaned` Run or operation projection;
- stale Evidence invalidation;
- reconciliation action and decision;
- safe retained dirty work and cleanup Approval.

## Security boundary

- cancellation cannot imply cleanup succeeded;
- unknown descendants or effects remain visible;
- no automatic repeat of uncertain external effects;
- no automatic deletion of dirty checkout or Artifact state;
- cleanup requires observed ownership and accepted policy;
- unsupported platform controls are reported as unavailable, not enforced.

## Exit

Every interrupted external effect resolves to observed completion, failure, cancellation, rollback, or explicit orphaned state.

## Deferred

- background Child scheduling;
- multi-platform parity beyond the accepted target;
- containers;
- remote execution.

---

# P1-S04 — One bounded Scout Child

**Milestone:** Visible delegated investigation  
**Target window:** Weeks 7–9

## User-visible value

The Root Run can create one read-only Scout Child, continue or wait, inspect it through the CLI, respond to blocking Attention, cancel it, and receive one bounded evidence-backed result.

## Concepts introduced

- one depth-one Child Run;
- immutable delegation contract;
- independent Child Context;
- narrower explicit grants;
- one active Child Worker lease;
- foreground or background interaction mode;
- Root-visible Attention;
- question, permission, failure, and completion records;
- bounded idempotent result delivery;
- CLI Run list, inspect, enter, answer, deny, cancel, and return-to-Root.

## Limits

```text
Maximum Child depth:          1
Maximum active Child Runs:    1 per Session
Nested delegation:            disabled
Peer communication:           disabled
Shared mutable Context:       disabled
Writing Child:                disabled
Child authority expansion:    disabled
```

## Security boundary

- the Child receives no Parent transcript, secrets, write scope, provider cache, or ambient Tools;
- effective Child authority can only narrow Project and Session limits;
- the Child cannot create or authorize another Child;
- permission requests create Attention but do not grant authority;
- background never means hidden;
- no source, Git, dependency, or configuration mutation occurs;
- result delivery copies references and a bounded structure, not the full transcript.

## Exit

One real delegated investigation improves the Root workflow without hidden work, recursive management, or authority expansion.

---

# P1-S05 — Independent Verifier Child

**Milestone:** Trustworthy Delegated CLI / version 0.1  
**Target window:** Weeks 10–12

## User-visible value

The Root Run can create one independent Verifier Child that evaluates accepted criteria against exact current state and returns `PASS`, `FAIL`, or `BLOCKED` without repairing the evaluated change.

## Concepts introduced

- Verifier role contract;
- independently compiled criteria and state package;
- author Claim separated from verification input;
- read-only Verifier grants;
- no Patch or write Tool;
- controlled registered Command reuse;
- reproduced Evidence and freshness;
- bounded result delivery;
- verification Receipt;
- CLI comparison of Root recommendation and Verifier result.

## Security boundary

- the Verifier cannot edit, apply a Patch, install dependencies, change configuration, or accept its own result;
- author confidence and persuasive completion narrative are excluded from initial Context;
- `PASS` requires reproduced current Evidence for every required criterion;
- missing tool, Environment, state, or requirement information produces `BLOCKED`;
- unknown effects produce `BLOCKED` or orphaned state;
- a completed Verifier Run can carry `PASS`, `FAIL`, or `BLOCKED`.

## Version 0.1 aggregate exit

Version 0.1 completes only when:

- P1-S01 through P1-S05 are integrated;
- one real source change passes the aggregate gate;
- interruption and orphan fixtures pass;
- one Scout Child passes no-write and result-delivery gates;
- one Verifier Child reproduces `PASS`, `FAIL`, and `BLOCKED` fixtures;
- restart reconstructs Root, Child, Attention, Evidence, and Receipt state;
- maximum depth one and one-active-Child limits are enforced;
- CLI actions cover the complete workflow;
- the aggregate version 0.1 Receipt binds the exact final state;
- the owner accepts the milestone.

## Deferred after version 0.1

- TUI;
- nested or concurrent Child graph;
- writing Child;
- managed worktrees;
- LSP, Tree-sitter, persistent code index, and runtime Skills;
- ACP, MCP, OpenAPI, AG-UI, AHP, and A2A;
- local project intelligence;
- embeddings and hosted retrieval;
- telemetry export;
- containers and remote execution;
- publication and formal attestations.

---

# Later evidence-gated slices

## P2-S01 — TUI projection

Consume stable commands, projections, and events after one real Child workflow exists. ExRatatui or another library requires a focused review and prototype. The TUI cannot become state authority.

## P2-S02 — Managed mutation isolation

Add one managed exclusive worktree only after the selected-checkout alpha exposes a real safety or concurrency need.

## P2-S03 — Safe delegated Patch proposal

Allow one read-only Child to return an immutable Patch Artifact. The Root or authorized applying Run owns mutation and verification.

## P2-S04 — Local code intelligence

Add Tree-sitter, selected read-only LSP operations, documentation resolution, and an optional native normalized cache only after measured source-search failures.

## P2-S05 — Capability interoperability

Evaluate ACP, one MCP client capability, one OpenAPI capability, and one accepted Container Environment independently against a concrete workflow. Do not implement protocols for coverage.

## P2-S06 — Local project intelligence

Retrieve prior local patterns only after active-Repository retrieval is stable and approved-root, no-execution, instruction-quarantine, licensing, secret-screening, and disclosure controls are accepted.

# Completion rule

A passing unit test, demo, Schema, Receipt, green obsolete check, or model statement cannot complete a slice alone.

A slice completes only when its accepted criteria, deterministic gates, security and failure gates, demo, Evidence, aggregate Receipt, exact Repository state, and owner acceptance all agree.
