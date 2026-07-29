# P0-W28: Wave A conformance scaffolding

**Document type:** Implementation plan and closeout record  
**Status:** Complete, verified, accepted, and integrated  
**Branch:** `work/p0-w28-wave-a-conformance`  
**Final branch head:** `7b9afe5552ca0d336d343d4bfbe17ce7d14cc955`  
**Integrated through:** Pull request 34, merge commit `57a5790d2266cf1ab59f107d0b429c31c618e0ae`  
**Depends on:** P0-W21 through P0-W25 integrated  
**Build authorization:** Not issued

## Objective

Create only the executable and machine-readable rails justified by the integrated first-month planning. Keep all external effects and product workflow visibly unimplemented.

## Observed current state

At entry, P0-W21 through P0-W25 were integrated, production still contained only bootstrap behavior, preflight used obsolete work grammar, and broad historical Schemas were not an accepted first-month contract set.

## Assumptions and unknowns

### Assumptions

- Standard Python 3 was available for dependency-free semantic validation.
- Conformance constants and external-boundary behaviours could be added without implementing product runtime.

### Unknowns

- Prompt 8-A remained responsible for deciding which scaffolds should be retained, revised, removed, or deferred.
- Later implementation Evidence could require bounded contract revision but could not silently widen scope.

## Requirements

P0-W28 required:

- current P0 and P1 branch and plan grammar;
- accepted lifecycle, Tool, Patch, Evidence, and CLI constants;
- provider and macOS Command-host behaviour declarations;
- one first-month JSON Schema;
- positive and protected negative fixtures;
- recurring semantic validation;
- CI and local validation wiring;
- no fake success or external effect.

## Security boundary

The work permitted static constants, pure transition checks, behaviour declarations, fixture parsing, deterministic semantic validation, preflight, and CI changes.

It denied provider calls, source mutation, SQLite state creation, Command execution, credential reads, product CLI actions, fallback, Child Runs, and Wave B scaffolding.

## Changes integrated

Prompt 6-A integrated:

- repaired P0 work-package and P1 slice-ticket preflight grammar;
- preflight behavior tests;
- `Kiln.Conformance.FirstMonth` accepted constants and transition shapes;
- `Kiln.Conformance.Provider` callback boundary;
- `Kiln.Conformance.CommandHost` callback boundary;
- first-month conformance tests;
- `docs/contracts/kiln-first-month.schema.json`;
- ten positive fixtures;
- eleven protected negative fixtures;
- `scripts/validate_first_month_contracts.py` semantic validation;
- CI and `scripts/check` wiring;
- contract-authority documentation and integrated planning status updates.

Pull request 34 changed 20 files with 1,729 additions and 254 deletions.

It added no product Store, Session workflow, provider adapter, Context builder, Repository reader, Patch engine, mutation Worker, Command runner, native helper, Artifact store, Evidence evaluator, product CLI, release, installer, or Receipt sealer.

## Expected files or components

All planned P0-W28 components were integrated. No future implementation file was reserved or created.

## Acceptance criteria

- **P0-W28-AC01:** Pass. P0 and P1 preflight fixtures pass; protected branches and malformed grammar fail.
- **P0-W28-AC02:** Pass. Elixir tests protect accepted states, transitions, Tools, Patch operations, proof results, limits, CLI exits, and behaviour callbacks.
- **P0-W28-AC03:** Pass for semantic validation. Positive fixtures pass and protected negative fixtures fail for their expected semantic reason.
- **P0-W28-AC04:** Pass at integration time. No external-effect runtime implementation was added.
- **P0-W28-AC05:** Pass. Exact final-head CI succeeded.

Prompt 8-A later revised the AC04 test mechanism because an explicit list of absent future module names created unnecessary namespace lock-in. The underlying no-runtime-implementation fact remains true.

## Deterministic verification

The final head passed:

```bash
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

GitHub Actions CI run `30425270052` completed successfully on exact head `7b9afe5552ca0d336d343d4bfbe17ce7d14cc955`.

## Demo contribution

No product demo was claimed. P0-W28 supplied executable planning rails for independent review.

## Required completion Evidence

| Evidence ID | Criterion | Result |
| --- | --- | --- |
| P0-W28-E01 | P0-W28-AC01 | preflight behavior passed in CI |
| P0-W28-E02 | P0-W28-AC02 | ExUnit conformance tests passed |
| P0-W28-E03 | P0-W28-AC03 | semantic fixture validator passed |
| P0-W28-E04 | P0-W28-AC04 | exact PR compare contained conformance work only |
| P0-W28-E05 | P0-W28-AC05 | CI `30425270052` succeeded |

### Slice gate contribution

P0-W28 contributes conformance Evidence to Prompt 8-A only. It does not satisfy a P1 slice gate.

## Explicit exclusions

Prompt 6-A did not:

- implement the product;
- add Exqlite or HTTP runtime dependencies;
- create migrations or state;
- invoke MiniMax;
- disclose Repository source;
- mutate files;
- run external Commands;
- create a native helper;
- evaluate completion Evidence;
- seal a product Receipt;
- create a release or installer;
- add Child, Scout, Verifier, Attention, TUI, or Wave B behavior;
- issue build authorization.

## Completion record

**Result:** Complete and verified

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W28-AC01 | Pass | P0-W28-E01 | current work grammar is enforced |
| P0-W28-AC02 | Pass | P0-W28-E02 | accepted constants and callbacks are protected |
| P0-W28-AC03 | Pass | P0-W28-E03 | semantic fixtures passed |
| P0-W28-AC04 | Pass | P0-W28-E04 | no product runtime entered |
| P0-W28-AC05 | Pass | P0-W28-E05 | exact final-head CI passed |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| full CI workflow | 0 | GitHub Actions run `30425270052` |

### Demo and slice status

- Ticket demo contribution: Pass for conformance review only
- Parent slice gate affected: none
- Slice verification manifest updated: not applicable
- Slice completion claimed: No

### Failures and warnings

- Prompt 6-A's Python validator is a semantic validator, not a complete Draft 2020-12 implementation. Prompt 8-A adds separate pinned Schema validation.
- Prompt 6-A issued no build authorization.

### Remaining unknowns and exclusions

- External-effect behavior remained unimplemented at merge.
- Prompt 8-A controls development authorization.

### Repository state

- Commit: `7b9afe5552ca0d336d343d4bfbe17ce7d14cc955`
- Merge commit: `57a5790d2266cf1ab59f107d0b429c31c618e0ae`
- Branch: `work/p0-w28-wave-a-conformance`
- Diff reviewed: Yes
- Exact CI run: `30425270052`
- Parent slice status after merge: unchanged
