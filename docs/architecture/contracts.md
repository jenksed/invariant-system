---
title: Cross-Product Contracts
description: Canonical facts exchanged between Invariant products without source-level coupling.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - contracts/README.md
  - contracts/work-envelope.v0.md
  - contracts/run-result-envelope.v0.md
  - contracts/qualified-method-record.v0.md
  - contracts/learning-observation.v0.md
  - integration/fixtures/
  - docs/reference/traceability.md
audience:
  - developer
---

# Cross-Product Contracts

Invariant keeps cross-product semantics in four canonical root contracts:

| Contract | Primary direction | What it does **not** grant |
| --- | --- | --- |
| Work Envelope v0 | Loadout → Kiln | execution or mutation authority |
| Run Result Envelope v0 | Kiln → Temper / Loadout consumers | permission to reinterpret absent facts or bypass acceptance rules |
| Qualified Method Record v0 | Arsenal / Bench → capability consumers | live execution authority |
| Learning Observation v0 | runtime observations → Arsenal learning plane | a Claim, qualification, policy, or automatic promotion |

The contract names contain `engineering-system/*` schema identity strings. Those are stable historical identifiers embedded in code, fixtures, authorization records, and frozen evidence. They are **not repository paths** and must not be renamed because the coordination repository became part of the monorepo.

## Contract rule

A product may maintain its own language-specific schema/type implementation. It may not silently fork the cross-product semantics.

Changing a root contract therefore requires checking every producer and consumer, not only the file that was edited.

## Required contract visibility

A consequential work package that consumes or changes a cross-product contract should identify:

- canonical contract path and version;
- producer(s) and consumer(s);
- authority implication and explicit non-authority;
- compatibility or migration decision;
- state/freshness/retry semantics affected by the change;
- fixtures, tests, and end-to-end evidence that bind both sides to the same canonical semantics.

Use the [traceability reference](../reference/traceability.md) to keep that chain visible. Do not duplicate the contract body into a work-package note.

## Contract-change gate

Before implementation fans out across products, freeze the shared semantic decision. Parallel producer/consumer edits against an unresolved contract are not independent work; they are a race to create accidental coupling.

A contract change is not complete merely because every product compiles. The evidence must show that the intended property survives the producer/consumer boundary, including important denial, stale-state, missing-field, and compatibility cases.
