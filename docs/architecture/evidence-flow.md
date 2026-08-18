---
title: Evidence Flow
description: How proposal, execution, verification, acceptance, and learning evidence remain distinct.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/
  - products/arsenal/evaluation/
  - contracts/learning-observation.v0.md
audience:
  - developer
---

# Evidence Flow

```mermaid
flowchart LR
    P[Proposal / prepared work]
    X[Execution + effects]
    V[Registered verification]
    D[Decision / acceptance]
    RR[Run Result projection]
    LO[Learning observation]
    BE[Bench evaluation evidence]

    P --> X --> V --> D --> RR
    RR -. observation .-> LO -. learning input .-> BE
```

The current repository implements meaningful parts of this flow, but not a single complete Development Loop that exercises every box exactly as drawn.

The important architectural property is separation: runtime evidence about a specific change is not automatically qualification evidence about a model, and qualification evidence does not become permission to mutate a repository.
