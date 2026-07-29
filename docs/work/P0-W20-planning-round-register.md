# P0-W20: Define and sequence remaining planning rounds

**Document type:** Planning work package  
**Status:** In progress  
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
- The Prompt 3 merge is the current `main` head at the start of P0-W20.
- No post-Prompt-3 commit changes the product target, implementation inventory, dispositions, first-month target, twelve-week target, or known planning dependencies.
- Prompt 3 records 33 implementation units and identifies lifecycle, journal, provider, Context, mutation, Command, Evidence, Receipt, CLI, and Child planning dependencies.
- Production source remains a dependency-free Mix bootstrap with no implemented product workflow.
- Current preflight still enforces P0 work-package grammar and obsolete plan headings. P0-W20 preserves those headings without treating the behavior as P1 conformance.

## Assumptions and unknowns

### Assumptions

- The accepted product direction in ADR 0020 remains authoritative.
- P0-W20 can use P0-W21 and later P0 work identifiers for focused planning rounds because current development process and preflight already recognize that convention.
- The smallest safe sequence may combine tightly coupled domains when separation would duplicate authority.
- Prompt 5 will run once for each required focused round.

### Unknowns

- The final count of first-month focused rounds.
- Whether any empirical prototype must precede a planning decision.
- Which questions require explicit owner selection rather than evidence-based planning.
- Which rounds can run in parallel without conflicting authority.
- The exact conformance candidates Prompt 6 should evaluate after focused planning.

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

1. Add one authoritative Planning Round Register.
2. Update the Roadmap planning-control section to reference the register and integrated Prompt 3 state.
3. Correct stale integrated status headers only where needed for current authority.
4. Complete this work record with exact final-head Evidence.

## Files or components expected to change

- `docs/PLANNING-ROUND-REGISTER.md` — new planning-control authority.
- `docs/ROADMAP.md` — current Phase 0 sequence and register link.
- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md` — integrated status correction and register link if required.
- `docs/ARCHITECTURE.md` — integrated status correction if required.
- `docs/IMPLEMENTATION-SLICES.md` — integrated status correction if required.
- `docs/SLICE-ACCEPTANCE-GATES.md` — integrated status correction if required.
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md` — integrated status correction and planning-register link if required.
- `docs/work/P0-W19-implementation-scaffold-reconciliation.md` — integrated status correction if required.
- `docs/work/P0-W20-planning-round-register.md` — completion record.

No production source, test, JSON Schema, dependency, runtime configuration, CI workflow, script, preflight behavior, Skill, prompt, specialist-agent definition, prototype, gate script, or executable scaffold shall change.

## Acceptance criteria

- The current Prompt 1 through Prompt 3 integrated equivalents are recorded.
- Every material unresolved domain has one classification and authoritative Evidence.
- Every first-month blocker has an owning focused round, owner decision, or explicit bounded implementation discretion.
- Every twelve-week planning dependency is visible.
- Every required round has exact questions, inputs, constraints, non-goals, outputs, completion gate, unlocks, remaining blocks, dispositions, conformance candidates, dependencies, parallelization, blast radius, and Prompt 5 bundle.
- The round graph is acyclic.
- No deferred domain is a first-month prerequisite.
- Prompt 7 remains immediately before Prompt 8.
- The final diff is planning-only.
- Exact final-head CI passes.

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

Targeted checks must also prove:

- all authoritative files exist;
- Prompt 3's disposition register is integrated;
- every required round has one complete Prompt 5 bundle and completion gate;
- every dependency names a valid round identifier;
- no dependency cycle exists;
- no deferred domain is a first-month prerequisite;
- every first-month decision question has an owner;
- Prompt 7 remains last before Prompt 8.

## Required completion evidence

- P0-W20-E01: Prompt 1 through Prompt 3 integrated merge Evidence.
- P0-W20-E02: planning-domain and decision-question inventory.
- P0-W20-E03: complete Planning Round Register.
- P0-W20-E04: dependency and parallelization validation.
- P0-W20-E05: owner, prototype, deferred, disposition, and conformance registers.
- P0-W20-E06: first-month and twelve-week planning gates.
- P0-W20-E07: final compare against `main`.
- P0-W20-E08: exact final-head CI run and job steps.

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
