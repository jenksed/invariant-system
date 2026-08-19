---
title: Repository Layout
description: Current monorepo topology and semantic ownership of root directories.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - AGENTS.md
  - docs/MONOREPO-MIGRATION.md
audience:
  - developer
---

# Repository Layout

```text
products/arsenal/    intelligence, methods, Bench evaluation
products/loadout/    goals, capabilities, planning
products/kiln/       runtime authority and execution truth
products/temper/     operator projection
products/manifold/   selection boundary documentation only
contracts/           canonical cross-product semantics
integration/         fixtures and executable scenarios
program/             decisions, work packages, dated planning, history
docs/                current synthesized documentation
docs-site/           documentation presentation/build tooling
```

The former `engineering-system` coordination repository is historical provenance, not another current product.
