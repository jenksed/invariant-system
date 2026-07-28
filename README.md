# Kiln

Kiln is a local-first, evidence-driven coding harness built on Elixir and OTP for rapid, lucid AI-assisted software development.

Kiln is not an application scaffolder, an autonomous software company, an agent-management framework, a replacement version-control system, or a catalog of protocol implementations. It is the durable runtime around model-driven Repository work: execution, state, Context, permissions, Runs, change isolation, interruption, recovery, and verification.

## Project thesis

A model supplies intelligence. The harness determines whether that intelligence becomes trustworthy software.

Kiln moves work through:

> Intent → Orientation → Investigation → Change → Verification → Reconciliation → Completion

Kiln uses these foundational boundaries:

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
- **External integration:** adapters map protocols and mature tools to Kiln domain commands, events, and schemas
- **Capability selection:** use the simplest reliable integration that satisfies lifecycle, security, interoperability, isolation, and replaceability
- **Model-facing Tools:** small intent-level operations rather than protocol, server, vendor, or CLI catalogs
- **Context compilation:** compile the smallest sufficient package for the next decision or action; do not fill a larger model window
- **Context continuity:** replace stale and resolved material with immutable manifests and compact Checkpoints rather than append forever
- **Documentation:** prefer authoritative, version-matched Project and dependency sources before Context7, web research, or model memory
- **Objective boundary:** one durable Session
- **Desired-work boundary:** one bounded Task
- **Execution model:** one Root Run and a navigable Run graph
- **Primary execution unit:** Run, not Agent persona, branch, process, or model invocation
- **Delivery coordination:** Project Steward responsibility on the Root Run
- **Git change isolation:** protected trunk, short-lived task branches, and one exclusive writable worktree per independently mutating Run
- **Read-only work:** no branch or worktree by default unless stable state requires one
- **Restricted mutation:** Patch Artifacts for Child Runs that should not own a writable checkout
- **Initial interface:** command-line interface
- **Durable state:** SQLite and an append-oriented event journal
- **Source truth:** Git and the filesystem
- **Authority:** explicit Capabilities, policy, scoped grants, and separate authoring and integration authority
- **Evidence:** Claims remain separate from Evidence and Receipts; verification binds to exact Repository state
- **Web interface:** Phoenix LiveView, after the runtime is proven
- **Extensions:** language-neutral supervised subprocess protocol
- **First external software development kit:** TypeScript, after the protocol is proven
- **Gleam:** deferred until a concrete pure domain component earns it

No external protocol may become Kiln's internal domain model.

MCP is an optional protocol boundary, not Kiln's default integration layer and not a security sandbox.

Git remains the version-control authority. Kiln records intent, authorization, ownership, Evidence, and recovery state without creating parallel commit, branch, or merge semantics.

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
- Local MCP requires material lifecycle, state, sharing, replacement, discovery, or existing-implementation value.
- Remote MCP requires material interoperability and discovery value beyond a narrow API.
- Browser automation is a fallback unless browser behavior is under test.
- Mature tools are orchestrated rather than rebuilt.

The full Capability catalog remains outside model Context. A Run receives a small phase-relevant Tool projection such as `repo.read`, `code.inspect`, `command.run`, and `verify.run`.

See [Capability integration](docs/CAPABILITY-INTEGRATION.md).

## Context system

Kiln compiles a new bounded Context package for each model invocation or other Context-consuming Worker step.

The package is built for one immediate purpose from current intent, accepted requirements, Task and Run state, Repository state, Evidence, assumptions, unknowns, the active Skill, phase-relevant Tools, permissions, model characteristics, remaining token budget, and compact Checkpoints.

The initial policy:

- defaults to a 16,000-token active input ceiling even when the provider supports more;
- uses lower phase targets;
- normally exposes six to eight Tools and never more than twelve;
- uses a 2,500-token default Tool-schema budget and a 4,000-token absolute ceiling;
- retrieves symbols, relevant lines, changed hunks, documentation sections, and Artifact segments just in time;
- removes stale, superseded, duplicate, and resolved material from the next package;
- keeps complete logs, test streams, documentation pages, DOM snapshots, database results, and large output in Artifacts when a digest and reference are sufficient;
- keeps complete MCP catalogs and raw LSP objects outside model Context;
- loads Skills and additional Tools lazily;
- treats prompt caching as an optimization rather than correctness or memory;
- gives Child Runs and Verifier Runs independently compiled Context and explicit grants.

For Elixir Projects, documentation resolution prefers:

1. active Repository documentation;
2. accepted ADRs and specifications;
3. dependency-authored usage rules;
4. version-locked local ExDoc;
5. running-Project documentation through a native adapter;
6. Context7;
7. official external documentation;
8. general web research;
9. model memory.

See [Context system](docs/CONTEXT-SYSTEM.md).

## Git change isolation

Kiln uses protected trunk-based development with short-lived task branches and one dedicated Git worktree for each independently mutating Run.

The initial product loop supports:

- shared read-only access for safe Scout Runs;
- one exclusive writable worktree and lease for a mutating Run;
- Patch Artifacts for restricted Child Runs;
- exact commit-bound or dirty-fingerprint-bound verification;
- a Verifier that does not repair the branch it evaluates;
- projected-merge checks against current protected trunk;
- manual user-approved local integration;
- deterministic Receipts, cleanup, and crash reconciliation.

A Child Run does not inherit its Parent Run's branch or write authority. A branch does not require a permanent OTP process. The authoring Run does not authorize its own merge.

See [Git Change Isolation](docs/GIT-CHANGE-ISOLATION.md).

## Protocol strategy

Kiln ranks protocols by direct product value and keeps each behind a replaceable adapter.

Accepted positions include:

- ACP as the primary future editor and coding-client interface after the native event model;
- MCP client support before optional server support;
- normalized LSP and internal Tree-sitter infrastructure;
- AG-UI projections from the same native event stream;
- A2A only for independent external agents;
- Agent Skills as first-class procedural packages;
- OpenTelemetry for operational observation without replacing the event journal.

See [Protocol capability map](docs/PROTOCOL-CAPABILITY-MAP.md).

## Project Steward

The Project Steward uses Kiln's Run graph, Tasks, specifications, Repository observations, Capability policy, Context state, Git ownership, Evidence, and completion gates to coordinate work.

The Steward can:

- decompose work into bounded Tasks and Runs;
- route attention;
- request independent verification;
- track requirements, mutations, Evidence, risks, and unknowns;
- reconcile Repository state against the accepted specification;
- recommend continuation, blocking, integration, or completion.

The Steward cannot override user authority, policy, Repository truth, Evidence freshness, Git ownership, or completion gates.

## Current milestone

Phase 0 defines the Repository and runtime foundation before implementation begins.

- P0-W05 established the planning baseline.
- P0-W06 defined the protocol-neutral internal domain model.
- P0-W07 defined Capability integration and the broker.
- P0-W08 defined the bounded Context system and documentation resolver.
- P0-W09 defined the protocol and standards strategy.
- P0-W10 defines Git change isolation, worktree ownership, Evidence staleness, integration, and recovery.

The next roadmap reconciliation must align Phase 1 with:

- Workspace, Project, Repository, Environment, Session, Task, Run, and event identity;
- minimum Context, Capability, Claim, Evidence, Receipt, Checkpoint, branch-contract, worktree, lease, and Git-operation state;
- Repository observation and trust policy;
- controlled native Repository and Git adapters;
- Repository-scoped Git mutation serialization;
- exact-state Context and Evidence binding;
- one isolated mutating Run and one restricted Patch Artifact path;
- independent read-only verification;
- projected-merge verification and manual integration approval;
- cleanup and restart reconciliation;
- fake navigable Child Runs with independent Context;
- Client-local focus, attention routing, and Project Steward projection;
- provider-backed Root Runs after the deterministic kernel is proven.

See [Roadmap](docs/ROADMAP.md) and [Plan reconciliation](docs/PLAN-RECONCILIATION.md).

## Work planning

Kiln uses short-lived branches and stable work-package identifiers.

```text
Plan:      docs/work/P1-W03-command-supervision.md
Branch:    work/p1-w03-command-supervision
PR:        [P1-W03] Add supervised command execution
Criterion: P1-W03-AC01
Evidence:  P1-W03-E01
```

See [Branching and Work Planning](docs/BRANCHING-AND-WORK-PLANNING.md) before planned implementation.

## Agent-ready development

Project-local Skills, prompts, and specialist agents support the coding agent that builds Kiln. They are development controls. They are not Kiln runtime Runs, Agent definitions, or Workers.

The default workflow is:

```bash
scripts/agent-preflight
scripts/check
```

Project-local Skills live under `.agents/skills/`:

- `kiln-work-package`
- `kiln-elixir-otp`
- `kiln-dependency-review`
- `kiln-integrity-review`
- `kiln-evidence-closeout`

Optional Pi specialist agents live under `.pi/agents/`. The OTP and integrity agents are read-only. The verifier can run non-mutating checks but cannot edit files.

The main coding agent remains the default writer and owns final implementation decisions.

## Documentation

- [Planning baseline](docs/PLANNING-BASELINE.md)
- [Internal domain model](docs/INTERNAL-DOMAIN-MODEL.md)
- [Capability integration](docs/CAPABILITY-INTEGRATION.md)
- [Context system](docs/CONTEXT-SYSTEM.md)
- [Git Change Isolation](docs/GIT-CHANGE-ISOLATION.md)
- [Protocol capability map](docs/PROTOCOL-CAPABILITY-MAP.md)
- [Domain contracts](docs/contracts/README.md)
- [Project provenance](docs/PROJECT-PROVENANCE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Session model](docs/SESSION-MODEL.md)
- [Run model](docs/RUN-MODEL.md)
- [Project Stewardship](docs/PROJECT-STEWARDSHIP.md)
- [Security model](docs/SECURITY-MODEL.md)
- [Roadmap](docs/ROADMAP.md)
- [Plan reconciliation](docs/PLAN-RECONCILIATION.md)
- [Project invariants](docs/PROJECT-INVARIANTS.md)
- [Agent-friendly codebase rules](docs/AGENT-FRIENDLY-CODEBASE.md)
- [Elixir and OTP engineering guide](docs/ELIXIR-OTP-ENGINEERING.md)
- [Branching and Work Planning](docs/BRANCHING-AND-WORK-PLANNING.md)
- [Engineering quality rules](docs/ENGINEERING-QUALITY-RULES.md)
- [Architecture decisions](docs/decisions/README.md)
- [Implementation plan template](docs/templates/IMPLEMENTATION-PLAN.md)
- [ADR template](docs/templates/ADR.md)

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
