# Loadout

Loadout is Invariant's human-facing capability and planning environment.

Users start with a Goal — understand a repository, verify a change, investigate a problem — and Loadout resolves supported Capabilities and configuration, produces a Plan, compiles the canonical Work Envelope, and runs against either a deterministic simulated boundary or the real Kiln supervision boundary.

Loadout prepares work. It does **not** grant runtime authority and does not become durable execution truth.

## Position in Invariant

```text
Arsenal / Bench   reusable methods + qualification evidence
        │
        ▼
Loadout           Goal → Capability → Plan → Work Envelope
        │
        ▼
Kiln              authority → execution/effects → evidence → Run Result
        │
        ▼
Temper            operator projection
```

Manifold is the documented future selection/allocation boundary and has no runtime today.

The canonical monorepo is `jenksed/invariant-system`; cross-product contracts live at `../../contracts/` and integration scenarios at `../../integration/`.

## Current capabilities

Loadout currently includes:

- CLI and minimal web UI;
- capability catalog/install/inspect/remove flows;
- `repository-recon` and `verify-change` work;
- Plan and Work Envelope compilation;
- deterministic simulated execution;
- a real fail-closed Kiln driver;
- Run records consumed by Temper.

## Repository Recon: real cross-product path

From the monorepo root:

```bash
./invariant test integration
```

The integration scenario at `../../integration/scenarios/repository-recon/run.sh` creates a real temporary Git repository, compiles a Loadout Plan for `execution=kiln`, sends the Work Envelope through the real Kiln supervisor, validates the canonical Run Result Envelope, rejects simulated labeling on that path, and renders the result through Temper.

The current automated runner covers the golden path. It does not prove the complete historical Wave 3 restart/negative/dogfood matrix.

## Direct CLI use

From `products/loadout` after `npm ci` / build as required:

```bash
npx loadout catalog
npx loadout install repository-recon --repository /path/to/repository
npx loadout inspect repository-recon --repository /path/to/repository
npx loadout plan --goal "Understand this repository" --repository /path/to/repository --execution kiln
```

Simulation remains available for deterministic product behavior where a real Kiln boundary is not the property under test.

## Real Kiln boundary

`src/core/kiln-driver.ts`:

- spawns an exact argv without a shell;
- writes the Work Envelope to a temporary file;
- validates `engineering-system/run-result-envelope/v0`;
- fails closed when Kiln is unavailable, returns malformed output, exits unsuccessfully, or labels a supposedly real result as simulated;
- only allows the Repository Recon procedure to run when Kiln's authority result grants the requested capability.

That boundary is stronger evidence than the historical LOD-01 README text that described a simulated-only slice.

## Verification

Canonical product gate:

```bash
npm run ci
```

From the monorepo root:

```bash
./invariant test loadout
```

## Ownership boundary

Loadout owns capabilities, goals, planning, and Work Envelope preparation.

It must not:

- grant Kiln runtime authority;
- become the canonical execution/effect ledger;
- fabricate Kiln evidence;
- absorb Manifold selection semantics merely because selection becomes convenient.

See `../../docs/products/loadout/index.md` and `../../docs/architecture/product-boundaries.md` for the system-level view.

## Two-track qualification note

Loadout is materially the same planning owner in candidates A0 and B0. Its
canonical gate passed 140 tests on both candidates, and the real
Loadout→Kiln→Temper integration scenario passed without simulation. That
evidence proves the bounded handoff path; it does not qualify either complete
candidate or grant Loadout runtime authority. Graph facts in B0 remain
downstream execution/projection concerns and do not alter this product's
contract.
