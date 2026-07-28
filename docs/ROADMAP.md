# Roadmap

**Document type:** Reference

The roadmap is ordered by proof, not platform ambition.

P0-W05 established the planning baseline. P0-W06 established the protocol-neutral domain. P0-W07 established Capability integration. P0-W08 established bounded Context. P0-W09 established protocol strategy. P0-W10 established Git change isolation. P0-W11 established delegated Runs, Scout and Verifier contracts, global Attention, cancellation, timeout, result delivery, and recovery. P0-W12 establishes the initial CLI and TUI, terminal navigation, public interface projections, and deterministic interaction prototype.

Read these authorities before Phase 1 planning:

- `docs/PLANNING-BASELINE.md`
- `docs/INTERNAL-DOMAIN-MODEL.md`
- `docs/RUN-MODEL.md`
- `docs/DELEGATED-WORK.md`
- `docs/CLI-TUI.md`
- `docs/PROJECT-STEWARDSHIP.md`
- `docs/CAPABILITY-INTEGRATION.md`
- `docs/CONTEXT-SYSTEM.md`
- `docs/PROTOCOL-CAPABILITY-MAP.md`
- `docs/GIT-CHANGE-ISOLATION.md`
- `docs/PLAN-RECONCILIATION.md`

## Work identifiers

```text
P1          Phase 1
P1-W02      Phase 1 work package 2
P1-X01      Phase 1 experiment 1
```

Each work package follows `docs/BRANCHING-AND-WORK-PLANNING.md`.

## Phase 0 — Repository and product foundation

**ID:** P0  
**Goal:** establish Project identity, constraints, documentation, Elixir structure, CI, work governance, domain semantics, Capability integration, bounded Context, protocol strategy, Git isolation, delegated-work contracts, and the initial terminal interaction before production implementation.

### Work packages

| ID | Purpose | Branch | Status |
| --- | --- | --- | --- |
| P0-W01 | Establish the Repository foundation. | `agent/bootstrap-project-foundation` | Integrated through pull request 1 |
| P0-W02 | Define branch-linked planning, Evidence rules, templates, and prose linting. | `work/p0-w02-work-governance` | Integrated through the approved planning stack |
| P0-W03 | Add agent-friendly code rules, Project invariants, Skills, specialist reviewers, and deterministic development checks. | `work/p0-w03-agent-ready-development` | Integrated through the approved planning stack |
| P0-W04 | Define first-class Runs, the navigable Run graph, and Project Steward responsibility. | `work/p0-w04-run-graph-stewardship` | Integrated through the approved planning stack |
| P0-W05 | Audit planning authority, conflicts, implementation Evidence, and document status. | `work/p0-w05-planning-baseline` | Integrated through the approved planning stack |
| P0-W06 | Define the protocol-neutral domain, contracts, adapter boundary, and Run-centered execution unit. | `work/p0-w06-internal-domain-model` | Integrated through the approved planning stack |
| P0-W07 | Define Capability integration hierarchy, broker, compact Tools, normalization, duplicates, and non-MCP boundaries. | `work/p0-w07-capability-integration` | Integrated through the approved planning stack |
| P0-W08 | Define bounded Context compilation, documentation resolution, token budgets, progressive disclosure, and observability. | `work/p0-w08-context-system` | Integrated through the approved planning stack |
| P0-W09 | Define and rank protocol and standards support behind adapters. | `work/p0-w09-protocol-strategy` | Integrated through pull request 13 and the planning-stack integration |
| P0-W10 | Define Git change isolation, worktree leases, exact-state Evidence, integration, security, and recovery. | `work/p0-w10-git-change-isolation` | Integrated through pull request 14 |
| P0-W11 | Define delegated Runs, Scout and Verifier roles, state machine, Attention, cancellation, timeouts, result delivery, and orphan recovery. | `work/p0-w11-delegated-work-model` | Integrated through pull request 15 |
| P0-W12 | Define the initial CLI and TUI, Run-first navigation, interface projections, ExRatatui boundary, and deterministic prototype. | `work/p0-w12-cli-tui-design` | In progress |

### Phase 0 exit

A new coding Session can identify:

- Project purpose, non-goals, accepted decisions, and invariants;
- Workspace, Project, Repository, Environment, Session, Task, Run, Agent, Worker, invocation, Capability, Context, Change set, Evidence, Receipt, Git, delegation, Attention, cancellation, interface, and recovery boundaries;
- Root, Parent, Child, Scout, Verifier, CLI, TUI, and Client-state contracts;
- shared durable state and client-local state;
- the next work package, mutation boundary, acceptance criteria, and required Evidence;
- one preflight command and one complete quality command.

Phase 0 exits after P0-W12 is accepted and the Phase 1 work-package order is reconciled.

## Phase 1 — Deterministic local execution and interaction kernel

**ID:** P1  
**Goal:** prove durable supervised local work, deterministic Capability selection, bounded Context, visible delegated Runs, global Attention, isolated Repository mutation, exact-state Evidence, CLI and TUI control, and restart recovery before an accepted live model loop.

### Required behavior

#### Domain and persistence

Kiln must:

- register one Workspace, Project, primary Repository, trust policy, and Environment;
- create one Session, accepted objective, root Task, and Root Run;
- create Tasks and Child Runs with durable identity and lineage;
- persist domain, Capability, Context, execution, delegation, Attention, Git coordination, Evidence, interface, and lifecycle events in SQLite;
- reconstruct accepted state and projections after restart;
- consolidate `waiting_for_command`, expanded Attention, and `kiln.interface/v0` into Phase 1 validators.

#### Context and Capability

Kiln must:

- create immutable Context manifests without a live provider;
- enforce Run and phase Context budgets;
- retrieve one narrow source excerpt just in time;
- invalidate stale Context after a Repository-state change;
- expose no more than eight intent-level Tools in the proof package;
- account for Tool-schema tokens;
- issue scoped Capability grants;
- register native Repository, controlled Git CLI, and Project verification implementations;
- select one implementation deterministically and normalize its result.

#### Command execution

Kiln must:

- start, stream, time out, interrupt, cancel, and accurately terminate one supervised Command;
- enter and leave `waiting_for_command` through durable transitions;
- store large output as an Artifact and retain bounded references;
- distinguish clean cancellation from unknown effects;
- expose bounded Command summaries to the CLI and TUI.

#### Delegated work

Kiln must:

- create every delegated Task as a Child Run before delegated execution;
- support Root, Parent, Child, sibling, and depth-two nested Run projections;
- enforce depth two and three active Children per Session;
- keep queued Children visible;
- support foreground and background delegation without automatic Client-focus changes;
- compile independent Child Context;
- issue independent read-only Child grants;
- account for tokens, cost, time, Commands, Artifacts, and Resources per Run;
- prevent peer-to-peer Child communication and shared mutable Context;
- deliver bounded, validated Child results through durable idempotent delivery;
- reconstruct pending delivery after a Parent process crash.

#### Scout proof

Kiln must:

- execute one deterministic or fixture Scout Run;
- inspect source or documentation through read-only Capabilities;
- reject source, dependency, Git, and configuration mutation attempts;
- return observed facts, inferences, assumptions, unknowns, scope notes, and Evidence references.

#### Verifier proof

Kiln must:

- execute one independent deterministic or fixture Verifier Run;
- compile Context without the author's confidence narrative or write Tools;
- evaluate accepted criteria against exact Repository and Environment state;
- reproduce Evidence;
- return and display `PASS`, `FAIL`, and `BLOCKED` fixtures;
- prove that Verifier completion and `PASS` are separate facts;
- prevent the Verifier from repairing the evaluated implementation or authorizing integration.

#### Attention and control

Kiln must:

- maintain one global Session Attention index independent of Run depth;
- route questions, permission requests, conflicts, failures, verification blockers, merge blockers, Resource limits, stale Evidence, and orphan recovery;
- support answer, enter Run, route to Parent, deny, pause, cancel, acknowledge, and inspect actions;
- prohibit `waiting_for_user` or `waiting_for_permission` without an Attention item in the same transaction;
- escalate blocking Attention without auto-answering or auto-granting;
- pause, resume, and cancel one Child independently;
- cancel active descendants when the Root Run is canceled;
- preserve partial Artifacts and Evidence after cancellation;
- resolve concurrent Client actions through expected revisions and idempotency.

#### Git and Evidence

Kiln must:

- capture Git state and Repository fingerprint;
- create one short-lived task branch and one exclusive writable worktree for a deterministic mutating Run;
- acquire one scoped worktree lease and prevent a second mutation owner;
- validate one Patch Artifact through the Git isolation path without treating it as an initial model-backed Child role;
- create one Change set and commit;
- bind verification Evidence to the exact commit;
- invalidate Evidence after a relevant Repository change;
- create and verify projected merged state against protected trunk;
- require explicit user integration approval;
- integrate one coherent Change set locally;
- issue one final Receipt;
- clean one safe worktree and preserve one dirty or uncertain worktree during recovery.

#### Interface projections

Kiln must:

- expose public `kiln.interface/v0` event, snapshot, Client-state, input-intent, and CLI-result contracts;
- build pure projection reducers from durable events;
- create one shared interface-facing projection service;
- provide a local runtime endpoint that survives Client disconnect;
- support snapshot plus event replay;
- deduplicate replayed events;
- detect event gaps and stale Client cursors;
- apply backpressure without dropping lifecycle, Attention, permission, cancellation, Evidence invalidation, result, or recovery events;
- externalize complete logs and large output;
- separate focused Run from selected Run;
- keep focus, selection, navigation history, scroll, layout, and drafts client-local;
- keep Run execution, Attention, permissions, transcripts, Artifacts, Evidence, Receipts, and Git ownership shared;
- prevent renderer failure from terminating active Runs.

#### CLI proof

Kiln must support deterministic versions of:

```text
kiln
kiln start
kiln resume
kiln runs
kiln run show
kiln run enter
kiln run pause
kiln run resume
kiln run cancel
kiln attention
kiln answer
kiln approve
kiln deny
kiln artifacts
kiln evidence
kiln receipts
kiln status
```

The CLI must:

- work without terminal cursor control;
- produce text, JSON, and JSON Lines;
- use stable exit codes;
- enforce explicit destructive confirmation;
- support expected revisions and idempotency;
- avoid exposing persistence schemas.

#### TUI proof

The deterministic terminal prototype must include:

- one Root Run;
- at least two Child Runs;
- one running Scout;
- one blocked Child;
- one completed Verifier;
- one depth-two Child;
- conversation-first main view;
- breadcrumb;
- Child cards;
- Run-tree overlay;
- global Attention inbox;
- keyboard-complete navigation;
- basic mouse;
- explicit composer target;
- simulated streaming output;
- simulated Command activity;
- one permission request;
- one Artifact;
- one Evidence item;
- one Receipt;
- one stale-Evidence transition;
- pause, resume, and cancel;
- wide, standard, narrow, and constrained layouts;
- renderer restart;
- durable projection reconstruction;
- headless tests.

ExRatatui can be added only after dependency review. It remains behind a renderer behaviour.

#### Crash and orphan recovery

Kiln must:

- recover after Root or Parent process crash without losing Child state;
- recover one Child Worker crash when retry is safe;
- prevent duplicate Child creation and duplicate result delivery;
- mark unknown external effects as `orphaned`;
- block orphaned Runs from reporting success, satisfying Tasks, or authorizing integration;
- recover Client focus to the nearest surviving ancestor;
- preserve dirty or uncertain worktrees;
- create one compact Checkpoint;
- expose all proof state through CLI and TUI projections.

### Provisional work packages

The post-P0-W12 reconciliation can replace these boundaries.

| ID | Purpose | Branch | Depends on | Status |
| --- | --- | --- | --- | --- |
| P1-W01 | Consolidate minimum domain, delegation, interface, policy, Context, Capability, Evidence, Git, Attention, cancellation, timeout, and event contracts. | `work/p1-w01-kernel-contracts` | P0 | Replacement plan required |
| P1-W02 | Persist the append-oriented journal and rebuild Session, Run graph, Attention, delivery, and interface projections. | `work/p1-w02-event-journal-projections` | P1-W01 | Replacement plan required |
| P1-W03 | Supervise Commands, bounded output, waiting states, timeouts, cancellation, and termination. | `work/p1-w03-command-supervision` | P1-W01, P1-W02 | Reconciliation required |
| P1-W04 | Implement deterministic scheduling, Worker leases, global Attention, Child result delivery, and crash recovery. | `work/p1-w04-run-control` | P1-W01 through P1-W03 | New package proposed |
| P1-W05 | Observe Git, manage one isolated worktree and lease, bind Evidence, and reconcile external changes. | `work/p1-w05-git-isolation` | P1-W01 through P1-W04 | New or major expansion required |
| P1-W06 | Compile bounded Context and select compact Capability projections for Root, Scout, and Verifier fixtures. | `work/p1-w06-context-capability-proof` | P1-W01 through P1-W05 | New package proposed |
| P1-W07 | Implement public CLI commands, structured output, revision checks, local runtime attach, and recovery. | `work/p1-w07-cli-control` | P1-W02 through P1-W06 | Replacement required |
| P1-W08 | Implement the ExRatatui-backed deterministic TUI prototype, projection replay, navigation, Attention, inspection, and headless tests. | `work/p1-w08-tui-prototype` | P1-W02, P1-W04, P1-W07 | New package proposed |
| P1-W09 | Execute the complete Phase 1 acceptance scenario, projected merge, approval, integration, Receipt, cleanup, Client restart, and runtime restart proof. | `work/p1-w09-phase-proof` | P1-W06 through P1-W08 | Replacement scenario required |

### Phase 1 reconciliation decisions

Before P1-W01 implementation begins, decide exact work-package ownership for:

- domain and event schema consolidation;
- SQLite projections and transaction boundaries;
- local runtime endpoint and service launch;
- projection service and event bus;
- Run scheduler and active-Child limit;
- Worker lease and heartbeat logic;
- state-transition validation;
- global Attention and notification projection;
- cancellation and timeout control;
- Parent and Child crash recovery;
- result validation and idempotent delivery;
- fake Scout and Verifier Workers;
- Context compilation and read-only grants;
- Repository and Git adapter behavior;
- worktree isolation and reconciliation;
- exact-state Evidence;
- public CLI envelopes and exit codes;
- ExRatatui dependency review and renderer boundary;
- TUI navigation, composer, layouts, inspection, and headless tests;
- Client-local state persistence;
- Phase 1 restart and completion proof.

Each accepted implementation work package requires a plan.

### Phase 1 exit

Kiln can create, execute, delegate, inspect, interrupt, cancel, isolate, verify, integrate, restart, reconstruct, navigate, authorize, compile, retrieve, invalidate, externalize, and accurately report one manual Project, Session, Root Run, Scout Run, Verifier Run, nested Child fixture, global Attention flow, supervised Command, isolated mutation, Change set, Evidence set, projected merge, integration decision, Receipt, Checkpoint, CLI flow, and TUI flow without a live model, MCP server, remote API, Context7, browser automation, Phoenix, ACP, AG-UI, or remote hosting provider.

## Phase 2 — Provider and model loop

**ID:** P2

Required:

- one Kiln-native provider-neutral model-invocation contract;
- one direct provider adapter;
- streamed normalized invocation events;
- one provider-backed Root Run;
- versioned Agent binding;
- one model-backed Scout and one model-backed Verifier after deterministic delegated-work and interface semantics pass;
- independent Child Context and grants;
- compact phase-relevant Tool projection and lazy Skill loading;
- persistent model, Tool, Attention, delivery, and interface events;
- token, cost, Context, and per-Run accounting;
- Privacy-policy evaluation before egress;
- interruption and cancellation;
- Project Steward projection;
- CLI and TUI model-stream presentation;
- Claims and completion summary without unsupported completion.

The first direct provider target is MiniMax because the Project owner has an active Token Plan.

Kimi and Codex require separate managed-client adapter evaluation because platform sign-in is owned by their official Clients.

Provider experiments can begin on isolated `spike/` branches. Experimental adapters do not satisfy Phase 2 until Phase 1 exits.

### Phase 2 exit

Kiln completes one small Repository change through a provider-backed Root Run, uses a bounded Scout and independent Verifier, preserves Run lineage and Git isolation, survives Client reconnect, and reports current Evidence, provenance, accounting, failures, warnings, and unresolved work through the CLI and TUI.

## Phase 3 — Evidence-backed completion

Required:

- observed mutation records and Change sets bound to Repository state;
- structured Claims and Evidence;
- exact commit, dirty-state, and dependency binding;
- Evidence freshness and invalidation;
- deterministic Receipts;
- Capability, Context, delegation, Git, interface, and integration provenance;
- independent Verifier Runs for material Claims;
- projected-merge Evidence;
- unresolved-failure and blocker reporting;
- completion readiness;
- precise proposed, applied, executed, verified, accepted, integrated, and delivered interface labels;
- token cost by accepted Change set.

### Phase 3 exit

A passing test becomes stale after a relevant change, and Kiln refuses to treat it as current. A final Receipt identifies the tested state, Verifier result and reproduced Evidence, integration decision, delegated-work provenance, and unresolved proof gaps. CLI and TUI projections agree.

## Phase 4 — Context and recovery

Required:

- Context authority, trust, sensitivity, freshness, and transformation history;
- deterministic inclusion, exclusion, budgets, and progressive disclosure;
- per-Run immutable Context manifests;
- lazy Tool and Skill loading;
- authoritative version-matched documentation resolution;
- independent Root, Scout, and Verifier Context;
- Repository-state and worktree binding;
- token and Context observability;
- Checkpoints, interruption summaries, and traceable compaction;
- recovery of Git ownership, policy, Capability, Context, Claims, Evidence, Steward state, interface snapshots, and Client cursors.

## Phase 5 — Extension and adapter boundary

Required:

- supervised external processes;
- versioned language-neutral extension protocol;
- adapter-owned negotiation and identifier mapping;
- Tool and Resource registration through Kiln-native contracts;
- Capability registration through the accepted hierarchy;
- progress and cancellation;
- Capability declarations without ambient grants;
- Privacy-policy evaluation;
- output normalization and Artifact limits;
- phase-specific Tool projection and schema-budget compatibility;
- duplicate detection and replacement groups;
- crash isolation;
- conformance tests that prove adapters do not alter core or interface semantics;
- one non-Elixir example extension or adapter.

MCP evaluation belongs here or later only after a concrete Capability justifies it. MCP is not required for the Phase 5 exit.

## Phase 6 — Phoenix LiveView

Required:

- Project, Session, and Workspace views;
- Task and Run tree navigation;
- model and Tool streams;
- global Attention;
- Approval and permission prompts;
- Capability and Context views;
- Git, Change set, verification, integration, and cleanup views;
- Claim, Evidence, Receipt, Artifact, and Context views;
- reconnect without terminating the runtime;
- Client-local focus;
- reuse of the accepted public projection and input-intent contracts.

Phoenix must not fork Run, Attention, permission, Evidence, or navigation semantics from the CLI and TUI.

## Phase 7 — TypeScript SDK

Required:

- typed Kiln-native Tool and Resource registration;
- Capability implementation registration;
- JSON Schema contracts;
- Capability declarations;
- cancellation and progress;
- compatibility checks;
- adapter mapping helpers;
- normalized result helpers;
- bounded Context-result and Artifact-reference helpers;
- public interface event, snapshot, and CLI-result helpers when justified;
- test helpers;
- example extensions and adapters.

## Pending roadmap reconciliation

P0-W04 through P0-W12 constrain the product but do not finalize the implementation proof order.

The next planning pass must replace or confirm the provisional Phase 1 packages and must not:

- create writing Child Runs before isolation and a writing role exist;
- treat Git branches as Run identity;
- allow Verifiers to repair authored changes;
- treat passing checks as merge authority;
- omit projected-merge Evidence;
- lose Context or Evidence bindings after Repository changes;
- use remote providers or protocols before deterministic local semantics;
- implement a TUI before projection reducers and CLI contracts;
- let ExRatatui types enter domain modules;
- make renderer state authoritative;
- couple keypresses directly to domain mutation;
- omit Client race and stale-projection handling;
- build stacks, candidate tournaments, or integration branches before independent task mode works.

## Deferred

- Gleam modules;
- Rust sandbox helper;
- ACP adapter implementation;
- MCP client or server until a concrete Capability justifies it;
- LSP client and server selection;
- A2A, AG-UI, and AHP adapters;
- remote Capability APIs beyond the first accepted provider;
- Context7 until local documentation resolution is proven;
- embeddings or vector databases until an accepted retrieval case justifies them;
- browser automation framework;
- hosted collaboration;
- plugin registry and plugin-defined widgets;
- browser IDE;
- remote execution;
- unlimited delegation depth;
- remote hosting-provider automation;
- remote merge queues;
- automatic Git publication;
- stacked, candidate, and timeboxed integration runtime modes until independent mode is proven;
- cross-Repository atomic changes;
- automatic conflict resolution and force-push;
- multi-user branch ownership and distributed locking;
- Git replacement abstractions;
- SSH TUI;
- arbitrary pane layouts;
- full Markdown fidelity;
- inline terminal images;
- embedded terminal multiplexing;
- extensive themes and animation;
- dozens of concurrent visible Runs.
