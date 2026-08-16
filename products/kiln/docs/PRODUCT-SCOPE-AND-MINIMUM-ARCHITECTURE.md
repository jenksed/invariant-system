# Kiln Product Scope and Minimum Architecture

**Document type:** Product-scope and minimum-architecture authority  
**Decision status:** Proposed by P0-W18; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Not implemented  
**Baseline:** P0-W17 integrated through pull request 22  
**Build authorization:** Not issued

## Authority

This document records Prompt 2 conclusions.

After owner acceptance and integration:

- `README.md` remains the concise product authority;
- `docs/ARCHITECTURE.md` remains the component, state, process, and boundary authority;
- `docs/ROADMAP.md` remains implementation-order authority;
- `docs/IMPLEMENTATION-SLICES.md` remains slice-detail authority;
- this document owns product scope, capability classification, delivery rationale, risks, and remaining planning-domain assessment.

Subject specifications can add detail. They cannot broaden the first-month or twelve-week scope without an accepted Roadmap change.

# 1. Entry revalidation

## Observed facts

- Pull request 22 merged P0-W17 into `main` at merge commit `ef487c432a04de705e58ec79569abe5bb51e3d7a`.
- `docs/PLANNING-COMPLETION-BASELINE.md` exists on `main`.
- Pull request 21 merged the P0-W16 verification closeout immediately before pull request 22.
- Product source remains a dependency-free Mix project with an empty supervisor, one version function, and one version test.
- No P1 slice is implemented, demonstrated, validated, or supported by an aggregate Receipt.
- JSON Schemas remain planning and conformance scaffolding.

## Material baseline change

Pull request 21 resolves the P0-W17 finding that P0-W16 verification Evidence was split between `main` and an open pull request.

No later source or planning change invalidates the Prompt 1 product, implementation, or conformance findings.

# 2. Evidence categories

- **Observed Fact:** Current source, configuration, tests, Git state, CI, or integrated planning Evidence directly supports the statement.
- **Accepted Decision:** An accepted ADR or integrated authority establishes the decision and this pass does not overturn it.
- **Proposed Decision:** P0-W18 recommends the decision. It becomes accepted only after owner acceptance and integration.
- **Inferred Decision:** Current accepted sources imply the decision, but no current authority states it directly.
- **Assumption:** The plan depends on the claim, but direct Evidence is insufficient.
- **Unknown:** Current Evidence does not support a defensible answer.
- **Conflict:** Active sources prescribe incompatible behavior or authority.
- **Superseded Decision:** A later accepted authority replaced the decision.
- **Build Blocker:** An implementation agent would otherwise need to invent a foundational product, safety, or architecture decision.

# 3. Executive reconciliation verdict

## What Kiln should be

**Proposed Decision:** Kiln should be a local-first coding execution ledger and control plane for one developer.

Kiln should move one accepted Repository objective through:

```text
Intent
→ bounded investigation
→ explicit change proposal
→ controlled application
→ deterministic verification
→ evidence-backed acceptance
→ durable recovery
```

Kiln should own durable work state, authority decisions, model Context boundaries, controlled side effects, Evidence, and recovery.

Kiln should use models, Git, the filesystem, existing CLIs, libraries, and later adapters without replacing them.

## What Kiln should not be

Kiln should not be:

- an autonomous software organization;
- a general multi-agent framework;
- a jobs dashboard around hidden transcripts;
- a protocol host whose product is adapter coverage;
- a replacement for Git, build tools, language servers, package managers, or mature CLIs;
- a whole-machine index;
- a generalized workflow engine;
- a universal developer-tool integration platform;
- a transcript archive described as durable project state;
- a policy-only security wrapper.

## Coherence verdict

**Observed Fact:** The P0-W16 top-level architecture is coherent.

**Conflict:** The P0-W16 delivery order proves simulated Run navigation and a TUI before it proves a complete coding workflow. Its twelve-week version 0.1 remains read-only.

## Largest scope correction

**Proposed Decision:** Version 0.1 must complete one real source change. A read-only twelve-week milestone is too weak for a coding harness.

## Largest architecture correction

**Proposed Decision:** The first useful Kiln shall use one Session, one Task, and one Root Run. Child Runs, background scheduling, Run-tree navigation, and the TUI shall not be prerequisites for first-month value.

## Prompt 2 verdict

Prompt 2 passes on this branch when canonical documents agree with this reconciliation and Repository validation passes.

Passing Prompt 2 does not issue build authorization.

# 4. Reconciled product definition

## Primary user

**Accepted Decision:** The initial user is one developer working on one local active Repository at a time.

Teams, hosted collaboration, remote Workers, and multi-user authority are outside the initial product.

## Primary problem

A developer can ask a coding model to inspect, change, and test a Repository, but the surrounding work often remains bound to a conversation and a broad tool loop.

The developer needs a reliable answer to:

- What objective and criteria control this work?
- What Repository state did the model inspect?
- What did the model propose?
- What did Kiln actually change?
- Which Commands ran against which state?
- What failed or remains unknown?
- What Evidence supports completion?
- Can work resume after interruption without repeating uncertain effects?

## Current alternatives

Current coding agents already provide many of these features:

- persistent or branching sessions;
- provider and model choice;
- terminal interfaces;
- file reads and edits;
- shell execution;
- permission modes;
- Skills and extensions;
- subagents;
- LSP integration;
- client and server surfaces.

These capabilities do not differentiate Kiln by themselves.

## Product hypotheses

- **Strong hypothesis:** A developer will value a harness that treats objective, change, execution results, Evidence, and recovery as first-class durable work rather than transcript implications.
- **Weak hypothesis:** The user will value a navigable Run graph before Kiln can complete one real source change.
- **Long-term possibility:** A bounded Run graph can improve delegated investigation and independent verification after the Root workflow proves value.

## Differentiation

Kiln is different only when it can:

1. bind one objective and criteria to exact Repository state;
2. limit model-visible Context and Tools explicitly;
3. separate model proposals from deterministic effects;
4. require user Approval for the exact proposed mutation;
5. execute a registered verification Command;
6. retain current machine-readable Evidence;
7. block completion on failed, stale, missing, contradictory, or blocked Evidence;
8. recover durable work without repeating unknown effects.

## User-visible result

The user receives:

- current objective and criteria;
- one inspectable Run status;
- exact proposed and applied change;
- Commands that ran;
- current `PASS`, `FAIL`, or `BLOCKED` verification status;
- Artifact and Evidence references;
- a bounded Receipt;
- a truthful next action after completion, failure, interruption, or restart.

## Success criteria

Kiln succeeds when one developer can complete a narrow real change with less ambiguity about authority, state, verification, and recovery than in an ordinary coding-agent session.

Agent count, Run count, pane count, protocol count, or token use do not establish success.

# 5. Explicit non-goals

## Product

Kiln shall not initially:

- coordinate an autonomous Agent organization;
- allow recursive Agent management;
- act as a general multi-agent framework;
- require Child Runs for ordinary sequential work;
- optimize for parallel activity rather than completed work;
- become a general workflow engine;
- become a hosted collaboration product;
- derive product requirements from unrelated repositories.

## Tooling

Kiln shall not replace:

- Git or the filesystem;
- build and test tools;
- package managers;
- language servers;
- parsers with mature libraries;
- mature command-line tools;
- provider SDKs when a bounded adapter is sufficient.

## Intelligence

Kiln shall not initially:

- index the entire local filesystem;
- index reference repositories automatically;
- require embeddings for basic retrieval;
- require a vector or graph database;
- start language servers for reference repositories;
- treat retrieved instructions as active authority;
- copy code without provenance and licensing review.

## Protocols

Kiln shall not initially:

- implement every emerging Agent protocol;
- use MCP for native Repository, Git, journal, Evidence, Context, Patch, Command, or policy operations;
- expose an MCP server;
- let ACP, AG-UI, AHP, A2A, SCIP, WASI, WIT, in-toto, or SLSA define the core;
- implement two adapter forms only to claim coverage.

## Safety

Kiln shall not initially:

- grant ambient shell access to a model;
- inherit the complete user environment into Commands;
- allow delegation to widen authority;
- allow concurrent writers in one checkout;
- modify reference repositories;
- auto-commit, push, merge, publish, or deploy;
- treat a process boundary or protocol as a sandbox;
- report unknown effects as canceled or complete.

# 6. Smallest useful Kiln

The smallest useful Kiln is a **single-Run, CLI-first, durable change loop** for one local Repository.

It includes:

- one Project definition for one active Repository;
- one Session for one accepted objective;
- one Task with explicit criteria;
- one Root Run;
- one provider adapter and deterministic fake provider;
- native bounded Repository search and read;
- one explicit Context package;
- at most four model-facing Tools;
- one exact Patch proposal;
- explicit user Approval for the Patch digest;
- deterministic Patch application to one selected writable checkout;
- one registered non-shell verification Command;
- minimal Artifact, Evidence, and Receipt records;
- an append-oriented SQLite journal for restart and audit;
- CLI status, inspect, approve, cancel, resume, verify, and accept actions.

## Why each part exists

| Part | User or system need | Existing capability reused | Deferred expansion |
| --- | --- | --- | --- |
| Project and Repository boundary | Prevent path and policy ambiguity | Git and filesystem | Multi-Repository Project |
| Session, Task, Root Run | Separate objective, desired work, and attempt | Plain data and SQLite | Child graph |
| One provider | Produce real model-guided work | Provider API or SDK | Router and fallback |
| Native read and search | Supply current source Context | Filesystem and deterministic search | LSP and Tree-sitter |
| Explicit Context package | Bound disclosure and token use | Plain selection functions | Retrieval framework |
| Exact Patch proposal | Separate proposal from mutation | Patch library or parser | AST transformation framework |
| Explicit Approval | Preserve user mutation authority | CLI action | General approval policy |
| Registered Command | Verify accepted criteria | Existing Project CLI | General shell and catalog |
| Artifacts and Evidence | Support completion claim | Filesystem and structured records | General Evidence platform |
| SQLite journal | Support restart, audit, replay, and unknown effects | SQLite library | Distributed event system |
| CLI | Deliver full workflow with low interface cost | Elixir CLI | TUI, ACP, web |

## Excluded from first month

- Child Runs and Run graph navigation;
- background concurrency and Attention;
- TUI;
- managed worktree provisioning;
- general Capability broker service;
- runtime Skills;
- LSP, Tree-sitter, and persistent indexes;
- protocol adapters;
- telemetry export;
- local project intelligence;
- remote execution;
- formal attestations.

# 7. Primary workflow

## Intent

- **User input:** Select one Repository, state one objective, and accept criteria.
- **Kiln:** Validate the root and Git state. Record Project observation, Session, Task, Root Run, objective, and criteria revisions.
- **Model:** No responsibility.
- **Deterministic system:** Enforce path, policy, identifier, and journal transaction rules.
- **Evidence:** Repository observation and accepted revisions.
- **Failure:** Invalid, unavailable, denied, or ambiguous Repository state blocks the Run.
- **Status:** `ready` with exact Repository and criteria summary.

## Investigation

- **User input:** Start the Root Run or ask a bounded question inside the objective.
- **Kiln:** Build one inspectable Context package and expose approved read and search operations.
- **Model:** Investigate, separate observations from inferences and unknowns, and propose a bounded change.
- **Deterministic system:** Validate paths, limits, secret screening, source digests, token limits, Tool limits, and elapsed time.
- **Tools:** `repo.search`, `repo.read`, `artifact.read`, and `change.propose`.
- **Evidence:** Exact source observations. Model conclusions remain Claims.
- **Failure:** Provider, Context, path, disclosure, or limit failure records `FAIL` or `BLOCKED`. No silent fallback occurs.
- **Status:** Current activity, source references, limits, Claims, Evidence, and blockers.

## Implementation

- **User input:** Inspect and approve or reject the exact Patch digest.
- **Kiln:** Validate the Patch against exact base hashes and allowed paths. Retain rollback data. Apply the transaction and observe the result.
- **Model:** Explain or revise a rejected proposal. It cannot approve or apply its own Patch.
- **Deterministic system:** Reject fuzzy application, path escape, symlink violations, stale base, unowned dirty overlap, partial failure, and uncertain rollback.
- **Evidence:** Proposal, Approval, changed regions, rollback reference, and resulting Repository fingerprint.
- **Failure:** Conflict or uncertain effect blocks verification and completion.
- **Status:** `proposed`, `approved`, `applied`, `conflicted`, `rolled_back`, `failed`, or `orphaned`.

## Verification

- **User input:** Start the configured verification action.
- **Kiln:** Run one registered Command against exact changed state.
- **Model:** May summarize results. It cannot change criteria or assign `PASS`.
- **Deterministic system:** Enforce executable, argv, cwd, environment, timeout, process-tree, output, and cleanup controls.
- **Evidence:** Command request, state binding, output Artifacts, exit, cleanup, structured result, and criterion result.
- **Failure:** Failed criteria produce `FAIL`; missing prerequisites produce `BLOCKED`; unknown effects produce orphan state.
- **Status:** Per-criterion `PASS`, `FAIL`, or `BLOCKED`.

## Completion

- **User input:** Accept the result or continue work.
- **Kiln:** Evaluate readiness from current criteria, Patch state, Evidence, blockers, unknown effects, and user acceptance.
- **Model:** May recommend completion. The recommendation remains a Claim.
- **Deterministic system:** Require applied accepted Patch, current passing Evidence, no unknown effects, and required acceptance.
- **Evidence:** Final state and bounded Receipt references.
- **Failure:** Missing, failed, blocked, stale, or contradictory Evidence keeps the Task open.
- **Result:** Exact change, verification, Evidence, warnings, exclusions, and next action.

## Interruption and recovery

Kiln persists every material transition before reporting it as durable.

After restart, Kiln restores Session, Task, Root Run, workflow step, proposal, application state, Command state, Evidence, and user decisions.

Kiln does not repeat a model invocation, Patch, or Command automatically when effects are uncertain.

Unknown effects produce `orphaned` state and a reconciliation action.

# 8. Reconciled Run model

## Run

A Run is one durable, independently inspectable attempt or coordination boundary for one Task.

The first-month Root Run is the primary unit of execution coordination, observation, persistence, cancellation, Evidence association, and recovery.

A Run is not a conversation, model invocation, Tool call, Command, process, branch, worktree, Agent persona, or protocol session.

## Session and Task

A Session is one accepted Project objective and complete Kiln work history.

A Task states one desired outcome and criteria.

A Run attempts or coordinates the Task. Run completion does not satisfy the Task without current Evidence and required acceptance.

## Root Task

**Proposed Decision:** Do not create a separate Root Task initially.

The Session owns one accepted objective. Its initial Task states the executable outcome. The Root Run attempts or coordinates that Task.

## Project and Workspace

The initial Project is one active Repository plus accepted instructions and policy.

Workspace remains the host-local maximum trust and path boundary. It does not require a persistent registry in the first month.

## Minimum lifecycle

```text
created
→ ready
→ running
→ waiting_for_user | waiting_for_command | verifying
→ completed | failed | canceled | orphaned
```

- `completed`, `failed`, and `canceled` are terminal for one attempt.
- `orphaned` requires explicit reconciliation.
- `waiting_for_user` records the pending decision and resume point.
- `waiting_for_command` identifies the owned execution.
- `verifying` identifies criteria and exact state.
- Evidence staleness is an Evidence property, not a first-month Run state.

## Run state

A Run owns or references:

- Session, Task, Root, and optional Parent identity;
- accepted Task and criteria revision;
- status and workflow step;
- policy and authority references;
- Context package manifests;
- model, Tool, Patch, and Command references;
- Artifacts, Claims, Evidence, and Receipt references;
- warnings, failures, unknowns, cancellation, recovery, timestamps, and accounting.

It does not own runtime handles, branch identity, complete transcript content, Tool catalogs, hidden reasoning, or client-local UI state.

## Conversation

Conversation messages are interaction records associated with a Run. They are not canonical objective, mutation, Evidence, recovery, or completion state.

## Child Runs

**Classification:** Important Next.

Version 0.1 can add one depth-one read-only Scout Child and one independent Verifier Child, with at most one active Child per Session.

```text
Maximum Child depth:          1
Maximum active Child Runs:    1
Nested delegation:            disabled
Peer communication:           disabled
Shared mutable Context:       disabled
Writing Child:                disabled
Permission expansion:         disabled
```

Create a Child only when independent Context, authority, cancellation, Evidence, result delivery, background visibility, or verification creates user value.

The Root requests a Child. A deterministic service validates purpose, role, limits, Context, authority, and output contract. A Child cannot create descendants.

The CLI can list, inspect, enter, cancel, and return to Root. Navigation changes client focus only.

A Child returns bounded data and Evidence or Artifact references. It does not copy its transcript into Root Context.

# 9. OTP process justification

## Rule

A process exists only when it owns a live Resource, concurrency, timing, cancellation, streaming, subscriptions, external communication, or fault isolation.

No process exists merely because a Project, Session, Task, Run, Capability, Context package, Artifact, Evidence record, Receipt, or Attention item exists.

## First-month processes

| Runtime owner | Live state or Resource | Why a process exists |
| --- | --- | --- |
| Application supervisor | Required process topology | Starts and restarts live owners |
| Model invocation Worker | Provider stream, request, cancellation, limits | Owns network lifecycle and isolates failure |
| Command Worker | Process tree, timeout, output, cleanup | Owns external process lifecycle and unknown effects |
| Library-owned SQLite connection or pool | Database connection and transactions | Selected library owns connection lifecycle |

## Not processes in the first month

- Run or Session supervisor;
- Workspace, Project, Task, Capability, Context, Evidence, Receipt, Artifact, or Attention server;
- general Capability broker GenServer;
- general Context compiler GenServer;
- event publisher;
- TUI renderer process.

A Session coordinator becomes justified only when background Child scheduling, timers, Attention, and delivery require live ownership.

# 10. Event journal decision

Kiln requires restart recovery, ordered audit, projection rebuild, duplicate-effect prevention, later client resume, and unknown-effect reconciliation.

These are concrete reasons for an append-oriented SQLite journal.

The journal records material accepted transitions and external-effect boundaries.

It does not record every model token, UI movement, static concept, complete Artifact, or rebuildable index fact.

Kiln does not adopt a distributed log, message broker, CQRS framework, or general event platform.

# 11. Capability classification

## Product and execution capabilities

| Capability | User problem and value | Cost or safety effect | Classification | Reconsideration trigger |
| --- | --- | --- | --- | --- |
| Session, Task, Root Run lifecycle | Durable objective and attempt state | Small domain and journal | Essential Now | Expand only for a real workflow |
| Child Runs | Independent delegated boundary | Scheduling, Context, authority, navigation | Important Next | Single-Run alpha works |
| Run graph navigation | Visible delegated work | Projection and interface cost | Important Next | A real Child exists |
| Nested Runs | Delegated delegation | High orchestration risk | Rejected for Now | Depth one blocks measured work |
| Background concurrency | Root continues during Child work | Scheduler and race cost | Important Next | One Child is useful |
| Attention | Prevent silent blockers | Durable routing and idempotency | Important Next | Child can block |
| Command execution | Deterministic verification | Process-control risk | Essential Now | Add registrations for accepted workflows |
| General shell | Flexible execution | Broad authority and unknown effects | Rejected for Now | Registered CLI cannot meet a specific need |
| Fixed authority evaluator | Prevent availability from becoming permission | Small pure intersection | Essential Now | None |
| General Capability broker | Select interchangeable implementations | Catalog, health, fallback complexity | Deferred | Two real alternatives exist |
| Permission profiles | Bound read, write, model, and Command scope | Approval design | Essential Now | Add role profiles with Children |
| Workspace and Repository isolation | Bound paths and source | Path and policy work | Essential Now | Expand after one Project |
| Managed worktrees | Isolate independent mutation | Git lifecycle and cleanup | Important Next | One checkout creates measured risk |
| One provider adapter | Produce model-guided work | Network and Privacy boundary | Essential Now | Add a second provider for measured need |
| Model router | Select providers | Fallback and policy complexity | Deferred | Two accepted providers exist |
| Explicit Context package | Bound model input | Moderate selection work | Essential Now | Expand retrieval after measured misses |
| General Context compiler | Retrieve many sources | Opacity and token risk | Rejected for Now | Explicit selection fails a benchmark |
| Tool-schema selection | Keep catalog out of Context | Low with fixed allowlist | Essential Now | More than four Tools has measured value |
| Runtime Skills | Reusable procedures | Hidden-prompt and authority risk | Deferred | Repeated tested procedure exists |
| Patch proposal and application | Complete coding work | Mutation and rollback risk | Essential Now | AST operations after exact Patch limits appear |
| Evidence and verification | Truthful completion | Small structured records first | Essential Now | Add formats when checks require them |
| Independent Verifier Child | Separate author Claim from evaluation | Child and Context cost | Important Next | Root deterministic verification works |
| Artifacts and Receipts | Retain large content and completion manifest | Storage and retention | Essential Now | Formal export for an immutable subject |
| SQLite persistence and journal | Restart, audit, and recovery | Migration and transaction work | Essential Now | Distributed storage is not justified |
| General event sourcing | Model all systems as events | High projection complexity | Rejected for Now | Concrete recovery need appears |
| Recovery | Separate work state from chat | Durable transitions | Essential Now | Expand for remote Workers later |
| CLI | Lowest-cost complete interface | Small delivery surface | Essential Now | Remains permanent |
| TUI | Improve concurrent navigation | Renderer and interaction cost | Deferred | Runtime is correct and real Children exist |

## Intelligence and retrieval

| Capability | Value | Cost or risk | Classification | Trigger |
| --- | --- | --- | --- | --- |
| Basic Repository search and read | Current source Context | Low and deterministic | Essential Now | None |
| Tree-sitter | Syntax ranges and symbols | Grammar maintenance | Deferred | Text search causes measured misses |
| LSP | Definitions, references, diagnostics | Server lifecycle and trust | Deferred | A language workflow requires it |
| Persistent code index | Reduce repeated retrieval | Invalidation and storage | Deferred | Repeated use shows latency or token waste |
| Local project intelligence | Reuse prior patterns | Trust, licensing, scope | Deferred | Core workflow is stable and benchmarked |
| Cross-project Evidence | Find prior solutions | Product-direction contamination | Deferred | Approved-root study shows value |
| Embeddings | Fuzzy retrieval | Privacy, dependency, opacity | Rejected for Now | Deterministic benchmark shows recall gap |
| Hosted retrieval | Remote semantic search | Source egress and service dependency | Rejected for Now | Explicit approval and critical need |
| SCIP | Index interchange | Freshness and adapter cost | Research Track | A real producer or consumer exists |

## Protocols and standards

| Capability | Classification | Trigger or reason |
| --- | --- | --- |
| Native adapter boundary | Essential Now | Preserve protocol-neutral core |
| ACP | Deferred | Stable native commands and a real Client need |
| MCP client | Research Track | One capability is better through MCP than simpler options |
| MCP server | Rejected for Now | No accepted host or exposure workflow |
| OpenAPI | Deferred | One accepted service lacks a better library or SDK |
| AG-UI | Rejected for Now | No near-term external Agent UI |
| AHP | Research Track | Stable specification and concrete need |
| A2A | Rejected for Now | Remote ownership and recursive delegation risk |
| WASI and WIT | Research Track | One component beats a supervised subprocess |
| In-toto and SLSA | Deferred | Immutable build or release subject exists |
| OpenTelemetry API | Deferred | Stable operations and Privacy policy exist |
| OTLP export | Rejected for Now | No explicit collector requirement |

Every classification is based on the current workflow, not document depth.

# 12. Minimum credible architecture

```text
CLI
  │
  ▼
Single-Run workflow application
  ├── pure domain and projection functions
  ├── effective-authority evaluator
  ├── explicit Context package builder
  ├── native Repository reader and exact Patch service
  ├── one provider adapter
  ├── one registered Command runner
  ├── Artifact, Evidence, and Receipt functions
  └── SQLite journal and current projections
          │
          └── transient model and Command Workers
```

## Components

| Component | Problem | Smallest solution now | Deliberate exclusion |
| --- | --- | --- | --- |
| CLI | Start, inspect, approve, verify, accept, recover | Commands and structured output | TUI and external Clients |
| Domain | Separate objective, desired work, and attempt | Plain structs and pure rules | Full future entity catalog |
| Workflow application | Coordinate one complete path | Explicit functions and tagged results | General workflow engine |
| Store | Survive restart | SQLite journal and projections | Distributed log and broad ORM framework |
| Repository boundary | Exact source and mutation scope | Native paths, reads, search, Patch, state | MCP Repository access |
| Authority | Bound every effect | Pure intersection and fixed profiles | General policy language and broker process |
| Context | Bound model disclosure | Explicit items and manifest | Opaque retrieval framework |
| Model boundary | Invoke one real model | Provider behaviour, fake, one adapter | Router, ensemble, fallback |
| Patch service | Separate proposal from effect | Exact base-bound transaction | AST framework and writing Child |
| Command runner | Evaluate criteria | Registered executable and argv | Arbitrary shell, container, remote execution |
| Artifact store | Externalize large content | Kiln-owned files and metadata | Remote object store |
| Evidence and Receipt | Support completion claim | Structured observations and bounded manifest | General attestation platform |
| Execution supervision | Own live streams and processes | Transient model and Command Workers | Process per domain noun |

## Call direction

```text
CLI
→ workflow application
→ domain validation
→ authority and Context selection
→ provider, Repository, Patch, or Command boundary
→ Artifact and Evidence creation
→ journal transaction and projection update
→ CLI result
```

Forbidden directions:

- provider output grants authority;
- model output mutates source directly;
- Repository or Command adapter changes criteria;
- Evidence code executes Commands;
- Receipt code accepts work;
- interface state becomes domain authority;
- protocol types enter domain modules.

## Boundaries

- **Execution:** transient Workers own live provider and process Resources.
- **Permission:** pure authority evaluation plus explicit user Approvals.
- **Workspace:** canonical approved root and active Repository.
- **Model:** one sealed Context package and bounded Tool set per invocation.
- **Context:** explicit items, reasons, digests, limits, and exclusions.
- **Evidence:** deterministic observations remain separate from Claims.
- **Artifact:** large retained content stays outside journal and normal Context.
- **Persistence:** SQLite owns work facts; Git and filesystem own source truth.
- **Integration:** adapters translate to native requests and results.

# 13. Source layout

Namespaces are earned by implemented responsibility. Do not pre-create the full Roadmap.

Possible first-month responsibilities are:

```text
lib/kiln/
├── domain/
│   ├── project.ex
│   ├── session.ex
│   ├── task.ex
│   ├── run.ex
│   └── event.ex
├── workflow.ex
├── store.ex
├── projections.ex
├── repository/
│   ├── state.ex
│   ├── reader.ex
│   └── patch.ex
├── model/
│   ├── provider.ex
│   └── invocation_worker.ex
├── context/package.ex
├── policy/effective_authority.ex
├── execution/
│   ├── command.ex
│   └── command_worker.ex
├── artifacts.ex
├── evidence.ex
├── receipt.ex
└── cli.ex
```

The map states responsibilities, not files that must all exist in the first ticket.

Plain data and pure functions own Project subset, Session, Task, Run, Event, projections, policy, Context selection, Patch validation, Evidence, and Receipt construction.

Only model invocation and Command execution need explicit Kiln Worker modules in the first month.

Do not create deferred `tui/`, `attention/`, `delegation/`, general `capability/`, runtime `skills/`, `code_intelligence/`, `knowledge/`, `protocols/`, `telemetry/`, `worktrees/`, `containers/`, or `attestations/` namespaces until an accepted slice needs them.

# 14. Protocol and integration policy

Choose the smallest boundary that preserves semantics, cancellation, security, Evidence, testing, and replacement:

1. direct function;
2. library;
3. deterministic CLI;
4. direct API or SDK;
5. local service or socket;
6. dedicated adapter;
7. protocol client;
8. protocol server;
9. MCP only when discovery or replacement provides measured value.

MCP is not a sandbox, permission system, Context authority, Evidence source, or reason to expose a full catalog.

Foundational now:

- native Kiln contracts;
- provider adapter;
- native Repository boundary;
- registered CLI Command boundary;
- SQLite library boundary.

Optional later:

- ACP;
- one MCP client capability;
- one OpenAPI capability;
- one accepted Dev Container or OCI Environment.

Deferred or rejected:

- MCP server;
- AG-UI;
- AHP;
- A2A;
- SCIP export;
- WASI and WIT runtime commitment;
- formal SLSA claims.

# 15. Context and Tool boundaries

## Required Context

A first-month model package can include:

- accepted objective and criteria;
- current workflow step;
- current Repository fingerprint;
- approved Project instructions;
- selected source ranges with path and digest;
- current Patch or failure summary when relevant;
- current Evidence, assumptions, and unknowns;
- output contract and limits;
- at most four Tool schemas.

## Excluded by default

- complete conversation history;
- full files when ranges suffice;
- complete Tool or Capability catalog;
- all Skills and prompt bodies;
- unrelated Project files;
- reference repositories;
- raw logs and reports;
- secrets and denied paths;
- stale or superseded criteria;
- author-confidence narrative for verification.

## Tool loading

The Tool set is fixed by workflow step. Unused schemas are absent. A model cannot request a catalog dump.

Adding a Tool requires an accepted need, authority profile, input and output contract, limits, failure contract, and deterministic test.

## Skills

Runtime Skills are deferred.

When introduced, metadata can be discoverable, but the body loads only after explicit selection. A Skill cannot grant authority or create a Run. Large procedures must use bounded references. Selection and digest remain inspectable.

## Large results

Large outputs become Artifacts. Context receives a bounded excerpt, digest, completeness state, and continuation method.

## Durable information

Persist objective and criteria revisions, selected item references and digests, Context manifest and package digest, Tool names and request digests, model result Artifact reference, Claims, Evidence, warnings, and unknowns.

Do not persist hidden reasoning or duplicate complete source content when exact Repository state can recover it.

## Inspectability

Every Context item states source, authority, trust, sensitivity, state binding, freshness, selection reason, transformation, token estimate, and disclosure decision when remote.

# 16. Local-first and security boundaries

## Local by default

Objective, criteria, Run state, journal, projections, Repository observations, Patch application, Commands, Artifacts, Evidence, Receipts, and user decisions remain local.

Only the sealed provider Context package and required provider metadata may leave the machine.

## Explicit Approval

Require explicit user Approval for:

- the exact Patch digest before mutation;
- source excerpt classes not already allowed by disclosure policy;
- network destinations beyond the configured provider;
- later broader Commands, worktree cleanup, publication, or export.

## Source and secret protection

- canonical approved root;
- path validation for every operation;
- deny symlink escape and special files by default;
- bounded reads;
- exact base hashes before Patch;
- one mutation owner;
- no model shell;
- no automatic dependency installation;
- no automatic commit, push, merge, or publish;
- minimal constructed Command environment;
- opaque secret references;
- denied secret paths and excerpt screening;
- no secret values in journal, logs, telemetry, Receipt, or normal Artifact metadata.

## Reference repositories and prompt injection

Reference repositories are disabled through version 0.1.

When later enabled, they remain read-only Evidence sources with `instruction_authority: none` and separate approved roots.

Instructions in source, comments, documentation, generated files, prompts, issues, or reference repositories are untrusted data unless part of the accepted active Project instruction set.

Prompt text alone is not enforcement. Path, Tool, permission, disclosure, and mutation boundaries must be deterministic.

## Delegation and concurrent writes

A Child receives a new Context package and narrower explicit grants. It receives no ambient Parent transcript, Tools, Skills, secrets, write scope, provider cache, or sibling state.

A Child cannot grant authority or create descendants in version 0.1.

The first month has one Root Run, one selected writable checkout, and no concurrent writer. Managed worktrees enter only after a real isolation need appears.

# 17. Evidence and completion model

## Evidence

Evidence is a structured observation bound to a subject, method, exact state when applicable, time or sequence, freshness, and completeness.

First-month types are:

- Repository state observation;
- source content observation;
- Patch proposal and application observation;
- Command result;
- criterion result;
- user Approval and acceptance decision.

## Not Evidence

- model confidence;
- persuasive summary;
- proposed Patch alone;
- exit zero without criterion evaluation;
- Receipt without underlying current Evidence;
- unrelated passing test;
- old result against changed source;
- absence of an observed error.

## Artifact

An Artifact is immutable stored content or a durable external reference. Initial kinds are model result, Patch proposal, rollback data, Command output, structured test report, and completion attachment.

Artifact existence does not make content Evidence or model-visible.

## Receipt

A Receipt is a sealed manifest that references Session, Task, Run, objective, criteria, Repository state, Context digest, provider, authority, Approvals, Patch, Command, Evidence, warnings, unknowns, user acceptance, and manifest digest.

A Receipt cannot grant authority, modify state, make Evidence current, turn failure into `PASS`, or accept work.

## Verification and completion

Verification evaluates accepted criteria through deterministic observations or registered Commands against exact current state.

A Task completes only when:

- the accepted Patch is the observed Repository state;
- every required criterion has current passing Evidence;
- no required operation is blocked or orphaned;
- no unknown effect remains;
- the user accepts the result.

Store all material failed, blocked, stale, contradictory, and orphaned results.

## Retention

Retain journal events, current projections, Patch and rollback Artifacts, required Command results, criterion Evidence, and final Receipt through the active Session.

Exact raw-output, abandoned-proposal, historical Context, and long-term Artifact retention requires focused planning.

# 18. Delivery targets

## First month — Single-Run Change Alpha

```text
open one Repository
→ record objective and criteria
→ start one Root Run
→ investigate through bounded reads
→ propose exact Patch
→ approve Patch digest
→ apply Patch
→ run registered verification
→ block completion on failed or blocked Evidence
→ accept current passing result
→ restart and restore work
```

Included:

- one active Repository;
- Session, Task, Root Run, and minimum lifecycle;
- SQLite journal and projections;
- one provider and deterministic fake;
- explicit Context package and four-Tool maximum;
- native read and exact search;
- exact Patch proposal and application;
- explicit Approval;
- one registered Command;
- minimal Artifacts, Evidence, Receipt, and restart;
- CLI only.

Excluded:

- Child Runs;
- TUI;
- background concurrency and Attention;
- managed worktrees;
- general Capability broker;
- Skills;
- LSP, Tree-sitter, persistent index;
- protocols;
- local project intelligence;
- telemetry and remote execution.

Acceptance requires exact restart, disclosure, mutation, verification, completion, and no-process-per-domain-noun Evidence.

## Twelve weeks — Trustworthy Delegated CLI

Add:

- interruption and unknown-effect recovery;
- one read-only Scout Child;
- one independent Verifier Child;
- maximum one active depth-one Child;
- bounded result delivery;
- Root-visible Attention;
- CLI Run list, inspect, enter, cancel, and return-to-Root.

Still defer TUI, nested or concurrent Child graph, writing Child, managed worktrees, code intelligence, runtime Skills, protocols, local project intelligence, embeddings, telemetry export, remote execution, publication, and attestations.

Operational limits:

- one local active Project and Repository;
- one active Session per CLI process;
- one Root Run;
- one active depth-one Child;
- one provider;
- one primary operating-system process-control target;
- no general shell;
- no automatic network destinations beyond the provider.

Version 0.1 Evidence includes aggregate deterministic tests, restart and orphan fixtures, Patch and Command safety fixtures, Scout no-write proof, Verifier `PASS`, `FAIL`, and `BLOCKED` fixtures, exact final Repository state, and one aggregate Receipt.

# 19. Three largest delivery risks

| Risk | Cause | Probability | Impact | Earliest warning | Mitigation | Scope reduction |
| --- | --- | --- | --- | --- | --- | --- |
| Scope expands before product proof | Detailed future planning invites horizontal implementation | High | High | Later directories, dependencies, or tickets appear before first change loop | Enforce exclusions and one workflow per new boundary | Remove Child, TUI, protocols, indexes, and broker from target |
| Safe Patch and Command work exceeds one developer's platform budget | Filesystem edge cases, process trees, cancellation, rollback, dirty state | Medium-high | High | Unknown effects or partial rollback appear in fixtures | Support one platform, exact Patch form, one Command, no shell | Ship proposal and verification without application rather than weaken safety |
| Provider and Context boundary leaks source or varies too much | Remote disclosure, retries, token limits, model behavior | Medium | High | Context cannot be reproduced or secret canaries escape | One provider, deterministic fake CI, explicit manifest, screening | Keep live provider path optional until deterministic local path passes |

# 20. Decision status register

## Accepted decisions retained

- one developer and local-first operation;
- Elixir and OTP for runtime coordination;
- SQLite as first durable store;
- journal separate from transcript;
- Git and filesystem as Repository truth;
- Task and Run distinction;
- Run identity separate from process, Agent, model, Tool, Command, branch, and protocol;
- no permanent process per Run;
- explicit Capability-based authority;
- Context cannot grant authority;
- Evidence outranks model confidence;
- external protocols adapt to Kiln;
- reference repositories have no instruction authority;
- mature tools should be reused;
- no concurrent writers in one checkout.

## Proposed decisions

- single-Run change loop before Child graph;
- CLI before TUI;
- one real source change in version 0.1;
- SQLite journal in the first slice because recovery is core;
- no separate Root Task initially;
- Child depth one and one active Child through version 0.1;
- direct deterministic Root verification before Verifier Child;
- one selected writable checkout before managed worktrees;
- fixed Tools and authority evaluator before general broker;
- TUI, code intelligence, protocols, Skills, and local project intelligence after twelve weeks.

## Rejected for now

- simulated TUI as first milestone;
- read-only version 0.1;
- nested delegation in version 0.1;
- three concurrent Children before dogfooding;
- process per active Run;
- general routing, retrieval, broker, Event, or Evidence framework before one workflow;
- mandatory worktrees for harmless reads or one writer;
- protocol implementation for coverage;
- embeddings and hosted retrieval.

## Proposed supersessions after owner acceptance

- ADR 0019 implementation order and read-only version 0.1 boundary;
- previous P1-S01 through P1-S05 sequence;
- near-term depth-two and three-active-Child limits;
- first-slice TUI and ExRatatui requirement;
- broad initial source-directory guidance.

Historical rationale remains in Git and ADR 0019.

# 21. Existing implementation and scaffolding affected

Prompt 3 must examine:

- empty OTP application shell against the minimum process list;
- preflight and P1 ticket incompatibility;
- plan template and slice-ticket grammar;
- `scripts/check`, CI, Vale, and asset validation;
- development Skills and prompts that assume older flow;
- specialist-agent definitions that resemble runtime roles;
- broad source-layout guidance;
- ExRatatui planning and implied early dependency;
- all JSON Schemas against the reduced subset;
- future gate names and Receipt scaffolding;
- ADR and status labels;
- historical files that call planning an implemented capability.

Prompt 3 should assign retain, narrow, replace, remove, or defer dispositions before repairs.

# 22. Remaining planning-domain assessment

| Domain | Assessment | Reason |
| --- | --- | --- |
| Product definition and non-goals | Resolved by Prompt 2, pending acceptance | Target is explicit |
| Minimum Run, Session, Task, Child scope | Resolved by Prompt 2, pending acceptance | Enough for implementation planning |
| Exact lifecycle transition table | Dedicated planning round | Recovery correctness depends on it |
| SQLite journal, projections, migrations, transactions | Dedicated planning round | Foundational durable-state decisions remain |
| Patch format, checkout policy, rollback, dirty conflicts | Dedicated planning round | Mutation safety cannot be invented during coding |
| Command registration, process-tree control, primary platform | Dedicated planning round | High-risk execution boundary |
| Provider, Context, disclosure, secret screening | Dedicated or combined model-boundary round | Remote egress and token limits are coupled |
| Evidence, Receipt, retention | Belongs with journal and execution planning | Types resolved; lifecycle is not |
| CLI syntax and interaction | Bounded implementation decision | Foundational actions are resolved |
| Child permission derivation and Attention | Dedicated round before Child slice | Concurrency and authority enter later |
| TUI and ExRatatui | Deferred until blast radius | Outside twelve weeks |
| Runtime Skills | Deferred | No repeated runtime procedure exists |
| Code intelligence | Deferred until its slice | Not required for basic source workflow |
| Local project intelligence | Deferred after active code intelligence | High trust and scope cost |
| Protocol adapters | Optional research with a concrete consumer | Protocols do not define core |
| Telemetry | Deferred until operations stabilize | Not state or Evidence |
| Packaging and release | Plan near version 0.1 integration | No current release Artifact |
| Final Planning Round Register | Prompt 4 | Prompt 2 supplies inputs only |

# 23. Required architecture challenges

| Risk | Evidence | Present? | Correction | Consequence |
| --- | --- | --- | --- | --- |
| Protocol support becomes product | Many protocol documents and expansion slice | Partial | Remove coverage from near-term outcome | Concrete workflow entry gate required |
| Run graph becomes orchestration theater | Simulated graph was first slice | Yes | Root Run first; Child only after value | No graph code first month |
| TUI precedes runtime correctness | TUI preceded provider and persistence | Yes | CLI-first; TUI after twelve weeks | No early TUI dependency |
| OTP processes represent static concepts | Run process example existed | Yes | Process only live Resources | Remove RunSupervisor design |
| Event sourcing lacks recovery need | Broad event planning existed | Partial | Journal only material recovery and audit facts | No event for every token or static noun |
| MCP replaces simpler option | Existing hierarchy prefers simpler choices | Not active | Preserve entry gate | No near-term MCP |
| Context becomes opaque retrieval | Broad compiler design spans many sources | Yes as future risk | Explicit package and fixed sources | General compiler deferred |
| Tool catalog consumes Context | Broad broker catalog planned | Yes as future risk | Four Tool maximum | New Tool requires Evidence |
| Skills become hidden prompts | Skill system planned before runtime need | Yes as future risk | Defer and lazy-load later | No runtime Skill loader |
| Intelligence becomes vector project | Detailed knowledge planning exists | Yes as scope risk | Defer; reject embeddings and graph database | No knowledge system in version 0.1 |
| Cross-project Evidence contaminates direction | Reference retrieval planned | Yes as safety risk | Disable reference roots through version 0.1 | Later content stays inert Evidence |
| Reference repositories are modified | Security docs prohibit mutation | High consequence | Preserve no-write and separate authorization | No reference execution in Roadmap |
| Permissions expand through delegation | Prior design prohibits inheritance | Risk remains | Child intersection only narrows | Tests required before Child slice |
| Durable state duplicates conversation | Journal and transcript already separate | Partial risk | Persist work facts and references | Recovery uses state, not summary |
| Worktrees required for trivial work | Execution hierarchy says reads need none | Partial future risk | One checkout first | No worktree provisioner first month |
| Protocols dictate internal architecture | ADRs prohibit it | No if enforced | Native requests and results | Adapter types forbidden in domain |
| Elixir justifies unnecessary concurrency | Early plans named many supervisors | Yes | Only justified Workers | Pure modules preferred |
| System is too large for one developer | Plans cover UI, broker, indexes, protocols, containers, telemetry | Yes | Narrow first month and twelve weeks | Expansion moves beyond version 0.1 |

# 24. Build blockers

Prompt 3 can proceed only after this pass is reviewed, accepted, integrated, and validated.

Broad implementation remains blocked by:

- Prompt 3 implementation and scaffold disposition;
- Prompt 4 planning-round sequencing;
- focused planning for journal, Patch, Command, provider, Context, and recovery;
- Prompt 6 conformance work;
- final independent adversarial review;
- adjudication and build authorization;
- current preflight incompatibility;
- no accepted authorized P1-S01 ticket plan.

# 25. Authoritative information movement

- README summarizes product and targets.
- Architecture owns minimum components, processes, and boundaries.
- Roadmap owns revised order.
- Implementation Slices owns slice behavior.
- Slice Acceptance Gates owns planned aggregate proof.
- Run and Session Models own minimum identity and lifecycle.
- Delegated Work owns depth-one Child contracts.
- CLI-TUI owns complete CLI and deferred TUI entry conditions.
- Project Provenance retains rationale.
- Agent-Friendly Codebase owns earned source layout.
- Protocol Map owns integration selection and standards status.
- Contract index records Schema disposition targets.
- ADR 0020 records proposed change-loop-first order and partial ADR 0019 supersession.

No product implementation, test, workflow, script, Schema, dependency, Skill, prompt, agent definition, or gate implementation changes in P0-W18.

# 26. Prompt 2 completion gate

Prompt 2 passes when:

- canonical documents use one product definition;
- non-goals constrain implementation;
- first useful version completes one real change;
- Run model serves work rather than Agent management;
- process-per-active-Run is removed;
- every near-term process has live ownership justification;
- journal is tied to recovery and audit;
- protocols remain adapters;
- source layout matches minimum target;
- Context and Tool limits are explicit;
- local-first and security invariants are explicit;
- Evidence and completion are defined;
- first-month and twelve-week targets are credible;
- Prompt 3 inputs and remaining planning domains are explicit;
- Repository validation passes;
- build authorization remains denied.

# 27. Exact next action

After P0-W18 is reviewed, accepted, and integrated, run **Prompt 3 — Reconcile scaffolded, partial, and completed-looking implementation** against current `main`.

Do not begin Prompt 4 or implementation before Prompt 3 passes.
