---
title: Source of Truth Audit
description: Reconciliation of current Invariant repository truth, dated planning material, and historical provenance.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - README.md
  - AGENTS.md
  - invariant.boundaries.json
  - contracts/
  - integration/
  - products/
  - program/
audience:
  - developer
  - operator
---

# Source of Truth Audit

This audit establishes the documentation baseline for the `invariant-system` monorepo at commit `cae53750ab6aa8405396172f3af4fffa5bfdb6f4`.

The purpose is not to make every document agree. Invariant contains current code, current normative contracts, dated plans, frozen evidence, migration records, and future architecture. Those categories are intentionally different. Current documentation must preserve the difference.

## Verification order

When claims conflict, use this order:

1. current implementation and repository structure;
2. executable tests and integration runners;
3. current cross-product contracts and boundary policy;
4. recent Git history and migration evidence;
5. current product documentation;
6. dated program plans and roadmaps;
7. historical/frozen evidence;
8. speculative or frontier material.

Historical evidence is authoritative for what happened at the time. It is not automatically authoritative for what exists now.

## Baseline facts

| Claim | Classification | Evidence |
| --- | --- | --- |
| `invariant-system` is the canonical monorepo | `VERIFIED_CURRENT` | root tree, `README.md`, `AGENTS.md`, migration commits |
| Arsenal owns reusable intelligence, methods, evaluation, qualification, and learning | `VERIFIED_CURRENT` | `invariant.boundaries.json`, `products/arsenal/` |
| Bench lives inside Arsenal at `products/arsenal/evaluation` | `VERIFIED_CURRENT` | `invariant.boundaries.json`, `AGENTS.md`, evaluation tree |
| Loadout owns capabilities, goals, planning, and Work Envelope preparation | `VERIFIED_CURRENT` | `invariant.boundaries.json`, `products/loadout/src/core/plan.ts` |
| Loadout can use a real Kiln execution boundary | `VERIFIED_CURRENT` | `products/loadout/src/core/kiln-driver.ts`, integration runner |
| Kiln owns authority, execution, effects, artifacts, evidence, registered verification, and acceptance truth | `VERIFIED_CURRENT` | `invariant.boundaries.json`, Kiln implementation/tests |
| Temper is a read-only projection surface | `VERIFIED_CURRENT` | `invariant.boundaries.json`, `products/temper/README.md`, source coupling gate |
| Manifold owns selection/allocation semantics but has no runtime | `VERIFIED_CURRENT` | `products/manifold/README.md`, boundary check |
| Canonical cross-product contracts live in `contracts/` | `VERIFIED_CURRENT` | `contracts/README.md`, `./invariant check boundaries` implementation |
| Historical `engineering-system/*` schema identity strings must remain unchanged | `VERIFIED_CURRENT` | `contracts/README.md`, fixtures, boundary rules |
| Repository Recon runs Loadout → real Kiln → Temper from one checkout | `VERIFIED_CURRENT` | `integration/scenarios/repository-recon/run.sh`; post-migration CI record |
| The complete Wave 3 restart/negative/dogfood matrix is automated | `STALE` / false | runner explicitly automates the golden path only |
| `implement-change` / Development Loop v0 exists as a complete product workflow | `PLANNED` | root README identifies it as the next milestone |

## Major conflicts found

### Loadout README vs current implementation

`products/loadout/README.md` still describes the former multi-repository topology, says LOD-01 has no real Kiln enforcement, and frames the work as awaiting review on an old branch. That conflicts with:

- `products/loadout/src/core/kiln-driver.ts`, which implements a real fail-closed Kiln subprocess boundary;
- `integration/scenarios/repository-recon/run.sh`, which executes it;
- the monorepo migration record and current root README.

Classification: `STALE`. The README should be repaired as current product documentation.

### Wave 3 scenario README vs executable runner

`integration/scenarios/repository-recon/README.md` still contains pre-monorepo paths and describes a broader verifier procedure than `run.sh` currently implements.

Classification: mixed. The test matrix remains useful planning/acceptance material. Current automation is the golden path only.

### Program state files vs monorepo reality

`program/PROJECT-STATE.md` and `program/DEPENDENCIES.md` are dated August 12 and describe separate repositories, pinned legacy SHAs, and launch workstreams that predate the monorepo migration.

Classification: `HISTORICAL` / dated planning material. Preserve them. Do not use them as current system status without an explicit rebaseline.

### Kiln README mixes product truth and dated governance state

The Kiln README contains durable architectural rules alongside detailed historical authorization/PR chronology. The architecture remains useful; the chronology should be treated as provenance and linked from deeper status/history material rather than used as a concise current-system summary.

Classification: mixed `VERIFIED_CURRENT` + `HISTORICAL`.

## Current evidence boundaries

The repository contains strong evidence for the current repository-recon golden path. It does **not** justify claims that every planned negative case, restart case, provider path, child-run architecture, or Development Loop milestone is complete.

The post-migration report records all six workflows green on `main`, including 689/689 Kiln tests and the repository-recon integration workflow. This documentation project did not independently re-run those product suites before its first commit because the GitHub connector operates on repository state rather than a local checkout. Subsequent documentation validation must distinguish newly executed checks from inherited CI evidence.

## Frozen provenance policy

Do not rewrite:

- qualification receipts;
- evaluation records;
- authorization records;
- wave closeouts;
- historical PR/commit references;
- digest-bound fixtures;
- historical repository paths embedded in evidence.

If a historical path is confusing, explain it from current documentation. Do not alter the evidence to make history look current.

## Documentation rule

A page may describe a capability as current only when its source basis is current implementation, a current contract/boundary, or executable evidence. Plans and roadmaps must use explicit `planned` or `frontier` status and must not be phrased as existing behavior.
