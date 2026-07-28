# Roadmap

**Document type:** Reference

The roadmap is ordered by proof, not platform ambition.

P0-W05 established the planning baseline. P0-W06 established the protocol-neutral domain. P0-W07 established Capability integration. P0-W08 established bounded Context. P0-W09 established protocol strategy. P0-W10 established Git change isolation. P0-W11 established delegated Runs. P0-W12 established the initial CLI and TUI. P0-W13 established read-only local project intelligence. P0-W14 established its security boundary. P0-W15 establishes the trustworthy execution plane.

Read these authorities before Phase 1 planning:

- `docs/PLANNING-BASELINE.md`
- `docs/INTERNAL-DOMAIN-MODEL.md`
- `docs/RUN-MODEL.md`
- `docs/DELEGATED-WORK.md`
- `docs/CLI-TUI.md`
- `docs/LOCAL-PROJECT-INTELLIGENCE.md`
- `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md`
- `docs/TRUSTWORTHY-EXECUTION-PLANE.md`
- `docs/COMMAND-AND-PATCH-EXECUTION.md`
- `docs/EXECUTION-EVIDENCE-AND-RECEIPTS.md`
- `docs/EXECUTION-OBSERVABILITY-AND-ATTESTATIONS.md`
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
**Goal:** establish Project identity, constraints, documentation, Elixir structure, CI, work governance, domain semantics, Capability integration, bounded Context, protocol strategy, Git isolation, delegated-work contracts, terminal interaction, local project intelligence and security, and trustworthy execution before production implementation.

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
| P0-W11 | Define delegated Runs, Scout and Verifier roles, state machine, Attention, cancellation, timeouts, result delivery, and recovery. | `work/p0-w11-delegated-work-model` | Integrated through pull request 15 |
| P0-W12 | Define the initial CLI and TUI, Run-first navigation, interface projections, ExRatatui boundary, and deterministic prototype. | `work/p0-w12-cli-tui-design` | Integrated through pull request 16 |
| P0-W13 | Define approved-root local project intelligence, SQLite-first storage, structural retrieval, provenance, invalidation, and knowledge-graph criteria. | `work/p0-w13-local-project-intelligence` | Integrated through pull request 17 |
| P0-W14 | Define instruction quarantine, technical read-only enforcement, provenance, licensing, Privacy modes, disclosure, audit, and adversarial security proof. | `work/p0-w14-knowledge-security-boundary` | Integrated through pull request 18 |
| P0-W15 | Define tiered deterministic execution, registered Commands, transactional Patches, structured Evidence, Receipts, observability, and attestation compatibility. | `work/p0-w15-trustworthy-execution-plane` | In progress |

### Phase 0 exit

A new coding Session can identify:

- Project purpose, non-goals, accepted decisions, and invariants;
- Workspace, Project, Repository, Environment, Session, Task, Run, Capability, Context, Evidence, Git, delegation, Attention, interface, knowledge, Privacy, execution, and recovery boundaries;
- Root, Parent, Child, Scout, Verifier, CLI, TUI, Client-state, local-knowledge, knowledge-security, Environment, Command, Patch, structured-result, Artifact, Receipt, and telemetry contracts;
- approved roots, instruction quarantine, source trust, licensing, and disclosure policy;
- the least-powerful sufficient execution hierarchy;
- exact Command, Patch, verification, acceptance, and delivery distinctions;
- the next work package, mutation boundary, acceptance criteria, and required Evidence;
- one preflight command and one complete quality command.

Phase 0 exits after P0-W15 is accepted and the exact Phase 1 work-package order is reconciled.

## Phase 1 — Deterministic local kernel

**ID:** P1  
**Goal:** prove durable supervised local work, deterministic Environment and Capability selection, registered Commands, transactional mutation, bounded Context, visible delegated Runs, global Attention, exact-state Evidence, Receipts, CLI and TUI control, approved-root intelligence, instruction isolation, observability, and restart recovery before a live model loop.

### Required behavior

#### Domain and persistence

Kiln must:

- register one Workspace, Project, primary Repository, trust policy, Privacy policy, and active Project Environment;
- create one Session, accepted objective, root Task, and Root Run;
- create Tasks and Child Runs with durable identity and lineage;
- persist domain, Capability, Context, execution, Patch, structured-result, Evidence, Receipt, delegation, Attention, Git, interface, knowledge, security, audit, and lifecycle events in SQLite;
- reconstruct accepted state and projections after restart;
- consolidate `waiting_for_command`, expanded Attention, `kiln.interface/v0`, `kiln.knowledge/v0`, `kiln.knowledge.security/v0`, and `kiln.execution_plane/v0` before runtime validators become authoritative.

#### Environment and Command execution

Kiln must:

- select the least powerful Environment that satisfies the registered operation;
- execute one harmless fixed read on the trusted host without a worktree or container;
- execute Project checks in one accepted active Project Environment;
- combine an exclusive writable worktree with the Project Environment for one mutating Run;
- execute one risky fixture in a disposable OCI worker with explicit effective controls and denied network;
- provision and clean one disposable database fixture;
- register versioned Commands with fixed executable resolution, argv schema, working-directory policy, environment policy, network policy, secret policy, timeouts, output limits, and result adapters;
- construct a minimal environment rather than inherit the user's shell;
- start, stream, time out, cancel, and terminate one owned process tree;
- distinguish graceful cleanup, forced cleanup, incomplete cleanup, and unknown effects;
- externalize complete output and retain bounded summaries;
- reject an unrestricted shell without exact Approval and a dedicated grant;
- prove that the knowledge indexer cannot invoke the general Command path.

#### Transactional Patch execution

Kiln must:

- accept one immutable Patch Artifact bound to an exact base state;
- validate path scope, expected hashes, target existence, worktree lease, symlinks, file types, and transaction consistency before mutation;
- preview exact text, create, delete, move, and rename operations;
- record changed regions;
- apply one multi-file transaction through staged deterministic operations;
- retain rollback Artifacts before replacement;
- prove one safe rollback after an injected application failure;
- report rollback uncertainty as orphaned or unknown effects;
- apply one Patch Artifact produced by an isolated deterministic Child through a separate authorized Run;
- run accepted formatters and focused validation as visible registered Commands after application;
- retain exact post-application Repository state and Change set.

#### Evidence, structured results, and Receipts

Kiln must:

- record Proposed, Implemented, Inspected, Executed, Verified, Accepted, and Delivered as separate facts;
- deny `Verified` without current `PASS` Evidence;
- deny `Accepted` without a user or accepted-policy decision;
- deny `Delivered` without destination Evidence;
- record unsupported completion attempts;
- ingest at least one SARIF fixture, one structured test report, and one compiler or linter report;
- preserve raw reports as immutable Artifacts;
- normalize findings with parser, schema, path mapping, completeness, source-state, and warning provenance;
- reject stale, invalid, partial-without-disclosure, or path-mismatched reports as complete proof;
- create deterministic Command, Patch, verification, Run, and delivery Receipt fixtures;
- prove that Receipts cannot make Evidence current or grant acceptance or integration.

#### Artifact store

Kiln must:

- publish immutable content-addressed Artifacts under a Kiln-owned data root;
- preserve producer, owner scope, digest, media type, size, trust, sensitivity, retention, and state bindings;
- support bounded read, pagination, and disclosure decisions;
- deduplicate content without collapsing separate provenance or policy records;
- retain rollback Artifacts through the recovery window;
- preserve minimal digests and expiration facts after policy-controlled cleanup.

#### Context and Capability

Kiln must:

- create immutable Context manifests without a live provider;
- enforce Run and phase Context budgets;
- retrieve narrow active and reference excerpts, result summaries, and Artifact segments just in time;
- keep active instructions separate from quoted reference Evidence;
- invalidate stale Context after Repository, Environment, Patch, or Evidence changes;
- expose no more than eight intent-level Tools in the proof package;
- issue scoped Capability grants;
- register native Repository, Git, Environment, Command, Patch, verification, Artifact, Receipt, and knowledge implementations;
- select implementations deterministically and normalize results.

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
- ingest its machine-readable Evidence where available;
- return and display `PASS`, `FAIL`, and `BLOCKED`;
- prove that Verifier completion and `PASS` remain separate;
- prevent the Verifier from repairing or authorizing integration.

#### Attention and control

Kiln must:

- maintain one global Session Attention index independent of Run depth;
- route questions, permissions, shell Approvals, conflicts, failures, verification blockers, merge blockers, Resource limits, stale Evidence, orphan cleanup, and disclosure decisions;
- support answer, enter Run, route to Parent, deny, pause, cancel, acknowledge, and inspect;
- prohibit silent user or permission waits;
- resolve concurrent Client actions through expected revisions and idempotency.

#### Git and integration

Kiln must:

- capture Git state and dependency fingerprint;
- create one short-lived task branch and exclusive writable worktree;
- acquire one scoped mutation lease;
- create one coherent Change set and commit;
- bind verification Evidence to the exact commit and Environment;
- invalidate Evidence after relevant changes;
- verify projected merged state against protected trunk;
- require explicit integration Approval;
- integrate one coherent Change set locally;
- record Delivered only after integration state is observed;
- issue a final Receipt and reconcile cleanup.

#### Interface proof

Kiln must:

- expose accepted `kiln.interface/v0` contracts;
- build pure projection reducers;
- provide a local runtime endpoint that survives Client disconnect;
- support snapshot plus event replay, deduplication, gap detection, and backpressure;
- show Environment class, effective isolation, Command lifecycle, Patch status, stage status, structured results, Evidence freshness, Receipts, and warnings;
- keep navigation state client-local and execution state durable;
- prevent renderer failure from terminating active Runs;
- provide the accepted deterministic CLI and ExRatatui-backed TUI prototype after dependency review.

#### Local project intelligence and security proof

Kiln must:

- accept explicit approved roots and required excludes;
- discover and index the accepted malicious fixture corpus without executing it;
- answer deterministic exact, dependency, structural, text, error, test, migration, and verification queries;
- return compact provenance-bearing candidates with `instruction_authority: none`;
- quarantine instruction-like content;
- give the indexer no source-write, Git-mutation, command, model, publication, secret-read, or network authority;
- store derived data under a Kiln-owned root;
- enforce canonical path, symlink, file type, secret, license, Privacy, disclosure, and audit rules;
- prove malicious reference content causes no active authority or execution effect.

#### OpenTelemetry proof

Kiln must:

- instrument Task, Run, model fixture, Context compile, Capability selection, Tool call, Command, Patch, verification, Attention, Approval, Artifact creation, completion decision, and delivery;
- measure token, cost, cache, Tool-schema, Tool-result, repeated retrieval, repeated Command, failure, denial, Patch, verification, Artifact, and unsupported-completion metrics;
- use bounded low-cardinality operation names and attributes;
- exclude source, Patch content, secrets, sensitive prompts, raw argv, stdout, stderr, and complete report content by default;
- prove telemetry exporter failure cannot corrupt or reverse a completed local operation;
- retain durable events, Evidence, audit, and Receipts separately from telemetry.

#### Attestation compatibility proof

Kiln must:

- generate one valid local execution Receipt for an immutable build Artifact;
- map that eligible Receipt to an in-toto Statement-shaped fixture;
- map known build facts to a SLSA provenance-shaped fixture without claiming a SLSA level;
- leave ordinary local reads and edits as Receipts without forced attestations;
- keep signing, DSSE, publication, and formal level claims deferred.

#### Crash and recovery

Kiln must:

- recover Run, Command, process-tree, disposable Resource, Patch, rollback, Attention, Artifact, Receipt, interface, and knowledge state after restart;
- prevent duplicate Child creation, Command start, Patch application, result ingestion, and Child result delivery;
- mark unknown external effects `orphaned`;
- preserve dirty or uncertain worktrees;
- preserve the last complete knowledge snapshot and immutable Artifacts;
- recover policy, grants, leases, disclosure status, audit cursors, and telemetry cursors;
- expose all proof state through CLI and TUI.

### Provisional work packages

The post-P0-W15 reconciliation must confirm or replace these exact boundaries before implementation begins.

| ID | Purpose | Branch | Depends on | Status |
| --- | --- | --- | --- | --- |
| P1-W01 | Consolidate domain, execution-plane, delegation, interface, knowledge, security, policy, Context, Capability, Evidence, Git, Attention, and event contracts. | `work/p1-w01-kernel-contracts` | P0 | Replacement plan required |
| P1-W02 | Implement the append-oriented journal, SQLite transactions, and rebuildable Run, Attention, execution, interface, audit, and knowledge projections. | `work/p1-w02-event-journal-projections` | P1-W01 | Replacement plan required |
| P1-W03 | Implement Environment selection, Command registry, supervised argv execution, process-tree ownership, timeouts, output Artifacts, network and secret policy, and recovery. | `work/p1-w03-command-environments` | P1-W01, P1-W02 | Major replacement required |
| P1-W04 | Implement deterministic Run scheduling, Worker leases, global Attention, Child result delivery, cancellation, and crash recovery. | `work/p1-w04-run-control` | P1-W01 through P1-W03 | Reconciliation required |
| P1-W05 | Implement Git observation, worktree leases, transactional Patch application, rollback, changed regions, Change sets, and exact-state reconciliation. | `work/p1-w05-git-patch-isolation` | P1-W01 through P1-W04 | Major expansion required |
| P1-W06 | Implement bounded Context, compact Tool projection, Capability grants, and deterministic Root, Scout, and Verifier fixtures. | `work/p1-w06-context-capability-proof` | P1-W01 through P1-W05 | Reconciliation required |
| P1-W07 | Implement the immutable Artifact store, structured-result ingestion, Evidence stages, verification, deterministic execution Receipts, and freshness. | `work/p1-w07-evidence-artifacts-receipts` | P1-W01 through P1-W06 | New package proposed |
| P1-W08 | Implement public CLI commands, structured output, local runtime attach, revision checks, execution inspection, and recovery. | `work/p1-w08-cli-control` | P1-W02 through P1-W07 | Replacement required |
| P1-W09 | Implement the ExRatatui deterministic TUI prototype, projections, navigation, Attention, Command and Patch inspection, Evidence, and headless tests. | `work/p1-w09-tui-prototype` | P1-W02, P1-W04, P1-W07, P1-W08 | Reordered package proposed |
| P1-W10 | Implement approved-root discovery, SQLite knowledge storage, structural indexing, deterministic retrieval, invalidation, and CLI inspection. | `work/p1-w10-local-project-intelligence` | P1-W01, P1-W02, P1-W05 through P1-W08 | Renumbered package proposed |
| P1-W11 | Enforce knowledge instruction quarantine, read-only isolation, secret and license handling, Privacy, disclosure denial, audit, and adversarial fixtures. | `work/p1-w11-knowledge-security` | P1-W01, P1-W02, P1-W05 through P1-W10 | Renumbered package proposed |
| P1-W12 | Add bounded OpenTelemetry instrumentation and prove optional in-toto and SLSA-shaped export from deterministic Receipts. | `work/p1-w12-observability-attestation-proof` | P1-W02 through P1-W11 | New package proposed |
| P1-W13 | Execute the complete Phase 1 scenario, including deterministic execution, Patch rollback, structured Evidence, independent verification, projected merge, Approval, delivery, Receipt, interface recovery, knowledge security, and restart proof. | `work/p1-w13-phase-proof` | P1-W06 through P1-W12 | Replacement scenario required |

### Phase 1 reconciliation decisions

Before P1-W01 implementation begins, decide exact ownership for:

- contract consolidation and SQLite transaction boundaries;
- local runtime endpoint, projection service, and event bus;
- Environment registration, selection, provisioning, and cleanup;
- trusted-host, Project, worktree, Dev Container, OCI, database, and degraded profiles;
- Command registry, executable resolution, argv validation, environment construction, network, secrets, limits, and process-tree primitives per platform;
- unrestricted-shell Approval and audit;
- Patch staging, atomicity limits, rollback, changed regions, AST adapters, formatters, and focused checks;
- Artifact storage, integrity, sensitivity, retention, and cleanup;
- SARIF, test, compiler, linter, security, browser, build, and coverage adapters;
- completion stages, Evidence authority, verification, acceptance, delivery, and Receipt sealing;
- OpenTelemetry dependency, semantic conventions, metric cardinality, Privacy, sampling, and exporter isolation;
- in-toto and SLSA fixture export boundaries;
- Run scheduling, leases, Attention, cancellation, and recovery;
- Context compilation, Tool projection, and Capability grants;
- CLI, TUI, and ExRatatui boundary;
- knowledge indexing and security dependencies;
- complete deterministic restart and completion proof.

Each accepted implementation work package requires a plan.

### Phase 1 exit

Kiln can create, execute, mutate, inspect, verify, accept, integrate, deliver, delegate, interrupt, cancel, isolate, restart, reconstruct, navigate, authorize, compile, retrieve, index, quarantine, sanitize, ingest, seal, instrument, and accurately report one complete deterministic scenario without a live model, remote execution, hosted disclosure, mandatory container for harmless work, Wasm plugin, signing service, or formal supply-chain claim.

## Phase 2 — Provider and model loop

Required:

- one provider-neutral invocation contract and direct provider adapter;
- streamed normalized invocation events;
- provider-backed Root, Scout, and Verifier Runs;
- compact Tool projection and lazy Skill loading;
- execution only through accepted Environment, Command, Patch, Artifact, Evidence, and Receipt paths;
- narrow `knowledge.*` Tools under instruction isolation and Privacy policy;
- persistent model, Tool, Command, Patch, Attention, delivery, interface, knowledge, quarantine, disclosure, and completion events;
- token, cost, Context, cache, Tool-overhead, and per-Run accounting;
- Claims and completion summaries without unsupported stage advancement.

The first direct provider target is MiniMax because the Project owner has an active Token Plan.

### Phase 2 exit

Kiln completes one small active-Repository change through a provider-backed Root Run, uses a registered Command and transactional Patch, bounded local knowledge, a Scout, and an independent Verifier, and reports current Evidence, precise stages, provenance, accounting, failures, warnings, disclosure status, and unresolved work through CLI and TUI.

## Phase 3 — Evidence-backed completion and delivery

Required:

- observed mutations and Change sets bound to Repository and Environment state;
- structured Claims, Evidence, findings, and freshness;
- deterministic Command, Patch, verification, Run, and delivery Receipts;
- independent Verifier Runs;
- projected-merge Evidence;
- explicit acceptance and delivery decisions;
- unresolved-failure and blocker reporting;
- completion readiness using precise stages;
- token and execution cost by accepted Change set.

A final Receipt identifies the tested state, Environment, Commands, structured results, Verifier Evidence, acceptance and integration decisions, delivered state, knowledge candidates used, license and disclosure status, and unresolved proof gaps.

## Phase 4 — Context, quality, security, and recovery

Required:

- Context authority, trust, sensitivity, freshness, and transformation history;
- deterministic inclusion, budgets, and progressive disclosure;
- independent Root, Scout, and Verifier Context;
- knowledge ranking, freshness, provenance, and adversarial evaluation;
- telemetry quality, cardinality, Privacy, retention, and exporter behavior;
- Artifact and Receipt retention;
- preference candidates separate from active decisions;
- Checkpoints and traceable compaction;
- recovery of Git ownership, Environment Resources, policy, Capability, Context, Evidence, Artifacts, Receipts, knowledge snapshots, audit, telemetry, interface snapshots, and Client cursors.

Embeddings can be evaluated only after deterministic retrieval has a measured missed-query class. Hosted embeddings remain a separate disclosure decision.

## Phase 5 — Extension and component boundary

Required:

- supervised external processes;
- a versioned language-neutral extension protocol;
- adapter-owned negotiation and identifiers;
- Tool, Resource, Environment, and Capability registration through Kiln-native contracts;
- progress, cancellation, Privacy, output normalization, Artifact limits, and crash isolation;
- conformance tests preserving core, execution, interface, knowledge, and security semantics;
- one non-Elixir example extension or adapter.

MCP remains optional and requires a concrete Capability. WASI and WIT can be evaluated here or later for one bounded component whose explicit imports and exports provide a measurable advantage.

## Phase 6 — Phoenix LiveView

Required:

- Project, Session, Task, Run, model, Tool, Command, Patch, Environment, Attention, permission, Context, Git, Evidence, Receipt, Artifact, completion-stage, and delivery views;
- local knowledge root, scan, candidate, provenance, quarantine, license, Privacy, and disclosure inspection;
- reconnect without terminating the runtime;
- Client-local focus;
- reuse of accepted projection and input-intent contracts.

Phoenix must not fork Run, execution, Attention, permission, Evidence, knowledge, security, or navigation semantics from CLI and TUI.

## Phase 7 — TypeScript SDK

Required:

- typed Kiln-native Tool, Resource, Environment, Capability, execution-plane, interface, knowledge, and security contracts;
- cancellation and progress;
- compatibility checks;
- adapter mapping helpers;
- normalized result, Artifact, Evidence, Receipt, provenance, disclosure, and telemetry helpers;
- test helpers and example adapters.

## Pending roadmap reconciliation

P0-W04 through P0-W15 constrain the product but do not finalize implementation proof order.

The next reconciliation must not:

- create writing Child Runs before isolation and a writing role exist;
- treat Git branches, worktrees, containers, or processes as Run identity;
- require a worktree or container for harmless reads;
- run Project-defined code through the trusted-host read profile;
- treat Dev Container configuration as implicit authority;
- use unrestricted shell as an ordinary model Tool;
- kill only a direct child while leaving descendants;
- hide unknown effects behind cancellation or timeout success;
- apply state-mismatched or fuzzy Patches automatically;
- hide formatter or generator mutations inside Patch application;
- collapse Proposed, Implemented, Inspected, Executed, Verified, Accepted, and Delivered;
- treat exit zero, model confidence, structured format shape, Receipt sealing, or attestation export as acceptance or delivery;
- discard raw reports after normalization;
- put source, patches, secrets, sensitive prompts, raw argv, or complete output in telemetry by default;
- claim a SLSA level because a compatible predicate can be exported;
- force formal attestations onto ordinary local actions;
- use remote execution, providers, or protocols before deterministic local semantics;
- treat reference content as active instruction or reuse the indexer grant for execution;
- store derived data inside active or reference repositories;
- silently weaken isolation when a required control is unavailable;
- use embeddings before deterministic retrieval is evaluated;
- add a graph database without a measured query requirement.

## Deferred

- Gleam modules;
- Rust sandbox helper;
- remote execution;
- ACP adapter implementation;
- MCP client or server until a concrete Capability justifies it;
- automatic LSP or SCIP generation;
- A2A, AG-UI, and AHP adapters;
- remote Capability APIs beyond the first accepted provider;
- Context7 until local documentation resolution is proven;
- embeddings or vector extensions until an accepted missed-query class justifies them;
- hosted embeddings and remote knowledge disclosure;
- a dedicated graph database until measured traversal requirements justify it;
- browser automation framework beyond the accepted deterministic fixture;
- hosted collaboration and shared knowledge;
- execution against reference repositories;
- automatic preference promotion, shared-library extraction, source reuse, or license compatibility decisions;
- historical indexing of every commit;
- production WASI/WIT plugin runtime;
- in-toto or SLSA publication, DSSE, signing, key management, or formal level claims;
- mandatory containers for harmless operations;
- SSH TUI, arbitrary pane layouts, full Markdown fidelity, inline terminal images, embedded terminal multiplexing, extensive themes, and dozens of concurrent visible Runs.
