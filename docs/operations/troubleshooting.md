---
title: Troubleshooting
description: Failure-first troubleshooting for the Invariant monorepo.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
  - integration/scenarios/repository-recon/run.sh
audience:
  - developer
  - operator
---

# Troubleshooting

Start by classifying the failure instead of broadening the fix.

## Tool missing

```bash
./invariant doctor
```

Use the owning product's setup instructions. Do not weaken a gate to accommodate a missing dependency.

## Boundary check fails

```bash
./invariant check boundaries
```

Common classes are nested Git roots/submodules, accidental Manifold runtime files, Temper sibling-source coupling, or duplicate canonical contracts. Fix the ownership violation rather than teaching the check to ignore it.

## Repository Recon fails

Run with preserved temp state:

```bash
KEEP_WORKDIR=1 ./integration/scenarios/repository-recon/run.sh
```

Inspect the printed workdir, Loadout Plan/Run records, Kiln output, and repository state. The real Kiln driver fails closed; a missing or malformed Kiln result should not be patched by falling back to simulation.

## A test is flaky

Record the observed failure and rerun evidence separately. The migration report preserves one transient Loadout fake-CLI spawn failure precisely because “passed on rerun” and “never failed” are different claims.
