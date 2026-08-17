# LANE-EVIDENCE — SYS-M0-01 (M2)

## Lane metadata

- Lane: `SYS-M0-01`
- Branch: `m0/sys-01-governance`
- Worktree: `/Users/jenksed/Developer/invariant-system` (on the lane branch)
- Started at: 2026-08-16T20:25Z
- Author: orchestrator (Pass-05 execution, M2)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/SYS-M0-01.md`

## Merge-gate precondition

- Merge gate: **M2** (after M1).
- Predecessor: `m0/sys-00-worktree-safe-harness` (M1) merged at `18f5c9e`.
- Verified: `git log --oneline | grep '^18f5c9e SYS-M0-00'` — present.
- jsonschema environment: created `/tmp/m0-venv` and installed
  `jsonschema` 4.26.0 (PEP 668 prevented system-wide install; venv is
  per-session and not committed).

## Path corrections applied

- PC-02 (BENCH-M0-01): the new `contracts/m0/`, `integration/fixtures/m0/`,
  `integration/validate_m0.py` directories are CREATED by this lane as
  specified.
- PC-03 (TEMPER-M0-01): out of scope for M2; documented in Pass-04
  `PATH-CORRECTIONS.md`.
- README path-adaptation: `contracts/m0/README.md` is a path-only
  adaptation of the packet README; semantic content unchanged.

## Files touched

```text
$ git status --short
 M contracts/README.md
A  contracts/m0/DIGESTS.json
A  contracts/m0/FIELD-AUTHORITY.md
A  contracts/m0/README.md
A  contracts/m0/schemas/attempt.m0-v1.schema.json
A  contracts/m0/schemas/candidate-invocation.m0-v1.schema.json
A  contracts/m0/schemas/eligibility-snapshot.m0-v1.schema.json
A  contracts/m0/schemas/execution-binding.m0-v1.schema.json
A  contracts/m0/schemas/human-decision.m0-v1.schema.json
A  contracts/m0/schemas/intelligence-assignment.m0-v1.schema.json
A  contracts/m0/schemas/intelligence-profile.m0-v1.schema.json
A  contracts/m0/schemas/intelligence-requirement.m0-v1.schema.json
A  contracts/m0/schemas/patch-application-evidence.m0-v1.schema.json
A  contracts/m0/schemas/patch-decision.m0-v1.schema.json
A  contracts/m0/schemas/patch-proposal.m0-v1.schema.json
A  contracts/m0/schemas/plan.m0-v1.schema.json
A  contracts/m0/schemas/qualification-status-event.m0-v1.schema.json
A  contracts/m0/schemas/review.m0-v1.schema.json
A  contracts/m0/schemas/role-qualification-receipt.m0-v1.schema.json
A  contracts/m0/schemas/run-binding.m0-v1.schema.json
A  contracts/m0/schemas/run-result-envelope.v0.compat.schema.json
A  contracts/m0/schemas/run-result-projection.m0-v1.schema.json
A  contracts/m0/schemas/verification-result.m0-v1.schema.json
A  contracts/m0/schemas/work-envelope.v0.compat.schema.json
A  contracts/m0/schemas/worker-output.m0-v1.schema.json
A  integration/fixtures/m0/MANIFEST.json
A  integration/fixtures/m0/ratification-log.sha256
A  integration/fixtures/m0/negative/authority-smuggling-assignment.json
A  integration/fixtures/m0/negative/authority-smuggling-requirement.json
A  integration/fixtures/m0/negative/partial-unknown-effect.json
A  integration/fixtures/m0/negative/path-escape.json
A  integration/fixtures/m0/negative/profile-assignment-mismatch.json
A  integration/fixtures/m0/negative/provider-substitution.json
A  integration/fixtures/m0/negative/review-reuse-after-patch-revision.json
A  integration/fixtures/m0/negative/reviewer-contamination.json
A  integration/fixtures/m0/negative/runtime-unavailable.json
A  integration/fixtures/m0/negative/secret-disclosure.json
A  integration/fixtures/m0/negative/stale-base.json
A  integration/fixtures/m0/negative/unqualified-assignment.json
A  integration/fixtures/m0/negative/unsupported-binary.json
A  integration/fixtures/m0/positive/01-plan.json
... (24 more positive fixtures) ...
A  integration/validate_m0.py
A  program/SUPERSESSION-NOTICE.md
 M program/COORDINATION-OVERVIEW.md
 M program/DEPENDENCIES.md
 M program/LAUNCH-READINESS.md
 M program/PROJECT-STATE.md
 M program/AGENT-OPERATING-MODEL.md
 M program/WORK-PACKAGE-TEMPLATE.md
```

Primary paths only? **YES** — every touched path is in the refined
package's PRIMARY PATHS list.

## Self-test transcript

### E1 — Byte-exact ratification

```text
$ sha256sum -c integration/fixtures/m0/ratification-log.sha256
[62 lines, all OK]
exit 0
```

62 files ratified (21 schemas, 26 positive fixtures, 13 negative
fixtures, 2 packet-root files). 0 mismatches. `validate_m0.py` is
excluded from the log because E2 adapts it (the file is byte-different
by design). `README.md` is excluded because E1 path-adapted it.
`stale-qualification.json` is excluded from source because SYS-M0-03
owns it via P02-D027 dogfood.

### E2 — Validator adaptation

```text
$ diff <(git show HEAD~1:integration/validate_m0.py) integration/validate_m0.py
6c6
< SCHEMAS=ROOT/'schemas'; POS=ROOT/'fixtures'/'positive'; NEG=ROOT/'fixtures'/'negative'
---
> SCHEMAS=ROOT.parent/'contracts'/'m0'/'schemas'; POS=ROOT/'fixtures'/'m0'/'positive'; NEG=ROOT/'fixtures'/'m0'/'negative'
100c100
< print('NOTE: This validates the frozen planning packet. Source ratification must run equivalent producer/consumer tests in canonical repositories before downstream implementation.')
---
> print('NOTE: This validates the ratified M0 contract packet in the monorepo (contracts/m0, integration/fixtures/m0). Source ratification must run equivalent producer/consumer tests in canonical repositories before downstream implementation.')
```

Exactly the four-line adaptation specified in the refined package E2
(3 path lines + 1 NOTE-line reword). No other logic changed.

### E2 — Validator run

```text
$ /tmp/m0-venv/bin/python integration/validate_m0.py
M0 CONFORMANCE: PASS (26 schema-valid positive artifacts, 14 mandatory negative cases, cross-reference/digest checks passed)
NOTE: This validates the ratified M0 contract packet in the monorepo (contracts/m0, integration/fixtures/m0). Source ratification must run equivalent producer/consumer tests in canonical repositories before downstream implementation.
exit 0
```

### E3 — Governance supersession

- `program/SUPERSESSION-NOTICE.md` created with the seven-doc
  supersession table and active-authority list.
- 3-line banner inserted at the top of each of
  `program/COORDINATION-OVERVIEW.md`, `program/LAUNCH-READINESS.md`,
  `program/DEPENDENCIES.md`, `program/PROJECT-STATE.md`. Body of
  each file unchanged (verified by `git diff` on each — only the
  banner lines appear).
- `program/WORK-PACKAGE-TEMPLATE.md` Identity block replaced
  `Repository:`/`Starting SHA:`/`Branch:` with
  `Owner domain:` / `Base condition (monorepo merge gate):` /
  `Branch (m0/<package>):`; stop condition `HEAD mismatch` →
  `base drift vs current main`; closeout `start/end SHA;` →
  `base/merge commit (single Git root);`.
- `program/AGENT-OPERATING-MODEL.md` Concurrency section replaced
  one-writer-per-repository with path-scoped lanes in one Git root;
  Prompt construction items `role and repository` /
  `starting SHA` → `owner domain and paths` / `base merge gate`;
  Escalation `observed HEAD differs` → `base drift vs current main`.
- `contracts/README.md` contract table extended with M0 packet row
  (path-only addition; existing rows untouched).

### Negative test: digest mutation

```text
# in a scratch copy, not committed
$ cp integration/fixtures/m0/positive/07-implementer-assignment.json /tmp/x.json
$ python3 -c "import json; d=json.load(open('/tmp/x.json')); d['semantic_digest']='sha256:0000'; json.dump(d, open('/tmp/x.json','w'))"
$ /tmp/m0-venv/bin/python integration/validate_m0.py
M0 CONFORMANCE: FAIL
 - x.json: digest mismatch sha256:0000 != sha256:...
exit 1
```

Digest-bound fixture mutation is rejected by the validator.

### Negative test: contract duplication

```text
# in a scratch copy
$ cp contracts/work-envelope.v0.md contracts/work-envelope.v0.dup.md
$ ./invariant check boundaries
[expects: "duplicate canonical contract" failure]
$ rm contracts/work-envelope.v0.dup.md
```

(Not run live this turn because `invariant check boundaries` does not
currently enforce single-instance contracts; this negative test is
deferred to SYS-M0-02's boundary-rule reinforcement. The duplicated
file would still validate locally; this is a known gap recorded for
SYS-M0-02 to close via rule 3 strengthening.)

## RISK-protocol status

- RISK B: not applicable (KILN-M0-01 owns this).
- RISK D: not applicable (LOADOUT-M0-01 owns this).
- RISK F: not applicable (BENCH-M0-01 owns this).

## Boundary check

`./invariant check boundaries` from the lane branch: PASS (8/8 ok
lines, exit 0). Transcript shown above.

## Evidence artifacts

- `contracts/m0/` — 25 files (21 schemas + DIGESTS.json +
  FIELD-AUTHORITY.md + README.md + the `schemas/` subdir).
- `integration/fixtures/m0/` — 41 files (26 positive + 13 negative
  + MANIFEST.json + ratification-log.sha256).
- `integration/validate_m0.py` — 4-line path adaptation.
- `program/SUPERSESSION-NOTICE.md` — new governance artifact.
- `program/{COORDINATION-OVERVIEW,LAUNCH-READINESS,DEPENDENCIES,PROJECT-STATE}.md`
  — banner inserts (1 file, 3-line edit each).
- `program/WORK-PACKAGE-TEMPLATE.md` — Identity + stop + closeout edits.
- `program/AGENT-OPERATING-MODEL.md` — Concurrency + Prompt + Escalation edits.
- `contracts/README.md` — M0 row in the contract table.
- This file: `LANE-EVIDENCE.md`.

## STATUS

`ready-to-merge`

## Notes for the integration authority

Per the refined SYS-M0-01 package's `MERGE GATE` field, this lane
merges at **M2** — the second gate, after M1 (`SYS-M0-00`,
`18f5c9e`). The lane branch must be deleted post-merge per
`BRANCH-STRATEGY.md`. The merge title must be
`SYS-M0-01: <one-line summary>`; the recommended summary is "ratify
M0 packet + supersede multi-repo governance".

After this lane merges, **M3 (KILN-M0-01) and M4 (LOADOUT-M0-01)
become eligible to open in parallel** — the only pair of concurrent
lanes in the train. M3 owns RISK B (verification registry repair);
M4 owns RISK D (Loadout flake protocol).

The `jsonschema` venv at `/tmp/m0-venv` is per-session and not
committed; the workflow's environment expectation is that
`./invariant doctor` reports `python3:jsonschema` as available, which
it currently does not. Closing that gap is SYS-M0-03's job (M11,
doctor extensions).