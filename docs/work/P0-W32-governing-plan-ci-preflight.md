# P0-W32: Enforce governing-plan preflight in CI

**Document type:** Development-tooling work package
**Status:** Proposed
**Branch:** `work/p0-w32-governing-plan-ci-preflight`
**Base:** `main`, which contains the merged P0-W31 work
**Implementation authorization:** None; this work package does not authorize P1-S01 or P1-S02 product implementation

## Objective

Make CI prove that the actual governing work package for a pull request conforms to the current preflight grammar, instead of relying solely on the preflight fixture regression suite.

The package closes one demonstrated CI integrity gap. It does not modify the preflight grammar, the preflight script, or any historical work package.

## Observed current state

- `.github/workflows/ci.yml` runs `scripts/test-agent-preflight` as part of the `test` job, then runs `scripts/validate-agent-assets`, Mix format/compile/xref/test, and the prose job.
- The workflow does not invoke the real `scripts/agent-preflight`.
- `scripts/test-agent-preflight` writes synthetic fixtures under `docs/work/`, exercises them against `scripts/agent-preflight` using the `KILN_BRANCH` override, and removes them. It proves the validator implementation works; it does not prove any actual governing plan conforms.
- `scripts/agent-preflight` validates the plan whose identifier is derived from the current branch. It reads the branch from `KILN_BRANCH` when set, otherwise from `git branch --show-current`, and refuses to run when both are empty (detached HEAD is not a valid implementation state). It refuses `main`, `master`, and `develop`. It accepts only the configured branch classes (`work/*`, `fix/*`, `spike/*`, `docs/*`, `chore/*`, `release/*`, `hotfix/*`, `agent/bootstrap-project-foundation`). For accepted work branches it locates one plan under `docs/work/`, verifies the plan identifies the branch, and verifies the required headings for the work kind.
- On a `pull_request` event GitHub Actions checks out the merge commit at a detached HEAD. A naive `scripts/agent-preflight` invocation in that checkout therefore fails because detached HEAD supplies no branch name.
- GitHub Actions supplies the pull-request source branch through `github.head_ref`. The preflight script already supports that branch being passed via `KILN_BRANCH`.
- `scripts/check` runs the same fixture suite locally; it does not run the real preflight.
- PR #43 merged the P0-W30 plan into `main` as merge commit `4f32815`. The preflight fixture suite passed for that pull request. The actual P0-W30 plan at merge time was missing five required headings against the current grammar; the real preflight against the actual PR branch (`work/p0-w30-p1-s02-planning-foundation`) would have failed. The plan was repaired in PR #44 (merge commit `fd9c68e`), proving the gap was real rather than theoretical.
- Older plans under `docs/work/` predate some current headings and branch conventions. They are not in scope for this package.

## Assumptions and unknowns

### Assumptions

- **P0-W32-A01:** GitHub Actions `pull_request` events reliably expose the PR source branch through `github.head_ref`.
- **P0-W32-A02:** The preflight script's existing `KILN_BRANCH` override is the correct mechanism for supplying the PR source branch; adding CI-only branch inference would duplicate the script's existing rule.
- **P0-W32-A03:** The fixture regression suite must remain in CI; it is not a substitute for the real preflight and must not be removed by this package.
- **P0-W32-A04:** A pull request that the preflight script intentionally treats as "no plan validation required" (branch classes outside `work/*` etc.) should pass CI without forcing the script to report success against an absent plan.
- **P0-W32-A05:** Historical plans under `docs/work/` are out of scope for this package and must not be globally revalidated, migrated, exempted, or grandfathered.

### Unknowns

- **P0-W32-U01:** Whether future GitHub Actions events beyond `pull_request` and `push` to `main` will be added and whether their branch semantics will require their own guard.
- **P0-W32-U02:** Whether future preflight grammar changes will require additional CI guard conditions beyond event-name and branch identity.

## Requirements

- **P0-W32-R01:** CI executes the real `scripts/agent-preflight` for pull-request runs.
- **P0-W32-R02:** CI supplies the actual pull-request source branch to the preflight script through `KILN_BRANCH=${{ github.head_ref }}` rather than inferring it from the detached HEAD checkout.
- **P0-W32-R03:** The governing-plan CI step runs only for `pull_request` events. It must not run naïvely on `push` to `main`, because the preflight script correctly refuses `main`.
- **P0-W32-R04:** The existing fixture regression suite (`scripts/test-agent-preflight`) continues to run as a separate CI step and is not removed or weakened by this package.
- **P0-W32-R05:** If the applicable governing plan fails preflight, CI fails. No `|| true`, no warning-only step, no silent fallback, and no model judgment may convert a real preflight failure into a CI pass.
- **P0-W32-R06:** Branch classes that the preflight script intentionally treats as "no plan validation required" retain their existing deterministic behaviour. CI does not invent a parallel exemption system; it relies on the script's existing branch-class rule.
- **P0-W32-R07:** CI does not validate every file in `docs/work/` or any global plan collection.
- **P0-W32-R08:** Current preflight grammar is not modified, weakened, or widened to make CI adoption convenient.
- **P0-W32-R09:** CI logs make it clear which governing plan was evaluated or why plan evaluation did not apply. The preflight script's existing structured output is sufficient; CI does not invent a parallel logging layer.
- **P0-W32-R10:** No change to `scripts/agent-preflight`, `scripts/test-agent-preflight`, or historical work-package documents is introduced by this package. If repository evidence during execution proves a script change is required, the requirement must be added explicitly and justified against current Evidence before any such change is made.

## Proposed changes

1. Add one guarded CI step to `.github/workflows/ci.yml` that runs the real `scripts/agent-preflight` for pull-request events and supplies `KILN_BRANCH` from `github.head_ref`.
2. Order that step so its failure blocks the PR without hiding the fixture regression or any later check.
3. Use the preflight script's existing structured output for CI log clarity; do not invent a separate logging layer.
4. Add this work-package record.

## Expected files or components

| Path or component | Result |
| --- | --- |
| `.github/workflows/ci.yml` | Added one guarded real-preflight step for `pull_request` that uses `KILN_BRANCH=${{ github.head_ref }}` |
| `docs/work/P0-W32-governing-plan-ci-preflight.md` | Added this work package |

No other repository path is expected to change. In particular, `scripts/agent-preflight`, `scripts/test-agent-preflight`, `scripts/check`, and historical `docs/work/` documents are unchanged.

## Acceptance criteria

- **P0-W32-AC01**
  - **Given** a pull request on a supported work branch with a conformant governing work package
  - **When** CI runs
  - **Then** the real `scripts/agent-preflight` runs against the PR source branch and passes
  - **Evidence:** CI run log shows the new step, the resolved `KILN_BRANCH` value, the script's existing pass output, and exit status 0

- **P0-W32-AC02**
  - **Given** a pull request whose governing work package violates the current plan contract
  - **When** CI runs
  - **Then** the governing-plan step exits non-zero and fails CI with the preflight script's existing actionable error message
  - **Evidence:** CI run log shows the new step, the preflight failure message, and a failed job

- **P0-W32-AC03**
  - **Given** CI executes repository checks
  - **When** preflight verification runs
  - **Then** `scripts/test-agent-preflight` also executes independently of the new step
  - **Evidence:** CI run log shows both steps in the same job

- **P0-W32-AC04**
  - **Given** GitHub Actions checks out a pull request at detached HEAD
  - **When** the governing-plan preflight step runs
  - **Then** the actual PR source branch is supplied through the existing `KILN_BRANCH` override rather than inferred from detached HEAD
  - **Evidence:** CI run log shows the resolved `KILN_BRANCH` value equals `github.head_ref`; the script does not emit "detached HEAD is not a valid implementation state"

- **P0-W32-AC05**
  - **Given** a `push` event to `main`
  - **When** CI runs
  - **Then** the PR governing-plan preflight step is not invoked
  - **Evidence:** CI run log for the push event does not contain the new step

- **P0-W32-AC06**
  - **Given** older work-package documents that do not satisfy today's grammar
  - **When** an unrelated current PR runs CI
  - **Then** those historical plans are not globally revalidated and do not cause CI failure
  - **Evidence:** CI run log shows the preflight step validates only the governing plan for the PR; the PR diff does not touch historical plan documents

- **P0-W32-AC07**
  - **Given** this branch diff
  - **When** it is compared with its base
  - **Then** it contains only the workflow change, this work-package record, and any evidence files needed to satisfy AC01–AC06, and no other repository path
  - **Evidence:** exact branch compare against `main`

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
scripts/validate-agent-assets
vale --glob='!{deps,_build}/**' .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
shellcheck .github/workflows/ci.yml
```

Repository CI remains authoritative for the exact head. The local checks above do not substitute for the GitHub Actions run that proves AC01, AC02, AC04, and AC05.

The YAML workflow is reviewed manually against the current workflow's structure, shell conventions, ordering, naming, permissions, and event configuration. No new workflow-validation dependency is introduced.

## Required completion Evidence

| Evidence ID | Criterion | Result |
| --- | --- | --- |
| P0-W32-E01 | P0-W32-AC01 | exact CI run log for the merged P0-W32 PR showing the new step, the resolved `KILN_BRANCH` value, the preflight pass output, and exit status 0 |
| P0-W32-E02 | P0-W32-AC02 | exact CI run log for a deliberately non-conformant follow-up commit on the same branch showing the preflight failure message and a failed job |
| P0-W32-E03 | P0-W32-AC03 | exact CI run log showing `Test agent preflight behavior` and the new step in the same job |
| P0-W32-E04 | P0-W32-AC04 | CI run log line showing the resolved `KILN_BRANCH` equals `github.head_ref`, and the absence of the detached-HEAD failure message |
| P0-W32-E05 | P0-W32-AC05 | CI run log for the `push` event on `main` showing the absence of the new step |
| P0-W32-E06 | P0-W32-AC06 | exact PR diff against `main` showing no historical plan migration and a narrow CI change |
| P0-W32-E07 | P0-W32-AC07 | exact branch compare against `main` |

## Explicit exclusions

- No validation of every historical `docs/work/` document.
- No migration of historical work packages to current headings.
- No edits to P0-W16 or older integration-summary plans merely because they fail today's grammar.
- No exemption lists, allowlists, or date-based grandfathering for historical documents.
- No weakening, broadening, or rewriting of the current preflight plan-contract rules.
- No change to `scripts/agent-preflight`, `scripts/test-agent-preflight`, or `scripts/check` unless current Evidence forces it; in that case the change must be justified explicitly against current Evidence before it is made.
- No Project Arsenal integration.
- No development-agent lifecycle work.
- No runtime Kiln implementation.
- No P1-S02 implementation.
- No `.claude/` cleanup or gitignore changes.
- No unrelated CI refactoring.
- No new workflow-validation dependency.
- No new dependency at all.

## Completion record

**Result:** In progress

The package is complete only after:

- the guarded real-preflight CI step is in place and runs against the PR source branch;
- the existing fixture regression suite continues to run as a separate step;
- AC01, AC02, AC03, AC04, AC05, AC06, and AC07 are each backed by exact repository or CI Evidence;
- the exact tested head equals the proposed merge head;
- the failure path has been demonstrated by an actual CI run;
- the branch diff against `main` contains only the workflow change, this work package, and any evidence artefacts;
- the branch ends clean.
