---
title: System Roadmap
description: Cross-product milestones required to move from Repository Recon to a governed one-change Development Loop.
status: planned
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - docs/roadmap/index.md
  - integration/scenarios/repository-recon/
  - contracts/
audience:
  - developer
---

# System Roadmap

## Current system proof

Repository Recon demonstrates the current public-boundary spine:

```text
Loadout preparation → real Kiln supervision → Temper projection
```

The next step should reuse that spine rather than inventing another orchestration path for code changes.

## Milestone: Development Loop v0

**Problem:** prove one real software change without letting planning, model intelligence, verification, UI, or receipts silently absorb runtime/human authority.

**Prerequisites:** current Work/Run contracts; accepted Kiln mutation/evidence slice; registered verification; independent-review representation; durable human-decision representation.

**Acceptance property:** a real repository change traverses public boundaries and no completion claim can bypass the authority/evidence chain.

**Evidence required:** exact repository/base state, requested/granted authority, proposal bytes/digest, observed mutation, registered verification bound to resulting state, independent review evidence, explicit human decision, final projection, restart/negative-path results.

**Blockers:** exact mutation slice authorization and review/decision integration semantics are not established by the current root contracts alone.

## Milestone: Full current-contract integration matrix

**Problem:** the historical Wave 3 matrix is broader than the automated monorepo golden path.

**Prerequisites:** none beyond current Repository Recon contracts for cases that do not redesign semantics.

**Acceptance property:** current negative/restart cases execute against the same public boundaries as the golden path.

**Evidence required:** deterministic scenario results and preserved failure states.

**Parallelism:** largely safe in parallel with documentation and product-local non-semantic work; do not mix new contract design into the test expansion accidentally.
