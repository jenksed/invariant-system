# P0-W02: Work Governance

**Document type:** Reference  
**Status:** In progress  
**Branch:** `work/p0-w02-work-governance`  
**Depends on:** P0-W01 repository foundation

## Objective

Define a branch-linked planning and evidence system that reduces coordination cost and preserves work provenance.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| Kiln has an accepted proof-ordered roadmap but no branch naming policy. | `docs/ROADMAP.md` at `5a05c22d11564689df183c90d4794a25a3693896` | ChatGPT GitHub connector | 2026-07-28 |
| Kiln requires ADRs for foundational changes but has no ADR template. | `AGENTS.md` lines 65-69 at `5a05c22d11564689df183c90d4794a25a3693896` | ChatGPT GitHub connector | 2026-07-28 |
| The current bootstrap branch predates the proposed naming policy. | Branch `agent/bootstrap-project-foundation` | ChatGPT GitHub connector | 2026-07-28 |
| CI checks Elixir formatting, compilation, and tests. It does not check prose. | `.github/workflows/ci.yml` at `5a05c22d11564689df183c90d4794a25a3693896` | ChatGPT GitHub connector | 2026-07-28 |

## Assumptions and unknowns

### Assumptions

- **P0-W02-A01:** A stable work-package identifier will reduce intent reconstruction across plans, branches, pull requests, and evidence.
- **P0-W02-A02:** Trunk-based development with short-lived branches is suitable for the current single-developer project.

### Unknowns

- **P0-W02-U01:** Unknown. The useful maximum branch size will be measured during Phase 1 work packages.
- **P0-W02-U02:** Unknown. The initial Vale rules can produce false positives. Verify by running Vale against the current documentation and adjusting only deterministic rules.

## Requirements

- **P0-W02-R01:** The repository shall define one branch naming grammar for planned work.
- **P0-W02-R02:** Each planned work branch shall include a stable work-package identifier.
- **P0-W02-R03:** Each work-package plan shall connect requirements, acceptance criteria, and completion evidence through the work-package identifier.
- **P0-W02-R04:** The repository shall define normative language, requirement, evidence, planning, ADR, and completion rules.
- **P0-W02-R05:** Documentation linting shall use repository-local deterministic rules.
- **P0-W02-R06:** The bootstrap branch shall remain an explicit one-time naming exception.

## Proposed changes

1. Add branch classes and a branch naming grammar.
2. Add work-package, requirement, acceptance, and evidence identifiers.
3. Map Phase 1 work packages to proposed branch names and dependencies.
4. Add normative engineering quality rules.
5. Add implementation-plan and ADR templates.
6. Add a pull-request template that requires evidence and unknowns.
7. Add Vale configuration and repository-local rules.
8. Add prose linting to continuous integration.
9. Link the new rules from contributor and project documentation.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `docs/BRANCHING-AND-WORK-PLANNING.md` | Add branch and work-package rules. | Added |
| `docs/ENGINEERING-QUALITY-RULES.md` | Add normative writing, requirements, evidence, and completion rules. | Added |
| `docs/templates/IMPLEMENTATION-PLAN.md` | Add work-package plan template. | Added |
| `docs/templates/ADR.md` | Add ADR template. | Proposed |
| `.github/pull_request_template.md` | Add evidence-centered pull-request template. | Proposed |
| `.vale.ini` | Configure prose linting. | Proposed |
| `styles/Kiln/` | Add repository-local Vale rules. | Proposed |
| `.github/workflows/ci.yml` | Run Vale in CI. | Proposed |
| `AGENTS.md` | Require the work-package and quality rules. | Proposed |
| `README.md` | Link the rules. | Proposed |
| `docs/ROADMAP.md` | Add work identifiers and Phase 1 work-package map. | Proposed |

## Acceptance criteria

- **P0-W02-AC01**
  - **Given** a planned Phase 1 work package
  - **When** a contributor creates its plan, branch, pull request, requirements, acceptance criteria, and evidence
  - **Then** each artifact can use one stable work-package identifier
  - **Evidence:** repository reference and template inspection

- **P0-W02-AC02**
  - **Given** a technical implementation plan
  - **When** a contributor uses the repository template
  - **Then** the plan contains all ten required planning sections
  - **Evidence:** `docs/templates/IMPLEMENTATION-PLAN.md`

- **P0-W02-AC03**
  - **Given** a documentation change that contains a repository-forbidden promotional term
  - **When** continuous integration runs Vale
  - **Then** the prose-linting check exits with a failure
  - **Evidence:** Vale command result in continuous integration

- **P0-W02-AC04**
  - **Given** the accepted Phase 1 roadmap
  - **When** a contributor selects the next work package
  - **Then** the roadmap identifies its proposed branch name and dependencies
  - **Evidence:** `docs/ROADMAP.md`

## Verification commands

```bash
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix test
```

Each command must exit with status `0`.

## Required completion evidence

| Evidence ID | Acceptance criterion | Required evidence |
| --- | --- | --- |
| P0-W02-E01 | P0-W02-AC01 | Paths and identifier examples in the branch reference and templates. |
| P0-W02-E02 | P0-W02-AC02 | Inspection of the implementation-plan template. |
| P0-W02-E03 | P0-W02-AC03 | Successful Vale CI run plus a local or isolated negative-rule test. |
| P0-W02-E04 | P0-W02-AC04 | Phase 1 work-package table in the roadmap. |

## Explicit exclusions

- GitHub label creation
- GitHub issue automation
- merge queue configuration
- branch protection configuration
- release automation
- a formal ASD-STE100 compliance claim
- semantic validation of requirement quality by Vale

## Completion record

**Result:** In progress

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W02-AC01 | In progress | P0-W02-E01 | Branch reference and plan template added. |
| P0-W02-AC02 | In progress | P0-W02-E02 | Template added; final inspection pending. |
| P0-W02-AC03 | Not run | P0-W02-E03 | Vale configuration and CI change pending. |
| P0-W02-AC04 | Not started | P0-W02-E04 | Roadmap update pending. |

### Verification executed

No verification has run for the current branch.

### Failures and warnings

- None observed through execution because verification has not run.

### Remaining unknowns and exclusions

- P0-W02-U01 and P0-W02-U02 remain open.

### Repository state

- Commit: Unknown until the work package is complete.
- Branch: `work/p0-w02-work-governance`
- Diff reviewed: No