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

For a short iteration loop, use `./invariant test changed HEAD --list` to inspect
the conservative routing and `./invariant test changed <base>` to run it. Do not
describe that result as the full gate. Dependency setup is project-local via
`./invariant setup <target>`, and formatting is non-mutating unless
`./invariant format <target> --write` is explicit.
