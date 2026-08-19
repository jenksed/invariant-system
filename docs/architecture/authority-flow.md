---
title: Authority Flow
description: Where authority originates, where it is evaluated, and how operator/control surfaces delegate without absorbing it.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
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
    T[Temper projection / control surface]

    H --> L
    L -->|requests capability| K
    K -->|grant / deny| E
    E --> R
    R --> T

    H -. operator action .-> T
    T -. governed request; planned where unsupported .-> K

    A[Arsenal method] -. no grant .-> K
    B[Bench qualification] -. no grant .-> K
    M[Manifold selection] -. cannot expand grant .-> K
```

Loadout's real driver embodies the current boundary operationally: a denied Kiln authority decision prevents the procedure from running.

The Temper → Kiln operator-action edge is an architectural control-path rule, not a blanket claim that every planned Workbench action already exists. When implemented, Temper may ask Kiln to perform an operation; Kiln must still validate authority, current state, and action semantics and must remain the durable source of resulting truth.

A remote topology does not change this rule. The operator host may be physically separate from the execution host without receiving the execution authority held by Kiln.
