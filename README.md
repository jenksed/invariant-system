# Kiln

Kiln is a local-first, evidence-driven coding harness built on Elixir and OTP for rapid, lucid AI-assisted software development.

Kiln is not an application scaffolder, autonomous software company, agent-management framework, replacement version-control system, or protocol catalog. It is the durable runtime around model-driven Repository work: execution, state, Context, permissions, Runs, delegated work, change isolation, interruption, recovery, and verification.

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

The Session owns the objective. Tasks state desired work. Runs are the primary execution units. Agent definitions, Workers, model invocations, Tools, Commands, Git branches, worktrees, and external protocols operate within or beneath Runs without becoming Run identity.

Kiln supports bounded Child Runs without turning the product into an artificial organization of agents.

## Foundational direction

- **Runtime:** Elixir and OTP
- **Internal model:** Kiln-native and protocol-neutral
- **Primary execution unit:** Run, not an Agent persona, branch, process, Tool call, or model invocation
- **Objective boundary:** one durable Session
- **Desired-work boundary:** one bounded Task
- **Delivery coordination:** Project Steward responsibility on the Root Run
- **Delegation:** every delegated Task creates a visible, inspectable, interruptible Child Run
- **Initial Child roles:** read-only Scout and independent non-mutating Verifier
- **Delegation limits:** depth two, three active Children per Session, no peer messaging, and no shared mutable Context
- **Attention:** global Session routing; Run depth cannot hide a blocker
- **Capability selection:** use the simplest reliable integration that satisfies lifecycle, security, interoperability, isolation, and replaceability
- **Model-facing Tools:** small intent-level operations rather than protocol, server, vendor, or CLI catalogs
- **Context:** compile the smallest sufficient package and replace stale or resolved material
- **Documentation:** prefer authoritative, version-matched Project and dependency sources before Context7, web research, or model memory
- **Git change isolation:** protected trunk, short-lived task branches, and one exclusive writable worktree per independently mutating Run
- **Restricted mutation:** Patch Artifacts when a later accepted writing Child must not own a writable checkout
- **Initial interface:** command-line interface
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

A delegated Run has independent:

- Context and Capability grants;
- Artifacts, Claims, and Evidence;
- token, cost, time, and Resource accounting;
- status, cancellation, and durable history;
- structured result delivery.

The initial Child roles are:

- **Scout:** read-only investigation that separates observed facts, inferences, assumptions, unknowns, and Evidence.
- **Verifier:** independent evaluation that cannot repair the implementation and returns `PASS`, `FAIL`, or `BLOCKED` with reproduced Evidence.

Repeated procedures normally become Skills, not permanent Agent personas.

Foreground and background are client-interaction modes. Background work remains visible through the Run graph, global Attention, accounting, events, and result delivery.

A blocked Child creates global Attention. The user can answer, enter the originating Run, route to the Parent, deny, pause, or cancel.

The logical Run graph remains separate from the OTP supervision tree.

See [Delegated Work Model](docs/DELEGATED-WORK.md) and [Run Model](docs/RUN-MODEL.md).

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

Kiln selects the earliest practical option that satisfies the required contract.

Initial positions:

- Repository reads and writes are native.
- Git uses a native adapter backed by the Git CLI.
- Build, test, lint, format, compiler, package-manager, and static-analysis behavior uses existing CLIs.
- Raw LSP remains behind a native semantic adapter.
- MCP requires a concrete interoperability or lifecycle benefit.
- Browser automation is a fallback unless browser behavior is under test.
- Mature tools are orchestrated rather than rebuilt.

The complete Capability catalog remains outside model Context. A Run receives a small phase-relevant Tool projection.

See [Capability Integration](docs/CAPABILITY-INTEGRATION.md).

## Context system

Kiln compiles a new bounded Context package for each model invocation or other Context-consuming Worker step.

The initial policy:

- defaults to a 16,000-token active input ceiling even when the provider supports more;
- uses lower phase targets;
- normally exposes six to eight Tools and never more than twelve;
- uses a 2,500-token default Tool-schema budget and a 4,000-token absolute ceiling;
- retrieves symbols, relevant lines, changed hunks, documentation sections, and Artifact segments just in time;
- removes stale, superseded, duplicate, and resolved material from later packages;
- keeps unbounded output in Artifacts when a digest and reference are sufficient;
- keeps complete MCP catalogs and raw LSP objects outside model Context;
- loads Skills and additional Tools lazily;
- treats prompt caching as an optimization rather than correctness or memory;
- gives Child and Verifier Runs independently compiled Context and explicit grants.

See [Context System](docs/CONTEXT-SYSTEM.md).

## Git change isolation

Kiln uses protected trunk-based development with short-lived task branches and one dedicated Git worktree for each independently mutating Run.

The initial deterministic product loop supports:

- safe shared read-only Repository access;
- one exclusive writable worktree and lease for a mutating Run;
- Patch Artifact validation for restricted mutation workflows;
- exact commit-bound or dirty-fingerprint-bound verification;
- a Verifier that does not repair the evaluated branch;
- projected-merge checks against current protected trunk;
- manual user-approved local integration;
- deterministic Receipts, cleanup, and crash reconciliation.

A Child does not inherit its Parent's branch or write authority. A branch does not require a permanent OTP process. The authoring Run does not authorize its own merge.

The initial Scout and Verifier roles remain read-only. A later work package must accept a writing Child role before model-backed Child mutation is enabled.

See [Git Change Isolation](docs/GIT-CHANGE-ISOLATION.md).

## Protocol strategy

Kiln ranks protocols by direct product value and keeps each behind a replaceable adapter.

Accepted positions include ACP as the primary future coding-client interface after the native event model, MCP client support before optional server support, normalized LSP, internal Tree-sitter infrastructure, AG-UI projections from native events, A2A only for independent external agents, first-class Agent Skills, and OpenTelemetry for runtime observation.

See [Protocol Capability Map](docs/PROTOCOL-CAPABILITY-MAP.md).

## Project Steward

The Project Steward uses the Run graph, Tasks, specifications, Repository observations, Capability policy, Context, Git ownership, Evidence, Attention, and completion gates to coordinate work.

The Steward can decompose work, request bounded delegation, route Attention, request independent verification, track traceability, and recommend continuation, blocking, integration, or completion.

It cannot override user authority, policy, Repository truth, Evidence freshness, Git ownership, or completion gates.

See [Project Stewardship](docs/PROJECT-STEWARDSHIP.md).

## Current milestone

Phase 0 constrains the Repository and runtime foundation before implementation begins.

- P0-W05 established the planning baseline.
- P0-W06 defined the protocol-neutral internal domain.
- P0-W07 defined Capability integration and the broker.
- P0-W08 defined bounded Context and documentation resolution.
- P0-W09 defined protocol and standards strategy.
- P0-W10 defined Git change isolation, exact-state Evidence, integration, and recovery.
- P0-W11 defines delegated Runs, Scout and Verifier contracts, state transitions, global Attention, cancellation, timeout, result delivery, and orphan recovery.

The next reconciliation must turn these accepted contracts into a proof-ordered Phase 1 implementation plan.

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

## Agent-ready development

Project-local Skills, prompts, and specialist agents support construction and review of Kiln. They are development controls, not evidence that Kiln runtime Runs are implemented.

```bash
scripts/agent-preflight
scripts/check
```

The main coding agent remains the default writer. Optional specialist development agents are read-only or non-mutating verifiers.

## Documentation

- [Planning Baseline](docs/PLANNING-BASELINE.md)
- [Internal Domain Model](docs/INTERNAL-DOMAIN-MODEL.md)
- [Run Model](docs/RUN-MODEL.md)
- [Delegated Work Model](docs/DELEGATED-WORK.md)
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

The Repository intentionally begins with no third-party runtime dependencies. Use the Project dependency-review Skill before adding a library, executable, service, native implemented function, port program, development tool, or protocol client.

## Status

Kiln is pre-alpha. The architecture is being constrained before implementation and will be tested through dogfooding on real software Projects.
