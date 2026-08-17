# M0 Frozen Contract Set

Schemas are JSON Schema Draft 2020-12 with closed top-level shapes. `work-envelope.v0.compat.schema.json` and `run-result-envelope.v0.compat.schema.json` are conformance mirrors of existing source contracts used by the planning packet; canonical source remains engineering-system/Kiln until M0 source ratification.

This packet is ratified byte-exactly under `contracts/m0/` (schemas, `DIGESTS.json`, `FIELD-AUTHORITY.md`) and `integration/fixtures/m0/` (positive and 13 of 14 negative fixtures; `stale-qualification.json` is reserved for `SYS-M0-03` dogfood execution). Validator: `integration/validate_m0.py`.

The first source ratification must preserve exact bytes/digests or explicitly record mechanical language-native generation. Any semantic discrepancy reopens Pass 02.