# P0-W19: Reconcile implementation-like assets

**Document type:** Planning work package  
**Status:** Implemented and verified; not integrated  
**Branch:** `work/p0-w19-implementation-scaffold-reconciliation`  
**Pull request:** 24  
**Depends on:** P0-W18 integrated through pull request 23  
**Scope:** Implementation inventory, status, blast radius, disposition, and Prompt 4 inputs only

## Objective

Inspect every material implementation-like Repository asset and record what exists, what it proves, what should survive, what must change later, and which unresolved planning decision blocks any disposition.

This pass does not implement, repair, remove, or reconfigure product source, tests, JSON Schemas, CI, scripts, Skills, prompts, specialist agents, dependencies, runtime configuration, or executable gates.

## Observed current state and evidence

- Pull request 23 is integrated into `main` at merge commit `33da2a718d8d5305bf89035503ac372f07e80a6e`.
- That merge commit was the current `main` head when P0-W19 began.
- ADR 0020 and the Prompt 2 delivery sequence are integrated.
- Production source contains one dependency-free Mix project, one public version function, and one empty application supervisor.
- Production tests contain one version assertion plus `ExUnit.start/0`.
- CI validates prose, obsolete preflight behavior, agent-asset shape, dependency installation, formatting, compilation, compile-connected cycles, and ExUnit.
- Eleven JSON Schema files exist as planning-conformance assets.
- No product Run, journal, provider, Context, Patch, Command, Evidence, Receipt, CLI, Child, or recovery capability is implemented.
- `mix.lock`, `config/config.exs`, and `scripts/gates/slice-01` do not exist.

## Assumptions and unknowns

### Assumptions

- Prompt 2 remains the accepted evaluation target.
- Documentation-only status and disposition records are sufficient for this pass.
- Existing executable and machine-readable assets must remain unchanged.

### Unknowns

- exact Run transition and recovery rules;
- SQLite library, migrations, journal transactions, and replay design;
- Patch format, base binding, rollback, and dirty-state policy;
- Command registration, process-tree control, cancellation, and unknown-effect behavior;
- provider disclosure, Context sealing, and secret screening;
- Evidence, Artifact, and Receipt retention;
- later Child permission derivation and Attention behavior.

## Requirements

- Inventory every material production, test, Schema, CI, script, agent-facing, structural, and contract-like asset.
- Group assets into implementation units rather than treating every file as a separate capability.
- Assign one current status, blast-radius class, and explicit disposition to every material unit.
- Separate Repository mechanics from product behavior and conformance from implementation.
- Record active safety issues, near-term hazards, conformance drift, misleading status, and deferred concerns without exaggeration.
- Provide implementation-grounded Prompt 4 inputs.
- Do not issue build authorization.

## Proposed changes

The branch implements these planning changes:

1. Add `docs/IMPLEMENTATION-ASSET-INVENTORY.md` with observed production, test, tooling, script, CI, agent-asset, Schema, structure, contractual-document, and absence Evidence.
2. Add `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md` with the executive verdict, implementation-unit map, status, blast radius, dispositions, safety findings, CI meaning, and Prompt 4 inputs.
3. Classify the Mix shell and empty supervisor as validated bootstrap implementation that can remain.
4. Classify the version surface as partial implementation pending packaging or CLI need.
5. Classify the preflight concept as valid conformance scaffolding and its current implementation as a build blocker.
6. Classify preflight tests as superseded implementation because they prove obsolete positive behavior.
7. Classify `scripts/check`, CI mechanics, and agent-asset validation as validated Repository tooling with narrow claims.
8. Classify every Schema family separately and identify overlap, retained value, required revision, and deferred triggers.
9. Confirm planned gate paths and Receipts are documentation only.
10. Identify no active runtime safety issue.
11. Identify conformance drift, misleading green status, and near-term implementation hazards.
12. Add implementation-grounded planning dependencies for Prompt 4.
13. Mark ADR 0020 accepted and integrated and ADR 0019 partially superseded.
14. Close the P0-W18 work record as accepted and integrated.
15. Keep build authorization denied.

## Files or components expected to change

### Added

- `docs/IMPLEMENTATION-ASSET-INVENTORY.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/work/P0-W19-implementation-scaffold-reconciliation.md`

### Status or decision corrections

- `docs/decisions/0019-implement-kiln-through-vertical-product-slices.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`
- `docs/decisions/README.md`
- `docs/work/P0-W18-product-scope-architecture.md`

### Unchanged executable and machine-readable areas

- production source and tests;
- JSON Schemas;
- CI workflows;
- Repository scripts;
- dependencies and runtime configuration;
- Skills, prompts, and specialist agents;
- executable gate paths.

## Acceptance criteria

| Criterion | Status | Evidence |
| --- | --- | --- |
| Material implementation-like assets inventoried | Pass | Implementation Asset Inventory |
| First-month and cross-cutting units have dispositions | Pass | Implementation Disposition Register section 6 |
| Twelve-week units have dispositions or planning dependencies | Pass | Units IU-17 and related Schema rows |
| Deferred units have review triggers | Pass | Register section 13 |
| Mix shell, supervisor, and version surface classified | Pass | Units IU-01 through IU-04 |
| Schemas classified accurately | Pass | Register section 5 and inventory section 8 |
| Preflight concept, implementation, tests, and CI classified separately | Pass | Units IU-18 through IU-23 |
| Planned gates and Receipts classified | Pass | Units IU-29 and IU-30 |
| Current CI meaning is precise | Pass | Register section 16 |
| Safety and integrity findings separated | Pass | Register section 15 |
| Prompt 4 inputs are implementation-grounded | Pass | Register sections 14 and 17 |
| Documentation-only diff | Pass | GitHub compare against `main` |
| Repository validation | Pass | GitHub CI run `30414091632` on review head `b2043c8d3d80e33e475a5df5a581e9eb7be38be6` |
| Exact closeout-head validation | Pending | One final CI run required after this record update |

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

GitHub CI run `30414091632` executed the equivalent Repository checks on review head `b2043c8d3d80e33e475a5df5a581e9eb7be38be6`.

Passed steps:

- Vale prose check;
- current agent-preflight behavior test;
- project agent-asset validation;
- dependency installation;
- Elixir format check;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit.

The preflight result remains Evidence of obsolete behavior, not P1 compatibility.

Targeted GitHub inspection proved:

- four source or test modules plus `test_helper.exs`;
- no runtime dependency or configuration file;
- four executable Repository scripts;
- eleven JSON Schemas;
- five Skills, three specialist agents, and three required prompts;
- exact CI workflow steps;
- absence of `scripts/gates/slice-01` and all discovered `scripts/gates/*` files.

## Required completion evidence

| Evidence ID | Scope | Evidence |
| --- | --- | --- |
| P0-W19-E01 | Entry gate | PR 23 merge and current-main commit |
| P0-W19-E02 | Production and tests | `mix.exs`, `lib/`, and `test/` inventory |
| P0-W19-E03 | Scripts and CI | four scripts and `.github/workflows/ci.yml` |
| P0-W19-E04 | Schemas | eleven-file package, conflicts, and validation status |
| P0-W19-E05 | Agent assets | five Skills, three agents, three prompts, validator behavior |
| P0-W19-E06 | Status and blast radius | Implementation Disposition Register |
| P0-W19-E07 | Safety and CI meaning | Register sections 15 and 16 |
| P0-W19-E08 | Prompt 4 inputs | Register sections 14 and 17 |
| P0-W19-E09 | Change surface | final compare against `main` |
| P0-W19-E10 | Design-head validation | GitHub CI run `30414091632` |
| P0-W19-E11 | Final validation | closeout-head GitHub CI run pending |

## Failures and warnings

- Current preflight remains incompatible with accepted P1 ticket branches.
- Current preflight tests and CI still prove obsolete P0 positive behavior.
- Current CI has no complete Schema validation or documentation-reference validation.
- Current Schemas overlap and include deferred capability detail.
- Detailed planning documents can create implementation pressure, but no runtime code consumes them.
- Several Prompt 2 authority headers still use branch-era proposed wording. ADR and work-package status are corrected in this pass; remaining header cleanup does not change the accepted target and can occur with the next bounded authority edit.
- A local clone was unavailable during this pass. GitHub connector file, commit, compare, and CI Evidence are authoritative for the recorded observations.
- Build authorization remains denied.

## Explicit exclusions

P0-W19 does not:

- implement or refactor runtime behavior;
- change production source or tests;
- edit JSON Schemas;
- alter CI, scripts, preflight, or validation logic;
- change Skills, prompts, or specialist agents;
- add dependencies, migrations, provider code, Context, Tools, Patch logic, Commands, Evidence, Receipts, CLI behavior, or gate scripts;
- remove implementation-like assets;
- sequence the final Planning Round Register;
- begin Prompt 4;
- issue build authorization.

## Exact next action

After final closeout-head validation, owner review, acceptance, and integration, run **Prompt 4 — Identify and sequence remaining planning rounds** against current `main`.

Do not begin Prompt 4 in this work package.
