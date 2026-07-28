# Roadmap

**Document type:** Reference

The roadmap is ordered by proof, not platform ambition.

P0-W05 established the planning baseline. P0-W06 established the protocol-neutral domain. P0-W07 established Capability integration. P0-W08 established bounded Context. P0-W09 established protocol strategy. P0-W10 established Git change isolation. P0-W11 establishes delegated Runs, Scout and Verifier contracts, state transitions, global Attention, cancellation, timeout, result delivery, and recovery.

Read these authorities before Phase 1 planning:

- `docs/PLANNING-BASELINE.md`
- `docs/INTERNAL-DOMAIN-MODEL.md`
- `docs/RUN-MODEL.md`
- `docs/DELEGATED-WORK.md`
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

## Phase 0 — Repository foundation

**ID:** P0  
**Goal:** establish Project identity, constraints, documentation, Elixir structure, CI, work governance, agent-ready controls, stable domain semantics, Capability integration, bounded Context, protocol strategy, Git isolation, and delegated-work contracts before production implementation.

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
| P0-W11 | Define delegated Runs, Scout and Verifier roles, state machine, Attention, cancellation, timeouts, result delivery, and orphan recovery. | `work/p0-w11-delegated-work-model` | In progress |

### Phase 0 exit

A new coding Session can identify:

- Project purpose, non-goals, accepted decisions, and invariants;
- Workspace, Project, Repository, Environment, Session, Task, Run, Agent, Worker, invocation, Capability, Context, Change set, Evidence, Receipt, Git, delegation, Attention, cancellation, and recovery boundaries;
- the Root, Parent, Child, Scout, and Verifier contracts;
- the next work package, mutation boundary, acceptance criteria, and required Evidence;
- one preflight command and one complete quality command.

Phase 0 exits after P0-W11 is accepted and Phase 1 work-package order is reconciled.

## Phase 1 — Deterministic local execution and delegated-work kernel

**ID:** P1  
**Goal:** prove durable supervised local work, deterministic Capability selection, bounded Context, visible delegated Runs, isolated Repository mutation, exact-state Evidence, global Attention, and restart recovery before an accepted live model loop.

### Required behavior

Kiln must:

#### Domain and persistence

- register one Workspace, Project, primary Repository, trust policy, and Environment;
- create one Session, accepted objective, root Task, and Root Run;
- create Tasks and Child Runs with durable identity and lineage;
- persist domain, Capability, Context, execution, delegation, Attention, Git coordination, Evidence, and lifecycle events in SQLite;
- reconstruct accepted state and projections after restart.

#### Context and Capability

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

- start, stream, time out, interrupt, cancel, and accurately terminate one supervised Command;
- enter and leave `waiting_for_command` through durable transitions;
- store large output as an Artifact and retain bounded references;
- distinguish clean cancellation from unknown effects.

#### Delegated work

- create every delegated Task as a Child Run before delegated execution;
- support Root, Parent, Child, sibling, and depth-two nested Run projections;
- enforce depth two and three active Children per Session;
- keep queued Children visible;
- support foreground and background delegation without automatic client-focus changes;
- compile independent Child Context;
- issue independent read-only Child grants;
- account for tokens, cost, time, Commands, Artifacts, and Resources per Run;
- prevent peer-to-peer Child communication and shared mutable Context;
- deliver bounded, validated Child results through durable idempotent delivery;
- reconstruct pending delivery after a Parent process crash.

#### Scout proof

- execute one deterministic or fixture Scout Run;
- inspect source or documentation through read-only Capabilities;
- reject source, dependency, Git, and configuration mutation attempts;
- return observed facts, inferences, assumptions, unknowns, scope notes, and Evidence references.

#### Verifier proof

- execute one independent deterministic or fixture Verifier Run;
- compile Context without the author's confidence narrative or write Tools;
- evaluate accepted criteria against exact Repository and Environment state;
- reproduce Evidence;
- return and display `PASS`, `FAIL`, and `BLOCKED` fixtures;
- prove that Verifier completion and `PASS` are separate facts;
- prevent the Verifier from repairing the evaluated implementation or authorizing integration.

#### Attention and control

- maintain one global Session Attention index independent of Run depth;
- route questions, permission requests, conflicts, failures, verification blockers, merge blockers, Resource limits, and stale Evidence;
- support answer, enter Run, route to Parent, deny, pause, and cancel actions;
- prohibit `waiting_for_user` or `waiting_for_permission` without an Attention item in the same transaction;
- escalate blocking Attention without auto-answering or auto-granting it;
- pause, resume, and cancel one Child independently;
- cancel active descendants when the Root Run is canceled;
- preserve partial Artifacts and Evidence after cancellation.

#### Git and Evidence

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

#### Crash and orphan recovery

- recover after Root or Parent process crash without losing Child state;
- recover one Child Worker crash when retry is safe;
- prevent duplicate Child creation and duplicate result delivery;
- mark unknown external effects as `orphaned`;
- block orphaned Runs from reporting success, satisfying Tasks, or authorizing integration;
- create one compact Checkpoint;
- expose all proof state through a basic CLI projection.

### Provisional work packages

The post-P0-W11 reconciliation can replace these boundaries.

| ID | Purpose | Branch | Depends on | Status |
| --- | --- | --- | --- | --- |
| P1-W01 | Define minimum domain, delegation, policy, Context, Capability, Evidence, Git, Attention, cancellation, timeout, and event types. | `work/p1-w01-kernel-domain` | P0 | Replacement plan required |
| P1-W02 | Persist the append-oriented journal and reconstruct Session, Task, Run graph, delivery, and control projections. | `work/p1-w02-event-journal` | P1-W01 | Replacement plan required |
| P1-W03 | Supervise Commands, bounded output, waiting states, timeouts, cancellation, and termination. | `work/p1-w03-command-supervision` | P1-W01, P1-W02 | Reconciliation required |
| P1-W04 | Implement deterministic Run scheduling, Worker leases, global Attention, Child result delivery, and crash recovery. | `work/p1-w04-run-control` | P1-W01 through P1-W03 | New package proposed |
| P1-W05 | Observe Git, manage one isolated task worktree and lease, bind Evidence, and reconcile external changes. | `work/p1-w05-git-isolation` | P1-W01 through P1-W04 | New or major expansion required |
| P1-W06 | Compile bounded Context and select compact Capability projections for Root, Scout, and Verifier fixtures. | `work/p1-w06-context-capability-proof` | P1-W01 through P1-W05 | New package proposed |
| P1-W07 | Expose CLI state and recover interrupted Session, Run, Command, Attention, delivery, cancellation, lease, and worktree state. | `work/p1-w07-cli-recovery` | P1-W02 through P1-W06 | Replacement required |
| P1-W08 | Execute the complete Phase 1 acceptance scenario, independent verification, projected merge, approval, integration, Receipt, cleanup, and restart proof. | `work/p1-w08-phase-proof` | P1-W06, P1-W07 | Replacement scenario required |

### Phase 1 reconciliation decisions

Before P1-W01 implementation begins, decide exact work-package ownership for:

- domain and event schemas;
- SQLite projections and transaction boundaries;
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
- CLI navigation and control;
- Phase 1 restart and completion proof.

Each accepted implementation work package requires a plan.

### Phase 1 exit

Kiln can create, execute, delegate, inspect, interrupt, cancel, isolate, verify, integrate, restart, reconstruct, navigate, authorize, compile, retrieve, invalidate, externalize, and accurately report one manual Project, Session, Root Run, Scout Run, Verifier Run, nested Child fixture, global Attention flow, supervised Command, isolated mutation, Change set, Evidence set, projected merge, integration decision, Receipt, and Checkpoint scenario without a live model, MCP server, remote API, Context7, browser automation, or remote hosting provider.

## Phase 2 — Provider and model loop

**ID:** P2

### Required behavior

- one Kiln-native provider-neutral model-invocation contract;
- one direct provider adapter;
- streamed normalized invocation events;
- one provider-backed Root Run;
- versioned Agent binding;
- one model-backed Scout Run and one model-backed Verifier Run after deterministic delegated-work semantics pass;
- independent Child Context and grants;
- compact phase-relevant Tool projection and lazy Skill loading;
- persistent model, Tool, Attention, and delivery events;
- token, cost, Context, and per-Run accounting;
- Privacy-policy evaluation before egress;
- interruption and cancellation;
- Project Steward projection;
- Claims and completion summary without unsupported completion.

The first direct provider target is MiniMax because the Project owner has an active Token Plan.

Kimi and Codex require separate managed-client adapter evaluation because platform sign-in is owned by their official clients.

Provider experiments can begin on isolated `spike/` branches. Experimental adapters do not satisfy Phase 2 until Phase 1 exits.

### Phase 2 exit

Kiln completes one small Repository change through a provider-backed Root Run, uses a bounded Scout and independent Verifier, preserves Run lineage and Git isolation, resumes after restart, and reports current Evidence, provenance, accounting, failures, warnings, and unresolved work.

## Phase 3 — Evidence-backed completion

Required:

- observed mutation records and Change sets bound to Repository state;
- structured Claims and Evidence;
- exact commit, dirty-state, and dependency binding;
- Evidence freshness and invalidation;
- deterministic Receipts;
- Capability, Context, delegation, Git, and integration provenance;
- independent Verifier Runs for material Claims;
- projected-merge Evidence;
- unresolved-failure and blocker reporting;
- completion readiness;
- token cost by accepted Change set.

### Phase 3 exit

A passing test becomes stale after a relevant change, and Kiln refuses to treat it as current. A final Receipt identifies the tested state, Verifier result and reproduced Evidence, integration decision, delegated-work provenance, and unresolved proof gaps.

## Phase 4 — Context and recovery

Required:

- Context authority, trust, sensitivity, freshness, and transformation history;
- deterministic inclusion, exclusion, budgets, and progressive disclosure;
- per-Run immutable Context manifests;
- lazy Tool and Skill loading;
- authoritative version-matched documentation resolution;
- independent Root, Scout, and Verifier Context;
- Repository-state and worktree binding;
- token cost by Run and accepted Change set;
- Checkpoints, compaction, and recovery of Run graph, Attention, delivery, cancellation, Git ownership, policy, Context, Claims, Evidence, and Steward state.

## Phase 5 — Extension and adapter boundary

Required:

- supervised external processes;
- versioned language-neutral extension protocol;
- adapter-owned negotiation and identifiers;
- Kiln-native Tool and Resource registration;
- progress and cancellation;
- explicit Capability declarations;
- Privacy-policy evaluation;
- bounded result and Artifact handling;
- crash isolation;
- conformance tests that preserve core semantics;
- one non-Elixir example adapter.

A2A remains reserved for independent external agents. Local Child Runs use Kiln's native delegated-work model.

## Phase 6 — Phoenix LiveView

Required:

- Project, Session, Task, and Run graph views;
- foreground and background Child visibility;
- global Attention and all user actions;
- model and Tool streams;
- Context, Capability, accounting, Artifact, Claim, Evidence, and Receipt views;
- Git branch, worktree, lease, diff, verification, integration, and cleanup views;
- interruption, pause, cancellation, and reconnect;
- Client-local focus.

## Phase 7 — TypeScript SDK

Required:

- typed Tool, Resource, Capability, Context, Git, and delegation contracts;
- cancellation and progress;
- normalized results and Artifact references;
- adapter mapping helpers;
- compatibility and conformance checks;
- test helpers and examples.

## Pending roadmap reconciliation

P0-W04 through P0-W11 constrain the product but do not finalize implementation proof order.

The next planning pass must prevent later work from:

- hiding delegated work inside Tool calls or transcripts;
- implementing live model Children before deterministic Run control works;
- treating Parent lineage as OTP supervision;
- allowing Child authority inheritance or expansion;
- adding Builder personas before a safe writing-role contract exists;
- letting Verifiers repair or self-authorize integration;
- allowing silent blockers or depth-dependent Attention;
- confusing Verifier completion with `PASS`;
- treating timeout or process death as clean cancellation;
- retrying unknown effects without reconciliation;
- creating writing Children before Git isolation and leases exist;
- treating passing checks as merge authority;
- using remote protocols before local deterministic semantics are proven.

## Deferred

- Gleam modules;
- Rust sandbox helper;
- ACP, MCP, LSP, A2A, AG-UI, and AHP implementations;
- Context7 until local documentation resolution is proven;
- embedding or vector databases until a retrieval case justifies them;
- browser automation framework;
- hosted collaboration and remote execution;
- Builder or other writing Child roles;
- model-authored Patch Artifacts;
- deeper or wider delegation limits;
- peer-to-peer Child communication;
- shared mutable Context;
- detached Children;
- recursive manager hierarchies;
- automatic permission expansion;
- remote merge queues and automatic Git publication;
- cross-Repository atomic changes;
- automatic conflict resolution and force-push;
- multi-user ownership and distributed locking;
- Git replacement abstractions.
