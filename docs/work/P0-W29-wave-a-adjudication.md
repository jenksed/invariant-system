# P0-W29: Final Wave A adjudication and authorization

**Document type:** Implementation plan and closeout record  
**Status:** Complete and verified on branch  
**Parent slice:** None  
**Branch:** `work/p0-w29-wave-a-adjudication`  
**Depends on:** Prompt 6-A integrated; independent Prompt 7-A review complete  
**Build authorization:** Vertical Slice Authorized after this branch merges at an exact green head

## Objective

Adjudicate the independent Wave A review, correct confirmed authority and conformance defects, create the exact P1-S01 implementation handoff, and issue a bounded development authorization without implementing product behavior.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| Prompt 6-A is integrated | PR 34, merge `57a5790d2266cf1ab59f107d0b429c31c618e0ae` | Repository history | 2026-07-29 |
| Prompt 6-A exact head passed CI | run `30425270052` on `7b9afe5552ca0d336d343d4bfbe17ce7d14cc955` | GitHub Actions | 2026-07-29 |
| Provider and SQLite evidence corrections are integrated | PR 35, merge `d76402a30e178d577d363384750baffd062cf9ef` and synchronized PR 34 commits | Repository history | 2026-07-29 |
| Runtime product behavior remained substantially absent | bootstrap and conformance modules only | Repository inspection | entry `main` |
| Prompt 6-A closeout was stale | prior `docs/work/P0-W28-wave-a-conformance.md` | Repository inspection | entry `main` |
| Active architecture summaries conflicted with focused lifecycle and Receipt authority | active docs compared with P0-W21 through P0-W25 | Repository inspection | entry `main` |
| Existing fixture validation was semantic, not full Draft 2020-12 validation | `scripts/validate_first_month_contracts.py` | Repository inspection | entry `main` |

## Assumptions and unknowns

### Assumptions

- **P0-W29-A01:** Pinned `jsonschema==4.26.0` is suitable for project-scoped Draft 2020-12 conformance validation.
- **P0-W29-A02:** Focused P0-W21 through P0-W25 documents remain subject authorities; active summaries should link to and summarize them.
- **P0-W29-A03:** P1-S01 can begin without provider, Repository source disclosure, Patch mutation, registered external Commands, product Receipt, or release packaging.

### Unknowns

- **P0-W29-U01:** Exact owner-machine SQLite and filesystem behavior remains P1-S01-T02 and T05 Evidence.
- **P0-W29-U02:** Exact MiniMax M3 endpoint compatibility remains later P1-S02 Evidence.
- **P0-W29-U03:** Exact macOS process-group helper behavior remains later authorized Command Evidence.

## Requirements

- **P0-W29-R01:** Record exact entry-gate Evidence and every accepted, rejected, or narrowed review finding.
- **P0-W29-R02:** Run semantic contract validation and pinned Draft 2020-12 Schema validation.
- **P0-W29-R03:** Remove or subordinate active authority contradictions with P0-W21 through P0-W25.
- **P0-W29-R04:** Separate ticket and slice closeout Evidence from post-completion product Receipts.
- **P0-W29-R05:** Retain MiniMax M3 while making exact live compatibility a later implementation gate.
- **P0-W29-R06:** Assign Retain, Revise, Remove, or Defer to every Prompt 6-A scaffold.
- **P0-W29-R07:** Define exact sequential P1-S01 tickets, gates, effects, and exclusions.
- **P0-W29-R08:** Make authorization effective only after exact-head green merge.
- **P0-W29-R09:** Keep Wave B, Child Runs, and broad implementation blocked.

## Security boundary

Allowed:

- documentation and authority reconciliation;
- conformance-only Schema validation dependency and scripts;
- fixture disposition metadata;
- CI and local validation wiring;
- accepted P1 ticket plans;
- removal of misleading conformance exports or namespace-locking tests.

Denied:

- SQLite state creation or migration execution;
- provider network or credential access;
- Repository source disclosure or mutation;
- Patch or external Command execution;
- native helper execution;
- criterion completion Evidence or product Receipt sealing;
- product CLI behavior or release packaging;
- Child or Wave B implementation.

## Proposed changes

The proposed changes were completed:

1. Closed Prompt 6-A accurately.
2. Added pinned Draft 2020-12 Schema validation beside semantic validation.
3. Reconciled active architecture, Run, Session, roadmap, slice, gate, planning, branching, and template authority.
4. Corrected MiniMax M3 evidence wording from current official model documentation.
5. Dispositioned every Prompt 6-A scaffold and removed misleading or namespace-locking elements.
6. Created exact P1-S01-T01 through P1-S01-T05 plans.
7. Created the final adjudication and authorization authority.
8. Opened draft pull request 36 and ran exact-head CI.

## Expected files or components

| Path or component | Result |
| --- | --- |
| `docs/WAVE-A-ADJUDICATION-AND-AUTHORIZATION.md` | Added final authority |
| `docs/work/P0-W28-wave-a-conformance.md` | Corrected integrated closeout |
| `requirements/conformance.txt` | Added pinned validator |
| `scripts/validate_json_schema_contracts.py` | Added Draft 2020-12 validation |
| negative fixtures | Added Schema and semantic dispositions |
| CI and `scripts/check` | Added dual validation |
| active architecture and planning summaries | Reconciled with focused authority |
| implementation-plan and branching authority | Replaced product-Receipt misuse with verification-manifest terminology |
| five `P1-S01` ticket plans | Added accepted sequential handoff |
| conformance module and tests | Removed product-like status export and namespace lock-in |

## Acceptance criteria

- **P0-W29-AC01:** Pass. Entry-gate PRs, heads, merge, CI, and runtime inventory are recorded in the final adjudication.
- **P0-W29-AC02:** Pass. The Schema validates under Draft 2020-12; all positives pass; all negatives match declared Schema and semantic disposition.
- **P0-W29-AC03:** Pass. Active lifecycle, Receipt, fallback, shell, Evidence, Child, TUI, worktree, and delegation conflicts were removed or explicitly subordinated.
- **P0-W29-AC04:** Pass. Every Prompt 6-A scaffold has an explicit disposition and no scaffold claims product runtime.
- **P0-W29-AC05:** Pass. Five accepted P1-S01 ticket plans define exact sequential scope and exclusions.
- **P0-W29-AC06:** Pass on review head. Full CI run `30433204279` returned a success conclusion on `07ee931d0871f4906c5114b3e0fbe585853890fa`; the closeout head requires one final exact-head run.

## Deterministic verification

The branch validation path is:

```bash
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

CI run `30433204279` returned a success conclusion on review head `07ee931d0871f4906c5114b3e0fbe585853890fa`.

The first CI run, `30433002819`, exposed a missing plan heading and one non-measurable prose claim. Both were corrected without weakening preflight or Vale.

## Demo contribution

```text
No product demo. Prompt 8-A creates the executable authorization boundary for P1-S01.
```

## Required completion Evidence

| Evidence ID | Criterion | Result |
| --- | --- | --- |
| P0-W29-E01 | P0-W29-AC01 | entry-gate table and Repository history |
| P0-W29-E02 | P0-W29-AC02 | dual validators and fixture dispositions passed |
| P0-W29-E03 | P0-W29-AC03 | 26-file authority reconciliation compare |
| P0-W29-E04 | P0-W29-AC04 | scaffold disposition matrix and conformance tests |
| P0-W29-E05 | P0-W29-AC05 | five ticket plans and authorization matrix |
| P0-W29-E06 | P0-W29-AC06 | CI `30433204279` on review head; final closeout-head CI pending |

## Explicit exclusions

- No product implementation.
- No Exqlite, HTTP, CLI, JSON runtime, or process dependency in the Elixir application.
- No P1 code, database, migration, provider adapter, Repository reader, Patch engine, Command runner, helper binary, Evidence evaluator, Receipt sealer, release, or installer.
- No P0-W26, P0-W27, Child, Scout, Verifier, Attention, TUI, or Wave B work.
- No automatic merge.

## Completion record

**Result:** Complete and verified on branch

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W29-AC01 | Pass | P0-W29-E01 | exact entry gate recorded |
| P0-W29-AC02 | Pass | P0-W29-E02 | dual validation passed |
| P0-W29-AC03 | Pass | P0-W29-E03 | active authorities reconciled |
| P0-W29-AC04 | Pass | P0-W29-E04 | scaffolds dispositioned |
| P0-W29-AC05 | Pass | P0-W29-E05 | bounded P1-S01 handoff complete |
| P0-W29-AC06 | Pass on review head | P0-W29-E06 | final closeout-head CI follows this update |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| complete CI workflow | 0 | GitHub Actions run `30433204279` |

### Demo and slice status

- Ticket demo contribution: Not applicable
- Parent slice gate affected: P1-S01 authorization only
- Slice verification manifest updated: Not applicable
- Slice completion claimed: No

### Failures and warnings

- Authorization is not effective before this PR merges.
- The exact closeout head must pass CI after this record update.

### Remaining unknowns and exclusions

- P1-S02 and Wave B remain unauthorized.
- Owner-machine SQLite and filesystem facts remain implementation Evidence.
- MiniMax and macOS helper behavior remain later Evidence.

### Repository state

- Review head: `07ee931d0871f4906c5114b3e0fbe585853890fa`
- Branch: `work/p0-w29-wave-a-adjudication`
- Pull request: 36
- Diff reviewed: Yes
- Review-head CI: `30433204279`
- Exact closeout-head CI: pending
- Parent slice status after merge: P1-S01 authorized only
