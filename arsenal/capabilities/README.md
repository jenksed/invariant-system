# Arsenal Capability Set

This directory contains the canonical machine-readable **Capability Contract v2** fragments.

Each `*.json` file defines exactly one capability using schema version `2.0.0` and is validated against `../capability.schema.json` plus the executable cross-contract rules in `../../scripts/capability_audit.py`.

The merged capability view is the deterministic filename-ordered composition of every JSON fragment in this directory.

Do not encode harness packaging here. Codex, Claude, Agent Skills, plugin, slash-command, and similar adapter details belong under distribution/compiler surfaces.

## ARS-01 migration set

- `repository-truth.json` — Repository Truth
- `pressure-test.json` — Pressure Test, preserving Grill/Grilling aliases
- `recon.json` — Recon, preserving Wayfind/Wayfinding aliases
- `diagnose.json` — Diagnose
- `tdd.json` — TDD
- `review.json` — Review
- `verify.json` — Verify
- `resume.json` — Resume
- `local-cloud-feature-delivery.json` — execution-backed Floci composition

All nine begin at capability lifecycle `draft`. ARS-01 establishes representability and validation; it does not create evaluation evidence. ARS-02 Arsenal Bench owns lifecycle evidence for `testing` and `stable`.

## Commands

```bash
python3 scripts/capability_audit.py
python3 scripts/test-capability-contract.py
```

See `../CAPABILITY_CONTRACT.md` for semantics and the boundary with the Asset Contract.
