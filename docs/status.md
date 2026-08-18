---
title: Current System Status
description: Evidence-backed maturity matrix for the Invariant system.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant.boundaries.json
  - MIGRATION-REPORT.md
  - integration/scenarios/repository-recon/run.sh
  - products/arsenal/evaluation/README.md
  - products/loadout/src/core/kiln-driver.ts
  - products/kiln/
  - products/temper/
  - products/manifold/README.md
audience:
  - developer
  - operator
---

# Current System Status

This page is intentionally harder to impress than a roadmap.

| Area | Status | Works today | Partial / bounded | Not yet |
| --- | --- | --- | --- | --- |
| Invariant root | **current** | one Git root; root status/doctor/check/test delegation; machine-readable boundary policy | docs foundation is new | no claim of full product loop |
| Arsenal | **current / experimental** | asset registry, capability contracts, compiler/distribution path, governance and qualification tooling | capability system continues to evolve | not an execution authority |
| Bench | **experimental** | case-health/evidence machinery; 19-case v0 corpus; deterministic active cases | many agent/model arms intentionally designed-not-run | broad model-efficacy claims |
| Loadout | **current / partial** | CLI/web; Goal/Capability/Plan/Work Envelope; simulation; real fail-closed Kiln driver | current real path is narrow | cannot grant runtime authority |
| Kiln | **current / partial** | durable Run foundation; authority evaluation; supervision; artifacts/evidence; registered verification; result projection; recovery foundations | broader planned runtime slices | automatic completion from model confidence or exit zero |
| Temper | **current / partial** | read-only workbench over real Plan + Run Result; truthful missing-state rendering | operator interaction remains projection-oriented | mutation or canonical authority |
| Manifold | **planned** | documented input/output/non-authority boundary | selection semantics are defined | runtime implementation |
| Cross-product integration | **partial** | Repository Recon golden path: Loadout → real Kiln → Temper | full restart/negative/dogfood matrix is specified | complete Development Loop v0 |
| Documentation system | **partial** | canonical Markdown, source audit, current-state model, architecture/product corpus | site/build validation being established | public deployment/search service decision |

## Strongest current proof

`integration/scenarios/repository-recon/run.sh` is the clearest whole-system executable currently in the monorepo. It:

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
- Temper does not become authoritative by displaying a fact.
- Manifold's documented boundary does not imply a runtime exists.
- A roadmap milestone does not authorize implementation.

## When this page is stale

Treat this page as suspect when `main` has moved materially beyond `verified_at_commit`. Re-check implementation, tests, contracts, and recent history before strengthening any status.
