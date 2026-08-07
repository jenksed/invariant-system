# P1-S02 Planning Baseline

**Document type:** Slice-planning baseline  
**Status:** Proposed; planning only  
**Target slice:** P1-S02 — Evidence-backed Single-Run Change Alpha plus QC0/QC1  
**Implementation authorization:** Not granted  
**Entry gate:** accepted P1-S01-T05 aggregate gate, demo, P1-S01-V01, owner-machine Evidence, and explicit subsequent authorization

## Purpose

Begin decomposition of the next major Kiln body of work after the durable P1-S01 foundation without converting roadmap intent into premature implementation authority.

P1-S02 is the first complete useful change loop. It must connect model-assisted investigation to controlled mutation and evidence-backed completion while introducing QC0 and QC1 through that same workflow.

The planning problem is therefore not "which subsystems should we build next?" The planning problem is "what sequence of bounded, independently coherent vertical increments can reach the accepted Single-Run Alpha while preserving Kiln's authority, failure, and Evidence boundaries at every intermediate state?"

## Starting point

P1-S01 is establishing durable identity, journal truth, replay, projections, restart reconstruction, Workflow authority, and a foundation CLI. T05 remains responsible for proving that foundation as an integrated slice.

P1-S02 may rely on the durable boundaries P1-S01 proves. It must not assume more than T05 actually demonstrates.

Before P1-S02 authorization, the planning pass must consume at least:

- exact P1-S01-V01;
- aggregate gate output;
- restart demo Evidence;
- owner-machine SQLite, filesystem, WAL, migration, and restart Evidence;
- final P1-S01 exclusions and warnings;
- any observed operation-recovery or host-specific limitations;
- the exact accepted integrated P1-S01 commit.

If that Evidence changes a durability, cancellation, external-operation, or state-binding assumption below, this baseline must be revised before authorization.

## Accepted slice outcome that planning must preserve

A developer can:

1. open one approved local Repository;
2. record an objective, criteria, and requested Assurance;
3. let MiniMax M3 investigate through bounded Repository reads and exact search;
4. inspect one exact complete-text Patch proposal;
5. approve the exact Patch digest;
6. apply the Patch through one mutation owner;
7. re-observe exact Repository state;
8. compile the required Evidence Plan;
9. run registered Kiln-owned Gates;
10. preserve raw outputs and inspect normalized Findings;
11. repair through a bounded recapture cycle when necessary;
12. inspect criterion-bound Evidence and aggregate readiness;
13. explicitly accept completion;
14. atomically complete the durable work state;
15. seal a post-completion product Receipt;
16. restart Kiln and recover the complete record.

QC0 and QC1 are demonstrated inside this workflow. They are not separate framework milestones detached from the user-visible change path.

## Architectural thesis

### 1. Kiln owns authority; integrations contribute information

The model, provider adapter, Development Pack, analyzer, and parser can propose, describe, detect, classify, or interpret. Kiln owns:

- approved Repository boundary;
- disclosure policy;
- Context construction;
- Tool exposure;
- Patch Approval and mutation authority;
- registered Command definitions;
- process execution policy;
- Environment and secret policy;
- Gate execution;
- Assurance requirements;
- Evidence sufficiency;
- aggregate decision;
- user acceptance;
- durable completion.

This is both a product differentiator and a security boundary.

### 2. External work receives explicit lifecycle ownership

Provider invocations, registered Commands, and external Development Packs are live resources with cancellation, timing, output, crash, and cleanup concerns. Their runtime ownership should be explicit.

Quality Subject, Gate definition, Finding, Assurance Plan, Evidence, Artifact metadata, Patch metadata, and Receipt remain data unless a real runtime lifecycle requires otherwise.

### 3. The first implementation of every nondeterministic boundary should have a deterministic counterpart

The fake provider and fake Pack are not test conveniences added later. They are contract-definition tools that make the durable workflow, cancellation semantics, output normalization, and failure matrix provable before live integrations are trusted.

Likewise, registered deterministic Commands and fixtures should prove execution and Evidence semantics before language-specific Pack intelligence is relied upon.

### 4. Exact state binding is the spine

Repository reads, Context, Patch proposal, Approval, application, Gate execution, Findings, criterion Evidence, aggregate decisions, completion, and Receipt references must remain bound to the exact relevant Repository and durable work state.

A stale or uncertain transition is not a degraded pass. It is blocked, stale, contradicted, failed, or unknown according to the accepted contract.

### 5. QC1 must preserve a migration path to QC4 without freezing QC4

P1-S02 needs an external Pack process boundary because QC1 must prove a real `kiln-elixir` Pack and a deterministic fake Pack. It does not need to declare that boundary a stable public multi-language SDK.

The QC1 protocol should be:

- narrow;
- versioned internally;
- supervised;
- fixture-driven;
- replaceable;
- explicit about unsupported fields;
- free of Elixir-specific assumptions in the Kiln core where practical;
- allowed to change before QC4 portability proof.

Compatibility obligation increases only after other producers depend on the contract.

## Accepted dependency spine

Planning must preserve this order from the roadmap:

```text
Artifact and registered Command substrate
→ Pack protocol and deterministic fake Pack
→ Quality Compilation plan and Gate execution
→ Findings, fingerprints, baselines, and Assurance
→ Elixir Pack
→ first dogfooded source change
→ criterion and Evidence consolidation
→ aggregate Single-Run Alpha proof and delivery
```

Repository investigation, provider, Patch, mutation, CLI, recovery, and completion work must be woven into that spine rather than appended as an unrelated second architecture.

## Proposed vertical ticket cuts

These cuts are planning candidates, not authorized tickets. The final authorization pass may merge, split, rename, or reorder them while preserving the accepted dependency spine.

### Candidate A — Registered evidence substrate

**User-visible increment:** A developer can run one approved deterministic Repository verification action through Kiln and inspect an exact-state result with preserved raw output.

**Likely responsibilities:**

- minimal immutable Artifact storage needed by Command results;
- registered non-shell Command definition;
- fixed executable and argv policy;
- bounded Environment, cwd, timeout, and output policy;
- external Command lifecycle ownership;
- terminal result plus unknown-cleanup classification;
- exact Repository/Subject binding;
- deterministic fake/fixture execution path;
- CLI inspection surface for the result.

**Must not include:** Pack intelligence, provider calls, source mutation, criterion completion, user acceptance, or a generic shell.

**Failure mode answered:** Without a controlled execution substrate, later verification can become arbitrary shell activity whose environment, effect, cleanup, and Evidence cannot be reconstructed.

### Candidate B — Pack-planned deterministic verification

**User-visible increment:** Kiln can ask a deterministic fake Pack what applies to a fixture Repository, execute the resulting registered Gate itself, preserve raw output, and parse a normalized observation without giving the Pack execution authority.

**Likely responsibilities:**

- supervised external Pack lifecycle;
- narrow versioned QC1 protocol subset;
- deterministic fake Pack and conformance fixtures;
- detect, plan, and parse responsibilities;
- explicit Pack capability metadata;
- Kiln validation of every proposed Gate against registered Commands;
- malformed, crashed, canceled, truncated, and unsupported Pack behavior;
- raw Artifact linkage behind parsed output.

**Must not include:** public Pack SDK promises, dependency installation, arbitrary executables, Pack-owned mutation, Pack-owned acceptance, or Elixir-specific production behavior.

**Failure mode answered:** Without this boundary, language intelligence can quietly become an execution and policy authority that Kiln cannot independently constrain or replace.

### Candidate C — Assurance, Evidence Plan, and deterministic Findings

**User-visible increment:** A developer can request an Assurance level, inspect the required Evidence Plan, execute selected Gates, and see normalized Findings and an aggregate result that preserves blocked, unknown, stale, contradicted, and failed states.

**Likely responsibilities:**

- Quality Subject and Verification Obligation subset;
- requested, required, and achieved Assurance;
- risk and policy escalation hooks needed by the Alpha;
- resource-budget distinction and explicit waiver shape;
- inspectable Evidence Plan;
- deterministic Gate graph/execution ordering;
- Observation and Guarantee classes;
- normalized Finding identity and raw Artifact references;
- initial exact/structural/candidate/no-match fingerprint classifications;
- audit, ratchet, and strict mode minimums;
- baseline semantics required by the Alpha;
- deterministic aggregate Decision.

**Planning caution:** Persist only concepts whose durability is necessary for restart, auditability, or completion. Derive values that can be reproduced cheaply from durable inputs.

**Failure mode answered:** Without explicit Assurance and Evidence planning, successful tools can be mistaken for sufficient verification and weak proof can silently masquerade as strong proof.

### Candidate D — Bounded Repository investigation and Patch proposal

**User-visible increment:** A deterministic fake provider can investigate an approved Repository through the final bounded Tool surface and produce one exact Patch proposal without write authority.

**Likely responsibilities:**

- approved Repository read boundary;
- path normalization, symlink escape, special-file, size, encoding, and secret controls;
- exact search;
- Artifact-backed large read results;
- disclosure classification;
- sealed Context compiler;
- no more than four phase-specific model-facing Tools;
- deterministic fake provider contract;
- provider invocation lifecycle and transcript separation;
- exact complete-text Patch representation bound to base hashes;
- proposal validation and CLI inspection.

**Must not include:** direct model mutation, fuzzy Patch application, ambient filesystem access, complete Repository dump, or unrestricted Tool catalogs.

**Failure mode answered:** Without a compiled disclosure and Tool boundary, model investigation can become ambient Repository access and accumulated transcript state can become an implicit authority surface.

### Candidate E — Approved mutation, recapture, and recovery

**User-visible increment:** A developer can approve one exact Patch, apply it through a single mutation owner, recover from bounded failure classes, re-observe Repository state, and rerun the current Evidence Plan.

**Likely responsibilities:**

- exact user Approval bound to Patch digest and base state;
- selected deterministic application primitive;
- one mutation owner;
- dirty-overlap rejection;
- path and symlink revalidation at mutation time;
- rollback information;
- intent-before-effect durable operation record;
- target observation after effect;
- explicit success, failure, canceled, orphaned, and unknown-effect handling;
- re-observation and Evidence invalidation;
- coherent one-repair-cycle behavior;
- CLI actions for approval, application, retry/recovery decisions where accepted.

**Must not include:** managed worktrees, automatic commit/push/merge, repeated blind retries, or model self-approval.

**Failure mode answered:** Without exact Approval, mutation ownership, and post-effect recapture, Kiln cannot distinguish an intended change from an uncertain filesystem effect or prove that later verification applies to the accepted Patch.

### Candidate F — Real provider and Elixir QC1 dogfood

**User-visible increment:** MiniMax M3 can perform the bounded investigation/proposal role, and `kiln-elixir` can verify one real Kiln change through the accepted QC1 boundary.

**Likely responsibilities:**

- real MiniMax M3 adapter after deterministic contract proof;
- request, streaming, cancellation, usage, timeout, and error normalization;
- explicit live-network smoke proof separated from deterministic CI;
- `kiln-elixir` detection and planning;
- format, compile, test, xref, and Repository aggregate Gate definitions as applicable;
- Elixir parser/normalizer behavior with raw Artifact preservation;
- one deliberately bounded real Kiln source change;
- Finding recapture after repair;
- achieved-Assurance calculation against the real change.

**Planning caution:** Do not make `kiln-elixir` a privileged in-process exception merely because Kiln is written in Elixir. The reference Pack should exercise the same authority separation intended for later language Packs.

**Failure mode answered:** Without dogfooding the real provider and real language Pack through the generic boundaries, QC1 could pass only against artificial fixtures while hiding core assumptions that do not survive a real Repository.

### Candidate G — Criterion Evidence, completion, Receipt, and delivery

**User-visible increment:** The developer can see current criterion-to-Evidence coverage, explicitly accept a ready aggregate, complete the durable work atomically, inspect a product Receipt, restart, and use the supported local delivery.

**Likely responsibilities:**

- criterion-to-Evidence consolidation;
- freshness, completeness, Guarantee, limitation, contradiction, and subject binding;
- aggregate readiness rules;
- explicit user acceptance;
- P0-W21 atomic Run/Task/Session completion;
- post-completion product Receipt assembly and digest;
- complete CLI actions needed by the Single-Run Alpha;
- restart reconstruction of the completed change record;
- arm64 macOS local packaging and installation;
- aggregate P1-S02 gate, demo, owner-machine Evidence, and verification manifest/closeout artifact as accepted by the later plan.

**Must not include:** Child Runs, QC2 independent falsification, TUI, public Pack SDK, remote execution, or deployment.

**Failure mode answered:** Without criterion-bound current Evidence and explicit acceptance, the system can confuse successful activity with completed work and cannot defensibly reconstruct why completion was allowed.

## Candidate sequencing questions

The A→G ordering above is a planning default, not a decision. The focused planning pass should test at least these alternatives:

1. Whether bounded Repository reads should enter earlier in Candidate A so every Command/Pack result has a richer common Subject observation, or remain isolated until model investigation needs source disclosure.
2. Whether Assurance and Findings should be split into two tickets to keep each merge small without creating a horizontal framework seam.
3. Whether provider integration belongs with Patch proposal or with Elixir dogfood; the deterministic fake provider must precede either choice.
4. Whether mutation should land before Finding baselines so recapture behavior shapes identity rules from the beginning.
5. Whether packaging can remain entirely final-ticket work or needs an earlier thin executable path to make owner-machine Command/process evidence realistic.
6. Which CLI actions must appear in each increment so every ticket has an inspectable user workflow rather than hidden subsystem progress.

## Planning decision register

The later authorization package should resolve or explicitly defer these decisions.

### D01 — Artifact durability and content-addressing

Decide the minimum Artifact metadata, storage layout, digest behavior, retention assumptions, and journal references required for raw Command/provider/Pack output.

Avoid building a generalized object store unless the Alpha failure modes require it.

### D02 — Command process ownership on macOS

Prove the process-tree termination strategy, timeout behavior, descendant cleanup observation, output-limit behavior, and classification when cleanup cannot be proven.

This is a high-rigor decision because external execution has meaningful blast radius.

### D03 — Pack transport and lifecycle

Choose the smallest transport that preserves message framing, versioning, cancellation, crash isolation, bounded output, deterministic fixtures, and replacement.

The transport should remain an internal QC1 seam, not a prematurely public ecosystem contract.

### D04 — Quality persistence boundary

For Subject, Obligation, Plan, Gate result, Finding, Finding Occurrence, Derived Fact, Assurance, and aggregate Decision, classify each as:

- durable event/fact;
- durable Artifact content;
- rebuildable projection;
- derived current value;
- deferred concept.

Every persisted concept must answer a restart, audit, idempotency, or completion failure mode.

### D05 — Finding identity and baseline semantics

Define stable Finding identity without pretending semantic matching is always certain. Ambiguous matches must remain ambiguous rather than being silently merged.

Baselines must represent explicit accepted debt, not wildcard suppression or count-based quality theater.

### D06 — Context and Tool contract

Select the final first-month four-Tool maximum and phase-specific exposure rules. Define item metadata for source, authority, trust, sensitivity, state binding, freshness, selection reason, transformation, token estimate, and disclosure.

### D07 — Patch application primitive

Evaluate available exact application mechanisms against:

- base-hash enforcement;
- complete-text replacement semantics;
- path safety;
- symlink behavior;
- binary/special-file rejection;
- dirty overlap;
- atomicity boundaries;
- rollback material;
- interruption;
- uncertain target observation.

Do not select a mechanism because it is familiar if it weakens Kiln's mutation contract.

### D08 — MiniMax adapter contract

Verify current official request, streaming, cancellation, token/usage, error, timeout, and credential behavior before freezing the provider boundary.

Keep provider-specific objects outside core domain modules.

### D09 — Assurance escalation and waivers

Specify how requested Assurance becomes required Assurance through Project minimums, risk, criterion requirements, and Pack mandatory conditions.

Define what a resource shortfall can do. It may block, narrow, or require explicit waiver; it cannot silently lower the claimed Assurance.

### D10 — Completion and Receipt boundary

Specify exactly what is required before the atomic completion transition and exactly what the post-completion Receipt may reference.

The Receipt must remain non-authoritative.

## Focused evidence-gathering work that can begin before authorization

Read-only research can accelerate the later plan without making architecture commitments. Useful investigations include:

- current MiniMax request, streaming, cancellation, usage, and error interfaces;
- macOS process-group and process-tree termination behavior from Elixir/Ports and available helper primitives;
- exact Patch-application mechanisms and their failure/rollback properties;
- current Repository read, ignore, symlink, encoding, and path behavior already present in Kiln or its dependencies;
- current JSON Schema references and which proposed P1-S02 contracts are already constrained versus merely described;
- available CLI/runtime packaging constraints on arm64 macOS;
- external process framing alternatives for the internal Pack boundary;
- Quality Compiler design-package claims that are unsupported by current runtime Evidence or that should be narrowed for QC1.

Research notes must report facts, uncertainty, sources, and implications. They must not add dependencies, modules, migrations, public protocols, or prototypes unless a separately accepted spike authorizes that work.

## Authorization package required before implementation

A later P1-S02 authorization pass should produce at minimum:

1. reconciled P1-S01 closeout Evidence and implications;
2. accepted P1-S02 ticket sequence and branch names;
3. one implementation plan per authorized ticket or an accepted mechanism for generating each plan immediately before work;
4. exact cross-ticket dependency graph;
5. security boundary for each ticket;
6. durable-domain and persistence decisions;
7. external Command and Pack lifecycle decisions;
8. final first-month Context and Tool contract;
9. Patch Approval/application/recovery contract;
10. Assurance and Finding/baseline semantics;
11. provider contract and deterministic fake contract;
12. Elixir Pack QC1 scope;
13. aggregate P1-S02 gate and demo definition;
14. owner-machine Evidence requirements;
15. explicit exclusions including QC2, Child Runs, TUI, worktrees, public Pack platform, and remote execution;
16. an adjudication statement that explicitly grants or withholds implementation authority.

## P1-S02 planning guardrails

- Do not build the Quality Compiler as an isolated horizontal framework.
- Do not let a Development Pack execute Project Commands or mutate source.
- Do not let the model approve or apply its own Patch.
- Do not expose arbitrary shell.
- Do not inherit the full user environment.
- Do not equate exit zero with criterion satisfaction.
- Do not discard raw output after normalization.
- Do not convert missing tooling, malformed output, cancellation, truncation, Pack crash, provider uncertainty, or cleanup uncertainty into pass.
- Do not silently downgrade required Assurance.
- Do not freeze a public Pack protocol before portability proof.
- Do not introduce Child Runs or claim QC2 independence.
- Do not add managed worktrees merely to simplify mutation isolation.
- Do not automatic commit, push, merge, publish, deploy, or install dependencies.
- Do not allow P1-S02 planning to weaken accepted P1-S01 durability contracts.

## Planning success condition

Planning is ready for adjudication when the project can explain, for every proposed P1-S02 ticket:

- the user-visible increment;
- the exact prerequisite Evidence;
- the failure mode the new mechanism addresses;
- the minimum durable concepts it introduces;
- the live resources that require process ownership;
- the Capability and security boundary;
- how current Repository state is bound;
- how deterministic verification works without a live provider;
- what later capability remains deliberately unreachable;
- what exact Evidence allows the ticket to merge;
- how the ticket advances the Single-Run Alpha rather than a standalone framework.

Until that package is accepted, P1-S02 remains planning only.
