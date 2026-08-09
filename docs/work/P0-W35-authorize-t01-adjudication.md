# P0-W35: Authorize P1-S02-T01 candidate adjudication

**Document type:** Implementation plan
**Status:** Accepted
**Parent work:** P0-W series (governance / development-process authority)
**Branch:** `work/p0-w35-authorize-t01-adjudication`
**Depends on:** P0-W34 merged at `dc375d923c99b9c754d9b53d601b214b0c8941a5`; explicit owner instruction to record main, authorize adjudication, and rebase/review PR #48

## Objective

Accept the corrected P1-S02-T01 plan and create prospective Repository authority for adjudicating PR #48, rerunning exact-state verification, and making only repairs bounded by T01. Preserve the earlier candidate commit as premature and unauthorized, keep every later P1-S02 ticket unauthorized, and make no Kiln runtime change in this governance package.

## Observed current state

| Observation | Evidence | Result |
| --- | --- | --- |
| Exact canonical main after PR #49 | `dc375d923c99b9c754d9b53d601b214b0c8941a5` | observed |
| PR #48 candidate head | `60367874bfc3c0e6d8cbd736f58e1ae17938943b` | open, premature candidate |
| Corrected T01 plan | `docs/work/P1-S02-T01-artifact-evidence-substrate.md` | Proposed before this package |
| Active T01 authorization | absent | adjudication blocked |
| Authorization enforcement | P0-W34 / PR #49 | integrated and exact-head bound |

## Assumptions and unknowns

### Assumptions

- **P0-W35-A01:** The owner's explicit instruction authorizes this governance package and prospective T01 adjudication.
- **P0-W35-A02:** Recreating the candidate patch atop the trusted authority source is a forward-looking authorized implementation state, not retroactive authorization of its earlier history.
- **P0-W35-A03:** Repairs, if required, remain inside the accepted T01 mutation surface and exclusions.

### Unknowns

- **P0-W35-U01:** Whether exact-state review will accept, require repair of, or reject the candidate.
- **P0-W35-U02:** Whether owner-machine OD-02 verification will expose a platform-specific defect after CI.
- **P0-W35-U03:** The final T01 enforcement and closeout SHAs do not exist until adjudication completes.

## Requirements

- **P0-W35-R01:** Record canonical main `dc375d923c99b9c754d9b53d601b214b0c8941a5` as the authorization base.
- **P0-W35-R02:** Change the corrected T01 plan to Accepted without representing candidate commit `60367874` as authorized or accepted.
- **P0-W35-R03:** Add a canonical authorization record bound to the exact accepted plan digest, trusted owner, base SHA, time, and bounded scope.
- **P0-W35-R04:** Synchronize current authority documents so T01 is the only authorized P1-S02 package.
- **P0-W35-R05:** Keep all Kiln runtime paths unchanged in this governance package.
- **P0-W35-R06:** After integration, rebase PR #48 onto the trusted authority source and verify the new implementation head.
- **P0-W35-R07:** Do not merge PR #48 without a separate exact-state technical adjudication and completion Evidence.

## Proposed changes

1. Accept the corrected P1-S02-T01 plan prospectively.
2. Add `docs/authorizations/P1-S02-T01.authorization`.
3. Update current authority/status documents to distinguish T01 adjudication from later unauthorized P1-S02 work.
4. Preserve the pre-authorization candidate SHA and non-retroactivity statement.
5. Record governance completion Evidence before integration.

## Expected files or components

- `docs/work/P0-W35-authorize-t01-adjudication.md`
- `docs/work/P1-S02-T01-artifact-evidence-substrate.md`
- `docs/authorizations/P1-S02-T01.authorization`
- `docs/IMPLEMENTATION-AUTHORIZATION.md`
- `AGENTS.md`, `README.md`, `docs/PLANNING.md`, and `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`, `docs/ARCHITECTURE.md`, `docs/RUN-MODEL.md`, and `docs/SLICE-ACCEPTANCE-GATES.md`

## Acceptance criteria

- **P0-W35-AC01:** Current Repository authority names exact main `dc375d923c99b9c754d9b53d601b214b0c8941a5` and authorizes only prospective P1-S02-T01 adjudication and bounded repair.
- **P0-W35-AC02:** The accepted T01 plan and canonical authorization record have matching SHA-256 identity and trusted owner/base/scope fields.
- **P0-W35-AC03:** Every authority document preserves candidate commit `60367874` as premature and non-retroactively unauthorized.
- **P0-W35-AC04:** Every later P1-S02 ticket and aggregate slice remain unauthorized.
- **P0-W35-AC05:** The final governance diff contains no Kiln runtime path.
- **P0-W35-AC06:** Complete Repository CI passes at the exact governance head.

## Deterministic verification

```bash
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
git diff --name-only dc375d923c99b9c754d9b53d601b214b0c8941a5 -- lib test priv mix.exs mix.lock config
```

## Required completion Evidence

- **P0-W35-E01:** exact branch head, PR, and compare from `dc375d923c99b9c754d9b53d601b214b0c8941a5`.
- **P0-W35-E02:** plan digest equals authorization `plan_sha256`.
- **P0-W35-E03:** preflight and protected authorization regression pass.
- **P0-W35-E04:** full exact-head CI pass.
- **P0-W35-E05:** empty runtime-path diff.
- **P0-W35-E06:** PR #48 unchanged during governance integration and later rebased only after authority reaches main.

## Explicit exclusions

- No Kiln runtime, test, migration, schema, dependency, or configuration change.
- No retroactive authorization or acceptance of candidate commit `60367874`.
- No authorization for P1-S02-T02 or later, aggregate P1-S02 acceptance, Wave B, or merge of PR #48.
- No repair of PR #48 before this authority integrates on canonical main.

## Completion record

**Result:** Governance intent integrated, but the authorization record was invalid at the P0-W35 merge and is superseded by P0-W36.

### Exact history

- Authorization base: `dc375d923c99b9c754d9b53d601b214b0c8941a5`.
- Initial authority head: `35045baa22be86ee182236eaca98d70edc5a9150`; its record correctly used plan digest `7a064766037e1a046f93c6bf82fa8920530aafe943db6933418330c8f43add33`, and CI run [31293458242](https://github.com/jenksed/kiln/actions/runs/31293458242) passed.
- A flawed local verification materialized the plan with one extra newline and falsely reported digest `3ce600f0…`.
- Incorrect-digest head: `f25a2a912576d5f81b472407fae28b15244833bb`; CI run [31293535726](https://github.com/jenksed/kiln/actions/runs/31293535726) passed because a P0 planning branch does not consume the T01 authorization record.
- Final P0-W35 head: `ed116085a11b37d9c86220265fab0b35ec3ee635`; CI run [31293601378](https://github.com/jenksed/kiln/actions/runs/31293601378) passed with the same invalid record.
- P0-W35 merge: `d26449e41eb97a316fa6bae4442418397ab29cd3`.
- First rebased PR #48 head: `01d4258c6abc9f53f0ddb1fb5e3999734af1dbca`; CI run [31293701028](https://github.com/jenksed/kiln/actions/runs/31293701028) correctly failed preflight because `plan_sha256` did not match the exact committed plan.
- Exact committed plan SHA-256 recomputed from the GitHub blob's base64-decoded bytes: `7a064766037e1a046f93c6bf82fa8920530aafe943db6933418330c8f43add33`.
- P0-W36 corrects the active record and this historical completion Evidence before adjudication continues.

### Acceptance status

| Criterion | Status | Evidence | Result |
| --- | --- | --- | --- |
| P0-W35-AC01 | Pass | P0-W35-E01 | prospective T01-only scope and exact base were recorded |
| P0-W35-AC02 | Fail at merge | P0-W35-E02 | active record contained `3ce600f0…`, not the exact plan digest `7a064766…` |
| P0-W35-AC03 | Pass | P0-W35-E01 | candidate `60367874…` remained premature and non-retroactive |
| P0-W35-AC04 | Pass | P0-W35-E01 | later P1-S02 work remained unauthorized |
| P0-W35-AC05 | Pass | P0-W35-E05 | governance diff contained no runtime path |
| P0-W35-AC06 | Fail as an authorization package | PR #48 CI 31293701028 | planning CI was green, but the first authorized consumer rejected the record |

### Boundary

No runtime implementation passed under the invalid P0-W35 record. PR #48 remains unaccepted and unmerged. P0-W36 must integrate a byte-correct record before PR #48 is rebased again or repaired.
