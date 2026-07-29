# P0-W29: Final Wave A adjudication and authorization

**Document type:** Implementation plan  
**Status:** In progress  
**Parent slice:** None  
**Branch:** `work/p0-w29-wave-a-adjudication`  
**Depends on:** Prompt 6-A integrated; independent Prompt 7-A review complete

## Objective

Adjudicate the independent Wave A review, correct confirmed authority and conformance defects, create the exact P1-S01 implementation handoff, and issue or withhold bounded development authorization without implementing product behavior.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| Prompt 6-A is integrated | PR 34 and merge commit | Repository history | `57a5790d2266cf1ab59f107d0b429c31c618e0ae` |
| Prompt 6-A exact head passed CI | GitHub Actions | CI run `30425270052` | `7b9afe5552ca0d336d343d4bfbe17ce7d14cc955` |
| Provider and SQLite evidence corrections are integrated | PR 35 and synchronized Prompt 6-A commits | Repository history | current `main` |
| Runtime product behavior remains substantially absent | `lib/`, `mix.exs` | Repository inspection | current `main` |
| Prompt 6-A work record remains stale | `docs/work/P0-W28-wave-a-conformance.md` | Repository inspection | current `main` |
| Active architecture summaries conflict with focused lifecycle and Receipt authority | active docs compared with P0-W21 through P0-W25 | Repository inspection | current `main` |
| Current fixture validator is semantic, not full Draft 2020-12 validation | `scripts/validate_first_month_contracts.py` | Repository inspection | current `main` |

## Assumptions and unknowns

### Assumptions

- **P0-W29-A01:** `jsonschema` 4.26.0 is a maintained project-scoped Draft 2020-12 validator suitable for conformance-only CI.
- **P0-W29-A02:** The focused W21 through W25 documents remain the subject authorities; active summaries should link to them rather than duplicate their full rules.
- **P0-W29-A03:** P1-S01 can begin without a provider, Repository source disclosure, Patch mutation, registered external Command, product Receipt, or release package.

### Unknowns

- **P0-W29-U01:** Exact owner-machine SQLite and filesystem behavior remains implementation Evidence for P1-S01-T02.
- **P0-W29-U02:** Exact MiniMax M3 endpoint compatibility remains implementation Evidence for a later P1-S02 provider ticket.
- **P0-W29-U03:** Exact macOS process-group helper behavior remains implementation Evidence for a later authorized Command ticket.

## Requirements

- **P0-W29-R01:** The adjudication shall record the exact entry-gate Evidence and every accepted, rejected, or narrowed review finding.
- **P0-W29-R02:** The Repository shall run both semantic contract validation and pinned Draft 2020-12 Schema validation.
- **P0-W29-R03:** Active architecture and planning summaries shall not contradict P0-W21 through P0-W25.
- **P0-W29-R04:** Ticket and slice closeout records shall not be called product Receipts before committed product completion.
- **P0-W29-R05:** MiniMax M3 shall remain the accepted provider model while exact live compatibility remains a later acceptance gate.
- **P0-W29-R06:** Prompt 6-A scaffolding shall be retained, revised, removed, or deferred with an explicit disposition.
- **P0-W29-R07:** The final handoff shall define exact sequential P1-S01 tickets and gates.
- **P0-W29-R08:** The final authorization shall permit no product implementation until this branch merges at an exact green head.
- **P0-W29-R09:** Wave B, Child Runs, and broad implementation shall remain blocked.

## Security boundary

Allowed:

- documentation and authority reconciliation;
- conformance-only Schema validation dependencies and scripts;
- fixture metadata;
- CI and local validation wiring;
- P1 ticket plans;
- removal of misleading conformance-only exports or tests.

Denied:

- SQLite state creation or migration execution;
- provider network calls;
- credential access;
- Repository source disclosure;
- source mutation;
- Patch application;
- external Command execution or native helper execution;
- Evidence completion or product Receipt sealing;
- CLI product behavior;
- release packaging;
- Child or Wave B implementation.

## Proposed changes

1. Close Prompt 6-A accurately.
2. Add pinned Draft 2020-12 Schema validation beside the semantic validator.
3. Reconcile active architecture, Run, Session, roadmap, slice, gate, and template authority.
4. Correct MiniMax M3 evidence wording using current official model documentation.
5. Disposition Prompt 6-A scaffolds and remove misleading or namespace-locking elements.
6. Create exact P1-S01-T01 through P1-S01-T05 plans.
7. Create the final adjudication and authorization authority.
8. Run exact-head validation and open one draft pull request.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `docs/WAVE-A-ADJUDICATION-AND-AUTHORIZATION.md` | final review and authorization authority | Proposed |
| `docs/work/P0-W28-wave-a-conformance.md` | exact integrated closeout | Proposed |
| `requirements/conformance.txt` | pinned external Schema validator | Proposed |
| `scripts/validate_json_schema_contracts.py` | Draft 2020-12 validation | Proposed |
| conformance fixtures and semantic validator | validation disposition metadata | Proposed |
| CI and `scripts/check` | recurring dual validation | Proposed |
| active architecture and planning summaries | focused-authority reconciliation | Proposed |
| work-plan template | implementation Evidence manifest terminology | Proposed |
| `docs/work/P1-S01-T01-*.md` through `T05` | exact authorized ticket plans | Proposed |

## Acceptance criteria

- **P0-W29-AC01**
  - **Given** current `main`
  - **When** the entry gate is evaluated
  - **Then** PR 34, its exact head and CI, PR 35, current main, and absent runtime behavior are recorded exactly
  - **Evidence:** final adjudication document and Repository history
- **P0-W29-AC02**
  - **Given** the active Schema and fixtures
  - **When** both validators run
  - **Then** the Schema is valid and every positive and negative fixture matches its declared Schema and semantic disposition
  - **Evidence:** validation command output
- **P0-W29-AC03**
  - **Given** active authority documents
  - **When** reviewed against W21 through W25
  - **Then** conflicting lifecycle, Receipt, fallback, shell, Evidence, Child, TUI, worktree, and delegation statements are corrected or explicitly subordinated
  - **Evidence:** exact diff and authority links
- **P0-W29-AC04**
  - **Given** Prompt 6-A scaffolding
  - **When** each scaffold is adjudicated
  - **Then** every scaffold has Retain, Revise, Remove, or Defer disposition and no scaffold claims product runtime
  - **Evidence:** adjudication matrix and tests
- **P0-W29-AC05**
  - **Given** the final implementation handoff
  - **When** development begins after merge
  - **Then** only P1-S01-T01 through T05 can run in exact dependency order with explicit effects, gates, and exclusions
  - **Evidence:** accepted ticket plans and authorization section
- **P0-W29-AC06**
  - **Given** the exact final branch head
  - **When** full validation and CI run
  - **Then** every required check passes and no product runtime was implemented
  - **Evidence:** exact CI run and compare

## Deterministic verification

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

All commands must exit zero. The Schema validator must run without network access after its pinned package is installed.

## Demo contribution

```text
No product demo. This pass creates the executable authorization boundary for P1-S01.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P0-W29-E01 | P0-W29-AC01 | PR, commit, CI, and runtime inventory references |
| P0-W29-E02 | P0-W29-AC02 | dual validator output and fixture counts |
| P0-W29-E03 | P0-W29-AC03 | authority reconciliation compare |
| P0-W29-E04 | P0-W29-AC04 | scaffold disposition and conformance tests |
| P0-W29-E05 | P0-W29-AC05 | five ticket plans and authorization matrix |
| P0-W29-E06 | P0-W29-AC06 | exact final-head CI and compare |

## Explicit exclusions

- No product implementation.
- No Exqlite, HTTP, CLI, JSON runtime, or process dependency in the Elixir application.
- No P1 code, database, migration, provider adapter, Repository reader, Patch engine, Command runner, helper binary, Evidence evaluator, Receipt sealer, release, or installer.
- No P0-W26, P0-W27, Child, Scout, Verifier, Attention, TUI, or Wave B work.
- No automatic merge.

## Completion record

**Result:** Implemented but unverified

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W29-AC01 | Pending | P0-W29-E01 | pending |
| P0-W29-AC02 | Pending | P0-W29-E02 | pending |
| P0-W29-AC03 | Pending | P0-W29-E03 | pending |
| P0-W29-AC04 | Pending | P0-W29-E04 | pending |
| P0-W29-AC05 | Pending | P0-W29-E05 | pending |
| P0-W29-AC06 | Pending | P0-W29-E06 | pending |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| pending | pending | pending |

### Demo and slice status

- Ticket demo contribution: Not applicable
- Parent slice gate affected: P1-S01 authorization only
- Slice verification manifest updated: Not applicable
- Slice completion claimed: No

### Failures and warnings

- Build authorization is not effective until this branch merges at an exact green head.

### Remaining unknowns and exclusions

- P1-S02 and Wave B remain unauthorized.

### Repository state

- Commit: pending
- Branch: `work/p0-w29-wave-a-adjudication`
- Diff reviewed: No
- Exact CI run: pending
- Parent slice status after merge: unchanged
