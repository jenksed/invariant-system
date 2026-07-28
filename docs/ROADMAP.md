# Roadmap

**Document type:** Reference

The roadmap is ordered by proof, not platform ambition.

P0-W05 established the planning baseline. P0-W06 established the protocol-neutral internal domain model. P0-W07 established Capability integration and the broker. P0-W08 established the bounded Context system and documentation resolver. P0-W09 established the protocol and standards strategy. P0-W10 establishes Git change isolation, worktree ownership, Evidence staleness, integration, and crash reconciliation.

Read these authorities before Phase 1 planning:

- `docs/PLANNING-BASELINE.md`
- `docs/INTERNAL-DOMAIN-MODEL.md`
- `docs/CAPABILITY-INTEGRATION.md`
- `docs/CONTEXT-SYSTEM.md`
- `docs/PROTOCOL-CAPABILITY-MAP.md`
- `docs/GIT-CHANGE-ISOLATION.md`
- `docs/PLAN-RECONCILIATION.md`

## Work identifiers

Kiln uses:

```text
P1          Phase 1
P1-W02      Phase 1 work package 2
P1-X01      Phase 1 experiment 1
```

Each work package follows `docs/BRANCHING-AND-WORK-PLANNING.md`.

## Phase 0 — Repository foundation

**ID:** P0  
**Goal:** establish Project identity, constraints, documentation, Elixir structure, CI, work governance, agent-ready controls, stable domain semantics, Capability integration, bounded Context, protocol strategy, and Git change isolation before production implementation.

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
| P0-W08 | Define bounded Context compilation, documentation resolution, token budgets, progressive disclosure, and Context observability. | `work/p0-w08-context-system` | Integrated through the approved planning stack |
| P0-W09 | Define and rank protocol and standards support behind adapters. | `work/p0-w09-protocol-strategy` | Integrated through pull request 13 and the planning-stack integration |
| P0-W10 | Define Git change isolation, worktree leases, exact-state Evidence, integration, security, and recovery. | `work/p0-w10-git-change-isolation` | In progress |

### Phase 0 exit

A new coding Session can identify:

- Project purpose and non-goals;
- accepted and provisional decisions;
- integration state and Project invariants;
- Workspace, Project, Repository, Environment, Session, Task, Run, Agent, Worker, model-invocation, Capability, Context, Change set, Evidence, Receipt, branch-contract, worktree, and lease boundaries;
- adapter and protocol boundaries;
- the next work package, mutation boundary, acceptance criteria, and required Evidence;
- one preflight command and one complete quality command.

Phase 0 exits after P0-W10 is accepted and the Phase 1 work-package order is reconciled.

## Phase 1 — Deterministic local execution and change kernel

**ID:** P1  
**Goal:** prove durable supervised local work, deterministic Capability selection, bounded Context compilation, isolated Repository mutation, exact-state Evidence, and restart recovery before an accepted model-driven loop.

### Required behavior

Kiln must:

- register one Workspace;
- register one Project;
- bind one primary Repository and Repository trust policy;
- define one Environment;
- create one Session, accepted objective, root Task, and Root Run;
- persist domain, Capability, Context, execution, Git coordination, Evidence, and lifecycle events in SQLite;
- reconstruct accepted state after restart;
- create one immutable Context manifest and bounded package without a live provider;
- enforce one Run Context ceiling and phase target;
- retrieve one file excerpt, symbol, or relevant line range just in time;
- invalidate and replace one stale Context item after a Repository-state change;
- expose no more than eight intent-level Tools in the proof package;
- account for Tool-schema tokens;
- issue one scoped Capability grant;
- register one native Repository implementation;
- register one controlled Git CLI adapter;
- register one Project verification CLI;
- observe implementation availability and compatibility;
- filter and select one implementation deterministically;
- collapse one duplicate Capability group behind one intent-level Tool;
- start one supervised Command;
- stream bounded output;
- store large output as an Artifact and include one bounded reference;
- support timeout, interruption, and cancellation;
- record termination accurately;
- capture Git state and a Repository fingerprint;
- create one short-lived task branch and one exclusive writable worktree;
- acquire one scoped worktree lease for one mutating Run;
- prevent a second Run from mutating that worktree;
- accept one Patch Artifact from a restricted Child Run without granting branch ownership;
- create one Change set and commit;
- bind focused verification Evidence to that exact commit;
- run one independent read-only Verifier that cannot repair the branch;
- invalidate Evidence after a relevant Repository change;
- create and verify one projected merged state against current protected trunk;
- require explicit user integration approval;
- integrate one coherent Change set locally;
- issue one final Receipt;
- clean one safe managed worktree;
- preserve one dirty or uncertain worktree during a recovery scenario;
- create one compact Checkpoint;
- expose state through a basic command-line projection.

### Provisional work packages

The post-P0-W10 reconciliation can replace these boundaries.

| ID | Purpose | Branch | Depends on | Status |
| --- | --- | --- | --- | --- |
| P1-W01 | Define minimum domain, policy, Context, Capability, Evidence, Git contract, and event types. | `work/p1-w01-kernel-domain` | P0 | Replacement plan required |
| P1-W02 | Persist the append-oriented journal and reconstruct core projections. | `work/p1-w02-event-journal` | P1-W01 | Replacement plan required |
| P1-W03 | Supervise Commands, bounded output, cancellation, and termination. | `work/p1-w03-command-supervision` | P1-W01, P1-W02 | Reconciliation required |
| P1-W04 | Observe Git, manage one isolated task worktree and lease, bind Evidence, and reconcile external changes. | `work/p1-w04-git-observation-isolation` | P1-W01 through P1-W03 | New or major expansion required |
| P1-W05 | Compile bounded Context and select compact Capability projections without a live model. | `work/p1-w05-context-capability-proof` | P1-W01 through P1-W04 | New package proposed |
| P1-W06 | Expose CLI state and recover interrupted Session, Run, Command, lease, and worktree state. | `work/p1-w06-cli-recovery` | P1-W02 through P1-W05 | Replacement required |
| P1-W07 | Execute the Phase 1 acceptance scenario, independent verification, projected merge, approval, integration, Receipt, cleanup, and restart proof. | `work/p1-w07-phase-proof` | P1-W05, P1-W06 | Replacement scenario required |

### Phase 1 reconciliation decisions

Before P1-W01 implementation begins, decide where to prove:

- Project and Repository membership;
- Task, Run, Agent, Worker, and invocation identity;
- event and projection schemas;
- Capability registration, availability, selection, grants, normalization, duplicates, and fallback;
- Context requests, items, manifests, packages, budgets, invalidation, and observations;
- native Repository and Git adapter behavior;
- branch contract, worktree, lease, Git operation, and reconciliation persistence;
- Repository-scoped Git mutation serialization;
- Project verification CLI discovery and execution;
- exact commit and dirty-fingerprint Evidence binding;
- Patch Artifact validation and atomic application;
- projected-merge verification;
- independent Verifier timing and authority;
- manual integration approval;
- cleanup and orphan recovery;
- Repository trust and Privacy policy timing;
- Claim, Evidence, Receipt, Artifact, and Checkpoint minimums;
- fake navigable Child Runs with independent Context and grants;
- Client-local focus, attention routing, and Project Steward projection;
- the version 0.1 completion scenario.

Each accepted implementation work package requires a plan.

### Phase 1 exit

Kiln can create, execute, interrupt, isolate, verify, integrate, restart, reconstruct, navigate, select, authorize, normalize, compile, retrieve, invalidate, externalize, and accurately report one manual Project, Session, Task, Root Run, restricted Child Patch Artifact, isolated mutating Run, Context package, native Repository operation, Git operation, worktree lease, Command, Change set, Artifact, Claim, Evidence, independent verification, projected merge, integration decision, Receipt, and Checkpoint scenario without a live model, MCP server, remote API, Context7, browser automation, or remote hosting provider.

## Phase 2 — Provider and model loop

**ID:** P2

### Required behavior

- one Kiln-native provider-neutral model-invocation contract;
- one direct provider adapter;
- model Capability discovery or explicit configuration;
- streamed normalized model-invocation events;
- one provider-backed Root Run;
- versioned Agent binding;
- one new immutable Context manifest per invocation;
- smallest-sufficient Context packages constrained by Run and phase budgets;
- stable prompt-prefix segmentation and cache observations;
- compact phase-relevant model-facing Tool projection;
- lazy Tool and Skill disclosure;
- accepted intent contracts such as `repo.search`, `repo.read`, `repo.change`, `code.inspect`, `docs.lookup`, `command.run`, `verify.run`, and `artifact.read`;
- persistent model and Tool events;
- token and Context accounting;
- Privacy-policy evaluation before egress;
- interruption and cancellation;
- Project Steward control projection;
- Claims and completion summary without unsupported completion.

The first direct provider target is MiniMax because the Project owner has an active Token Plan.

Kimi and Codex require separate managed-client adapter evaluation because platform sign-in is owned by their official Clients.

Provider experiments can begin on isolated `spike/` branches. Experimental adapter code does not satisfy Phase 2 until Phase 1 exits.

The reconciliation decides when the first real read-only Child Run, Patch-producing Child Run, mutating Child Run, and independent Verifier become accepted behavior.

### Phase 2 exit

Kiln completes one small Repository change through a provider-backed Root Run, uses the broker and Context compiler, preserves isolated Git ownership, resumes after restart, and reports current Evidence, Claims, provenance, token use, failures, warnings, and unresolved work.

## Phase 3 — Evidence-backed completion

**ID:** P3

Required:

- observed mutation records;
- Change sets bound to Repository state;
- Project verification Commands;
- structured Claims and Evidence;
- exact commit, dirty-state, and dependency binding;
- Evidence freshness and invalidation;
- mutation reconciliation;
- deterministic Receipts;
- Capability, Context, Git, and integration provenance;
- unresolved-failure reporting;
- completion readiness;
- `what remains unproven?` inspection;
- independent Verifier Runs for material completion Claims;
- projected-merge Evidence for integration-sensitive changes;
- token cost by accepted Change set.

### Phase 3 exit

A passing test becomes stale after a relevant source change, and Kiln refuses to treat it as current. A final Receipt identifies the tested commit or dirty fingerprint, selected verification implementation, Verifier Context manifest, integration decision, and unresolved proof gaps.

## Phase 4 — Context and recovery

**ID:** P4

Required:

- orientation records and freshness;
- Context-item provenance, authority, trust, sensitivity, and transformation history;
- deterministic inclusion and exclusion rules;
- calibrated token estimates;
- per-Run immutable Context manifests and replacement packages;
- category budgets, phase targets, Tool-schema budgets, and burst records;
- just-in-time retrieval and progressive disclosure;
- symbol, relevant-line, hunk, documentation-section, and Artifact-segment retrieval;
- stale-Context removal and deduplication;
- explicit Artifact-to-Context inclusion;
- phase-relevant Tool projection and lazy discovery;
- lazy Skill loading;
- prompt-cache observations;
- authoritative version-matched documentation resolution;
- independent Child and Verifier Context compilation;
- Repository-state and worktree-scope binding;
- Context observability and token cost by Run and accepted Change set;
- Checkpoints, interruption summaries, traceable compaction, and recovery of Git ownership, policy, Capability, Context, Claim, Evidence, and Steward state.

## Phase 5 — Extension and adapter boundary

**ID:** P5

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
- conformance tests that prove adapters do not alter core semantics or leak raw catalogs into Context;
- one non-Elixir example extension or adapter.

MCP evaluation belongs here or in a later dedicated work package only after a concrete Capability justifies it. MCP is not required for the Phase 5 exit.

## Phase 6 — Phoenix LiveView

**ID:** P6

Required:

- Project, Session, and Workspace views;
- Task and Run tree navigation;
- model and Tool streams;
- global attention view;
- Approval and permission prompts;
- Capability availability and selected-implementation views;
- Context package, budget, exclusion, retrieval, cache, and invalidation views;
- Git branch, worktree, lease, Change set, diff, verification, integration, and cleanup views;
- interruption;
- Claim, Evidence, Receipt, Artifact, and Context views;
- reconnect without terminating the runtime;
- Client-local focus.

## Phase 7 — TypeScript SDK

**ID:** P7

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
- Git contract and hosting-adapter mapping helpers when justified;
- test helpers;
- example extensions and adapters.

## Pending roadmap reconciliation

P0-W04 through P0-W10 constrain the product but do not finalize the implementation proof order.

The next planning pass must replace or confirm the provisional Phase 1 packages and update later prompts so they do not:

- create writing Child Runs before isolation and leases exist;
- treat Git branches as Run identity;
- allow Verifiers to repair authored changes;
- treat passing checks as merge authority;
- omit projected-merge Evidence;
- lose Context and Evidence bindings after Repository changes;
- use remote providers or protocols before deterministic local semantics are proven;
- build stacks, candidate tournaments, or integration branches before independent task mode works.

## Deferred

- Gleam modules;
- Rust sandbox helper;
- ACP adapter implementation;
- MCP client or server implementation until a concrete Capability justifies it;
- LSP client implementation and server selection;
- A2A, AG-UI, and AHP adapter implementations;
- remote Capability APIs beyond the first accepted provider;
- Context7 implementation until local documentation resolution is proven;
- embedding or vector-database adoption until an accepted retrieval case justifies it;
- browser automation framework;
- hosted collaboration;
- plugin registry;
- browser integrated development environment;
- remote execution;
- unlimited delegation depth;
- remote hosting-provider automation;
- remote merge queues;
- automatic Git publication;
- stacked, candidate, and timeboxed integration runtime modes until independent mode is proven;
- cross-Repository atomic changes;
- automatic conflict resolution and force-push;
- multi-user branch ownership and distributed locking;
- Git replacement abstractions.
