# AGENTS.md — Temper

This file applies under `products/temper/`. Root `AGENTS.md` still governs.

## Ownership

Temper owns truthful operator projection and governed request initiation. It
does not own canonical execution state, authority, effects, evidence, or
completion. Missing canonical facts render as unknown/unavailable; never infer
them into existence.

## Fast loop

```bash
npm ci
npm run typecheck
npm test
```

Canonical gate from the monorepo root:

```bash
./invariant test temper
```

For a live practice repository, prefer `./invariant run /path/to/repository`
from the root. Preserve the HTTP/WebSocket and scoped-token boundary; do not
replace it with a sibling-product import for convenience.

## Change discipline

- Keep projection functions deterministic and explicit about unknown state.
- Update source-mapping tests when a visible fact or label changes.
- Exercise narrow terminal widths for layout changes.
- Run the public RPC/restart profile for live-client changes:
  `./invariant test runtime`.
- A TypeScript Temper change does not promote or supersede Temper Elixir.
