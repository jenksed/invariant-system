# ADR 0019: Implement Kiln through vertical product slices

- **Decision status:** Accepted
- **Integration status:** Integrated through pull request 20
- **Date:** 2026-07-28

## Context

Kiln completed a sequence of architecture passes covering the internal domain, Runs, delegation, CLI and TUI, Capability integration, Context, protocols, Git isolation, local project intelligence, knowledge security, and trustworthy execution.

The resulting architecture is coherent, but the provisional Phase 1 roadmap remained component-shaped. It proposed completing contract consolidation, persistence, Command supervision, Run control, Git isolation, Context, interfaces, knowledge, security, observability, and a phase proof as separate horizontal packages.

That sequence carried three risks:

1. Kiln could spend months building internal infrastructure before proving its Run-centered interaction model.
2. Every accepted future subsystem could enter the early backlog merely because the final architecture included it.
3. Duplicated paths could emerge for active code intelligence, cross-project intelligence, external protocols, execution, and interface state.

The Project needs one implementation order that preserves the accepted security and Evidence boundaries while delivering product-shaped proof as early as possible.

## Decision

Kiln will be implemented through vertical product slices.

The accepted default order is:

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

Each slice must include:

- user-visible value;
- the minimum domain and runtime concepts it needs;
- explicit dependencies and security boundary;
- deterministic tests;
- an acceptance gate;
- a demo script;
- a Receipt;
- explicit exclusions.

A slice does not complete an entire subsystem unless the demo requires it.

### Minimal architecture decisions

P0-W16 also accepts these integration decisions:

1. **Runs remain durable data.** Kiln does not create one permanent process per Run. Processes exist only for active Worker leases, Commands, model invocations, adapters, subscriptions, timing, cancellation, or managed Resources.
2. **One code-intelligence path serves active and reference use.** Tree-sitter, on-demand LSP, documentation resolution, and normalized semantic facts share extraction and index infrastructure. Reference repositories receive stricter trust, Privacy, instruction-quarantine, and no-execution policy.
3. **Persistent semantic indexing is Kiln-native first.** Store normalized structural and selected semantic observations keyed by exact state and tool versions. Do not require automatic SCIP generation, embeddings, a vector database, or a graph database.
4. **Initial writing delegation uses Patch Artifacts.** A writing Child remains read-only and returns an immutable Patch proposal. The authorized Parent owns one exclusive writable worktree and applies the selected Patch transactionally.
5. **Protocol seams do not imply protocol-first implementation.** ACP, MCP, OpenAPI, Dev Containers, OCI, and later standards enter only after the native Run, authority, execution, Evidence, and recovery loop exists and a concrete workflow justifies them.
6. **Version 0.1 is read-only.** The first release milestone ends after durable recovery of navigable Runs, one real Scout, background Attention, and an independent Verifier.

### Version 0.1 boundary

Version 0.1 is the Durable Operator Kernel through P1-S05.

It includes:

- navigable Root and Child Runs;
- one real read-only Scout;
- background concurrency and global Attention;
- independent controlled verification;
- minimal Artifacts, Evidence, and Receipts;
- SQLite durability, Checkpoints, client cursors, and restart recovery.

It excludes source mutation, worktrees, production LSP and Tree-sitter adapters, external protocols, containers, local project intelligence, embeddings, Phoenix, remote execution, and formal attestations.

## Consequences

- The first implementation task is a pure Run event reducer, not a database or service framework.
- The TUI interaction model is tested before persistence and providers.
- One real model-backed Scout appears early, but broad model routing does not.
- The minimum Command runner enters with the Verifier rather than as an isolated execution package.
- Persistence arrives after Run, Attention, and verification semantics are demonstrated.
- Source mutation is delayed until the read-only product is durable and independently verified.
- Subject specifications remain architecture constraints but do not independently add early roadmap scope.
- Protocol and expansion candidates can remain deferred without weakening the native architecture.
- Historical P1-W01 through P1-W13 identifiers no longer define implementation order.

## Rejected positions

- Building every internal component before the first navigable product demo.
- Treating every foundational protocol seam as a Phase 1 implementation requirement.
- Creating a permanent process, service, or table for every domain noun.
- Implementing separate active-code and local-project parser and index stacks.
- Treating persistent semantic indexing as an automatic SCIP or graph-database requirement.
- Giving the first writing Child a shared writable checkout.
- Requiring containers or worktrees for harmless reads.
- Moving embeddings, graph databases, remote execution, Phoenix, AG-UI, or formal attestations into the first release.
- Preserving the old component roadmap beside the vertical roadmap.

## Review triggers

Review this decision when:

- a slice cannot deliver its user-visible demo without a missing horizontal prerequisite;
- the in-memory-to-SQLite transition would require changing accepted domain semantics;
- Patch Artifact mode prevents a measured high-value writing workflow;
- one code-intelligence path cannot satisfy both active and reference Repository security boundaries;
- a protocol is required by a concrete user workflow earlier than planned;
- the twelve-week target repeatedly fails despite active scope pruning;
- dogfooding shows that version 0.1 lacks a minimum capability needed to evaluate the product;
- implementation Evidence justifies splitting, merging, or reordering a slice.

A review must state what scope is removed as well as what is added.