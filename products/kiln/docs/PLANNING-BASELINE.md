# Planning Baseline

**Document type:** Historical planning audit  
**Status:** Superseded as current planning-status authority  
**Original audit date:** 2026-07-28  
**Current planning-status authority:** `docs/PLANNING-COMPLETION-BASELINE.md`  
**Current architecture authority:** `docs/ARCHITECTURE.md` and accepted ADRs  
**Current implementation-order authority:** `docs/ROADMAP.md`

## Required use

This document preserves the durable conclusions of the earlier source-of-truth audit.

Do not use it as the current planning status or implementation sequence.

For current authority, conflicts, implementation evidence, debt, build blockers, and the exact next pass, read `docs/PLANNING-COMPLETION-BASELINE.md`.

## Original purpose

The original audit inspected the early planning stack and exposed:

- missing integration;
- stale status;
- unresolved Run and interface order;
- the gap between documentation and implementation;
- branch and pull-request state that was not yet on `main`.

P0-W16 later integrated the accepted architecture and replaced the component-shaped roadmap with vertical slices.

P0-W17 now audits that integrated state for the Planning Completion Sequence.

Git history preserves the complete original audit. This file preserves the conclusions that remain valid.

## Durable conclusions

1. Documentation does not prove implementation.
2. `main` is Repository integration truth.
3. Decision acceptance and Repository integration are separate facts.
4. A Run, not an Agent persona, is Kiln's primary durable work unit.
5. Task intent, Run execution, model invocations, Tools, Commands, processes, and Git state are distinct.
6. Claims, Evidence, Receipts, acceptance, integration, and delivery are distinct.
7. Git and the filesystem remain source truth for Repository state.
8. External protocols and providers do not define Kiln's internal domain.
9. Development-agent Skills and prompts help build Kiln. They are not Kiln runtime capabilities.
10. Product proof, not component ambition, determines implementation order.
11. A process exists only when it owns a live lifecycle concern.
12. A Schema, module name, plan, or passing compile check does not prove user-visible behavior.

## Historical implementation observation

At the start of P0-W16, Repository evidence showed:

- one Elixir Mix project;
- an OTP application shell;
- project version and baseline tests;
- CI, prose checks, agent preflight, and asset validation;
- integrated planning and contract documents;
- no production Session, Run, provider, Command, TUI, persistence, code-intelligence, Patch, knowledge, or adapter runtime.

The current planning-completion audit must use current source and tests to update that observation. Do not infer capability from this historical record.

## Historical source-of-truth hierarchy

P0-W16 established this hierarchy:

1. `README.md` — product identity and milestone summary;
2. `docs/ARCHITECTURE.md` — integrated architecture and responsibility boundaries;
3. `docs/ROADMAP.md` — implementation order and milestones;
4. `docs/IMPLEMENTATION-SLICES.md` — slice-level tickets, security, tests, demos, and Receipts;
5. accepted ADRs — architecture constraints;
6. subject specifications — detailed boundaries;
7. machine-readable contracts — provisional shapes;
8. historical records — planning provenance.

P0-W17 preserves that hierarchy and adds `docs/PLANNING-COMPLETION-BASELINE.md` as planning-status authority only.

A historical document cannot override a current product, architecture, roadmap, ADR, subject specification, source file, test, or executed result.

## Resolved conflicts from P0-W16

| Earlier conflict | P0-W16 resolution |
| --- | --- |
| No integrated planning source | One architecture, one roadmap, and one detailed slice plan. |
| Run graph delayed behind infrastructure | P1-S01 begins with simulated navigable Runs. |
| Provider delayed until a complete kernel | P1-S02 adds one fixed-policy real Scout. |
| Evidence deferred | Scout and Verifier introduce minimum Evidence and Receipts; P1-S05 makes them durable. |
| Persistence before interface learning | P1-S01 through P1-S04 use deterministic fixtures; P1-S05 persists proven semantics. |
| One process per domain noun | Runs remain data; only active lifecycle owners receive processes. |
| Separate code and project intelligence stacks | Shared extraction and index primitives use separate trust policy. |
| Worktree-writing Child versus Patch mode | The first writing Child returns a Patch Artifact to a Parent-owned worktree. |
| Protocol priority mistaken for early scope | Adapter seams remain; implementation is evidence-gated after the native loop. |
| Component-only Phase 1 | P1-S01 through P1-S10 replaced P1-W01 through P1-W13. |

These resolutions remain accepted architecture. The current audit records any repository artifact that did not reconcile to them.

## Historical version 0.1 decision

P0-W16 set the first milestone as the Durable Operator Kernel through P1-S05:

```text
navigable simulated Runs
→ one real read-only Scout
→ background work and Attention
→ independent Verifier
→ durable SQLite recovery
```

Source writing, production LSP and Tree-sitter, external protocols, containers, local project intelligence, embeddings, Phoenix, remote execution, and formal attestations remain outside that milestone unless a later accepted decision changes the boundary.

## Status vocabulary

- **Observed:** Current Repository or executed Evidence supports the statement.
- **Accepted:** An owner decision or accepted ADR establishes the direction.
- **Integrated:** The change exists on `main`.
- **Proposed:** The change exists only on a branch, pull request, or candidate plan.
- **Scaffolded:** Structure exists, but the required behavior does not.
- **Implemented:** Production source or configuration contains the behavior.
- **Verified:** Current deterministic checks passed against the stated Repository state.
- **Accepted work:** The user or accepted policy approved the result.
- **Delivered:** Evidence shows that the accepted result reached its destination.
- **Deferred:** An accepted boundary excludes the work until an entry condition occurs.
- **Superseded:** A later authority replaced the statement.
- **Blocked:** A stated condition prevents safe progress.

No status implies a later status automatically.

## Current continuation

Continue with `docs/PLANNING-COMPLETION-BASELINE.md`.

Do not begin implementation from this historical record.