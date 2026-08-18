---
title: System Map
description: Current and planned relationships among Invariant product areas.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant.boundaries.json
  - integration/scenarios/repository-recon/run.sh
  - products/manifold/README.md
audience:
  - developer
  - operator
---

# System Map

```mermaid
flowchart TB
    Human[Human / operator]

    subgraph Intelligence[Engineering intelligence]
      Arsenal[Arsenal\nmethods · research · learning]
      Bench[Bench\nevaluation · qualification evidence]
      Arsenal --> Bench
    end

    subgraph Preparation[Work preparation]
      Loadout[Loadout\ngoals · capabilities · plans · Work Envelopes]
    end

    subgraph Selection[Selection]
      Manifold[Manifold\nselection · allocation\nNO RUNTIME YET]
    end

    subgraph Runtime[Governed runtime]
      Kiln[Kiln\nauthority · execution · effects · evidence · verification]
    end

    subgraph Experience[Operator experience]
      Temper[Temper\nread-only projection]
    end

    Human --> Loadout
    Bench -. qualification evidence .-> Manifold
    Loadout -->|Work Envelope| Kiln
    Manifold -. future assignment .-> Kiln
    Kiln -->|Run Result Envelope| Temper
    Temper --> Human
    Kiln -. Learning Observation direction .-> Arsenal
```

Solid edges are present in the current Repository Recon system where applicable. Dashed edges represent architecture that is either indirect or not yet implemented end to end.

## Canonical shared surfaces

`contracts/` defines the cross-product facts. `integration/` proves selected cross-product behavior. `program/` preserves decisions, planning, and history. None is a peer product.
