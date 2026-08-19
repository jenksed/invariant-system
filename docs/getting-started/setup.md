---
title: Setup
description: Prepare a checkout without bypassing product-local toolchain rules.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - AGENTS.md
  - invariant
audience:
  - developer
---

# Setup

From the monorepo root:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
./invariant status
./invariant doctor
```

Do not install missing tools globally merely because a gate reports them. Product-local setup remains authoritative.

For Node products, the root test command installs pinned dependencies with `npm ci` when `node_modules` is absent. Kiln resolves Mix dependencies when needed. Arsenal uses repository Python scripts rather than a separate root package manager.

Before changing cross-product code or contracts, read root `AGENTS.md` plus the applicable product-local `AGENTS.md`.
