# P0-W38: Correct the rejected P1-S02-T01 plan

**Document type:** Implementation plan
**Status:** Accepted
**Parent work:** P0-W series (governance / development-process authority)
**Branch:** `work/p0-w38-correct-rejected-t01-plan-v2`
**Depends on:** P0-W37 merged at `f9b5a312ac31ee4015025a87bcd3cec199b12297`; PR #48 rejected and closed without merge at `7ba158bddff76ade9aca79cb8501e675bd0cded9`

## Objective

Replace the rejected P1-S02-T01 contract with one coherent proposed plan that resolves its Evidence-result, persistence, protected-classification, freshness-boundary, Artifact-API, accepted-authority reconciliation, currentness, and bounds defects while preserving PR #48 as rejected history, changing no Kiln runtime path, and granting no implementation authority.

## Observed current state

The original "Observed current state" snapshot was captured at the pre-P0-W39 historical base `f9b5a312ac31ee4015025a87bcd3cec199b12297` on 2026-08-09. The historical snapshot remains accurate for that base. The current state below is the locally reconciled view against the current canonical main `9f09ea2400ea73257c1fb2efc566ee165a4a1181`.

Historical snapshot at pre-P0-W39 base `f9b5a312...` (2026-08-09):

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| Canonical `main` (at historical snapshot time) | `f9b5a312ac31ee4015025a87bcd3cec199b12297` | `git ls-remote`, fresh clone | 2026-08-09 |
| Latest governance closeout (at historical snapshot time) | PR #52 merged as `f9b5a312ac31ee4015025a87bcd3cec199b12297` | GitHub PR metadata and Git history | 2026-08-09 |
| Rejected candidate | PR #48 closed, unmerged, at `7ba158bddff76ade9aca79cb8501e675bd0cded9` | GitHub PR metadata | 2026-08-09 |
| Rejected candidate CI | Run `31294035484` passed but did not satisfy the accepted criteria | PR #48 disposition | 2026-08-09 |

Current state at canonical `main` = `9f09ea2400ea73257c1fb2efc566ee165a4a1181`:

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| Canonical `main` (current) | `9f09ea2400ea73257c1fb2efc566ee165a4a1181` | `git rev-parse origin/main` | current local integration |
| P0-W39 is integrated | `9f09ea2 Merge pull request #55 from jenksed/work/p0-w39-adopt-project-arsenal-dependency` | `git log origin/main` | current |
| P0-W39 scope | development tooling and a pinned reference dependency only; no P1-S02 runtime implementation | `git diff f9b5a312...9f09ea2 -- lib test priv config mix.exs mix.lock` returns empty | current |
| Current implementation authority | No P1-S02 authorization record exists; every P1-S02 ticket and slice is unauthorized | `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/authorizations/` | `9f09ea2` |
| Runtime on `main` | No PR #48 runtime file is integrated; no P1-S02 runtime path exists | compare and runtime-path inspection against `9f09ea2` | current |

## Assumptions and unknowns

### Assumptions

- **P0-W38-A01:** The owner's instruction authorizes this governance-only plan correction and publication, but not acceptance of the corrected T01 plan or implementation of it.
- **P0-W38-A02:** The same T01 plan path remains the governing path so a later authorization can bind one unambiguous plan digest.
- **P0-W38-A03:** Rejected PR #48 remains negative Evidence and is not a source of accepted implementation.

### Unknowns

- **P0-W38-U01:** Whether the owner will accept, revise, or reject the corrected T01 plan remains undecided.
- **P0-W38-U02:** The future authorization base, authorization time, implementation branch, and replacement implementation head do not exist yet.
- **P0-W38-U03:** Exact implementation performance and crash-window behavior remain unverified until a fresh authorized implementation supplies runtime Evidence.

## Requirements

- **P0-W38-R01:** Correct the T01 plan as a complete domain and persistence contract, not as five isolated sentence edits.
- **P0-W38-R02:** Define one explicit Evidence result field and preserve P0-W24's subject, Repository, host/environment, Command-result, plural Artifact, freshness, completeness, and contradiction contract through an exact canonical record-plus-view representation.
- **P0-W38-R03:** Define the runtime owner and durable path for Artifact bytes, Artifact metadata, and Evidence records.
- **P0-W38-R04:** Define contradiction, stale, incomplete, and integrity semantics, persistence effects, atomic failure behavior, and deterministic acceptance tests.
- **P0-W38-R05:** Reconcile the rejected candidate's invalid TTL behavior by preserving P0-W24's four state-based freshness rules, forbidding `time_bound` and TTL persistence, and testing application and direct SQL rejection.
- **P0-W38-R06:** Resolve the Artifact public write API to exactly `Kiln.Artifact.Store.put/2` and define both arguments.
- **P0-W38-R07:** Reconcile identity, plural association, transaction ownership, idempotency, migrations, rollback, schemas, canonical bytes, P0-W24, the active conformance projection, and completion Evidence.
- **P0-W38-R08:** Preserve the distinction between proposed planning, owner acceptance, implementation authorization, implementation, verification, and acceptance.
- **P0-W38-R09:** Change no runtime source, test, migration, schema, dependency, or configuration path.
- **P0-W38-R10:** Separate persistent Evidence request identity and unseen-key admission from pure currentness re-evaluation, with exact replay ordering and an integrity-checked read API.
- **P0-W38-R11:** Fix numeric Artifact and metadata bounds, direct-persistence enforcement, and deterministic no-truncation overflow behavior.

## Security boundary

Allowed:

- governance and planning Markdown;
- correction of the rejected T01 plan at its existing path;
- synchronization of current governance status and exact-next-action text;
- deterministic Repository validation and read-only inspection of rejected PR #48.

Denied:

- `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, or `mix.lock` changes;
- creation of an authorization record;
- acceptance of the corrected T01 plan;
- reuse, restoration, rebase, or modification of PR #48;
- Artifact, Evidence, migration, provider, Repository-read, Patch, Command, Gate, completion, Receipt, Child, TUI, or Wave B runtime work;
- merge of this pull request.

Authority inputs are canonical `origin/main`, the accepted authority order in `AGENTS.md`, PR #48's rejection record, and PR #52's governance closeout. This package performs no product network, secret, process, or filesystem effect beyond normal local Git and publication of the governance diff.

## Proposed changes

1. Rewrite the existing T01 plan as a proposed replacement contract while retaining the exact PR #48 rejection history.
2. Define exact Artifact and Evidence records, accepted binding projection, persistence ownership, byte placement, API signatures, transaction boundaries, replay ordering, pure currentness, and migration behavior.
3. Define protected outcomes and their durable effects so a false pass or dangling Evidence association cannot commit.
4. Fix Artifact and metadata limits plus exact overflow behavior at application and applicable database boundaries.
5. Synchronize current authority documents to say that the correction is proposed, owner acceptance is pending, and no implementation is authorized.
6. Record deterministic validation and an empty runtime-path diff in this plan's completion record.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `docs/work/P0-W38-correct-rejected-t01-plan.md` | governance package and completion Evidence | Proposed |
| `docs/work/P1-S02-T01-artifact-evidence-substrate.md` | coherent corrected T01 contract, proposed only | Proposed |
| `AGENTS.md` | exact next authority state | Proposed |
| `README.md` | current implementation and planning status | Proposed |
| `docs/PLANNING.md` | exact next owner decision | Proposed |
| `docs/ROADMAP.md` | exact next action | Proposed |
| `docs/IMPLEMENTATION-AUTHORIZATION.md` | proposed-plan/no-authorization result | Proposed |
| `docs/IMPLEMENTATION-SLICES.md` | corrected-plan status without authorization | Proposed |

## Acceptance criteria

- **P0-W38-AC01**
  - **Given** PR #48's five blocking findings and accepted Evidence authority;
  - **When** the corrected T01 plan is reviewed;
  - **Then** Evidence has one explicit result vocabulary, a real owned persistence path, every accepted P0-W24 binding, and an exact record-plus-currentness projection into the active first-month Schema.
  - **Evidence:** T01 requirements, record shapes, APIs, and acceptance criteria.
- **P0-W38-AC02**
  - **Given** contradiction, stale, incomplete, and integrity cases;
  - **When** the corrected protected matrix is reviewed;
  - **Then** each case has exact semantics, persistence effects, failure behavior, and tests that prevent false or dangling durable Evidence.
  - **Evidence:** T01 protected-classification contract and AC08 through AC11.
- **P0-W38-AC03**
  - **Given** application and direct-SQL persistence paths;
  - **When** freshness and association constraints are reviewed;
  - **Then** only the four accepted state-based rules can commit, no TTL has a durable representation, and missing Artifact references cannot commit.
  - **Evidence:** T01 migration contract and AC06, AC09, and AC11.
- **P0-W38-AC04**
  - **Given** the corrected public API;
  - **When** Artifact persistence is planned;
  - **Then** the only public write function is `Kiln.Artifact.Store.put/2`, with a ready Store and one typed request as its exact arguments.
  - **Evidence:** T01 API contract and AC04.
- **P0-W38-AC05**
  - **Given** the final branch diff;
  - **When** authority language and paths are inspected;
  - **Then** no P1-S02 implementation is accepted or authorized and no runtime path changed.
  - **Evidence:** authority scans and empty runtime-path diff.
- **P0-W38-AC06**
  - **Given** the exact branch head;
  - **When** the complete governance validation suite runs;
  - **Then** every applicable deterministic check passes.
  - **Evidence:** command results and exact-head CI.
- **P0-W38-AC07**
  - **Given** an exact Evidence retry after Repository, host, Command, Artifact, or invalidation state changes;
  - **When** the persistence and currentness contracts are reviewed;
  - **Then** persistent identity replays before unseen-key admission and `Currentness.evaluate/2` reports the changed applicability without a write or idempotency conflict.
  - **Evidence:** T01 APIs, idempotency ordering, and AC07 through AC09.
- **P0-W38-AC08**
  - **Given** Artifact bytes and all security-relevant metadata at their limit and one unit over;
  - **When** the application and direct-persistence boundaries are reviewed;
  - **Then** every limit is numeric, byte-based where applicable, and paired with exact rejection or explicit upstream truncation behavior.
  - **Evidence:** T01 bounds table, migration contract, and AC13.
- **P0-W38-AC09**
  - **Given** P0-W24 and the active first-month conformance Schema;
  - **When** the corrected T01 representation is compared field by field;
  - **Then** T01 explicitly preserves and maps the accepted contract and does not silently supersede it.
  - **Evidence:** T01 canonical Evidence-view mapping and AC05.

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/check-project-arsenal-dependency
scripts/validate-agent-assets
vale --glob='!{deps,_build,.claude/dependencies}/**' .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
test ! -e docs/authorizations/P1-S02-T01.authorization
git diff --name-only 9f09ea2400ea73257c1fb2efc566ee165a4a1181 -- lib test priv mix.exs mix.lock config
git diff --check 9f09ea2400ea73257c1fb2efc566ee165a4a1181
```

Every command except `scripts/test-agent-preflight` must exit `0` when run from the developer's named checkout. `scripts/test-agent-preflight` has a pre-existing named-branch structural harness defect fixed to a historical W34 branch identity; it exits non-zero from any non-W34 named checkout, including this one, and that single local failure is not P0-W38 regression Evidence. The same script is invoked by CI in a state where the flaw does not manifest; the CI step must pass for merge. The runtime-path diff command must print no path. Exact-head remote CI is external integration Evidence bound to the final candidate head and is recorded in PR and CI metadata, not in this tracked record.

The Vale glob `!{deps,_build,.claude/dependencies}/**` excludes pinned reference-repository content already established by P0-W39 / PR #55 while preserving required Kiln-owned prose validation. The `scripts/check-project-arsenal-dependency` command is included because the current canonical main materializes the pinned Project Arsenal submodule.

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P0-W38-E01 | P0-W38-AC01 | corrected result and persistence contract compare |
| P0-W38-E02 | P0-W38-AC02 | protected-classification matrix compare |
| P0-W38-E03 | P0-W38-AC03 | accepted freshness vocabulary, absent TTL, plural foreign-key, and direct-SQL constraint compare |
| P0-W38-E04 | P0-W38-AC04 | exact `put/2` signature and argument contract |
| P0-W38-E05 | P0-W38-AC05 | authority scan, absent authorization record, and empty runtime-path diff |
| P0-W38-E06 | P0-W38-AC06 | full local validation and exact-head CI |
| P0-W38-E07 | P0-W38-AC07 | persistent-identity, replay-order, read, and pure-currentness contract compare |
| P0-W38-E08 | P0-W38-AC08 | numeric bounds, byte semantics, direct-persistence, and overflow contract compare |
| P0-W38-E09 | P0-W38-AC09 | P0-W24 and active conformance field-by-field reconciliation |

## Explicit exclusions

- No runtime implementation, test, migration, runtime JSON Schema, dependency, or configuration change.
- No owner acceptance of T01 and no implementation authorization record.
- No restoration, rebase, cherry-pick, or reuse of rejected PR #48 code.
- No T02 or later planning authorization.
- No merge of this pull request.

## Completion record

**Result:** Corrected T01 governance contract proposed, amended after blocking review, and historically verified at the pre-P0-W39 amendment head. No T01 plan acceptance or P1-S02 implementation authorization was granted, PR #48 remains rejected, and no runtime path changed. This v2 package is a current-main governance replay against `9f09ea2400ea73257c1fb2efc566ee165a4a1181`; exact-head CI for the final candidate head is external integration Evidence and is recorded in PR and CI metadata.

### Verified Repository state

- Original historical base: `f9b5a312ac31ee4015025a87bcd3cec199b12297` (pre-P0-W39 main; base of PR #53 when opened).
- Current canonical main: `9f09ea2400ea73257c1fb2efc566ee165a4a1181` (post-P0-W39 / PR #55 merge; current target for any rebase).
- Historical predecessor branch: `work/p0-w38-correct-rejected-t01-plan` (PR #53, unmerged, head `e030c61d0d117e46ae80680a42b02325c56dd7c7`).
- Replacement branch: `work/p0-w38-correct-rejected-t01-plan-v2` (this branch; PR to be opened against canonical main).
- Governance enforcement head (historical): `53c6562fa4c4febd6f28fe8927352101e8a6832f`.
- Initial governance CI (historical): runs `31311303234` and `31311421953`, success at the pre-review heads.
- Review-correction head (historical): `cf34adcb97d1cb4483d286abeb77939f6d820fb4`.
- Review-correction exact-head CI (historical): run `31315585161`, success.
- Corrected T01 plan SHA-256 (historical pre-correction-replay): `ae468ff2656c753c908aaddc44a2285b32def044feab52201fa4a5d26f6fe176`. This value is preserved as a historical reference for the pre-P0-W39 amendment.
- Corrected T01 plan SHA-256 (this branch, after the KILN-INV-051 accuracy repair): `fb4dcad0d278ca096c383d835b19dc9bc1d66ca9dc66c7feaddc6daa728ea072`. The T01 plan on this branch incorporates the accuracy repair; its digest therefore differs from the historical pre-correction-replay digest. This is the digest the next authorized T01 implementation plan should match (modulo any further owner-accepted amendments).
- Rejected PR #48 head: `7ba158bddff76ade9aca79cb8501e675bd0cded9`.
- Active T01 authorization record: absent.
- Corrected T01 lifecycle: Proposed, not Accepted.
- Runtime-path diff vs. current canonical main: empty (validated locally against `9f09ea2400ea73257c1fb2efc566ee165a4a1181`).
- Final closeout commit: governance-only; must receive fresh full CI on the replacement branch head before PR readiness.

### Historical vs current Evidence

Historical exact-head Evidence (preserved for provenance):

- Pre-review governance CI: runs `31311303234` and `31311421953`, success at the pre-review heads on the historical base `f9b5a312ac31ee4015025a87bcd3cec199b12297`.
- Review-correction exact-head CI: run `31315585161`, success on review-correction head `cf34adcb97d1cb4483d286abeb77939f6d820fb4`.
- Pre-correction T01 plan SHA-256: `ae468ff2656c753c908aaddc44a2285b32def044feab52201fa4a5d26f6fe176` (historical; the locally reconciled T01 plan in this candidate has a different SHA-256 because it incorporates the KILN-INV-051 accuracy repair).

These runs are valid historical Evidence for their old states. They are not current integration Evidence for the post-P0-W39 repository.

Current-main integration:

- Local reconciliation performed against `9f09ea2400ea73257c1fb2efc566ee165a4a1181`.
- Local merge of PR #53's eight governance-only files applied to a temporary integration worktree at `test/p0-w38-pr53-rebase`, then promoted to the local branch `work/p0-w38-correct-rejected-t01-plan-v2` (this branch).
- Applicable local deterministic checks pass on this branch against current canonical main. The known pre-existing `scripts/test-agent-preflight` named-branch structural harness defect causes that one local invocation to exit non-zero on this developer's named checkout; the same script is invoked by CI in a state where the defect does not manifest and the CI step passes. This package does not modify that harness.
- Exact-head remote CI is external integration Evidence bound to the final candidate head; it must pass for merge. Historical CI does not substitute for current exact-head CI. The actual current head SHA and CI run ID live in PR and CI metadata, not in self-referential tracked content.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W38-AC01 | Pass | P0-W38-E01 | result, accepted bindings, conformance projection, and owned durable persistence are explicit |
| P0-W38-AC02 | Pass | P0-W38-E02 | four protected classifications have exact semantics, effects, failures, and tests |
| P0-W38-AC03 | Pass | P0-W38-E03 | four accepted freshness rules, absent TTL, result/completeness, and plural Artifact association have application and SQLite boundaries |
| P0-W38-AC04 | Pass | P0-W38-E04 | public Artifact write API is exactly `put/2(ready_store, PutRequest)` |
| P0-W38-AC05 | Pass | P0-W38-E05 | eight changed files are governance-only; authorization absent; runtime compare empty |
| P0-W38-AC06 | Pass (historical exact-head CI on the pre-P0-W39 review-correction head); current-main integration: applicable local deterministic checks pass against current canonical `main` `9f09ea2400ea73257c1fb2efc566ee165a4a1181`, except for the known pre-existing `scripts/test-agent-preflight` named-branch harness defect, which is recorded under "Failures and warnings"; exact-head CI is the external integration Evidence and is recorded in PR and CI metadata | P0-W38-E06 | local contract checks and historical review-correction CI run `31315585161` passed on pre-P0-W39 review-correction head `cf34adcb…`; the local reconciliation against `9f09ea2400ea73257c1fb2efc566ee165a4a1181` (current canonical main) passes the applicable deterministic checks; the exact-head CI bound to the current replacement branch head lives in PR and CI metadata, not in this tracked record |
| P0-W38-AC07 | Pass | P0-W38-E07 | persistent identity, unseen-key admission, read, replay ordering, and pure currentness are separate |
| P0-W38-AC08 | Pass | P0-W38-E08 | Artifact and metadata limits are numeric with exact overflow behavior |
| P0-W38-AC09 | Pass | P0-W38-E09 | P0-W24 and active first-month conformance fields are explicitly preserved and mapped |

### Completion Evidence

- **P0-W38-E01:** the corrected T01 plan requires `result: pass | fail | blocked | unknown`, assigns `Kiln.Evidence.Store.record/2` durable ownership, preserves Repository, host/environment, Command-result, plural Artifact, freshness, completeness, and contradiction bindings, and maps immutable storage plus pure currentness into the accepted Evidence item.
- **P0-W38-E02:** contradiction preserves all valid observations and is derived across current peers; stale admission rejects an unseen mismatched record while pure currentness reports an old record stale without mutation; truthful incomplete `blocked` or `unknown` may persist while incomplete `pass` or `fail` cannot; integrity rolls back the Evidence transaction.
- **P0-W38-E03:** the plan permits exactly P0-W24's four state-based freshness rules, has no TTL field or column, requires plural foreign-key and Artifact integrity checks, and defines direct-SQL negative fixtures and per-migration rollback.
- **P0-W38-E04:** the plan defines only `Kiln.Artifact.Store.put/2(ready_store, %Kiln.Artifact.PutRequest{})` for writing, adds read-only `fetch/2`, names a fresh replacement implementation branch, and forbids reuse of the rejected branch.
- **P0-W38-E05:** the compare from current canonical `main` (`9f09ea2400ea73257c1fb2efc566ee165a4a1181`) to this package's branch head contains exactly eight governance-only files (`AGENTS.md`, `README.md`, `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/PLANNING.md`, `docs/ROADMAP.md`, `docs/work/P0-W38-correct-rejected-t01-plan.md`, `docs/work/P1-S02-T01-artifact-evidence-substrate.md`) and no `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, or `mix.lock` path. `docs/authorizations/P1-S02-T01.authorization` remains absent. The historical pre-P0-W39 base `f9b5a312ac31ee4015025a87bcd3cec199b12297` is preserved only as the original base of PR #53 and as provenance for P0-W37 / PR #52; it is not the base of this v2 package.
- **P0-W38-E06:** review-correction head `cf34adcb…` passed local preflight, detached preflight regression, semantic validation, pinned JSON Schema validation, agent assets, diff and authority checks. Historical exact-head CI run `31315585161` additionally passed Vale, formatting, warnings-as-errors compilation, compile-connected cycle checks, all tests, the P1-S01 aggregate gate, and prose validation. The local reconciliation against `9f09ea2400ea73257c1fb2efc566ee165a4a1181` (current canonical main) passes the applicable deterministic checks (the known pre-existing `scripts/test-agent-preflight` named-branch harness defect is not a regression caused by this package and is recorded under "Failures and warnings"). Exact-head remote CI bound to the current replacement branch head is external integration Evidence and lives in PR and CI metadata; historical CI does not substitute for it.
- **P0-W38-E07:** Evidence persistent request identity excludes admission and later currentness contexts; exact replay is integrity-checked before unseen-key admission, and `fetch/2` plus pure `Currentness.evaluate/2` re-evaluate historical records without writes.
- **P0-W38-E08:** the T01 bounds table fixes a 16,777,216-byte Artifact maximum, 65,536-byte canonical requests, and explicit identifier, media-type, warning, rationale, association, and currentness limits. Overflow is rejected without silent T01 truncation.
- **P0-W38-E09:** the corrected plan states that it does not supersede P0-W24 or the active first-month Schema and defines exact canonical mappings for subject, Repository, host/environment, Command result, plural Artifacts, freshness, completeness, contradiction, invalidation, status, and record digest.

### Failures and warnings

- The fresh workspace did not expose Vale or the pinned Elixir/Mix runtime locally. Exact review-correction CI supplied passing prose, formatting, compile, xref, and test results.
- `scripts/test-agent-preflight` has a pre-existing final source-root assertion fixed to the historical W34 branch name. It passes in a detached-head source-root state and in CI but exits non-zero from any non-W34 named branch checkout. This package does not modify that development-tool path; the flaw is recorded here for transparency and is not P0-W38 regression Evidence. The same script is invoked by CI in a state where the flaw does not manifest.
- The local integration candidate's reconciliation pass surfaced two governance-only documentation drifts in the corrected T01 plan and then two governance-only Evidence-wording corrections during the v2 commit cycle: (1) the plan's description of `KILN-INV-051` did not match the accepted invariant text and has been corrected to use the exact invariant title plus a concise faithful description; (2) the deterministic verification Vale glob did not exclude pinned reference-repository content established by P0-W39 and has been updated to `vale --glob='!{deps,_build,.claude/dependencies}/**' .`; (3) `P0-W38-E05` previously described the package diff as if compared from the historical `f9b5a312…` base, and now describes the compare from current canonical `main` `9f09ea2400ea73257c1fb2efc566ee165a4a1181` while preserving `f9b5a312…` only as historical provenance; (4) tracked statements asserting "remote exact-head CI pending" or "all local deterministic checks pass" were replaced with timeless contract language acknowledging the pre-existing `test-agent-preflight` named-branch harness limitation. None of these corrections altered the technical contract of the corrected T01 plan.

### Required next action

After this governance package merges, the owner must accept, revise, or reject the corrected proposed T01 plan. Only a later, separate governance action may mark it Accepted and issue a new exact authorization record for a fresh implementation package.
