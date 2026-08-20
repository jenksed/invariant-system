---
title: Testing Changes
description: Match validation evidence to the property a change can actually affect.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - AGENTS.md
  - invariant
audience:
  - developer
---

# Testing Changes

Choose validation by ownership and blast radius.

A product-local change can usually begin with that product's canonical gate. A contract, integration, or boundary change requires every affected consumer/producer path.

A green unit suite is not a substitute for a cross-product scenario when the acceptance property is “these products communicate through the intended public boundary.” Conversely, a single integration path does not prove every product-local invariant.

Record exact commands and results. Separate environment-blocked checks from passing checks.

## Fast feedback without weaker completion

```bash
./invariant test changed HEAD --list
./invariant test changed origin/main
```

The first command previews conservative routing; the second runs it. Changed
files include committed divergence, staged/unstaged work, and untracked files.
Selected gates continue after a failure so one edit/test cycle can expose more
than the first defect. Structure and boundary checks always run.

This is not qualification. Contracts and boundary policy still require all
consuming products, and the canonical repository claim still requires
`./invariant test`. See the [developer loop](developer-loop.md) for setup,
formatting, runtime, Graph, and tooling profiles.
