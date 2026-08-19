---
title: Provenance and History
description: How the monorepo preserves historical repository identity without confusing it with current topology.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - docs/MONOREPO-MIGRATION.md
  - MIGRATION-REPORT.md
  - migration-source-manifest.json
  - program/historical/
audience:
  - developer
---

# Provenance and History

Invariant was consolidated from separate Arsenal, Loadout, Kiln, Temper, and coordination histories. The migration preserved source history and redistributed coordination material by semantic ownership.

Current topology:

```text
products/arsenal
products/loadout
products/kiln
products/temper
products/manifold   # boundary docs only
contracts/
integration/
program/
```

Historical records may still say `project-arsenal`, `engineering-system`, or other former repository paths. That is expected.

Current documentation should translate those records for the reader. It must not rewrite frozen evidence so the past appears to have happened inside today's tree.
