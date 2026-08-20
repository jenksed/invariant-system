---
title: Command Reference
description: Root commands and their current owning behavior.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
  - scripts/two-track
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
| `./invariant test temper-elixir` | Elixir Temper format/compile/test gate when present |
| `./invariant test manifold` | Manifold selection-only tests |
| `./invariant test contracts` | M0 positive/mandatory-negative conformance |
| `./invariant test integration` | Repository Recon real golden path |
| `./invariant test runtime` | daemon kill/restart and public Temper RPC scenarios |
| `./invariant test graph` | focused Kiln Graph + Temper-Elixir gate |
| `./invariant test tooling` | root/helper syntax, ShellCheck when available, candidate identity/topology, and launcher smoke |
| `./invariant test changed [BASE] [--list]` | conservative changed-file routing for fast feedback; never promotion evidence |
| `./invariant test` | all current product/integration gates |
| `./invariant setup [TARGET]` | install only project-local npm/Mix/docs dependencies |
| `./invariant format TARGET [--write]` | check canonical formatting by default; modify only with explicit `--write` |
| `./invariant run REPOSITORY` | start bounded Kiln + Temper against a repository |
| `./invariant track list` | exact A0/B0 identities, verdicts, and roles |
| `./invariant track doctor [LAB_ROOT]` | candidate objects, ancestry, required surfaces, and optional Lab interface |
| `./invariant track create TRACK DEST` | clean detached worktree at an exact candidate SHA |
| `./invariant track inspect TRACK SOURCE` | verify exact SHA and clean source |
| `./invariant track test TRACK SOURCE [PROFILE]` | run evidence-logging candidate gates with provider credential removed |
| `./invariant track use TRACK SOURCE TARGET` | run a candidate against a practice repository |
| `./invariant track lab TRACK SOURCE LAB_ROOT` | snapshot/install a candidate using Lab's supported switch command |

The track helper never fetches, moves refs, removes worktrees, invokes a live
provider, or performs a destructive Lab action. Profiles are `smoke`, `full`,
`runtime`, `graph` (dev only), and `qualification`. Use `--output DIR` to choose
a durable evidence location; otherwise the helper prints its new temporary
evidence directory.
