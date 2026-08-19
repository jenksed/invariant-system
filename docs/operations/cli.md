---
title: Root CLI
description: Current commands exposed by the root ./invariant developer entry point.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
audience:
  - developer
---

# Root CLI

Current commands:

```bash
./invariant status
./invariant doctor
./invariant check
./invariant check boundaries
./invariant test [all|arsenal|loadout|kiln|temper|integration]
```

`status` reports branch, commit, dirty/clean state, product paths, and major runtimes.

`doctor` checks prerequisites without installing them.

`check` verifies root structure and single-Git-root assumptions.

`check boundaries` enforces a subset of architectural boundaries mechanically.

`test` delegates to the canonical product gates instead of reimplementing them.

Documentation commands are added by the documentation foundation only when they continue this delegation model.
