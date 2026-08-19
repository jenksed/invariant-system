---
title: Architecture
description: Invariant system topology, ownership, contracts, data flow, authority flow, and provenance.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant.boundaries.json
  - contracts/
  - integration/
audience:
  - developer
---

# Architecture

Invariant's monorepo is deliberately not a monolith of authority.

- [System map](system-map.md)
- [Product boundaries](product-boundaries.md)
- [Data flow](data-flow.md)
- [Contracts](contracts.md)
- [Authority flow](authority-flow.md)
- [Evidence flow](evidence-flow.md)
- [Execution model](execution-model.md)
- [Provenance and history](provenance-and-history.md)

The most important architectural constraint is negative: a product does not gain another product's authority merely because both source trees now share a Git root.
