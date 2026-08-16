# P0-W37: Close rejected P1-S02-T01 adjudication

**Document type:** Implementation plan
**Status:** Accepted
**Parent work:** P0-W series (governance / development-process authority)
**Branch:** `work/p0-w37-close-rejected-t01-adjudication`
**Depends on:** P0-W36 merged at `d0f9cf424297d1b55f6d3d2bad9478555ebe03ed`; PR #48 adjudicated and rejected at `7ba158bddff76ade9aca79cb8501e675bd0cded9`

## Objective

Record PR #48's rejection in Repository authority, remove the consumed T01 authorization record, return P1-S02 to an explicit unauthorized planning state, and preserve the exact technical findings and CI Evidence without changing Kiln runtime files.

## Observed current state

| Observation | Evidence | Result |
| --- | --- | --- |
| Current main | `d0f9cf424297d1b55f6d3d2bad9478555ebe03ed` | observed |
| Authorized PR #48 head | `7ba158bddff76ade9aca79cb8501e675bd0cded9` | exact adjudication state |
| Exact-state CI | [31294035484](https://github.com/jenksed/kiln/actions/runs/31294035484) | green |
| Technical adjudication | PR #48 owner comment/body | rejected |
| PR state | closed, unmerged | observed |
| Runtime on main | no T01 files integrated | unchanged |

## Assumptions and unknowns

### Assumptions

- **P0-W37-A01:** The owner's instruction to accept, repair, or reject authorizes recording the rejection and consuming its adjudication authority.
- **P0-W37-A02:** Removing the active record is the clearest deterministic revocation; Git history preserves the consumed authorization.
- **P0-W37-A03:** A replacement T01 requires a corrected plan and new authorization rather than reopening the rejected implementation.

### Unknowns

- **P0-W37-U01:** The corrected Evidence result/status and contradiction model require owner adjudication.
- **P0-W37-U02:** Persistence ownership and final Artifact API shape require a replacement plan.

## Requirements

- **P0-W37-R01:** Record PR #48 as rejected at exact head `7ba158bd` with CI run `31294035484`.
- **P0-W37-R02:** Remove the active P1-S02-T01 authorization record.
- **P0-W37-R03:** Mark the T01 plan rejected and record criterion-level failures and next planning work.
- **P0-W37-R04:** Synchronize current authority/status documents so no P1-S02 work is authorized.
- **P0-W37-R05:** Preserve every candidate and failed/corrected authorization SHA as historical Evidence.
- **P0-W37-R06:** Change no Kiln runtime path.

## Proposed changes

1. Remove `docs/authorizations/P1-S02-T01.authorization`.
2. Close the T01 plan with the exact rejection record.
3. Update current authority and planning documents.
4. Add P0-W37 completion Evidence before integration.

## Expected files or components

- `docs/work/P0-W37-close-rejected-t01-adjudication.md`
- `docs/work/P1-S02-T01-artifact-evidence-substrate.md`
- `docs/IMPLEMENTATION-AUTHORIZATION.md`
- current authority/status documents
- removal of `docs/authorizations/P1-S02-T01.authorization`

## Acceptance criteria

- **P0-W37-AC01:** No active P1-S02 authorization record remains.
- **P0-W37-AC02:** Current authority identifies PR #48 as rejected, closed, unmerged, and non-retroactive.
- **P0-W37-AC03:** The T01 record names every blocking contract defect and the required governance return.
- **P0-W37-AC04:** All later P1-S02 work remains unauthorized.
- **P0-W37-AC05:** Exact-head CI passes and the runtime-path diff is empty.

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
test ! -e docs/authorizations/P1-S02-T01.authorization
git diff --name-only d0f9cf424297d1b55f6d3d2bad9478555ebe03ed -- lib test priv mix.exs mix.lock config
```

## Required completion Evidence

- **P0-W37-E01:** exact PR #48 head, state, and CI.
- **P0-W37-E02:** absent active authorization record.
- **P0-W37-E03:** synchronized authority compare.
- **P0-W37-E04:** full exact-head CI.
- **P0-W37-E05:** empty runtime-path diff.

## Explicit exclusions

- No T01 runtime repair, replacement plan, implementation, merge, or branch deletion.
- No later P1-S02 authorization.
- No deletion of Git history or negative Evidence.
- No Kiln runtime, test, migration, schema, dependency, or configuration change.

## Completion record

**Result:** Rejected T01 adjudication closed in Repository authority and verified. No active P1-S02 authorization remains; no runtime path changed.

### Verified Repository state

- Base: `d0f9cf424297d1b55f6d3d2bad9478555ebe03ed`.
- Branch: `work/p0-w37-close-rejected-t01-adjudication`.
- Pull request: PR #52.
- Governance enforcement head: `1b34f15f43b01ce7684ae9216a0864efd0b03df8`.
- Exact-head CI: [31294256864](https://github.com/jenksed/kiln/actions/runs/31294256864), success.
- Rejected PR #48 head: `7ba158bddff76ade9aca79cb8501e675bd0cded9`.
- Rejected PR #48 CI: [31294035484](https://github.com/jenksed/kiln/actions/runs/31294035484), green but criteria-insufficient.
- PR #48 state: closed, unmerged.
- Active T01 record: removed.
- Runtime-path diff: empty.
- Final closeout commit: documentation-only and must receive fresh full CI before integration.

### Acceptance status

| Criterion | Status | Evidence | Result |
| --- | --- | --- | --- |
| P0-W37-AC01 | Pass | P0-W37-E02 | `docs/authorizations/P1-S02-T01.authorization` removed |
| P0-W37-AC02 | Pass | P0-W37-E01, E03 | current authority names exact rejected head, closed/unmerged state, and non-retroactivity |
| P0-W37-AC03 | Pass | T01 completion record | result, persistence, classification, TTL, and API blockers recorded |
| P0-W37-AC04 | Pass | P0-W37-E03 | every P1-S02 ticket and aggregate slice explicitly unauthorized |
| P0-W37-AC05 | Pass | P0-W37-E04, E05 | full CI green and runtime-path diff empty |

### Completion Evidence

- **P0-W37-E01:** PR #48 closed at `7ba158bddff76ade9aca79cb8501e675bd0cded9`; exact CI run `31294035484` passed; owner adjudication rejected the candidate without merge.
- **P0-W37-E02:** the active T01 authorization record is deleted in the governance compare; consumed authority remains preserved in Git history.
- **P0-W37-E03:** `AGENTS.md`, README, Planning, Roadmap, Architecture, Run Model, Implementation Slices, Slice Gates, T01 plan, and implementation-authorization authority agree that no P1-S02 work is authorized.
- **P0-W37-E04:** CI run `31294256864` passed preflight/regressions, semantic and JSON Schema validation, agent assets, formatting, warnings-as-errors compilation, cycle checks, direct tests, P1-S01 aggregate gate/upload, and Vale.
- **P0-W37-E05:** compare from `d0f9cf4…` contains only governance/status documents and deletion of the authorization record; no `lib/`, `test/`, `priv/`, `mix.exs`, `mix.lock`, or `config/` path.

### Required next action

Create a governance-only replacement T01 planning package that resolves the five recorded blockers. Do not reopen PR #48 or begin runtime implementation. A later owner decision must accept the corrected plan and issue a new exact authorization record.
