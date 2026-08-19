---
title: Architecture Boundaries for Contributors
description: Rules that preserve ownership while products share one Git root.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - AGENTS.md
  - invariant.boundaries.json
audience:
  - developer
---

# Architecture Boundaries for Contributors

Before a cross-product change, ask two questions:

1. Which product owns the fact or decision?
2. What contract should carry it across the boundary?

Do not solve cross-product integration with source imports merely because relative paths are convenient in a monorepo.

Run:

```bash
./invariant check boundaries
```

The check catches several structural violations, but semantic review remains necessary. It cannot automatically detect every form of authority laundering or duplicated business meaning.
