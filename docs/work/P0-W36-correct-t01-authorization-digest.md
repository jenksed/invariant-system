# P0-W36: Correct the P1-S02-T01 authorization digest

**Document type:** Implementation plan
**Status:** Accepted
**Parent work:** P0-W series (governance / development-process authority)
**Branch:** `work/p0-w36-correct-t01-authorization-digest`
**Depends on:** P0-W35 merged at `d26449e41eb97a316fa6bae4442418397ab29cd3`; PR #48 preflight failure in CI run 31293701028

## Objective

Correct the active P1-S02-T01 authorization record to the SHA-256 of the exact committed accepted-plan blob, repair P0-W35's inaccurate completion Evidence, and restore a valid prospective authority state without changing Kiln runtime files or widening T01 scope.

## Observed current state

| Observation | Evidence | Result |
| --- | --- | --- |
| Current main | `d26449e41eb97a316fa6bae4442418397ab29cd3` | observed |
| Active record digest | `3ce600f0ffe07eb0617c9756090173d9bdaacb48835bf8ca273756f7f9084259` | invalid |
| Exact plan digest | `7a064766037e1a046f93c6bf82fa8920530aafe943db6933418330c8f43add33` | base64-decoded GitHub blob plus `sha256sum` |
| First rebased PR #48 | `01d4258c6abc9f53f0ddb1fb5e3999734af1dbca` | preflight rejected |
| Failed CI | [31293701028](https://github.com/jenksed/kiln/actions/runs/31293701028) | authoritative negative Evidence |

## Assumptions and unknowns

### Assumptions

- **P0-W36-A01:** Correcting a malformed authority record and its Evidence is governance repair, not runtime implementation.
- **P0-W36-A02:** The accepted T01 plan bytes remain unchanged; only the record digest and historical completion account require correction.
- **P0-W36-A03:** PR #48 must be rebased again after this repair integrates so its implementation head descends from the corrected trusted authority source.

### Unknowns

- **P0-W36-U01:** The technical T01 adjudication result remains accept, bounded repair, or reject.
- **P0-W36-U02:** Exact-state runtime verification has not run because preflight correctly blocked it.

## Requirements

- **P0-W36-R01:** Set the T01 authorization `plan_sha256` to `7a064766037e1a046f93c6bf82fa8920530aafe943db6933418330c8f43add33`.
- **P0-W36-R02:** Preserve owner, base, time, scope, canonical order, and every non-retroactivity boundary unchanged.
- **P0-W36-R03:** Correct P0-W35's completion record to retain the flawed verification, invalid merge, and failed consumer CI as negative Evidence.
- **P0-W36-R04:** Change no Kiln runtime, test, migration, schema, dependency, or configuration path.
- **P0-W36-R05:** Require a new PR #48 head descending from the corrected authority source before runtime adjudication resumes.

## Proposed changes

1. Correct `docs/authorizations/P1-S02-T01.authorization`.
2. Replace P0-W35's inaccurate completion account with the exact failure chain.
3. Record P0-W36 exact-head Evidence before integration.

## Expected files or components

- `docs/authorizations/P1-S02-T01.authorization`
- `docs/work/P0-W35-authorize-t01-adjudication.md`
- `docs/work/P0-W36-correct-t01-authorization-digest.md`

## Acceptance criteria

- **P0-W36-AC01:** The active record digest equals the SHA-256 of the exact accepted-plan Git blob.
- **P0-W36-AC02:** P0-W35 history identifies the invalid integrated record and PR #48's preflight rejection.
- **P0-W36-AC03:** The diff contains no runtime path and does not alter authorization scope.
- **P0-W36-AC04:** Full Repository CI passes at the exact governance head.

## Deterministic verification

```bash
git cat-file blob HEAD:docs/work/P1-S02-T01-artifact-evidence-substrate.md | sha256sum
scripts/agent-preflight
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
vale --glob='!{deps,_build}/**' .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
git diff --name-only d26449e41eb97a316fa6bae4442418397ab29cd3 -- lib test priv mix.exs mix.lock config
```

## Required completion Evidence

- **P0-W36-E01:** exact plan blob SHA-256 and matching record.
- **P0-W36-E02:** exact governance head and CI run.
- **P0-W36-E03:** empty runtime-path diff.
- **P0-W36-E04:** exact new main after integration.
- **Post-integration handoff:** new PR #48 head and authorization preflight result; required before runtime adjudication resumes, but impossible before this authority source integrates.

## Explicit exclusions

- No T01 runtime change, repair, acceptance, rejection, or merge.
- No plan-content or scope amendment.
- No later P1-S02 authorization.
- No erasure of the invalid P0-W35 or failed PR #48 Evidence.

## Completion record

**Result:** Authorization digest corrected and governance repair verified. Runtime adjudication remains paused until PR #48 is rebased again onto the integrated P0-W36 authority source and its implementation-head preflight passes.

### Verified Repository state

- Base: `d26449e41eb97a316fa6bae4442418397ab29cd3`.
- Branch: `work/p0-w36-correct-t01-authorization-digest`.
- Pull request: PR #51.
- Corrected authority head: `0d0564165e7a94e2017cf77eb413ceda9160c7cb`.
- Exact accepted-plan blob SHA-256: `7a064766037e1a046f93c6bf82fa8920530aafe943db6933418330c8f43add33`.
- Corrected record `plan_sha256`: identical.
- Exact-head CI: [31293872465](https://github.com/jenksed/kiln/actions/runs/31293872465), success.
- Runtime-path diff: empty.
- Final closeout commit: documentation-only and must receive a fresh full CI run before merge.

### Acceptance status

| Criterion | Status | Evidence | Result |
| --- | --- | --- | --- |
| P0-W36-AC01 | Pass | P0-W36-E01 | base64-decoded exact GitHub plan blob hashes to `7a064766…`, matching the record |
| P0-W36-AC02 | Pass | compare | P0-W35 completion now records the invalid merge and failed PR #48 consumer CI |
| P0-W36-AC03 | Pass | P0-W36-E03 | owner, base, time, scope, and non-retroactivity unchanged; no runtime path changed |
| P0-W36-AC04 | Pass | P0-W36-E02 | exact corrected authority head is fully CI-green |

### Completion Evidence

- **P0-W36-E01:** `base64 -d` of the GitHub `fadeb6d00f83894539c35f7498790b4f04e3231b` plan blob piped to `sha256sum` produced `7a064766037e1a046f93c6bf82fa8920530aafe943db6933418330c8f43add33`.
- **P0-W36-E02:** CI run `31293872465` passed governing-package validation, preflight regressions, semantic and JSON Schema validation, agent assets, formatting, warnings-as-errors compilation, cycle checks, direct tests, P1-S01 aggregate gate/upload, and Vale.
- **P0-W36-E03:** Compare from `d26449e…` changes only the T01 authorization record and P0-W35/P0-W36 governance records.
- **Post-integration handoff:** after this PR merges, recreate PR #48's unchanged patch on the resulting exact main, require its actual implementation-head preflight to pass, and only then continue technical adjudication.

### Remaining boundary

PR #48 remains unaccepted and unmerged. Its first rebased head `01d4258c…` remains failed Evidence tied to the invalid P0-W35 authority state. No runtime validation result from that head may be promoted. P1-S02-T02 and later work remain unauthorized.
