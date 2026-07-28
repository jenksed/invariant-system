# Planning Baseline

**Document type:** Historical planning audit  
**Status:** Superseded as current authority by P0-W16  
**Original audit date:** 2026-07-28  
**Current authority:** `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and `docs/IMPLEMENTATION-SLICES.md`

## Purpose

This document originally audited the early planning stack and exposed missing integration, stale status, unresolved Run and interface order, and the gap between documentation and implementation.

Its work is complete. P0-W16 integrates the accepted planning passes and replaces this document as the current architecture and roadmap authority.

The Git history preserves the complete original audit. This shortened record preserves the durable conclusions that implementation must continue to respect.

## Durable conclusions from the audit

1. Documentation cannot prove implementation.
2. `main` is Repository integration truth.
3. Accepted architecture and Repository integration status are separate facts.
4. A Run, not an Agent persona, is Kiln's primary durable work unit.
5. Task intent, Run execution, model invocations, Tools, Commands, processes, and Git state are distinct.
6. Claims, Evidence, Receipts, acceptance, integration, and delivery are distinct.
7. Git and the filesystem remain source truth for Repository state.
8. External protocols and providers cannot define Kiln's internal domain.
9. Development-agent Skills and prompts help build Kiln; they are not Kiln runtime capabilities.
10. Phase order must be driven by observable product proof rather than component ambition.

## Current product definition

Kiln is a local-first, evidence-driven coding harness for one developer building real software with AI.

Kiln owns:

- durable Session, Task, and Run state;
- visible delegated work;
- explicit authority and Capability grants;
- bounded Context;
- controlled model and Command execution;
- inspectable Patch application;
- Artifacts, Evidence, Receipts, and Checkpoints;
- Attention routing and recovery;
- native Repository trust and local project intelligence policy.

Kiln does not replace Git, language servers, build systems, test runners, mature CLIs, or external protocols.

## Current implementation reality

At the start of P0-W16, Repository evidence shows:

- one Elixir Mix project;
- an OTP application shell;
- project version and baseline tests;
- CI, prose checks, agent preflight, and asset validation;
- integrated planning and contract documents through P0-W15;
- no implemented production Session, Run, provider, Command, TUI, persistence, code-intelligence, Patch, knowledge, or adapter runtime.

The architecture is accepted planning. Runtime support must be demonstrated by source, deterministic tests, current CI, and required slice Receipts.

## Current source-of-truth hierarchy

### Integrated product and implementation authority

1. `README.md` — product identity and milestone summary.
2. `docs/ARCHITECTURE.md` — integrated architecture and responsibility boundaries.
3. `docs/ROADMAP.md` — implementation order and milestones.
4. `docs/IMPLEMENTATION-SLICES.md` — slice-level tickets, gates, security, tests, demos, and Receipts.
5. accepted ADRs — architectural constraints.

### Subject authority

Detailed specifications remain authoritative for their subject, including:

- internal domain and Run model;
- delegated work;
- CLI and TUI;
- Capability integration;
- Context compilation;
- Git isolation;
- trustworthy execution;
- local code and project intelligence;
- knowledge security;
- protocol positions.

A subject document cannot reorder the integrated roadmap or pull all of its described future scope into an early slice.

### Machine-readable contracts

`docs/contracts/` defines provisional Kiln-native shapes. Contract existence does not prove implementation. Each slice implements only the subset it exercises.

### Historical records

- this file;
- `docs/PLAN-RECONCILIATION.md`;
- earlier roadmap versions;
- `docs/work/` records;
- merged planning pull requests.

Historical records cannot override the current architecture and roadmap.

## Resolved planning conflicts

| Earlier conflict | P0-W16 resolution |
| --- | --- |
| No integrated planning source | One architecture, one roadmap, one detailed slice plan. |
| Run graph delayed behind infrastructure | P1-S01 begins with simulated navigable Runs. |
| Provider delayed until a complete kernel | P1-S02 adds one fixed-policy real Scout. |
| Evidence deferred | Scout and Verifier introduce minimal Evidence and Receipts; Slice 5 makes them durable. |
| Persistence before interface learning | Slices 1–4 use deterministic fixtures; Slice 5 persists proven semantics. |
| One process per domain noun | Runs remain data; only active lifecycle owners receive processes. |
| Separate code and project intelligence stacks | Shared extraction and index primitives with separate trust policy. |
| Worktree-writing Child versus Patch mode | Initial writing Child returns a Patch Artifact to a Parent-owned worktree. |
| Protocol priority mistaken for early scope | Adapter seams remain; implementation is evidence-gated after the native loop. |
| Component-only Phase 1 | Replaced by P1-S01 through P1-S10 vertical slices. |

## Current first implementation target

The first twelve-week target is the Durable Operator Kernel through P1-S05:

```text
navigable simulated Runs
→ one real read-only Scout
→ background work and Attention
→ independent Verifier
→ durable SQLite recovery
```

Source writing, LSP, Tree-sitter, protocols, containers, local project intelligence, embeddings, Phoenix, remote execution, and formal attestations remain outside that target.

## Status vocabulary

- **Observed:** current Repository or executed Evidence supports the statement.
- **Accepted:** an owner decision or accepted ADR establishes the direction.
- **Integrated:** the change exists on `main`.
- **Proposed:** the change exists only on a branch or pull request.
- **Implemented:** production source or configuration exists.
- **Verified:** current deterministic checks passed against stated state.
- **Accepted work:** the user or accepted policy approved the result.
- **Delivered:** Evidence shows the accepted result reached its destination.
- **Deferred:** intentionally excluded until an entry condition is met.
- **Superseded:** a later authority replaces the statement.

No status implies a later status automatically.