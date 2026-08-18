---
title: Authority Flow
description: Where authority originates, where it is evaluated, and which components cannot create it.
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
    T[Temper projection]

    H --> L
    L -->|requests capability| K
    K -->|grant / deny| E
    E --> R
    R --> T

    A[Arsenal method] -. no grant .-> K
    B[Bench qualification] -. no grant .-> K
    M[Manifold selection] -. cannot expand grant .-> K
```

Loadout's real driver embodies this boundary operationally: a denied Kiln authority decision prevents the procedure from running.

The diagram does not imply every future human-approval step is already implemented across the whole Development Loop. It shows the current ownership rule that future slices must preserve.
