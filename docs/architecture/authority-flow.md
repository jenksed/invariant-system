---
title: Authority Flow
description: Where authority originates, where it is evaluated, and how planned operator/control surfaces delegate without absorbing it.
status: current
verified_at_commit: fed26fcc8b7598a56ce86e47c99d0154e6b46436
source_paths:
  - invariant.boundaries.json
  - products/loadout/src/core/kiln-driver.ts
  - products/kiln/
audience:
  - developer
  - operator
---

# Authority Flow

```mermaid
flowchart LR
    H[Human intent / policy]
    L[Loadout request\nWork Envelope]
    K[Kiln authority evaluator]
    E[Authorized execution/effect]
    R[Durable result + evidence]
    T[Temper projection]

    H --> L
    L -->|requests capability| K
    K -->|grant / deny| E
    E --> R
    R --> T

    H -. planned operator action .-> T
    T -. planned governed request .-> K

    A[Arsenal method] -. no grant .-> K
    B[Bench qualification] -. no grant .-> K
    M[Manifold selection] -. cannot expand grant .-> K
```

Loadout's real driver embodies the current boundary operationally: a denied Kiln authority decision prevents the procedure from running.

The Temper → Kiln operator-action edge is a **planned control-path rule**, not current Temper ownership and not a blanket claim that Workbench actions exist. If implemented, Temper may ask Kiln to perform an operation; Kiln must validate authority, current state, and action semantics and remain the durable source of resulting truth.

A remote topology does not change this rule. The operator host may be physically separate from the execution host without receiving the execution authority held by Kiln.
