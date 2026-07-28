# Roadmap

**Document type:** Reference

The roadmap is ordered by proof, not platform ambition.

P0-W05 establishes the planning-status baseline. P0-W06 establishes the protocol-neutral internal domain model. P0-W07 establishes the Capability integration hierarchy, broker contract, compact model-facing Tool surface, and initial non-MCP boundary. P0-W08 establishes the smallest-sufficient Context compiler, documentation resolver, bounded Tool and Skill exposure, independent Child and Verifier contexts, and Context observability contract. The current Phase 1 and Phase 2 work-package boundaries require reconciliation after P0-W08. See `docs/PLANNING-BASELINE.md`, `docs/INTERNAL-DOMAIN-MODEL.md`, `docs/CAPABILITY-INTEGRATION.md`, `docs/CONTEXT-SYSTEM.md`, and `docs/PLAN-RECONCILIATION.md`.

## Work identifiers

Kiln uses these identifiers:

```text
P1          Phase 1
P1-W02      Phase 1 work package 2
P1-X01      Phase 1 experiment 1
```

Each planned work package MUST follow `docs/BRANCHING-AND-WORK-PLANNING.md`.

## Phase 0 — Repository foundation

**ID:** P0  
**Goal:** establish project identity, constraints, documentation, basic Elixir structure, CI, work governance, coding-agent controls, foundational execution concepts, one reliable planning baseline, one stable protocol-neutral internal domain model, one explicit Capability integration model, and one bounded Context-system contract.

### Work packages

| ID | Purpose | Branch | Status |
| --- | --- | --- | --- |
| P0-W01 | Establish the Repository foundation. | `agent/bootstrap-project-foundation` | Integrated into `main` through pull request 1 |
| P0-W02 | Define branch-linked planning, Evidence rules, templates, and prose linting. | `work/p0-w02-work-governance` | Merged into the P0-W01 branch; not integrated into `main` |
| P0-W03 | Add agent-friendly code rules, project invariants, Skills, specialist reviewers, and deterministic development checks. | `work/p0-w03-agent-ready-development` | Merged into the P0-W02 branch; not integrated into `main` |
| P0-W04 | Define first-class Runs, the navigable Run graph, and Project Steward responsibility. | `work/p0-w04-run-graph-stewardship` | Draft pull request 5; implemented but unverified |
| P0-W05 | Audit planning authority, decisions, conflicts, implementation Evidence, and document status. | `work/p0-w05-planning-baseline` | Draft pull request 6; implemented but unverified |
| P0-W06 | Define the protocol-neutral internal domain, contracts, adapter boundary, and Run-centered execution unit. | `work/p0-w06-internal-domain-model` | Draft pull request 7; implemented but unverified |
| P0-W07 | Define Capability integration hierarchy, broker, compact model Tools, normalization, duplicates, and initial non-MCP boundaries. | `work/p0-w07-capability-integration` | Draft pull request 8; implemented but unverified |
| P0-W08 | Define smallest-sufficient Context compilation, documentation resolution, token budgets, progressive disclosure, independent Child and Verifier contexts, and Context observability. | `work/p0-w08-context-system` | In progress; depends on P0-W07 |

**Exit:** a new coding Session can identify the Project purpose, non-goals, accepted decisions, integration state, invariants, Workspace, Project, Repository, Environment, Session, Task, Run, Agent, Worker, model-invocation, Capability, Context, Evidence, adapter, Capability-integration, and Context-compilation boundaries. It can select the next work package, identify the mutation boundary and acceptance criteria, and run one preflight command and one complete quality command.

## Phase 1 — Local execution kernel

**ID:** P1  
**Goal:** prove durable supervised local work, deterministic Capability selection, and bounded Context compilation through the Kiln-native domain before adding an accepted model-driven or protocol-backed loop.

### Required behavior

- register one Workspace;
- register one Project;
- bind one primary Repository and Repository trust policy;
- define one Environment;
- create one Session and accepted objective;
- create one root Task and one Root Run;
- persist Session, Task, Run, Capability, selection, Context, and execution events in SQLite;
- reconstruct Session, Task, Run, policy, Capability, Context, and execution state after restart;
- create one immutable Context manifest and bounded package without a live provider;
- enforce one Run Context ceiling and phase target;
- include one current intent, requirement, Task, Run, permission, and Repository-state projection;
- retrieve one file excerpt, symbol, or relevant line range just in time;
- invalidate and replace one stale Context item after a source-state change;
- expose no more than eight intent-level Tools in the proof package;
- account for Tool-schema tokens;
- issue one scoped Capability grant;
- register one native Repository implementation;
- register one Git CLI adapter;
- register one Project verification CLI;
- observe implementation availability and compatibility;
- filter candidates by Task phase;
- select one implementation deterministically through the hierarchy;
- collapse one duplicate group behind one intent-level Tool;
- execute one supervised Command through a Tool call;
- stream bounded output;
- store large output as an Artifact and include one bounded Artifact reference;
- support timeout, interruption, and cancellation;
- record termination accurately;
- capture Git state and a Repository fingerprint;
- produce one Artifact and Claim;
- record one minimal Evidence item bound to Repository state;
- reference material Capability and Context use in a Trace and Receipt;
- demonstrate one authorized fallback or explicit unavailable result without broadening authority;
- create one compact Checkpoint;
- expose state through a basic command-line projection.

### Current proposed work packages

These work packages predate ADRs 0004 through 0011. They remain proposed until the reconciliation pass confirms or replaces them.

| ID | Purpose | Branch | Depends on | Status |
| --- | --- | --- | --- | --- |
| P1-W01 | Define Workspace, Session, event, execution, fingerprint, and Checkpoint types. | `work/p1-w01-session-domain` | P0 | Replacement or major expansion required |
| P1-W02 | Persist append-oriented Session events in SQLite and reconstruct a Session. | `work/p1-w02-event-journal` | P1-W01 | Replacement or major expansion required |
| P1-W03 | Start, stream, time out, cancel, and record a Command. | `work/p1-w03-command-supervision` | P1-W01, P1-W02 | Domain, Tool-result, and Capability reconciliation required |
| P1-W04 | Capture Git state and Repository fingerprints before and after execution. | `work/p1-w04-git-observation` | P1-W01, P1-W02 | Native Repository, Git adapter, trust, Context invalidation, and Evidence reconciliation required |
| P1-W05 | Expose Session and execution state through the CLI. | `work/p1-w05-cli-projection` | P1-W02, P1-W03, P1-W04 | Task, Run, attention, Client-focus, compact Tool, and Context projection reconciliation required |
| P1-W06 | Reconstruct interrupted Sessions and report the last known safe state. | `work/p1-w06-restart-recovery` | P1-W02, P1-W03, P1-W04 | Worker lease, orphan, availability, selection, policy, Context, and Checkpoint reconciliation required |
| P1-W07 | Execute and record the Phase 1 acceptance scenario. | `work/p1-w07-phase-proof` | P1-W05, P1-W06 | Replacement scenario required |

The reconciliation must decide where to prove:

- Project and Repository membership;
- Task identity and satisfaction;
- Run identity and lineage;
- event and projection schemas;
- Capability definitions, registrations, availability, selection, grants, and effective authority;
- native Repository operations;
- Git CLI adaptation;
- Project verification CLI discovery and execution;
- bounded result normalization and Artifact continuations;
- duplicate groups and fallback reauthorization;
- compact model-facing Tool projection without a live model;
- Context compile requests, items, immutable manifests, bounded packages, and source-state bindings;
- token ceilings, phase targets, Tool-schema accounting, and exclusion records;
- just-in-time file, symbol, line, and Artifact retrieval;
- stale-item invalidation, replacement, and compact Checkpoint continuity;
- one local authoritative documentation resolution without Context7;
- Context observability events and Run-cost accounting;
- Claim, Evidence, Receipt, and Checkpoint minimums;
- fake navigable Child Runs with independent delegation packages;
- a fake independent Verifier package;
- Client-local focus;
- attention routing;
- the first Project Steward projection.

Each accepted work package requires a plan before implementation.

**Exit:** Kiln can create, execute, interrupt, restart, reconstruct, navigate, select, authorize, normalize, compile, retrieve, invalidate, externalize, and accurately report one manual Project, Session, Task, Root Run, bounded Context package, native Repository operation, Git CLI operation, verification CLI operation, Command, Artifact, Claim, Evidence, Trace, Receipt, and Checkpoint scenario without a live model, MCP server, remote API, Context7, or browser automation.

## Phase 2 — Provider and model loop

**ID:** P2

### Required behavior

- one Kiln-native provider-neutral model-invocation contract;
- one direct provider adapter;
- model Capability discovery or explicit configuration;
- streamed normalized model-invocation events;
- one provider-backed Root Run;
- versioned Agent binding;
- one newly compiled immutable Context manifest per invocation;
- smallest-sufficient Context packages constrained by Run and phase budgets rather than provider window size;
- stable prompt-prefix segmentation and cache observations;
- compact phase-relevant model-facing Tool projection;
- lazy Tool and Skill disclosure;
- `repo.search`, `repo.read`, `repo.change`, `code.inspect`, `docs.lookup`, `command.run`, `verify.run`, and `artifact.read` as accepted intent contracts where required;
- persistent model and Tool events;
- model input, output, Tool-schema, retained-result, and Context-size accounting;
- Privacy-policy evaluation before egress;
- interruption and cancellation;
- Project Steward control projection;
- Claims and completion summary without unsupported completion.

The first direct provider target is MiniMax because the project owner has an active Token Plan.

Kimi and Codex require separate managed-client adapter evaluation because platform sign-in is owned by their official Clients.

Provider transport experiments MAY begin before Phase 1 is complete on isolated `spike/` branches. Experimental adapter code MUST NOT enter the accepted Session loop or satisfy Phase 2 until Phase 1 exits.

The reconciliation must decide when the first real read-only Child Run and independent Verifier become accepted behavior.

**Exit:** Kiln completes one small Repository change through a provider-backed Root Run, selects Capabilities through the broker, compiles replacement Context packages within budget, preserves the Session after restart, and reports current Evidence, Claims, implementation and retrieval provenance, token use, failures, and unresolved work.

## Phase 3 — Evidence-backed completion

**ID:** P3

Required:

- observed mutation records;
- Change sets bound to Repository fingerprints;
- project verification Commands;
- structured Claims and Evidence;
- Repository-state binding;
- Evidence freshness;
- mutation reconciliation;
- deterministic Receipts;
- Capability-use and Context-manifest provenance in Traces and Receipts;
- unresolved-failure reporting;
- completion readiness;
- `what remains unproven?` inspection;
- independent Verifier Runs for material completion Claims;
- token cost by accepted Change set with explicit shared or unallocated attribution when exact allocation is unavailable.

**Exit:** a passing test becomes stale after a relevant source change, and Kiln refuses to treat it as current. A final Receipt discloses the stale Evidence, selected verification implementation, Verifier Context manifest, and token attribution and cannot report the Claim as proven.

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
- symbol-level, relevant-line, hunk, documentation-section, and Artifact-segment retrieval;
- stale-context removal and deduplication;
- explicit Artifact-to-Context inclusion;
- phase-relevant model-facing Tool projection and lazy discovery;
- lazy Skill loading;
- stable prompt prefixes and prompt-cache observations;
- authoritative version-matched documentation resolution, including optional Context7 below local sources;
- independent Child-Run and Verifier-Run Context compilation;
- Context observability and token cost by Run and accepted change;
- Checkpoints;
- interruption summaries;
- traceable compaction;
- Session and Run branching where accepted;
- recovery of Tasks, Run graph, Worker leases, attention, policies, Capability availability, selection decisions, Context manifests, Claims, Evidence, and Steward projection.

## Phase 5 — Extension and adapter boundary

**ID:** P5

Required:

- supervised external processes;
- versioned language-neutral extension protocol;
- adapter-owned protocol negotiation and identifier mapping;
- Tool and Resource registration through Kiln-native contracts;
- Capability registration through the accepted hierarchy;
- progress and cancellation;
- Capability declarations without ambient grants;
- Privacy-policy evaluation;
- output normalization and Artifact limits;
- phase-specific Tool projection and schema-budget compatibility;
- duplicate detection and replacement groups;
- crash isolation;
- conformance tests that prove the adapter does not alter core semantics or leak raw protocol catalogs into Context;
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
- interruption;
- Git status and diff;
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
- cancellation;
- progress;
- compatibility checks;
- adapter mapping helpers;
- normalized result helpers;
- bounded Context-result and Artifact-reference helpers;
- test helpers;
- example extensions and adapters.

## Pending roadmap reconciliation

P0-W04 through P0-W08 do not finalize the new proof order.

Before P1-W01 implementation begins, reconcile:

- Workspace, Project, Repository, and Environment boundaries;
- Session, Task, Run, Agent, Worker, and model-invocation boundaries;
- event-journal and projection scope;
- Capability registration, availability, selection, permission, normalization, duplicate, and fallback work-package boundaries;
- native Repository and Git adapter timing;
- Project verification CLI timing;
- Repository trust and Privacy-policy timing;
- minimum Context compile request, item, manifest, package, budget, cache, invalidation, and observation state;
- minimum Claim, Evidence, Receipt, and Checkpoint state;
- fake-Run interface proof;
- attention and Client-focus timing;
- Project Steward vertical slice;
- MiniMax adapter acceptance timing;
- first read-only Child Run and its independent Context package;
- independent Verifier timing and first-pass Context policy;
- writing-Run isolation;
- version 0.1 completion scenario;
- documentation resolver proof and Context7 timing;
- adapter acceptance and conformance boundaries;
- the first justified local or remote MCP work package, if any.

The current authorities, conflicts, gaps, and unknowns are recorded in `docs/PLANNING-BASELINE.md`. The internal terms and contracts are in `docs/INTERNAL-DOMAIN-MODEL.md`. Capability selection and broker rules are in `docs/CAPABILITY-INTEGRATION.md`. Context compilation and documentation resolution are in `docs/CONTEXT-SYSTEM.md`. The earlier candidate proof order remains in `docs/PLAN-RECONCILIATION.md` until it is replaced.

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
- writing Child Runs before isolation;
- automatic Git publication.
