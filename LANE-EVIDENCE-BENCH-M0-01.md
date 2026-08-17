# LANE-EVIDENCE — BENCH-M0-01 (M6)

## Lane metadata

- Lane: `BENCH-M0-01`
- Branch: `m0/bench-01-role-qualification`
- Worktree: `/Users/jenksed/Developer/invariant-m0-bench-01`
- Base SHA: `6534ad6` (Merge KILN-M0-01-CLI-CLOSURE into main, M6-FIX)
- Started at: 2026-08-16
- Author: orchestrator (Pass-05 execution, M6)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/BENCH-M0-01.md`
- Authoritative authorization: `KILN-M0-01.authorization` (existing M3 authorization; the CLI surface that BENCH-M0-01 invokes through is the one M3 wired)

## Train amendment context

The merge train position around M6 was amended by `MERGE-TRAIN-AMENDMENT-M6.md`
to insert a corrective lane (`KILN-M0-01-CLI-CLOSURE`, merged at
`6534ad6`) ahead of M6. That corrective lane fixed the M3 latent E4
acceptance defect: the public CLI surface for `candidate-invocation` and
`candidate-invocation-digest` was unwired; the bench could not invoke
through the canonical surface until E1/E2 landed. This lane therefore
depends on `m0/kiln-01-cli-closure` merged first.

## What this lane produced

### E1 — Profile materialization
- `products/arsenal/evaluation/profiles/m0/implementer.json` and
  `products/arsenal/evaluation/profiles/m0/reviewer.json`. Both profiles
  bind to the **runtime** `adapter.implementation_digest` surfaced by
  `mix kiln candidate-invocation-digest`
  (`sha256:c3b959045f54b5501430ca3f26d8823e04a665a0171d63c9ed107c6f4bed39d1`,
  this run), not the planning-time fixture constant
  (`sha256:39cfd816...`). `profile_id` is generated and excluded from
  the `semantic_digest` computation per the M0 contract; both
  invariants are enforced in `arsenal_m0_qualification.py` and verified
  in `test-m0-role-qualification.py`.
- Role-package, system-config, tool-policy, and context-policy files
  under `evaluation/profiles/m0/{role-packages,system-configs,tool-policies,context-policies}/`.
  Their canonical `sha256:` digests are embedded in each Profile.

### E2 — Campaign runner `scripts/arsenal_m0_qualification.py`
- Self-locating pattern (`ROOT = Path(__file__).resolve().parents[1]`)
  shared with `arsenal_bench.py` and friends.
- Subcommands: `materialize`, `run --role IMPLEMENTER|REVIEWER`,
  `receipt`, `status`, `snapshot`.
- The `run` subcommand executes the frozen campaign (`m0-role-qualification-v1`):
  8 required cases × 3 replications = **24 executions per role**. Each
  execution invokes `mix kiln candidate-invocation --request <f> --mode
  evaluation --format json --actor-id bench` (subprocess; never a Python
  HTTP client). The Kiln CLI gates production mode on `MINIMAX_API_KEY`
  presence; evaluation mode does not consume the credential. The bench
  nevertheless carries the key from `MINIMAX.txt` so a future
  production-mode case would not silently fall through.
- The `receipt` subcommand emits the immutable Role Qualification
  Receipt, bound to the materialized `profile_ref`, the closed
  `policy_ref id=m0-role-qualification-v1`, the per-role `campaign_ref`,
  the per-case summary, the per-category hard-zero counters, and the
  `evaluated_at` wall clock. Receipt bytes are immutable; subsequent
  Status Event changes never rewrite them.
- The `status` subcommand appends an `ACTIVE` Qualification Status
  Event when the receipt's verdict is `QUALIFIED`.
- The `snapshot` subcommand derives an Eligibility Snapshot that
  implements the 168-hour currentness rule and the `QUALIFIED`
  preconditions from `QUALIFICATION-CURRENTNESS-MODEL`. Competing
  ACTIVE receipts for the same Profile force `NOT_ELIGIBLE` until
  reconciled.

### E3 — Cases `evaluation/cases/m0-role-qualification/suite.json`
- 16 cases: 8 IMPLEMENTER + 8 REVIEWER.
- Each case carries the bench case fields
  (`id`, `title`, `track`, `capability_id`, `active`, `execution`,
  `fixture`, `comparison`, `expected`, `case_health`, `metrics`),
  follows the existing `cases/core-engineering.json` shape, and uses
  the existing `CASE_HEALTH_CHECKS` vocabulary.
- Holdouts (2 per role, sealed): `m0-impl-secret-disclosure-holdout`,
  `m0-impl-authority-violation-holdout`,
  `m0-rev-reviewer-context-contamination-holdout`,
  `m0-rev-acceptance-fabrication-holdout`. Each is flagged `sealed: true`
  in `execution`; the bench harness controls visibility of the fixture
  content. ≥2 sealed holdouts per role satisfied.

### E4 — Tests
- `scripts/test-m0-role-qualification.py`: adversarial mirror of
  `test-arsenal-qualification.py`. Mutations exercised:
  hard-zero category (`SECRET_DISCLOSURE`) forces
  `NOT_QUALIFIED`; failed holdout invalidates the qualification;
  adapter digest drift between Profile and receipt invalidates the
  receipt.
- `scripts/test-m0-qualification-currentness.py`:
  - NEGATIVE stale-qualification: receipt aged >168h drives
    eligibility to `NOT_ELIGIBLE`;
  - competing ACTIVE receipts for the same Profile drive
    `NOT_ELIGIBLE` until reconciled;
  - SUPERSEDED/INVALIDATED Status Event removes eligibility while
    receipt bytes remain immutable;
  - determinism: same eligibility-driving inputs yield the same
    eligibility value across runs.

### E5 — Root wiring
- Appended exactly two lines to `test_arsenal()` in `invariant`
  (after the existing `test-arsenal-qualification.py` line):
  ```
  python3 scripts/test-m0-role-qualification.py
  python3 scripts/test-m0-qualification-currentness.py
  ```
  This is the only edit to `invariant` from this lane; the
  pre-existing lines are untouched.

## Real campaign evidence (authoritative)

The actual 24/24 campaigns per role were executed through the Kiln
CLI surface fixed by the corrective lane, not through a Python HTTP
client. Both campaigns passed **24/24** with the runtime adapter
digest `sha256:c3b959045f54b5501430ca3f26d8823e04a665a0171d63c9ed107c6f4bed39d1`.

| Role | Executions | PASS | Holdouts | Verdict | Receipt id |
|------|-----------:|-----:|---------:|---------|-----------|
| IMPLEMENTER | 24 | 24 | 2 | QUALIFIED | `qlf_ba9049d4f6df11283929efe8847ce89d035ed777390f4e6800449a3170d4098c` |
| REVIEWER | 24 | 24 | 2 | QUALIFIED | `qlf_b7e61d7e5b4233872bc95cad1f8639aa4ff0276bb67f1a32befdd757fa45306d` |

All artifacts committed under `products/arsenal/evaluation/qualifications/m0/`:

```
implementer-case-health.json           (Case Health Receipts, 8 cases × HEALTHY)
implementer-eligibility.json           (Eligibility Snapshot, QUALIFIED)
implementer-evidence.json              (24 evidence rows: invocations + status)
implementer-qualification-receipt.json (immutable receipt)
implementer-status-event.json          (initial ACTIVE Status Event)
reviewer-case-health.json              (Case Health Receipts, 8 cases × HEALTHY)
reviewer-eligibility.json              (Eligibility Snapshot, QUALIFIED)
reviewer-evidence.json                 (24 evidence rows: invocations + status)
reviewer-qualification-receipt.json    (immutable receipt)
reviewer-status-event.json             (initial ACTIVE Status Event)
```

The Placeholder QMR from M4 (in
`products/arsenal/evaluation/qualifications/agent-skills.repository-truth.v1.json`
and `agent-skills.plan.v1.json`) is preserved unchanged as a fixture;
its status is **NOT** promoted. The M6 receipts use the new bounded
`role-qualification-receipt/m0-v1` schema and live under `m0/`,
distinct from the existing distribution-qualification receipts at the
top of `qualifications/`.

## Schema conformance

Each artifact conforms to the corresponding M0 schema (verified with
`jsonschema`):

| Artifact | Schema | Result |
|----------|--------|--------|
| `implementer-qualification-receipt.json` | `role-qualification-receipt.m0-v1.schema.json` | PASS |
| `implementer-status-event.json` | `qualification-status-event.m0-v1.schema.json` | PASS |
| `implementer-eligibility.json` | `eligibility-snapshot.m0-v1.schema.json` | PASS |
| (same for reviewer) | (same) | PASS |

## Test commands run

```
$ python3 scripts/test-m0-role-qualification.py
M0 role qualification adversarial suite: PASS

$ python3 scripts/test-m0-qualification-currentness.py
M0 qualification currentness suite: PASS

$ python3 scripts/test-arsenal-qualification.py
ARS-07 qualification adversarial suite: PASS

$ ./invariant test arsenal
... (full Arsenal suite; all PASS, including the two new lines)
```

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
ok:   contract canonical: contracts/learning-observation.v0.md
EXIT=0
```

## Why this lane satisfies the M6 acceptance property

M6 is the first lane that depends on a **consumer-visible** Kiln
surface. The bench's M0 campaigns execute 48 real `mix kiln
candidate-invocation` invocations across two roles, each returning a
schema-conformant CLI Result envelope with the runtime
`adapter_implementation_digest`. The receipts are immutable
artifacts bound to that runtime digest. The Eligibility Snapshots
implement the 168-hour currentness rule.

The M4 placeholder QMR is explicitly **not** promoted: it remains a
fixture in the `qualifications/` top-level with its existing status;
the new M6 receipts are committed under `qualifications/m0/` and use
the bounded M0-v1 schemas. M7 (Manifold selection) can read the
Eligible Snapshots to surface qualified profiles without conflating
them with the fixture QMR.

## Constraints honoured

- No `products/bench` directory created; Bench stays inside Arsenal.
- No Python HTTP client to the provider; every campaign execution
  routed through `mix kiln candidate-invocation` (the M6-FIX
  corrective-lane surface).
- The Placeholder QMR from M4 is **not** promoted; its status is
  preserved.
- Adapter implementation digest is the runtime digest surfaced by
  the live Kiln CLI, not a planning-time fixture constant.
- M7 (Manifold) is not implemented; this lane stops at M6.

## Downstream unlocks

- MANIFOLD-M0-01 (M7): reads the Eligibility Snapshots to surface
  qualified Profiles for selection. The snapshots are
  schema-conformant and the eligibility value is `QUALIFIED` for both
  roles within the 168-hour currentness window.
- SYS-M0-03 dogfood currentness data: the per-role `evaluated_at` and
  `valid_until` are real wall-clock values; the 168-hour rule is
  exercised in `test-m0-qualification-currentness.py`.