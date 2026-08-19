---
title: Invariant Roadmap
description: Capability-oriented roadmap connecting the demonstrated foundation to Temper Workbench, distributed operation, engineering intelligence, dogfood, and strategic programs.
status: planned
verified_at_commit: 325b1b5fe2e65c35bde9a1cd75e099a540b283aa
source_paths:
  - README.md
  - invariant.boundaries.json
  - docs/status.md
  - docs/_meta/post-wp09-product-direction.md
  - products/arsenal/docs/roadmap/capability-system.md
  - products/kiln/docs/ROADMAP.md
  - products/manifold/README.md
audience:
  - developer
  - operator
---

# Invariant Roadmap

This roadmap reconciles product direction; it does not prove implementation and does not authorize product work by itself. [Current system status](../status.md) remains the evidence-backed baseline until newer branch/worktree evidence is promoted and reconciled.

The near-term direction is capability-oriented so internal work-package numbers do not become the product model.

## Gate 0 — close the current durable foundation

The post-WP-09 sequence begins only after WP-09 is accepted against its own contract and evidence. The documentation branch does not currently contain the active WP-08/WP-09 implementation state, so it does not upgrade those capabilities from local milestone reports.

When WP-09 is accepted/promoted, reconcile this roadmap, [status](../status.md), Kiln recovery/session docs, and the [traceability](../reference/traceability.md) record before dependent Workbench work treats the capability as available.

## Operator product — Temper Workbench Alpha

Primary acceptance direction:

> From a repository directory, an operator can start Temper with one obvious command, enter a persistent project-centric workbench, see the current governed Session and repository state, inspect live activity/changes/evidence, take required human actions, recover after disconnect, and hand source editing to Zed without transferring execution authority out of Kiln.

Target sequence:

| Capability | Owner(s) | Acceptance property | Dependency | Current documentation status |
| --- | --- | --- | --- | --- |
| `temper .` entry + project discovery | Temper | current directory resolves to an explicit project/repository identity or a truthful error | project identity contract | planned |
| Project-centric Workbench | Temper | one surface projects current Session/repository/activity/evidence without inventing state | canonical Kiln query surface | planned |
| Explicit `ATTENTION` | Kiln truth + Temper projection | required human action is durable/queryable and visibly distinguished from passive status | durable Session/action state | planned |
| Governed human actions | Temper → Kiln | operator can approve/revise/decide through Kiln; Temper cannot self-authorize | authority/action API | planned |
| Activity / changes / verification / review traversal | Kiln evidence + Temper | every view traces to canonical state/evidence and represents missing/stale facts honestly | evidence/query contracts | planned |
| Zed handoff | Temper adapter | editor receives path/context while execution authority remains in Kiln | project identity + editor adapter | planned |
| UI-loss recovery | Kiln + Temper | a new Temper process reconstructs actionable Session state from Kiln | accepted durable Session recovery | planned |

## Distributed operation

Remote operation is now a near-term product target rather than a generic frontier idea, but it remains evidence-gated.

| Capability | Acceptance property |
| --- | --- |
| Temper → remote Kiln topology | operator and execution hosts can differ without changing authority ownership |
| Topology identity | project/repo/Session/Kiln/host identities are explicit rather than inferred from path or `localhost` |
| Disconnect/reconnect | canonical Session continues independently of Temper connectivity; reconnect reconstructs state |
| Freshness/staleness | stale projections are detectable and represented rather than silently treated as current |
| Remote human authority | governed actions traverse Kiln and remain attributable/state-bound across the transport |

The stretch target is to exercise Workbench Alpha against Kiln running on another Mac with the same authority/recovery properties as local operation.

## Engineering intelligence

Loadout, Manifold, Bench, and Arsenal should improve planning, selection, qualification, experimentation, and method promotion without becoming alternative execution authorities.

Near-term work should favor evidence that reduces friction for the operator product:

- Loadout produces bounded work/requirements without granting execution authority;
- Manifold selection consumes qualified options only when a real selection problem exists;
- Bench qualification is scoped/current and cannot grant runtime authority;
- Arsenal experiments may accelerate product decisions, but research findings require explicit promotion before runtime adoption.

## Dogfood / system proof

A decisive system proof is Invariant operating on Invariant through its public boundaries while the operator can see the same contracts/evidence/decisions used to judge completion.

Dogfood should demonstrate the governed property, not merely run an agent inside the repository.

## Strategic programs

The [T3 Challenge / 30-day competitive program](strategic-programs.md) is a protected strategic overlay. It may consume or accelerate Workbench, remote-operation, Arsenal, provider/model, and other product work. It does not replace the durable Invariant roadmap and its historical program records should not be rewritten to match newer product sequencing.

## Parallel-safe versus dependency-sensitive work

Generally parallel-safe after inputs are frozen:

- read-only reconnaissance;
- documentation and traceability updates;
- independent falsification against immutable candidate state;
- tests for already-defined contracts;
- Temper projection work against frozen canonical fields;
- Arsenal experiments that do not mutate runtime contracts.

Dependency-sensitive:

- UI/actions before Kiln action/state semantics are accepted;
- remote transport before identity/freshness/authority semantics are frozen;
- producer/consumer implementation before a changed shared contract is resolved;
- reviewer/runtime wiring before independence and evidence ownership are explicit;
- promotion of Arsenal findings before qualification/promotion evidence is accepted.

See the [engineering process](../development/engineering-process.md) for the gate model.

## Product roadmaps

- [Arsenal](arsenal.md)
- [Loadout](loadout.md)
- [Kiln](kiln.md)
- [Temper](temper.md)
- [Manifold](manifold.md)
- [System](system.md)
- [Strategic programs](strategic-programs.md)
