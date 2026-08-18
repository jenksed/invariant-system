---
title: Monorepo Migration
description: What changed when Invariant consolidated repositories and what deliberately did not change.
status: historical
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - docs/MONOREPO-MIGRATION.md
  - MIGRATION-REPORT.md
  - migration-source-manifest.json
audience:
  - developer
---

# Monorepo Migration

The monorepo migration consolidated product source and coordination material into one canonical Git root while preserving product ownership and imported Git history.

Semantic redistribution:

```text
project-arsenal → products/arsenal
loadout         → products/loadout
kiln            → products/kiln
temper          → products/temper
engineering-system contracts   → contracts/
engineering-system fixtures    → integration/
engineering-system decisions   → program/
engineering-system root history→ program/historical/engineering-system/
```

The migration repaired path assumptions and removed product submodules. It did **not** authorize renaming stable schema identities or rewriting frozen evidence to use new paths.

See root `MIGRATION-REPORT.md` for the migration's recorded verification evidence and `docs/MONOREPO-MIGRATION.md` for the detailed source mapping.
