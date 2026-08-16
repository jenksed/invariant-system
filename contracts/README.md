# Invariant Contracts

Canonical cross-product boundary contracts. These documents define the
semantics that let Invariant products exchange facts without sharing
implementations.

| Contract | Spec | Fixture |
| --- | --- | --- |
| Work Envelope v0 | [work-envelope.v0.md](work-envelope.v0.md) | [integration/fixtures/work-envelope.v0.yaml](../integration/fixtures/work-envelope.v0.yaml) |
| Run Result Envelope v0 | [run-result-envelope.v0.md](run-result-envelope.v0.md) | [integration/fixtures/run-result-envelope.v0.yaml](../integration/fixtures/run-result-envelope.v0.yaml) |
| Qualified Method Record v0 | [qualified-method-record.v0.md](qualified-method-record.v0.md) | [integration/fixtures/qualified-method-record.v0.yaml](../integration/fixtures/qualified-method-record.v0.yaml) |
| Learning Observation v0 | [learning-observation.v0.md](learning-observation.v0.md) | [integration/fixtures/learning-observation.v0.yaml](../integration/fixtures/learning-observation.v0.yaml) |

## Provenance

These contracts originated in the `engineering-system` coordination
repository (history preserved under `program/historical/engineering-system/`)
and were relocated to the monorepo root during consolidation.

## Schema identity strings

The schema identity strings (`engineering-system/work-envelope/v0`,
`engineering-system/run-result-envelope/v0`, …) are **stable identifiers**,
not paths. They are embedded in product code, fixtures, signed authorization
records, and frozen evaluation evidence across the system. They MUST NOT be
renamed merely because the contract documents moved; treat the
`engineering-system/` prefix as historical namespacing.

## Rules

- This directory defines canonical cross-product semantics only. Products
  keep their own language-specific adapters and types (e.g. Loadout's zod
  schemas in `products/loadout/src/core/schemas.ts`, Kiln's
  `Kiln.WorkEnvelope` / `Kiln.RunResultEnvelope` modules, Temper's types in
  `products/temper/src/types.ts`).
- Product-internal contracts (e.g. Kiln's `products/kiln/docs/contracts/`
  conformance schemas, Arsenal's capability/asset contracts) stay inside
  their product.
- Changing a contract here requires checking every product that produces or
  consumes it. Fixtures under `integration/fixtures/` are
  compatibility-checked by product test suites; do not reformat them
  casually — some records are digest-bound.
