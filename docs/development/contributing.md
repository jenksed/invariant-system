---
title: Contributing
description: Minimum contribution discipline for the Invariant monorepo.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - AGENTS.md
  - products/
audience:
  - developer
---

# Contributing

Before changing code:

```bash
./invariant status
./invariant check
./invariant check boundaries
```

Read root `AGENTS.md` and the applicable product-local `AGENTS.md`. Keep commits bounded by ownership. Do not mix historical-record cleanup, runtime semantics, contract redesign, and unrelated refactors into one change.

Before declaring completion, run the gates that prove the intended property and report anything you could not execute.
