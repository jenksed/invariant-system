# Kiln Planning Completion Baseline

**Document type:** Planning-status audit authority  
**Status:** Proposed on P0-W17  
**Audit date:** 2026-07-28  
**Audited integrated base:** `57493016b052e5c1c1390ca0360845940dc56917`  
**Product authority:** `README.md`  
**Architecture authority:** `docs/ARCHITECTURE.md` and accepted ADRs  
**Implementation-order authority:** `docs/ROADMAP.md`  
**Slice-detail authority:** `docs/IMPLEMENTATION-SLICES.md`  
**Implementation truth:** current source, tests, configuration, executed checks, and current Repository state  
**Build authorization:** Not issued  
**Exact next pass:** Prompt 2 — reconcile product, scope, and architecture

## Purpose

This document establishes the current baseline for the Kiln Planning Completion Sequence.

It does not define a competing product or architecture. It maps current authority, decisions, conflicts, terminology, implementation evidence, scaffolded work, debt, and blockers.

The current architecture and roadmap remain authoritative for their subjects. This audit controls only planning status and the sequence required before build authorization.

## Executive baseline assessment

Kiln no longer has a fragmented top-level architecture.

Pull request 20 integrated:

- one product definition;
- one protocol-neutral architecture;
- one vertical implementation roadmap;
- ten implementation slices;
- aggregate acceptance gates;
- a read-only version 0.1 boundary;
- one first coding task.

The planning repository is coherent at the top level. It is not implementation-ready yet.

The current implementation is still an early bootstrap:

- one dependency-free Mix project;
- one empty OTP supervisor;
- one version function;
- one version test;
- CI and development-agent checks;
- planning documents, ADRs, and JSON Schemas.

No current source or test proves a production Session, Task, Run, event journal, TUI, provider adapter, Capability broker, Context compiler, Command runner, Artifact store, Evidence system, Patch engine, code-intelligence adapter, or local project intelligence runtime.

The main readiness problem has moved from architecture fragmentation to planning-conformance drift:

1. current development scripts reject the first accepted Phase 1 ticket branch grammar;
2. current preflight checks require headings from an obsolete plan template;
3. current `AGENTS.md` points to a historical audit as current authority;
4. integrated documents still contain proposed or in-progress status labels;
5. one Run supervision example conflicts with the integrated no-process-per-Run decision;
6. old source-layout guidance can become accidental architecture;
7. Schema validation evidence exists in planning history, but no current Repository command enforces the contract package;
8. detailed planning and Schemas can appear more complete than the production implementation.

Kiln must complete Prompts 2 through 8 before broad implementation begins.

## Evidence and status categories

This audit uses these categories.

### Observed fact

Current Repository source, configuration, test output, CI output, Git state, or an exact integrated document establishes the statement.

### Accepted decision

An accepted ADR, current owner instruction, or integrated planning authority establishes the direction.

### Proposed decision

A branch, open pull request, candidate plan, or non-accepted document recommends the direction.

### Inferred decision

Several accepted artifacts imply a direction, but no current authority states it directly.

### Assumption

The project temporarily relies on the statement without direct verification.

### Unknown

Current evidence does not establish the answer.

### Conflict

Two current artifacts make incompatible claims or prescribe incompatible behavior.

### Superseded decision

A later accepted authority replaced the earlier decision or sequence.

### Scaffolded work

Structure exists to support later implementation, but the user-visible or runtime behavior does not exist.

### Implemented but unvalidated work

Executable code or configuration exists, but current Evidence does not prove its intended current contract.

### Validated implementation

Current deterministic Evidence proves the behavior against an identified Repository state.

### Build blocker

A defect, unresolved decision, missing gate, or authority conflict prevents safe construction or truthful completion.

No category implies a later category automatically.

# Artifact map

## A01 — `README.md`

- **Intended purpose:** Product identity, boundary, integrated architecture summary, milestone summary, roadmap summary, development entry point, and documentation hierarchy.
- **Apparent authority:** Primary product overview.
- **Actual authority:** Canonical product and milestone summary. It defers architecture detail to `docs/ARCHITECTURE.md` and order to `docs/ROADMAP.md`.
- **Current relevance:** High.
- **Unique information:** Concise product language, non-goals, first milestone, first coding task, and reader entry points.
- **Overlap:** Repeats selected architecture, Run, delegation, Evidence, protocol, and code-intelligence decisions.
- **Contradiction or staleness:** The final status says planning is still being reconciled although P0-W16 is integrated.
- **Implementation implication:** Readers can mistake the integrated milestone description for implemented behavior unless the pre-alpha status remains explicit.
- **Disposition:** Retain as canonical product summary. Correct current planning status. Keep detailed behavior in linked authorities.

## A02 — `docs/ARCHITECTURE.md`

- **Intended purpose:** Integrated architecture and responsibility boundaries.
- **Apparent authority:** Architecture authority.
- **Actual authority:** Canonical architecture authority, constrained by accepted ADRs.
- **Current relevance:** Highest.
- **Unique information:** Minimal system shape, runtime shape, storage classes, responsibility flow, authority boundaries, shared code-intelligence path, Patch Artifact writing choice, and integration rules.
- **Overlap:** Summarizes most subject specifications.
- **Contradiction or staleness:** Its header says integration is proposed on P0-W16 although pull request 20 integrated it.
- **Implementation implication:** All implementation plans must preserve its dependency direction and no-process-per-Run decision.
- **Disposition:** Retain as canonical. Correct integration status. Do not expand it during this audit.

## A03 — `docs/ROADMAP.md`

- **Intended purpose:** Implementation-order authority.
- **Apparent authority:** Roadmap.
- **Actual authority:** Canonical implementation order and milestone authority.
- **Current relevance:** Highest.
- **Unique information:** P1-S01 through P1-S10 order, dependencies, version 0.1 boundary, first twelve-week target, first coding task, exclusions, and roadmap-change policy.
- **Overlap:** Summarizes slice details and protocol timing.
- **Contradiction or staleness:** Its header says integration is proposed. Its Phase 0 table says P0-W16 is in progress although pull request 20 integrated it.
- **Implementation implication:** No implementation ticket can pull later-slice scope forward without an accepted roadmap change.
- **Disposition:** Retain as canonical. Correct integration and P0-W16 status.

## A04 — `docs/IMPLEMENTATION-SLICES.md`

- **Intended purpose:** Detailed vertical slice specifications.
- **Apparent authority:** Detailed roadmap.
- **Actual authority:** Canonical slice-level user value, concepts, modules, security boundaries, tickets, tests, Receipts, demos, exit conditions, and deferred scope.
- **Current relevance:** Highest for implementation planning.
- **Unique information:** Complete P1-S01 through P1-S10 delivery definitions.
- **Overlap:** Repeats subject requirements and roadmap summaries.
- **Contradiction or staleness:** Its header says integration is proposed on P0-W16.
- **Implementation implication:** Tickets implement only the subset required by the current slice.
- **Disposition:** Retain as canonical slice detail. Correct integration status. Prompt 2 must test each slice against product necessity without rewriting it by default.

## A05 — `docs/SLICE-ACCEPTANCE-GATES.md`

- **Intended purpose:** Define aggregate gate identifiers and required proof for each slice.
- **Apparent authority:** Verification plan.
- **Actual authority:** Accepted planning definition for future gates. No listed gate script exists yet.
- **Current relevance:** High.
- **Unique information:** Gate-to-proof mapping and aggregate command names.
- **Overlap:** Acceptance criteria and tests also appear in slice specifications.
- **Contradiction or staleness:** Its header says integration is proposed. It refers to future `scripts/gates/*` commands that are not implemented.
- **Implementation implication:** A future script path in a plan is not current validation capability.
- **Disposition:** Retain as canonical gate plan. Correct integration status. Classify all gate commands as scaffolded requirements until Prompt 3 and later implementation establish them.

## A06 — `docs/PROJECT-PROVENANCE.md`

- **Intended purpose:** Explain why Kiln exists and preserve early product rationale.
- **Apparent authority:** Foundational product definition.
- **Actual authority:** Supporting product rationale. `README.md` and the integrated architecture now control current product language and hierarchy.
- **Current relevance:** Medium to high.
- **Unique information:** Runtime rationale, Project Steward rationale, language choice, non-goals, and trust standard.
- **Overlap:** Product thesis, hierarchy, Run rationale, and boundaries repeat the README and architecture.
- **Contradiction or staleness:** An early hierarchy omits the Project level. The runtime rationale lists “run processes,” which can imply a process per Run.
- **Implementation implication:** Old explanatory language can reintroduce a superseded runtime shape.
- **Disposition:** Retain as supporting explanation. Prompt 2 must narrow or reconcile outdated hierarchy and process wording. Do not treat it as implementation-order authority.

## A07 — `docs/INTERNAL-DOMAIN-MODEL.md`

- **Intended purpose:** Define the protocol-neutral internal domain and critical distinctions.
- **Apparent authority:** Subject authority.
- **Actual authority:** Canonical domain subject specification, subordinate to the integrated architecture and accepted ADRs.
- **Current relevance:** High.
- **Unique information:** Entity responsibilities, identities, lifecycles, persistence roles, security boundaries, forbidden states, and adapter separation.
- **Overlap:** Session, Run, delegation, security, Evidence, and contract documents restate portions.
- **Contradiction or staleness:** Its header says integration is proposed on P0-W06 although the planning stack is on `main`.
- **Implementation implication:** The document is planning, not an implemented type system. Each slice uses only the exercised subset.
- **Disposition:** Retain as canonical subject specification. Prompt 2 must confirm precedence and remove accidental duplication. Correct broad integration-status drift in a focused later status pass if not handled here.

## A08 — `docs/SESSION-MODEL.md`

- **Intended purpose:** Explain Session, Task, Root Run, event, and completion relationships.
- **Apparent authority:** Foundational Session model.
- **Actual authority:** Supporting Session subject specification. The internal domain model controls terminology.
- **Current relevance:** High for P1-S01 through P1-S05.
- **Unique information:** Session lifecycle, Task lifecycle, Root Task, Root Run, and Steward projection.
- **Overlap:** Internal domain, Run model, Project Steward, and delegated work.
- **Contradiction or staleness:** Uses broad “should eventually track” lists that are not slice scope or implementation evidence.
- **Implementation implication:** A field appearing in this document does not belong in P1-S01 unless the slice requires it.
- **Disposition:** Retain and narrow during Prompt 2. Do not implement the complete state inventory as one package.

## A09 — `docs/RUN-MODEL.md`

- **Intended purpose:** Define Run identity, roles, lifecycle, lineage, delegation, authority, and recovery.
- **Apparent authority:** Run subject specification.
- **Actual authority:** Canonical Run subject specification, constrained by `docs/ARCHITECTURE.md`, `docs/INTERNAL-DOMAIN-MODEL.md`, and `docs/DELEGATED-WORK.md`.
- **Current relevance:** Highest for the first slice.
- **Unique information:** Run identity exclusions, role relationships, state vocabulary, Child limits, Worker distinction, and recovery expectations.
- **Overlap:** Internal domain and delegated work.
- **Conflict:** The “Possible runtime supervision” example shows one active Run process per Root, Scout, Verifier, and nested Run. P0-W16 explicitly rejects one permanent process per Run.
- **Implementation implication:** A coding agent could create `Kiln.RunSupervisor` and one process per Run from this obsolete example.
- **Disposition:** Retain as canonical subject specification. Mark the process example superseded and point to the integrated runtime shape. Prompt 2 must reconcile the remaining process language.

## A10 — `docs/PROJECT-STEWARDSHIP.md` and `docs/DELEGATED-WORK.md`

- **Intended purpose:** Define delivery coordination, delegation contracts, Scout, Verifier, Attention, cancellation, delivery, and recovery.
- **Apparent authority:** Subject specifications.
- **Actual authority:** Canonical delegation and Steward boundaries, subordinate to the integrated roadmap.
- **Current relevance:** High for P1-S02 through P1-S05.
- **Unique information:** Role contracts, independent Context, no-silent-blocker rule, result schemas, limits, and authority constraints.
- **Overlap:** Run, Session, Context, Security, CLI/TUI, and Evidence documents.
- **Contradiction or staleness:** Detailed complete contracts can appear to require all fields in the first implementation ticket.
- **Implementation implication:** The first slices must implement only the minimum accepted subset.
- **Disposition:** Retain as subject authority. Prompt 2 must define concise precedence and remove repeated requirements where retrieval cost exceeds value.

## A11 — `docs/CLI-TUI.md`

- **Intended purpose:** Define the initial terminal interaction, navigation, events, snapshots, inputs, and safety rules.
- **Apparent authority:** Interface subject specification.
- **Actual authority:** Canonical terminal-interface boundary, subordinate to P1-S01 scope.
- **Current relevance:** High for P1-S01 and P1-S03.
- **Unique information:** Run-first navigation, client-local state, headless projection requirements, Attention interactions, and renderer boundary.
- **Overlap:** Run Model, delegated work, architecture, slice plan, and interface Schema.
- **Contradiction or staleness:** ExRatatui is selected for a future prototype, but the dependency is absent and not reviewed.
- **Implementation implication:** The library name does not prove a TUI exists or authorize dependency addition.
- **Disposition:** Retain as subject authority. Prompt 3 must classify the dependency decision and required spike or review before implementation.

## A12 — `docs/CAPABILITY-INTEGRATION.md`

- **Intended purpose:** Define integration hierarchy, broker behavior, normalized Tool surface, and protocol selection.
- **Apparent authority:** Capability subject specification.
- **Actual authority:** Canonical Capability integration boundary.
- **Current relevance:** High for P1-S02 and later adapters.
- **Unique information:** Implementation hierarchy, broker responsibilities, duplicate handling, and native Repository boundary.
- **Overlap:** Architecture, Security Model, Context System, and protocol map.
- **Contradiction or staleness:** Header integration status is stale. Complete broker behavior exceeds P1-S02 minimum scope.
- **Implementation implication:** A broker process, registry service, health subsystem, and full catalog are not all required for the first Scout.
- **Disposition:** Retain. Prompt 2 must confirm minimal P1-S02 subset and consolidate repeated policy language by reference.

## A13 — `docs/CONTEXT-SYSTEM.md`

- **Intended purpose:** Define bounded Context compilation, retrieval, authority, budgets, manifests, documentation resolution, and observability.
- **Apparent authority:** Context subject specification.
- **Actual authority:** Canonical Context boundary.
- **Current relevance:** High for P1-S02 and later slices.
- **Unique information:** Smallest-sufficient package, replacement instead of accumulation, authority dimensions, budgets, and provenance.
- **Overlap:** Security, Capability, local intelligence, delegated work, and Context Schema.
- **Contradiction or staleness:** Header integration status is stale. The full compiler pipeline is broader than the first Scout requires.
- **Implementation implication:** P1-S02 needs one minimal deterministic manifest, not a general retrieval framework.
- **Disposition:** Retain. Prompt 2 must state minimum required compiler behavior and defer later pipeline stages.

## A14 — `docs/SECURITY-MODEL.md`

- **Intended purpose:** Define foundational threat and authority direction.
- **Apparent authority:** General security authority.
- **Actual authority:** Canonical cross-cutting security baseline. Focused security specifications can narrow it.
- **Current relevance:** High.
- **Unique information:** Effective-authority intersection, egress controls, broker limits, Context security, Child isolation, MCP position, and Repository trust roles.
- **Overlap:** Capability, Context, execution, Git, and knowledge security.
- **Contradiction or staleness:** Capability names and scope grammar remain provisional. It does not claim operating-system containment.
- **Implementation implication:** Policy mediation must not be represented as a sandbox.
- **Disposition:** Retain as canonical security baseline. Prompt 2 must define focused-spec precedence and remove duplicate rules where possible.

## A15 — `docs/PROTOCOL-CAPABILITY-MAP.md`

- **Intended purpose:** Define adapter and standards positions.
- **Apparent authority:** Protocol roadmap.
- **Actual authority:** Accepted adapter strategy. It cannot reorder the vertical roadmap.
- **Current relevance:** Medium before P1-S08.
- **Unique information:** Scheduled, evidence-gated, watch, and rejected positions for protocols and formats.
- **Overlap:** Capability Integration, Architecture, and Roadmap.
- **Contradiction or staleness:** No material current conflict after P0-W16. Entries are planning positions, not installed adapters.
- **Implementation implication:** “Scheduled” does not mean implemented or authorized in an earlier slice.
- **Disposition:** Retain as supporting strategy. Prompt 2 should test whether every listed seam is necessary to preserve now.

## A16 — `docs/GIT-CHANGE-ISOLATION.md`

- **Intended purpose:** Define Git truth, branch contracts, worktree leases, Patch Artifacts, verification binding, integration, and recovery.
- **Apparent authority:** Git runtime subject specification.
- **Actual authority:** Canonical Git-change boundary, with P1-S07 selecting the initial Patch Artifact path.
- **Current relevance:** Medium before P1-S07.
- **Unique information:** Exact-state Evidence, mutation ownership, worktree and Patch modes, conflict classes, and cleanup.
- **Overlap:** Branching governance, Command/Patch execution, Evidence, and architecture.
- **Contradiction or staleness:** Earlier direct writing-worktree direction is narrowed by P0-W16 for the first writing Child.
- **Implementation implication:** The full multi-mode Git design is not an early implementation package.
- **Disposition:** Retain as subject specification. Prompt 2 must mark P1-S07 Patch mode as controlling initial scope and later modes as deferred.

## A17 — trustworthy execution document group

Paths:

- `docs/TRUSTWORTHY-EXECUTION-PLANE.md`;
- `docs/COMMAND-AND-PATCH-EXECUTION.md`;
- `docs/EXECUTION-EVIDENCE-AND-RECEIPTS.md`;
- `docs/EXECUTION-OBSERVABILITY-AND-ATTESTATIONS.md`.

- **Intended purpose:** Define Environments, Commands, Patches, structured results, Evidence, Receipts, telemetry, and optional export.
- **Apparent authority:** Execution architecture.
- **Actual authority:** Focused execution subject specifications. P1-S04 introduces only the minimum registered Command and Verifier path.
- **Current relevance:** High for P1-S04, later for P1-S07 and P1-S08.
- **Unique information:** Command registration, process-tree handling, Patch transaction, result ingestion, completion stages, telemetry exclusions, and attestation limits.
- **Overlap:** Architecture, Security, Git, Capability, and Evidence Schemas.
- **Contradiction or staleness:** Complete future execution scope can appear required before the read-only Verifier.
- **Implementation implication:** Containers, broad Environment brokerage, Patch mutation, OTLP, and attestations remain later work.
- **Disposition:** Retain as a focused specification group. Prompt 2 must add a concise authority index or merge repeated introductory material. Do not create a fifth execution architecture.

## A18 — local project intelligence document group

Paths:

- `docs/LOCAL-PROJECT-INTELLIGENCE.md`;
- `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md`.

- **Intended purpose:** Define approved-root indexing, retrieval, provenance, trust, instruction quarantine, licensing, Privacy, and disclosure.
- **Apparent authority:** Cross-project intelligence architecture.
- **Actual authority:** Canonical future local project intelligence boundary for P1-S09.
- **Current relevance:** Low for version 0.1, high as a protected deferred boundary.
- **Unique information:** Read-only root policy, deterministic retrieval, candidate provenance, secret and license handling, and prompt-injection defenses.
- **Overlap:** Active code intelligence, Security, Context, Capability, and protocol map.
- **Contradiction or staleness:** Detailed future design can be mistaken for present capability. It must share extraction primitives with P1-S06 without sharing authority.
- **Implementation implication:** No indexer, watcher, Tree-sitter integration, or knowledge query exists in production source.
- **Disposition:** Retain as deferred subject authority. Prompt 2 must verify that no P1-S09 requirement leaks into version 0.1.

## A19 — `docs/decisions/`

- **Intended purpose:** Preserve accepted architecture decisions and rationale.
- **Apparent authority:** Decision authority.
- **Actual authority:** Accepted ADRs constrain implementation. The index records current status.
- **Current relevance:** Highest.
- **Unique information:** Decision drivers, rejected options, consequences, and review triggers.
- **Overlap:** Every ADR repeats selected subject decisions.
- **Contradiction or staleness:** ADR 0019 and its index entry say integration is proposed although pull request 20 integrated them. Several older ADR files also retain branch-era integration labels.
- **Implementation implication:** Stale integration labels can cause a coding agent to treat accepted decisions as optional.
- **Disposition:** Retain as canonical decision record. Correct ADR 0019 now. Prompt 2 should audit all ADR file headers against the index and remove obsolete branch-era status.

## A20 — `docs/contracts/`

- **Intended purpose:** Define provisional Kiln-native JSON shapes and protected invariants.
- **Apparent authority:** Implemented contract package.
- **Actual authority:** Planning and conformance scaffolding only. The contract index explicitly states that runtime support is not implemented.
- **Current relevance:** High as design input. Low as proof of current behavior.
- **Unique information:** Machine-readable shapes for domain, execution, Evidence, Capability, Context, Git, delegation, interface, knowledge, knowledge security, and execution plane.
- **Overlap:** Schemas repeat many prose constraints and contain fields for distant slices.
- **Contradiction or staleness:** Historical pull requests report parser and meta-schema validation, but current CI does not run a Schema validator. Generic and focused Schemas require later consolidation before production validation.
- **Implementation implication:** A Schema definition does not justify a table, process, API, Tool, or implemented feature.
- **Disposition:** Retain as conformance scaffolding. Prompt 3 must classify each Schema, identify the minimum P1-S01 subset, verify cross-Schema consistency, and decide what automated validation is justified.

## A21 — `docs/PROJECT-INVARIANTS.md`

- **Intended purpose:** Provide stable protected constraints for plans and reviews.
- **Apparent authority:** Invariant register.
- **Actual authority:** Canonical constraint register, derived from accepted documents and ADRs.
- **Current relevance:** High.
- **Unique information:** Stable `KILN-INV-*` identifiers for automated and human reference.
- **Overlap:** Restates accepted decisions.
- **Contradiction or staleness:** The register can lag a superseding ADR or integrated architecture unless status is audited.
- **Implementation implication:** Plans must identify applicable invariants, but an invariant does not prove implementation.
- **Disposition:** Retain as canonical constraint index. Prompt 2 must confirm that P0-W16 decisions are fully represented and no superseded process assumption remains.

## A22 — development-quality document group

Paths:

- `docs/AGENT-FRIENDLY-CODEBASE.md`;
- `docs/ELIXIR-OTP-ENGINEERING.md`;
- `docs/ENGINEERING-QUALITY-RULES.md`;
- `docs/AGENT-ASSET-NOTES.md`.

- **Intended purpose:** Guide repository structure, Elixir practice, writing quality, evidence discipline, and development-agent use.
- **Apparent authority:** Engineering implementation authority.
- **Actual authority:** Development-process guidance. It cannot override product architecture.
- **Current relevance:** High for implementation quality.
- **Unique information:** Process-use tests, side-effect naming, evidence language, prose rules, development-agent boundaries, and local workflow.
- **Overlap:** AGENTS, Branching, templates, and invariants.
- **Conflict:** `docs/AGENT-FRIENDLY-CODEBASE.md` proposes an early source directory map that does not match the P1-S01 module map in the integrated slice plan.
- **Implementation implication:** The old source map can become accidental architecture before Prompt 3 evaluates the scaffold.
- **Disposition:** Retain. Prompt 3 must reconcile source layout and current development controls before coding begins.

## A23 — `docs/BRANCHING-AND-WORK-PLANNING.md` and templates

- **Intended purpose:** Govern branches, ticket identifiers, plans, PRs, gates, Receipts, and integration.
- **Apparent authority:** Development governance.
- **Actual authority:** Canonical current work-governance authority.
- **Current relevance:** Highest before any implementation ticket.
- **Unique information:** `P1-SXX-TXX` grammar, small-ticket rule, aggregate slice completion, and exact plan template.
- **Overlap:** AGENTS, Skills, prompts, and scripts.
- **Conflict:** Current `scripts/agent-preflight` still enforces the superseded `P1-WXX`-style grammar and old headings.
- **Implementation implication:** The accepted first branch `work/p1-s01-t01-run-event-projection` cannot pass current preflight.
- **Disposition:** Retain as canonical governance. Prompt 3 must reconcile all executable developer controls to this authority. Prompt 6 may add the justified conformance repair after planning decisions are settled.

## A24 — `AGENTS.md`

- **Intended purpose:** Provide current repository instructions to coding agents.
- **Apparent authority:** Active development instruction source.
- **Actual authority:** Canonical repository-level coding-agent instruction file, subordinate to current user instructions and accepted project authorities.
- **Current relevance:** Highest.
- **Unique information:** Required start sequence, protected principles, context limits, Elixir rules, domain rules, development-agent roles, and completion discipline.
- **Overlap:** Nearly all governance and architecture documents.
- **Contradiction or staleness:** The start sequence calls historical `docs/PLANNING-BASELINE.md` current authority. Work-package wording does not clearly distinguish P0 planning packages from P1 slice tickets.
- **Implementation implication:** Agents can begin from a superseded status map and fail to load the current roadmap.
- **Disposition:** Retain as active instruction authority. Correct the start sequence now. Prompt 3 must reconcile ticket terminology and script behavior.

## A25 — development-agent assets

Paths:

- `.agents/skills/*/SKILL.md`;
- `.pi/agents/*.md`;
- `.pi/prompts/*.md`.

- **Intended purpose:** Help external coding agents build and review Kiln.
- **Apparent authority:** Product Agent and Skill implementation.
- **Actual authority:** Repository development scaffolding only. These assets do not execute inside Kiln.
- **Current relevance:** Medium to high for development workflow.
- **Unique information:** Work orientation, Elixir review, dependency review, integrity review, Evidence closeout, and optional read-only specialist definitions.
- **Overlap:** AGENTS, development-quality docs, templates, and scripts.
- **Contradiction or staleness:** `kiln-work-package` and prompt wording assumes generic work-package flow and depends on the stale preflight implementation.
- **Implementation implication:** Asset presence does not prove runtime Agents, Skills, Scout, Verifier, or delegation.
- **Disposition:** Retain as development scaffolding. Prompt 3 must test each asset against the new slice-ticket workflow and remove or repair stale procedure text.

## A26 — development scripts

Paths:

- `scripts/agent-preflight`;
- `scripts/test-agent-preflight`;
- `scripts/validate-agent-assets`;
- `scripts/check`.

- **Intended purpose:** Enforce branch, plan, asset, prose, compile, dependency, and test expectations.
- **Apparent authority:** Validated implementation-readiness gate.
- **Actual authority:** Executable development scaffolding. Some behavior is validated, but the preflight contract is stale.
- **Current relevance:** Highest as a build blocker.
- **Unique information:** Deterministic checks and negative branch tests.
- **Overlap:** Branching authority, plan template, AGENTS, CI, and Skills.
- **Conflict:** Preflight recognizes only `work/pN-wNN-*`. It rejects every accepted P1 ticket branch. It checks obsolete heading names. Its tests cover only old branch forms.
- **Implementation implication:** Current CI can pass while the first accepted implementation ticket is impossible to start under repository rules.
- **Disposition:** Retain as implemented but currently unvalidated against the accepted ticket contract. Prompt 3 must determine exact disposition. Prompt 6 can implement the accepted repair and negative tests.

## A27 — `.github/workflows/ci.yml`, `mise.toml`, and Vale configuration

- **Intended purpose:** Pin the development environment and run repository checks.
- **Apparent authority:** Complete project validation.
- **Actual authority:** Validated bootstrap CI for prose, agent assets, formatting, compilation, cycle detection, and existing ExUnit tests.
- **Current relevance:** High.
- **Unique information:** Elixir, OTP, and Vale versions and required jobs.
- **Overlap:** `scripts/check`.
- **Contradiction or staleness:** CI validates the stale preflight test. It does not validate JSON Schemas, future slice gate scripts, architecture-status accuracy, or product behavior.
- **Implementation implication:** Green CI proves only the checks that ran. It does not prove the planned Kiln runtime.
- **Disposition:** Retain as validated bootstrap infrastructure. Prompt 3 must identify missing and obsolete conformance checks. Prompt 6 may add only checks justified by accepted planning.

## A28 — production source

Paths:

- `mix.exs`;
- `lib/kiln.ex`;
- `lib/kiln/application.ex`.

- **Intended purpose:** Dependency-free Elixir application seed.
- **Apparent authority:** Kiln 0.1 implementation.
- **Actual authority:** Current production implementation truth.
- **Current relevance:** Highest for capability claims.
- **Unique information:** Application name, development version, Elixir requirement, empty supervisor, and version function.
- **Overlap:** README and planning descriptions of the intended product.
- **Contradiction or staleness:** The source does not implement the planned product behavior.
- **Implementation implication:** No planned runtime capability can be described as current.
- **Disposition:** Retain as bootstrap implementation. Prompt 3 must determine whether names, module boundaries, and version handling fit P1-S01 before coding.

## A29 — tests

Paths:

- `test/test_helper.exs`;
- `test/kiln_test.exs`.

- **Intended purpose:** Start ExUnit and verify the development version.
- **Apparent authority:** Product test suite.
- **Actual authority:** Current test truth for one version function only.
- **Current relevance:** High for limiting capability claims.
- **Unique information:** The only current product-level behavior assertion.
- **Overlap:** Version in `mix.exs` and `Kiln.version/0`.
- **Contradiction or staleness:** No test covers application supervision, domain behavior, events, persistence, interface, security, or recovery.
- **Implementation implication:** A passing `mix test` proves only the version assertion and compilation of existing code.
- **Disposition:** Retain. Prompt 3 must classify the test as bootstrap-only and define the first behavioral test boundary without implementing it.

## A30 — historical planning records

Paths:

- `docs/PLANNING-BASELINE.md`;
- `docs/PLAN-RECONCILIATION.md`;
- `docs/work/P0-W01-*` through `docs/work/P0-W16-*`;
- merged planning pull requests.

- **Intended purpose:** Preserve planning provenance, decisions, acceptance claims, failures, and earlier unknowns.
- **Apparent authority:** Current plan because records use formal IDs and completion language.
- **Actual authority:** Historical evidence only unless a current authority links a still-active decision.
- **Current relevance:** Medium for rationale and audit. Low for implementation order.
- **Unique information:** Evolution of decisions, validation history, earlier conflicts, and scope exclusions.
- **Overlap:** Current architecture and subject specifications contain accepted results.
- **Contradiction or staleness:** Historical records often use “implemented” for documentation completion. They include superseded component-roadmap identifiers and branch-era status.
- **Implementation implication:** Retrieval can promote obsolete requirements or mistaken capability claims.
- **Disposition:** Preserve as historical evidence. Do not remove silently. Prompt 2 should add stronger historical labels or an index if retrieval still confuses current authority.

## A31 — open pull request 21

- **Intended purpose:** Record P0-W16 verification and integration facts that did not reach `main` before pull request 20 merged.
- **Apparent authority:** Completed current P0-W16 status.
- **Actual authority:** Proposed documentation correction only. It is not integrated at the audited base.
- **Current relevance:** High for status accuracy, not architecture.
- **Unique information:** Exact design-head and closeout CI runs and merge commit.
- **Overlap:** P0-W16 work record and PR 20 history.
- **Contradiction or staleness:** `main` still reports P0-W16 verification pending while current GitHub evidence shows the design and closeout heads passed.
- **Implementation implication:** Build authorization still does not follow from the closeout.
- **Disposition:** Retain as an open proposed closeout. Do not treat it as integrated. Owner decides whether to merge, close, or supersede it after this audit.

# Source-of-truth map

| Subject | Current source | Authority status | Limit or conflict |
| --- | --- | --- | --- |
| Product identity | `README.md` | Canonical summary | Detailed rationale remains in Project Provenance. |
| Primary user | `README.md`; `docs/PROJECT-PROVENANCE.md` | Accepted: one developer, local-first | No multi-user product is accepted. |
| Primary workflow | `README.md`; `docs/ARCHITECTURE.md` | Accepted | Intent through verified completion; not current runtime behavior. |
| Internal domain | `docs/INTERNAL-DOMAIN-MODEL.md`; accepted ADRs | Subject authority | Header status is stale; slice subsets control implementation timing. |
| Session and Task | `docs/INTERNAL-DOMAIN-MODEL.md`; `docs/SESSION-MODEL.md` | Subject authority | Overlap requires Prompt 2 precedence cleanup. |
| Run model | `docs/RUN-MODEL.md`; `docs/DELEGATED-WORK.md`; ADRs 0004, 0007, and 0014 | Subject authority | Obsolete process example conflicts with architecture. |
| Architecture | `docs/ARCHITECTURE.md`; accepted ADRs | Canonical | Integration header is stale at the audited base. |
| Security | `docs/SECURITY-MODEL.md`; focused Git, execution, and knowledge security specifications | Cross-cutting and focused authority | Focused documents may narrow, never broaden, the baseline. |
| Capability and Tool model | `docs/CAPABILITY-INTEGRATION.md`; `docs/SECURITY-MODEL.md` | Subject authority | Minimum P1-S02 subset remains to be reconciled. |
| Context | `docs/CONTEXT-SYSTEM.md` | Subject authority | Minimum P1-S02 subset remains to be reconciled. |
| Interface | `docs/CLI-TUI.md`; `docs/IMPLEMENTATION-SLICES.md` | Subject authority plus slice scope | ExRatatui is planned, not installed. |
| Git and Patch | `docs/GIT-CHANGE-ISOLATION.md`; `docs/COMMAND-AND-PATCH-EXECUTION.md`; P1-S07 | Subject authority | P1-S07 Patch Artifact mode controls initial writing scope. |
| Evidence and Receipts | internal domain; execution Evidence specification; Schemas | Subject authority | No product Evidence runtime exists. |
| Protocol positions | `docs/PROTOCOL-CAPABILITY-MAP.md`; ADR 0012 | Accepted strategy | Cannot reorder roadmap. No product protocol adapter exists. |
| Implementation order | `docs/ROADMAP.md` | Canonical | P1-S01 through P1-S10. |
| Slice behavior | `docs/IMPLEMENTATION-SLICES.md` | Canonical | Detailed scope remains planning until implemented. |
| Slice completion proof | `docs/SLICE-ACCEPTANCE-GATES.md` | Accepted gate plan | Gate scripts and Receipts do not exist. |
| Accepted decisions | `docs/decisions/README.md` and accepted ADRs | Canonical decision record | ADR 0019 integration status is stale. |
| Stable constraints | `docs/PROJECT-INVARIANTS.md` | Canonical invariant register | Must be checked against P0-W16. |
| Development work governance | `docs/BRANCHING-AND-WORK-PLANNING.md`; plan template | Canonical | Executable preflight conflicts with it. |
| Coding-agent instructions | `AGENTS.md` | Active repository instruction authority | Required start sequence points to historical baseline. |
| Implementation status | source, tests, configuration, CI, Git state | Highest factual authority | Current product implementation is bootstrap only. |
| Open questions | this baseline; slice deferrals; unresolved items in accepted subject documents | Planning-status authority | Prompt 4 must identify focused rounds. |
| Ticket completion criteria | accepted ticket plan using current template | Future ticket authority | No P1 ticket plan exists. |
| Slice completion criteria | slice plan, gate plan, demo, aggregate Receipt | Future slice authority | None is implemented. |
| Build authorization | Prompt 8 adjudication record | No current authority | Build authorization is not issued. |

# Decision audit

## Accepted decisions

The following decisions are accepted and integrated unless a later Prompt 2 review supersedes them through an ADR.

| Decision | Classification | Current authority |
| --- | --- | --- |
| Kiln serves one developer on local repositories first. | Accepted | README; Project Provenance |
| Elixir and OTP own initial runtime coordination. | Accepted | ADR 0001 |
| SQLite is the first durable event store. | Accepted | ADR 0002; architecture |
| The event journal is separate from transcript projections. | Accepted | ADR 0002 |
| Git and the filesystem remain Repository source truth. | Accepted | architecture and invariants |
| External protocols adapt to Kiln-native concepts. | Accepted | ADR 0006 and ADR 0012 |
| Run is the primary durable execution unit. | Accepted | ADR 0007 |
| Task desired work remains separate from Run attempts. | Accepted | domain and Run model |
| Agent, Worker, model invocation, Tool call, Command, and Run remain separate. | Accepted | domain model |
| Logical Run lineage does not define OTP supervision. | Accepted | ADR 0004 and architecture |
| A permanent process per Run is rejected. | Accepted | architecture and ADR 0019 |
| Capability availability, policy allowance, and grants remain separate. | Accepted | security and ADR 0009 |
| The full Capability catalog remains outside model Context. | Accepted | ADR 0009 |
| Context is compiled as the smallest sufficient package. | Accepted | ADR 0010 |
| Child and Verifier Context are independently compiled. | Accepted | Context and delegation specifications |
| Scout and Verifier are the first delegated role contracts. | Accepted | delegated work and ADR 0014 |
| Background work must remain visible through Run and Attention projections. | Accepted | delegated work and interface specifications |
| Initial Child authority is read-only. | Accepted | delegated work |
| The first writing Child returns a Patch Artifact. | Accepted | ADR 0019 and P1-S07 |
| The Parent or applying Run owns one exclusive writable worktree. | Accepted | ADR 0013 and ADR 0019 |
| Active and reference code intelligence share extraction primitives. | Accepted | architecture and ADR 0019 |
| Reference repositories have no instruction authority. | Accepted | ADR 0017 |
| Embeddings and a dedicated graph database are not initial requirements. | Accepted | ADR 0016 and ADR 0019 |
| MCP is optional and is not a sandbox. | Accepted | ADR 0008 and protocol map |
| ACP is the first planned external coding Client adapter. | Accepted planning direction | protocol map and P1-S08 |
| OpenTelemetry observes Kiln but does not own durable state or Evidence. | Accepted planning direction | execution observability and protocol map |
| Implementation proceeds through P1-S01 through P1-S10 vertical slices. | Accepted | ADR 0019 and roadmap |
| Version 0.1 ends after P1-S05 and does not mutate source. | Accepted | ADR 0019 and roadmap |

## Proposed decisions

| Decision | Classification | Evidence or owner |
| --- | --- | --- |
| Merge the P0-W16 verification closeout from pull request 21. | Proposed | Open draft pull request 21 |
| Exact P1-S01 module paths and file layout. | Proposed | Slice module map; no source implementation |
| ExRatatui as the first TUI dependency. | Accepted planning choice, implementation approval pending | CLI/TUI specification |
| MiniMax as the first direct provider adapter. | Accepted planning choice, implementation contract pending | roadmap and protocol map |
| Exact JSON Schema subset used as P1-S01 production validation. | Unresolved proposal | contract package and slice plan |
| Exact persistent identifiers, timestamp form, and event-envelope fields. | Unresolved proposal | Schemas and first ticket description |

## Inferred decisions

| Decision | Classification | Reason |
| --- | --- | --- |
| P1-S01 should begin only after development preflight accepts slice-ticket branches. | Inferred and necessary | Branching rules require preflight before work, but current preflight rejects the branch. |
| The first implementation must not use the old `lib/kiln/sessions/` source map without review. | Inferred | Integrated slice module map differs from earlier guidance. |
| Contract consolidation is required before a generic Schema becomes a production validator. | Inferred and stated in contract index | Generic and focused contracts overlap. |
| Schema conformance should become a deterministic repository check only after Prompt 3 establishes retained contracts. | Inferred | Current CI lacks a validator and Prompt 1 forbids adding one. |

## Superseded decisions and sequences

| Earlier position | Superseding authority | Current effect |
| --- | --- | --- |
| P1-W01 through P1-W13 component implementation order | ADR 0019 and P1-S01 through P1-S10 roadmap | Historical only |
| Infrastructure completion before product interaction | P1-S01 simulated navigable Runs | Rejected implementation order |
| One active process per Run example | Integrated architecture | Superseded runtime example |
| Separate active-code and local-project indexing stacks | Integrated architecture | One extraction and index path with separate trust policy |
| First writing Child owns a writable worktree | P1-S07 Patch Artifact mode | Deferred later option |
| Protocol “foundational” status implies early implementation | P0-W16 protocol map | Adapter seam only until a vertical workflow justifies implementation |
| Historical planning baseline is current authority | P0-W16 hierarchy and this audit | Historical evidence only |

## Rejected decisions

- Agent-manager hierarchy as Kiln's central abstraction.
- One process, table, service, or protocol object for each domain noun.
- MCP as the default core integration layer.
- Model confidence as verification Evidence.
- Reference Repository instructions as active Project authority.
- Concurrent writing Children in one checkout.
- Embeddings or a graph database as the first local intelligence implementation.
- Containers or worktrees for harmless deterministic reads.
- Broad protocols, remote execution, Phoenix, and formal attestations in version 0.1.

## Unsupported or unresolved decisions

| Issue | Current classification | Required later pass |
| --- | --- | --- |
| Exact P1-S01 domain file and module layout | Unresolved | Prompt 3 |
| Exact minimal event envelope and projection Schema | Unresolved | Prompt 2 or focused Prompt 5 round identified by Prompt 4 |
| Identifier generation library and format | Unresolved | Prompt 4 or focused round |
| Persistent Schema validator and test fixture mechanism | Unresolved | Prompt 3, then Prompt 6 if justified |
| ExRatatui dependency safety and headless behavior | Unvalidated planning choice | Prompt 3 or focused round |
| MiniMax authentication, transport, streaming, and disclosure contract | Unresolved implementation boundary | Prompt 4 or focused round |
| Process-tree cancellation support on each target operating system | Unresolved | Focused planning round before P1-S04 |
| Exact SQLite library, migrations, transaction model, and event serialization | Unresolved | Focused planning round before P1-S05 |
| Exact OpenTelemetry dependency and exporter | Deferred | P1-S05 or later evidence-gated work |
| Build authorization | Not issued | Prompt 8 |

# Conflict report

## C01 — current preflight rejects the accepted ticket grammar

- **Observed source A:** `docs/BRANCHING-AND-WORK-PLANNING.md` defines `work/p1-s01-t01-run-event-projection`.
- **Observed source B:** `scripts/agent-preflight` accepts only `work/pN-wNN-*` as a `work/` branch.
- **Risk:** The first authorized implementation branch fails the required start command.
- **Disposition:** Build blocker. Prompt 3 determines exact script disposition. Prompt 6 implements the accepted conformance change.

## C02 — preflight heading checks do not match the current plan template

- **Observed source A:** The current template uses `Observed current state`, `Expected files or components`, `Deterministic verification`, and `Required completion Evidence`.
- **Observed source B:** Preflight requires earlier heading names.
- **Risk:** A plan that follows current authority can fail the executable gate.
- **Disposition:** Build blocker. Resolve with C01.

## C03 — `AGENTS.md` points to a historical baseline as current authority

- **Observed source A:** `AGENTS.md` requires `docs/PLANNING-BASELINE.md` for current authority.
- **Observed source B:** That file states that P0-W16 superseded it as current authority.
- **Risk:** A coding agent can orient from stale conflicts and sequence.
- **Disposition:** Correct the reference in this pass.

## C04 — integrated documents retain proposed or in-progress status

Affected current authorities include:

- `docs/ARCHITECTURE.md`;
- `docs/ROADMAP.md`;
- `docs/IMPLEMENTATION-SLICES.md`;
- `docs/SLICE-ACCEPTANCE-GATES.md`;
- ADR 0019 and the ADR index;
- the P0-W16 work record on `main`.

- **Risk:** Accepted constraints appear optional. Planning can restart or diverge.
- **Disposition:** Correct current integrated authority headers in this pass. Leave the P0-W16 work-record closeout to owner disposition of pull request 21 or a later consolidated status correction.

## C05 — Run Model process example conflicts with the integrated architecture

- **Observed source A:** Run Model shows `Kiln.RunSupervisor` with one active process for each active Run role.
- **Observed source B:** Integrated architecture rejects one permanent process per Run and uses transient Worker leases and execution workers.
- **Risk:** Process proliferation and false Run-process identity.
- **Disposition:** Mark the example superseded in this pass. Prompt 2 reconciles remaining process wording.

## C06 — source-layout guidance conflicts with slice module guidance

- **Observed source A:** Agent-Friendly Codebase proposes broad plural top-level directories such as `sessions/`, `workspaces/`, and `events/`.
- **Observed source B:** P1-S01 proposes `Kiln.Domain.Session`, `Kiln.Domain.Task`, `Kiln.Domain.Run`, `Kiln.Domain.Event`, and projection modules.
- **Risk:** A coding agent must choose architecture from non-authoritative examples.
- **Disposition:** Prompt 3 must reconcile source scaffold and accepted first-ticket layout. Do not choose in Prompt 1.

## C07 — historical “implemented” language conflicts with current implementation vocabulary

- **Observed source A:** Older planning work records call documentation and Schemas “implemented.”
- **Observed source B:** Current status vocabulary defines implemented as production source or configuration.
- **Risk:** Retrieval and completion reports can treat planning artifacts as product capabilities.
- **Disposition:** Preserve historical records. Add stronger status guidance and archive indexing in Prompt 2 or Prompt 3. Do not rewrite every historical PR record.

## C08 — Schema validation is claimed historically but not reproducible through current CI

- **Observed source A:** Planning PRs record JSON parse, meta-schema, positive, and negative validation.
- **Observed source B:** Current CI has no JSON Schema validation command or fixtures.
- **Risk:** Contract drift can pass CI, and historical validation can appear current.
- **Disposition:** Prompt 3 must identify retained Schemas and missing conformance. Prompt 6 may add a narrow validator after acceptance.

## C09 — P0-W16 verification evidence is split between `main` and open pull request 21

- **Observed source A:** Pull request 20 integrated the design head.
- **Observed source B:** The `main` work record says verification is pending.
- **Observed source C:** Pull request 21 records successful design and closeout CI but is not integrated.
- **Risk:** Status reports disagree with GitHub evidence.
- **Disposition:** Record the conflict. Do not merge or close pull request 21 in this pass without owner direction.

## C10 — gate commands are specified but do not exist

- **Observed source A:** Gate plan names `scripts/gates/slice-01` through later commands.
- **Observed source B:** Current Repository scripts do not implement those paths.
- **Risk:** A document path can be mistaken for executable conformance.
- **Disposition:** Classify as scaffolded work. Prompt 3 maps required and premature gate scaffolding. Implement each gate only with its slice.

# Terminology report

| Term | Current accepted meaning | Conflict or overload | Disposition |
| --- | --- | --- | --- |
| Workspace | Host-local operating and trust boundary | Early Project Provenance hierarchy skips Project beneath Workspace | Prompt 2 reconciliation |
| Project | Durable software product or body of work with repositories, instructions, and policies | Earlier documents sometimes use Repository objective as the direct Session parent | Retain domain definition; reconcile old diagrams |
| Repository | Version-controlled source tree; Git and filesystem are source truth | Sometimes used loosely for Project | Use Repository only for source tree |
| Session | Durable attempt for one accepted Project objective and work history | Early wording says one “repository objective” | Prompt 2 selects one canonical phrase |
| Task | Bounded desired outcome, decision, investigation, or verification target | Historical work packages are also called tasks informally | Use product Task only for runtime domain; use ticket for development work |
| Run | Durable independently inspectable execution or coordination attempt for one Task | “Run process” suggests process identity | Mark process example superseded |
| Root Run | The one Run with no Parent that carries Steward responsibility by default | Sometimes paired with “Root Task,” which is less settled | Prompt 2 confirms Root Task necessity |
| Child Run | A non-root Run created for delegated work that needs independent properties | “Child” can be confused with OTP child process | Always qualify logical Run lineage |
| Agent | Versioned execution definition in Kiln; also generic name for external coding agent | Development-agent assets use agent in a separate construction context | Keep explicit “development agent” versus runtime Agent |
| Worker | Transient executor lease that advances a Run | Can be confused with BEAM Task, process, or external worker | Preserve lease-based definition |
| Model invocation | One provider request and response stream | Sometimes called Agent execution | Keep distinct from Agent and Run |
| Capability | Named controlled authority | Sometimes used for product feature or available adapter | Use feature or implementation for product behavior; keep Capability for authority |
| Tool | Intent-level operation that declares required Capabilities | External MCP tools and CLI commands can be called tools | Use model-facing Tool, MCP Tool, and Command explicitly |
| Skill | Versioned procedure and knowledge package | Repository development Skills are not Kiln runtime Skills | Qualify development Skill versus runtime Skill package |
| Context | Explicit bounded package for one invocation or step | Informal “context” can mean repository background or transcript | Capitalized Context for Kiln object; use background information otherwise |
| Event | Versioned durable domain fact or accepted state change | Interface event and transient stream delta are distinct | Use domain event, interface event, or transient delta explicitly |
| Execution | Live model, Tool, Command, adapter, or Environment activity under a Run | Run itself is sometimes called execution | Keep Run as durable attempt and execution as live side effect |
| Artifact | Immutable stored content or durable external reference | Change set, Patch, logs, and reports can be specializations | Preserve Artifact as storage class, not Evidence automatically |
| Claim | Assertion that can be wrong | Completion narrative can appear as Evidence | Preserve distinction |
| Evidence | Structured observation bound to a subject and freshness rule | Tool result or passing CI is often overgeneralized | State exact behavior each Evidence item proves |
| Receipt | Sealed manifest that references state, Evidence, outcomes, and decisions | Can be mistaken for proof or approval | Preserve non-authority rule |
| Checkpoint | Compact immutable continuity record | Can be confused with transcript summary or model memory | Preserve journal and Context distinctions |
| Attention | Durable Session-level routing for questions, permissions, conflicts, and blockers | Notification can be confused with blocking Attention | Keep informational notification separate |
| Ticket | Repository development work step within a slice | Older documents use work package for implementation step | Use P1 ticket for implementation; P0 work package for planning history |
| Slice | Product-delivery planning boundary | Could become a runtime entity | Preserve planning-only status |

# Broad implementation-state map

## Validated bootstrap implementation

| Artifact or behavior | State | Evidence limit |
| --- | --- | --- |
| Mix project metadata | Validated bootstrap | Compilation and CI prove current project configuration parses and builds. |
| `Kiln.version/0` | Validated implementation | One ExUnit test proves the returned development version. |
| OTP application shell | Implemented but minimally validated | Source starts an empty supervisor. No behavior test evaluates supervision or restart. |
| Vale prose job | Validated development tooling | CI proves configured prose checks run on current documents. It does not prove technical accuracy. |
| Elixir format, compile, xref-cycle, and ExUnit jobs | Validated development tooling | CI proves current tiny source passes those checks. |
| Agent asset structure validator | Validated development tooling | It proves required files and selected metadata rules, not usefulness or runtime behavior. |
| Branch preflight for P0-WXX | Validated historical workflow | Negative tests prove old branch rules. They do not prove current P1 ticket support. |

## Implemented but unvalidated or stale scaffolding

| Artifact | Classification | Reason |
| --- | --- | --- |
| `scripts/agent-preflight` for current P1 tickets | Implemented but invalid against current authority | It rejects accepted branch grammar and template headings. |
| `kiln-work-package` development Skill | Implemented but unvalidated against P1 ticket workflow | It delegates to stale preflight and generic work-package wording. |
| Pi start, review, and close prompts | Implemented development scaffolding | Presence and metadata are validated; current slice-ticket behavior is not. |
| Specialist agent definitions | Implemented optional scaffolding | No reviewed project subagent extension is installed by the Repository. |
| JSON Schemas | Conformance scaffolding | Historical validation exists, but no current automated contract suite runs. |
| Slice gate command names | Planning scaffolding | Paths are specified, but scripts do not exist. |
| ExRatatui selection | Planning choice | No dependency or prototype exists. |

## Documentation only

The following current capabilities are documentation and contract design only:

- Session, Task, and Run domain;
- event journal and projections;
- Root Run and Project Steward;
- Scout and Verifier;
- Capability broker;
- Context compiler;
- model routing and MiniMax adapter;
- CLI and TUI;
- Command supervision;
- Repository reader and Patch engine;
- Artifact store;
- Evidence, Receipts, and Checkpoints;
- SQLite durability;
- LSP and Tree-sitter;
- persistent semantic indexing;
- runtime Agent Skills;
- ACP, MCP, OpenAPI, Dev Container, and OCI adapters;
- OpenTelemetry instrumentation;
- local project intelligence.

## Experimental scaffolding

No current source implements an experimental product prototype.

The Repository contains planning choices and external development-agent definitions. Those are not Kiln runtime experiments.

## Apparently completed implementation

No product subsystem is apparently complete in source.

Several subject specifications and Schemas are detailed enough to look complete. Their headers and contract index state that implementation does not exist.

## Validated product capability

The only validated product-level function is the development version query.

No accepted user-visible Kiln slice has passed its future aggregate gate, demo, and Receipt.

# Planning and bootstrap debt report

| Debt ID | Problem | Why it matters | Risk | Resolving pass |
| --- | --- | --- | --- | --- |
| D01 | Stale integration headers | Current decisions appear optional or branch-only | Duplicate planning and ignored constraints | Prompt 1 status corrections; Prompt 2 full audit |
| D02 | `AGENTS.md` stale authority link | Coding agents can start from historical state | Wrong plan and false conflicts | Prompt 1 |
| D03 | Preflight rejects P1 ticket grammar | Accepted work cannot follow required start process | Workarounds, skipped checks, or blocked coding | Prompt 3, then Prompt 6 |
| D04 | Preflight checks old template headings | Current plans fail executable validation | Two competing plan contracts | Prompt 3, then Prompt 6 |
| D05 | Run Model process-per-Run example | Can drive process proliferation | Runtime complexity and identity confusion | Prompt 1 note; Prompt 2 reconciliation |
| D06 | Old source directory map conflicts with first slice | Source architecture can be chosen accidentally | Early refactor and duplicate module boundaries | Prompt 3 |
| D07 | Contract package is ahead of implementation | Large Schemas can drive horizontal construction | Overbuilding and migration churn | Prompt 3 and Prompt 4 |
| D08 | No current Schema-conformance command | Contract drift can pass CI | False validation claims | Prompt 3, then Prompt 6 if justified |
| D09 | Historical “implemented” labels describe documents | Search and summaries can inflate capability status | False completion and build authorization | Prompt 2 or Prompt 3 historical indexing |
| D10 | Subject-document overlap | Same rules appear in several long files | Retrieval cost and contradictory edits | Prompt 2 |
| D11 | Broad future module lists | Proposed module names can become fixed architecture | Premature package structure | Prompt 2 and Prompt 3 |
| D12 | Open P0-W16 closeout is not on `main` | Status differs between GitHub and work record | Unclear planning completion | Owner disposition of PR 21 |
| D13 | README says reconciliation is pending | Top-level status is inaccurate | Repeated planning or premature implementation | Prompt 1 |
| D14 | Future gate paths look executable | Readers can cite nonexistent commands | False conformance | Prompt 3 |
| D15 | No accepted P1-S01-T01 plan exists | First coding task lacks branch-level requirements and Evidence | Uncontrolled implementation | After Prompt 8 build authorization |
| D16 | CI proves old bootstrap contract | Green checks can conceal current workflow failure | Misleading readiness | Prompt 3 and Prompt 6 |
| D17 | Planning density exceeds source evidence | Many files and contracts create a completion illusion | Broad implementation from paper design | All remaining prompts |
| D18 | Final independent adversarial review has not occurred | Current plan has not faced the completion-sequence challenge | Unseen necessity, safety, or delivery defects | Prompt 7 |
| D19 | No adjudication or build authorization exists | The project cannot distinguish planning completion from owner permission to construct | Premature coding | Prompt 8 |

# Canonical, merge, and historical disposition

## Documents that should remain canonical

- `README.md` for product and milestone summary;
- `docs/ARCHITECTURE.md` for integrated architecture;
- `docs/ROADMAP.md` for implementation order;
- `docs/IMPLEMENTATION-SLICES.md` for slice detail;
- `docs/SLICE-ACCEPTANCE-GATES.md` for future aggregate proof;
- `docs/decisions/README.md` and accepted ADRs for decisions;
- `docs/PROJECT-INVARIANTS.md` for stable constraints;
- `docs/BRANCHING-AND-WORK-PLANNING.md` for development governance;
- `docs/templates/IMPLEMENTATION-PLAN.md` for ticket plans;
- `AGENTS.md` for active repository coding-agent instructions;
- this file for current planning-completion status only.

## Documents that should remain subject specifications

- internal domain;
- Session and Run;
- Project Steward and delegated work;
- CLI and TUI;
- Capability integration;
- Context;
- Security;
- Git isolation;
- execution, Evidence, and observability;
- local project intelligence and knowledge security;
- protocol and format positions.

Prompt 2 must make each document's authority and precedence explicit. A subject specification cannot reorder the roadmap.

## Documents that should be narrowed or merged later

- Product Provenance should preserve rationale but defer current hierarchy and milestone language to the README and architecture.
- Session Model, Run Model, Project Stewardship, and Delegated Work contain repeated relationship and lifecycle material. Prompt 2 should preserve unique contracts and replace duplicate introductions with links.
- Capability Integration, Context System, and Security Model repeat authority and egress rules. Prompt 2 should identify one owning source for each rule.
- The four trustworthy execution documents should keep focused concerns but use one short authority index and fewer repeated foundations.
- Agent-Friendly Codebase source-layout examples should be narrowed after Prompt 3 establishes the first actual module boundary.

## Documents that should remain historical

- `docs/PLANNING-BASELINE.md`;
- `docs/PLAN-RECONCILIATION.md`;
- P0 work-package records;
- superseded roadmap versions in Git history;
- merged PR descriptions and CI records.

Do not remove these records. Mark them clearly historical and keep current authorities ahead of them in retrieval and contributor instructions.

## Documents that may be archived after later review

Prompt 2 or Prompt 3 may archive a work record or duplicate explanation only when:

- all unique rationale is preserved in a current authority or explicit archive;
- source and movement are recorded;
- no accepted ADR relies on the removed location;
- links and development instructions are updated;
- Git history alone is not used as the only discovery path for important rationale.

# Areas requiring Prompt 2 product or architecture reconciliation

Prompt 2 must evaluate, not automatically redesign:

1. whether the current product boundary and primary workflow are necessary and coherent;
2. whether Project, Session, Task, Run, Root Task, and Root Run relationships have one unambiguous current definition;
3. whether Project Steward responsibility adds delivery value without creating a manager Agent;
4. whether the first five slices are the minimum product proof;
5. whether each later slice belongs in the product roadmap or only in an expansion register;
6. whether subject specifications repeat or contradict the integrated architecture;
7. whether the Run Model contains any remaining process-per-Run implication;
8. whether the one shared code-intelligence path has a clear active-versus-reference trust boundary;
9. whether Patch Artifact mode is the correct initial writing boundary;
10. whether protocol seams preserve replaceability without expanding early scope;
11. whether the documentation hierarchy has one owner for each requirement class;
12. whether accepted ADRs and invariants fully represent P0-W16.

Prompt 2 must update current authorities rather than create another top-level architecture.

# Areas requiring Prompt 3 implementation reconciliation

Prompt 3 must inspect and classify:

1. `mix.exs`, application shell, version function, and current tests;
2. branch preflight, its tests, and the current plan template;
3. `scripts/check`, CI, Vale, and agent-asset validation;
4. development Skills, prompts, and optional specialist-agent definitions;
5. proposed source directory and module maps;
6. JSON Schemas, cross-Schema overlap, historical validation, and missing current conformance;
7. future gate script paths and Receipt scaffolding;
8. dependency pins and the lack of runtime dependencies;
9. whether any scaffold should be retained, repaired, narrowed, moved, or removed;
10. what exact minimal scaffold is needed before P1-S01-T01 can begin;
11. which current checks prove behavior and which prove structure only;
12. whether open pull request 21 should merge, close, or be superseded.

Prompt 3 must not complete the product subsystems that it inspects.

# Build blockers

Kiln does not have build authorization.

The following blockers exist at this baseline:

- Prompt 2 product, scope, and architecture reconciliation is not complete.
- Prompt 3 implementation and scaffold disposition is not complete.
- Prompt 4 has not identified the remaining focused planning rounds.
- Required Prompt 5 rounds have not run.
- Planning-conformance scaffolding has not been justified or reconciled.
- The final independent adversarial review has not run.
- Review findings have not been adjudicated.
- The owner has not issued build authorization.
- Current preflight rejects the first accepted Phase 1 ticket branch.
- No accepted P1-S01-T01 ticket plan exists.

Do not begin broad implementation because P0-W16 names a first coding task.

# Files changed by this pass

Planned P0-W17 changes are limited to:

- this baseline;
- the P0-W17 work record;
- current authority references;
- current integration-status headers;
- one Run Model supersession note;
- top-level status correction.

No production implementation, test, dependency, workflow, Schema, Skill, prompt, or conformance script changes are permitted.

# Prompt 1 completion gate

Prompt 1 passes when the final P0-W17 head proves all of these conditions:

- current documented state is described without guessing;
- product and implementation claims are separate;
- current authority and historical evidence are separate;
- material artifact groups have a disposition;
- accepted, proposed, inferred, unresolved, superseded, rejected, and unsupported decisions are visible;
- terminology conflicts are visible;
- implementation and scaffolding states are visible;
- planning and bootstrap debt is assigned to later passes;
- build blockers are explicit;
- current references and status headers are accurate;
- Repository validation passes;
- Prompt 2 can begin without rebuilding this audit.

# Exact next action

After P0-W17 is reviewed, accepted, and integrated, run **Prompt 2 — Reconcile the product, scope, and architecture** against current `main`.

Prompt 2 must use this audit as the status map and must use the existing architecture and roadmap as the documents to challenge and update.

Do not start Prompt 3 or implementation until Prompt 2 completes its gate.