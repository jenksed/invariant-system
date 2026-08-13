# Contract Adjudication Required — Productized Method Binding

**Status:** BLOCKS QMR GRADUATION, NOT METHOD EVALUATION  
**Affected contract:** `engineering-system/qualified-method-record/v0`

## Observed seam

Wave 5 has evidence for a winning Repository Recon method, exact candidate
implementation, exact real-repository suite, exact corpus commits, exact
results, and a Loadout product target. QMR v0 can carry only one
`procedure_ref`. It cannot canonically state which product target and adapter
the evaluation exercised.

Putting adapter or target identity into `evaluation.observed_strengths`,
`notes`, or free-form provenance would make the binding descriptive rather
than canonical. Arsenal therefore must not mark the winner `qualified` under
QMR v0.

## Smallest missing semantic

QMR needs one canonical **evaluation target binding** containing:

```text
target_product
target_commit
target_procedure_digest
adapter_id
adapter_version_or_digest
evaluation_suite_digest
result_digest
```

This may be one optional structured object; no new lifecycle vocabulary is
required. `status: experimental | qualified` can remain unchanged because the
binding says what the qualification applies to.

## Current truthful state

- Winner: selected and holdout-validated.
- Winner QMR status: Loadout records experimental adoption only; QMR v0 cannot bind the full observed reality and no qualification is claimed.
- Existing fixture QMR: replaced in Loadout by the experimental adoption record.
- Capability adoption: may consume the evaluated method as boundary data
  because Loadout accepts experimental methods, but must not call it qualified.
- Contract change: proposed for owner adjudication only; not implemented in
  Wave 5.
