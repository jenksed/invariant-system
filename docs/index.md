---
title: Invariant Documentation
description: System documentation for Invariant — architecture, products, governed engineering process, operations, evidence, and roadmap.
status: current
verified_at_commit: 325b1b5fe2e65c35bde9a1cd75e099a540b283aa
source_paths:
  - README.md
  - AGENTS.md
  - invariant.boundaries.json
  - docs/development/engineering-process.md
audience:
  - developer
  - operator
---

# Invariant Documentation

Invariant is an engineering system for AI-assisted software work where intelligence can propose, but authority, effects, evidence, and acceptance remain explicit system concerns.

The documentation is both a truthful projection of repository state and a map through the engineering process. It should tell you what is implemented, what is merely planned, which contracts govern the work, what evidence is required, and where the decision that accepted the work lives.

## Start with the question you have

### What is true now?

- [Current status](status.md) — evidence-backed maturity, bound to an explicit repository state.
- [System map](architecture/system-map.md) — products, boundaries, and flows.
- [Product boundaries](architecture/product-boundaries.md) — ownership and negative authority rules.

### How should this change be engineered?

- [Evidence-driven engineering process](development/engineering-process.md) — recon → acceptance property → contract freeze → implementation → evidence → review → decision → docs reconciliation.
- [Engineering traceability](reference/traceability.md) — connect requirement, contract, exact state, evidence, review, and human decision.
- [Cross-product contracts](architecture/contracts.md) — canonical producer/consumer semantics.
- [Evidence flow](architecture/evidence-flow.md) — evidence is not judgment and qualification is not authority.

### Where is the product going?

- [Roadmap](roadmap/index.md) — capability-oriented post-WP-09 direction.
- [Temper roadmap](roadmap/temper.md) — `temper .`, Workbench Alpha, governed actions, recovery, and remote operation.
- [Kiln roadmap](roadmap/kiln.md) — durable Session/query/action/recovery requirements for the operator product.
- [Strategic programs](roadmap/strategic-programs.md) — T3 Challenge relationship and preservation rule.

### Understand the products

- [Arsenal](products/arsenal/index.md) — reusable engineering intelligence and learning.
- [Bench](products/bench/index.md) — evaluation and qualification evidence inside Arsenal.
- [Loadout](products/loadout/index.md) — goals, capabilities, planning, and Work Envelopes.
- [Kiln](products/kiln/index.md) — runtime authority, execution truth, evidence, and acceptance state.
- [Temper](products/temper/index.md) — truthful operator projection and evolving control surface.
- [Manifold](products/manifold/index.md) — selection/allocation boundary.

### Run the repository-visible proof

- [Repository Recon](workflows/repository-recon.md) — the verified Loadout → Kiln → Temper golden path represented by this docs baseline.
- [Operations](operations/index.md) — root commands, doctor, testing, and troubleshooting.

## Truth labels

Every major page declares a status:

- `current` — implemented or normative now;
- `partial` — a real slice exists but the broader capability is incomplete;
- `experimental` — implemented enough to exercise, with intentionally limited evidence/maturity;
- `planned` — bounded direction, not implemented;
- `frontier` — research direction without commitment;
- `historical` — provenance, not current behavior.

Those labels are part of the documentation contract. A compelling diagram, milestone report, or green proxy test is not permission to depict unfinished architecture as demonstrated product behavior.
