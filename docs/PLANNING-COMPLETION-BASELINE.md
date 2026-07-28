# Kiln Planning Completion Baseline

**Document type:** Planning-status audit authority  
**Status:** Verified on P0-W17; not integrated  
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

The architecture and roadmap remain authoritative for their subjects. This audit controls planning status and the sequence required before build authorization.

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

The planning repository is coherent at the top level. It is not implementation-ready.

The current production implementation is an early bootstrap:

- one dependency-free Mix project;
- one empty OTP supervisor;
- one version function;
- one version test;
- CI and development-agent checks.

The Repository also contains planning documents, accepted ADRs, provisional JSON Schemas, development Skills, prompt templates, specialist-agent definitions, and future gate descriptions.

No current source or test proves a production:

- Workspace or Project registry;
- Session, Task, or Run model;
- event journal or projection system;
- CLI or TUI;
- provider adapter or model invocation loop;
- Capability broker or permission evaluator;
- Context compiler;
- Command runner or process-tree supervisor;
- Artifact store;
- Evidence, Receipt, or Checkpoint runtime;
- Patch engine or worktree coordinator;
- Tree-sitter or LSP adapter;
- persistent semantic index;
- runtime Skill loader;
- ACP, MCP, or OpenAPI adapter;
- local project intelligence index.

The main readiness problem has moved from architecture fragmentation to planning-conformance drift:

1. current development scripts reject the first accepted Phase 1 ticket branch grammar;
2. current preflight checks require headings from an obsolete plan template;
3. current `AGENTS.md` routes readers through a historical audit before they reach current status;
4. integrated subject documents retain branch-era proposed or in-progress labels;
5. one Run supervision example conflicts with the accepted no-process-per-Run decision;
6. old source-layout guidance can become accidental architecture;
7. historical Schema validation is not reproduced by a current Repository command;
8. future gate paths are named but not implemented;
9. detailed planning and Schemas can appear more complete than production source.

Kiln must complete Prompts 2 through 8 before broad implementation begins.

## Evidence and status categories

### Observed fact

Current source, configuration, test output, CI output, Git state, or an exact integrated document establishes the statement.

### Accepted decision

A current owner instruction, accepted ADR, or integrated planning authority establishes the direction.

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

Structure exists to support later implementation, but required user-visible or runtime behavior does not exist.

### Implemented but unvalidated work

Executable source or configuration exists, but current Evidence does not prove its intended current contract.

### Validated implementation

Current deterministic Evidence proves the behavior against an identified Repository state.

### Build blocker

A defect, unresolved decision, missing gate, or authority conflict prevents safe construction or truthful completion.

No category implies a later category automatically.

# Artifact map

## A01 — product and top-level orientation

**Paths:**

- `README.md`;
- `docs/PROJECT-PROVENANCE.md`.

- **Intended purpose:** Define the product, primary user, primary workflow, non-goals, rationale, and milestone boundary.
- **Apparent authority:** Both documents can appear to define the product.
- **Actual authority:** `README.md` is the current product summary. Project Provenance preserves supporting rationale.
- **Current relevance:** High.
- **Unique information:** The README provides current product and milestone language. Project Provenance preserves early reasoning and language choice.
- **Overlap:** Product thesis, Run rationale, hierarchy, and non-goals appear in both.
- **Conflict or staleness:** Project Provenance contains an early hierarchy that omits Project and uses “run processes.” The README status still implies that P0-W16 reconciliation is pending.
- **Implementation implication:** Old explanatory language can reintroduce superseded hierarchy or process assumptions.
- **Recommended disposition:** Retain the README as canonical. Retain Project Provenance as supporting explanation. Prompt 2 must narrow stale hierarchy and process language.

## A02 — integrated architecture

**Path:** `docs/ARCHITECTURE.md`.

- **Intended purpose:** Define the integrated architecture and dependency direction.
- **Apparent authority:** Architecture authority.
- **Actual authority:** Canonical architecture authority, constrained by accepted ADRs.
- **Current relevance:** Highest.
- **Unique information:** Minimal runtime, authoritative versus rebuildable storage, Run-process separation, shared code intelligence, Patch Artifact writing, and adapter boundaries.
- **Overlap:** Summarizes most subject specifications.
- **Conflict or staleness:** The header says integration is proposed on P0-W16 although pull request 20 integrated it.
- **Implementation implication:** Implementation must preserve its no-process-per-Run, native-domain, authority, Evidence, and storage distinctions.
- **Recommended disposition:** Retain as canonical. Prompt 2 must correct status and reconcile subject documents against it.

## A03 — roadmap and slice planning

**Paths:**

- `docs/ROADMAP.md`;
- `docs/IMPLEMENTATION-SLICES.md`;
- `docs/SLICE-ACCEPTANCE-GATES.md`.

- **Intended purpose:** Define implementation order, slice detail, future gates, demos, and Receipts.
- **Apparent authority:** Current implementation plan.
- **Actual authority:** The Roadmap controls order. Implementation Slices controls detailed slice scope. Slice Acceptance Gates controls future aggregate proof.
- **Current relevance:** Highest.
- **Unique information:** P1-S01 through P1-S10, version 0.1 through P1-S05, first task, twelve-week target, ticket lists, and gate identifiers.
- **Overlap:** Each file repeats selected scope, criteria, tests, and exclusions.
- **Conflict or staleness:** All three retain proposed or in-progress P0-W16 status. Future `scripts/gates/*` paths do not exist.
- **Implementation implication:** A named gate or ticket is a requirement, not executable capability.
- **Recommended disposition:** Retain as canonical planning authorities. Prompt 2 must challenge necessity and overlap. Prompt 3 must classify missing gate scaffolding. Do not create gate scripts in Prompt 1.

## A04 — internal domain and work models

**Paths:**

- `docs/INTERNAL-DOMAIN-MODEL.md`;
- `docs/SESSION-MODEL.md`;
- `docs/RUN-MODEL.md`;
- `docs/PROJECT-STEWARDSHIP.md`;
- `docs/DELEGATED-WORK.md`.

- **Intended purpose:** Define Workspace, Project, Repository, Environment, Session, Task, Run, Agent, Worker, delegation, Steward, Attention, and recovery.
- **Apparent authority:** Several files can appear to own the same relationship.
- **Actual authority:** Internal Domain owns core distinctions. Run Model and Delegated Work own Run and delegation detail. Session Model and Project Stewardship are supporting subject specifications. Integrated Architecture controls runtime shape.
- **Current relevance:** Highest for P1-S01 through P1-S05.
- **Unique information:** Entity lifecycle, Run state, Child limits, Scout and Verifier contracts, no-silent-blocker behavior, result delivery, and recovery.
- **Overlap:** Hierarchy, Task versus Run, Root Run, Worker, Attention, and recovery repeat across the group.
- **Conflict or staleness:** Run Model shows one active process for each active Run role. Integrated Architecture rejects a permanent process per Run. Several headers retain branch-era status.
- **Implementation implication:** A coding agent can overbuild all domain fields or reproduce the obsolete RunSupervisor example.
- **Recommended disposition:** Retain subject authorities. Prompt 2 must remove duplicate introductions, state precedence, and mark the process example superseded. P1-S01 must implement only its exercised subset.

## A05 — Capability, Context, security, and protocols

**Paths:**

- `docs/CAPABILITY-INTEGRATION.md`;
- `docs/CONTEXT-SYSTEM.md`;
- `docs/SECURITY-MODEL.md`;
- `docs/PROTOCOL-CAPABILITY-MAP.md`.

- **Intended purpose:** Define Capability selection, Tool projection, Context compilation, authority, Privacy, trust, and protocol entry.
- **Apparent authority:** Each can appear to own authorization or integration.
- **Actual authority:** Security Model owns cross-cutting authority. Capability Integration owns implementation selection and broker boundaries. Context System owns model-visible package construction. Protocol Map owns adapter positions but cannot reorder the Roadmap.
- **Current relevance:** High for P1-S02 and later.
- **Unique information:** Effective-authority intersection, compact Tool surface, smallest-sufficient Context, documentation order, and evidence-gated adapters.
- **Overlap:** Permission, egress, fallback, provenance, large-result handling, and MCP constraints repeat.
- **Conflict or staleness:** The complete planned systems exceed the minimum P1-S02 Scout. Some headers remain branch-era proposed status.
- **Implementation implication:** A coding agent can build a general broker, retrieval platform, protocol catalog, or policy service before the first Scout.
- **Recommended disposition:** Retain. Prompt 2 must assign one owner to each repeated rule and define the minimum P1-S02 subset.

## A06 — terminal interface

**Path:** `docs/CLI-TUI.md`.

- **Intended purpose:** Define Run-first terminal navigation, projections, inputs, Attention, and renderer boundaries.
- **Apparent authority:** Implemented terminal design.
- **Actual authority:** Interface subject specification. P1-S01 controls the first implemented subset.
- **Current relevance:** High.
- **Unique information:** Client-local focus, Parent and sibling navigation, no implicit approval, headless tests, and ExRatatui adapter boundary.
- **Overlap:** Run Model, Delegated Work, Architecture, and interface Schema.
- **Conflict or staleness:** ExRatatui is selected in planning but is not a dependency or prototype.
- **Implementation implication:** Library selection does not authorize addition or prove platform support.
- **Recommended disposition:** Retain. Prompt 3 must classify the dependency decision, required review, and missing prototype Evidence.

## A07 — Git, Commands, Patches, Evidence, and observability

**Paths:**

- `docs/GIT-CHANGE-ISOLATION.md`;
- `docs/TRUSTWORTHY-EXECUTION-PLANE.md`;
- `docs/COMMAND-AND-PATCH-EXECUTION.md`;
- `docs/EXECUTION-EVIDENCE-AND-RECEIPTS.md`;
- `docs/EXECUTION-OBSERVABILITY-AND-ATTESTATIONS.md`.

- **Intended purpose:** Define Git truth, worktree leases, Commands, Patches, structured results, Evidence, Receipts, telemetry, and optional exports.
- **Apparent authority:** A complete execution subsystem.
- **Actual authority:** Focused subject specifications. P1-S04 introduces only the minimum registered Command and Verifier path. P1-S07 introduces the first mutation path.
- **Current relevance:** High for future slices, but not current implementation.
- **Unique information:** Exact-state binding, process-tree cleanup, Patch transactions, result authority, completion stages, telemetry exclusions, and attestation limits.
- **Overlap:** Security, Capability, Architecture, contracts, and slice detail.
- **Conflict or staleness:** Earlier writable-Child implications are narrowed by P1-S07 Patch Artifact mode. The complete future scope can appear to be an early requirement.
- **Implementation implication:** Containers, broad Environment brokerage, Patches, OTLP, and attestations can be pulled forward without user value.
- **Recommended disposition:** Retain as a focused group. Prompt 2 must reduce repeated foundations and state initial slice precedence.

## A08 — active and reference code intelligence

**Paths:**

- active code-intelligence sections in Architecture, Protocol Map, Context System, and slices;
- `docs/LOCAL-PROJECT-INTELLIGENCE.md`;
- `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md`.

- **Intended purpose:** Define active Repository semantics and later approved-root pattern retrieval.
- **Apparent authority:** Two separate intelligence products.
- **Actual authority:** One accepted extraction and index path with separate active and reference trust policies.
- **Current relevance:** Deferred beyond version 0.1.
- **Unique information:** Tree-sitter structure, LSP normalization, persistent facts, approved roots, provenance, instruction quarantine, licensing, and disclosure.
- **Overlap:** Context, Security, Capability, and protocol strategy.
- **Conflict or staleness:** Detailed P1-S09 design can appear current. Active and reference paths must share primitives without sharing authority.
- **Implementation implication:** The project can become an index or graph project before proving the Run product.
- **Recommended disposition:** Retain as deferred subject authority. Prompt 2 must ensure no P1-S09 scope leaks into version 0.1.

## A09 — ADRs and invariants

**Paths:**

- `docs/decisions/`;
- `docs/PROJECT-INVARIANTS.md`.

- **Intended purpose:** Preserve accepted decisions, rationale, review triggers, and stable constraints.
- **Apparent authority:** Accepted project constraints.
- **Actual authority:** Accepted ADRs are decision authority. The invariant register provides stable references derived from accepted decisions.
- **Current relevance:** Highest.
- **Unique information:** Decision drivers, rejected positions, consequences, and stable IDs.
- **Overlap:** ADRs and invariants restate subject requirements.
- **Conflict or staleness:** ADR 0019 and its index reported proposed integration despite pull request 20. P0-W17 corrects those two records. Older ADR file headers may still contain branch-era status.
- **Implementation implication:** Stale integration labels can cause accepted decisions to appear optional.
- **Recommended disposition:** Retain as canonical. Prompt 2 must audit all ADR headers and ensure P0-W16 decisions are represented in invariants.

## A10 — JSON contracts

**Path group:** `docs/contracts/`.

- **Intended purpose:** Define provisional machine-readable shapes and protected invalid states.
- **Apparent authority:** Implemented contract layer.
- **Actual authority:** Planning and conformance scaffolding. The contract index states that runtime support is not implemented.
- **Current relevance:** High as design input and low as current capability proof.
- **Unique information:** Schemas for domain, execution, Evidence, Capability, Context, Git, delegation, interface, knowledge, knowledge security, and execution plane.
- **Overlap:** Schemas repeat prose constraints and contain fields for distant slices.
- **Conflict or staleness:** Historical pull requests report parser and meta-schema validation. Current CI has no accepted Schema validator or fixture suite. Generic and focused Schemas overlap.
- **Implementation implication:** Schema existence can drive a table, process, API, or horizontal implementation without a current slice need.
- **Recommended disposition:** Retain as conformance scaffolding. Prompt 3 must classify every Schema and identify the minimum P1-S01 subset before Prompt 6 adds any validator.

## A11 — engineering and development guidance

**Paths:**

- `AGENTS.md`;
- `docs/AGENT-FRIENDLY-CODEBASE.md`;
- `docs/ELIXIR-OTP-ENGINEERING.md`;
- `docs/ENGINEERING-QUALITY-RULES.md`;
- `docs/AGENT-ASSET-NOTES.md`.

- **Intended purpose:** Guide coding agents and contributors.
- **Apparent authority:** Current implementation architecture and workflow.
- **Actual authority:** AGENTS is the active repository instruction source. The other files are development guidance and cannot override product architecture.
- **Current relevance:** Highest before implementation.
- **Unique information:** Start sequence, evidence discipline, process rules, source examples, and external development-agent boundaries.
- **Overlap:** Branching, templates, scripts, Skills, and invariants.
- **Conflict or staleness:** AGENTS points first to the historical baseline. The historical file now redirects to this audit, which mitigates but does not remove the extra hop. Agent-Friendly Codebase proposes a source map that differs from P1-S01 module guidance.
- **Implementation implication:** Agents can choose stale source structure or treat development agents as runtime features.
- **Recommended disposition:** Retain. Prompt 2 must correct authority references. Prompt 3 must reconcile source layout and ticket terminology.

## A12 — work governance and templates

**Paths:**

- `docs/BRANCHING-AND-WORK-PLANNING.md`;
- `docs/templates/IMPLEMENTATION-PLAN.md`;
- other PR and ADR templates.

- **Intended purpose:** Govern branches, tickets, plans, gates, demos, Receipts, reviews, and integration.
- **Apparent authority:** Current development contract.
- **Actual authority:** Canonical current work-governance authority.
- **Current relevance:** Highest.
- **Unique information:** `P1-SXX-TXX` grammar, small-ticket rule, aggregate slice completion, and current plan sections.
- **Overlap:** AGENTS, Skills, prompts, preflight, and CI.
- **Conflict or staleness:** Executable preflight still enforces the earlier work-package grammar and headings.
- **Implementation implication:** The first accepted implementation branch cannot pass the required start command.
- **Recommended disposition:** Retain as canonical. Prompt 3 must define the exact executable repair. Prompt 6 may implement it after planning acceptance.

## A13 — development-agent assets

**Paths:**

- `.agents/skills/*/SKILL.md`;
- `.pi/agents/*.md`;
- `.pi/prompts/*.md`.

- **Intended purpose:** Help external coding agents build and review Kiln.
- **Apparent authority:** Kiln runtime Agents and Skills.
- **Actual authority:** Development scaffolding only. These assets do not run inside Kiln.
- **Current relevance:** Medium to high for development workflow.
- **Unique information:** Work orientation, Elixir review, dependency review, integrity review, Evidence closeout, and optional specialist definitions.
- **Overlap:** AGENTS, engineering guidance, templates, and scripts.
- **Conflict or staleness:** Work-package procedures depend on stale preflight behavior and generic terminology.
- **Implementation implication:** Asset presence can be reported incorrectly as Scout, Verifier, runtime Skill, or multi-agent support.
- **Recommended disposition:** Retain as development scaffolding. Prompt 3 must test each asset against the accepted slice-ticket workflow.

## A14 — scripts and CI

**Paths:**

- `scripts/agent-preflight`;
- `scripts/test-agent-preflight`;
- `scripts/validate-agent-assets`;
- `scripts/check`;
- `.github/workflows/ci.yml`;
- `mise.toml`;
- Vale configuration.

- **Intended purpose:** Enforce branch, plan, asset, prose, format, compile, dependency, and test expectations.
- **Apparent authority:** Implementation-readiness gate.
- **Actual authority:** Validated bootstrap tooling. Preflight is not valid for the accepted P1 ticket contract.
- **Current relevance:** Highest as a blocker.
- **Unique information:** Deterministic checks, pinned tools, and negative old-branch tests.
- **Overlap:** Branching, templates, AGENTS, and Skills.
- **Conflict or staleness:** Preflight accepts only `work/pN-wNN-*`, checks obsolete headings, and tests only old branch forms. CI validates that stale behavior. CI does not validate JSON Schemas or future gate scripts.
- **Implementation implication:** Green CI can coexist with an impossible P1-S01-T01 start path.
- **Recommended disposition:** Retain as implemented bootstrap tooling. Prompt 3 must classify exact repairs and removals. Prompt 6 can add justified conformance changes.

## A15 — production source and tests

**Paths:**

- `mix.exs`;
- `lib/kiln.ex`;
- `lib/kiln/application.ex`;
- `test/test_helper.exs`;
- `test/kiln_test.exs`.

- **Intended purpose:** Provide a dependency-free Elixir application seed and version test.
- **Apparent authority:** Kiln 0.1 runtime.
- **Actual authority:** Current implementation truth.
- **Current relevance:** Highest for capability claims.
- **Unique information:** Application metadata, development version, empty supervisor, and version behavior.
- **Overlap:** README and plans describe intended behavior that source does not contain.
- **Conflict or staleness:** Source does not implement the planned product. The old source-directory guide is not reflected in current source.
- **Implementation implication:** No planned subsystem can be described as implemented.
- **Recommended disposition:** Retain as bootstrap. Prompt 3 must determine whether current names and layout fit the first ticket before coding.

## A16 — historical planning and open closeout

**Paths and records:**

- `docs/PLANNING-BASELINE.md`;
- `docs/PLAN-RECONCILIATION.md`;
- `docs/work/P0-W01-*` through P0-W16;
- merged planning pull requests;
- open draft pull request 21.

- **Intended purpose:** Preserve planning provenance, earlier status, rationale, validation, and closeout evidence.
- **Apparent authority:** Current plan because records use formal IDs and completion language.
- **Actual authority:** Historical evidence, except open pull request 21 is a proposed status correction.
- **Current relevance:** Medium for audit and rationale, low for implementation order.
- **Unique information:** Decision evolution, earlier failures, CI runs, and scope exclusions.
- **Overlap:** Current authorities contain accepted conclusions.
- **Conflict or staleness:** Historical records use “implemented” for documents, contain superseded component identifiers, and retain branch-era status. Pull request 21 has P0-W16 closeout Evidence not integrated into the audited base.
- **Implementation implication:** Retrieval can promote obsolete scope or false capability claims.
- **Recommended disposition:** Preserve as historical. P0-W17 converts the older baseline into a gateway to this audit. Prompt 3 must decide pull request 21 disposition.

# Source-of-truth map

| Subject | Current source | Authority status | Limit or conflict |
| --- | --- | --- | --- |
| Product identity | `README.md` | Canonical summary | Project Provenance is supporting rationale. |
| Primary user | README and Project Provenance | Accepted: one developer, local-first | No multi-user product is accepted. |
| Primary workflow | README and Architecture | Accepted planning | Intent through verified completion is not current runtime behavior. |
| Internal domain | Internal Domain Model and accepted ADRs | Subject authority | Slice subsets control implementation timing. |
| Session and Task | Internal Domain Model and Session Model | Subject authority | Prompt 2 must reduce overlap. |
| Run and delegation | Run Model, Delegated Work, ADRs 0004, 0007, and 0014 | Subject authority | Process example conflicts with Architecture. |
| Architecture | Architecture and accepted ADRs | Canonical | Header status is stale on audited `main`. |
| Security | Security Model plus focused Git, execution, and knowledge security specifications | Baseline and focused authority | Focused documents may narrow, not broaden, authority. |
| Capability and Tool model | Capability Integration and Security Model | Subject authority | Minimum Scout subset is unresolved. |
| Context | Context System | Subject authority | Minimum Scout subset is unresolved. |
| Interface | CLI-TUI and Implementation Slices | Subject authority plus slice scope | ExRatatui is planned, not installed. |
| Git and Patch | Git Change Isolation, Command and Patch Execution, P1-S07 | Subject authority | Patch Artifact mode controls first writing scope. |
| Evidence and Receipts | Internal Domain Model and execution Evidence specification | Subject authority | No runtime exists. |
| Protocol positions | Protocol Map and ADR 0012 | Accepted strategy | Cannot reorder roadmap. |
| Implementation order | Roadmap | Canonical | P1-S01 through P1-S10. |
| Slice behavior | Implementation Slices | Canonical | Planning until source and tests exist. |
| Slice proof | Slice Acceptance Gates | Future gate authority | Gate scripts and Receipts do not exist. |
| Accepted decisions | ADR index and accepted ADRs | Canonical | Older ADR headers require later status audit. |
| Stable constraints | Project Invariants | Canonical index | Prompt 2 must confirm P0-W16 coverage. |
| Development governance | Branching and current plan template | Canonical | Preflight conflicts with it. |
| Coding-agent instructions | `AGENTS.md` | Active instruction source | Historical-baseline hop remains. |
| Implementation status | source, tests, config, CI, and Git state | Highest factual authority | Bootstrap only. |
| Open questions | this audit and accepted deferrals | Planning-status authority | Prompt 4 must identify focused rounds. |
| Ticket completion | accepted current ticket plan | Future ticket authority | No P1 ticket plan exists. |
| Slice completion | slice plan, gate, demo, and aggregate Receipt | Future slice authority | No slice is implemented. |
| Build authorization | Prompt 8 adjudication | No current authority | Not issued. |

# Decision audit

## Accepted decisions

- Kiln serves one developer on local repositories first.
- Elixir and OTP own initial runtime coordination.
- SQLite is the first durable event store.
- The durable journal is separate from transcript projections.
- Git and the filesystem remain Repository source truth.
- External protocols adapt to Kiln-native concepts.
- Run is the primary durable execution unit.
- Task desired work remains separate from Run attempts.
- Agent, Worker, model invocation, Tool call, Command, and Run remain separate.
- Logical Run lineage does not define OTP supervision.
- A permanent process per Run is rejected.
- Capability availability, policy allowance, and grants remain separate.
- The complete Capability catalog remains outside model Context.
- Context is compiled as the smallest sufficient package.
- Child and Verifier Context are independently compiled.
- Scout and Verifier are the first delegated role contracts.
- Background work remains visible through Run and Attention projections.
- Initial Child authority is read-only.
- The first writing Child returns a Patch Artifact.
- The Parent or applying Run owns one exclusive writable worktree.
- Active and reference code intelligence share extraction primitives under different trust policy.
- Reference repositories have no instruction authority.
- Embeddings and a dedicated graph database are not initial requirements.
- MCP is optional and is not a sandbox.
- OpenTelemetry observes Kiln and does not own state or Evidence.
- Implementation proceeds through P1-S01 through P1-S10.
- Version 0.1 ends after P1-S05 and does not mutate source.

## Proposed or unresolved decisions

| Issue | Classification | Required later pass |
| --- | --- | --- |
| Merge, close, or supersede pull request 21 | Proposed status correction | Prompt 3 or owner decision |
| Exact P1-S01 file and module layout | Unresolved | Prompt 3 |
| Exact minimal event envelope and projection Schema | Unresolved | Prompt 2 or a focused round identified by Prompt 4 |
| Identifier format and library | Unresolved | Prompt 4 or focused round |
| Schema validator and fixture mechanism | Unresolved | Prompt 3, then Prompt 6 if justified |
| ExRatatui dependency safety and headless behavior | Unvalidated planning choice | Prompt 3 or focused round |
| MiniMax authentication, streaming, and disclosure contract | Unresolved implementation boundary | Prompt 4 or focused round |
| Process-tree cancellation by target operating system | Unresolved | Focused round before P1-S04 |
| SQLite library, migrations, transactions, and event serialization | Unresolved | Focused round before P1-S05 |
| Build authorization | Not issued | Prompt 8 |

## Superseded decisions and sequences

| Earlier position | Superseding authority | Current effect |
| --- | --- | --- |
| P1-W01 through P1-W13 component order | ADR 0019 and vertical Roadmap | Historical only |
| Infrastructure completion before product interaction | P1-S01 navigable simulated Runs | Rejected order |
| One active process per Run example | Integrated Architecture | Superseded runtime example, still present in Run Model |
| Separate active-code and reference-index stacks | Integrated Architecture | One extraction path with separate trust policy |
| First writing Child owns a worktree | P1-S07 Patch Artifact mode | Deferred option |
| Foundational protocol means early implementation | P0-W16 Protocol Map | Adapter seam until workflow evidence exists |
| Historical baseline is current authority | P0-W16 hierarchy and this audit | Historical evidence only |

## Rejected positions

- Agent-manager hierarchy as the core abstraction.
- One process, table, service, or protocol object for each domain noun.
- MCP as the default core integration layer.
- Model confidence as verification Evidence.
- Reference instructions as active Project authority.
- Concurrent writing Children in one checkout.
- Embeddings or a graph database as the first local intelligence implementation.
- Containers or worktrees for harmless reads.
- Broad protocols, remote execution, Phoenix, and formal attestations in version 0.1.

# Conflict report

## C01 — preflight rejects the accepted ticket grammar

- **Source A:** Branching authority defines `work/p1-s01-t01-run-event-projection`.
- **Source B:** `scripts/agent-preflight` accepts only `work/pN-wNN-*` as a work branch.
- **Risk:** The first implementation branch fails the required start command.
- **Disposition:** Build blocker. Prompt 3 determines exact disposition. Prompt 6 implements the accepted conformance repair.

## C02 — preflight headings do not match the current template

- **Source A:** The current template uses `Observed current state`, `Expected files or components`, `Deterministic verification`, and `Required completion Evidence`.
- **Source B:** Preflight requires earlier heading names.
- **Risk:** A plan that follows current authority fails executable validation.
- **Disposition:** Build blocker. Resolve with C01.

## C03 — coding instructions route through a historical baseline

- **Source A:** `AGENTS.md` requires the older Planning Baseline for current authority.
- **Source B:** That file is historical.
- **P0-W17 change:** The historical file now directs readers immediately to this audit and preserves its historical role.
- **Residual risk:** The extra authority hop remains in `AGENTS.md`.
- **Disposition:** Mitigated, not fully corrected. Prompt 2 or Prompt 3 must update the direct start sequence.

## C04 — integrated documents retain branch-era status

Affected files include Architecture, Roadmap, Implementation Slices, Slice Acceptance Gates, older subject specifications, and the P0-W16 work record.

- **P0-W17 change:** ADR 0019 and its index entry now report integration through pull request 20.
- **Residual risk:** Other stale headers remain and can make accepted constraints appear optional.
- **Disposition:** Recorded for Prompt 2. P0-W17 does not mass-edit large subject authorities without performing their required reconciliation.

## C05 — Run Model process example conflicts with Architecture

- **Source A:** Run Model shows one active process for each active Run role.
- **Source B:** Architecture rejects a permanent process per Run and uses transient Worker and execution processes.
- **Risk:** Process proliferation and false identity coupling.
- **Disposition:** Superseded by current Architecture but still present in the subject file. Prompt 2 must edit the Run Model after adjudicating all related process language.

## C06 — source-layout guidance conflicts with first-slice modules

- **Source A:** Agent-Friendly Codebase proposes plural top-level directories such as `sessions/`, `workspaces/`, and `events/`.
- **Source B:** P1-S01 names `Kiln.Domain.Session`, `Kiln.Domain.Task`, `Kiln.Domain.Run`, `Kiln.Domain.Event`, and projection modules.
- **Risk:** A coding agent must choose architecture from examples.
- **Disposition:** Prompt 3 must reconcile the scaffold and first-ticket layout.

## C07 — historical “implemented” language inflates capability status

- **Source A:** Older planning records call documents and Schemas implemented.
- **Source B:** Current implementation truth is production source, configuration, tests, and execution Evidence.
- **Risk:** Search and summaries can treat planning as runtime capability.
- **Disposition:** Preserve historical records. Add stronger historical retrieval labels in Prompt 2 or Prompt 3.

## C08 — Schema validation is historical, not current conformance

- **Source A:** Planning PRs record JSON parse, meta-schema, positive, and negative validation.
- **Source B:** Current CI has no Schema validator or fixtures.
- **Risk:** Contract drift can pass CI and old validation can appear current.
- **Disposition:** Prompt 3 identifies retained Schemas and gaps. Prompt 6 may add a narrow validator after acceptance.

## C09 — P0-W16 closeout is split between `main` and open pull request 21

- **Source A:** Pull request 20 integrated the design.
- **Source B:** The `main` work record says verification is pending.
- **Source C:** Pull request 21 records successful design and closeout CI but is not integrated at the audited base.
- **Risk:** Repository and GitHub status reports disagree.
- **Disposition:** Do not merge or close pull request 21 in Prompt 1. Prompt 3 or the owner determines disposition.

## C10 — gate commands are specified but absent

- **Source A:** The gate plan names `scripts/gates/slice-01` and later commands.
- **Source B:** Current Repository scripts do not implement those paths.
- **Risk:** A planned path can be cited as current conformance.
- **Disposition:** Classify as scaffolding. Implement each gate only with its slice.

# Terminology report

| Term | Current accepted meaning | Conflict or overload | Disposition |
| --- | --- | --- | --- |
| Workspace | Host-local operating and trust boundary | Early diagrams skip Project | Prompt 2 reconciliation |
| Project | Durable product or body of work with repositories and policy | Sometimes used as Repository | Preserve domain definition |
| Repository | Version-controlled source tree | Used loosely for Project in early text | Use only for source tree |
| Session | Durable attempt for one accepted Project objective | Early wording says repository objective | Prompt 2 selects one phrase |
| Task | Bounded desired outcome or decision | Development work is also called task | Use ticket for repository work |
| Run | Durable execution or coordination attempt for one Task | “Run process” implies process identity | Prompt 2 removes overload |
| Root Run | One Run with no Parent and default Steward responsibility | Root Task is less settled | Prompt 2 confirms necessity |
| Child Run | Non-root delegated Run with independent properties | Child can mean OTP child process | Qualify logical lineage |
| Agent | Versioned execution definition | Also generic external coding agent | Say development agent when external |
| Worker | Transient executor lease | Can be confused with BEAM Task or process | Preserve lease definition |
| Model invocation | One provider request and stream | Sometimes called Agent execution | Keep distinct |
| Capability | Controlled authority | Also used loosely for feature | Use feature for product behavior |
| Tool | Intent-level operation requiring Capabilities | MCP Tool and CLI command differ | Qualify Tool kind |
| Skill | Procedure and knowledge package | Development Skills are not runtime Skills | Qualify development versus runtime |
| Context | Bounded package for one invocation | Informal background or transcript | Capitalize Kiln Context |
| Event | Durable domain fact | Interface event and transient delta differ | Qualify event kind |
| Execution | Live side effect beneath a Run | Sometimes used as Run synonym | Keep distinct |
| Artifact | Immutable stored content or durable reference | Not automatically Evidence | Preserve storage role |
| Claim | Assertion that can be wrong | Completion prose can appear evidentiary | Preserve distinction |
| Evidence | Structured observation with state and freshness | CI or Tool result can be overgeneralized | State exact proof boundary |
| Receipt | Sealed manifest of references and outcomes | Can be mistaken for proof or approval | Preserve non-authority rule |
| Checkpoint | Compact continuity record | Can be confused with transcript summary | Preserve journal distinction |
| Attention | Durable routing for questions and blockers | Notification can be non-blocking | Keep separate |
| Ticket | Development step inside a slice | Older work package terminology remains | Use P1 ticket and P0 work package |
| Slice | Product-delivery planning boundary | Could become runtime entity | Keep planning-only |

# Broad implementation-state map

## Validated implementation and tooling

| Artifact or behavior | State | Evidence limit |
| --- | --- | --- |
| Mix project metadata | Validated bootstrap | Current configuration compiles. |
| `Kiln.version/0` | Validated implementation | One test proves the returned development version. |
| OTP application shell | Implemented but minimally validated | Source starts an empty supervisor; no behavior test covers it. |
| Vale job | Validated development tooling | Proves configured prose checks, not technical accuracy. |
| Format, compile, xref-cycle, and ExUnit jobs | Validated development tooling | Proves the current small source passes those checks. |
| Agent asset validator | Validated development tooling | Proves required files and selected metadata, not usefulness. |
| P0 branch preflight | Validated historical workflow | Does not prove P1 ticket support. |

## Implemented but unvalidated or stale scaffolding

| Artifact | Classification | Reason |
| --- | --- | --- |
| Preflight for P1 tickets | Implemented but invalid against current authority | Rejects accepted grammar and headings. |
| `kiln-work-package` Skill | Development scaffolding | Depends on stale preflight and generic wording. |
| Pi prompts | Development scaffolding | Structure is validated; slice-ticket behavior is not. |
| Specialist agents | Optional development scaffolding | Repository installs no reviewed subagent extension. |
| JSON Schemas | Conformance scaffolding | No current automated contract suite runs. |
| Slice gate names | Planning scaffolding | Paths are absent. |
| ExRatatui choice | Planning choice | No dependency or prototype exists. |

## Documentation-only product systems

The following are planned, not implemented:

- domain entities and events;
- Run graph and Steward runtime;
- Scout and Verifier;
- Capability broker and grants;
- Context compiler;
- provider integration and routing;
- CLI and TUI;
- Command supervision;
- Git observation and Patch application;
- Artifact store;
- Evidence, Receipts, and Checkpoints;
- SQLite durability and recovery;
- code intelligence;
- runtime Skills;
- external adapters;
- OpenTelemetry;
- local project intelligence.

## Validated product slice

None.

No P1 slice has an implementation, aggregate gate, demo, or Receipt.

# Planning and bootstrap debt report

| Debt | Why it matters | Risk | Resolving pass |
| --- | --- | --- | --- |
| Stale integration headers | Accepted work appears optional | Duplicate planning | Prompt 2 |
| Historical authority hop in AGENTS | Agents can orient indirectly | Wrong status retrieval | Prompt 2 or 3 |
| Preflight grammar mismatch | First ticket cannot start | Skipped or bypassed checks | Prompt 3, then 6 |
| Preflight heading mismatch | Current plan fails old validator | Competing plan contracts | Prompt 3, then 6 |
| Process-per-Run example | Conflicts with runtime architecture | Process proliferation | Prompt 2 |
| Source-layout conflict | Examples can become accidental design | Early refactor | Prompt 3 |
| Contract package ahead of source | Schemas drive horizontal construction | Overbuilding and churn | Prompt 3 and 4 |
| No current Schema conformance | Contract drift can pass CI | False validation | Prompt 3, then 6 |
| Historical “implemented” labels | Planning can appear as product | False completion | Prompt 2 or 3 |
| Subject-document overlap | Raises retrieval and maintenance cost | Contradictory edits | Prompt 2 |
| Future gate paths absent | Planned commands look executable | False conformance | Prompt 3 |
| No P1-S01-T01 plan | First coding task lacks ticket authority | Uncontrolled implementation | After Prompt 8 |
| CI proves old bootstrap contract | Green CI hides workflow incompatibility | Misleading readiness | Prompt 3 and 6 |
| Planning density exceeds source | Detailed paper design looks complete | Premature broad build | Prompts 2 through 8 |
| No final adversarial review | Plan has not passed independent challenge | Hidden necessity or safety defects | Prompt 7 |
| No adjudication or authorization | Planning cannot become construction | Premature coding | Prompt 8 |

# Disposition summary

## Retain as canonical

- README for product summary;
- Architecture for system boundaries;
- Roadmap for order;
- Implementation Slices for detailed slice scope;
- Slice Acceptance Gates for future aggregate proof;
- accepted ADRs and ADR index;
- Project Invariants;
- Branching and Work Planning;
- current implementation-plan template;
- AGENTS as repository instructions;
- this audit as planning-status authority after integration.

## Retain as subject specifications

- internal domain;
- Session, Run, Steward, and delegation;
- terminal interface;
- Capability, Context, and Security;
- Git and execution;
- Evidence and observability;
- active and reference intelligence;
- protocol positions.

Prompt 2 must make each subject's authority and precedence explicit. A subject specification cannot reorder the Roadmap.

## Narrow or merge later

- Project Provenance should preserve rationale and defer current hierarchy to README and Architecture.
- Session, Run, Stewardship, and Delegated Work should preserve unique contracts and remove repeated introductions.
- Capability, Context, and Security should identify one owner for each repeated authority and egress rule.
- The execution document group should retain focused concerns with less repeated foundation text.
- Agent-Friendly Codebase source examples should be narrowed after Prompt 3 establishes the first actual module boundary.

## Preserve as historical

- earlier Planning Baseline;
- Plan Reconciliation;
- P0 work records;
- superseded Roadmap versions in Git history;
- merged PR descriptions and CI records.

Do not remove these records silently. Keep current authorities ahead of them in retrieval and contributor instructions.

## Archive only after later review

Archive or remove material only when:

- unique rationale is preserved;
- the source and destination are recorded;
- accepted ADR links remain valid;
- current instructions and references are updated;
- Git history is not the only discovery path for important rationale.

# Prompt 2 inputs

Prompt 2 must challenge and reconcile:

1. product boundary and primary workflow necessity;
2. Project, Session, Task, Run, Root Task, and Root Run definitions;
3. Project Steward value without manager-Agent behavior;
4. whether P1-S01 through P1-S05 are the minimum product proof;
5. whether later slices belong in the roadmap or only an expansion register;
6. overlap and contradiction among subject specifications;
7. all remaining process-per-Run implications;
8. active versus reference code-intelligence trust separation;
9. initial Patch Artifact writing boundary;
10. protocol seams and early scope;
11. one owner for each requirement class;
12. ADR and invariant coverage of P0-W16;
13. stale status headers and direct authority references.

Prompt 2 must update current authorities. It must not create another top-level architecture.

# Prompt 3 inputs

Prompt 3 must inspect and classify:

1. Mix metadata, application shell, version function, and tests;
2. preflight, its tests, and current plan template;
3. `scripts/check`, CI, Vale, and agent validation;
4. development Skills, prompts, and specialist definitions;
5. proposed source and module maps;
6. all JSON Schemas, overlap, historical validation, and missing conformance;
7. future gate paths and Receipt scaffolding;
8. dependency pins and the lack of runtime dependencies;
9. retain, repair, narrow, move, replace, or remove disposition for each scaffold;
10. exact minimum scaffold required before P1-S01-T01;
11. checks that prove behavior versus checks that prove structure;
12. disposition of open pull request 21.

Prompt 3 must not complete the product subsystems it inspects.

# Build blockers

Kiln does not have build authorization.

Current blockers are:

- Prompt 2 is not complete.
- Prompt 3 is not complete.
- Prompt 4 has not identified remaining focused planning rounds.
- Required Prompt 5 rounds have not run.
- Planning-conformance scaffolding has not been justified.
- The final independent adversarial review has not run.
- Review findings have not been adjudicated.
- The owner has not issued build authorization.
- Current preflight rejects the first accepted Phase 1 ticket branch.
- No accepted P1-S01-T01 ticket plan exists.

Do not begin broad implementation because P0-W16 names a first coding task.

# Files changed by P0-W17

P0-W17 changes exactly these planning and status files:

- adds `docs/PLANNING-COMPLETION-BASELINE.md`;
- adds `docs/work/P0-W17-planning-completion-baseline.md`;
- revises `docs/PLANNING-BASELINE.md` as a historical gateway;
- corrects ADR 0019 integration status;
- corrects ADR 0019 status in the ADR index.

P0-W17 does not change production source, tests, dependencies, workflows, runtime configuration, JSON Schemas, development Skills, agents, prompts, or conformance scripts.

# Prompt 1 completion gate

Prompt 1 passes on the P0-W17 branch when:

- current state is described without guessing;
- product and implementation claims are separate;
- current authority and historical evidence are separate;
- material artifact groups have a disposition;
- accepted, proposed, inferred, unresolved, superseded, rejected, and unsupported decisions are visible;
- terminology conflicts are visible;
- implementation and scaffolding states are visible;
- planning and bootstrap debt is assigned to later passes;
- unresolved status and authority conflicts are explicit;
- build blockers are explicit;
- Repository validation passes;
- Prompt 2 can begin without rebuilding this audit.

Passing Prompt 1 does not issue build authorization.

# Exact next action

After P0-W17 is reviewed, accepted, and integrated, run **Prompt 2 — Reconcile the product, scope, and architecture** against current `main`.

Prompt 2 must use this audit as the status map. It must challenge and update the existing architecture and roadmap rather than create competing documents.

Do not start Prompt 3 or implementation until Prompt 2 completes its gate.