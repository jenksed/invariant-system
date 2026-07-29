# ADR 0019: Implement Kiln through vertical product slices

- **Decision status:** Accepted
- **Integration status:** Integrated through pull request 20
- **Date:** 2026-07-28
- **Supersession status:** Slice order, first coding target, and read-only version 0.1 boundary are proposed for supersession by ADR 0020

## Context

Kiln completed architecture planning across domain, Runs, delegation, interfaces, Capability integration, Context, protocols, Git isolation, local project intelligence, security, and trustworthy execution.

The earlier Phase 1 plan was component-shaped. It proposed completing contracts, persistence, execution, Run control, Git isolation, Context, interfaces, knowledge, observability, and a phase proof as horizontal packages.

That order risked building internal infrastructure before product-shaped behavior and pulling every planned subsystem into the first implementation phase.

## Accepted decision that remains active

Kiln is implemented through vertical product slices.

Every slice must include:

- user-visible value;
- the minimum domain and runtime concepts required by its workflow;
- explicit dependencies and security boundary;
- deterministic tests;
- an aggregate acceptance gate;
- a demo;
- a bounded Receipt;
- explicit exclusions.

A slice does not complete an entire subsystem unless its workflow requires that subsystem.

## Accepted architecture decisions that remain active

1. **Runs remain durable data.** Kiln does not create one permanent process per Run. Processes exist only for live Worker leases, Commands, model invocations, adapters, subscriptions, timing, cancellation, or managed Resources.
2. **One code-intelligence path can serve active and reference use.** When that capability enters scope, Tree-sitter, selected LSP operations, documentation resolution, and normalized semantic facts can share extraction and index infrastructure while reference repositories retain stricter trust and no-execution policy.
3. **Persistent semantics remain Kiln-native first.** SCIP, embeddings, a vector database, and a graph database are not default requirements.
4. **Later writing delegation uses Patch Artifacts.** A writing Child remains read-only and returns an immutable Patch proposal. An authorized applying Run owns mutation and verification.
5. **Protocol seams do not imply protocol-first implementation.** ACP, MCP, OpenAPI, Dev Containers, OCI, and later standards require a concrete workflow and entry gate.
6. **Subject specifications cannot reorder delivery.** Detailed planning remains bounded by the current Roadmap.
7. **Historical component identifiers do not define implementation order.** P1-W01 through P1-W13 remain historical.

## Historical order

ADR 0019 originally accepted:

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

It also defined a read-only version 0.1 through P1-S05 and placed the TUI before persistence, provider execution, and source mutation.

## Proposed partial supersession

ADR 0020 proposes a new order:

```text
P1-S01  Durable single-Run CLI
P1-S02  Evidence-backed single-Run change loop
P1-S03  Interruption and unknown-effect recovery
P1-S04  One bounded Scout Child
P1-S05  Independent Verifier Child
```

Under ADR 0020:

- the first month completes one real source change;
- SQLite durability begins with the first product slice;
- provider, Patch, Command, Artifact, Evidence, and completion support enter in narrow form during the first month;
- Child Runs are earned after the Root workflow works;
- version 0.1 supports maximum depth one and one active Child;
- the TUI and all later expansion capabilities move beyond version 0.1.

ADR 0020 becomes binding only after owner acceptance and integration.

## Historical consequences

ADR 0019:

- replaced a horizontal component backlog with product slices;
- rejected a process or table for every domain noun;
- preserved protocol-neutral native semantics;
- prevented every planned adapter or index from entering Phase 1 automatically;
- preserved one shared future code-intelligence path;
- established explicit slice gates, demos, Receipts, and exclusions.

Its original sequence did not prove a complete coding workflow early enough. P0-W18 challenges that order without discarding the vertical-slice discipline.

## Rejected positions that remain rejected

- building every internal component before user-visible proof;
- treating protocol seams as implementation requirements;
- creating a permanent process, service, or table for every noun;
- separate active-code and reference-code parser stacks by default;
- requiring SCIP, embeddings, a graph database, or vector database;
- giving a writing Child a shared writable checkout;
- requiring containers or worktrees for harmless reads;
- moving remote execution, Phoenix, AG-UI, or formal attestations into version 0.1;
- preserving competing implementation roadmaps.

## Review triggers

Review vertical-slice structure when:

- a slice cannot deliver usable behavior without a missing horizontal prerequisite;
- accepted durable semantics cannot migrate safely between slices;
- one selected checkout cannot satisfy a measured mutation workflow;
- one code-intelligence path cannot preserve active and reference trust separation;
- a protocol is required earlier by a concrete workflow;
- the twelve-week target repeatedly fails despite scope reduction;
- dogfooding shows version 0.1 lacks a minimum capability needed to evaluate Kiln;
- implementation Evidence justifies splitting, merging, or reordering a slice.

A review must state what scope is removed as well as what is added.
