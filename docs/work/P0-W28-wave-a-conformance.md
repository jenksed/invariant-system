# P0-W28: Wave A conformance scaffolding

**Document type:** Implementation plan  
**Status:** In progress  
**Parent slice:** None  
**Branch:** `work/p0-w28-wave-a-conformance`  
**Depends on:** P0-W21 through P0-W25 integrated

## Objective

Create only the executable and machine-readable rails justified by the integrated first-month planning. Keep all external effects and product workflow visibly unimplemented.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| P0-W21 through P0-W25 are integrated | PRs 27–33 | Repository history | `aabfc49a9b0ba294b4e0f6558fbe8fed38263784` |
| Production still contains only application bootstrap and literal version | `lib/`, `mix.exs` | Repository inspection | current base |
| Preflight accepts only P0 work-package branches and obsolete headings | `scripts/agent-preflight` | Repository inspection | current base |
| CI proves obsolete preflight behavior | `scripts/test-agent-preflight`, CI | Repository inspection | current base |
| Broad historical Schemas force deferred concepts | `docs/contracts/README.md` and Prompt 3 dispositions | planning Evidence | integrated |

## Assumptions and unknowns

### Assumptions

- **P0-W28-A01:** Standard Python 3 is available in GitHub Actions and on the supported development host for dependency-free fixture validation.
- **P0-W28-A02:** Contract constants and behaviours can live under `Kiln.Conformance` without becoming runtime product APIs.

### Unknowns

- **P0-W28-U01:** Unknown. Prompt 8-A will determine which scaffold units become authorized implementation dependencies.
- **P0-W28-U02:** Unknown. Later implementation Evidence can require a contract revision, but cannot silently widen scope.

## Requirements

- **P0-W28-R01:** The Repository shall accept P0 work-package and P1 slice-ticket branch grammar through preflight.
- **P0-W28-R02:** The preflight shall enforce the current implementation-plan headings and ticket-specific slice/security/demo headings.
- **P0-W28-R03:** The Repository shall expose exact first-month lifecycle, Tool, Patch, Evidence, and CLI constants through conformance-only Elixir modules.
- **P0-W28-R04:** The Repository shall define provider and macOS Command-host behaviours without implementations.
- **P0-W28-R05:** The Repository shall contain one first-month JSON Schema and positive and negative fixtures.
- **P0-W28-R06:** A dependency-free validation command shall reject deferred states, excess Tools, unsupported Patch operations, Receipt authority, and invalid CLI outcomes.
- **P0-W28-R07:** Tests shall prove runtime Session, Store, provider, mutation, Command, CLI, and Receipt modules remain absent.
- **P0-W28-R08:** CI and `scripts/check` shall run the new conformance validation.
- **P0-W28-R09:** No scaffold shall return fake product success or perform an external effect.

## Security boundary

Allowed:

- static constants and types;
- pure transition-shape checks;
- behaviour declarations;
- fixture parsing and deterministic validation;
- preflight and CI changes.

Denied:

- provider network calls;
- source mutation;
- SQLite state creation;
- Command execution;
- credential reads;
- runtime CLI actions;
- permissive fallback;
- Child Runs or Wave B scaffolding.

A failed or incomplete contract returns a validation error. No placeholder can report a successful workflow.

## Proposed changes

1. Repair agent preflight and its tests.
2. Add `Kiln.Conformance.FirstMonth`, `Kiln.Conformance.Provider`, and `Kiln.Conformance.CommandHost`.
3. Add tests for exact accepted constants, transition shapes, behaviours, and missing runtime modules.
4. Add one first-month Schema, fixtures, and dependency-free validator.
5. Wire validation into CI and `scripts/check`.
6. Mark broad historical Schemas deferred outside the first-month required set.
7. Record exact completion Evidence.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `scripts/agent-preflight` | current branch and plan grammar | Proposed |
| `scripts/test-agent-preflight` | P0 and P1 fixtures and protected negatives | Proposed |
| `lib/kiln/conformance/` | constants and behaviours only | Proposed |
| `test/kiln/conformance/` | exact contract and incompleteness tests | Proposed |
| `docs/contracts/kiln-first-month.schema.json` | canonical first-month Schema | Proposed |
| `test/fixtures/conformance/` | positive and negative fixtures | Proposed |
| `scripts/validate_first_month_contracts.py` | dependency-free validator | Proposed |
| `.github/workflows/ci.yml` | recurring validation | Proposed |
| `scripts/check` | local validation | Proposed |
| `docs/contracts/README.md` | current authority status | Proposed |

## Acceptance criteria

- **P0-W28-AC01**
  - **Given** a P1 ticket branch and current plan fixture
  - **When** preflight runs
  - **Then** it passes, while protected branches and invalid grammar fail
  - **Evidence:** `scripts/test-agent-preflight`
- **P0-W28-AC02**
  - **Given** the integrated first-month decisions
  - **When** Elixir conformance tests run
  - **Then** exact states, Tools, Patch operations, proof results, exits, and behaviour callbacks match
  - **Evidence:** `mix test`
- **P0-W28-AC03**
  - **Given** positive and protected negative fixtures
  - **When** the Python validator runs
  - **Then** positives pass and negatives are rejected for the expected reason
  - **Evidence:** `python3 scripts/validate_first_month_contracts.py`
- **P0-W28-AC04**
  - **Given** the scaffold branch
  - **When** incompleteness tests run
  - **Then** runtime external-effect modules remain absent
  - **Evidence:** `mix test`
- **P0-W28-AC05**
  - **Given** the exact final head
  - **When** CI runs
  - **Then** all existing and new checks pass
  - **Evidence:** exact CI run

## Deterministic verification

```bash
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
scripts/validate-agent-assets
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Every command must exit zero. Negative fixtures must be rejected inside their harness rather than by failing the overall command.

## Demo contribution

```text
No product demo. This work enables Prompt 7-A to review executable planning rails without implying Single-Run behavior exists.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P0-W28-E01 | P0-W28-AC01 | preflight test output |
| P0-W28-E02 | P0-W28-AC02 | ExUnit output and module paths |
| P0-W28-E03 | P0-W28-AC03 | fixture validator output |
| P0-W28-E04 | P0-W28-AC04 | incompleteness test output |
| P0-W28-E05 | P0-W28-AC05 | exact final CI run and compare |

### Slice gate contribution

| Slice gate or Receipt | Contribution |
| --- | --- |
| First-month Prompt 8-A review | contract and negative-fixture Evidence only |
| P1 slice gate | None until Prompt 8-A authorizes implementation |

## Explicit exclusions

- No runtime Session, Store, MiniMax adapter, Context builder, Repository reader, Patch engine, mutation Worker, Command runner, helper binary, Artifact store, Evidence evaluator, CLI, release, installer, or Receipt sealer.
- No Exqlite, HTTP, JSON, CLI, or process dependency.
- No migration, release configuration, real gate script, or successful end-to-end fixture.
- No P0-W26, P0-W27, Child, Scout, Verifier, Attention, or Wave B contract.

## Completion record

**Result:** Implemented but unverified

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W28-AC01 | Pending | P0-W28-E01 | pending |
| P0-W28-AC02 | Pending | P0-W28-E02 | pending |
| P0-W28-AC03 | Pending | P0-W28-E03 | pending |
| P0-W28-AC04 | Pending | P0-W28-E04 | pending |
| P0-W28-AC05 | Pending | P0-W28-E05 | pending |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| pending | pending | pending |

### Demo and slice status

- Ticket demo contribution: Not yet exercised
- Parent slice gate affected: first-month Prompt 8-A only
- Aggregate Receipt updated: Not applicable
- Slice completion claimed: No

### Failures and warnings

- Build authorization remains denied.

### Remaining unknowns and exclusions

- Prompt 7-A and Prompt 8-A remain required.

### Repository state

- Commit: pending
- Branch: `work/p0-w28-wave-a-conformance`
- Diff reviewed: No
- Exact CI run: pending
- Parent slice status after merge: unchanged
