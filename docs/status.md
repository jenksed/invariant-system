---
title: Current System Status
description: Evidence-backed maturity matrix for the Invariant system.
status: current
verified_at_commit: 755696052cd3b122de906ab9690dfaf6811efeb6
source_paths:
  - invariant.boundaries.json
  - MIGRATION-REPORT.md
  - integration/scenarios/repository-recon/run.sh
  - products/arsenal/evaluation/README.md
  - products/loadout/src/core/kiln-driver.ts
  - products/kiln/
  - products/temper/
  - products/manifold/README.md
  - docs/reference/traceability.md
audience:
  - developer
  - operator
---

# Current System Status

This page is intentionally harder to impress than a roadmap.

The table below remains bound to `verified_at_commit`. Active local/worktree engineering may be newer. Reported milestone completion does not advance this table until the implementation, tests/evidence, accepted candidate state, and relevant decision are inspectable from the documented repository context.

## Two-track qualification notice

The pre-Graph `main` lineage is rooted at candidate A0
(`0c6ed3ad39c6a9a8808a37c8728c56f3dcd254af`) and Graph-enabled `dev`
is rooted at B0 (`5e7b0134d5e901603904ca5b1f4f3f16d4a472ec`). Both historical
runtime candidates are **NOT QUALIFIED**. Publishing documentation and
developer tooling on those branch lines does not advance this canonical status
matrix or turn branch identity into acceptance evidence. A0 fails the
canonical Kiln gate; B0 also fails shared Kiln tests and its Elixir Temper
experiment crosses the Kiln source boundary. See [the two-track qualification record](qualification/two-track-qualification.md)
for exact evidence and [the candidate inventory](reference/current-system-inventory.md)
for the material capability delta.

| Area | Status | Works today | Partial / bounded | Not yet |
| --- | --- | --- | --- | --- |
| Invariant root | **current** | one Git root; root status/doctor/check/test delegation; machine-readable boundary policy | docs foundation/process traceability is new | no claim of full product loop on this verified state |
| Arsenal | **current / experimental** | asset registry, capability contracts, compiler/distribution path, governance and qualification tooling | capability system continues to evolve | not an execution authority |
| Bench | **experimental** | case-health/evidence machinery; 19-case v0 corpus; deterministic active cases | many agent/model arms intentionally designed-not-run | broad model-efficacy claims |
| Loadout | **current / partial** | CLI/web; Goal/Capability/Plan/Work Envelope; simulation; real fail-closed Kiln driver | current real path is narrow | cannot grant runtime authority |
| Kiln | **current / partial** | durable Run foundation; authority evaluation; supervision; artifacts/evidence; registered verification; result projection; recovery foundations | broader planned runtime slices | automatic completion from model confidence or exit zero |
| Temper | **current / partial** | read-only workbench over real Plan + Run Result; truthful missing-state rendering | operator interaction remains projection-oriented on this verified state | mutation/execution authority |
| Manifold | **planned** | documented input/output/non-authority boundary | selection semantics are defined | runtime implementation |
| Cross-product integration | **partial** | Repository Recon golden path: Loadout → real Kiln → Temper | full restart/negative/dogfood matrix is specified | complete newer engineering loop is not claimed from this verified state |
| Documentation system | **current / partial** | canonical Markdown, source audit, status model, engineering process, traceability model, architecture/product corpus | implementation evidence still must be reconciled as branches advance | docs are not runtime/evidence authority |

## Strongest proof on this verified repository state

`integration/scenarios/repository-recon/run.sh` is the clearest whole-system executable captured by this page. It:

1. builds Loadout and Temper when needed;
2. compiles Kiln when needed;
3. creates a real temporary Git repository from the proof fixture;
4. installs Repository Recon through Loadout;
5. compiles a Plan targeting `execution_boundary = kiln`;
6. invokes the real Kiln supervisor;
7. asserts the canonical Run Result schema and rejects a simulated label;
8. renders the result through Temper.

The migration report records that integration workflow green on published `main`. The current runner itself says the broader matrix remains the responsibility of a dedicated verifier.

## Important non-claims

- Bench's deterministic evidence does not prove a model is universally “better.”
- A Qualified Method Record does not grant Kiln execution authority.
- A Loadout Plan does not grant Kiln execution authority.
- A successful verification command does not by itself prove every acceptance criterion.
- Temper does not become authoritative by displaying or initiating an action.
- Manifold's documented boundary does not imply a runtime exists.
- A roadmap milestone does not authorize implementation.
- An active-worktree completion report does not update this page without repository-visible evidence reconciliation.

## Moving a status forward

Use [Engineering traceability](reference/traceability.md) to connect the acceptance property to exact state, contracts, verification, independent review, and human decision. Then update this page and the affected product/roadmap pages together.

## When this page is stale

Treat this page as suspect when the repository state in front of you has moved materially beyond `verified_at_commit`. Re-check implementation, tests, contracts, accepted evidence, and recent history before strengthening any status.

## Accepted work packages on this verified state

- **WP-09** — Temper client/server RPC + activity stream. Status: ACCEPTED at candidate `755696052cd3b122de906ab9690dfaf6811efeb6`. Owner gates green (25/25, 90/90, 1031/1031, 33/33); Lane 5 PASS; Lane 6 APPROVE; Owner HumanDecision ACCEPT. Live reconnect evidence crosses the real Cowboy 2.18 WebSocket boundary (Repair-14 regression test confirms). See [WP-09 closeout](roadmap/t3-competitive-30-day/work-packages/wp-09-closeout.md) for evidence identities, defect history, and post-acceptance followups.
