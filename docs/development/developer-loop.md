---
title: Developer Loop
description: Fast local feedback that preserves Invariant's canonical qualification boundaries.
status: partial
verified_at_commit: 5e7b0134d5e901603904ca5b1f4f3f16d4a472ec
source_paths:
  - invariant
  - scripts/two-track
  - AGENTS.md
audience:
  - developer
---

# Developer Loop

The repository supports a short feedback loop without redefining “done.” Fast
commands help while a change is moving; canonical product and integration gates
still prove completion.

## First checkout

Inspect before installing anything:

```bash
./invariant status
./invariant doctor
```

Install project-local dependencies only where needed:

```bash
./invariant setup loadout
./invariant setup kiln
./invariant setup temper
./invariant setup docs
# or all known local dependency sets:
./invariant setup
```

Setup never installs a global toolchain. `doctor` remains the source of truth
for missing host prerequisites and Kiln's pinned-versus-detected runtime.

## During a change

Ask what the conservative router would run:

```bash
./invariant test changed HEAD --list
```

Run those feedback gates against a meaningful base:

```bash
./invariant test changed origin/main
```

The router includes working-tree, staged, untracked, and committed changes. It
always runs structure and boundary checks, routes product-local files to their
owner, routes Graph facts/views to the combined Graph gate, treats integration
and contract changes conservatively, and runs documentation/tooling checks for
their own surfaces. It continues after one selected gate fails so a developer
gets a useful failure set in one pass.

This command is deliberately labeled fast feedback. It is not a substitute for
`./invariant test`, required cross-product consumer gates, Lab evidence, review,
or acceptance.

Formatting is check-only by default:

```bash
./invariant format loadout
./invariant format kiln
./invariant format temper-elixir
```

Mutation requires an explicit option:

```bash
./invariant format loadout --write
```

Products without an established formatter are not silently rewritten.

## Run the application

```bash
./invariant run /path/to/practice-repository
```

This delegates to the existing bounded launcher: local Kiln daemon, generated
scoped tokens, explicit SQLite state, public HTTP/WebSocket boundary, and the
TypeScript Temper workbench. For A0/B0 comparison or Lab installation, use the
`./invariant track` workflow documented in the root README.

## Before handoff

Run the property-owning canonical gates. Typical escalation is:

```bash
./invariant test tooling
./invariant test <affected-product>
./invariant test integration    # when a public cross-product path changed
./invariant test runtime        # when daemon/session/live-client behavior changed
./invariant test graph          # when Graph truth or projection changed
./invariant test                # canonical full repository gate
```

Record exact commands, exit codes, environment limitations, and the final tree
state. A fast loop preserves velocity; it never promotes a proxy into evidence
for a stronger property.
