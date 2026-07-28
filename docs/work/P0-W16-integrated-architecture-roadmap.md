# P0-W16: Integrated architecture and implementation roadmap

- **Status:** Implemented; verification pending
- **Branch:** `work/p0-w16-integrated-architecture-roadmap`
- **Depends on:** P0-W05 through P0-W15
- **Scope:** Planning and documentation only

## Objective

Integrate all accepted Kiln planning passes into one coherent architecture, remove duplication and contradictions, and replace the component-shaped implementation plan with the smallest vertical-slice roadmap that can deliver the intended product.

## Inputs inspected

P0-W16 reconciles:

- planning baseline and pending reconciliation;
- internal domain and Run model;
- Project Steward and delegated work;
- CLI and TUI;
- Capability integration;
- Context compilation;
- protocol and standards map;
- Git change isolation;
- local project intelligence and security;
- trustworthy execution, Commands, Patches, Evidence, Receipts, telemetry, and attestations;
- current README, roadmap, contracts, ADRs, templates, and work-planning rules.

## Protected decisions

- Elixir and OTP own runtime coordination.
- Run is the primary durable execution unit.
- Task intent, Run execution, model invocation, Tool call, Command, process, branch, and protocol identity remain separate.
- Run lineage does not define OTP supervision.
- Capability availability does not grant authority.
- Context compilation does not grant authority.
- Git and the filesystem remain Repository source truth.
- one writable worktree has one mutation owner.
- authoring, verification, acceptance, integration, and delivery authority remain separate.
- Claims, Evidence, Receipts, and freshness remain distinct.
- other repositories are Evidence sources, never instruction sources.
- local project intelligence remains read-only and local-only by default.
- deterministic execution and machine-readable Evidence outrank model confidence.
- external protocols adapt to Kiln-native contracts.

## Requirements

- **P0-W16-R01:** Produce one integrated architecture authority.
- **P0-W16-R02:** Explain how all accepted systems interact without creating parallel architectures.
- **P0-W16-R03:** Replace the component-only Phase 1 roadmap with vertical slices.
- **P0-W16-R04:** Preserve the ten user-directed slice outcomes while pruning speculative early scope.
- **P0-W16-R05:** Define user value, concepts, dependencies, modules, security, criteria, tests, Receipt, demo, exit, and deferrals for every slice.
- **P0-W16-R06:** Reconcile the broader architecture sequence with the vertical roadmap.
- **P0-W16-R07:** Define milestones, dependency graph, implementation tickets, acceptance gates, and demo scripts.
- **P0-W16-R08:** Choose the initial writing-delegation mechanism.
- **P0-W16-R09:** Define the first coding task.
- **P0-W16-R10:** Define a realistic first twelve-week target.
- **P0-W16-R11:** Update the document hierarchy and close stale planning authorities.
- **P0-W16-R12:** Be aggressive about exclusions and avoid adding a subsystem merely because the final architecture may need it.
- **P0-W16-R13:** Align branch, plan, PR, gate, demo, and Receipt identifiers with the vertical roadmap.
- **P0-W16-R14:** Reconcile protocol “priority” with actual slice entry conditions.
- **P0-W16-R15:** Do not add production runtime code or dependencies.

## Integrated decisions

### Small runtime

Runs remain durable records and projections. Kiln does not create one permanent process per Run. Active Worker leases, Commands, model invocations, adapters, subscriptions, timers, and managed Resources receive processes only while they own live lifecycle concerns.

### Shared code intelligence

Tree-sitter, on-demand LSP, documentation resolution, Skills, and native semantic facts form one active-code intelligence path. Later approved-root intelligence reuses those extractors and `index.sqlite3` infrastructure under stricter reference trust and no-execution policy.

### Native persistent semantics

Kiln persists normalized structural facts and selected semantic observations keyed by exact source and tool versions. SCIP remains a later import or export option. Embeddings, vector storage, and a dedicated graph database remain deferred.

### Safe writing delegation

The initial writing Child remains read-only and returns an immutable Patch Artifact. The authorized Parent applies one selected Patch in an exclusive writable worktree. Direct writing Child worktrees remain deferred.

### Protocol ordering

Adapter seams are foundational. Protocol implementation is not. ACP, structured result adapters, MCP, OpenAPI, Dev Containers, and OCI enter only after native Runs, authority, execution, Evidence, and recovery are proven. OpenTelemetry begins only after durable operation semantics stabilize and remains observation rather than state.

### Version 0.1

Version 0.1 is the Durable Operator Kernel through P1-S05:

```text
navigable simulated Runs
→ one real read-only Scout
→ background work and Attention
→ independent Verifier
→ durable recovery
```

## Changes

- add `docs/IMPLEMENTATION-SLICES.md` with all ten vertical slices, tickets, security boundaries, criteria, tests, Receipts, demos, exit conditions, deferrals, risks, first task, and twelve-week target;
- add `docs/SLICE-ACCEPTANCE-GATES.md` with aggregate gate identifiers and machine-readable gate expectations;
- replace `docs/ARCHITECTURE.md` with the integrated architecture authority;
- replace `docs/ROADMAP.md` with the vertical-slice implementation order and milestones;
- simplify `README.md` around the integrated product and first milestone;
- replace the protocol backlog with a slice-linked adapter-entry map in `docs/PROTOCOL-CAPABILITY-MAP.md`;
- mark `docs/PLAN-RECONCILIATION.md` resolved;
- mark `docs/PLANNING-BASELINE.md` historical and superseded as current authority;
- update `docs/BRANCHING-AND-WORK-PLANNING.md` for slice and ticket identifiers, small coherent branches, aggregate gates, demos, and Receipts;
- update `docs/templates/IMPLEMENTATION-PLAN.md` with slice contribution, security, deterministic verification, demo, and Receipt fields;
- update `docs/contracts/README.md` so schemas are boundaries rather than a horizontal backlog;
- add ADR 0019 and update the ADR index;
- record P0-W16 and the first coding task.

## Acceptance criteria

- **P0-W16-AC01:** One integrated architecture explains every required subsystem and dependency direction.
- **P0-W16-AC02:** No external protocol, UI, model, index, or process becomes parallel domain authority.
- **P0-W16-AC03:** The architecture rejects one permanent process per Run.
- **P0-W16-AC04:** Active code intelligence and local project intelligence share extraction and index primitives but retain separate trust policy.
- **P0-W16-AC05:** Persistent semantic indexing does not require SCIP, embeddings, vector storage, or a graph database.
- **P0-W16-AC06:** Writing delegation selects Patch Artifacts returned to the Parent.
- **P0-W16-AC07:** The old P1-W01 through P1-W13 component order is superseded rather than retained beside the new roadmap.
- **P0-W16-AC08:** P1-S01 through P1-S10 each define user value, concepts, dependencies, modules, security, criteria, deterministic tests, Receipt, demo, exit, and deferred scope.
- **P0-W16-AC09:** The roadmap includes milestones, dependencies, tickets, acceptance gates, demos, risks, and exclusions.
- **P0-W16-AC10:** Version 0.1 stops after P1-S05 and remains read-only.
- **P0-W16-AC11:** The first coding task is a pure Run event model and projection without infrastructure expansion.
- **P0-W16-AC12:** The first twelve-week target is explicit and excludes later systems.
- **P0-W16-AC13:** Planning baseline and reconciliation documents no longer claim current roadmap authority.
- **P0-W16-AC14:** Subject specifications remain normative for boundaries but cannot independently reorder implementation.
- **P0-W16-AC15:** Protocol and standards positions identify slice entry, concrete workflow, security, and removal gates rather than implied early backlog status.
- **P0-W16-AC16:** Work governance supports small slice tickets and prevents scattered tickets from falsely claiming aggregate slice completion.
- **P0-W16-AC17:** Every slice has explicit aggregate gate, demo, and Receipt identifiers.
- **P0-W16-AC18:** Repository CI passes on the final branch head.
- **P0-W16-AC19:** The diff changes documentation only.

## Verification

Repository checks:

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Planning checks:

- search active authorities for superseded P1-W implementation-order references;
- verify every required subsystem appears in the integrated architecture;
- verify all ten slices contain every required field;
- verify the roadmap, slice details, gate registry, and work-planning identifiers agree;
- verify protocol entry positions match the vertical roadmap;
- verify README, architecture, roadmap, ADR index, contract index, templates, and documentation hierarchy link correctly;
- verify no production source, tests, dependency, workflow, script, Skill, prompt, or runtime configuration changed.

## Evidence

- **P0-W16-E01:** `docs/ARCHITECTURE.md` is the integrated architecture authority.
- **P0-W16-E02:** `docs/IMPLEMENTATION-SLICES.md` defines all ten vertical slices, tickets, criteria, tests, Receipts, demos, risks, exclusions, first task, and twelve-week target.
- **P0-W16-E03:** `docs/SLICE-ACCEPTANCE-GATES.md` defines explicit aggregate gate identifiers and result requirements.
- **P0-W16-E04:** `docs/ROADMAP.md` defines implementation order, milestones, dependencies, and version 0.1.
- **P0-W16-E05:** `docs/PROTOCOL-CAPABILITY-MAP.md` ties adapter entry to slices and concrete evidence.
- **P0-W16-E06:** ADR 0019 records the vertical-slice and minimal-architecture decision.
- **P0-W16-E07:** planning baseline and reconciliation records are historical rather than competing authorities.
- **P0-W16-E08:** branching rules and the implementation-plan template use the new slice/ticket/gate/demo/Receipt vocabulary.
- **P0-W16-E09:** the final diff is planning-only.
- **P0-W16-E10:** final-head CI passes.

## Exclusions

P0-W16 does not implement:

- domain structs or events;
- TUI code or ExRatatui;
- SQLite migrations;
- provider adapters;
- Capability or Context services;
- Command workers;
- Git worktrees or Patches;
- Artifact storage;
- LSP or Tree-sitter;
- Skills runtime loading;
- ACP, MCP, OpenAPI, Dev Container, or OCI adapters;
- local project intelligence;
- OpenTelemetry;
- expansion protocols or attestations.