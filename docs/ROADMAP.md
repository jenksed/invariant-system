# Roadmap

**Document type:** Reference

The roadmap is ordered by proof, not platform ambition.

P0-W05 established the planning baseline. P0-W06 established the protocol-neutral domain. P0-W07 established Capability integration. P0-W08 established bounded Context. P0-W09 established protocol strategy. P0-W10 established Git change isolation. P0-W11 established delegated Runs. P0-W12 established the initial CLI and TUI. P0-W13 established read-only local project intelligence. P0-W14 establishes the technical security boundary for reference-repository retrieval, reuse, Privacy, and disclosure.

Read these authorities before Phase 1 planning:

- `docs/PLANNING-BASELINE.md`
- `docs/INTERNAL-DOMAIN-MODEL.md`
- `docs/RUN-MODEL.md`
- `docs/DELEGATED-WORK.md`
- `docs/CLI-TUI.md`
- `docs/LOCAL-PROJECT-INTELLIGENCE.md`
- `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md`
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
**Goal:** establish Project identity, constraints, documentation, Elixir structure, CI, work governance, domain semantics, Capability integration, bounded Context, protocol strategy, Git isolation, delegated-work contracts, terminal interaction, local project intelligence, and its security boundary before production implementation.

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
| P0-W12 | Define the initial CLI and TUI, Run-first navigation, interface projections, ExRatatui boundary, and deterministic prototype. | `work/p0-w12-cli-tui-design` | Integrated through pull request 16 |
| P0-W13 | Define approved-root local project intelligence, SQLite-first storage, structural retrieval, provenance, invalidation, and knowledge-graph criteria. | `work/p0-w13-local-project-intelligence` | Integrated through pull request 17 |
| P0-W14 | Define instruction quarantine, technical read-only enforcement, provenance, licensing, Privacy modes, disclosure, audit, and adversarial security proof. | `work/p0-w14-knowledge-security-boundary` | In progress |

### Phase 0 exit

A new coding Session can identify:

- Project purpose, non-goals, accepted decisions, and invariants;
- Workspace, Project, Repository, Environment, Session, Task, Run, Capability, Context, Evidence, Git, delegation, Attention, interface, knowledge, Privacy, and recovery boundaries;
- Root, Parent, Child, Scout, Verifier, CLI, TUI, Client-state, local-knowledge, and knowledge-security contracts;
- approved roots, Repository opt-out, instruction quarantine, source trust labels, and disclosure policy;
- exact candidate provenance, license status, and safe reuse requirements;
- the next work package, mutation boundary, acceptance criteria, and required Evidence;
- one preflight command and one complete quality command.

Phase 0 exits after P0-W14 is accepted and the Phase 1 work-package order is reconciled.

## Phase 1 — Deterministic local execution, interaction, intelligence, and security kernel

**ID:** P1  
**Goal:** prove durable supervised local work, deterministic Capability selection, bounded Context, visible delegated Runs, global Attention, isolated Repository mutation, exact-state Evidence, CLI and TUI control, approved-root local intelligence, instruction isolation, and restart recovery before an accepted live model loop.

### Required behavior

#### Domain and persistence

Kiln must:

- register one Workspace, Project, primary Repository, trust policy, Privacy policy, and Environment;
- create one Session, accepted objective, root Task, and Root Run;
- create Tasks and Child Runs with durable identity and lineage;
- persist domain, Capability, Context, execution, delegation, Attention, Git coordination, Evidence, interface, knowledge, knowledge-security, and lifecycle events in SQLite;
- reconstruct accepted state and projections after restart;
- consolidate `waiting_for_command`, expanded Attention, `kiln.interface/v0`, `kiln.knowledge/v0`, and `kiln.knowledge.security/v0` into Phase 1 validators.

#### Context and Capability

Kiln must:

- create immutable Context manifests without a live provider;
- enforce Run and phase Context budgets;
- retrieve narrow active-Repository and reference-Repository excerpts just in time;
- keep active instructions structurally separate from quoted reference Evidence;
- reject any reference candidate with instruction or permission effect;
- invalidate stale Context after Repository-state changes;
- expose no more than eight intent-level Tools in the proof package;
- issue scoped Capability grants;
- register native Repository, controlled Git CLI, verification, and local-knowledge implementations;
- select implementations deterministically and normalize results.

#### Command execution

Kiln must:

- start, stream, time out, interrupt, cancel, and accurately terminate one supervised Command;
- enter and leave `waiting_for_command` through durable transitions;
- store large output as an Artifact and retain bounded references;
- distinguish clean cancellation from unknown effects;
- expose bounded Command summaries to CLI and TUI.

The knowledge indexer cannot invoke this general Command path.

#### Delegated work

Kiln must:

- create every delegated Task as a Child Run before delegated execution;
- support Root, Parent, Child, sibling, and depth-two projections;
- enforce depth two and three active Children per Session;
- compile independent Child Context and grants;
- prevent peer communication and shared mutable Context;
- deliver bounded idempotent Child results;
- recover pending delivery after Parent-process failure.

#### Scout and Verifier proof

Kiln must:

- execute one deterministic Scout fixture through read-only Capabilities;
- return facts, inferences, assumptions, unknowns, scope notes, and Evidence references;
- execute one independent deterministic Verifier fixture;
- return and display `PASS`, `FAIL`, and `BLOCKED`;
- prove that Verifier completion and `PASS` remain separate;
- prevent the Verifier from repairing or authorizing integration.

#### Attention and control

Kiln must:

- maintain one global Session Attention index independent of Run depth;
- route questions, permissions, conflicts, failures, verification blockers, merge blockers, Resource limits, stale Evidence, and orphan recovery;
- support answer, enter Run, route to Parent, deny, pause, cancel, acknowledge, and inspect;
- prohibit silent user or permission waits;
- resolve concurrent Client actions through expected revisions and idempotency.

#### Git and Evidence

Kiln must:

- capture Git state and Repository fingerprint;
- create one short-lived task branch and exclusive writable worktree for a deterministic mutating Run;
- acquire one scoped worktree lease;
- create one Change set and commit;
- bind verification Evidence to the exact commit;
- invalidate Evidence after relevant changes;
- verify projected merged state against protected trunk;
- require explicit integration Approval;
- issue one final Receipt and reconcile cleanup.

#### Interface proof

Kiln must:

- expose accepted `kiln.interface/v0` contracts;
- build pure projection reducers;
- provide a local runtime endpoint that survives Client disconnect;
- support snapshot plus event replay, deduplication, gap detection, and backpressure;
- keep navigation state client-local and execution state durable;
- prevent renderer failure from terminating active Runs;
- provide the accepted deterministic CLI and ExRatatui-backed TUI prototype after dependency review.

#### Local project intelligence proof

Kiln must:

- accept one explicit root configuration and required excludes;
- reject indexing without an accepted root;
- discover a fixture corpus with active, archived, experimental, incomplete, abandoned, clean, dirty, branch, and detached states;
- create content hashes and immutable Repository snapshots;
- index generic text, supported manifests, and Elixir structure;
- import one approved SCIP-like fixture without generating it;
- create typed nodes, edges, and provenance;
- answer exact, dependency, structural, text, error, test, migration, and verification queries without a model;
- return no more than eight compact candidates;
- inspect and trace candidates through verified source state;
- invalidate changed files and reuse unchanged extraction;
- preserve the last complete snapshot after failure;
- keep embeddings and a dedicated graph database disabled.

#### Knowledge security proof

Kiln must:

- assign `instruction_authority: none` to every reference Repository and candidate;
- quarantine roadmaps, TODOs, Agent files, prompts, ADRs, issue templates, comments, generated recommendations, and embedded instructions;
- prove retrieved content cannot change active Task, requirements, policy, grants, Tools, model, write scope, verification, completion, or integration;
- give the indexer no source-write, Git-mutation, command, dependency-installation, service, secret-read, model, publication, or network authority;
- store all derived data under one Kiln-owned data root outside fixtures;
- revalidate canonical roots, relative paths, excludes, symlinks, file type, and policy before every source inspection;
- use read-only handles and a fixed sanitized Git observer;
- run one risky extractor through a separate process or stronger accepted isolation;
- report the effective containment profile honestly;
- disable an unsafe extractor when required isolation is unavailable;
- scan for secrets before searchable indexing, display, Context, or disclosure;
- sanitize terminal and markup control behavior;
- preserve complete source, state, hash, time, trust, license, sanitization, and disclosure provenance;
- support local-only, metadata-only, approved-excerpt, explicit-each-time, and deny Privacy modes;
- deny external disclosure without a matching decision;
- deny hosted embeddings and remote MCP source access;
- record security audit events;
- prove malicious fixture repositories cause no write, command, network, secret, or authority effect;
- reject reference execution when its separate Run, grant, Environment, Approval, snapshot, Evidence, or audit fields are missing;
- perform no actual reference-Repository execution in Phase 1.

#### Crash and recovery

Kiln must:

- recover Run, Command, Attention, delivery, interface, and knowledge state after restart;
- prevent duplicate Child creation and result delivery;
- mark unknown external effects `orphaned`;
- preserve dirty or uncertain worktrees;
- preserve the last complete knowledge snapshot;
- recover security policy, disclosure status, and audit cursors;
- expose proof state through CLI and TUI.

### Provisional work packages

The post-P0-W14 reconciliation can replace these boundaries.

| ID | Purpose | Branch | Depends on | Status |
| --- | --- | --- | --- | --- |
| P1-W01 | Consolidate domain, delegation, interface, knowledge, knowledge-security, policy, Context, Capability, Evidence, Git, Attention, cancellation, timeout, and event contracts. | `work/p1-w01-kernel-contracts` | P0 | Replacement plan required |
| P1-W02 | Persist the append-oriented journal and rebuild Session, Run, Attention, delivery, interface, knowledge, disclosure, and audit projections. | `work/p1-w02-event-journal-projections` | P1-W01 | Replacement plan required |
| P1-W03 | Supervise Commands, bounded output, waiting states, timeouts, cancellation, and termination. | `work/p1-w03-command-supervision` | P1-W01, P1-W02 | Reconciliation required |
| P1-W04 | Implement deterministic scheduling, Worker leases, global Attention, Child result delivery, and crash recovery. | `work/p1-w04-run-control` | P1-W01 through P1-W03 | New package proposed |
| P1-W05 | Observe Git, manage one isolated worktree and lease, bind Evidence, and reconcile external changes. | `work/p1-w05-git-isolation` | P1-W01 through P1-W04 | Major expansion required |
| P1-W06 | Compile bounded Context and compact Capability projections for Root, Scout, and Verifier fixtures. | `work/p1-w06-context-capability-proof` | P1-W01 through P1-W05 | New package proposed |
| P1-W07 | Implement public CLI commands, structured output, local runtime attach, revision checks, and recovery. | `work/p1-w07-cli-control` | P1-W02 through P1-W06 | Replacement required |
| P1-W08 | Implement the ExRatatui deterministic TUI prototype, projection replay, navigation, Attention, inspection, and headless tests. | `work/p1-w08-tui-prototype` | P1-W02, P1-W04, P1-W07 | New package proposed |
| P1-W09 | Implement approved-root discovery, SQLite knowledge storage, generic and Elixir structural indexing, retrieval, invalidation, and CLI inspection. | `work/p1-w09-local-project-intelligence` | P1-W01, P1-W02, P1-W05 through P1-W07 | New package proposed |
| P1-W10 | Enforce instruction quarantine, read-only source access, secret and license handling, Privacy modes, disclosure denial, audit, isolation profiles, and adversarial fixtures. | `work/p1-w10-knowledge-security` | P1-W01, P1-W02, P1-W05, P1-W06, P1-W09 | New package proposed |
| P1-W11 | Execute the complete Phase 1 acceptance scenario, including local knowledge security, independent verification, projected merge, Approval, Receipt, interface recovery, and restart proof. | `work/p1-w11-phase-proof` | P1-W06 through P1-W10 | Replacement scenario required |

### Phase 1 reconciliation decisions

Before P1-W01 implementation begins, decide exact ownership for:

- contract consolidation and SQLite transaction boundaries;
- local runtime endpoint, projection service, and event bus;
- Run scheduling, leases, Attention, cancellation, and recovery;
- Context compilation, Tool projection, and Capability grants;
- active Repository and reference Repository readers;
- controlled Git observation and worktree mutation adapters;
- CLI, TUI, and ExRatatui boundary;
- approved-root configuration and Repository opt-out;
- FTS5, Tree-sitter, manifest, SCIP-like import, and watcher dependencies;
- instruction classifier, sanitizer, secret scanner, and license detector;
- path-relative read primitives and symlink checks per platform;
- extractor process, mount, container, and degraded-isolation profiles;
- Privacy modes, disclosure decisions, and audit storage;
- adversarial fixture corpus and no-write, no-command, no-network canaries;
- Phase 1 restart and completion proof.

Each accepted implementation work package requires a plan.

### Phase 1 exit

Kiln can create, execute, delegate, inspect, interrupt, cancel, isolate, verify, integrate, restart, reconstruct, navigate, authorize, compile, retrieve, index, quarantine, sanitize, invalidate, and accurately report one complete deterministic scenario with an approved knowledge root and malicious reference corpus without a live model, MCP server, remote API, external disclosure, embeddings, graph database, browser automation, Phoenix, ACP, AG-UI, or reference-Repository execution.

## Phase 2 — Provider and model loop

Required:

- one provider-neutral invocation contract and direct provider adapter;
- streamed normalized invocation events;
- provider-backed Root, Scout, and Verifier Runs;
- compact Tool projection and lazy Skill loading;
- narrow `knowledge.*` Tools backed by the deterministic local index;
- strict separation of active instructions and quoted reference Evidence;
- persistent model, Tool, Attention, delivery, interface, knowledge, quarantine, and disclosure events;
- token, cost, Context, and per-Run accounting;
- Privacy evaluation before any knowledge-candidate egress;
- local-only operation as the default;
- Claims and completion summary without unsupported completion.

The first direct provider target is MiniMax because the Project owner has an active Token Plan.

### Phase 2 exit

Kiln completes one small active-Repository change through a provider-backed Root Run, uses bounded local knowledge under the accepted security boundary, a Scout, and an independent Verifier, and reports current Evidence, provenance, disclosure status, accounting, failures, warnings, and unresolved work through CLI and TUI.

## Phase 3 — Evidence-backed completion

Required:

- observed mutations and Change sets bound to Repository state;
- structured Claims and Evidence;
- Evidence freshness and invalidation;
- deterministic Receipts;
- Capability, Context, delegation, Git, interface, knowledge, disclosure, and integration provenance;
- independent Verifier Runs;
- projected-merge Evidence;
- unresolved-failure and blocker reporting;
- completion readiness;
- token cost by accepted Change set.

A final Receipt identifies the tested state, Verifier Evidence, integration decision, knowledge candidates used, license and disclosure status, and unresolved proof gaps.

## Phase 4 — Context, knowledge quality, security, and recovery

Required:

- Context authority, trust, sensitivity, freshness, and transformation history;
- deterministic inclusion, budgets, and progressive disclosure;
- independent Root, Scout, and Verifier Context;
- knowledge ranking, freshness, provenance, and adversarial quality evaluation;
- preference candidates separate from active decisions;
- disclosure and audit retention policy;
- Checkpoints and traceable compaction;
- recovery of Git ownership, policy, Capability, Context, Evidence, knowledge snapshots, security audit state, interface snapshots, and Client cursors.

Embeddings can be evaluated only after deterministic retrieval has a measured missed-query class. Hosted embeddings remain a separate disclosure and policy decision.

## Phase 5 — Extension and adapter boundary

Required:

- supervised external processes;
- a versioned language-neutral extension protocol;
- adapter-owned negotiation and identifiers;
- Tool, Resource, and Capability registration through Kiln-native contracts;
- progress, cancellation, Privacy evaluation, output normalization, and Artifact limits;
- duplicate detection and replacement groups;
- crash isolation;
- conformance tests preserving core, interface, knowledge, and knowledge-security semantics;
- one non-Elixir example extension or adapter.

MCP evaluation belongs here or later only after a concrete Capability justifies it. Remote MCP local-knowledge access remains denied unless a later accepted disclosure design permits it.

## Phase 6 — Phoenix LiveView

Required:

- Project, Session, Task, Run, model, Tool, Attention, permission, Context, Git, Evidence, Receipt, and Artifact views;
- local knowledge root, scan, candidate, provenance, quarantine, license, Privacy, and disclosure inspection;
- reconnect without terminating the runtime;
- Client-local focus;
- reuse of accepted projection and input-intent contracts.

Phoenix must not fork Run, Attention, permission, Evidence, knowledge, security, or navigation semantics from CLI and TUI.

## Phase 7 — TypeScript SDK

Required:

- typed Kiln-native Tool, Resource, Capability, interface, knowledge, and knowledge-security contracts;
- cancellation and progress;
- compatibility checks;
- adapter mapping helpers;
- normalized result, provenance, disclosure, and Artifact-reference helpers;
- test helpers and example adapters.

## Pending roadmap reconciliation

P0-W04 through P0-W14 constrain the product but do not finalize implementation proof order.

The next reconciliation must not:

- create writing Child Runs before isolation and a writing role exist;
- treat Git branches as Run identity;
- allow Verifiers to repair authored changes;
- treat passing checks as merge authority;
- lose Context or Evidence bindings after Repository changes;
- use remote providers or protocols before deterministic local semantics;
- implement a TUI before projection reducers and CLI contracts;
- scan local paths without explicit approved roots;
- treat reference content as active instruction;
- rely only on prompts for instruction isolation;
- run Repository code to improve indexing;
- store derived data inside indexed repositories;
- follow symlinks after only a discovery-time check;
- give the indexer command or network authority;
- use remote models, MCP, APIs, exports, or hosted embeddings without disclosure policy;
- present copied or adapted code without source and license provenance;
- reuse the indexer grant for reference execution;
- silently weaken isolation when a sandbox is unavailable;
- use embeddings before deterministic retrieval is evaluated;
- add a graph database without a measured query requirement;
- call the first index a knowledge graph before its criteria pass.

## Deferred

- Gleam modules;
- Rust sandbox helper;
- ACP adapter implementation;
- MCP client or server until a concrete Capability justifies it;
- automatic LSP or SCIP generation;
- A2A, AG-UI, and AHP adapters;
- remote Capability APIs beyond the first accepted provider;
- Context7 until local documentation resolution is proven;
- embeddings or vector extensions until an accepted missed-query class justifies them;
- hosted embeddings and remote knowledge disclosure;
- a dedicated graph database until measured traversal requirements justify it;
- browser automation framework;
- hosted collaboration and shared knowledge;
- remote execution and execution against reference repositories;
- automatic preference promotion;
- automatic shared-library extraction;
- automatic source reuse or license compatibility decisions;
- historical indexing of every commit;
- SSH TUI, arbitrary pane layouts, full Markdown fidelity, inline terminal images, embedded terminal multiplexing, extensive themes, and dozens of concurrent visible Runs.
