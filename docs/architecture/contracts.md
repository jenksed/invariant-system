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
audience:
  - developer
---

# Cross-Product Contracts

Invariant keeps cross-product semantics in four canonical root contracts:

| Contract | Primary direction |
| --- | --- |
| Work Envelope v0 | Loadout → Kiln |
| Run Result Envelope v0 | Kiln → Temper / Loadout consumers |
| Qualified Method Record v0 | Arsenal / Bench → capability consumers |
| Learning Observation v0 | runtime observations → learning plane |

The contract names contain `engineering-system/*` schema identity strings. Those are stable historical identifiers embedded in code, fixtures, authorization records, and frozen evidence. They are **not repository paths** and must not be renamed because the coordination repository became part of the monorepo.

## Contract rule

A product may maintain its own language-specific schema/type implementation. It may not silently fork the cross-product semantics.

Changing a root contract therefore requires checking every producer and consumer, not only the file that was edited.
