# Temper Elixir M4 projection experiment

This directory is an M4-specific parallel renderer and projection research
surface. It contains CellFrame experiments, Graph work-map/proof/inspector
views, live projection and navigation, deterministic Why dispatch/results,
and committed terminal snapshots. It is not proven to replace the TypeScript
Temper workbench in `products/temper`.

## Ownership

Temper Elixir may derive operator labels, attention, navigation, layout, and
explanations from canonical inputs. It must not create execution truth, grant
authority, infer absent canonical relationships, or feed presentation
freshness back into Kiln authority.

Canonical Graph nodes and ref-backed edges originate in Kiln's accepted
envelopes. `PRODUCED` is a caller-consistency-derived edge rather than a stable
canonical ref. Attention states, header priority, layout, and freshness display
are projections. Why results are deterministic renderings of structured
`WhyPacket/v0`; they are not model-authored execution facts.

## Run and test

```bash
mix deps.get
mix test
```

At candidate B0 (`5e7b013`), 68 tests passed under Elixir 1.20.2 / OTP 29.
That isolated result is useful but not promotion evidence for the whole
candidate; the repository pins OTP 28.

The reconciliation successor exposes the intended combined gate as:

```bash
./invariant test graph
```

That command currently passes the focused Kiln Graph group (50/50) and then
fails the Temper-Elixir formatting gate. The failure is intentional evidence:
this experimental tree is not yet formatted/compiled/tested as a registered
product by a green canonical command.

## Blocking limitation

`mix.exs` currently declares `{:kiln, path: "../kiln"}`. That is a direct
cross-product source dependency forbidden by the monorepo architecture. The
root runner and boundary check now expose the defect instead of overlooking
the product. Invariant Lab starts the TypeScript Temper service, not this renderer. Before promotion,
the owner must decide whether this is a retained experiment, the future Temper
implementation, or a component behind a contract/API boundary; then register
and qualify the selected surface in root checks and Lab.
