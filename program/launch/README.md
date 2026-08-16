# First-Wave Launch Package

This directory is the copyable, MiniMax-first launch surface for ARS-01, LOD-01, and KIL-01.

## Use

1. Keep the four repositories as separate Git repositories in one multi-root project space. Do not create a monorepo or combine histories.
2. Give the orchestrator [SIMULTANEOUS-LAUNCH-PROMPT.md](SIMULTANEOUS-LAUNCH-PROMPT.md).
3. Supply the exact owner authorization token only when the three writers should actually start.
4. The orchestrator performs read-only preflight first and aborts on any drift.
5. The orchestrator gives each writer only its product prompt and a read-only engineering-system checkout.

## Files

- [LAUNCH-MANIFEST.yaml](LAUNCH-MANIFEST.yaml): machine-readable pinned state.
- [ARSENAL-PROMPT.md](ARSENAL-PROMPT.md): ARS-01 writer instructions.
- [LOADOUT-PROMPT.md](LOADOUT-PROMPT.md): LOD-01 writer instructions.
- [KILN-PROMPT.md](KILN-PROMPT.md): KIL-01 writer instructions.

The package authorizes branches and bounded work, not merges. Each writer stops at a tested checkpoint and opens or prepares a reviewable PR.
