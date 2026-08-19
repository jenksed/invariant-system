---
title: Product Boundaries
description: What each Invariant product owns and what it is forbidden to absorb.
status: current
verified_at_commit: fed26fcc8b7598a56ce86e47c99d0154e6b46436
source_paths:
  - invariant.boundaries.json
  - AGENTS.md
audience:
  - developer
---

# Product Boundaries

The authoritative summary is machine-readable in `invariant.boundaries.json`. This table intentionally mirrors that current ownership model rather than promoting roadmap behavior into present ownership.

| Area | Owns | Must not become |
| --- | --- | --- |
| Arsenal | intelligence, methods, evaluation, qualification, learning | execution authority; mutation authority |
| Bench | evaluation, qualification evidence | runtime selection authority |
| Loadout | capabilities, goals, planning, Work Envelope preparation | durable execution truth; authority grantor |
| Manifold | intelligence selection, allocation | executor; mutator; qualifier; authority grantor; generic workflow engine |
| Kiln | authority, execution, effects, artifacts, evidence, registered verification, acceptance truth | R&D intelligence owner; model qualification system |
| Temper | operator experience, projection | canonical authority; execution truth; mutation authority |

## Planned control surface is not current ownership

The Workbench roadmap plans for Temper buttons, commands, TUI actions, or remote requests to initiate governed operations. That is **planned control-surface behavior**, not an additional current ownership claim.

When implemented, a Temper action must cross the owning boundary. Kiln validates authority/state and records resulting canonical truth. If implementation requires changing the canonical ownership model, freeze that architecture decision explicitly before dependent work proceeds; do not edit `invariant.boundaries.json` merely to make roadmap prose appear consistent.

The same distinction applies to editor integration: handing source editing/context to Zed or another editor does not transfer Kiln execution authority.

## Why the negative boundaries matter

Without `may_not` rules, a product boundary tends to expand toward convenience. A planner starts applying changes. A UI starts making canonical decisions. A qualification harness starts selecting live workers. The architecture then becomes whatever the last feature needed.

Invariant encodes the negative space because those shortcuts are exactly what would erase the system's reason for existing.

## Enforcement

`./invariant check boundaries` currently enforces structural properties including:

- one Git root;
- no submodules;
- documentation-only Manifold;
- no Temper source coupling to sibling product trees;
- one canonical copy of each cross-product contract.

It does not prove every semantic ownership rule automatically. Review still matters.
