# P0-W20: Define and sequence remaining planning rounds

**Document type:** Planning work package  
**Status:** Implemented and verified; owner acceptance and integration pending  
**Branch:** `work/p0-w20-planning-round-register`  
**Depends on:** P0-W19 integrated through pull request 24  
**Scope:** Planning-domain classification, focused-round definition, dependency sequencing, and Prompt 5 handoff only

## Objective

Define the smallest complete set of focused planning rounds required before Kiln can become planning-ready for the first-month Single-Run Change Alpha and the twelve-week Trustworthy Delegated CLI.

P0-W20 classifies and sequences unresolved decisions. It does not execute a focused round, implement product behavior, create a prototype or conformance scaffold, or issue build authorization.

## Observed current state and evidence

- Prompt 1 integrated through pull request 22 at `ef487c432a04de705e58ec79569abe5bb51e3d7a`.
- Prompt 2 integrated through pull request 23 at `33da2a718d8d5305bf89035503ac372f07e80a6e`.
- Prompt 3 integrated through pull request 24 at `0dba694f2a54ab517a2c43bbbd5c77f526a02e65`.
- The Prompt 3 merge was the current `main` head when P0-W20 began.
- No later commit changed the product target, implementation inventory, dispositions, delivery targets, or planning dependencies.
- Prompt 3 records 33 implementation units and identifies lifecycle, journal, provider, Context, mutation, Command, Evidence, Receipt, CLI, and Child planning dependencies.
- Product source remains a dependency-free Mix bootstrap with no implemented product workflow.
- Current preflight still enforces P0 work grammar and obsolete plan headings. Its passing test is not P1 conformance Evidence.

## Assumptions and unknowns

### Assumptions

- ADR 0020 remains the accepted product-order authority.
- Prompt 5 will run once for each required focused round.
- Prompt 6, Prompt 7, and Prompt 8 will run separately for the first-month and delegated authorization boundaries.

### Resolved by P0-W20

- Five focused rounds precede the first-month authorization wave.
- Two additional focused rounds precede the delegated twelve-week wave.
- P0-W21 and P0-W22 are the only safe initial parallel pair.
- No planning prototype is required.
- Two owner decisions remain: first provider and disclosure mode; first supported host and architecture.

### Intentionally unresolved

- Detailed decisions owned by P0-W21 through P0-W27.
- Which Prompt 6 candidates will be accepted.
- Whether Prompt 8 will authorize either bounded implementation wave.
- Whether later implementation Evidence will require a planning-dependent disposition to reopen.

## Requirements

- Revalidate Prompt 1 through Prompt 3 authority.
- Classify every material unresolved planning domain.
- Convert each active domain into exact decision questions.
- Define the smallest sufficient set of focused planning rounds.
- Provide exact authoritative inputs, constraints, non-goals, outputs, completion gates, implementation unlocks and blocks, dependencies, parallelization, blast radius, and Prompt 5 bundles.
- Define acyclic dependencies and safe merge order.
- Define first-month and twelve-week planning-readiness gates.
- Identify deferred domains, owner decisions, prototype dependencies, Prompt 3 disposition reviews, and Prompt 6 candidates.
- Keep Prompt 7 immediately before Prompt 8 and Prompt 8 as the only authorization pass.
- Keep the diff planning-only.

## Proposed changes

P0-W20 completed these changes:

1. Added `docs/PLANNING-ROUND-REGISTER.md` as the remaining-planning authority.
2. Added `docs/PLANNING-ROUND-INPUTS.md` with exact paths for every Prompt 5 bundle.
3. Added `docs/PLANNING.md` as the planning index and integration ledger.
4. Defined P0-W21 through P0-W25 before the first-month authorization wave.
5. Defined P0-W26 and P0-W27 before delegated version 0.1 authorization.
6. Defined dependency, parallelization, readiness, deferred, prototype, owner, disposition, conformance-candidate, risk, and reduction registers.
7. Kept existing product and slice authorities unchanged.
8. Kept build authorization denied.

## Files or components expected to change

### Added

- `docs/PLANNING.md`
- `docs/PLANNING-ROUND-REGISTER.md`
- `docs/PLANNING-ROUND-INPUTS.md`
- `docs/work/P0-W20-planning-round-register.md`

### Deliberately unchanged

- production source and tests;
- JSON Schemas;
- dependencies and runtime configuration;
- CI workflows and scripts;
- preflight behavior;
- Skills, prompts, and specialist agents;
- executable gates and conformance scaffolding;
- accepted product, architecture, Roadmap, and slice behavior.

Earlier integrated authorities retain some branch-era status headers. `docs/PLANNING.md` records their integrated equivalents. New focused-round documents must not copy the stale status wording.

## Acceptance criteria

| Criterion | Status | Evidence |
| --- | --- | --- |
| Prompt 1 through Prompt 3 integration recorded | Pass | `docs/PLANNING.md` and merge Evidence |
| Every material unresolved domain classified | Pass | Planning Round Register section 6 |
| Every first-month blocker has an owner | Pass | P0-W21 through P0-W25 and OD-01/OD-02 |
| Every twelve-week dependency is visible | Pass | P0-W26, P0-W27, dependency graph, readiness gate |
| Seven complete round entries exist | Pass | P0-W21 through P0-W27 |
| Exact authoritative paths exist for every round | Pass | `docs/PLANNING-ROUND-INPUTS.md` |
| Every round has a completion gate | Pass | seven targeted matches |
| Every round has a Prompt 5 bundle | Pass | seven targeted matches |
| Dependencies are valid and acyclic | Pass | register section 9 |
| Parallel and sequential rules are explicit | Pass | register section 10 |
| Deferred domains are not first-month prerequisites | Pass | sections 6, 9, 11, and 14 |
| Prototype and owner registers are complete | Pass | sections 15 and 16 |
| Prompt 3 dispositions map to rounds | Pass | section 17 |
| Prompt 6 candidates are identified but absent | Pass | section 18 and final diff |
| Prompt 7 immediately precedes Prompt 8 | Pass | sections 1, 9, 11, 12, and 21 |
| Diff is planning-only | Pass | GitHub compare against `main` |
| Design-head CI | Pass | run `30416045818` |
| Closeout-head CI before this status commit | Pass | run `30416135802` |
| Exact final status-head CI | Pending | required because this record changed the head |

## Verification commands

Current CI runs:

```bash
scripts/test-agent-preflight
scripts/validate-agent-assets
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
vale .
```

Design head `3e2f555c899c91360696fb12fde1fe63d32f6fec` passed CI run `30416045818`.

Closeout head `72b04547c9136f6d7036664b89ec257a53a3fd22` passed CI run `30416135802`.

Both runs passed prose, preflight behavior tests, agent-asset validation, dependency installation, formatting, warnings-as-errors compilation, compile-connected cycle detection, and ExUnit.

Targeted validation proved:

- seven required round identities;
- seven completion gates;
- seven Prompt 5 invocation bundles;
- exact input paths for every round;
- one acyclic dependency graph;
- one safe initial parallel pair;
- no deferred first-month prerequisite;
- one owner for every active first-month decision family;
- Prompt 7 immediately before Prompt 8 in both waves.

The current preflight pass remains Evidence for obsolete P0 behavior only.

## Required completion evidence

| Evidence ID | Scope | Evidence |
| --- | --- | --- |
| P0-W20-E01 | Entry gate | PR 22, PR 23, PR 24 merge commits; Prompt 3 merge identical to starting `main` |
| P0-W20-E02 | Domain and question inventory | register sections 5 and 6 and seven question sets |
| P0-W20-E03 | Focused rounds | P0-W21 through P0-W27 and seven Prompt 5 bundles |
| P0-W20-E04 | Dependency and parallelization | register sections 9 and 10 |
| P0-W20-E05 | Supporting registers | sections 14 through 20 |
| P0-W20-E06 | Readiness boundaries | sections 11 through 13 |
| P0-W20-E07 | Change boundary | four added Markdown files; no executable or machine-readable changes |
| P0-W20-E08 | Design verification | CI `30416045818` |
| P0-W20-E09 | Closeout verification | CI `30416135802` |
| P0-W20-E10 | Final status-head verification | pending exact-head CI |

## Failures and warnings

- Current preflight rejects accepted P1 ticket grammar and checks obsolete plan headings.
- Current CI proves obsolete positive preflight behavior and does not validate complete Schema compatibility or documentation references.
- Earlier integrated documents retain some stale branch-era status headers.
- P0-W22 cannot complete until OD-01 is answered.
- P0-W24 and P0-W25 cannot complete until OD-02 is answered.
- P0-W26 and P0-W27 require integrated Single-Run Alpha Evidence before final acceptance.
- Build authorization remains denied.

## Explicit exclusions

P0-W20 does not:

- execute Prompt 5;
- answer focused-round design questions;
- select or add dependencies;
- create or run prototypes;
- modify source, tests, Schemas, CI, scripts, preflight, Skills, prompts, or agents;
- create behaviours, types, validators, fixtures, gates, or other conformance scaffolding;
- change the accepted product target or slice order;
- authorize implementation;
- begin Prompt 6, Prompt 7, or Prompt 8.

## Exact next action

After exact final status-head CI, owner review, acceptance, and integration, run Prompt 5 for:

```text
P0-W21 — Root Run lifecycle and durable journal
```

P0-W22 may start in parallel only after P0-W20 is integrated and OD-01 is supplied. Use separate branches. Merge P0-W21 first, then rebase and reconcile P0-W22 before merge.
