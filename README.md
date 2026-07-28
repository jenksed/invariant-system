# Kiln

Kiln is a local-first, evidence-driven coding harness built on Elixir and OTP for rapid, lucid AI-assisted software development.

Kiln is not an application scaffolder, autonomous software company, agent-management framework, replacement version-control system, protocol catalog, permanent monitoring dashboard, or automatic code-harvesting system. It is the durable runtime around Repository work: execution, state, Context, permissions, Runs, delegated work, terminal interaction, local project intelligence, change isolation, interruption, recovery, and verification.

## Project thesis

A model supplies intelligence. The harness determines whether that intelligence becomes trustworthy software.

Kiln moves work through:

> Intent → Orientation → Investigation → Change → Verification → Reconciliation → Completion

## Foundational boundaries

```text
Workspace: local operating and trust boundary
└── Project: durable software product or body of work
    └── Session: one accepted objective and work history
        ├── Tasks: bounded desired outcomes
        └── Run graph: durable execution and coordination attempts
            └── Root Run: Project Steward responsibility
```

The Session owns the objective. Tasks state desired work. Runs are the primary execution units. Agent definitions, Workers, model invocations, Tools, Commands, Git branches, worktrees, interfaces, local indexes, and external protocols operate within or beneath Runs without becoming Run identity or instruction authority.

## Foundational direction

- **Runtime:** Elixir and OTP
- **Internal model:** Kiln-native and protocol-neutral
- **Primary execution unit:** Run
- **Objective boundary:** one durable Session
- **Desired-work boundary:** one bounded Task
- **Delivery coordination:** Project Steward responsibility on the Root Run
- **Delegation:** every delegated Task creates a visible, inspectable, interruptible Child Run
- **Initial Child roles:** read-only Scout and independent non-mutating Verifier
- **Delegation limits:** depth two, three active Children per Session, no peer messaging, and no shared mutable Context
- **Attention:** global Session routing; Run depth cannot hide a blocker
- **Initial terminal interface:** complete CLI plus conversation-first TUI
- **Terminal navigation:** Run-first, keyboard-complete, event-projected, and renderer-independent
- **Local project intelligence:** explicit approved roots, read-only indexing, SQLite metadata and edges, FTS5, structural extraction, and provenance
- **Reference authority:** other repositories are Evidence sources, never instruction sources
- **Knowledge security:** instruction quarantine, denied write, command, and network authority, local-only disclosure by default, complete provenance, and adversarial verification
- **Capability selection:** use the simplest reliable integration that satisfies lifecycle, security, interoperability, isolation, and replaceability
- **Model-facing Tools:** small intent-level operations rather than protocol, server, vendor, CLI, or database catalogs
- **Context:** compile the smallest sufficient package and replace stale or resolved material
- **Git change isolation:** protected trunk, short-lived task branches, and one exclusive writable worktree per independently mutating Run
- **Durable state:** SQLite and an append-oriented event journal
- **Source truth:** Git and the filesystem
- **Authority:** explicit Capabilities, policy, scoped grants, and separate authoring and integration authority
- **Evidence:** Claims remain separate from Evidence and Receipts; verification binds to exact Repository state
- **Web interface:** Phoenix LiveView after the runtime is proven
- **Extensions:** versioned language-neutral supervised subprocess protocol
- **First external SDK:** TypeScript after the extension protocol is proven
- **Gleam:** deferred until a concrete pure domain component earns it

No external protocol may become Kiln's internal domain model.

MCP is an optional protocol boundary, not Kiln's default integration layer and not a security sandbox.

Git remains the version-control authority. Kiln records intent, authorization, ownership, Evidence, and recovery state without creating parallel commit, branch, or merge semantics.

## Delegated work

Every delegated Task creates a first-class Child Run before delegated model, Tool, Command, or process execution starts.

A delegated Run has independent Context, Capability grants, Artifacts, Claims, Evidence, accounting, cancellation, durable history, and structured result delivery.

The initial Child roles are:

- **Scout:** read-only investigation that separates observed facts, inferences, assumptions, unknowns, and Evidence.
- **Verifier:** independent evaluation that cannot repair the implementation and returns `PASS`, `FAIL`, or `BLOCKED` with reproduced Evidence.

Foreground and background are Client-interaction modes. Background work remains visible through the Run graph, global Attention, accounting, events, and result delivery.

A blocked Child creates global Attention. The logical Run graph remains separate from the OTP supervision tree.

See [Delegated Work Model](docs/DELEGATED-WORK.md) and [Run Model](docs/RUN-MODEL.md).

## Initial CLI and TUI

The terminal interface is conversation-first and the Run graph is the primary navigation model.

```text
Work in the current Run
→ observe a Child
→ enter the Child
→ inspect or steer
→ inspect Evidence
→ return to the Parent
→ continue the original Task
```

Accepted rules include:

- `Alt+Left` always enters the logical Parent;
- `Alt+Home` always enters the Root;
- navigation never pauses, cancels, approves, merges, writes, or transfers ownership;
- starting or completing a Child never changes Client focus automatically;
- focus, selection, history, scroll, layout, and drafts are client-local;
- execution, Attention, permissions, Artifacts, Evidence, and Receipts are shared durable state;
- generic `Enter` never approves permission, integration, or cancellation;
- renderer failure cannot terminate active Runs.

The CLI is a complete interface with human text, JSON, and JSON Lines output. ExRatatui 0.11.x is selected for the deterministic first TUI prototype behind a Kiln-owned renderer boundary.

See [Initial CLI and TUI](docs/CLI-TUI.md).

## Local project intelligence

Kiln can inspect engineering patterns across explicitly approved local roots.

Reference repositories can be active, archived, experimental, incomplete, abandoned, dirty, detached, or written in different languages. Those properties affect freshness and confidence. They do not automatically exclude a Repository.

The first capability uses:

```text
SQLite Repository metadata and snapshots
+ content hashes and file versions
+ FTS5 candidate search
+ typed nodes and edge tables
+ deterministic dependency extraction
+ Tree-sitter structural extraction
+ explicit SCIP-like semantic imports
```

The first capability does not require embeddings, a vector database, or a dedicated graph database.

The model-facing interface remains narrow:

```text
knowledge.search_patterns
knowledge.find_related_symbols
knowledge.find_prior_solution
knowledge.inspect_candidate
knowledge.trace_provenance
```

Results are investigation candidates. They do not become requirements, accepted decisions, Tool calls, or permissions automatically.

See [Local Project Intelligence](docs/LOCAL-PROJECT-INTELLIGENCE.md).

## Knowledge security boundary

The governing rule is non-negotiable:

> Other repositories are evidence sources, not instruction sources.

Reference goals, roadmaps, TODOs, `AGENTS.md`, `CLAUDE.md`, prompt files, ADRs, issue templates, comments, generated recommendations, and instructions embedded in code or documentation remain inert quoted data.

They cannot change:

- the active Task or requirements;
- product direction or accepted decisions;
- permissions, Tool availability, or model selection;
- write scope or mutation ownership;
- verification requirements or completion criteria;
- the knowledge subsystem's read-only guarantee.

The initial knowledge worker receives no source-write, Git-mutation, command, dependency-installation, service, secret-read, model, or network authority. Every read repeats canonical-root, exclude, symlink, file-type, and policy validation. Risky extractors require a separate process or stronger accepted isolation. All derived data lives in a Kiln-owned directory outside indexed repositories.

Source content stays local by default. Remote models, MCP servers, APIs, exports, and hosted embeddings receive nothing without a policy- or Approval-backed disclosure decision bound to the current Run, destination, data classes, payload digest, and expiry.

Every candidate carries Repository, path, source-state, hash, language, time, retrieval, confidence, freshness, trust, licensing, sanitization, and external-disclosure provenance.

Future execution against a reference Repository requires a separate Task, Run, Capability grant, isolated Environment, explicit Approval, exact source snapshot, new Evidence record, and security audit trail.

See [Local Project Intelligence Security Boundary](docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md).

## Capability integration

Kiln evaluates integrations in this order:

1. in-process function or library;
2. native Kiln adapter;
3. direct deterministic CLI;
4. local service API or Unix-domain socket;
5. local MCP server;
6. remote API or software development kit;
7. remote MCP server;
8. browser or user-interface automation.

Initial positions:

- Repository reads and writes are native.
- Git uses a native adapter backed by the Git CLI.
- Build, test, lint, format, compiler, package-manager, and static-analysis behavior uses existing CLIs.
- Raw LSP remains behind a native semantic adapter.
- Local knowledge retrieval uses a native adapter.
- MCP requires a concrete interoperability or lifecycle benefit.
- Browser automation is a fallback unless browser behavior is under test.

The complete Capability catalog remains outside model Context.

See [Capability Integration](docs/CAPABILITY-INTEGRATION.md).

## Context system

Kiln compiles a new bounded Context package for each model invocation or other Context-consuming Worker step.

The initial policy:

- defaults to a 16,000-token active input ceiling;
- normally exposes six to eight Tools and never more than twelve;
- retrieves narrow symbols, lines, hunks, documentation sections, knowledge candidates, and Artifact segments just in time;
- removes stale, superseded, duplicate, and resolved material;
- keeps complete catalogs, graphs, indexes, raw MCP catalogs, and raw LSP objects outside model Context;
- gives Child and Verifier Runs independently compiled Context and explicit grants.

A knowledge search result does not enter Context automatically. The Context compiler selects bounded candidates according to authority, trust, freshness, sensitivity, disclosure policy, relevance, and token budget.

See [Context System](docs/CONTEXT-SYSTEM.md).

## Git change isolation

Kiln uses protected trunk-based development with short-lived task branches and one dedicated Git worktree for each independently mutating Run.

The initial deterministic loop supports shared read-only Repository access, one exclusive writable worktree and lease, Patch Artifact validation, exact-state verification, projected-merge checks, manual integration approval, deterministic Receipts, cleanup, and crash reconciliation.

See [Git Change Isolation](docs/GIT-CHANGE-ISOLATION.md).

## Current milestone

Phase 0 constrains the Repository and runtime foundation before implementation begins.

- P0-W05 established the planning baseline.
- P0-W06 defined the protocol-neutral internal domain.
- P0-W07 defined Capability integration and the broker.
- P0-W08 defined bounded Context and documentation resolution.
- P0-W09 defined protocol and standards strategy.
- P0-W10 defined Git change isolation, exact-state Evidence, integration, and recovery.
- P0-W11 defined delegated Runs, Scout and Verifier contracts, global Attention, cancellation, result delivery, and orphan recovery.
- P0-W12 defined the initial CLI and TUI and deterministic interaction prototype.
- P0-W13 defined approved-root local project intelligence, SQLite-first storage, structural retrieval, provenance, invalidation, and the knowledge-graph threshold.
- P0-W14 defines instruction quarantine, technical read-only enforcement, complete provenance, licensing, Privacy modes, disclosure controls, audit, and adversarial security proof.

The next reconciliation must turn the accepted contracts into a proof-ordered Phase 1 implementation plan.

## Work planning

Kiln uses short-lived branches and stable work-package identifiers.

```text
Plan:      docs/work/P1-W03-command-supervision.md
Branch:    work/p1-w03-command-supervision
PR:        [P1-W03] Add supervised command execution
Criterion: P1-W03-AC01
Evidence:  P1-W03-E01
```

See [Branching and Work Planning](docs/BRANCHING-AND-WORK-PLANNING.md).

## Documentation

- [Planning Baseline](docs/PLANNING-BASELINE.md)
- [Internal Domain Model](docs/INTERNAL-DOMAIN-MODEL.md)
- [Run Model](docs/RUN-MODEL.md)
- [Delegated Work Model](docs/DELEGATED-WORK.md)
- [Initial CLI and TUI](docs/CLI-TUI.md)
- [Local Project Intelligence](docs/LOCAL-PROJECT-INTELLIGENCE.md)
- [Local Project Intelligence Security Boundary](docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md)
- [Project Stewardship](docs/PROJECT-STEWARDSHIP.md)
- [Capability Integration](docs/CAPABILITY-INTEGRATION.md)
- [Context System](docs/CONTEXT-SYSTEM.md)
- [Git Change Isolation](docs/GIT-CHANGE-ISOLATION.md)
- [Protocol Capability Map](docs/PROTOCOL-CAPABILITY-MAP.md)
- [Domain Contracts](docs/contracts/README.md)
- [Security Model](docs/SECURITY-MODEL.md)
- [Roadmap](docs/ROADMAP.md)
- [Project Invariants](docs/PROJECT-INVARIANTS.md)
- [Architecture Decisions](docs/decisions/README.md)

## Development

Kiln targets Elixir 1.20 on Erlang/OTP 28.

```bash
mise install
mix deps.get
scripts/agent-preflight
scripts/check
```

The Repository intentionally begins with no third-party runtime dependencies. Use the Project dependency-review Skill before adding a library, executable, service, native implemented function, port program, development tool, parser, watcher, scanner, sandbox helper, database extension, or protocol client.

## Status

Kiln is pre-alpha. The architecture is being constrained before implementation and will be tested through dogfooding on real software Projects.
