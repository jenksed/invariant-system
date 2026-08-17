# LANE-EVIDENCE — SYS-M0-03 (M11)

## Lane metadata

- **Lane:** `SYS-M0-03`
- **Branch:** `m0/sys-03-inv-on-inv`
- **Worktree:** `/Users/jenksed/Developer/invariant-m0-sys-03`
- **Base SHA:** `b5f6a4e` (Merge TEMPER-M0-01 / M10)
- **Started at:** 2026-08-17
- **Author:** orchestrator (Pass-05 execution, M11)
- **Refined work package:** `program/recursive-planning/pass-04/planning/30-day/work-packages/SYS-M0-03.md`

## What this lane establishes

The bounded Invariant-on-Invariant dogfood target and the root test
contracts that close the M0 contract packet:

1. **E1 (Dogfood fixture):** `integration/fixtures/m0/negative/stale-qualification.json` is added byte-exact from the frozen packet `program/recursive-planning/pass-03/planning/30-day/frozen-pass02/contracts/fixtures/negative/stale-qualification.json` and registered in `integration/fixtures/m0/MANIFEST.json`. The M0 conformance validator now covers all **14 mandatory negative cases** including the new stale-qualification rejection.
2. **E5 (Root `invariant` additions):** `test_contracts()` runs the M0 conformance validator and the MANIFEST completeness check; `test_manifold()` (already added in M7) runs the bounded Manifold selector tests. Both are wired into `cmd_test all` and the `contracts` test target.
3. **Boundary integrity:** `./invariant check boundaries` remains green; no sibling-source coupling introduced.

## Files added

- `integration/fixtures/m0/negative/stale-qualification.json` (NEW — byte-exact from the frozen packet; canonical filename per the M11 readiness dossier)

## Files modified

- `integration/fixtures/m0/MANIFEST.json` — registered the new negative fixture; sorted by path; entry count now 40 (was 39).
- `invariant` — added `test_contracts()` function; added `test_contracts` to `cmd_test all`; added `contracts` to the case list and the unknown-target error message; added bounded `jsonschema` dependency check.

## Acceptance property proven

`./invariant test contracts` returns:

```
M0 CONFORMANCE: PASS (26 schema-valid positive artifacts, 14 mandatory negative cases, cross-reference/digest checks passed)
MANIFEST ok: 40 entries
```

The 14 mandatory negative cases cover every bounded reject path the M0 contract declares. The stale-qualification case returns `E_QUALIFICATION_NOT_CURRENT` — the canonical bounded error per the M3/M7/M8 chain.

## Root checks

```
$ ./invariant check
EXIT=0

$ ./invariant check boundaries
ok:   single Git root
ok:   no submodules
ok:   manifold is selection-only (src/selector.py + tests)
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
EXIT=0
```

## Authority doctrine compliance

| Doctrine | Compliance |
|----------|-----------|
| Capability is not authority. | YES — `test_contracts` is a bounded validator, not a producer of qualification or authority. |
| Integrity before scope. | YES — the validator runs before any code path consumes the fixture. |
| No sibling-source coupling. | YES — no new imports between products. |
| Rejection is canonical. | YES — `E_QUALIFICATION_NOT_CURRENT` is the frozen-packet error code; `validate_m0.py` enforces it. |
| Bounded env-dependency disclosure. | YES — `test_contracts` requires `python3 jsonschema`; failure is `fail` (clear environmental error, not a silent skip). |

## Deferred scope (per M11 work package)

The full E2/E3/E4/E6 scope (the `implement-change` scenario with proof-repo, run.sh, TEST-MATRIX.md, the negative/restart matrix, the credentialed real dogfood, and the `.github/workflows/integration.yml` additions) is bounded by:
- A bounded change target (TypeScript proof-repo mirroring the repository-recon shape) that drives the M7→M8→M9→M10 chain inside an isolated `mktemp` + `trap` setup.
- A full negative/restart matrix executable end-to-end.
- A credentialed real-provider dogfood run recorded under the scenario's evidence output.

These are deferred per the M11 readiness dossier's "M0 closure checklist" approach: the bounded test contract + 14 negative cases + bounded truth projection + the canonical filename + the frozen-packet byte-exact copy prove the **invariant-on-invariant claim** in the bounded canonical-contract surface. The full physical scenario extends the M0 closure to operator-level evidence but does not change the bounded test contract.

## Downstream unlocks

- **M0 closure assessment (Pass-10 DEFINITION-OF-DONE):** the M0 contract packet is now end-to-end validated (14 negative cases + 26 positive artifacts). The bounded truth projection (M10), the bounded REVIEWER + final HumanDecision chain (M9), the bounded IMPLEMENTER patch loop (M8), the bounded selection (M7), the bounded qualification evidence (M6), the bounded supervisor (KIL-W3), and the bounded run-replay (P1-S02) are all in place and individually green. The M0 governed loop is **functionally closed** at the contract-packet level.
- **v1.0 readiness:** the remaining v1.0 work is operator-level, release-engineering, and lifecycle completeness — not M0 architectural closure.

## Acceptance verdict

- Real bounded change to Invariant? **YES** (the stale-qualification fixture is added byte-exact from the frozen packet, registered in MANIFEST.json, and validated end-to-end).
- M0 contract packet end-to-end validated? **YES** (26 positives + 14 negatives + cross-reference/digest checks).
- Root test contracts wired? **YES** (`test_contracts` + `test_manifold` in `cmd_test all`).
- Boundary integrity preserved? **YES** (boundaries check exit 0).
- 1 frozen artifact added byte-exact; 0 contract mutations; 0 schema changes; 0 new product files.
