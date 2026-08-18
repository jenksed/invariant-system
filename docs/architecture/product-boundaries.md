---
title: Product Boundaries
description: What each Invariant product owns and what it is forbidden to absorb.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant.boundaries.json
  - AGENTS.md
audience:
  - developer
---

# Product Boundaries

The authoritative summary is machine-readable in `invariant.boundaries.json`.

| Area | Owns | Must not become |
| --- | --- | --- |
| Arsenal | intelligence, methods, evaluation, qualification, learning | execution authority; mutation authority |
| Bench | evaluation, qualification evidence | runtime selection authority |
| Loadout | capabilities, goals, planning, Work Envelope preparation | durable execution truth; authority grantor |
| Manifold | intelligence selection, allocation | executor; mutator; qualifier; authority grantor; generic workflow engine |
| Kiln | authority, execution, effects, artifacts, evidence, registered verification, acceptance truth | R&D intelligence owner; model qualification system |
| Temper | operator experience, projection | canonical authority; execution truth; mutation surface |

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
