# P0-W18: Reconcile product, scope, and minimum architecture

**Document type:** Planning work package  
**Status:** Implemented and verified; not integrated  
**Branch:** `work/p0-w18-product-scope-architecture`  
**Depends on:** P0-W17 integrated through pull request 22  
**Scope:** Product, scope, and architecture planning only

## Objective

Reconcile Kiln's product boundary, smallest useful workflow, Run model, minimum architecture, capability sequence, delivery targets, and remaining planning domains.

This pass updates current planning authorities. It does not implement or repair runtime, tests, CI, development-agent scripts, JSON Schemas, Skills, prompts, agents, dependencies, or gate scripts.

## Observed current state and Evidence

| Observation | Evidence | Date or commit |
| --- | --- | --- |
| Prompt 1 is integrated | Pull request 22 merged at `ef487c432a04de705e58ec79569abe5bb51e3d7a` | 2026-07-28 |
| P0-W16 closeout is integrated | Pull request 21 merged immediately before pull request 22 | 2026-07-28 |
| Prompt 1 baseline exists | `docs/PLANNING-COMPLETION-BASELINE.md` | Branch base |
| Product source remains an early Mix bootstrap | `mix.exs`, `lib/kiln.ex`, `lib/kiln/application.ex`, `test/kiln_test.exs` | Branch base |
| No P1 slice is implemented | No accepted source, demo, aggregate gate, or Receipt | Branch base |
| Existing Schemas are conformance scaffolding | `docs/contracts/README.md` and current Schema files | Branch base |
| Earlier roadmap begins with simulated Runs and TUI | Historical ADR 0019 and pre-P0-W18 Roadmap | Branch base |
| Earlier version 0.1 is read-only | Historical ADR 0019 and pre-P0-W18 Roadmap | Branch base |
| Run Model contained process-per-active-Run example | Pre-P0-W18 `docs/RUN-MODEL.md` | Branch base |
| Source guide pre-created broad subsystem directories | Pre-P0-W18 `docs/AGENT-FRIENDLY-CODEBASE.md` | Branch base |

## Material baseline change after P0-W17

Pull request 21 resolved the Prompt 1 finding that P0-W16 verification Evidence was split between `main` and an open pull request.

No post-baseline production change invalidated the Prompt 1 product or implementation findings before P0-W18 began.

## Assumptions and unknowns

### Assumptions

- **P0-W18-A01:** One developer remains the initial and primary user.
- **P0-W18-A02:** One local active Repository is sufficient for the first useful workflow.
- **P0-W18-A03:** A coding harness must complete a narrow change and verification loop to be meaningfully better than a generic model wrapper.
- **P0-W18-A04:** Owner integration of this pass will accept its proposed roadmap and architecture changes.

### Unknowns

- **P0-W18-U01:** Exact SQLite library, schema, migration, and transaction implementation.
- **P0-W18-U02:** Exact provider authentication, streaming, cancellation, and rate-limit implementation.
- **P0-W18-U03:** Exact primary-platform process-tree termination mechanism and later portability.
- **P0-W18-U04:** Exact Patch format, write algorithm, and rollback implementation.
- **P0-W18-U05:** Exact retention periods for Artifacts, raw output, and historical Context packages.
- **P0-W18-U06:** Exact deferred TUI library and headless behavior.
- **P0-W18-U07:** Whether managed worktrees are required after the single-writer alpha proves value.

Prompt 4 must evaluate these planning domains. P0-W18 does not invent implementation answers.

## Requirements

- **P0-W18-R01:** Define one primary user problem that is not Agent orchestration or protocol support.
- **P0-W18-R02:** Define enforceable non-goals that constrain early architecture and delivery.
- **P0-W18-R03:** Identify the smallest complete workflow that is meaningfully better than a generic coding-agent wrapper.
- **P0-W18-R04:** Define the minimum Project, Session, Task, Run, and later Child relationships.
- **P0-W18-R05:** Resolve process-per-active-Run and justify every near-term process boundary.
- **P0-W18-R06:** Classify all material planned capabilities by current necessity.
- **P0-W18-R07:** Define a minimum architecture and earned source layout.
- **P0-W18-R08:** Preserve protocol neutrality and smallest-reliable integration selection.
- **P0-W18-R09:** Define inspectable Context, Tool, Skill, security, Evidence, Artifact, Receipt, and completion boundaries.
- **P0-W18-R10:** Define credible first-month and twelve-week outcomes.
- **P0-W18-R11:** Identify remaining planning domains for Prompt 4.
- **P0-W18-R12:** Do not issue build authorization.

## Implemented changes

P0-W18 proposes these decisive corrections:

1. Kiln is a local-first coding execution ledger and control plane for one developer.
2. The first useful product is one durable CLI Root Run that completes a real source change.
3. Version 0.1 includes one read-only Scout Child and one independent Verifier Child after the Root workflow works.
4. Maximum Child depth is one and maximum active Child count is one through version 0.1.
5. A separate Root Task is not required initially.
6. No process exists merely because a Run or another domain record exists.
7. SQLite journaling is limited to concrete recovery, audit, replay, duplicate prevention, and unknown-effect requirements.
8. One selected writable checkout and one mutation owner precede managed worktrees.
9. The CLI is complete and permanent. The TUI is deferred beyond twelve weeks.
10. At most four Tool schemas enter a first-month model invocation.
11. A general Capability broker, model router, Context retrieval framework, Skills, code intelligence, protocols, telemetry, and local project intelligence are deferred.
12. One real source change is the first-month milestone.
13. A trustworthy delegated CLI is the twelve-week version 0.1 milestone.
14. Existing JSON Schemas remain unchanged and become Prompt 3 disposition targets.
15. ADR 0020 proposes partial supersession of ADR 0019's order and milestone while retaining vertical-slice discipline.

## Authoritative files changed

### Added

- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`
- `docs/work/P0-W18-product-scope-architecture.md`

### Rewritten or narrowed

- `README.md`
- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/RUN-MODEL.md`
- `docs/SESSION-MODEL.md`
- `docs/DELEGATED-WORK.md`
- `docs/PROJECT-STEWARDSHIP.md`
- `docs/PROJECT-PROVENANCE.md`
- `docs/CLI-TUI.md`
- `docs/PROTOCOL-CAPABILITY-MAP.md`
- `docs/AGENT-FRIENDLY-CODEBASE.md`
- `docs/contracts/README.md`
- `docs/PLANNING-COMPLETION-BASELINE.md`
- `docs/decisions/0019-implement-kiln-through-vertical-product-slices.md`
- `docs/decisions/README.md`

### Unchanged executable and machine-readable areas

- production source;
- production tests;
- CI workflows;
- development scripts;
- JSON Schema files;
- dependencies and runtime configuration;
- development Skills;
- prompt templates;
- specialist-agent definitions;
- planned gate script paths.

## Acceptance criteria

| Criterion | Status | Evidence |
| --- | --- | --- |
| P0-W18-AC01 product definition | Pass | README and product-scope specification |
| P0-W18-AC02 enforceable non-goals | Pass | Product-scope specification and README |
| P0-W18-AC03 complete smallest workflow | Pass | First-month single-Run change loop |
| P0-W18-AC04 reconciled Run model | Pass | Run and Session Models |
| P0-W18-AC05 no process per domain noun | Pass | Architecture, Run Model, source-layout rules |
| P0-W18-AC06 justified near-term processes | Pass | Architecture process ownership table |
| P0-W18-AC07 bounded journal rationale | Pass | Architecture and product-scope specification |
| P0-W18-AC08 capability classifications | Pass | Product-scope classification tables |
| P0-W18-AC09 source-layout conflict | Pass | Agent-Friendly Codebase Rules |
| P0-W18-AC10 Context, security, Evidence boundaries | Pass | Product-scope specification and Architecture |
| P0-W18-AC11 delivery targets | Pass | Roadmap and Implementation Slices |
| P0-W18-AC12 remaining planning domains | Pass | Product-scope assessment |
| P0-W18-AC13 coherent Prompt 3 target | Pass | Contract index, affected-scaffolding register, and current authorities |
| P0-W18-AC14 documentation-only diff | Pass | Compare against `main`: 21 documentation files |
| P0-W18-AC15 Repository validation | Pass | GitHub CI run `30411615027` on design head `3f2d2eadd611ba0dca1f5512bc89872ec37d6eb3` |

## Verification executed

The design head `3f2d2eadd611ba0dca1f5512bc89872ec37d6eb3` passed GitHub CI run `30411615027`:

- Vale;
- agent preflight behavior;
- Project agent-asset validation;
- dependency installation;
- Elixir formatting;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit.

An earlier head passed every executable test step but failed Vale on two uses of a forbidden marketing word. P0-W18 corrected the text and did not weaken the rule.

A passing preflight test proves that obsolete P0 behavior still passes. It does not prove current P1 slice-ticket support.

This closeout commit requires one final exact-head CI run before integration.

## Required completion Evidence

| Evidence ID | Criteria | Evidence |
| --- | --- | --- |
| P0-W18-E01 | AC01–AC03 | Product specification, README, and primary workflow |
| P0-W18-E02 | AC04–AC07 | Run Model, Session Model, Architecture process and journal sections |
| P0-W18-E03 | AC08 | Capability classification and reconsideration triggers |
| P0-W18-E04 | AC09 | Earned namespace and deferred namespace rules |
| P0-W18-E05 | AC10 | Context, Tool, security, Evidence, Artifact, Receipt, and completion sections |
| P0-W18-E06 | AC11 | Roadmap, slice definitions, and planned aggregate gates |
| P0-W18-E07 | AC12–AC13 | Remaining planning-domain assessment and Prompt 3 affected-scaffolding register |
| P0-W18-E08 | AC14 | GitHub compare against `main` |
| P0-W18-E09 | AC15 | GitHub CI run `30411615027`; final closeout-head run pending |

## Failures and warnings

- Current preflight and its tests remain intentionally obsolete and unchanged.
- Current Schema files remain intentionally unchanged and may conflict with the reconciled minimum subset.
- Existing accepted invariants describe some broader long-term maxima. P0-W18 narrows version 0.1 timing and limits through proposed ADR 0020 without renumbering the stable register.
- Exact dependency, persistence, Patch, process-control, provider, retention, and later TUI decisions remain unresolved.
- Build authorization remains denied.

## Explicit exclusions

P0-W18 does not:

- implement any product capability;
- repair preflight, CI, Skills, prompts, agents, or gate scripts;
- change JSON Schemas;
- select runtime dependencies;
- design every transition or retention rule;
- define the final Planning Round Register;
- perform the final adversarial review;
- authorize implementation.

## Exact next action

After final closeout-head validation, owner review, acceptance, and integration, run **Prompt 3 — Reconcile scaffolded, partial, and completed-looking implementation** against current `main`.

Do not begin Prompt 4 or implementation before Prompt 3 passes.
