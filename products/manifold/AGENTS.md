# AGENTS.md — Manifold

This file applies under `products/manifold/`. Root `AGENTS.md` still governs.

Manifold is selection-only. The only permitted runtime files are
`src/selector.py` and `tests/test_selector.py`; every other file here must be
Markdown. The selector stays Python-stdlib-only and must not import process,
network, environment, sibling-product, mutation, authority, qualification, or
orchestration surfaces.

Fast and canonical loops:

```bash
python3 tests/test_selector.py
./invariant test manifold
./invariant check boundaries
```

Add a runtime concept only when it is necessary to choose among already
qualified intelligence configurations. New evidence belongs to Arsenal/Bench;
execution and authorization remain Kiln responsibilities.
