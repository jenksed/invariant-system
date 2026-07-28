# Kiln

Kiln is a local-first, evidence-driven coding harness built on Elixir and OTP for one developer building real software with AI.

A model supplies intelligence. Kiln determines whether that intelligence becomes trustworthy work through durable Runs, explicit authority, bounded Context, controlled execution, inspectable changes, machine-readable Evidence, and recovery.

Kiln moves work through:

> Intent → Investigation → Change → Verification → Reconciliation → Completion

## Product boundary

Kiln is not:

- an autonomous software company;
- an agent-management hierarchy;
- a protocol catalog;
- a replacement for Git, language servers, build tools, or mature CLIs;
- a universal sandbox;
- a hosted collaboration platform;
- an automatic code-harvesting system.

Kiln is the durable runtime around Repository work.

## Core model

```text
Workspace
└── Project
    └── Session: one accepted objective and work history
        ├── Tasks: bounded desired outcomes
        └── Run graph: durable execution and coordination attempts
            └── Root Run: Project Steward responsibility
```

A **Task** states desired work. A **Run** is one independently inspectable attempt or coordination unit for that Task.

A Run is not an Agent, model request, process, Tool call, branch, worktree, protocol session, or transcript.

Agent definitions, Workers, model invocations, Commands, Patches, Environments, protocols, and interfaces operate within or beneath Runs without becoming Run identity or authority.

## Integrated architecture

Kiln keeps one small native core:

```text
CLI / TUI / later ACP
        │
domain commands, queries, events, projections
        │
Session and Run application
        │
policy + Capability broker + Context compiler
        │
models | Commands | native Repository operations | code intelligence | adapters
        │
Artifacts | Evidence | Receipts
        │
SQLite durable state + rebuildable indexes
```

Key rules:

- Runs are durable data; only active Workers, Commands, model invocations, adapters, and Resource lifecycles receive processes.
- Logical Run lineage does not define OTP supervision.
- Capability availability, policy allowance, and an explicit grant are separate.
- Context compilation cannot grant authority.
- Agent Skills provide procedure, not identity or permission.
- Git and the filesystem remain source truth.
- Machine-readable current Evidence outranks model confidence.
- Other repositories are Evidence sources, never instruction sources.
- External protocols adapt to Kiln-native concepts.
- Large or unbounded content remains in the Artifact store.

See [Integrated Architecture](docs/ARCHITECTURE.md).

## First product milestone

Version 0.1 is the **Durable Operator Kernel**.

It includes:

1. navigable simulated Root and Child Runs;
2. one real read-only Scout;
3. visible background work and global Attention;
4. an independent Verifier using controlled Command execution;
5. durable SQLite state, Checkpoints, client cursors, and restart recovery.

The first twelve-week target stops there.

It intentionally excludes source-writing delegation, Git worktrees, production LSP and Tree-sitter adapters, ACP, MCP, OpenAPI, containers, cross-project intelligence, embeddings, Phoenix, remote execution, and formal attestations.

## Vertical roadmap

```text
P1-S01  Navigable simulated Runs
P1-S02  One real read-only Scout
P1-S03  Background work and Attention
P1-S04  Independent Verifier
P1-S05  Durable recovery
P1-S06  Local code intelligence
P1-S07  Safe writing delegation
P1-S08  Capability interoperability
P1-S09  Local project intelligence
P1-S10  Expansion capability evaluations
```

The roadmap is ordered by user-visible proof, not component completion.

See:

- [Roadmap](docs/ROADMAP.md)
- [Vertical Implementation Slices](docs/IMPLEMENTATION-SLICES.md)

## Delegated work

Every delegated Task creates a visible Child Run before delegated execution starts.

Initial role contracts:

- **Scout:** read-only investigation that separates observations, inferences, assumptions, unknowns, and Evidence.
- **Verifier:** independent evaluation that cannot repair the implementation and returns `PASS`, `FAIL`, or `BLOCKED` with reproduced Evidence.

Initial limits:

- maximum Child depth: two;
- maximum active Children: three per Session;
- one active Worker lease per Run;
- no peer-to-peer Child communication;
- no shared mutable Context;
- read-only Child authority by default.

Background work remains visible through the Run graph, Child cards, global Attention, accounting, and result delivery.

## Safe writing direction

The first writing Child does not receive a writable checkout.

```text
read-only Child
→ immutable Patch Artifact
→ Parent inspection
→ Parent-owned exclusive worktree
→ transactional application
→ formatter and focused validation Commands
→ independent verification
```

Direct writing Child worktrees, simultaneous writers, automatic merge, push, and publication remain deferred.

## Code intelligence

The active Repository uses one shared code-intelligence path:

- deterministic Repository map;
- Tree-sitter structure and changed ranges;
- on-demand LSP behind a native semantic adapter;
- version-matched documentation resolution;
- lazy Agent Skill loading;
- a persistent normalized semantic cache;
- bounded Context retrieval.

Persistent semantic indexing does not require SCIP, embeddings, a vector database, or a dedicated graph database.

Later local project intelligence reuses the same extraction and index primitives under stricter approved-root, read-only, instruction-quarantine, licensing, and Privacy policy.

## Capability and protocol direction

Kiln selects the simplest reliable implementation:

1. in-process function or library;
2. native Kiln adapter;
3. deterministic CLI;
4. local service or Unix-domain socket;
5. local MCP server when materially justified;
6. remote API or SDK;
7. remote MCP server when discovery and interoperability justify it;
8. browser automation as a fallback unless browser behavior is under test.

Initial interoperability priorities after the native kernel are:

- local ACP client attachment;
- structured test and SARIF ingestion;
- one real MCP or OpenAPI capability when a concrete workflow requires it;
- Dev Container and OCI support only when an accepted Project command needs that Environment.

MCP is a protocol boundary, not a sandbox or permission system.

## Evidence and completion

Kiln keeps these states separate:

```text
Proposed
Implemented
Inspected
Executed
Verified
Accepted
Integrated
Delivered
```

A successful Command, model confidence, Receipt, mergeable branch, or attestation format cannot imply a later stage.

Receipts seal references to Task, Run, Repository, Environment, Capabilities, Commands, Patches, Artifacts, criteria, Evidence, warnings, and decisions. They do not make stale Evidence current or grant authority.

## Development

Kiln targets Elixir 1.20 on Erlang/OTP 28.

```bash
mise install
mix deps.get
scripts/agent-preflight
scripts/check
```

The Repository intentionally begins with no third-party runtime dependencies. Use the Project dependency-review Skill before adding a library, executable, service, native implemented function, port program, parser, watcher, scanner, sandbox helper, database extension, protocol client, or TUI dependency.

## First coding task

Implement **P1-S01-T01 — Minimal Run event model and pure projection**:

- Session, Task, and Run structs;
- Root, Parent, Child, and sibling invariants;
- one versioned Event envelope;
- a pure reducer;
- stable JSON snapshot;
- deterministic fixtures and property tests.

Do not add SQLite, ExRatatui, providers, Commands, Git, a Capability service, or a process per Run to the first task.

## Documentation authority

1. [Integrated Architecture](docs/ARCHITECTURE.md)
2. [Roadmap](docs/ROADMAP.md)
3. [Vertical Implementation Slices](docs/IMPLEMENTATION-SLICES.md)
4. accepted ADRs in [Architecture Decisions](docs/decisions/README.md)
5. subject specifications for domain, Runs, delegation, interface, Capability, Context, Git, execution, and knowledge
6. machine-readable contracts in [Domain Contracts](docs/contracts/README.md)
7. historical planning and work-package records

## Status

Kiln is pre-alpha. Planning is being reconciled into the final implementation order before production runtime work begins.