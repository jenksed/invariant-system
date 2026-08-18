---
title: Development Loop v0
description: Target one-change workflow for Invariant; not yet complete end to end.
status: planned
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - README.md
  - program/
  - products/
audience:
  - developer
  - operator
---

# Development Loop v0

The next system milestone is deliberately small: prove one real code change through the intended authority boundaries.

Target shape:

```mermaid
flowchart LR
    L[Loadout\nrequest + plan]
    M[Manifold\nselection when needed]
    K1[Kiln\nbounded implementation]
    K2[Exact mutation]
    V[Registered verification]
    R[Independent review]
    H[Human decision]
    T[Temper projection]
    A[Arsenal / Bench\nlearning observation]

    L --> M --> K1 --> K2 --> V --> R --> H --> T
    H -. observation .-> A
```

## Current vs target

Current components already cover substantial pieces: Loadout planning, real Kiln supervision, registered verification foundations, Arsenal review methods, Temper projection, and cross-product contracts.

The complete chain above is still **planned**. In particular, documentation must not imply that Manifold selection, governed mutation, independent reviewer selection, explicit human decision, and learning feedback are all currently connected as one public workflow.

## Acceptance property

A v0 implementation is credible only when a real repository change traverses the intended public boundaries, authority cannot be bypassed through convenience paths, verification/review are state-bound, the human decision is explicit, and the final projected result can be independently inspected.
