---
title: Repository Recon for Contributors
description: Establish the actual repository state before planning or implementation.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - AGENTS.md
  - invariant
  - products/arsenal/agent_workflows/repository_truth_audit.md
audience:
  - developer
---

# Repository Recon for Contributors

Before planning or changing Invariant, establish the checkout rather than inheriting assumptions from an old session:

```bash
git status --short
git branch --show-current
git rev-parse HEAD
git log --oneline -15
./invariant status
./invariant doctor || true
./invariant check
./invariant check boundaries
```

Then inspect the owning product's README, `AGENTS.md`, current source, tests, contracts, and recent history.

Repository truth has priority over stale prose. Historical evidence still has authority over what happened historically; do not “fix” provenance simply because current paths differ.
