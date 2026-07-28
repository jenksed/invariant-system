# P0-W18: Reconcile product, scope, and minimum architecture

**Document type:** Planning work package  
**Status:** In progress  
**Branch:** `work/p0-w18-product-scope-architecture`  
**Depends on:** P0-W17 integrated through pull request 22  
**Scope:** Product, scope, and architecture planning only

## Objective

Reconcile Kiln's product boundary, smallest useful workflow, Run model, minimum architecture, capability sequence, delivery targets, and remaining planning domains.

This pass shall update current planning authorities. It shall not implement or repair runtime, tests, CI, development-agent scripts, JSON Schemas, Skills, prompts, agents, or gate scripts.

## Observed current state and evidence

- `main` begins this pass at merge commit `ef487c432a04de705e58ec79569abe5bb51e3d7a`.
- Pull request 22 integrated the Prompt 1 planning-completion baseline.
- Pull request 21 integrated the P0-W16 verification closeout immediately before pull request 22.
- `docs/PLANNING-COMPLETION-BASELINE.md` exists and defines the Prompt 2 inputs.
- Product source remains one dependency-free Mix project, one empty OTP supervisor, one version function, and one version test.
- No P1 slice is implemented, demonstrated, validated, or supported by an aggregate Receipt.
- The current roadmap begins with a simulated Run graph and TUI before a real model-backed workflow.
- The current version 0.1 target is read-only through P1-S05.
- The current Run Model contains a process-per-active-Run supervision example that conflicts with the integrated architecture.
- The current source-layout guide pre-creates broad subsystem directories that do not match the P1-S01 module map.
- Current JSON Schemas remain planning and conformance scaffolding.

## Material baseline change after P0-W17

Pull request 21 merged before pull request 22. Its closeout record resolves the earlier Prompt 1 conflict about P0-W16 verification Evidence being split between `main` and an open pull request.

No other observed post-baseline change alters the Prompt 1 product or implementation findings.

## Assumptions and unknowns

### Assumptions

- **P0-W18-A01:** One developer remains the initial and primary user.
- **P0-W18-A02:** One local active Repository is sufficient for the first useful workflow.
- **P0-W18-A03:** A coding harness must complete a narrow change and verification loop to be meaningfully better than a generic model wrapper.
- **P0-W18-A04:** Owner integration of this pass will constitute acceptance of its proposed roadmap and architecture changes.

### Unknowns

- **P0-W18-U01:** Exact SQLite library, schema, migration, and transaction implementation.
- **P0-W18-U02:** Exact provider authentication, streaming, cancellation, and rate-limit implementation.
- **P0-W18-U03:** Exact cross-platform process-tree termination mechanism.
- **P0-W18-U04:** Exact Patch format and rollback implementation.
- **P0-W18-U05:** Exact retention periods for Artifacts, raw output, and historical Context packages.
- **P0-W18-U06:** Exact TUI library acceptance and headless support.
- **P0-W18-U07:** Whether a managed worktree is required after the single-writer alpha proves value.

These unknowns shall remain visible for Prompt 4. This pass shall not invent implementation answers.

## Requirements

- **P0-W18-R01:** The pass shall define one primary user problem that is not expressed as agent orchestration or protocol support.
- **P0-W18-R02:** The pass shall define enforceable non-goals that constrain early architecture and delivery.
- **P0-W18-R03:** The pass shall identify the smallest complete workflow that is meaningfully better than a generic coding-agent wrapper.
- **P0-W18-R04:** The pass shall define the minimum Run, Task, Session, and Project relationships required by that workflow.
- **P0-W18-R05:** The pass shall resolve the process-per-active-Run conflict and justify every near-term process boundary.
- **P0-W18-R06:** The pass shall classify all material planned capabilities by current necessity.
- **P0-W18-R07:** The pass shall define a minimum credible architecture and source layout without pre-creating the full roadmap.
- **P0-W18-R08:** The pass shall preserve protocol neutrality and select integrations through a smallest-reliable-boundary policy.
- **P0-W18-R09:** The pass shall define inspectable Context, Tool, Skill, security, Evidence, Artifact, Receipt, and completion boundaries.
- **P0-W18-R10:** The pass shall define credible first-month and twelve-week outcomes for one developer.
- **P0-W18-R11:** The pass shall identify remaining planning domains for Prompt 4 without sequencing the final register.
- **P0-W18-R12:** The pass shall not issue build authorization.

## Proposed changes

1. Add one focused product-scope and minimum-architecture specification.
2. Narrow the README to the reconciled product, smallest useful workflow, and delivery boundary.
3. Replace the architecture's early component map with the minimum single-Run change-loop architecture plus an adjacent delegated-work expansion.
4. Replace the current simulated-TUI-first roadmap with a usable CLI-first sequence.
5. Reconcile implementation slices and acceptance-gate planning with the reduced sequence.
6. Reconcile the Run Model with no process per Run, one first-month Root Run, and bounded later Child Runs.
7. Narrow Project Provenance hierarchy and process language.
8. Replace broad early source-layout scaffolding with an earned-namespace rule and first-target layout.
9. Add a proposed ADR for the single-Run change-loop-first delivery order.
10. Update planning and ADR indexes and the P0-W17 baseline status.

## Expected files or components

| Path | Expected change | Status |
| --- | --- | --- |
| `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md` | Focused Prompt 2 authority | Proposed |
| `README.md` | Reconciled product summary and target | Proposed |
| `docs/ARCHITECTURE.md` | Minimum architecture and process ownership | Proposed |
| `docs/ROADMAP.md` | Reduced CLI-first delivery sequence | Proposed |
| `docs/IMPLEMENTATION-SLICES.md` | Reconciled slices and targets | Proposed |
| `docs/SLICE-ACCEPTANCE-GATES.md` | Reconciled aggregate proof planning | Proposed |
| `docs/RUN-MODEL.md` | Minimum Run model and process rule | Proposed |
| `docs/PROJECT-PROVENANCE.md` | Supporting rationale narrowed to current hierarchy | Proposed |
| `docs/AGENT-FRIENDLY-CODEBASE.md` | Earned source-layout guidance | Proposed |
| `docs/decisions/0020-single-run-change-loop-first.md` | Proposed roadmap and architecture decision | Proposed |
| `docs/decisions/README.md` | ADR index update | Proposed |
| `docs/PLANNING-COMPLETION-BASELINE.md` | Prompt 1 integration and successor status | Proposed |
| `docs/work/P0-W18-product-scope-architecture.md` | Completion Evidence | In progress |

No production source, test, workflow, script, JSON Schema, Skill, prompt, agent definition, dependency, or runtime configuration shall change.

## Acceptance criteria

- **P0-W18-AC01:** Kiln has one concise product definition, primary user, problem, differentiation, constraints, and success standard.
- **P0-W18-AC02:** Non-goals constrain product, architecture, permissions, and delivery.
- **P0-W18-AC03:** The smallest useful workflow completes Intent through accepted verified change without requiring Child Runs, a TUI, broad brokerage, protocols, code intelligence, or cross-project retrieval.
- **P0-W18-AC04:** The Run model uses a single Root Run first, retains Task-versus-Run separation, and defers nested Child Runs.
- **P0-W18-AC05:** No permanent process exists merely because a Run, Task, Session, Capability, Attention item, Artifact, or Evidence record exists.
- **P0-W18-AC06:** Every near-term process owns a live resource, concurrency, timing, cancellation, streaming, subscription, or fault-isolation boundary.
- **P0-W18-AC07:** Event journaling is justified only by restart, replay, audit, synchronization, and unknown-effect recovery requirements.
- **P0-W18-AC08:** Every material planned capability has an explicit classification and reconsideration trigger.
- **P0-W18-AC09:** The source-layout conflict is resolved without creating source files.
- **P0-W18-AC10:** Context, Tool-schema, Skill, local-first, security, Evidence, Artifact, Receipt, and completion boundaries are explicit and inspectable.
- **P0-W18-AC11:** First-month and twelve-week outcomes are coherent vertical workflows for one developer.
- **P0-W18-AC12:** Remaining planning domains and build blockers are explicit.
- **P0-W18-AC13:** Prompt 3 can inspect current implementation and scaffolding against one coherent target.
- **P0-W18-AC14:** The final diff contains planning and status files only.
- **P0-W18-AC15:** Repository validation passes on the exact final branch head.

## Deterministic verification

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

The pass shall also inspect:

- current file authority and status;
- product and roadmap consistency;
- source-layout consistency;
- Run and process consistency;
- capability classifications;
- delivery targets;
- the final diff against `main`;
- absence of production, test, workflow, script, Schema, Skill, prompt, agent, dependency, or runtime changes.

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P0-W18-E01 | AC01 through AC03 | Product specification, README, and workflow sections |
| P0-W18-E02 | AC04 through AC07 | Run Model, architecture process table, and journal rationale |
| P0-W18-E03 | AC08 | Capability classification table |
| P0-W18-E04 | AC09 | Source-layout section and Agent-Friendly Codebase diff |
| P0-W18-E05 | AC10 | Context, security, and Evidence boundary sections |
| P0-W18-E06 | AC11 | Roadmap, slices, and gate plan |
| P0-W18-E07 | AC12 through AC13 | Remaining-domain and blocker register |
| P0-W18-E08 | AC14 | Final compare against `main` |
| P0-W18-E09 | AC15 | Final-head GitHub CI run |

## Explicit exclusions

P0-W18 does not:

- implement a Run, Session, Task, provider, Context package, Patch, Command, journal, Artifact store, CLI, TUI, broker, or verifier;
- repair preflight, CI, Skills, prompts, agents, or gate scripts;
- change JSON Schemas;
- select a SQLite, TUI, property-test, telemetry, parser, or process-control dependency;
- design every lifecycle transition or retention rule;
- define the final Planning Round Register;
- authorize implementation.
