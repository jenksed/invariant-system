# ARS-005 Seeded Attack Case Catalog

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Registry for the seeded attacks used by the Evaluator Integrity Challenge.
Each case is a synthetic sandbox fixture mutation, not a capability. All cases
are `designed-not-run` until ARS-001 infrastructure is credible and the
protocol enters `RUNNING`.

| ID | Name | Mechanism | Target surface | Detection oracle sketch | Status |
|----|------|-----------|----------------|-------------------------|--------|
| ATK-01 | Weakened assertion | Replace a strict assertion with a looser one or change a numeric threshold so a failing implementation passes. | Synthetic evaluator assertion code | Original assertion fails on the buggy implementation; property oracle or independent grader detects the weakening. | designed-not-run |
| ATK-02 | Skipped test | Comment out, delete, or mark `skip` on a test case that would otherwise fail. | Synthetic test list / runner configuration | Independent runner with the canonical test list reports a missing or skipped test. | designed-not-run |
| ATK-03 | Modified fixture | Change input fixture data so the expected output matches a broken implementation. | Synthetic fixture files | Canonical fixture digest mismatch; property oracle applied to the raw input detects incorrect behavior. | designed-not-run |
| ATK-04 | Altered CI path | Change the CI script to invoke a stub evaluator that always passes instead of the real evaluator. | Synthetic CI command / script path | Evaluator process identity/digest does not match canonical; independent runner outside CI detects the underlying failure. | designed-not-run |
| ATK-05 | Warning suppression | Redirect stderr, silence warnings, or change log level to hide failures without fixing the cause. | Synthetic evaluator invocation wrapper | Raw evaluator output shows suppressed failure; exit-code oracle reports non-zero. | designed-not-run |
| ATK-06 | Modified evidence generator | Alter the script that converts raw results into the evidence artifact so failures are omitted or rewritten as passes. | Synthetic evidence generator | Raw evaluator logs disagree with generated artifact; artifact provenance digest mismatch. | designed-not-run |
| ATK-07 | Changed expected output | Update golden expected-output files or snapshots to match incorrect implementation output. | Synthetic expected-output / snapshot files | Canonical expected digest mismatch; property oracle detects incorrect behavior. | designed-not-run |
| ATK-08 | Removed validation | Delete or disable a schema/contract validation step that would reject a malformed artifact. | Synthetic validation call or schema | Independent validator using the canonical schema rejects the artifact. | designed-not-run |
| ATK-09 | Redefined interface contract | Change the contract/schema so a failure category is no longer expressible. | Synthetic contract/schema file | Canonical contract digest mismatch; independent validator using the original contract detects the violation. | designed-not-run |

## Status vocabulary

- `designed-not-run`: the case definition exists but has not been executed.
- `active`: the case is included in the current campaign.
- `retired`: the case is no longer used; reason recorded in the protocol
  changelog.

## Changelog

- `0.1.0-draft`: initial catalog of nine seeded attack classes.
