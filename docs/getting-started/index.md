---
title: Getting Started
description: Establish repository truth, verify prerequisites, and run the current Invariant golden path.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
  - AGENTS.md
  - integration/scenarios/repository-recon/run.sh
audience:
  - developer
  - operator
---

# Getting Started

The fastest useful path is not “install everything and trust the README.” It is to establish the checkout's state, inspect prerequisites, run structural checks, then exercise the one current cross-product golden path.

```bash
./invariant status
./invariant doctor
./invariant check
./invariant check boundaries
./invariant test integration
```

Read next:

- [Prerequisites](prerequisites.md)
- [Setup](setup.md)
- [First run](first-run.md)
- [Repository recon](repository-recon.md)
