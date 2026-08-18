---
title: Command Reference
description: Root commands and their current owning behavior.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
audience:
  - developer
---

# Command Reference

| Command | Purpose |
| --- | --- |
| `./invariant status` | checkout, product, and runtime overview |
| `./invariant doctor` | prerequisite diagnostics; installs nothing |
| `./invariant check` | root structure / single-Git-root checks |
| `./invariant check boundaries` | deterministic architecture-boundary subset |
| `./invariant test arsenal` | Arsenal canonical Python gates |
| `./invariant test loadout` | Loadout `npm run ci` |
| `./invariant test kiln` | Kiln validators + format/compile/xref/test |
| `./invariant test temper` | Temper `npm run ci` |
| `./invariant test integration` | Repository Recon real golden path |
| `./invariant test` | all current product/integration gates |
