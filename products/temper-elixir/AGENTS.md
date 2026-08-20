# AGENTS.md — Temper Elixir experiment

This file applies under `products/temper-elixir/`. Root `AGENTS.md` still
governs. This directory is an M4 projection experiment, not an accepted
replacement for `products/temper`.

## Hard boundary

Temper may derive labels, attention, layout, navigation, freshness display,
and deterministic explanations. It may not create canonical Graph facts,
authority, effects, evidence, or completion. Do not add new sibling-source
coupling. The existing `{:kiln, path: "../kiln"}` dependency is a known blocker
to remove through an accepted contract/public interface, not a pattern to copy.

## Fast loop

```bash
mix deps.get
mix test
```

Canonical combined gate:

```bash
./invariant check boundaries
./invariant test graph
```

The boundary gate and formatter currently expose known candidate defects. Do
not weaken either gate to make the experiment look qualified. Snapshot changes
must be intentional, reviewed alongside the renderer change, and verified at
the recorded terminal dimensions.
