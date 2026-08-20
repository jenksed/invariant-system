---
title: Integration Ledger
description: Candidate SHA, acceptance state, evidence state, and integration disposition for accepted work items.
status: current
verified_at_commit: 1dcb5466debe6d443d6a0fb648ae8eea73d2b128
source_paths:
  - docs/development/branch-policy.md
  - docs/development/engineering-process.md
  - docs/status.md
audience:
  - developer
  - operator
---

# Integration Ledger

This ledger tracks the state of accepted candidates across the integration pipeline. It distinguishes `HUMAN_ACCEPTED` from `REPOSITORY_EVIDENCE` from `MERGED_TO_DEV` from `RELEASED_TO_MAIN`. See [branch policy](branch-policy.md) for the promotion rules.

## Branch state (this verified commit)

| Branch class | Ref | SHA | Purpose |
| --- | --- | --- | --- |
| `main` | `main` | `1dcb5466debe6d443d6a0fb648ae8eea73d2b128` | Deliberate release baseline |
| `dev` | `dev` | `1dcb5466debe6d443d6a0fb648ae8eea73d2b128` | Persistent qualified integration line |
| `integration/dev-reconciliation` | `integration/dev-reconciliation` | `1dcb5466debe6d443d6a0fb648ae8eea73d2b128` | Reserved reconciliation work branch |

`dev` was created from exactly `1dcb546` in this session. It currently has zero commits ahead of `main`.

## Candidates

### WP-09 — Temper client/server RPC + activity stream

| Field | Value |
| --- | --- |
| Candidate SHA | `755696052cd3b122de906ab9690dfaf6811efeb6` |
| `HUMAN_ACCEPTED` | yes (WP-09 closeout) |
| `REPOSITORY_EVIDENCE` | yes (gates 25/25, 90/90, 1031/1031, 33/33; LANES 1-6 PASS/APPROVE) |
| `MERGED_TO_DEV` | yes (already in `main` at `1dcb546`) |
| `RELEASED_TO_MAIN` | yes (incorporated via WP-09 merge `0d6d41d`) |
| Evidence record | `docs/roadmap/t3-competitive-30-day/work-packages/wp-09-closeout.md` |

### M4-Q1C — graph projection + operator truth contract

| Field | Value |
| --- | --- |
| Candidate SHA | `11ba660037f33c87f8bbbf671b4b94873d7e6b3f` |
| Branch | `experiment/m4-a-graph-projection` |
| `HUMAN_ACCEPTED` | yes (historical acceptance decision reported by human) |
| `REPOSITORY_EVIDENCE` | RECONCILIATION_REQUIRED (test files exist at candidate SHA; historical run logs do not survive in repo) |
| `MERGED_TO_DEV` | not yet performed |
| `RELEASED_TO_MAIN` | no |
| Evidence record | This document (below) |

### Other active candidates

The following branches each carry one or more commits unique to themselves but are not yet promoted. They are listed for traceability, not for action:

- `m11-closeout-final` (392f790) — M11 closeout packet, +1 unique commit
- `m12-b-recovery` (66a3bc0) — recovery tests, +1 unique commit
- `m12-c-artifact` (c07f6e6) — artifact canonicalization, +1 unique commit
- `m12-d-temper` (b3c796e) — Temper operator surface, +1 unique commit (likely WP-09 superseded)
- `m12-e-provider-qual` (7d3f67e) — provider qualification properties, +1 unique commit
- `research/arsenal-program-foundation` (e2568cf) — Arsenal research program, 6 unique commits, 146 behind main
- `process/risk-scaled-verification` (4b570b5) — process doc, +1 unique commit
- `roadmap/t3-competitive-pathfinder` (421b7d9) — Pathfinder docs, +1 unique commit, 81 behind main

## M4-Q1C evidence reconciliation

`HUMAN_ACCEPTED` is preserved; `REPOSITORY_EVIDENCE` requires reconciliation. The human reported the following historical PASS counts against candidate `11ba660`:

| Claim | Historical value | Repository artifact at 11ba660 | Classification |
| --- | --- | --- | --- |
| `M3_R1_FOCUSED` | 4/4 PASS | `products/kiln/test/kiln/m3_dogfood_lifecycle_test.exs` (4 tests) | REPOSITORY_ARTIFACT_FOUND |
| `M3_DOGFOOD` | 4/4 PASS | Same module as `M3_R1_FOCUSED` (4 tests) | REPOSITORY_ARTIFACT_FOUND |
| `M3_DOGFOOD_PROBE` | PASS | `products/kiln/scripts/m3_dogfood_probe.sh` orchestrates 4 cases | COMMAND_RECONSTRUCTABLE |
| `M4_KILN_TRUTH_PROJECTION` | 47/47 PASS | `m3_dogfood_lifecycle` (4) + `m3_r2_governed_apply` (1) + `m3_r2_real_provider_lifecycle` (1) + `m3_r2_verification_failure` (1) + `freshness` (6) + `why_packet` (5) + `m4_a_graph_projection` (13) + `m4_p0_truth_contract` (18) = 49 tests; aggregate 47/47 not bit-exact | COMMAND_RECONSTRUCTABLE |
| `M4_TEMPER_RUNTIME_OPERATOR` | 39/39 PASS | `products/temper-elixir/test/cell_frame` (13) + `m4_live_projection` (9) + `m4_navigation` (15) + `m4_snapshot` (5) + `m4_why_dispatcher` (6) + `m4_why_result` (9) = 57 tests; subset 39 not identified | COMMAND_RECONSTRUCTABLE |

Historical run logs do not survive in the repository. Aggregate counts cannot be verified to be exactly `47/47` or `39/39` without fresh execution.

**Disposition:**

- Acceptance decision is preserved as `HUMAN_ACCEPTED`.
- A fresh qualification run is required before promotion. The plan is in [qualification index](../qualification/README.md).
- Aggregate counts from the historical acceptance are NOT accepted as PASS-by-inspection.

## Provenance

This ledger was created by Session B (reconciliation) and is committed on `integration/dev-reconciliation`. Promotion to `dev` requires the qualification in the [qualification index](../qualification/README.md) plus an explicit human decision against the candidate SHA.