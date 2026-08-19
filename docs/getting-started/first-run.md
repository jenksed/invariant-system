---
title: First Run
description: Exercise the current real Loadout → Kiln → Temper integration path.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - integration/scenarios/repository-recon/run.sh
  - invariant
audience:
  - developer
  - operator
---

# First Run

After prerequisites are available:

```bash
./invariant test integration
```

A successful run should end with:

```text
repository-recon golden path: PASS
```

The scenario creates its own temporary proof repository, runs Loadout against the real Kiln boundary, verifies the result is not simulated, and renders the Run through Temper.

Set `KEEP_WORKDIR=1` when you need to inspect the temporary repository and generated records after the scenario completes:

```bash
KEEP_WORKDIR=1 ./invariant test integration
```

This is a golden-path proof, not the complete historical Wave 3 matrix.
