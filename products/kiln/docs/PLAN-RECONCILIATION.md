# Plan Reconciliation

**Document type:** Historical planning record  
**Status:** Resolved by P0-W16  
**Resolution:** `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and `docs/IMPLEMENTATION-SLICES.md`

## Purpose

This document originally recorded conflicts that had to be resolved before implementation.

P0-W16 resolves those conflicts and replaces the candidate component sequence with a vertical-slice roadmap. This document remains as evidence of the questions that drove the reconciliation. It is no longer implementation-order authority.

## Preserved inputs

P0-W16 preserves:

1. Elixir and OTP own runtime coordination.
2. A Session is the durable boundary for one accepted Project objective.
3. Each Session contains exactly one Root Run.
4. The Run graph is the durable model for independently inspectable work.
5. Project Steward responsibility belongs to the Root Run by default.
6. Logical Run lineage is separate from OTP supervision.
7. Each Client owns its focused Run.
8. Attention routing is independent of Run depth.
9. Read-only Child Runs precede writing delegation.
10. Concurrent writers require isolation.
11. Evidence-backed completion and Repository-state binding remain foundational.
12. MiniMax is the first direct provider target.
13. CLI and TUI remain independent from Phoenix.
14. development-agent Skills and prompts are not Kiln runtime Runs.
15. external protocols adapt to Kiln-native concepts.

## Resolved conflicts

### Session and Run scope

**Resolution:** Session, Task, Run, lineage, Attention, Client focus, and Steward projections are introduced through P1-S01 through P1-S05 as each user-visible slice needs them. There is no horizontal “complete domain package” before the first product demo.

### Event journal scope

**Resolution:** Slices 1 through 4 prove event semantics through deterministic in-memory fixtures. P1-S05 persists the same versioned event envelopes in one SQLite journal and rebuilds Session, Run, Attention, execution, Evidence, and interface projections.

### Interface proof order

**Resolution:** P1-S01 is the first implementation slice. It delivers simulated Root and Child Runs, breadcrumbs, Child cards, Parent and sibling navigation, streamed deterministic events, and headless TUI tests before providers, Commands, Git, or persistence.

### Provider proof order

**Resolution:** P1-S02 adds one real read-only Scout using a fixed-policy direct provider adapter, MiniMax first. Broad multi-provider routing, Kimi or Codex managed-client bridges, fallback, and ensembles remain later evidence-based work.

### Project Steward proof order

**Resolution:** Steward responsibility emerges through the first five slices:

```text
navigable Run graph
→ evidence-backed Scout
→ visible Attention and control
→ independent verification
→ durable recovery and completion projection
```

There is no separate early Steward service or Agent persona.

### Evidence timing

**Resolution:** minimal Evidence and Receipts appear with the first real Scout and Verifier. P1-S05 makes them durable and recoverable. Later slices extend structured results, Patch, integration, and delivery Evidence without redefining the concepts.

### Command supervision timing

**Resolution:** the minimum registered Command runner enters in P1-S04 because the independent Verifier needs controlled execution. Environment, network, secret, process-tree, container, and broader result support expand only when later slices require them.

### Writing isolation

**Resolution:** P1-S07 chooses Patch Artifact mode for delegated writing. The Child remains read-only. The Parent owns one exclusive writable worktree and applies one selected Patch transactionally. Direct writing Child worktrees are deferred.

### Code intelligence and local project intelligence

**Resolution:** Tree-sitter, on-demand LSP, documentation resolution, and persistent normalized semantic facts form one code-intelligence path. Local project intelligence reuses those primitives under stricter approved-root, read-only, instruction-quarantine, licensing, and Privacy policy.

### Protocol priority

**Resolution:** protocol seams remain accepted, but implementations do not precede the native product loop. ACP, structured result adapters, MCP, OpenAPI, Dev Containers, and OCI are independently evidence-gated in P1-S08.

### Persistence versus early product learning

**Resolution:** do not force SQLite before the Run interaction is understood. Do not claim durability until P1-S05. The same domain events and projections are exercised in-memory first, then persisted without changing their semantic roles.

## Accepted vertical order

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

## Version 0.1 decision

Version 0.1 is the Durable Operator Kernel through P1-S05.

It demonstrates:

- navigable Root and Child Runs;
- one real read-only Scout;
- visible background work and Attention;
- independent controlled verification;
- Artifacts, Evidence, and Receipts sufficient for those flows;
- SQLite durability, Checkpoints, client cursors, restart recovery, and honest orphan state.

It does not mutate source.

## Identifier migration

The provisional component packages `P1-W01` through `P1-W13` are superseded as implementation-order identifiers.

New implementation planning uses:

```text
P1-S01       vertical slice
P1-S01-T01   implementation ticket
P1-S01-G01   acceptance gate
P1-S01-D01   demo
P1-S01-R01   Receipt
```

Historical work-package files remain records. New implementation plans use the slice identifiers and branch names in `docs/ROADMAP.md`.

## Current authorities

1. `docs/ARCHITECTURE.md`
2. `docs/ROADMAP.md`
3. `docs/IMPLEMENTATION-SLICES.md`
4. accepted ADRs
5. subject specifications
6. machine-readable contracts

No statement in this historical document overrides those authorities.