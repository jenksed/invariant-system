---
title: Invariant Documentation
description: System documentation for Invariant — architecture, products, workflows, operations, development, and roadmap.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - README.md
  - AGENTS.md
  - invariant.boundaries.json
audience:
  - developer
  - operator
---

# Invariant Documentation

Invariant is an engineering system for AI-assisted software work where intelligence can propose, but authority, effects, evidence, and acceptance remain explicit system concerns.

If you are new to the project, start with the working path rather than the vocabulary:

```text
Goal
→ Loadout Plan + Work Envelope
→ Kiln authority + real supervision
→ Run Result + evidence
→ Temper operator projection
```

That Repository Recon path runs today. The broader Development Loop — governed implementation, mutation, verification, independent review, human decision, and learning — is the next system milestone, not a completed capability.

## Choose a path

### Understand the system

- [Current status](status.md) — what works, what is partial, what does not exist.
- [System map](architecture/system-map.md) — products, boundaries, and flows.
- [Doctrine](concepts/doctrine.md) — the engineering rules behind the architecture.
- [Authority](concepts/authority.md) — why capability, selection, execution, and acceptance stay separate.
- [Evidence](concepts/evidence.md) — what a completion claim must be bound to.

### Understand the products

- [Arsenal](products/arsenal/index.md) — reusable engineering intelligence and learning.
- [Bench](products/bench/index.md) — evaluation and qualification evidence inside Arsenal.
- [Loadout](products/loadout/index.md) — goals, capabilities, planning, and Work Envelopes.
- [Kiln](products/kiln/index.md) — runtime authority, execution truth, evidence, and acceptance state.
- [Temper](products/temper/index.md) — truthful operator projection.
- [Manifold](products/manifold/index.md) — selection/allocation boundary; no runtime yet.

### Run something real

- [Repository Recon](workflows/repository-recon.md) — the current Loadout → Kiln → Temper golden path.
- [Operations](operations/index.md) — root commands, doctor, testing, and troubleshooting.

### Build or review the system

- [Architecture](architecture/index.md)
- [Development](development/index.md)
- [Contracts](architecture/contracts.md)
- [Roadmap](roadmap/index.md)
- [Source-of-truth audit](_meta/source-of-truth-audit.md)

## Truth labels

Every major page declares a status:

- `current` — implemented or normative now;
- `partial` — a real slice exists but the broader capability is incomplete;
- `experimental` — implemented enough to exercise, with intentionally limited evidence/maturity;
- `planned` — bounded direction, not implemented;
- `frontier` — research direction without commitment;
- `historical` — provenance, not current behavior.

Those labels are part of the documentation contract. A compelling diagram is not permission to depict unfinished architecture as shipped software.
