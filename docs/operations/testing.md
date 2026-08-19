---
title: Testing
description: Canonical root and product validation paths.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
  - .github/workflows/
audience:
  - developer
---

# Testing

Root gates:

```bash
./invariant test arsenal
./invariant test loadout
./invariant test kiln
./invariant test temper
./invariant test integration
./invariant test
```

The all-products gate is expensive by design: it runs the owning product's canonical validation rather than substituting shallow root smoke tests.

Cross-product contract or boundary changes should run every affected producer and consumer. A fixture validation pass is not evidence that a runtime consumer still behaves correctly unless the relevant consumer gate also runs.

## Integration

`./invariant test integration` currently exercises Repository Recon's golden path only. The existence of `TEST-MATRIX.md` does not imply all matrix cases are executed by the runner.
