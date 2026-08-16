# Implementation Disposition Register

**Document type:** Implementation inventory and disposition authority  
**Decision status:** Proposed by P0-W19; owner acceptance required  
**Integration status:** Proposed on `work/p0-w19-implementation-scaffold-reconciliation`  
**Implementation status:** Inventory only; no product capability added  
**Baseline:** P0-W18 integrated through pull request 23  
**Build authorization:** Not issued

## 1. Executive implementation-reconciliation verdict

Kiln has a valid Elixir application bootstrap and useful Repository quality checks.

Kiln does not have an implemented product workflow.

Current production behavior is limited to:

- one Mix application;
- one empty application supervisor;
- one version function;
- one version assertion;
- Repository validation and development-agent validation.

The most misleading implementation-like asset is the green agent-preflight path. CI proves the obsolete P0 branch grammar and obsolete plan headings. That result does not prove that an accepted Phase 1 ticket can start.

The most useful existing foundation is the small Mix application plus the current formatting, compilation, cycle, prose, and ExUnit checks. These assets are easy to understand and do not constrain the product architecture.

The largest near-term risk is conformance scaffolding that looks more complete than the accepted product. Broad JSON Schemas, old gate names, old examples, and overlapping contract families can cause an implementation agent to build deferred systems or settle unresolved decisions.

Prompt 3 can pass after:

- all listed units have accepted dispositions;
- integrated Prompt 2 status labels are corrected;
- the final documentation-only diff is inspected;
- exact final-head CI passes.

Prompt 3 does not issue build authorization.

## 2. Evidence basis

The inventory uses these current Repository facts:

- `mix.exs` defines application `:kiln`, version `0.1.0-dev`, Elixir 1.20, `Kiln.Application`, no dependencies, and a small `check` alias.
- `lib/kiln.ex` exposes only `Kiln.version/0`.
- `lib/kiln/application.ex` starts one empty `one_for_one` supervisor.
- `test/kiln_test.exs` tests only the version literal.
- `test/test_helper.exs` starts ExUnit.
- `scripts/agent-preflight` enforces P0 work-package grammar and obsolete plan headings.
- `scripts/test-agent-preflight` tests that obsolete behavior.
- `scripts/check` runs preflight tests, agent-asset validation, Vale, formatting, compilation, cycle detection, and ExUnit.
- `scripts/validate-agent-assets` validates asset shape and prevents specialist agents from receiving `edit` or `write` Tools.
- `.github/workflows/ci.yml` runs the same Repository mechanics on pull requests and `main`.
- `docs/contracts/` contains eleven JSON Schemas.
- no file exists under `scripts/gates/`.
- no source module implements Session, Task, Run, journal, provider, Context, Patch, Command, Evidence, Receipt, CLI, Child Run, Attention, or recovery behavior.

Historical pull-request reports and historical Schema validation remain Evidence for their exact historical blobs only.

## 3. Status and blast-radius vocabulary

This register uses the Prompt 3 status categories without treating compilation, file presence, or Schema validity as product proof.

Blast-radius values are:

- **First-month blast radius** — the Single-Run Change Alpha will consume or modify the unit.
- **Twelve-week blast radius** — the delegated CLI will consume or modify the unit.
- **Cross-cutting conformance blast radius** — the unit can cause immediate implementation drift.
- **Outside the current blast radius** — no current workflow depends on the unit and it does not create immediate drift.
- **Unclear because of a planning dependency** — a named focused planning decision must occur first.

## 4. Detailed implementation-like asset inventory

### 4.1 Production source and tests

| Asset | Files | Actual behavior | Status |
| --- | --- | --- | --- |
| Mix application shell | `mix.exs` | Defines and starts an Elixir application with no third-party dependencies | Validated Implementation |
| Application supervisor | `lib/kiln/application.ex` | Starts an empty named supervisor | Validated Implementation |
| Public `Kiln` module | `lib/kiln.ex` | Returns one hard-coded development version | Partial Implementation |
| Version test | `test/kiln_test.exs` | Proves one literal return value | Partial Implementation |
| Test bootstrap | `test/test_helper.exs` | Starts ExUnit | Validated Implementation |
| Product runtime | No files | No accepted product workflow exists | Documentation Only |

The empty supervisor is not a product capability. Its emptiness is accurate for the current Repository state.

The `Kiln` module description creates mild implementation pressure because it calls the module a public domain boundary while the module exposes no domain operation. The statement does not prove a product API.

### 4.2 Scripts and CI

| Asset | Files | Actual behavior | Status |
| --- | --- | --- | --- |
| Preflight concept | `scripts/agent-preflight`, process docs | Prevents work from starting on protected branches and requires a plan | Conformance Scaffold |
| Current preflight implementation | `scripts/agent-preflight` | Accepts P0 work branches only and checks obsolete headings | Build Blocker |
| Preflight tests | `scripts/test-agent-preflight` | Prove obsolete P0 behavior and several useful negative cases | Superseded Implementation |
| Repository check wrapper | `scripts/check` | Runs current Repository mechanics | Validated Implementation |
| Agent-asset validator | `scripts/validate-agent-assets` | Validates asset shape, required assets, and read-only specialist Tools | Validated Implementation |
| CI workflow | `.github/workflows/ci.yml` | Runs prose and Repository mechanics | Validated Implementation |
| Product gates | `scripts/gates/*` | Paths do not exist | Documentation Only |
| Complete Schema validation | No accepted command | No recurring complete package validation exists | Build Blocker |

The missing Schema command blocks Schema promotion to active conformance authority. It does not block this planning pass.

### 4.3 Agent-facing assets

| Asset group | Files | Actual behavior | Status |
| --- | --- | --- | --- |
| Root instructions | `AGENTS.md` | States current product scope, build block, process rules, and known preflight mismatch | Documentation Only |
| Work-package Skill | `.agents/skills/kiln-work-package/SKILL.md` | Defines orientation and calls obsolete preflight | Conformance Scaffold |
| Evidence-closeout Skill | `.agents/skills/kiln-evidence-closeout/SKILL.md` | Defines evidence-based closeout and calls `scripts/check` | Conformance Scaffold |
| Integrity-review Skill | `.agents/skills/kiln-integrity-review/SKILL.md` | Defines read-only scope and invariant review | Conformance Scaffold |
| Dependency-review Skill | `.agents/skills/kiln-dependency-review/SKILL.md` | Defines current-source dependency review | Conformance Scaffold |
| Elixir and OTP Skill | `.agents/skills/kiln-elixir-otp/SKILL.md` | Defines process, lifecycle, test, and xref rules | Conformance Scaffold |
| Specialist agents | `.pi/agents/*.md` | Define read-only reviewer and verifier procedures | Conformance Scaffold |
| Work prompts | `.pi/prompts/*.md` | Route start, review, and closeout procedures | Conformance Scaffold |

These assets are development tooling. They are not runtime Skills, Scout Runs, Verifier Runs, or Kiln Agents.

### 4.4 Repository structure and contract-like documentation

| Asset | Actual effect | Status |
| --- | --- | --- |
| Current `lib/` tree | Contains no premature product namespaces | Validated Implementation |
| Earned-namespace rule | Prevents empty future directories and modules | Conformance Scaffold |
| First-month responsibility map | Suggests possible module placement | Documentation Only |
| Branching authority | Defines current slice and ticket grammar | Conformance Scaffold |
| Implementation-plan template | Defines current plan and closeout fields | Conformance Scaffold |
| Slice specifications | Define future behavior, tickets, tests, demos, and Receipts | Documentation Only |
| Slice acceptance gates | Define future aggregate proof and absent command paths | Documentation Only |
| ADR 0020 | Defines the accepted single-Run-first direction after integration | Documentation Only |

No listed module path, ticket, gate, demo, Receipt, or command is implemented because a document names it.

## 5. JSON Schema package inventory

### 5.1 Package-level verdict

The Schema package is a **Conformance Scaffold**.

It preserves useful terms and safety rules, but it is not one accepted runtime contract package. It contains overlapping generic and focused definitions, unresolved implementation choices, and deferred capability detail.

Prompt 6 must not validate every current Schema and thereby promote every current field. Prompt 6 must first apply the accepted Prompt 3 dispositions.

### 5.2 Schema dispositions

| Schema | Accepted value to preserve | Current mismatch | Status | Blast radius | Disposition |
| --- | --- | --- | --- | --- | --- |
| `kiln-core.schema.json` | Project, Repository, Session, Task, Run separation; generated IDs; no runtime handles | Run requires Agent binding and broad lifecycle; Client and policy shapes exceed first month | Conformance Scaffold | First-month blast radius | Revise as Conformance Scaffold |
| `kiln-execution.schema.json` | model invocation, explicit grant, Approval, registered Command concepts | combines Agent catalog, Skills, Terminal, Attention, and broad Capability model | Conformance Scaffold | First-month and twelve-week blast radius | Revise as Conformance Scaffold |
| `kiln-evidence.schema.json` | Artifact, Claim, Evidence freshness, Receipt limits, exact Repository state | Trace, Checkpoint, retention, and generic Receipt overlap remain unresolved | Conformance Scaffold | First-month blast radius | Revise as Conformance Scaffold |
| `kiln-capability.schema.json` | intent-level operations, bounded results, provenance, availability not permission | assumes generalized registration, selection, health, replacement, and fallback | Conformance Scaffold | Outside first month; cross-cutting terminology | Defer Until Blast Radius |
| `kiln-context.schema.json` | item authority, trust, sensitivity, state binding, provenance, digest | assumes compiler, retrieval providers, Skills, semantic adapters, documentation resolution, and observability | Conformance Scaffold | First-month blast radius | Revise as Conformance Scaffold |
| `kiln-git-change.schema.json` | Repository observation, exact Patch base, expected hashes, verification state binding | centers branch contracts, worktree leases, integration, and later writing modes | Conformance Scaffold | First-month blast radius | Revise as Conformance Scaffold |
| `kiln-delegation.schema.json` | independent Scout and Verifier results, no peer state, `PASS`/`FAIL`/`BLOCKED` | depth two, broad Run states, descendant cancellation, timeout, and Attention policy precede decisions | Conformance Scaffold | Twelve-week blast radius | Defer Until Planning Decision |
| `kiln-interface.schema.json` | structured CLI result and errors; interface is not domain truth | TUI surfaces, depth-two Run tree, broad Client state, worktree and stale-state fields | Conformance Scaffold | First-month and twelve-week blast radius | Revise as Conformance Scaffold |
| `kiln-knowledge.schema.json` | provenance-bearing, read-only investigation candidates | entire capability is outside version 0.1 | Conformance Scaffold | Outside the current blast radius | Defer Until Blast Radius |
| `kiln-knowledge-security.schema.json` | no instruction authority, no source write, no Command or network authority | reference repositories are disabled through version 0.1 | Conformance Scaffold | Outside the current blast radius | Preserve as Conformance Scaffold |
| `kiln-execution-plane.schema.json` | registered Command, cleanup, unknown effects, Patch state, structured result | combines containers, worktrees, shell, SARIF, telemetry, attestations, and overlapping Receipt shapes | Conformance Scaffold | First-month blast radius | Revise as Conformance Scaffold |

### 5.3 Package changes required later

Prompt 6 should:

1. identify one retained first-month contract subset;
2. choose one owner for overlapping Run transitions;
3. choose one owner for Command request and result;
4. choose one owner for Patch proposal and application;
5. choose one owner for Artifact, Evidence, and Receipt;
6. remove required fields that force deferred capability support;
7. add representative positive and negative fixtures;
8. add one complete recurring validation command;
9. keep deferred Schemas outside required CI until their blast-radius trigger occurs.

Prompt 6 must not create runtime code.

## 6. Implementation unit map and disposition register

| ID | Unit and files | Intended responsibility | Current status | Blast radius | Primary disposition | Preserved value | Exact future action and owner | Review trigger |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IU-01 | Mix shell: `mix.exs` | Start one Elixir application | Validated Implementation | First-month blast radius | Retain | small application, pinned language, no dependencies | Keep as base; dependency changes require focused review and an accepted ticket | first accepted dependency |
| IU-02 | Empty supervisor: `lib/kiln/application.ex` | Own top-level live process topology | Validated Implementation | First-month blast radius | Retain and Validate | valid application callback and one supervisor | validate children against focused journal, model, and Command planning before adding any child | first ticket that adds a live owner |
| IU-03 | Public module and version: `lib/kiln.ex` | Public entry point and version reporting | Partial Implementation | Outside current product blast radius | Defer Until Planning Decision | one stable name and one version value | packaging or CLI planning must decide derive, retain, move, or remove `version/0`; do not treat it as a product API | release and packaging round |
| IU-04 | Version test | Test version literal | Partial Implementation | Outside current product blast radius | Defer Until Planning Decision | confirms current literal only | replace with packaging or CLI version behavior if that behavior becomes accepted | version command or release artifact |
| IU-05 | `mix check` alias | Fast local checks | Validated Implementation | Cross-cutting conformance blast radius | Retain | small no-script fallback | keep lightweight; do not call it the complete Repository gate | addition of Schema or product gates |
| IU-06 | Core work model planning and core Schema | Session, Task, Run, Event, transition | Conformance Scaffold | Unclear because of a planning dependency | Defer Until Planning Decision | accepted identity distinctions | lifecycle round defines exact states, commands, events, and invalid transitions before code or Schema revision | Prompt 4 schedules lifecycle round |
| IU-07 | Journal and persistence planning | durable append, replay, projections, migrations | Documentation Only | Unclear because of a planning dependency | Defer Until Planning Decision | accepted need for SQLite recovery | persistence round selects library and transaction boundaries; prohibit migration or store code before acceptance | Prompt 4 schedules persistence round |
| IU-08 | Provider boundary | one provider and fake | Documentation Only | Unclear because of a planning dependency | Defer Until Planning Decision | one provider-neutral seam is justified | model-boundary round decides request, stream, cancel, disclosure, retry, and fake contract | Prompt 4 schedules provider and Context round |
| IU-09 | Context package and Tool projection | seal bounded provider input and at most four Tools | Conformance Scaffold | Unclear because of a planning dependency | Defer Until Planning Decision | provenance, trust, sensitivity, digest, fixed Tool limit | define explicit package inputs, screening, disclosure, and omission rules before implementation | provider and Context round |
| IU-10 | Patch proposal and application | separate proposal, Approval, and controlled mutation | Conformance Scaffold | Unclear because of a planning dependency | Defer Until Planning Decision | exact base binding, digest Approval, no model write | mutation round selects Patch format, path rules, staleness, rollback, dirty overlap, and unknown effects | Prompt 4 schedules mutation round |
| IU-11 | Approval boundary | bind user decision to exact proposed effect | Conformance Scaffold | Unclear because of a planning dependency | Defer Until Planning Decision | explicit authority and digest binding | mutation and authority planning defines actor, scope, revision, expiry, replay, and denial behavior | mutation and authority round |
| IU-12 | Command execution | registered non-shell verification Command | Conformance Scaffold | Unclear because of a planning dependency | Defer Until Planning Decision | fixed executable and argv; bounded output; cleanup state | execution round defines registration, process tree, timeout, cancellation, environment, and unknown-effect contract | Prompt 4 schedules Command round |
| IU-13 | Artifact storage | retain bounded large outputs and rollback data | Conformance Scaffold | Unclear because of a planning dependency | Defer Until Planning Decision | immutable content digest and metadata boundary | persistence and Evidence planning defines storage root, atomic write, retention, and recovery | persistence and Evidence rounds |
| IU-14 | Evidence and completion | criterion Evidence and completion blocking | Conformance Scaffold | Unclear because of a planning dependency | Defer Until Planning Decision | Claims are not Evidence; stale or blocked proof blocks completion | Evidence round defines currentness, completeness, contradiction, retention, and acceptance aggregation | Prompt 4 schedules Evidence round |
| IU-15 | Receipt | seal references without changing facts | Conformance Scaffold | First-month blast radius | Reduce to Conformance Scaffold | bounded immutable manifest concept | retain only fields required by S01 and S02 after Evidence and retention decisions; no service or signature claim | accepted Evidence and retention design |
| IU-16 | CLI and interface Schema | complete first-month user control | Conformance Scaffold | First-month blast radius | Revise as Conformance Scaffold | structured result, error categories, domain/interface separation | narrow to first-month commands and output; defer TUI, broad Client state, and Run-tree navigation | accepted CLI ticket plan |
| IU-17 | Child Runs and delegation Schema | Scout, Verifier, Attention, delivery, cancellation | Conformance Scaffold | Twelve-week blast radius | Defer Until Planning Decision | independent Context and grants; no-write roles; bounded results | Child round defines depth-one creation, one-active limit, permission intersection, Attention, delivery, and cancellation | P1-S04 entry after single-Run alpha |
| IU-18 | Agent preflight concept | stop work on invalid branch or plan | Conformance Scaffold | Cross-cutting conformance blast radius | Preserve as Conformance Scaffold | protected branch checks and one-plan rule | keep mechanism; revise contract in Prompt 6 | Prompt 6 conformance pass |
| IU-19 | Current preflight implementation | enforce work grammar and plan shape | Build Blocker | Cross-cutting conformance blast radius | Rebuild | protected branch and required-context checks can survive | implement accepted P0 and P1 grammar and current template headings after Prompt 4 fixes identifiers | Prompt 6 after Planning Round Register |
| IU-20 | Preflight tests | prove preflight behavior | Superseded Implementation | Cross-cutting conformance blast radius | Rebuild | retain negative tests for protected and invalid branches | add P1 ticket and current-heading fixtures; keep P0 planning coverage | preflight contract revision |
| IU-21 | `scripts/check` | complete current Repository mechanics | Validated Implementation | Cross-cutting conformance blast radius | Retain and Validate | one deterministic local entry point | after Prompt 6, prove it invokes only accepted Schema and conformance checks; product gates remain separate | conformance additions |
| IU-22 | Agent-asset validator | validate shape and no-write reviewers | Validated Implementation | Cross-cutting conformance blast radius | Retain and Validate | deterministic frontmatter and Tool restrictions | add semantic compatibility checks only when a concrete drift class justifies them | first accepted asset revision |
| IU-23 | CI | enforce current Repository checks | Validated Implementation | Cross-cutting conformance blast radius | Retain and Validate | pinned Elixir/OTP and separate prose/test jobs | replace obsolete positive preflight assertion through script tests; later add accepted conformance checks | Prompt 6 changes scripts or Schemas |
| IU-24 | Work-package Skill and start prompt | orient work | Conformance Scaffold | Cross-cutting conformance blast radius | Revise as Conformance Scaffold | plan, invariant, source, and mutation-surface orientation | point to revised preflight contract after Prompt 6 | preflight revision |
| IU-25 | Other Skills and reviewer agents | evidence, integrity, dependency, OTP, and read-only verification procedures | Conformance Scaffold | Cross-cutting conformance blast radius | Preserve as Conformance Scaffold | useful read-only procedures and evidence discipline | validate against final Prompt 4 register and Prompt 6 commands; keep outside runtime claims | first semantic asset review |
| IU-26 | Branching authority examples | guide ticket and branch identity | Conformance Scaffold | Cross-cutting conformance blast radius | Revise as Conformance Scaffold | current P1-SXX-TXX grammar | replace superseded simulated-Run example after Prompt 4 and Prompt 8 accept the first ticket | accepted first ticket |
| IU-27 | Implementation-plan template | define ticket plan and closeout | Conformance Scaffold | Cross-cutting conformance blast radius | Preserve as Conformance Scaffold | current security, Evidence, demo, and closeout sections | use as preflight authority after Prompt 6; revise only from observed use | preflight revision or first ticket use |
| IU-28 | Earned source-layout rule | prevent speculative namespaces | Conformance Scaffold | Cross-cutting conformance blast radius | Retain | direct protection against premature architecture | keep rule; exact map remains advisory until focused rounds settle boundaries | every first-month ticket |
| IU-29 | Planned slice gates | aggregate product proof | Documentation Only | First-month and twelve-week blast radius | Defer Until Blast Radius | accepted proof categories and command naming convention | create `slice-01`, `slice-02`, and later gates only in accepted implementation tickets; do not reserve empty files | corresponding slice implementation |
| IU-30 | Planned Receipts | bind aggregate state and Evidence | Documentation Only | First-month and twelve-week blast radius | Defer Until Planning Decision | manifest concept and no-authority rule | Evidence and retention planning defines minimum manifest; implementation ticket adds generator and fixtures | accepted Evidence round |
| IU-31 | Capability broker Schema | generalized implementation selection | Conformance Scaffold | Outside current blast radius | Defer Until Blast Radius | intent-level result and provenance ideas | reassess only after two accepted interchangeable implementations exist | second implementation of one capability |
| IU-32 | Knowledge and knowledge-security Schemas | reference Repository retrieval | Conformance Scaffold | Outside current blast radius | Isolate | useful adversarial and no-authority constraints | keep outside required CI and runtime dependencies; review after active code retrieval proves value | accepted local-project-intelligence slice |
| IU-33 | TUI planning remnants inside interface assets | terminal Run graph interface | Documentation Only | Outside current blast radius | Archive as Reference | prior interaction research | mark as deferred reference; do not let it define first-month CLI contracts | stable CLI plus one real Child workflow |

## 7. Existing foundations to retain

### 7.1 Mix application shell

Retain the application name, top-level Application callback, and small dependency surface.

Reason:

- the first-month target requires a real Elixir application;
- no current process topology contradicts Prompt 2;
- replacement would add no value;
- the shell compiles and starts without hiding product behavior.

### 7.2 Empty top-level supervisor

Retain the supervisor without adding children during Prompt 3.

The first accepted live child must own one approved live Resource or lifecycle. The empty list prevents speculative process structure.

### 7.3 Repository quality checks

Retain:

- Vale;
- formatting checks;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit;
- the local `scripts/check` entry point;
- read-only specialist Tool restrictions.

These checks protect Repository mechanics. They do not prove the product.

### 7.4 Evidence-oriented development assets

Retain the evidence-closeout, integrity-review, dependency-review, and OTP-review procedures.

They preserve:

- current Evidence requirements;
- explicit unknowns;
- one-objective changes;
- read-only review;
- process necessity;
- dependency due diligence.

## 8. Assets requiring validation

| Asset | Missing validation | Dependent work blocked |
| --- | --- | --- |
| Empty supervisor | startup and child-spec behavior after first live owner is selected | adding SQLite, model, or Command children |
| `Kiln.version/0` | accepted packaging or CLI version requirement | public API or release claim |
| `scripts/check` | compatibility with the final accepted conformance set | calling it the complete pre-implementation gate |
| agent-asset validator | semantic compatibility, not only shape | broad claim that all agent assets follow current workflow |
| reviewer and verifier assets | execution in one real accepted ticket | claim that they are operationally sufficient |
| Schema package | retained subset, cross-file resolution, fixtures, negative invariants | runtime or CI consumer |
| planned gates | executable scripts, deterministic fixtures, exact state, demos, Receipts | slice completion claim |

## 9. Assets to refactor, rebuild, or replace later

### Rebuild preflight implementation and tests

Preserve:

- protected branch rejection;
- approved branch classes;
- one matching plan;
- required Repository context;
- exact branch reference in the plan;
- negative tests.

Change:

- accept current P0 work packages and accepted P1 slice-ticket grammar;
- read current plan headings from the accepted template contract;
- add positive P1 fixtures;
- stop using an old planning branch as the only positive test.

Prompt 6 owns the conformance change after Prompt 4 fixes the planning register and Prompt 8 accepts construction identifiers.

### Revise the Schema package

Do not patch isolated fields until focused planning resolves ownership and lifecycle.

Prompt 6 should replace broad required top-level documents with the minimum retained first-month subset and separately deferred Schemas.

### Refactor the public version surface only when needed

A packaging or CLI version decision must determine whether `Kiln.version/0`:

- remains public;
- derives from application metadata;
- moves behind a CLI command;
- or is removed.

The current literal and test do not justify a permanent public contract.

## 10. Assets to reduce to scaffolding

### Receipt contracts

Preserve only:

- immutable manifest identity;
- exact Repository state references;
- criteria and Evidence references;
- warnings, unknowns, and exclusions;
- user acceptance reference;
- manifest digest.

Keep signature, attestation, broad delivery, Skill, multi-environment, and protocol fields absent until a later accepted need.

### Interface contracts

Preserve only the first-month CLI request, result, error, status, and exact-state fields.

Keep TUI layout, Run-tree surfaces, navigation history, multiple Clients, worktree display, and broad event catalogs out of the first-month required contract.

### Execution contracts

Preserve only:

- one provider request and result;
- one fixed authority profile;
- one exact Patch proposal and application result;
- one registered Command request and result;
- cleanup and unknown-effect state.

Keep general broker, Skill catalog, Terminal, shell, container, telemetry, and attestation contracts deferred.

## 11. Scaffolds to preserve or revise

### Preserve

- earned namespace rule;
- implementation-plan template;
- no-write specialist-agent rule;
- Evidence closeout vocabulary;
- Claims versus Evidence distinction;
- Task versus Run distinction;
- no process per domain noun;
- protocol-neutral core;
- reference Repository no-authority rules.

### Revise

- preflight grammar and headings;
- preflight tests and CI meaning;
- branching document examples;
- core, execution, Context, Git, delegation, interface, and execution-plane Schemas;
- integrated Prompt 2 status labels;
- any document that implies a gate or Receipt exists.

## 12. Assets to isolate, remove, or archive

### Isolate knowledge contracts

Keep the knowledge and knowledge-security Schemas available as deferred reference material.

Restrictions:

- do not include them in required first-month contract validation;
- do not add runtime dependencies for them;
- do not create knowledge namespaces;
- do not let reference content affect active Project authority.

### Archive TUI-first implementation detail as reference

The current CLI/TUI subject document can retain later interaction research, but first-month contracts must not consume ExRatatui, layout, Run-tree, or TUI Client shapes.

### Removal recommendations

No executable asset requires immediate removal.

Later conformance work can remove superseded Schema fields, obsolete examples, and old positive preflight fixtures after replacement Evidence exists.

## 13. Deferred assets and triggers

| Asset | Why no action now | Blast-radius trigger | Required Evidence at review |
| --- | --- | --- | --- |
| Capability broker | one fixed implementation per operation is enough | second accepted implementation for one intent | measured selection or replacement need |
| TUI | CLI must prove full control first | stable CLI plus one real Child workflow | CLI usability limits and TUI dependency review |
| managed worktrees | first month has one mutation owner | measured isolation or concurrency problem | dirty-state, cleanup, and concurrent-write Evidence |
| code intelligence | bounded search and reads are enough | measured retrieval or token failure | benchmark showing missed or costly queries |
| runtime Skills | no repeated tested runtime procedure | repeated procedure with stable contract | procedure repetition and value Evidence |
| protocols | no concrete external consumer | accepted external Client or capability | workflow, mapping, security, and replacement Evidence |
| local project intelligence | reference repositories are disabled | active Repository retrieval is stable and valuable | adversarial security and provenance Evidence |
| telemetry export | operation boundaries are not stable | stable runtime operations and diagnostic need | explicit signals and sensitive-data policy |
| remote execution | local single-developer product first | accepted remote workflow | isolation, identity, network, secret, and cleanup plan |
| attestations | no release subject or signing system | immutable build or release subject | exact attestation consumer and authenticity model |

## 14. Planning-dependent dispositions

Implementation must not settle these decisions accidentally.

| Planning domain | Affected units | Current constraining assets | Prohibited implementation before decision | Focused round appears required |
| --- | --- | --- | --- | --- |
| Run lifecycle transitions | core model, journal, CLI, Child model | core and delegation Schemas; Run and slice documents | transition modules, event validators, database states | Yes |
| SQLite library and transaction boundary | application shell, Store, projections, Artifacts | `mix.exs`, architecture, S01 plan, core/evidence Schemas | dependency, migration, connection child, tables | Yes |
| journal append and replay | Store, Event, projections, restart | S01 gates and contract index | append API, sequence rules, replay engine | Yes |
| migration ownership | application startup and Store | S01 ticket plan | migration framework and startup policy | Yes |
| orphan and restart reconciliation | workflow, Patch, Command, model invocation | execution and delegation Schemas | automatic retry or success-shaped recovery | Yes |
| Patch base binding and format | Repository Patch, Approval, Artifacts | Git and execution-plane Schemas | parser choice, fuzzy apply, write API | Yes |
| Patch rollback and dirty conflict | mutation owner and completion | S02 gates | cleanup, rollback automation, conflict policy | Yes |
| Approval binding | policy, Patch, CLI | execution Schema and Prompt 2 rules | generic approval service or model approval | Yes, with mutation round |
| Command registration | execution boundary and verification | execution and execution-plane Schemas | command catalog, arbitrary shell, generic runner | Yes |
| process-tree control | Command Worker | S02/S03 gates and OTP guidance | portability claim, timeout success, cleanup claim | Yes |
| provider disclosure and retry | provider Worker and Context | execution and Context Schemas | real provider adapter or fallback | Yes |
| Context sealing and secret screening | Context package and Repository reads | Context Schema and security rules | compiler framework, egress, secret scanner selection | Yes |
| Evidence freshness and contradiction | Evidence and completion | evidence and execution-plane Schemas | completion evaluator or `PASS` aggregation | Yes |
| Artifact and Evidence retention | Store, Artifacts, Receipt | privacy and evidence Schemas | deletion jobs, long-term retention promise | Yes |
| Receipt aggregation | completion and slice gates | evidence and execution-plane Schemas | Receipt service, signature, aggregate manifest | Yes, with Evidence round |
| CLI interaction and exit codes | CLI and interface Schema | interface Schema and S01/S02 demos | full command syntax or stable public API | Bounded implementation planning; no separate broad round unless Prompt 4 finds a conflict |
| Child permission derivation | Scout, Verifier, Attention | delegation, execution, and interface Schemas | Child creation, scheduler, grant inheritance | Yes before P1-S04 |

## 15. Safety and integrity findings

### Active safety issues

None observed.

The production application has no source mutation, provider egress, secret handling, Command execution, reference Repository access, or permission expansion behavior.

### Near-term implementation hazards

1. Broad Schemas can cause deferred capability implementation.
2. Overlapping Command, Patch, Receipt, and Run-transition contracts can create two owners for one responsibility.
3. A model could receive excess Tools or Context if the generalized schemas are treated as first-month requirements.
4. Worktree and branch contracts can displace the accepted one-checkout first-month design.
5. Depth-two delegation fields can displace the accepted depth-one limit.

### Conformance drift

1. Preflight rejects accepted P1 ticket branch grammar.
2. Preflight checks obsolete headings instead of the current template.
3. Preflight tests and CI prove obsolete positive behavior.
4. Branching examples still name the superseded simulated-Run first ticket.
5. Prompt 2 documents retain proposed or branch-only status after merge.

### Misleading status

1. Green CI can be read as product readiness even though it runs one product test for a version literal.
2. Complete-looking Schemas can be read as accepted runtime contracts.
3. Planned `scripts/gates/*` paths can be read as commands even though no path exists.
4. Detailed Receipt fields can be read as a Receipt generator even though none exists.

### Deferred concerns

TUI, worktrees, code intelligence, protocols, knowledge, telemetry, remote execution, and attestations create no current active risk when they remain unreachable and outside required conformance.

## 16. Current CI meaning

Current green CI proves:

- all checked Markdown passes current Vale rules;
- the obsolete preflight tests pass;
- required development-agent asset files and frontmatter exist;
- specialist agents do not declare `edit` or `write` Tools;
- dependency installation for the dependency-free project completes;
- Elixir source is formatted;
- the project compiles without warnings;
- no compile-connected cycle exists in the current tiny source graph;
- `Kiln.version/0` returns `0.1.0-dev`.

Current green CI does not prove:

- accepted P1 branch and plan compatibility;
- complete Schema validity or Prompt 2 compatibility;
- Session, Task, Run, Event, journal, SQLite, replay, or restart behavior;
- provider, Context, Tool, disclosure, or secret-screening behavior;
- Patch proposal, Approval, mutation, rollback, or dirty-state behavior;
- Command registration, timeout, cancellation, cleanup, or process-tree behavior;
- Artifact storage, Evidence freshness, Receipt generation, or completion logic;
- CLI workflow behavior;
- Child Run, Scout, Verifier, Attention, delivery, or cancellation behavior;
- any slice gate, demo, aggregate Receipt, release, or delivered product.

## 17. Prompt 4 implementation-grounded inputs

Prompt 4 should use the planning-dependent table in section 14.

The implementation inventory adds these constraints:

1. The first focused rounds must produce decisions that let Prompt 6 narrow existing Schemas. They must not create a second contract path.
2. Persistence planning must account for the empty supervisor and the selected SQLite library's own process model.
3. Lifecycle planning must select one transition authority before core and delegation Schemas are revised.
4. Mutation planning must select one Patch contract owner across Git, execution-plane, and Evidence assets.
5. Command planning must select one request and result owner across generic execution and execution-plane assets.
6. Evidence planning must select one Artifact, Evidence, Receipt, and completion model across generic and focused Schemas.
7. Provider and Context planning must keep the first package explicit and the Tool set at four or fewer.
8. Child planning must occur after the single-Run alpha and must resolve permission intersection, Attention, cancellation, and delivery together.
9. Packaging and version behavior can wait until release planning unless an earlier CLI requirement needs it.
10. Prompt 6 must follow the focused decisions and must repair preflight before any P1 ticket starts.

Prompt 4 owns sequencing. This register does not define the final Planning Round Register.

## 18. Owner decisions

No immediate owner decision is required to complete Prompt 3.

Repository Evidence supports the current dispositions.

Later owner acceptance is required for each focused planning decision and for the final build authorization.

## 19. Authoritative information movement

P0-W19 adds this register as the authority for:

- current implementation maturity;
- implementation-like asset status;
- blast radius;
- primary disposition;
- deferred review triggers;
- Prompt 4 implementation-grounded inputs.

Prompt 2 documents remain product, architecture, roadmap, and slice authorities.

P0-W19 will correct only stale Prompt 2 integration and status labels. It will not change accepted product behavior.

## 20. Verification plan and known limitations

Required Repository checks:

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Current CI runs the equivalent checks, including `scripts/test-agent-preflight`.

Targeted inventory inspection must also confirm:

- production modules and tests;
- all eleven Schema files;
- all four executable Repository scripts;
- CI workflow steps;
- five Skills, three specialist agents, and three required prompts;
- absence of `scripts/gates/*` files.

The GitHub connector supplies Repository file and CI Evidence for this pass. A local clone was not required for classification.

## 21. Prompt 3 gate

Prompt 3 passes only when:

- this inventory is complete;
- status corrections are committed;
- the final diff remains planning-only;
- exact final-head CI passes;
- no product capability is claimed;
- build authorization remains denied.

## 22. Exact next action

After P0-W19 is reviewed, accepted, and integrated, run **Prompt 4 — Identify and sequence remaining planning rounds** against current `main`.

Do not begin Prompt 4 in this work package.
