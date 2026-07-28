# Kiln Product Scope and Minimum Architecture

**Document type:** Product-scope and minimum-architecture authority  
**Decision status:** Proposed by P0-W18; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Not implemented  
**Baseline:** P0-W17 integrated through pull request 22  
**Build authorization:** Not issued

## Authority

This document records the Prompt 2 reconciliation.

After owner acceptance and integration:

- `README.md` remains the concise product authority;
- `docs/ARCHITECTURE.md` remains the integrated architecture authority;
- `docs/ROADMAP.md` remains the implementation-order authority;
- `docs/IMPLEMENTATION-SLICES.md` remains the slice-detail authority;
- this document owns product scope, capability classification, minimum-architecture rationale, and remaining planning-domain assessment.

Subject specifications can add detail. They cannot broaden the first-month or twelve-week scope without an accepted roadmap change.

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

## Observed Fact

Current Repository source, configuration, tests, Git state, CI, or integrated planning Evidence directly supports the statement.

## Accepted Decision

An accepted ADR or integrated authority establishes the decision and this pass does not challenge it successfully.

## Proposed Decision

P0-W18 recommends the decision. The decision becomes accepted only after owner acceptance and integration.

## Inferred Decision

Current accepted sources imply the decision, but no current authority states it directly.

## Assumption

The plan depends on the claim, but direct Evidence is not sufficient.

## Unknown

Current Evidence does not support a defensible answer.

## Conflict

Current sources prescribe incompatible behavior or authority.

## Superseded Decision

A later accepted authority replaced the decision.

## Build Blocker

An implementation agent would otherwise need to invent a foundational product, safety, or architecture decision.

# 3. Executive reconciliation verdict

## What Kiln should be

**Proposed decision:** Kiln should be a local-first coding execution ledger and control plane for one developer.

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

Kiln should own the durable work record, authority decisions, model Context boundary, controlled side effects, Evidence, and recovery state.

Kiln should use models, Git, the filesystem, existing CLIs, and later adapters without replacing them.

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
- a policy-only security wrapper;
- a transcript archive described as durable project state.

## Coherence verdict

**Observed fact:** The current top-level architecture is internally coherent.

**Conflict:** The current delivery order does not prove the smallest useful coding workflow first. It begins with a simulated Run graph and TUI, then delivers a read-only version 0.1 after twelve weeks.

## Largest scope correction

**Proposed decision:** Version 0.1 must complete one real source change and deterministic verification loop. A read-only twelve-week milestone is too weak for a coding harness and is not sufficiently differentiated from current coding agents.

## Largest architecture correction

**Proposed decision:** The first useful Kiln shall use one Session, one Task, and one Root Run. Child Runs, background scheduling, Run-tree navigation, and the TUI shall not be prerequisites for first-month usefulness.

## Prompt 2 verdict

Prompt 2 passes on this branch when the canonical documents agree with this reconciliation and Repository validation passes.

Passing Prompt 2 does not accept the proposed decisions, authorize implementation, or complete Prompt 3.

# 4. Reconciled product definition

## Primary user

**Accepted decision:** The initial user is one developer working on one local active Repository at a time.

Multi-user collaboration, hosted control, teams, and remote Workers are outside the initial product.

## Primary problem

The developer can ask a coding model to inspect, change, and test a Repository, but the surrounding work often remains bound to a conversation and a permissive tool loop.

The developer needs a reliable answer to these questions:

- What objective and criteria control this work?
- What Repository state did the model inspect?
- What did the model propose?
- What did Kiln actually change?
- Which Commands ran against which state?
- What failed or remains unknown?
- What Evidence supports completion?
- Can the work resume after interruption without repeating uncertain effects?

## Current alternatives

Current coding agents already provide substantial capability:

- Pi provides persistent branching sessions, model choice, tool allowlists, read and write Tools, Bash, Skills, extensions, and programmatic integration.
- OpenCode provides a TUI, provider flexibility, built-in and custom Agents, subagents, LSP, Skills, permission rules, and a client/server architecture.
- Codex CLI can read, modify, and run local code with approval modes.

These products show that session persistence, terminal interaction, model selection, basic permissions, file editing, Bash, Skills, subagents, and provider flexibility do not differentiate Kiln by themselves.

## Product hypothesis

**Strong hypothesis:** A developer will value a harness that treats the accepted objective, change, execution results, Evidence, and recovery state as first-class durable work rather than as implications of a transcript.

**Weak hypothesis:** The user will prefer a navigable Run graph before Kiln can complete one real change.

**Long-term possibility:** A bounded Run graph can improve delegated investigation and independent verification after the single-Run loop proves value.

## Differentiation

Kiln is meaningfully different only when it can:

1. bind one objective and criteria to exact Repository state;
2. limit model-visible Context and Tools explicitly;
3. separate model proposals from deterministic effects;
4. require user approval for the exact proposed mutation;
5. execute one registered verification Command;
6. retain machine-readable current Evidence;
7. block completion on failed, stale, missing, or contradictory Evidence;
8. recover durable work without replaying unknown effects.

## Observable result

The user receives:

- the current objective and criteria;
- one inspectable Run status;
- the exact proposed and applied change;
- the Commands that ran;
- current `PASS`, `FAIL`, or `BLOCKED` verification status;
- retained Artifacts and Evidence references;
- a bounded Receipt;
- a truthful next action after success, failure, interruption, or restart.

## Success criteria

Kiln succeeds when one developer can complete a narrow real change with less ambiguity about authority, state, verification, and recovery than in a normal coding-agent session.

Kiln does not succeed because it can create more Agents, display more panes, load more Tools, or implement more protocols.

# 5. Explicit non-goals

The following non-goals constrain early product and architecture decisions.

## Product non-goals

Kiln shall not initially:

- coordinate an autonomous Agent organization;
- allow recursive Agent management;
- act as a general multi-agent framework;
- require Child Runs for ordinary sequential work;
- optimize for parallel activity rather than completed work;
- become a generic workflow engine;
- become a hosted collaboration product;
- expose a plugin marketplace;
- derive product requirements from unrelated repositories.

## Tooling non-goals

Kiln shall not replace:

- Git;
- the filesystem;
- build and test tools;
- package managers;
- language servers;
- parsers with mature libraries;
- mature command-line tools;
- provider software development kits when a bounded adapter is sufficient.

## Intelligence non-goals

Kiln shall not initially:

- index the entire local filesystem;
- index reference repositories automatically;
- require embeddings for basic retrieval;
- require a vector database or graph database;
- start language servers for reference repositories;
- treat retrieved instructions as active authority;
- copy or adapt code without provenance and licensing review.

## Protocol non-goals

Kiln shall not initially:

- implement every emerging Agent protocol;
- use MCP for native Repository, Git, journal, Evidence, or policy operations;
- expose an MCP server;
- let ACP, AG-UI, AHP, A2A, SCIP, WASI, WIT, in-toto, or SLSA define the internal domain;
- implement two adapter forms for one narrow service only to claim coverage.

## Safety non-goals

Kiln shall not initially:

- grant ambient shell access to a model;
- inherit a user's complete environment into Commands;
- allow delegation to widen authority;
- allow concurrent writers in one checkout;
- modify reference repositories;
- auto-commit, push, merge, publish, or deploy;
- treat a process boundary or protocol as a sandbox;
- claim unknown external effects are canceled or complete.

# 6. Smallest useful Kiln

## Proposed first useful product

The smallest useful Kiln is a **single-Run, CLI-first, durable change loop** for one local Repository.

It contains:

- one Project definition for one active Repository;
- one Session for one accepted objective;
- one Task with explicit criteria;
- one Root Run;
- one fixed provider adapter and a deterministic fake provider for tests;
- native bounded Repository search and read;
- one explicit Context package;
- at most four model-facing Tools;
- one exact Patch proposal;
- explicit user approval for the Patch digest;
- deterministic Patch application to one selected writable checkout;
- one registered non-shell verification Command;
- minimal Artifact, Evidence, and Receipt records;
- an append-oriented SQLite journal for restart and audit;
- CLI status, inspect, approve, cancel, resume, and verify actions.

## Why each part is required

| Part | Requirement | Existing implementation reused | Deferred alternative |
| --- | --- | --- | --- |
| Project and Repository boundary | Prevent path and policy ambiguity | Git and filesystem | Multi-Repository Project |
| Session, Task, Root Run | Separate objective, desired outcome, and attempt | Plain data and SQLite | Child Run graph |
| One provider | Produce real model-guided work | Provider API or SDK | General router and fallback |
| Native read and search | Give bounded current source Context | Filesystem and deterministic search | LSP and Tree-sitter |
| Explicit Context package | Bound disclosure and token use | Plain selection functions | General retrieval framework |
| Exact Patch proposal | Separate model proposal from mutation | Patch parser or bounded library | AST transformation framework |
| Explicit approval | Preserve user mutation authority | CLI confirmation | Persistent approval policy |
| One registered Command | Verify one accepted criterion | Existing Project CLI | General shell and Command catalog |
| Artifact and Evidence records | Support completion claim | Filesystem blobs and structured records | General Evidence platform |
| SQLite journal | Support restart, audit, replay, and unknown effects | SQLite library | Distributed event system |
| CLI | Deliver the workflow with low interface cost | Elixir CLI | TUI, ACP, web client |

## Deliberate exclusions

The first useful version does not require:

- Child Runs;
- Run graph navigation;
- background concurrency;
- global Attention routing;
- a TUI;
- managed worktree provisioning;
- a general Capability broker service;
- Skills;
- LSP or Tree-sitter;
- local project intelligence;
- external protocols;
- telemetry export;
- remote execution;
- formal attestations.

# 7. Primary workflow

## Intent

### User input

The user selects one Repository, states one objective, and accepts explicit completion criteria.

### Kiln responsibility

Kiln records the Project root, Repository fingerprint, objective revision, criteria revision, Task, Session, and Root Run.

### Model responsibility

None.

### Deterministic responsibility

Validate the Repository root, selected writable checkout, Git state, policy, identifiers, and durable transaction.

### State and Evidence

- Project observation;
- objective and criteria revision;
- Repository fingerprint;
- Session, Task, and Root Run creation events.

### Failure behavior

Invalid, unavailable, denied, or ambiguous Repository state blocks the Run before model invocation.

### User-visible status

`ready` with exact Repository and criteria summary.

## Investigation

### User input

The user starts the Root Run or asks a bounded Repository question within the accepted objective.

### Kiln responsibility

Kiln builds one inspectable Context package and exposes only approved read/search operations.

### Model responsibility

The model investigates, identifies relevant source, states observations, separates inferences and unknowns, and proposes a bounded change.

### Deterministic responsibility

- canonicalize paths;
- enforce excludes and file limits;
- screen denied and secret-bearing content;
- bind excerpts to content digests;
- enforce step, token, Tool, and elapsed-time limits.

### Tools

Initial model-facing operations are limited to:

```text
repo.search
repo.read
artifact.read
change.propose
```

`change.propose` creates a proposal. It does not mutate source.

### State and Evidence

Repository observations and exact source references become Evidence. Model conclusions remain Claims.

### Failure behavior

Provider, Context, path, limit, or disclosure failure records a failed or blocked step. It does not widen scope or fall back silently.

### User-visible status

Current activity, selected source, limits, Claims, Evidence, and blockers.

## Implementation

### User input

The user inspects the proposed Patch and explicitly approves or rejects its exact digest.

### Kiln responsibility

Kiln validates the Patch against exact base file hashes and allowed paths, retains rollback information, applies the transaction, and observes the result.

### Model responsibility

The model can explain or revise a rejected proposal. It cannot approve or apply its own Patch.

### Deterministic responsibility

- no fuzzy application;
- no path escape;
- no symlink or special-file violation;
- no overlap with unowned dirty changes;
- atomic replacement where supported;
- rollback on partial failure;
- before and after content digests.

### State and Evidence

The proposal, approval, application outcome, changed regions, rollback reference, and resulting Repository fingerprint are durable.

### Failure behavior

Conflict, stale base, partial application, or uncertain rollback blocks verification and completion.

### User-visible status

`proposed`, `approved`, `applied`, `conflicted`, `rolled_back`, or `orphaned`.

## Verification

### User input

The user starts or accepts the configured verification action.

### Kiln responsibility

Kiln runs one registered non-shell Command against the exact changed state.

### Model responsibility

The model can summarize results. It cannot turn them into `PASS` or change criteria.

### Deterministic responsibility

- fixed executable and argv;
- bounded working directory;
- minimal environment;
- timeout;
- process-tree ownership on the supported platform;
- bounded live output;
- complete retained output Artifact when permitted;
- exit and structured-result normalization.

### State and Evidence

Command request, state binding, output Artifacts, exit status, cleanup result, and criterion result become Evidence.

### Failure behavior

- failed criterion produces `FAIL`;
- missing tool or invalid Environment produces `BLOCKED`;
- unknown process effects produce `orphaned` and block completion.

### User-visible status

Per-criterion `PASS`, `FAIL`, or `BLOCKED` with current Evidence links.

## Completion

### User input

The user accepts the result or continues work.

### Kiln responsibility

Kiln evaluates completion readiness from current criteria, Patch state, verification Evidence, unresolved blockers, and user acceptance.

### Model responsibility

The model may recommend completion. The recommendation remains a Claim.

### Deterministic responsibility

Completion is allowed only when:

- the accepted Patch is applied;
- required verification is current and passes;
- no unknown effects remain;
- no blocking Attention remains;
- the user accepts the result.

### State and Evidence

Kiln seals a Receipt that references all required durable records. It does not copy every Artifact into the Receipt.

### Failure behavior

Missing, failed, blocked, contradictory, or stale Evidence keeps the Task open.

### User-visible result

A completion summary with exact change, verification, Evidence, warnings, exclusions, and next action.

## Interruption and recovery

Kiln persists every material transition before reporting it as durable.

After restart, Kiln restores the Session, Task, Root Run, current step, proposal, application state, Command state, Evidence, and user decisions.

Kiln does not replay a model invocation, Patch, or Command automatically when effects are uncertain.

Unknown effects produce `orphaned` state and a reconciliation action.

# 8. Reconciled Run model

## Run

A Run is one durable, independently inspectable attempt or coordination boundary for one Task.

For the first useful version, the Root Run is the primary unit of:

- execution coordination;
- observation;
- persistence;
- cancellation;
- Evidence association;
- recovery.

A Run is not:

- a conversation;
- a model invocation;
- a Tool call;
- a Command;
- a process;
- a branch;
- a worktree;
- an Agent persona;
- a protocol session.

## Session

A Session is one accepted Project objective and its complete Kiln work history.

The first version has one Session open at a time per CLI process. Multi-client and multi-Session coordination are deferred.

## Task

A Task states one desired outcome and its criteria.

A Run attempts or coordinates the Task. Completing a Run does not satisfy the Task without current Evidence and acceptance.

## Root Task

**Proposed decision:** The initial implementation shall not create a separate Root Task concept.

The Session owns one accepted objective. It creates one initial Task. The Root Run attempts or coordinates that Task.

A separate Root Task adds terminology without current user value.

## Project and Workspace

The initial Project is one active Repository plus accepted instructions and policy.

Workspace remains the host-local maximum trust and path boundary. It does not require a persistent registry in the first month.

## Minimum lifecycle

The first useful version requires:

```text
created
→ ready
→ running
→ waiting_for_user | waiting_for_command | verifying
→ completed | failed | canceled | orphaned
```

Rules:

- `completed`, `failed`, and `canceled` are terminal for one attempt;
- `orphaned` requires explicit reconciliation;
- `waiting_for_user` records the pending decision and resume point;
- `waiting_for_command` identifies the owned execution;
- `verifying` identifies the criteria and exact state;
- Evidence staleness is an Evidence property, not a separate first-month Run status.

Later Child and background work can add `queued`, `waiting_for_child`, `waiting_for_permission`, and `paused` after their workflows require them.

## State owned or referenced by a Run

- Session and Task identity;
- Root and optional Parent identity;
- accepted Task and criteria revision;
- status and current workflow step;
- policy and authority snapshot references;
- Context package manifests;
- model invocation references;
- Tool calls;
- Patch proposal and application references;
- Command execution references;
- Artifacts, Claims, Evidence, and Receipt references;
- warnings, failures, unknowns, and cancellation state;
- timestamps and accounting.

## State that does not belong in Run identity

- BEAM or operating-system process identifiers;
- provider request identifiers;
- branch, worktree, or commit identity;
- complete transcript content;
- complete Tool catalog;
- raw Artifact content;
- client-local cursor, scroll, selection, or draft state.

## Conversation relationship

Conversation messages are ordered interaction records associated with a Run.

They are not the canonical objective, Task state, mutation state, Evidence state, or completion state.

A compact current Context package is constructed from authoritative state and selected records. Kiln does not recover by asking a model to summarize the full transcript.

## Child Runs

**Classification:** Important next, not Essential now.

The first twelve-week target can add two depth-one role contracts:

- one read-only Scout Child;
- one independent Verifier Child.

Near-term limits are:

```text
Maximum Child depth:          1
Maximum active Child Runs:    1 per Session
Peer communication:           disabled
Shared mutable Context:       disabled
Child permission expansion:   disabled
Writing Child:                disabled
```

These limits replace the earlier depth-two and three-active-Child defaults for version 0.1. Expansion requires dogfood Evidence.

### User problem

A Child Run is justified only when the work needs independent Context, authority, cancellation, Evidence, result delivery, or background visibility.

### Creation authority

The Root Run can request a Child. A deterministic application service validates the purpose, role, limits, and effective authority before creating it.

A Child cannot create or authorize another Child in version 0.1.

### Navigation

The CLI can list Runs, inspect one Child, and return to the Root. A TUI is not required.

### Blocked work

A blocking Child question, permission request, failure, or missing prerequisite creates an Attention record visible from the Root status.

### Cancellation

Canceling a Child targets its Worker and owned executions. It does not cancel the Root automatically.

### Permissions

Child authority is the intersection of Project policy, Session limits, role profile, requested scope, and explicit grant. It cannot exceed the Root Run or Project maximum.

### Evidence return

A Child returns one bounded structured result with Evidence and Artifact references. It does not copy its transcript into the Parent Context.

### Anti-theater rule

Do not create a Child to wrap one Tool call, add a persona, imitate an organization, or inflate activity.

# 9. OTP process justification

## Accepted process rule

A process exists only when it owns live mutable state, a live Resource, concurrency, timing, cancellation, streaming, subscriptions, external communication, or fault isolation.

No process exists merely because a Session, Task, Run, Capability, Context package, Artifact, Evidence record, Receipt, or Attention item exists.

## First-month process boundaries

| Process or runtime owner | State or Resource owned | Lifecycle | Concurrency and failure value | Why plain data is insufficient |
| --- | --- | --- | --- | --- |
| Application supervisor | Child process topology | Application lifetime | Restarts required live owners | Processes need one root supervisor |
| Model invocation Worker | Provider stream, network request, cancellation handle, output limits | One invocation | Isolates provider failure and supports cancellation | A struct cannot own a live stream or cancellation handle |
| Command Worker | Port or process tree, timeout, output capture, cleanup | One Command | Isolates command failure and owns termination | A plain function cannot supervise an external process tree |
| SQLite connection owner supplied by the selected library | Database connection and transaction serialization | Application or pool lifetime | Protects connection and transaction lifecycle | The library normally represents the connection as a process |

## Processes not justified in the first month

- `RunSupervisor`;
- one process per Root Run;
- `SessionRuntime`;
- `WorkspaceServer`;
- `ProjectServer`;
- `TaskServer`;
- `CapabilityBroker` GenServer;
- `ContextCompiler` GenServer;
- `EvidenceServer`;
- `ReceiptServer`;
- `ArtifactServer`;
- `AttentionRouter`;
- `EventPublisher`;
- adapter supervisor without a live adapter;
- TUI renderer process.

These responsibilities remain pure modules, persisted records, library-owned Resources, or direct application functions until a workflow creates a live ownership need.

## Twelve-week adjacent processes

| Process | Entry condition | Ownership |
| --- | --- | --- |
| Session coordinator | A background Child and Attention require scheduling, timers, and subscriptions | One active Session's Worker leases, timer state, and delivery routing |
| Child Worker | One Child advances independently | Model stream and Child cancellation boundary |
| Local event publisher | More than one live Client or a TUI requires ordered subscriptions | Transient subscriber cursors and backpressure, not durable state |

# 10. Event journal decision

## Concrete requirement

Kiln requires restart recovery, ordered audit, projection rebuild, duplicate-effect prevention, client resume, and honest unknown-effect reconciliation.

These are concrete reasons for an append-oriented event journal.

## Proposed boundary

- Use SQLite as the first durable journal.
- Record accepted state transitions, authority decisions, external-effect requests and results, Evidence state, and acceptance decisions.
- Update minimal current projections in the same transaction where practical.
- Keep transcript records separate from domain events.
- Keep raw Artifacts outside event payloads.
- Do not event-source static documentation, model catalogs, every token, every UI movement, or rebuildable code indexes.
- Do not add distributed logs, message brokers, CQRS frameworks, or generalized event infrastructure.

Event sourcing is a bounded recovery mechanism, not the product.

# 11. Capability classification

## Core workflow

| Capability | User problem and value | Current Evidence | Cost, safety, and architecture effect | Classification | Reconsideration trigger |
| --- | --- | --- | --- | --- | --- |
| Run lifecycle | Makes one attempt inspectable, cancellable, and recoverable | Central accepted domain; no runtime | Small pure model plus journal | Essential Now | Expand states only when a workflow requires them |
| Session and Task | Preserve objective and separate desired outcome from attempt | Accepted domain | Low cost; prevents transcript-only state | Essential Now | Multi-Session only after one Session works |
| Child Runs | Independent Context, authority, cancellation, and Evidence | Strong long-term design; no user Evidence yet | Adds scheduling, navigation, delivery, and permission complexity | Important Next | Single-Run alpha proves value and one delegated workflow is accepted |
| Run graph navigation | Makes delegated work visible | Current plan only | Interface and projection cost; theater risk | Important Next | At least one real Child exists |
| Nested Runs | Supports delegated delegation | No observed need | High complexity and orchestration risk | Rejected for Now | A measured workflow cannot complete with depth one |
| Background concurrency | Lets Root continue during read-only work | Product hypothesis | Scheduler, race, and Attention complexity | Important Next | One bounded Child is useful sequentially |
| Attention | Prevents silent blockers | Accepted safety requirement for background work | Requires durable routing and idempotency | Important Next | First Child can block on user or permission input |
| Command execution | Produces deterministic verification | Required by complete change loop | High process-control risk; narrow registry limits it | Essential Now | Expand registrations only with accepted workflows |
| General shell | Flexible execution | Mature shells exist; high risk | Broad authority and unknown effects | Rejected for Now | A registered CLI cannot satisfy a specific accepted command |
| Minimal authority evaluator | Enforces exact read, write, model, and Command scope | Accepted security boundary | Small pure intersection | Essential Now | None; authority is foundational |
| General Capability broker | Selects among many implementations | No first-month need | Catalog, health, fallback, and context complexity | Deferred | Two real interchangeable implementations exist |
| Permission profiles | Prevent read/write/Command confusion | Accepted security requirement | Low data cost; approval design required | Essential Now | Add role profiles with Child Runs |
| Workspace isolation | Restricts paths and host scope | Accepted security boundary | Canonical path and policy work | Essential Now | Expand to multi-Project after one Project |
| Managed worktrees | Isolate mutation | Accepted future safety design | Git lifecycle and cleanup complexity | Important Next | Single selected checkout causes real conflicts or concurrent writers are accepted |
| One provider adapter | Produces real model-guided change | Required for useful product | Network, privacy, streaming, cancellation | Essential Now | Add second provider only after measured replacement need |
| Model router | Chooses provider | One provider first | General routing adds policy and fallback complexity | Deferred | Two accepted providers have measured trade-offs |
| Explicit Context package | Bounds model input and disclosure | Accepted Context principle | Moderate selection and provenance work | Essential Now | Expand retrieval only after observed misses |
| General Context compiler | Retrieves across many sources and phases | Detailed planning only | Opaque-framework and token risk | Rejected for Now | Benchmarks show explicit selection cannot meet a query class |
| Tool-schema selection | Prevents whole catalog loading | Alternatives already support many Tools | Low cost with fixed allowlist | Essential Now | Expand above four Tools only with measured need |
| Runtime Skills | Reusable procedures | Existing development Skills are not runtime | Hidden-prompt and authority risk | Deferred | A repeated procedure has stable inputs, outputs, tests, and value |
| Patch proposal and application | Completes actual coding work | Accepted future execution design | High mutation risk; exact Patch narrows it | Essential Now | AST operations only after exact Patch misses real workflows |
| Evidence | Supports truthful completion | Accepted central product value | Small structured records first | Essential Now | Add formats only with required checks |
| Deterministic verification | Tests accepted criteria | Core differentiation | Requires controlled Command | Essential Now | Independent model Verifier is adjacent |
| Independent Verifier Child | Separates author confidence from evaluation | Strong product hypothesis | Adds Child, Context, and role complexity | Important Next | Single-Run deterministic verification works |
| Artifacts | Retain Patch, output, and reports without Context bloat | Accepted boundary | Filesystem store and retention risk | Essential Now | Content addressing can expand after first retained types |
| Receipts | Bind completion Evidence and decisions | Accepted boundary | Small manifest; false-authority risk | Essential Now | Formal export only for immutable release subjects |
| Persistence | Supports objective continuity and recovery | Core product thesis | SQLite and migration work | Essential Now | Distributed storage is not justified |
| Journal | Supports replay, audit, and unknown effects | Concrete recovery requirement | Event design and migration cost | Essential Now | Reduce if implementation cannot show recovery value |
| General event sourcing | Models every subsystem as events | No requirement | High schema and projection complexity | Rejected for Now | None without a concrete recovery or synchronization need |
| Recovery | Differentiates work state from chat history | Accepted product thesis | Requires durable transitions and reconciliation | Essential Now | Expand to remote Workers only later |
| CLI | Lowest-cost complete interface | Repository already targets CLI | Small delivery surface | Essential Now | Remains permanent |
| TUI | Improves navigation and live observation | Detailed design; no dependency | Significant renderer and interaction cost | Deferred | Runtime is correct and at least two real Runs need navigation |

## Intelligence and retrieval

| Capability | User problem and value | Current Evidence | Cost and safety effect | Classification | Reconsideration trigger |
| --- | --- | --- | --- | --- | --- |
| Basic Repository search and read | Supplies current source | Required by model workflow | Low, deterministic | Essential Now | None |
| Tree-sitter | Adds structural ranges and symbols | Planned, no runtime | Grammar and extraction maintenance | Deferred | Text search causes measured context or accuracy failures |
| LSP | Adds definitions, references, diagnostics | Planned, no runtime | Server lifecycle and trust complexity | Deferred | A supported language workflow requires semantics unavailable from source and CLI |
| Persistent code index | Reduces repeated retrieval | No dogfood Evidence | Invalidation and storage cost | Deferred | Repeated queries show measurable latency or token waste |
| Local project intelligence | Reuses prior local patterns | Detailed planning only | High trust, licensing, and scope risk | Deferred | Core active-Repository workflow is stable and benchmarked |
| Cross-project Evidence | Can provide prior solutions | No current product need | Product-direction contamination risk | Deferred | Explicit approved-root user study shows material value |
| Embeddings | Fuzzy retrieval | No accepted missed query class | Privacy, dependency, opacity, and cost | Rejected for Now | Deterministic benchmark shows a material recall gap |
| Hosted retrieval | Remote semantic search | No need | Source egress and service dependency | Rejected for Now | Explicit user approval and local retrieval cannot satisfy a critical workflow |
| SCIP | Interchange persistent semantic index | No consumer or producer need | Adapter and freshness complexity | Research Track | A real index producer or consumer exists |

## Protocols, interfaces, and standards

| Capability | User problem and value | Evidence | Cost and risk | Classification | Reconsideration trigger |
| --- | --- | --- | --- | --- | --- |
| Native adapter boundary | Keeps core protocol-neutral | Accepted ADRs | Low and foundational | Essential Now | None |
| ACP | Allows external coding Client attachment | No initial workflow need | Reconnect and protocol mapping | Deferred | Stable native commands and events plus a real Client requirement |
| MCP client | Imports one selected external capability | No accepted capability | Catalog, prompt-injection, and egress risk | Research Track | A concrete capability is materially better through MCP than library, CLI, or API |
| MCP server | Exposes Kiln capabilities | No user need | Authentication and authority exposure | Rejected for Now | An identified host requires bounded read-only resources |
| OpenAPI | Imports one HTTP operation | No initial service need | Credential and schema trust | Deferred | One accepted service lacks a better library or SDK boundary |
| AG-UI | External Agent UI protocol | No near-term Client | Can dictate event semantics | Rejected for Now | Native event surface is stable and a real Client requires it |
| AHP | Experimental harness protocol | No product requirement | Architecture contamination risk | Research Track | Stable specification and concrete interoperability need |
| A2A | Remote independent Agent bridge | No local product need | Identity, trust, and recursive delegation risk | Rejected for Now | Remote ownership is a real accepted workflow |
| WASI and WIT | Portable bounded component boundary | No component need | Toolchain and sandbox-completeness risk | Research Track | One plugin benefits more than a supervised subprocess |
| In-toto and SLSA | Export release provenance | No immutable release subject in first target | Signing and claim risk | Deferred | Kiln produces a release Artifact with complete provenance |
| OpenTelemetry API | Operational observation | No stable runtime operations yet | Dependency and sensitive-data risk | Deferred | Durable operation names and privacy policy stabilize |
| OTLP export | External telemetry | No collector requirement | Network egress and operations cost | Rejected for Now | User operates an explicit local collector |

# 12. Minimum credible architecture

## First-month architecture

```text
CLI
  │
  ▼
Single-Run workflow application
  ├── pure domain and projection functions
  ├── explicit authority evaluator
  ├── explicit Context package builder
  ├── native Repository reader and exact Patch service
  ├── one provider adapter
  ├── one registered Command runner
  ├── Artifact, Evidence, and Receipt functions
  └── SQLite journal and current projections
          │
          └── transient model and Command Workers under one supervisor
```

## Component responsibilities

| Component | Problem | Smallest credible solution | Proposed Kiln solution now | Excluded expansion |
| --- | --- | --- | --- | --- |
| CLI | User must start, inspect, approve, cancel, verify, and resume work | Commands and structured output | Permanent CLI over one workflow application | TUI, ACP, web |
| Domain | Objective, desired work, and attempt must remain distinct | Plain structs and pure validation | Project subset, Session, Task, Run, Event | Full future entity catalog |
| Workflow application | One path must coordinate model and deterministic effects | Explicit functions with tagged results | One single-Run change-loop service | General workflow engine |
| Store | Work must survive restart | SQLite transactions and migrations | Bounded append journal plus current projections | Distributed log, ORM framework by default |
| Repository boundary | Source and mutation scope must be exact | Canonical paths, Git observations, file hashes | Native read, search, Patch, and state observation | MCP Repository access, broad VCS abstraction |
| Authority | Availability must not become permission | Pure intersection of policy and grant data | Fixed first-month profiles and approvals | General policy language or broker service |
| Context | Model input must be bounded and inspectable | Explicit selected items and manifest | Deterministic package for one provider invocation | Opaque retrieval framework |
| Model boundary | One real model is required | Provider behaviour plus fake implementation | One provider adapter and transient Worker | General router, ensemble, fallback |
| Patch service | Proposal must remain separate from effect | Exact base-bound Patch transaction | User-approved Patch apply with rollback reference | AST framework, writing Child |
| Command runner | Verification requires controlled execution | Registered executable and argv | One non-shell Project verification entry | Arbitrary shell, containers, remote execution |
| Artifact store | Large content must stay outside Context and journal | Kiln-owned files with metadata | Patch and Command-output types first | General object store and publication |
| Evidence and Receipt | Completion must be auditable | Structured observations and bounded manifest | Repository, Patch, Command, criterion, and user-decision Evidence | General attestation platform |
| Execution supervision | Live streams and processes must be cancelable | Dynamic transient Workers | Model and Command Workers only | Process per domain noun |

## Call direction

```text
CLI
→ Workflow application
→ pure domain validation
→ authority and Context selection
→ provider, Repository, Patch, or Command boundary
→ Artifact and Evidence creation
→ journal transaction and projection update
→ CLI result
```

Forbidden directions:

- provider output granting authority;
- model output directly mutating source;
- Repository or Command adapter changing Task criteria;
- Evidence functions executing Commands;
- Receipt functions accepting work;
- CLI state becoming domain authority;
- protocol types entering domain modules.

## Boundary summary

- **Execution boundary:** transient Workers own model streams and external processes.
- **Permission boundary:** pure effective-authority evaluation plus explicit user approvals.
- **Workspace boundary:** canonical approved root and selected active Repository.
- **Model boundary:** one sealed Context package and bounded Tool set per invocation.
- **Context boundary:** explicit items, reasons, digests, budgets, and exclusions.
- **Evidence boundary:** deterministic observations remain separate from Claims.
- **Artifact boundary:** large or sensitive retained content stays outside journal and ordinary Context.
- **Persistence boundary:** SQLite owns durable work facts; Git and filesystem own source truth.
- **External integration boundary:** provider and CLI adapters translate to Kiln-native requests and results.

# 13. Reconciled source layout

## Rule

Namespaces are earned by implemented responsibility. The Repository shall not pre-create the full roadmap.

The earlier plural directory map is superseded for first implementation planning.

## First-month namespaces

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
├── context/
│   └── package.ex
├── policy/
│   └── effective_authority.ex
├── execution/
│   ├── command.ex
│   └── command_worker.ex
├── artifacts.ex
├── evidence.ex
├── receipt.ex
└── cli.ex
```

This map defines responsibilities, not a requirement to create every file in the first ticket.

## Plain data and pure modules

The following remain structs, types, or pure functions:

- Project subset;
- Session;
- Task;
- Run;
- Event envelope;
- projections;
- policy and authority evaluation;
- Context selection and manifest construction;
- Patch validation;
- Evidence validation;
- Receipt construction.

## Runtime owners

Only model invocation and Command execution require explicit Kiln Worker modules in the first month.

The selected SQLite library can own its connection processes.

## Deferred namespaces

Do not create these until an accepted slice requires them:

- `tui/`;
- `attention/`;
- `delegation/`;
- `capability/` broker catalog;
- `skills/`;
- `code_intelligence/`;
- `knowledge/`;
- `protocols/`;
- `telemetry/`;
- `worktrees/`;
- `containers/`;
- `attestations/`.

# 14. Protocol and integration policy

Kiln chooses the smallest boundary that preserves correct semantics, cancellation, security, Evidence, testing, and replacement.

| Boundary | Use when | Avoid when |
| --- | --- | --- |
| Direct function | Kiln owns deterministic logic and no replacement boundary exists | Side effects or independent lifecycle are hidden |
| Library | Mature implementation can run safely in process | It requires unsafe native code, broad global state, or hidden network behavior without controls |
| CLI | A mature Project tool already defines the operation and structured or bounded output is available | Shell parsing, cleanup, or semantics cannot be controlled |
| Direct API or SDK | One stable remote service is required | Dynamic discovery adds no value or egress cannot be bounded |
| Local service or socket | Separate lifecycle, sharing, or fault isolation has material value | It only wraps a library or CLI with more failure modes |
| Dedicated adapter | Kiln must normalize a provider, protocol, or tool into native requests and results | The adapter invents a second domain model |
| Protocol client | A real external implementation already exists and interoperability is required | Native, library, CLI, or direct API is simpler and safer |
| Protocol server | Another accepted host requires bounded Kiln resources | It is added for discoverability without a consumer |
| MCP | Dynamic capability discovery or replacement creates measured value and all operations remain behind Kiln policy | A library, CLI, API, or narrow adapter already solves the workflow |

Foundational now:

- native Kiln contracts;
- provider adapter;
- native Repository boundary;
- registered CLI Command boundary.

Optional later:

- ACP;
- one MCP client capability;
- one OpenAPI capability;
- Dev Container or OCI Environment.

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
- active Patch proposal summary when revising;
- current failures, Evidence, assumptions, and unknowns;
- no more than four Tool schemas;
- explicit output contract and limits.

## Excluded by default

- complete conversation history;
- complete Repository files when ranges suffice;
- the complete Tool or Capability catalog;
- all Skills and prompt bodies;
- unrelated Project files;
- reference repositories;
- raw logs and reports;
- secrets and denied paths;
- stale or superseded criteria;
- hidden author-confidence narrative for verification.

## Tool loading

The first-month Tool set is fixed by workflow step.

Unused Tool schemas are absent. A model cannot request a catalog dump.

Adding a Tool requires an accepted need, authority profile, input and output contract, size limit, failure contract, and deterministic test.

## Skills

Runtime Skills are deferred.

When introduced:

- metadata can be discoverable;
- the body loads only after explicit selection;
- the Skill cannot grant authority or create a Run;
- large Skill bodies must be split into bounded references;
- selection and loaded digest must be inspectable.

## Large results

Large outputs become Artifacts. Context receives a bounded excerpt, digest, completeness state, and continuation method.

## Durable versus active information

Durable:

- objective and criteria revisions;
- selected item references and digests;
- Context manifest and package digest;
- Tool names and request digests;
- model result Artifact reference;
- Claims, Evidence, warnings, and unknowns.

Active only by default:

- provider-specific rendered prompt;
- transient stream buffers;
- hidden model reasoning;
- duplicated full source content already recoverable from an exact Repository state.

## Inspectability

Every Context item must state:

- source;
- authority and trust;
- sensitivity;
- state binding and freshness;
- selection reason;
- transformation;
- token estimate;
- disclosure decision when remote.

# 16. Local-first and security boundaries

## Local by default

The following remain local:

- objective, criteria, Run state, journal, projections, Artifacts, Evidence, and Receipts;
- Git and filesystem observations;
- Patch application;
- Command execution;
- policy and approval records.

Only the sealed provider Context package and required provider metadata may leave the machine during model invocation.

## Explicit approval

The user must explicitly approve:

- the exact Patch digest before source mutation;
- any source excerpt class not already allowed by Project disclosure policy;
- any network destination beyond the configured provider;
- any future broader Command, worktree cleanup, publication, or external export.

## Source protection

- canonical approved root;
- path normalization before every operation;
- deny symlink escape and special files by default;
- bounded reads;
- exact base hashes before Patch;
- one mutation owner;
- no model shell;
- no automatic dependency installation;
- no automatic commit, push, merge, or publish.

## Secret protection

- do not inherit the complete user environment;
- use opaque secret references;
- deny common secret files and configured paths;
- screen selected excerpts before provider disclosure;
- do not write secret values to journal, logs, telemetry, Receipt, or normal Artifact metadata.

## Reference repositories

Reference repositories are disabled through version 0.1.

When later enabled, they remain read-only Evidence sources with `instruction_authority: none`, no Command authority, no model authority, and separate approved roots.

## Prompt injection

Instructions found in source, comments, documentation, generated files, issues, prompts, or reference repositories are untrusted data unless they are part of the accepted active Project instruction set.

Prompt text alone is not an enforcement mechanism. Path, Tool, permission, disclosure, and mutation boundaries must be deterministic.

## Delegation

A Child receives a new Context package and explicit narrower grants. It receives no ambient Parent transcript, Tools, secrets, write scope, or provider cache.

No Child can grant itself or another Run authority.

## Concurrent writes

The first month has one Root Run and one selected writable checkout.

No concurrent writer exists.

Managed worktrees enter only when a later accepted workflow requires independent mutation.

# 17. Evidence and completion model

## Evidence

Evidence is one structured observation bound to:

- a subject;
- a method;
- exact Repository and Environment state when applicable;
- time or sequence;
- freshness and completeness;
- source Artifact or Command.

First-month Evidence types are limited to:

- Repository state observation;
- source content observation;
- Patch proposal and application observation;
- Command execution result;
- criterion result;
- user approval or acceptance decision.

## What is not Evidence

- model confidence;
- a persuasive summary;
- a proposed Patch;
- exit zero without criterion interpretation;
- a Receipt without underlying Evidence;
- a passing unrelated test;
- an old result against changed source;
- absence of an observed error.

## Artifact

An Artifact is immutable stored content or a durable external reference.

Initial Artifact kinds:

- model result;
- Patch proposal;
- rollback data;
- Command stdout and stderr;
- structured test report when present;
- completion summary attachment.

Artifact existence does not make content authoritative or model-visible.

## Receipt

A Receipt is a sealed manifest that references:

- Session, Task, and Run;
- objective and criteria revisions;
- Repository base and result state;
- Context package digest;
- provider and model when relevant;
- authority and approval references;
- Patch proposal and application;
- Command request and result;
- Evidence by criterion;
- warnings, unknowns, exclusions;
- user acceptance;
- timestamps and manifest digest.

A Receipt cannot grant authority, change a result, make Evidence current, or accept work.

## Verification

Verification evaluates accepted criteria through deterministic observation or registered Commands against exact current state.

The first-month Root Run can use deterministic verification directly. A separate Verifier Child is Important Next.

## Completion

A Task can complete only when:

- all required criteria pass with current Evidence;
- the accepted change is the observed Repository state;
- no required Command is blocked or orphaned;
- no unknown effect remains;
- the user accepts the result.

## Failed and contradictory checks

Store every material result. Do not collapse contradiction into one optimistic status.

Required criteria with any unresolved `FAIL`, `BLOCKED`, stale result, or contradiction block completion.

## Retention

Retain through the active Session:

- journal events;
- current projections;
- Patch and rollback Artifacts;
- required Command results;
- criterion Evidence;
- final Receipt.

Exact raw-output, abandoned-proposal, historical Context, and long-term Artifact retention requires a focused planning decision.

# 18. Delivery targets

## First-month target — Single-Run Change Alpha

### User-visible outcome

```text
kiln opens one local Repository
→ records one objective and criteria
→ starts one Root Run
→ one model investigates through bounded reads
→ model proposes one exact Patch
→ user approves the Patch digest
→ Kiln applies the Patch
→ Kiln runs one registered verification Command
→ failed Evidence blocks completion
→ passing current Evidence permits user acceptance
→ restart restores the completed or blocked work record
```

### Included

- one active Repository;
- one Session, Task, and Root Run;
- CLI;
- minimal SQLite journal and projection;
- one provider plus fake provider;
- explicit Context package;
- four or fewer Tools;
- native read and search;
- exact Patch proposal and application;
- explicit approval;
- one registered Command;
- minimal Artifacts, Evidence, Receipt, and restart.

### Excluded

- Child Runs;
- TUI;
- background concurrency and Attention;
- managed worktrees;
- general Capability broker;
- Skills;
- LSP, Tree-sitter, or persistent code index;
- protocols;
- local project intelligence;
- telemetry;
- remote execution.

### Planning dependencies

Prompt 4 must identify focused planning for:

- SQLite journal and migration boundary;
- Patch transaction and selected-checkout policy;
- provider, Context, and disclosure boundary;
- Command process-tree and primary-platform boundary;
- Evidence retention.

### Acceptance criteria

- restart restores objective, Task, Root Run, current state, Evidence, and decisions;
- only approved paths enter model Context;
- model cannot mutate source directly;
- Patch applies only to exact base state after explicit approval;
- failed or blocked verification prevents completion;
- current passing Evidence plus user acceptance completes the Task;
- no process or static domain noun is created without ownership justification.

## Twelve-week target — Trustworthy Delegated CLI

### Product outcome

The developer can complete the single-Run change loop, delegate one bounded read-only Scout, run one independent Verifier Child, observe one background Child and its Attention state from the CLI, cancel it, restart Kiln, and return to current durable state.

### Added after first month

- interruption and unknown-effect recovery hardening;
- one depth-one read-only Scout Child;
- one active Child at a time;
- bounded result delivery;
- global Root-visible Attention for Child blockers;
- independent Verifier Child with separate Context and grants;
- CLI Run listing, inspect, enter, and return-to-Root actions.

### Still deferred

- TUI;
- nested Children;
- more than one active Child;
- writing Children;
- managed worktrees;
- code intelligence;
- runtime Skills;
- protocol adapters;
- local project intelligence;
- embeddings;
- telemetry export;
- remote execution;
- publication and attestations.

### Operational limits

- one local active Project and Repository;
- one active Session per CLI process;
- one Root Run;
- maximum Child depth one;
- maximum one active Child;
- one provider;
- one primary operating-system support target for process-tree guarantees;
- no general shell;
- no automatic network destinations beyond the provider.

### Completion Evidence

- aggregate deterministic test gate;
- restart and orphan fixtures;
- Patch and Command safety fixtures;
- Scout no-write proof;
- Verifier `PASS`, `FAIL`, and `BLOCKED` fixtures;
- exact final Repository state;
- one aggregate version 0.1 Receipt.

# 19. Three largest delivery risks

| Risk | Cause | Probability | Impact | Earliest warning | Mitigation | Scope reduction |
| --- | --- | --- | --- | --- | --- | --- |
| Architecture and planning scope expands faster than product proof | Detailed future documents and Schemas invite horizontal implementation | High | High | New subsystem directories, dependencies, or tickets appear before the first change loop | Enforce first-month exclusions and one accepted workflow per new boundary | Remove Child Runs, TUI, protocols, indexes, and generalized broker from the target |
| Safe Patch and Command execution exceeds one developer's platform budget | Filesystem edge cases, process trees, cancellation, rollback, and dirty state are difficult | Medium-high | High | Unknown process effects, partial rollback, or platform-specific failures appear in fixtures | Support one primary platform, one exact Patch form, one Command, no shell | Ship proposal plus verification without application until safety gate passes, rather than weaken controls |
| Provider and Context boundary leaks source or becomes nondeterministic | Remote disclosure, token limits, retries, and model behavior vary | Medium | High | Context packages cannot be reproduced, secret canaries escape, or live tests gate CI | One provider, fake deterministic CI, explicit package manifest, source-screening and disclosure policy | Keep live provider path optional until deterministic local workflow passes |

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

- single-Run change loop before Child Run graph;
- CLI before TUI;
- one real source change in version 0.1;
- SQLite journal in the first implementation slice because recovery is core;
- Root Task is not a separate initial concept;
- Child depth one and one active Child through version 0.1;
- direct deterministic verification in the Root Run before an independent Verifier Child;
- one selected writable checkout before managed worktrees;
- fixed Tool set and authority evaluator before a general Capability broker;
- TUI, code intelligence, protocols, Skills, and local project intelligence after the twelve-week target.

## Rejected for now

- simulated TUI as the first useful milestone;
- read-only version 0.1 after twelve weeks;
- nested delegation in version 0.1;
- three concurrent Children before dogfooding;
- a process for every active Run;
- a general routing, retrieval, broker, event, or Evidence framework before one workflow;
- mandatory worktrees for harmless reads or one sequential writer;
- protocol implementation for coverage;
- embeddings or hosted retrieval.

## Proposed supersessions after owner acceptance

- ADR 0019's implementation order, while retaining its vertical-slice and protocol-neutral principles;
- P1-S01 through P1-S05 as the current read-only sequence;
- the first twelve-week read-only Durable Operator Kernel boundary;
- the near-term depth-two and three-active-Child limits;
- the first-slice TUI and ExRatatui requirement;
- broad initial source-directory guidance.

Historical rationale remains preserved in Git and the earlier documents.

# 21. Existing implementation and scaffolding affected

Prompt 3 must examine:

- the empty OTP application shell against the minimum process list;
- `scripts/agent-preflight` and its P1 ticket incompatibility;
- the implementation-plan template and slice-ticket grammar;
- `scripts/check`, CI, and agent-asset validation;
- development Skills and prompts that assume the older work-package flow;
- specialist-agent definitions that can be confused with runtime Child roles;
- the broad source-layout guide;
- ExRatatui planning and any implied first-slice dependency;
- all JSON Schemas against the reduced first-month contract subset;
- future `scripts/gates/*` names against the revised slice sequence;
- ADR and document status labels;
- historical files that still describe documentation as implemented capability.

Prompt 3 should not repair these items until it records retain, narrow, replace, remove, or defer dispositions against this target.

# 22. Remaining planning-domain assessment

| Domain | Assessment | Reason |
| --- | --- | --- |
| Product definition and non-goals | Resolved by Prompt 2, pending owner acceptance | Canonical target is explicit |
| Minimum Run, Session, Task, and Child scope | Resolved by Prompt 2, pending acceptance | Enough for implementation and later delegation |
| Exact lifecycle transition table | Dedicated planning round | Persistence and recovery correctness depend on it |
| SQLite journal, projections, migrations, and transaction boundaries | Dedicated planning round | Foundational durable state and schema decisions remain |
| Patch format, checkout policy, rollback, and dirty-state conflicts | Dedicated planning round | Mutation safety cannot be invented during coding |
| Command registration, process-tree control, cancellation, and primary platform | Dedicated planning round | High-risk execution boundary |
| Provider, Context package, disclosure, and secret screening | Dedicated planning round or one combined model-boundary round | Remote egress and token efficiency are coupled |
| Evidence, Receipt, and retention | Belongs with journal and execution planning, with retention called out | First types are resolved; storage and lifecycle are not |
| CLI syntax and interaction | Can be decided during bounded implementation within accepted actions | No foundational product choice remains |
| Child permission derivation and Attention | Dedicated round before Child slice | Concurrency and authority enter later |
| TUI and ExRatatui | Deferred until runtime enters its blast radius | Not in twelve-week target |
| Runtime Skills | Deferred | No repeated runtime procedure exists |
| Code intelligence | Deferred until its slice | Not required for initial read/search workflow |
| Local project intelligence and prompt-injection corpus | Deferred until after active code intelligence | High trust and scope cost |
| Protocol adapters | Optional research when a concrete consumer or capability exists | Protocols do not define core |
| Telemetry | Deferred until stable operations exist | Not state or Evidence |
| Packaging and release | Can be planned near version 0.1 integration | No current release Artifact |
| Final Planning Round Register | Prompt 4 | This pass supplies inputs only |

# 23. Required architecture challenges

| Risk | Current Evidence | Present? | Correction | Consequence |
| --- | --- | --- | --- | --- |
| Protocol support becomes product | Ten planned slices include an expansion evaluation and many protocol docs | Partial | Remove protocol coverage from near-term outcome | Protocols require concrete workflow entry gates |
| Run graph becomes orchestration theater | Current first slice is simulated graph and TUI | Yes | Single Root Run first; one Child only after value | No child or graph code in first month |
| TUI precedes runtime correctness | Current P1-S01 requires TUI before provider or persistence | Yes | CLI-first; TUI after twelve weeks | ExRatatui no longer early dependency |
| OTP processes for static concepts | Run Model shows active process per Run | Yes | Process only live Workers and Resources | Remove RunSupervisor architecture |
| Event sourcing without recovery | Journal is planned for recovery but broad event use is possible | Partial | Bound journal to recovery, audit, replay, and effects | No event for every token or static concept |
| MCP used instead of simpler boundary | Existing hierarchy already prefers earlier options | Not currently | Preserve and strengthen entry gate | No MCP in near-term roadmap |
| Context compiler becomes opaque retrieval | Full compiler plan spans many sources and rankings | Yes as future risk | Explicit first-month package and fixed sources | General retrieval deferred |
| Tool catalog consumes Context | Planned broker catalog is large | Yes as future risk | Maximum four first-month Tools; catalog absent | New Tool requires workflow evidence |
| Skills become hidden prompts | Skill system is detailed before runtime need | Yes as future risk | Defer Skills; lazy bounded load later | No runtime Skill loader now |
| Local intelligence becomes vector project | Detailed index planning exists | Yes as scope risk | Defer; reject embeddings and graph database | No knowledge subsystem in twelve weeks |
| Cross-project Evidence contaminates direction | Reference retrieval is planned | Yes as safety risk | Disable reference roots through version 0.1 | Later content remains inert Evidence |
| Reference repositories are modified | Security docs prohibit it | No accepted path, but high consequence | Preserve no-write and separate execution authorization | No reference execution in roadmap |
| Permissions expand through delegation | Current docs prohibit ambient inheritance | Risk remains | Child intersection can only narrow; no Child-created descendants | Deterministic tests required before Child slice |
| Durable state duplicates conversation | Current architecture separates journal and transcript | Partial risk | Persist work facts and references, not chat as authority | Recovery uses state, not transcript summary |
| Worktrees required for trivial work | Current execution hierarchy says harmless reads need none | Partial future risk | One selected checkout first; managed worktree later | No worktree provisioner first month |
| External protocols dictate architecture | Accepted ADRs prohibit it | No, if enforced | Native requests and results remain core | Adapter-specific types forbidden in domain |
| Elixir justifies unnecessary concurrency | Current plans include several supervisors early | Yes | Four justified runtime owners at most in first month | Pure functions and library-owned processes preferred |
| System too large for one developer | Planning covers providers, TUI, broker, indexes, protocols, containers, telemetry, attestations | Yes | Narrow first month and twelve weeks | Expansion work moves outside version 0.1 |

# 24. Build blockers

Prompt 3 can proceed after this pass is reviewed, accepted, integrated, and validated.

Broad implementation remains blocked by:

- Prompt 3 implementation and scaffold disposition;
- Prompt 4 planning-round sequencing;
- required focused planning rounds for journal, Patch, Command, provider and Context, and recovery;
- Prompt 6 justified conformance work;
- final independent adversarial review;
- adjudication and build authorization;
- current preflight incompatibility with P1 ticket branches;
- no accepted P1-S01-T01 plan under the revised roadmap.

# 25. Authoritative information movement

This pass shall move or summarize durable information as follows:

- README summarizes the reconciled product and targets.
- Architecture summarizes minimum components, process ownership, and boundaries.
- Roadmap owns the revised slice order.
- Implementation Slices owns detailed slice behavior.
- Slice Acceptance Gates owns future aggregate proof.
- Run Model owns the minimal Run and later Child model.
- Project Provenance retains rationale without stale hierarchy.
- Agent-Friendly Codebase owns earned source-layout guidance.
- ADR 0020 records the proposed change-loop-first decision and proposed partial supersession of ADR 0019.

No historical rationale is removed from Git history.

# 26. Prompt 2 completion gate

Prompt 2 passes when:

- canonical documents use one product definition;
- non-goals constrain implementation;
- the first useful version completes one real change;
- the Run model serves work rather than Agent management;
- process-per-active-Run is removed;
- every near-term process has live ownership justification;
- event journaling is tied to concrete recovery and audit requirements;
- protocols remain adapters;
- source-layout guidance matches the minimum target;
- Context and Tool limits are explicit;
- local-first and security invariants are explicit;
- Evidence and completion are defined;
- first-month and twelve-week targets are credible for one developer;
- Prompt 3 inputs and remaining planning domains are explicit;
- Repository validation passes;
- build authorization remains denied.

# 27. Exact next action

After P0-W18 is reviewed, accepted, and integrated, run **Prompt 3 — Reconcile scaffolded, partial, and completed-looking implementation** against current `main`.

Do not begin Prompt 4 or implementation before Prompt 3 completes its gate.
