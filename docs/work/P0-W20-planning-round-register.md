# P0-W20: Define and sequence remaining planning rounds

**Document type:** Planning work package  
**Status:** Implemented; final verification pending  
**Branch:** `work/p0-w20-planning-round-register`  
**Depends on:** P0-W19 integrated through pull request 24  
**Scope:** Planning-domain classification, focused-round definition, dependency sequencing, and Prompt 5 handoff only

## Objective

Define the smallest complete set of focused planning rounds that must run before Kiln can become planning-ready for the first-month Single-Run Change Alpha and the twelve-week Trustworthy Delegated CLI.

This work package classifies and sequences unresolved decisions. It does not execute a focused planning round, change implementation, create a prototype, create conformance scaffolding, or issue build authorization.

## Observed current state and evidence

- Pull request 22 integrated the Prompt 1 baseline at `ef487c432a04de705e58ec79569abe5bb51e3d7a`.
- Pull request 23 integrated Prompt 2 at `33da2a718d8d5305bf89035503ac372f07e80a6e`.
- Pull request 24 integrated Prompt 3 at `0dba694f2a54ab517a2c43bbbd5c77f526a02e65`.
- The Prompt 3 merge was the current `main` head when P0-W20 began.
- No post-Prompt-3 commit changed the product target, implementation inventory, dispositions, first-month target, twelve-week target, or known planning dependencies.
- Prompt 3 records 33 implementation units and identifies lifecycle, journal, provider, Context, mutation, Command, Evidence, Receipt, CLI, and Child planning dependencies.
- Production source remains a dependency-free Mix bootstrap with no implemented product workflow.
- Current preflight still enforces P0 work-package grammar and obsolete plan headings. P0-W20 preserves those headings without treating the behavior as P1 conformance.

## Assumptions and unknowns

### Assumptions

- The accepted product direction in ADR 0020 remains authoritative.
- P0-W21 and later P0 work identifiers remain the current focused-planning coordinate because current development process and preflight recognize that convention.
- Prompt 5 will run once for each required focused round.
- Prompt 6, Prompt 7, and Prompt 8 will run separately for the first-month and delegated authorization boundaries.

### Unknowns resolved by this pass

- Five focused rounds are required before the first-month authorization wave.
- Two additional rounds are required before the twelve-week delegated target.
- No planning prototype is required.
- Two owner decisions remain: first provider and disclosure mode; first supported host and architecture.
- P0-W21 and P0-W22 are the only safe initial parallel pair.

### Unknowns intentionally retained

- Detailed answers owned by P0-W21 through P0-W27.
- Whether Prompt 8 will authorize either bounded implementation wave.
- Which Prompt 6 candidates will be accepted as conformance scaffolding.
- Whether implementation Evidence will require a later round to reopen one planning-dependent disposition.

## Requirements

- Revalidate the accepted Prompt 1 through Prompt 3 authorities.
- Inventory every material unresolved planning domain.
- Convert domains into exact decision questions.
- Assign one planning classification to every material domain.
- Define the smallest sufficient set of focused planning rounds.
- Use stable P0 work identifiers and provide a complete Prompt 5 invocation bundle for every required round.
- Define acyclic dependencies, safe parallelism, merge order, and conflict rules.
- Define first-month and twelve-week planning-readiness gates.
- Identify deferred domains, owner decisions, prototype dependencies, Prompt 3 dispositions to revisit, and Prompt 6 conformance candidates.
- Preserve Prompt 7 as the final independent review and Prompt 8 as the only build-authorization pass.
- Keep all changes planning-only.

## Proposed changes

P0-W20 completed these planning-control changes:

1. Added one authoritative Planning Round Register.
2. Added one exact-path input specification consumed by every Prompt 5 bundle.
3. Added one planning authority index with Prompt 1 through Prompt 3 integration equivalents and current next action.
4. Defined five first-month rounds and two delegated rounds.
5. Defined owner, prototype, deferred, disposition-review, conformance-candidate, risk, reduction, dependency, parallelization, and readiness registers.
6. Kept existing canonical product and subject authorities unchanged because Prompt 4 did not need to reopen or rewrite them.
7. Kept build authorization denied.

## Files or components expected to change

### Added

- `docs/PLANNING.md` — planning authority index, integration ledger, process, and next action.
- `docs/PLANNING-ROUND-REGISTER.md` — authoritative Prompt 4 planning control.
- `docs/PLANNING-ROUND-INPUTS.md` — exact repository paths for each focused round and Prompt 5 bundle.
- `docs/work/P0-W20-planning-round-register.md` — work record and verification Evidence.

### Deliberately unchanged

- `docs/ROADMAP.md` remains product slice and implementation-order authority.
- Prompt 2 product, architecture, Run, Session, slice, and gate authorities remain accepted inputs.
- Prompt 3 implementation inventory and dispositions remain accepted inputs.
- Stale branch-era headers in earlier integrated documents are recorded by the planning index and do not alter the accepted current target. A later bounded status-normalization pass may correct them without changing decisions.

No production source, test, JSON Schema, dependency, runtime configuration, CI workflow, script, preflight behavior, Skill, prompt, specialist-agent definition, prototype, gate script, or executable scaffold changed.

## Acceptance criteria

| Criterion | Status before final CI | Evidence |
| --- | --- | --- |
| Prompt 1 through Prompt 3 integrated equivalents recorded | Pass | `docs/PLANNING.md`; PR and compare Evidence |
| Every material unresolved domain classified | Pass | Planning Round Register section 6 |
| Every first-month blocker has an owner | Pass | P0-W21 through P0-W25 and OD-01/OD-02 |
| Every twelve-week dependency visible | Pass | P0-W26, P0-W27, dependency graph, readiness gate |
| Every round has exact questions and complete required fields | Pass | seven round entries |
| Every round has exact authoritative paths | Pass | `docs/PLANNING-ROUND-INPUTS.md` |
| Every round has a completion gate | Pass | seven targeted matches |
| Every round has a Prompt 5 bundle | Pass | seven targeted matches |
| Dependency graph is valid and acyclic | Pass | register section 9 |
| Safe and unsafe parallelism is explicit | Pass | register section 10 |
| Deferred domains are outside first-month prerequisites | Pass | sections 6, 9, 11, and 14 |
| Prototype register complete | Pass | no planning prototype required |
| Owner register complete | Pass | OD-01 and OD-02 |
| Prompt 3 dispositions mapped to rounds | Pass | section 17 |
| Prompt 6 candidates identified but not created | Pass | section 18 |
| Prompt 7 remains immediately before Prompt 8 | Pass | sections 1, 9, 11, 12, and 21 |
| Documentation-only diff | Pass | GitHub compare against `main` |
| Design-head Repository validation | Pass | CI run `30416045818` |
| Exact final-head Repository validation | Pending | final closeout-head CI required |

## Verification commands

Current CI ran the Repository-equivalent checks on design head `3e2f555c899c91360696fb12fde1fe63d32f6fec`:

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

CI run `30416045818` passed:

- Vale prose validation;
- current agent-preflight behavior tests;
- Project agent-asset validation;
- dependency installation;
- formatting;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit.

The preflight result proves the current obsolete P0 behavior still passes. It does not prove P1 branch or plan compatibility.

Targeted validation also proved:

- seven required round identities;
- seven completion-gate headings;
- seven Prompt 5 invocation-bundle headings;
- exact input paths for every round;
- one acyclic dependency graph;
- one safe initial parallel pair;
- no deferred domain in the first-month dependency path;
- P0-W21 through P0-W25 own every active first-month decision family;
- Prompt 7 immediately precedes Prompt 8 in both authorization waves.

## Required completion evidence

| Evidence ID | Scope | Evidence |
| --- | --- | --- |
| P0-W20-E01 | Entry gate | PR 22, PR 23, PR 24 merge commits; Prompt 3 merge identical to starting `main` |
| P0-W20-E02 | Domain and question inventory | Planning Round Register sections 5 and 6 and seven decision-question sets |
| P0-W20-E03 | Complete focused rounds | P0-W21 through P0-W27 entries and Prompt 5 bundles |
| P0-W20-E04 | Dependencies and parallelization | register sections 9 and 10 |
| P0-W20-E05 | Supporting registers | deferred, prototype, owner, dispositions, candidates, risks, and reduction sections |
| P0-W20-E06 | Readiness boundaries | first-month, twelve-week, and broad readiness sections |
| P0-W20-E07 | Change boundary | GitHub compare: four added Markdown files, no executable or machine-readable changes |
| P0-W20-E08 | Design verification | CI run `30416045818` on design head `3e2f555c899c91360696fb12fde1fe63d32f6fec` |
| P0-W20-E09 | Final verification | exact closeout-head CI pending |

## Failures and warnings

- Current preflight remains incompatible with accepted P1 ticket grammar and current plan-template headings.
- Current CI still proves obsolete positive preflight behavior.
- Current CI does not validate complete Schema compatibility or documentation references.
- Earlier integrated Prompt 2 and Prompt 3 documents retain some branch-era status headers. The new planning index records their integrated equivalents. These stale headers do not change the accepted target but should not be copied into new focused-round documents.
- P0-W22 cannot complete until OD-01 is answered.
- P0-W24 and P0-W25 cannot complete until OD-02 is answered.
- P0-W26 and P0-W27 require integrated Single-Run Alpha Evidence before final acceptance.
- Build authorization remains denied.

## Explicit exclusions

P0-W20 does not:

- execute Prompt 5;
- answer a focused round's detailed design questions;
- select or add dependencies;
- create or run prototypes;
- modify source, tests, Schemas, CI, scripts, preflight, Skills, prompts, or agents;
- create behaviours, types, validators, fixtures, gates, or other conformance scaffolding;
- change the accepted product target or slice order;
- authorize implementation;
- begin Prompt 6, Prompt 7, or Prompt 8.

## Exact next action

After exact final-head CI, owner review, acceptance, and integration, run Prompt 5 for:

```text
P0-W21 — Root Run lifecycle and durable journal
```

P0-W22 may start in parallel only after P0-W20 is integrated and OD-01 is supplied. Use separate branches. Merge P0-W21 first, then rebase and reconcile P0-W22 before merge.
