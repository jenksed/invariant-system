---
title: Data Flow
description: Producer-contract-consumer relationships across the current Invariant system.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - contracts/
  - products/loadout/src/core/schemas.ts
  - products/kiln/
  - products/temper/src/types.ts
audience:
  - developer
---

# Data Flow

```mermaid
flowchart LR
    Arsenal[Arsenal / Bench] -->|Qualified Method Record| Loadout[Loadout]
    Loadout -->|Work Envelope| Kiln[Kiln]
    Kiln -->|Run Result Envelope| Temper[Temper]
    Kiln -. learning observation .-> Arsenal
```

The canonical contract documents live at the repository root. Products keep language-specific adapters and types but must not create competing canonical semantics.

## Current real path

Repository Recon exercises the middle of this graph now:

```text
Loadout Plan
→ Work Envelope v0
→ Kiln supervision
→ Run Result Envelope v0
→ Temper projection
```

## Qualification and selection

Qualified Method Record v0 exists as a cross-product contract and Arsenal/Bench produce qualification-related evidence. Manifold's future assignment/selection output is not yet a runtime contract in this monorepo. Do not add one merely to make a diagram symmetrical.
