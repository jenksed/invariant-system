# Kiln Planning Round Register

**Document type:** Remaining-planning control authority  
**Decision status:** Proposed by P0-W20; owner acceptance required  
**Integration status:** Proposed on `work/p0-w20-planning-round-register`  
**Implementation status:** Planning control only  
**Baseline:** Prompt 3 integrated through pull request 24 at `0dba694f2a54ab517a2c43bbbd5c77f526a02e65`  
**Build authorization:** Not issued

## 1. Authority and use

This register owns:

- unresolved planning-domain classification;
- focused planning-round identity, scope, sequence, dependencies, status, and completion gates;
- Prompt 5 invocation bundles;
- first-month and twelve-week planning-readiness boundaries;
- owner, prototype, deferred, disposition-review, and conformance-candidate registers.

Prompt 4 defines these rounds. It does not execute them.

Prompt 5 runs once for each required round. Prompt 6 evaluates justified conformance scaffolding after all rounds required for the next authorization boundary. Prompt 7 performs the final independent review for that boundary. Prompt 8 adjudicates findings and is the only pass that may issue build authorization.

Focused rounds must update current authorities. They must not create detached alternative architectures.

## 2. Evidence categories

This register uses:

- **Observed Fact** — current Repository Evidence directly supports the statement.
- **Accepted Decision** — an integrated current authority establishes the decision.
- **Proposed Decision** — P0-W20 recommends the decision or sequence; acceptance is pending.
- **Inferred Decision** — current authorities imply the decision.
- **Assumption** — required planning relies on an unverified claim.
- **Unknown** — current Repository Evidence cannot answer the question.
- **Conflict** — active authorities require incompatible behavior.
- **Superseded Decision** — a later authority replaced the earlier decision.
- **Build Blocker** — implementation would otherwise invent product, authority, safety, state, or recovery behavior.
- **Planning Dependency** — another planning decision must occur first.
- **Prototype Dependency** — empirical Evidence must precede acceptance.
- **Owner Decision** — Repository Evidence cannot select the product, risk, disclosure, compatibility, or delivery choice.

## 3. Executive planning-sequence verdict

**Observed Fact:** Prompts 1 through 3 are integrated. The current `main` head is the Prompt 3 merge. No post-Prompt-3 change alters the product target, inventory, dispositions, delivery targets, or planning dependencies.

**Accepted Decision:** The planning target remains one local-first, CLI-first, durable, controlled, evidence-backed source-change loop before Child Runs.

**Proposed Decision:** Five focused rounds are required before the first-month authorization wave:

1. P0-W21 — Root Run lifecycle and durable journal.
2. P0-W22 — Provider, Context, Tools, Repository reads, and disclosure.
3. P0-W23 — Patch, Approval, mutation, and recovery.
4. P0-W24 — Command execution, Evidence, Artifacts, Receipts, and acceptance.
5. P0-W25 — CLI product contract and local delivery.

Two additional focused rounds are required before the twelve-week delegated target:

6. P0-W26 — Interruption and unknown-effect reconciliation.
7. P0-W27 — Child Runs, delegated permissions, Attention, and navigation.

The most important planning dependency is the Root Run lifecycle and journal contract. It defines durable state, transition authority, restart truth, and the effect boundaries consumed by later rounds.

The largest sequencing risk is allowing a downstream round to redefine an upstream state, authority, or Evidence contract. The second largest risk is allowing Child planning to delay or broaden the Root workflow.

No foundational Prompt 2 contradiction is present. Prompt 4 can pass after this register, canonical status, dependency, and final-head validation are complete.

## 4. Revalidated authority

| Authority | Current conclusion | Classification |
| --- | --- | --- |
| `docs/PLANNING-COMPLETION-BASELINE.md` | Product source is an early Mix bootstrap; planning depth is not implementation | Observed Fact |
| `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md` | One developer, one Repository, one Root Run, one real change, CLI first | Accepted Decision |
| ADR 0020 | Single-Run change loop precedes delegated orchestration | Accepted Decision |
| `docs/ARCHITECTURE.md` | Plain data for domain facts; processes only for live Resources | Accepted Decision |
| `docs/RUN-MODEL.md` | Run identity is separate from process, model, Tool, Command, branch, worktree, and transcript | Accepted Decision |
| `docs/ROADMAP.md` | P1-S01 and P1-S02 form the first-month target; P1-S03 through P1-S05 form adjacent version 0.1 work | Accepted Decision |
| `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md` | 33 units are classified; planning-dependent units identify Prompt 4 inputs | Accepted Decision |
| `docs/contracts/` | Current Schemas are overlapping conformance scaffolds, not one active runtime contract | Observed Fact |
| current source and tests | No product workflow exists | Observed Fact |

Prompt 3 found conformance drift and implementation pressure. It did not invalidate the accepted product or architecture target.

## 5. Resolved decisions

The following do not require another focused round:

- product definition, initial user, and non-goals;
- first-month and twelve-week scope boundaries;
- one Project, Repository, Session, Task, and Root Run for the first product;
- Task and Run separation;
- no separate Root Task initially;
- no process per domain noun;
- transient model and Command Workers only when live ownership exists;
- SQLite as the first durable store and journal separate from transcript;
- Git and filesystem as source truth;
- one selected checkout and one mutation owner in the first month;
- one provider and deterministic fake, with no router or fallback;
- explicit Context package and four-Tool maximum;
- model proposal separated from Approval and application;
- registered non-shell verification Command;
- Claims separated from current Evidence;
- failed, blocked, stale, contradictory, incomplete, missing, or orphaned Evidence blocks completion;
- CLI before TUI;
- Child depth one, one active Child, no nesting, no writing Child, no permission expansion through version 0.1;
- TUI, managed worktrees, runtime Skills, code intelligence, local project intelligence, protocols, telemetry export, remote execution, and attestations remain deferred.

## 6. Planning-domain inventory and classification

| Domain | Exact unresolved decision | Evidence | Classification | Owner |
| --- | --- | --- | --- | --- |
| Root Run lifecycle | complete transition table, authority, invalid behavior, completion and orphan boundaries | Run Model; Prompt 3 IU-06 | Dedicated round | P0-W21 |
| SQLite journal | append transaction, sequence, idempotency, projections, migrations, corruption, restart | Prompt 2 remaining-domain assessment; IU-07 | Dedicated round | P0-W21 |
| SQLite library | exact dependency and connection ownership | P0-W18 unknown; IU-02 and IU-07 | Belongs in P0-W21 | P0-W21 |
| Provider invocation | first adapter, fake, request/result, streaming, cancellation, timeout, retry, usage | IU-08 | Dedicated round | P0-W22 |
| Context package | fields, ordering, digest, limits, selection, inspection, staleness | IU-09 | Belongs in P0-W22 | P0-W22 |
| Tool projection | exact four-or-fewer Tools, phase eligibility, authority, result and failure | Context and Capability scaffolds | Belongs in P0-W22 | P0-W22 |
| Repository reads | root, ignore, path, symlink, binary, size, encoding, fingerprints | P1-S02 gates; security authority | Belongs in P0-W22 | P0-W22 |
| Disclosure and secrets | allowed egress, source classes, screening, redaction, retained provider content | Security Model; IU-09 | Belongs in P0-W22 plus OD-01 | P0-W22 |
| Patch proposal | representation, canonical digest, base binding, operation and size limits | IU-10; overlapping Git and execution contracts | Dedicated round | P0-W23 |
| Approval and mutation authority | exact subject, actor, lifetime, replay, stale Approval, one owner | IU-11 | Belongs in P0-W23 | P0-W23 |
| Patch application and recovery | preconditions, dirty overlap, application, rollback, partial failure, unknown effects | P1-S02 and P1-S03 gates | Belongs in P0-W23 | P0-W23 |
| Command execution | registration, argv, cwd, environment, timeout, process tree, output, cleanup | IU-12 | Dedicated round | P0-W24 |
| Evidence and completion | subject, criterion, freshness, completeness, contradiction, invalidation, readiness | IU-14 | Belongs in P0-W24 | P0-W24 |
| Artifacts | atomic storage, content addressing, metadata, limits, active-Session retention | IU-13 | Belongs in P0-W24 | P0-W24 |
| Receipts and first-month acceptance | minimum manifest, criterion coverage, warnings, unknowns, aggregate proof | IU-15, IU-29, IU-30 | Belongs in P0-W24 | P0-W24 |
| CLI workflow | commands, confirmations, structured output, exit status, restart and errors | IU-16 | Dedicated round | P0-W25 |
| Local packaging and version | supported host, installation, configuration, version surface | IU-03 and IU-04 | Belongs in P0-W25 plus OD-02 | P0-W25 |
| Interruption and reconciliation | cross-operation cancellation, idempotency, stale Evidence, orphan actions | P1-S03; Prompt 3 planning inputs | Dedicated later round | P0-W26 |
| Child Runs and permissions | creation, one-active depth-one enforcement, narrower grants, no-write roles | IU-17 | Dedicated later round | P0-W27 |
| Attention, delivery, and Child navigation | routing, response, cancellation, bounded result, CLI focus | delegation and interface scaffolds | Belongs in P0-W27 | P0-W27 |
| CLI parser, help text, formatting | local reversible presentation inside accepted contract | no cross-boundary effect | Bounded implementation discretion | P1 ticket |
| internal private helper layout | local and reversible under earned namespaces | source-layout authority | Bounded implementation discretion | P1 ticket |
| exact test helper organization | local and reversible within accepted gates | testing rules | Bounded implementation discretion | P1 ticket |
| TUI and ExRatatui | no current consumer; outside twelve weeks | ADR 0020; IU-33 | Deferred until blast radius | future round |
| managed worktrees | one writer and one checkout suffice | ADR 0020; IU-31 trigger logic | Deferred until measured isolation need | future round |
| runtime Skills | no repeated tested runtime procedure | Prompt 2 capability classification | Not currently justified | future evidence |
| code intelligence | basic read and search are accepted | Prompt 2 capability classification | Deferred until measured retrieval failure | future round |
| local project intelligence | reference repositories disabled through version 0.1 | IU-32 | Deferred until active retrieval is stable | future round |
| generalized Capability broker and model router | one implementation per operation | IU-31 | Not currently justified | future evidence |
| protocols | no concrete Client or capability consumer | protocol policy | Optional research only with consumer | future round |
| telemetry export | operations and privacy policy are not stable | Prompt 2 | Deferred until blast radius | future round |
| remote execution and attestations | no accepted remote workflow or immutable release subject | Prompt 2 | Not currently justified | future evidence |
| broad release infrastructure | one local developer product only | product non-goals | Not currently justified | future evidence |

## 7. Round-selection reductions

### Rounds combined

- Lifecycle and SQLite journal are one round because storage representation depends on state identity, transition authority, and restart truth.
- Provider, Context, Tools, Repository reads, disclosure, and secret screening are one round because they form one outbound investigation boundary.
- Patch, Approval, application, rollback, and first-month mutation recovery are one round because they form one authority-to-effect transaction.
- Command, Evidence, Artifacts, Receipts, retention, and acceptance are one round because they form one verification-to-completion proof chain.
- CLI and local packaging are one round because they define one delivered local workflow and must not become a release program.
- Scout, Verifier, Child permissions, Attention, bounded delivery, cancellation, and navigation are one round because they share one Parent/Child authority boundary.

### Rounds rejected

No standalone rounds are created for:

- security — each owning round must define its deterministic boundary;
- retention — active-Session retention belongs with journal and proof records; long-term retention is deferred;
- CLI styling — presentation remains bounded implementation discretion;
- protocols, TUI, worktrees, Skills, code intelligence, knowledge, telemetry, remote execution, or attestations — no current consumer exists;
- general Capability, Context, Event, Evidence, Artifact, or workflow platforms — explicitly rejected for now;
- broad packaging or release engineering — not required for one local user.

### Sequence effect

These reductions keep the first-month path at five rounds and prevent Child planning from blocking the Root change loop.

# 8. Required Planning Round Register

## P0-W21 — Root Run lifecycle and durable journal

**Planning domain:** Root work state, persistence, replay, and restart  
**Status:** Required; not started  
**Blast radius:** Required before P1-S01 and first-month implementation

### Purpose

Define the exact first-month Run transition contract and the smallest SQLite journal that reconstructs it without inventing state during implementation.

### Why required

Prompt 2 provides a minimum lifecycle, but no complete transition table, authority, invalid-transition result, journal transaction, migration, corruption, or restart matrix. Prompt 3 marks IU-02, IU-06, IU-07, and IU-13 as planning-dependent and identifies overlapping transition definitions.

### Authoritative inputs

- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/RUN-MODEL.md`
- `docs/SESSION-MODEL.md`
- `docs/ROADMAP.md` P1-S01
- `docs/IMPLEMENTATION-SLICES.md` P1-S01
- `docs/SLICE-ACCEPTANCE-GATES.md` P1-S01
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md` IU-02, IU-06, IU-07, IU-13
- `docs/contracts/kiln-core.schema.json`
- `docs/contracts/kiln-evidence.schema.json`
- ADRs 0002, 0007, and 0020
- `mix.exs` and `lib/kiln/application.ex`

### Exact decision questions

1. What exact first-month Run states exist, and which named states remain deferred?
2. What transitions are valid from each state, with which actor, reason, causation, prerequisites, and resume point?
3. Which application action can request and commit each transition?
4. What observable result follows invalid, duplicate, stale-revision, or out-of-order transition requests?
5. Which completion, failure, cancellation, and orphan facts are Run state, operation state, or Evidence state?
6. Which facts must be durable before Kiln reports Session, Task, Run, Approval, Patch, Command, Evidence, or acceptance state as durable?
7. What journal envelope, sequence, expected revision, idempotency, and causation contract is required?
8. Which facts belong in journal entries, projections, transcript records, Artifacts, or Repository observations?
9. What data commits atomically for Session creation, initial Task and Root Run creation, objective and criteria revision, and each transition?
10. How are projections rebuilt and versioned?
11. What happens after partial write, SQLite error, unsupported schema, corrupt record, or projection failure?
12. Who owns migrations, when do they run, and what blocked startup state results from failure?
13. Which SQLite library and connection model satisfy the required transaction, migration, busy, startup, and supervision behavior?
14. What is the smallest persistent data set for restart, audit, duplicate prevention, and reconciliation?
15. What observation classifies an interrupted external reference as known failed, canceled, complete, or orphaned?

### Accepted constraints

One Session, one initial Task, and one Root Run; no process per domain noun; SQLite only; journal only material work and effect boundaries; Git and filesystem remain source truth; unknown effects are never success or silently repeated.

### Non-goals

No Child states, Attention, TUI, distributed log, message broker, CQRS framework, general event platform, provider design, Patch design, Command design, Evidence platform, implementation, dependency change, migration, or Schema edit.

### Required method

Define a transition table, external-effect/restart matrix, journal ownership table, transaction examples, migration and corruption failure matrix, and smallest-credible SQLite library comparison from current official sources.

### Required outputs

- create `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`;
- update Run, Session, Architecture, P1-S01, gate, and disposition authorities;
- select the SQLite dependency boundary and connection ownership;
- create or revise an ADR only when required by the accepted dependency or state decision;
- update this register.

### Completion gate

Every first-month state and valid and invalid transition is enumerated. Transition authority, atomic facts, journal envelope, sequence, expected revision, idempotency, projections, migration, startup, corruption, and restart behavior are explicit. One transition owner and one journal owner exist. The SQLite library or exact accepted selection decision is recorded. No later scope is introduced.

### Implementation unlocked

After later Prompt 8 authorization: P1-S01 domain records, transition validation, journal migration, append transaction, projections, replay, and restart reconstruction.

### Implementation still blocked

Provider, Context, Repository investigation, Patch mutation, Command verification, Evidence completion, Receipt aggregation, full CLI delivery, and all Child work.

### Prompt 3 dispositions revisited

IU-02, IU-06, IU-07, IU-13, core and Evidence Schema rows.

### Candidate conformance scaffolding

Run state and transition types; material-event envelope; append and expected-revision contract; migration check; projection contract; invalid, duplicate, corruption, migration, and restart fixtures.

### Dependencies and parallelization

Prompt 4 must be integrated. P0-W21 may run in parallel with P0-W22. Use separate focused files. Merge P0-W21 first. P0-W22 may reference identifiers but may not add states or journal semantics.

### Prompt 5 invocation bundle

```text
Planning round:
P0-W21 — Root Run lifecycle and durable journal

Purpose:
Define the exact first-month Run transition contract and the smallest SQLite journal that reconstructs it without inventing state during implementation.

Exact decisions required:
Answer P0-W21 questions 1 through 15 in the Planning Round Register.

Authoritative inputs:
Use the exact paths listed in the P0-W21 Authoritative inputs section.

Accepted constraints:
Preserve one Session, Task, and Root Run; no process per domain noun; SQLite-only durable state; material journal events only; Git and filesystem source truth; conservative unknown effects.

Non-goals:
Do not plan Children, Attention, TUI, distributed logs, provider, Patch, Command, Evidence platform, or implementation.

Expected authoritative outputs:
Create docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md; update Run, Session, Architecture, P1-S01, gate, disposition, ADR when required, and register status.

Completion gate:
Satisfy every item in the P0-W21 Completion gate without adding later scope.
```

## P0-W22 — Provider, Context, Tools, Repository reads, and disclosure

**Planning domain:** Bounded model investigation and local-first egress  
**Status:** Required; not started  
**Blast radius:** Required before P1-S02 and first-month implementation

### Purpose

Define one reproducible model boundary, one explicit Context package, four or fewer Tools, safe Repository reads, and the only data that may leave the machine.

### Why required

Prompt 3 marks IU-08 and IU-09 planning-dependent. Provider request, source disclosure, path policy, Tool projection, secret screening, and result externalization form one security boundary. Implementation must not invent disclosure tolerance, retries, path rules, or Tool scope.

### Authoritative inputs

- Product Scope, Architecture, Context System, Capability Integration, Security Model, and Run Model;
- Roadmap, slices, and gates for P1-S02;
- implementation register IU-08, IU-09, IU-13, IU-31;
- core, execution, Context, and Capability Schemas;
- ADR 0010 and ADR 0020.

### Exact decision questions

1. Which single provider is first, and which provider fields remain adapter metadata?
2. What request, stream or response, finish, usage, timeout, cancellation, malformed-result, and failure contract is normalized?
3. When is retry allowed, and what uncertain result forbids retry?
4. What deterministic fake behavior must CI reproduce?
5. What exact fields and item classes form the ordered Context package and manifest?
6. How are item and package digests, versions, state bindings, inspection, and staleness handled?
7. Which source classes may be included, summarized, excerpted, redacted, omitted, or externalized?
8. Which token, byte, file, item, and elapsed limits apply?
9. Which paths, files, encodings, symlinks, binaries, control characters, and secret patterns are denied?
10. Which data may leave the machine, under what policy or Approval, and what disclosure decision is recorded?
11. What provider input and output is retained, externalized, redacted, or never stored?
12. What exact Repository observe, search, read, and Artifact-read operations exist?
13. How are root, checkout, ignore, path normalization, dirty state, and fingerprints handled?
14. What are the exact four-or-fewer Tools by workflow step, with input, output, authority, limits, and failure?
15. How are unused catalogs, Skills, reference repositories, and unrelated source excluded?
16. How are model observations, inference, proposed change, warning, and unknown separated from source Evidence?

### Accepted constraints

One provider and deterministic fake; no router or fallback; sealed package only; Context grants no authority; maximum four Tool schemas; Repository content is untrusted data; no broker, Skill, retrieval framework, reference Repository, LSP, index, or protocol.

### Non-goals

No multi-provider system, Agent catalog, generalized Capability system, Skills, embeddings, hosted retrieval, MCP, LSP, Tree-sitter, reference retrieval, Patch application, Command execution, Evidence aggregation, CLI syntax, implementation, or scaffold creation.

### Required method

Perform an outbound-data threat analysis, define concrete Context inclusion and exclusion examples, define a phase Tool matrix, compare one-provider adapters against OD-01, and define secret-canary, path, malformed-result, timeout, cancel, and retry examples.

### Required outputs

Create `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`; update Architecture, Security Model, Context System, Capability Integration, P1-S02, gates, dispositions, provider ADR when required, and register status.

### Completion gate

One provider and fake contract; exact request, result, timeout, cancellation, retry, usage, disclosure, and retention behavior; exact Context fields, order, digests, limits, and exclusions; exact Repository operations and path controls; exact four-or-fewer Tools; complete secret and untrusted-instruction handling; no generalized system.

### Implementation unlocked

After later Prompt 8 authorization: native bounded Repository reads and search, Context package, fixed Tool projection, fake provider, and one real provider adapter.

### Implementation still blocked

Patch, Approval, mutation, Command, Evidence, Receipt, completion, and complete CLI workflow.

### Prompt 3 dispositions revisited

IU-08, IU-09, IU-13, IU-31, execution, Context, Capability, and core Schema rows.

### Candidate conformance scaffolding

Provider behaviour and fake; Context item, manifest, and package types; Tool eligibility; Repository observation and path types; disclosure decision; secret and Repository negative fixtures.

### Dependencies and parallelization

Prompt 4 integrated and OD-01 answered before completion. May run in parallel with P0-W21. Merge P0-W21 first; rebase and merge P0-W22 second. P0-W22 cannot add lifecycle or persistence semantics.

### Prompt 5 invocation bundle

```text
Planning round:
P0-W22 — Provider, Context, Tools, Repository reads, and disclosure

Purpose:
Define one reproducible model boundary, one explicit Context package, four or fewer Tools, safe Repository reads, and the only data that may leave the machine.

Exact decisions required:
Answer P0-W22 questions 1 through 16 in the Planning Round Register.

Authoritative inputs:
Use the exact paths listed in the P0-W22 Authoritative inputs section.

Accepted constraints:
One provider and fake; sealed Context only; four-Tool maximum; Context cannot grant authority; no router, broker, Skills, retrieval framework, reference repositories, code intelligence, or protocols.

Non-goals:
Do not implement or plan Patch application, Commands, Evidence aggregation, CLI syntax, or deferred model systems.

Expected authoritative outputs:
Create docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md; update Architecture, Security, Context, Capability, P1-S02, gates, dispositions, ADR when required, and register status.

Completion gate:
Satisfy every item in the P0-W22 Completion gate without adding generalized or deferred scope.
```

## P0-W23 — Patch, Approval, mutation, and recovery

**Planning domain:** Controlled source mutation  
**Status:** Required; not started  
**Blast radius:** Required before P1-S02 mutation implementation

### Purpose

Define one base-bound Patch, one user Approval subject, one mutation owner, and truthful success, conflict, rollback, partial-failure, restart, and unknown-effect behavior.

### Why required

IU-10 and IU-11 are planning-dependent. Git and execution-plane Schemas overlap. Patch, Approval, selected checkout, application, rollback, and recovery are one authority-to-effect transaction.

### Authoritative inputs

Accepted P0-W21 and P0-W22 outputs; Product Scope; Architecture; Git Change Isolation; Command and Patch Execution; Trustworthy Execution Plane; Security Model; P1-S02 and mutation-related P1-S03 planning and gates; IU-10, IU-11, IU-13, IU-15; Git, execution-plane, and Evidence Schemas; ADRs 0013, 0018, and 0020.

### Exact decision questions

1. What one Patch representation supports first-month create, modify, and delete?
2. How is the proposal canonicalized and hashed, and what does the Approval digest cover?
3. Which Repository, checkout, commit, dirty fingerprint, file hashes, paths, and expected states bind the base?
4. Which rename, mode, symlink, submodule, binary, generated-file, line-ending, and encoding changes are allowed or blocked?
5. What Patch size, file count, changed-region, and path limits apply?
6. What deterministic validation precedes Approval?
7. What Approval actor, subject, reason, revision, lifetime, replay, revocation, and denial record is required?
8. What changes invalidate a pending Approval?
9. Which dirty overlap is allowed, and what blocks application?
10. Who owns the one mutation lease, and how is concurrent mutation rejected?
11. What application mechanism and order provide accepted practical atomicity?
12. What rollback data is retained, where, and with what guarantee?
13. What follows full apply, no-op, conflict, partial mutation, validation failure, rollback success or failure, and interruption?
14. What observation permits verification, and what unknown state blocks it?
15. What happens after restart at each Approval and application boundary?
16. What mutation facts pass to Evidence and Receipt without making the Patch proof of correctness?

### Accepted constraints

One selected checkout and mutation owner; model cannot approve or apply; exact digest and base Approval; no fuzzy apply, path escape, concurrent writer, commit, push, merge, publish, deploy, dependency install, worktree provisioner, writing Child, AST framework, or binary Patch; unknown effects block verification.

### Non-goals

No worktree system, branches as runtime identity, delegated writer, AST framework, general Approval service, commit or publication automation, Command verification, Receipt aggregation, CLI syntax, implementation, or scaffold creation.

### Required method

Define Patch and Approval state machines, file-operation matrix, mutation threat analysis, smallest credible application comparison, restart examples, and outcome-to-Evidence and next-action table.

### Required outputs

Create `docs/PATCH-APPROVAL-AND-MUTATION.md`; update Architecture, Git Change Isolation, Command and Patch Execution, Security Model, P1-S02, relevant P1-S03 gates, dispositions, contract ownership, ADR when required, and register status.

### Completion gate

One representation, digest, base, path, operation, and size contract; Approval authority, lifetime, invalidation, denial, and replay; one mutation owner and dirty policy; application, rollback, partial failure, interruption, restart, unknown effects, and next actions; no later scope.

### Implementation unlocked

After later Prompt 8 authorization: Patch validation, digest-bound Approval, mutation ownership, application, rollback reference, result observation, and conservative restart handling.

### Implementation still blocked

Command verification, Evidence, completion, Receipt, and complete CLI.

### Prompt 3 dispositions revisited

IU-10, IU-11, IU-13, IU-15, Git, execution-plane, and Evidence Patch rows.

### Candidate conformance scaffolding

Patch and operation types; canonical digest and base binding; Approval binding and replay guard; mutation lease; dirty validator; apply and rollback result; stale, conflict, path, partial-failure, rollback, and restart fixtures.

### Dependencies and parallelization

P0-W21 and P0-W22 accepted and integrated. Must run alone after both because it owns the shared mutation transaction.

### Prompt 5 invocation bundle

```text
Planning round:
P0-W23 — Patch, Approval, mutation, and recovery

Purpose:
Define one base-bound Patch, one user Approval subject, one mutation owner, and truthful mutation and recovery behavior.

Exact decisions required:
Answer P0-W23 questions 1 through 16 in the Planning Round Register.

Authoritative inputs:
Use the exact paths listed in the P0-W23 Authoritative inputs section and accepted P0-W21 and P0-W22 outputs.

Accepted constraints:
One checkout and mutation owner; exact digest and base Approval; model cannot approve or apply; no fuzzy apply, worktrees, writing Children, commit, merge, publication, or unknown success.

Non-goals:
Do not plan Commands, aggregate Evidence, full CLI, or later mutation systems. Do not implement or scaffold.

Expected authoritative outputs:
Create docs/PATCH-APPROVAL-AND-MUTATION.md; update mutation, security, P1-S02, gate, disposition, ownership, ADR when required, and register authorities.

Completion gate:
Satisfy every item in the P0-W23 Completion gate without adding later scope.
```

## P0-W24 — Command execution, Evidence, Artifacts, Receipts, and acceptance

**Planning domain:** Verification and proof-backed completion  
**Status:** Required; not started  
**Blast radius:** Required before P1-S02 verification and first-month completion

### Purpose

Define the proof chain from one registered Command through bounded Artifacts and current criterion Evidence to user acceptance and a non-authoritative Receipt.

### Why required

IU-12 through IU-15 and IU-30 are planning-dependent. Command results constrain Evidence; Evidence constrains completion; Artifacts and Receipts preserve proof. Splitting them would create duplicate owners or a general Evidence platform.

### Authoritative inputs

Accepted P0-W21 through P0-W23 outputs; Product Scope; Architecture; Command and Patch Execution; Execution Evidence and Receipts; Trustworthy Execution Plane; deferred observability document only for exclusions; Security Model; P1-S02 and P1-S03 planning and gates; IU-12 through IU-15, IU-29, IU-30; execution, Evidence, and execution-plane Schemas; ADRs 0018 and 0020.

### Exact decision questions

1. What registration identifies the first Command, executable, argv, cwd, environment, network, secret, timeout, and output policy?
2. How are user or model values represented without arbitrary shell or injection?
3. Which transient Worker owns start, process tree, timeout, cancellation, output, and cleanup?
4. Which primary host and process-control guarantees are supported, degraded, blocked, or unknown?
5. What follows start failure, nonzero exit, timeout, cancellation, kill, truncation, incomplete cleanup, or unknown effects?
6. Which output and structured result is inline, externalized, redacted, or omitted?
7. What fields define Evidence subject, criterion, method, observation, state, time, freshness, completeness, producer, and digest?
8. Which observations support, refute, block, or only record a Claim?
9. What yields criterion PASS, FAIL, or BLOCKED, and why is exit zero insufficient?
10. How are stale, partial, contradictory, superseded, unrelated, missing, and orphaned Evidence represented and invalidated?
11. Which Repository, Environment, criteria, registration, and dependency changes invalidate Evidence?
12. What becomes an Artifact, and how is it written atomically, addressed, sized, typed, trusted, referenced, and recovered?
13. What active-Session retention is required, and what remains deferred?
14. What minimum Receipt fields represent criteria, state, failures, warnings, unknowns, exclusions, and acceptance?
15. What prevents Receipt sealing from granting authority, refreshing Evidence, changing results, or accepting work?
16. What readiness rule permits user acceptance and Task completion, and what blocks it?
17. How are acceptance, Run completion, Task satisfaction, and Receipt creation ordered and committed?
18. What deterministic aggregate proof and negative fixtures define the Single-Run Change Alpha?

### Accepted constraints

Registered executable and argv, no arbitrary shell; transient Worker only; exit zero is not criterion success; bad or unknown Evidence blocks completion; Artifacts are external content, not automatic Evidence or Context; Receipt cannot authorize or verify; no telemetry, attestations, containers, remote execution, broad command catalog, or long-term retention.

### Non-goals

No terminal, shell, containers, remote Workers, broad discovery, telemetry, attestation, release provenance, general Evidence platform, Child Verifier, CLI syntax, implementation, or scaffold creation.

### Required method

Define Command state and process failure matrices; trace outcomes into Artifact, Evidence, criteria, completion, journal, and Receipt; define Evidence examples; define minimal Artifact lifecycle and retention; define completion truth table and Receipt manifest; remove deferred fields.

### Required outputs

Create `docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md`; update Architecture, Command and Patch Execution, Execution Evidence and Receipts, Trustworthy Execution Plane, P1-S02, P1-S03, aggregate gates, dispositions, contract ownership, OD-02, ADR when required, and register status.

### Completion gate

One Command and Worker contract; explicit primary-platform process behavior; exact Evidence, criterion, freshness, completeness, contradiction, invalidation, and blocking; exact Artifact storage and active retention; exact Receipt and no-authority rule; exact acceptance and completion order; exact aggregate proof; no deferred platform scope.

### Implementation unlocked

After later Prompt 8 authorization: registered verification, Command Worker, output Artifacts, criterion Evidence, completion evaluation, acceptance recording, and bounded Receipt.

### Implementation still blocked

Complete CLI delivery, richer interruption UX, and all Child work.

### Prompt 3 dispositions revisited

IU-12, IU-13, IU-14, IU-15, IU-29, IU-30, execution, Evidence, and execution-plane Schema rows.

### Candidate conformance scaffolding

Command registration, request, result, cleanup, Worker contract, Artifact reference and store, Evidence and criterion types, completion truth table, Receipt manifest, process and stale-Evidence fixtures.

### Dependencies and parallelization

P0-W21 through P0-W23 accepted and integrated; OD-02 answered before completion. Must run alone.

### Prompt 5 invocation bundle

```text
Planning round:
P0-W24 — Command execution, Evidence, Artifacts, Receipts, and acceptance

Purpose:
Define the complete first-month proof chain from registered Command to current Evidence, acceptance, and bounded Receipt.

Exact decisions required:
Answer P0-W24 questions 1 through 18 in the Planning Round Register.

Authoritative inputs:
Use the exact paths listed in the P0-W24 Authoritative inputs section and accepted P0-W21 through P0-W23 outputs.

Accepted constraints:
Registered non-shell Command; transient Worker; bad or unknown Evidence blocks completion; Artifacts externalize content; Receipts cannot change facts; no remote, container, telemetry, attestation, or general platform.

Non-goals:
Do not plan full CLI or Child verification. Do not implement or scaffold.

Expected authoritative outputs:
Create docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md; update proof, execution, security, P1-S02/P1-S03, gate, disposition, ownership, OD-02, ADR when required, and register authorities.

Completion gate:
Satisfy every item in the P0-W24 Completion gate without adding deferred scope.
```

## P0-W25 — CLI product contract and local delivery

**Planning domain:** Complete first-month user workflow and support boundary  
**Status:** Required; not started  
**Blast radius:** Required before first-month planning-ready and build authorization

### Purpose

Define the smallest complete CLI and local installation contract that exposes the accepted workflow without redefining lifecycle, authority, mutation, or Evidence.

### Why required

The product is CLI-first. IU-16 is a first-month scaffold. IU-03 and IU-04 depend on packaging. Syntax is reversible, but workflow actions, confirmations, structured results, errors, configuration, supported host, and delivery are product decisions.

### Authoritative inputs

Accepted P0-W21 through P0-W24 outputs; README; Product Scope; Architecture; CLI-TUI as CLI research and deferred TUI reference; P1-S01 and P1-S02 roadmap, demos, and gates; IU-03, IU-04, IU-16, IU-26, IU-29, IU-33; interface Schema; `mix.exs`, `lib/kiln.ex`, tool-version files; ADRs 0015 and 0020.

### Exact decision questions

1. What command and guided interaction structure exposes the full workflow with the fewest stable public concepts?
2. Which actions exist for Repository selection, Session start, objective and criteria, Run, status, inspection, Context, Patch review, approve, reject, apply, verify, accept, cancel, resume, reconcile, and Receipt?
3. Which actions require interactive confirmation, and which support explicit flags, files, or structured non-interactive use?
4. Which human and machine result fields must be equivalent?
5. What exit and error contract covers usage, state, permission, conflict, blocked, unavailable, timeout, interruption, integrity, and internal failure?
6. How are state, pending decision, stale Evidence, unknown effects, warnings, exclusions, and next action shown without secrets?
7. How does restart select the correct Session and Root Run, and what ambiguity blocks automatic selection?
8. What client-local state is allowed, and how is it kept out of domain truth?
9. What configuration is required for root, SQLite, provider, disclosure, Command, Artifact, and output mode?
10. Which host, architecture, and runtime versions are supported, and how are unsupported controls reported?
11. What local installation and invocation form is smallest and supportable?
12. Is `Kiln.version/0` derived, exposed through CLI, retained internally, or removed?
13. What demo and operator instructions prove one real change and restart without TUI?
14. Which parser, help, formatting, and presentation details remain bounded implementation discretion?

### Accepted constraints

CLI is permanent; TUI deferred; interface never owns truth; no bypass of prior contracts; one Project, Repository, checkout, Session, Task, Root Run; no auto commit, push, merge, publish, dependency install, fallback, or shell; packaging is local support, not release infrastructure.

### Non-goals

No TUI, Child navigation, web, ACP, AG-UI, multiple Clients, daemon, universal installer, auto-update, hosted service, broad release system, redefinition of earlier contracts, implementation, or scaffold creation.

### Required method

Walk every successful, failed, blocked, interrupted, and restart path; define action-to-application matrix and result-to-exit matrix; compare smallest local packaging choices against OD-02; separate stable structured fields from presentation discretion; review prompts, flags, outputs, and configuration for secrets and authority.

### Required outputs

Create `docs/CLI-AND-LOCAL-DELIVERY-CONTRACT.md`; update README, Architecture, CLI-TUI, P1-S01/P1-S02 demos and criteria, dispositions, host and packaging decision, version disposition, ADR when required, and register status.

### Completion gate

Every first-month action and failure maps to an earlier application command or query. Interactive and structured behavior, results, errors, exits, restart, secrets, configuration, host, runtime, installation, invocation, and version are explicit. Demo requires no TUI or broad delivery. Implementation discretion is named. Earlier contracts remain unchanged.

### Implementation unlocked

After first-month Prompt 6, Prompt 7, and Prompt 8 authorization: complete P1-S01 and P1-S02 CLI and local delivery implementation.

### Implementation still blocked

P1-S03 recovery UX, P1-S04/P1-S05 Child navigation, TUI, protocols, hosted delivery, and broad release work.

### Prompt 3 dispositions revisited

IU-03, IU-04, IU-16, IU-26, IU-29, IU-33, interface Schema row.

### Candidate conformance scaffolding

CLI command/query contract; structured result and error types; action and confirmation matrix; exit codes; configuration and redaction; packaging and version checks; headless demo and documentation-reference checks.

### Dependencies and parallelization

P0-W21 through P0-W24 accepted and integrated; OD-02 answered. Must run alone after all first-month semantic rounds.

### Prompt 5 invocation bundle

```text
Planning round:
P0-W25 — CLI product contract and local delivery

Purpose:
Define the smallest complete CLI and local installation contract for the accepted first-month workflow.

Exact decisions required:
Answer P0-W25 questions 1 through 14 in the Planning Round Register.

Authoritative inputs:
Use the exact paths listed in the P0-W25 Authoritative inputs section and accepted P0-W21 through P0-W24 outputs.

Accepted constraints:
CLI permanent, TUI deferred, interface not truth, no safety bypass, one local workflow, no shell or publication, no release platform.

Non-goals:
Do not redesign upstream contracts, plan Child/TUI/protocol systems, or implement or scaffold.

Expected authoritative outputs:
Create docs/CLI-AND-LOCAL-DELIVERY-CONTRACT.md; update README, Architecture, CLI reference, demos, gates, dispositions, packaging/version, ADR when required, and register status.

Completion gate:
Satisfy every item in the P0-W25 Completion gate without redefining upstream decisions.
```

## P0-W26 — Interruption and unknown-effect reconciliation

**Planning domain:** Cross-operation cancellation, crash recovery, and conservative reconciliation  
**Status:** Required before P1-S03; not a first-month prerequisite  
**Blast radius:** Required before the twelve-week expansion authorization

### Purpose

Extend the Root workflow with explicit interruption, cancellation, idempotency, Evidence invalidation, orphan reconciliation, and recovery actions without changing first-month success semantics.

### Why required

First-month rounds define safety at each effect boundary. P1-S03 adds a complete cross-operation user contract. Combining it with first-month planning would delay the Root loop and add later states too early.

### Authoritative inputs

Accepted P0-W21 through P0-W25 outputs; integrated P1-S01/P1-S02 Evidence when available; Product Scope; Architecture; Run Model; P1-S03 roadmap, slice, and gates; Command and Patch Execution; Trustworthy Execution Plane; IU-06, IU-10, IU-12, IU-14, IU-17.

### Exact decision questions

1. Which operations are interruptible, and what durable boundary precedes each request?
2. What distinguishes pause, cancel request, canceled, failed, timed out, killed, orphaned, and reconciled?
3. Who can interrupt each operation?
4. What acknowledgement, grace, escalation, cleanup, and observation is required before applied cancellation?
5. How do request IDs and idempotency keys prevent repetition after restart?
6. What observations classify interrupted model, Patch, and Command effects?
7. Which changes invalidate which Evidence, and how is unrelated Evidence preserved?
8. What reconciliation actions exist, and which require user input or fresh observation?
9. What dirty work, output, rollback data, warnings, and unknowns are retained?
10. How are duplicate interruption and reconciliation requests handled?
11. What recovery CLI statuses, actions, and messages are required?
12. Which later states, timers, or live owners are justified?

### Accepted constraints

No uncertain repeat or success; first-month contracts remain authoritative; only observable states and live ownership; no Child, Attention router, TUI, remote Worker, general scheduler, or distributed lease; unsupported controls are unavailable or blocked.

### Non-goals

No Child cancellation, Parent propagation, Attention, TUI, remote execution, distributed idempotency, general compensation, implementation, or scaffold creation.

### Required method

Create interruption and crash matrices, separate request from acknowledgement and cleanup, define idempotency and restart examples, use integrated first-month Evidence to challenge assumptions, and justify every new state and process.

### Required outputs

Create `docs/INTERRUPTION-AND-RECONCILIATION.md`; update Run, Architecture, Command/Patch, focused first-month specs only when Evidence requires correction, P1-S03, gates, dispositions, platform blocks, and register status.

### Completion gate

Every interruptible operation and crash point has durable pre-state, request, acknowledgement, cleanup, terminal classification, and restart action. Idempotency, Evidence invalidation, orphan actions, retained work, and recovery CLI are explicit. Every new state or process is justified. No Child or remote scope.

### Implementation unlocked

After the twelve-week conformance, review, and authorization wave: P1-S03 interruption and reconciliation.

### Implementation still blocked

Scout, Verifier, Child permissions, Attention, Child navigation, and delivery.

### Prompt 3 dispositions revisited

IU-06, IU-10, IU-12, IU-14, IU-17 and recovery rows in execution and delegation Schemas.

### Candidate conformance scaffolding

Interruption request and acknowledgement; cancellation and cleanup result; idempotency; orphan and reconciliation action; Evidence invalidation; crash and recovery fixtures.

### Dependencies and parallelization

P0-W21 through P0-W25 accepted; first-month Prompt 8 authorization before this round starts; integrated P1-S01/P1-S02 Evidence before final acceptance. It may run alongside authorized first-month implementation but must merge only after revalidation against the integrated Single-Run Alpha.

### Prompt 5 invocation bundle

```text
Planning round:
P0-W26 — Interruption and unknown-effect reconciliation

Purpose:
Define cross-operation cancellation, idempotency, orphan reconciliation, Evidence invalidation, and recovery actions without changing first-month success semantics.

Exact decisions required:
Answer P0-W26 questions 1 through 12 in the Planning Round Register.

Authoritative inputs:
Use the exact paths listed in the P0-W26 Authoritative inputs section, accepted P0-W21 through P0-W25 outputs, and integrated Single-Run Alpha Evidence before final acceptance.

Accepted constraints:
No uncertain repeat or success; first-month contracts authoritative; unsupported controls blocked; no Child, TUI, remote, or general scheduler.

Non-goals:
Do not plan Child or remote recovery. Do not implement or scaffold.

Expected authoritative outputs:
Create docs/INTERRUPTION-AND-RECONCILIATION.md; update recovery authorities, P1-S03, gates, dispositions, platform blocks, and register status.

Completion gate:
Satisfy every item in the P0-W26 Completion gate and revalidate against integrated Single-Run Alpha Evidence.
```

## P0-W27 — Child Runs, delegated permissions, Attention, and navigation

**Planning domain:** Bounded Scout and Verifier delegation  
**Status:** Required before P1-S04 and P1-S05; deferred until Root value is proven  
**Blast radius:** Required before the twelve-week delegated CLI authorization

### Purpose

Define one depth-one, one-active-Child contract for a read-only Scout and independent Verifier, including narrower authority, independent Context, Attention, cancellation, bounded delivery, and CLI navigation.

### Why required

IU-17 and the delegation Schema are planning-dependent. Existing scaffolds include depth-two and broad assumptions. Scout, Verifier, permission derivation, Context, Attention, delivery, cancellation, and navigation share one Parent/Child authority boundary. Planning this before Root proof would return Kiln to orchestration-first design.

### Authoritative inputs

Accepted P0-W26 output; integrated Single-Run Alpha Evidence; Product Scope; Architecture; Run Model; Delegated Work; Project Stewardship; retained CLI navigation research; P1-S04/P1-S05 roadmap, slices, gates, and version 0.1 aggregate gate; IU-16, IU-17, IU-25, IU-29, IU-30; delegation, execution, and interface Schemas; ADRs 0014 and 0020.

### Exact decision questions

1. What measured Root limitation justifies Scout or Verifier instead of a Tool or Root action?
2. What Root request and deterministic validation create a Child, and what can deny it?
3. How are Root, Parent, Task, purpose, role, depth one, and one-active limit represented?
4. What independent Context does each role receive, and what Parent transcript, working set, secrets, Tools, caches, Skills, or narrative are excluded?
5. How are Child capabilities and Resources derived as a narrowing intersection?
6. What exact no-write constraints apply, and how is attempted mutation represented?
7. What bounded Scout result separates facts, Claims, assumptions, unknowns, Artifacts, and recommendation?
8. What Verifier input excludes author confidence and supplies criteria, exact state, Commands, and access?
9. What Evidence yields Verifier PASS, FAIL, or BLOCKED?
10. What Child states and live ownership are necessary for foreground or background execution?
11. Which question, permission, failure, blocker, limit, completion, or uninspected result creates Attention?
12. How is Attention deduplicated, routed, answered, denied, resolved, and resumed without granting authority?
13. How do Root failure, Child cancellation, restart, and result arrival use P0-W26 semantics?
14. What delivery contract copies references and structured results without transcript or mutable Context?
15. How does CLI list, inspect, enter, return, answer, deny, cancel, and show uninspected results while focus remains local?
16. What prevents nesting, peer communication, shared Context, permission expansion, writing Child, and Agent-manager loops?
17. How do Root recommendation, Child result, Evidence, acceptance, and Receipt remain separate?
18. What aggregate demo and Receipt prove Scout value, Verifier independence, restart, cancellation, Attention, and limits?

### Accepted constraints

Depth one; one active Child; Scout and Verifier only; independent Context and narrower grants; no write, nesting, peer, shared Context, permission expansion, ambient transcript, or Agent catalog; Verifier cannot repair or satisfy Task automatically; navigation changes focus only; Root contracts remain authoritative.

### Non-goals

No general orchestration, multiple active Children, depth two, writing delegation, worktrees, peer messaging, shared memory, role market, manager Agents, TUI, protocols, remote Agents, implementation, or scaffold creation.

### Required method

Start from integrated Root Evidence and state the measured need for each role. Define Parent/Child, permission intersection, Context exclusion, result delivery, Attention, cancellation, and CLI matrices. Define positive, denied, blocked, write-attempt, stale, cancel, restart, and duplicate-delivery examples. Challenge every process and field against the narrow limits.

### Required outputs

Create `docs/BOUNDED-CHILD-RUNS.md`; update Run Model, Delegated Work, Stewardship, Architecture, CLI navigation reference, P1-S04, P1-S05, aggregate gates, dispositions, contract ownership, ADR when required, and register status.

### Completion gate

Scout and Verifier creation, purpose, Context, grants, no-write, limits, states, cancellation, result, Evidence, and accounting are explicit. Depth and active limits are explicit. Attention, restart, Parent/Child failure, delivery, deduplication, navigation, PASS/FAIL/BLOCKED, and aggregate proof are explicit. No broader delegation scope.

### Implementation unlocked

After twelve-week Prompt 6, Prompt 7, and Prompt 8 authorization: P1-S04 Scout and P1-S05 Verifier delegation.

### Implementation still blocked

TUI, multiple or nested Children, writing delegation, worktrees, Skills, protocols, code intelligence, knowledge, telemetry, remote execution, and attestations.

### Prompt 3 dispositions revisited

IU-16, IU-17, IU-25, IU-29, IU-30 and delegation, execution, and interface Schema rows.

### Candidate conformance scaffolding

Child and role contract; permission intersection and no-write declarations; Child Context manifest; Attention and response; result delivery and deduplication; Scout and Verifier results; depth, active, no-nesting, no-write, restart, and navigation checks.

### Dependencies and parallelization

P0-W26 accepted and integrated; P1-S01 and P1-S02 integrated and accepted with aggregate Evidence. May run alongside authorized P1-S03 implementation after P0-W26, but runs alone as the authority owner for Child behavior.

### Prompt 5 invocation bundle

```text
Planning round:
P0-W27 — Child Runs, delegated permissions, Attention, and navigation

Purpose:
Define one depth-one, one-active-Child Scout and Verifier contract with narrower authority, independent Context, Attention, cancellation, delivery, and CLI navigation.

Exact decisions required:
Answer P0-W27 questions 1 through 18 in the Planning Round Register.

Authoritative inputs:
Use the exact paths listed in the P0-W27 Authoritative inputs section, accepted P0-W26 output, and integrated Single-Run Alpha Evidence.

Accepted constraints:
Depth one, one active Child, Scout and Verifier only, independent Context, narrower grants, no write, nesting, peer, shared Context, expansion, TUI, protocol, or manager Agents.

Non-goals:
Do not plan general orchestration or later delegation. Do not implement or scaffold.

Expected authoritative outputs:
Create docs/BOUNDED-CHILD-RUNS.md; update Child, permission, Attention, delivery, CLI, P1-S04/P1-S05, gate, disposition, ownership, ADR when required, and register authorities.

Completion gate:
Satisfy every item in the P0-W27 Completion gate without adding broader delegation scope.
```

## 9. Dependency graph

```text
Prompt 4 / P0-W20
├── P0-W21 lifecycle + journal ─┐
└── P0-W22 model boundary ─────┴→ P0-W23 mutation
                                      ↓
                                  P0-W24 proof
                                      ↓
                                  P0-W25 CLI + delivery
                                      ↓
                         Prompt 6-A first-month conformance
                                      ↓
                         Prompt 7-A independent review
                                      ↓
                         Prompt 8-A adjudication / possible authorization
                                      ↓
                               P1-S01 + P1-S02
                                      ↓
                                  P0-W26 recovery
                                      ↓
                                  P0-W27 Child Runs
                                      ↓
                         Prompt 6-B delegated conformance
                                      ↓
                         Prompt 7-B independent review
                                      ↓
                         Prompt 8-B adjudication / possible authorization
                                      ↓
                               P1-S03 through P1-S05
```

### Dependency table

| Round | Prerequisites | Unlocks | Can invalidate |
| --- | --- | --- | --- |
| P0-W21 | Prompt 4 integrated | P0-W23, P0-W24, P0-W25 | core and journal scaffolds |
| P0-W22 | Prompt 4 integrated; OD-01 before completion | P0-W23, P0-W24, P0-W25 | provider, Context, Tool, Repository-read scaffolds |
| P0-W23 | P0-W21 and P0-W22 | P0-W24 and P0-W25 | Git, Patch, Approval scaffolds |
| P0-W24 | P0-W21 through P0-W23; OD-02 | P0-W25 and first-month proof | Command, Artifact, Evidence, Receipt scaffolds |
| P0-W25 | P0-W21 through P0-W24; OD-02 | first-month conformance/review/adjudication | interface, packaging, branch examples |
| P0-W26 | accepted first-month plan; authorized and integrated Root Evidence before completion | P0-W27 and P1-S03 planning | recovery rows in earlier contracts when Evidence proves need |
| P0-W27 | P0-W26; integrated Single-Run Alpha Evidence | delegated conformance/review/adjudication | delegation, interface, role, Attention scaffolds |

The graph is acyclic. Deferred domains are not prerequisites.

## 10. Parallelization plan

### Safe group

P0-W21 and P0-W22 may run in parallel after P0-W20 integrates.

Why safe:

- P0-W21 owns lifecycle and durable state.
- P0-W22 owns model input, Repository reads, Tool projection, and disclosure.
- Each creates a separate focused specification.

Shared inputs:

- Product Scope;
- Architecture;
- ADR 0020;
- Roadmap and P1-S01/P1-S02 boundaries;
- Prompt 3 dispositions.

Merge order:

1. merge P0-W21;
2. rebase P0-W22;
3. verify that P0-W22 consumes but does not redefine lifecycle and journal decisions;
4. merge P0-W22.

Conflict rule:

Upstream owner wins. P0-W22 must defer lifecycle, transition, sequence, and persistence questions to P0-W21. P0-W21 must defer provider, Context, Tool, Repository-read, and disclosure questions to P0-W22.

### Unsafe combinations

- Lifecycle and journal cannot be separate parallel rounds.
- Patch and Approval cannot run separately.
- Patch planning cannot precede lifecycle and Repository-boundary planning.
- Command and Evidence cannot run separately or in parallel.
- CLI cannot run before lifecycle, model, mutation, and proof contracts settle.
- Child planning cannot run before Root proof and recovery semantics.

## 11. First-month planning-ready gate

The Single-Run Change Alpha is planning-ready only when:

1. P0-W21 through P0-W25 are accepted and integrated.
2. OD-01 and OD-02 are answered and recorded.
3. Every first-month Prompt 3 planning-dependent disposition has a final accepted direction.
4. Prompt 6-A evaluates and creates only justified first-month conformance rails.
5. Preflight, branch grammar, plan headings, Schema subset, agent assets, and documentation references agree with the accepted first ticket process.
6. Prompt 7-A independently reviews the exact integrated planning and conformance state.
7. Prompt 8-A adjudicates all blocking findings and explicitly authorizes a bounded first implementation scope.

P0-W20, the focused rounds, Prompt 6, or Prompt 7 cannot authorize construction.

## 12. Twelve-week planning-ready gate

The delegated CLI target is planning-ready only when:

1. the first-month gate has passed and Prompt 8-A authorized implementation;
2. P1-S01 and P1-S02 are integrated and accepted with current aggregate Evidence;
3. P0-W26 and P0-W27 are accepted and integrated;
4. Prompt 6-B evaluates only the interruption and delegation conformance needed for P1-S03 through P1-S05;
5. Prompt 7-B independently reviews the exact integrated state;
6. Prompt 8-B adjudicates findings and explicitly authorizes the next bounded scope.

Child planning does not block the Root build.

## 13. Broad build planning-ready

Broad implementation beyond P1-S05 is not planning-ready.

Each deferred domain requires:

- its recorded blast-radius trigger;
- current product and implementation Evidence;
- a new focused round only when implementation would otherwise invent a material decision;
- Prompt 6, Prompt 7, and Prompt 8 for the new authorization boundary.

No current document authorizes TUI, worktrees, Skills, code intelligence, knowledge, protocols, telemetry, remote execution, or attestations.

## 14. Deferred planning register

| Domain | Status | Review trigger | Required Evidence |
| --- | --- | --- | --- |
| TUI | Deferred | stable CLI plus one real Child workflow exposes a usability limit | measured CLI navigation or visibility failure; dependency review |
| managed worktrees | Deferred | one selected checkout creates measured isolation or concurrency risk | dirty-state, cleanup, or concurrent-write Evidence |
| runtime Skills | Not justified | repeated procedure with stable tested contract | repetition, value, authority, and prompt-injection analysis |
| code intelligence | Deferred | bounded read and exact search cause measured misses or token cost | benchmark and concrete language workflow |
| local project intelligence | Deferred | active Repository retrieval is stable and valuable | approved-root, provenance, licensing, and adversarial security Evidence |
| generalized Capability broker | Not justified | second interchangeable implementation for one intent | measured selection, health, or replacement need |
| model router and fallback | Not justified | second accepted provider | explicit routing, disclosure, retry, and authority need |
| protocols | Optional research | concrete Client, capability, service, or Environment | native mapping, security, cancellation, Evidence, replacement value |
| telemetry export | Deferred | stable operations and diagnostic need | exact signals and sensitive-data policy |
| remote execution | Not justified | accepted remote workflow | identity, isolation, network, secrets, cleanup, and unknown-effect plan |
| attestations | Not justified | immutable build or release subject and consumer | authenticity, subject, issuer, and verification model |
| long-term retention | Deferred | first-month use exposes storage or deletion need | measured volume, user expectation, privacy, and recovery requirement |
| broad release infrastructure | Not justified | supported external distribution becomes a product requirement | target platforms, support commitment, upgrade and rollback needs |

## 15. Prototype register

No prototype is required before the planning rounds can answer their product and architecture questions.

Potential empirical work is implementation-gate Evidence, not a pre-planning escape hatch:

- SQLite busy, migration, and transaction behavior must be tested in the authorized persistence ticket after P0-W21 defines the contract.
- Primary-platform process-tree cleanup must be tested in the authorized Command ticket after P0-W24 defines supported, degraded, blocked, and unknown behavior.
- Patch application and rollback must be tested in the authorized mutation ticket after P0-W23 defines the contract.

A focused round may recommend a bounded spike only when official interfaces cannot establish feasibility. The recommendation must return to Prompt 8 for authorization and must not block the round from defining required behavior.

## 16. Owner Decision Register

### OD-01 — First provider and source-disclosure mode

**Question:** Which single real provider is the first supported destination, and may sealed source excerpts leave the machine under accepted Project policy?

**Why not inferable:** Current authority accepts one provider but does not make the current historical MiniMax preference a binding provider and disclosure commitment.

**Options:**

1. MiniMax first; sealed source excerpts allowed only under explicit Project disclosure policy; no fallback.
2. Another hosted provider under the same sealed-context and no-fallback rules.
3. Local or self-hosted model; no remote source egress, with higher local setup cost.

**Default recommendation:** Option 1. It preserves the historical first-provider direction while keeping egress explicit, inspectable, bounded, and reversible behind one adapter.

**Consequences:** Provider API, credentials, request shape, rate and timeout limits, Privacy exposure, test fixtures, and support burden.

**Latest decision point:** Before P0-W22 completion.

**Blocked:** Real provider selection, final disclosure policy, provider-specific ADR, live smoke path.

**Reversible default:** Yes. The provider adapter is replaceable, but stored disclosure policy and historical manifests must remain interpretable.

### OD-02 — Primary supported host for first-month execution and delivery

**Question:** Which one host platform and architecture receive first-month process-tree, packaging, and support guarantees?

**Why not inferable:** The Repository accepts one primary process-control target but does not select macOS, Linux, or both.

**Options:**

1. macOS first.
2. Linux first.
3. macOS and Linux together.

**Default recommendation:** Select the Project owner's actual development host as the only guaranteed first target. Report unavailable controls honestly on other hosts. Do not choose option 3 before one platform passes the complete workflow.

**Consequences:** Process-tree mechanism, test environment, package form, path behavior, support matrix, and delivery schedule.

**Latest decision point:** Before P0-W24 and P0-W25 completion.

**Blocked:** Exact Command cleanup guarantees, supported-platform gate, local installation contract.

**Reversible default:** Yes. A later platform adapter and acceptance suite can expand support without changing native domain semantics.

No other owner decision is required now. Focused rounds may propose bounded UX or retention defaults and request ordinary acceptance without adding them to this register unless Repository Evidence cannot resolve the choice.

## 17. Prompt 3 dispositions to revisit

| Round | Dispositions |
| --- | --- |
| P0-W21 | IU-02, IU-06, IU-07, IU-13; core and Evidence Schema ownership |
| P0-W22 | IU-08, IU-09, IU-13, IU-31; provider, Context, Capability, and core Schemas |
| P0-W23 | IU-10, IU-11, IU-13, IU-15; Git, execution-plane, and Evidence Patch ownership |
| P0-W24 | IU-12, IU-13, IU-14, IU-15, IU-29, IU-30; Command, Artifact, Evidence, Receipt ownership |
| P0-W25 | IU-03, IU-04, IU-16, IU-26, IU-29, IU-33; interface and version surface |
| P0-W26 | IU-06, IU-10, IU-12, IU-14, IU-17; interruption and orphan rows |
| P0-W27 | IU-16, IU-17, IU-25, IU-29, IU-30; delegation, Attention, result, and navigation rows |

A round may narrow or replace a planning-dependent disposition. It may not reopen a retained or deferred disposition without contradictory current Evidence.

## 18. Candidate conformance-scaffolding register

| Candidate | Required round | Decision encoded | Drift risk addressed | Likely form | Why not now |
| --- | --- | --- | --- | --- | --- |
| Run transition contract | P0-W21 | states, authority, invalid and terminal behavior | competing transition owners | types, pure validator, Schema subset, fixtures | transition table unsettled |
| journal envelope and append contract | P0-W21 | sequence, expected revision, idempotency, atomic facts | storage invents product state | types, validator, migration and replay fixtures | library and transaction boundary unsettled |
| provider behaviour and fake | P0-W22 | normalized request/result and failure | provider-specific semantics leak inward | behaviour, fake, contract tests | provider and retry unsettled |
| Context package | P0-W22 | items, order, digests, limits, disclosure | broad compiler and hidden egress | types, Schema, manifest fixtures | exact package unsettled |
| Tool eligibility | P0-W22 | four-or-fewer phase Tools | catalog enters Context or grants authority | allowlist and contract tests | exact Tools unsettled |
| Repository path and disclosure rails | P0-W22 | root, path, symlink, binary, secret, egress | path escape and source leak | validators and negative fixtures | policy unsettled |
| Patch, digest, and base binding | P0-W23 | one proposal and base contract | stale or fuzzy application | types, canonicalizer checks, fixtures | representation unsettled |
| Approval binding | P0-W23 | exact authority and invalidation | replay or self-approval | type and validator | subject and lifetime unsettled |
| mutation result and recovery | P0-W23 | apply, rollback, partial, orphan | uncertain mutation called success | result types and crash fixtures | mechanism unsettled |
| registered Command | P0-W24 | executable, argv, cwd, environment, limits | arbitrary shell and ambient environment | registration and request types | platform decision unsettled |
| Command Worker contract | P0-W24 | timeout, cancel, cleanup, unknown effects | process leak and false cancellation | behaviour and lifecycle tests | primary host unsettled |
| Artifact reference and store | P0-W24 | atomic content and metadata | large content in journal or Context | type, store contract, fixtures | storage and retention unsettled |
| Evidence and completion | P0-W24 | criterion, freshness, contradiction, readiness | model confidence or exit zero becomes proof | types, pure evaluator, fixtures | proof semantics unsettled |
| bounded Receipt | P0-W24 | exact manifest and no-authority rule | complete-looking Receipt overstates proof | Schema and manifest tests | fields unsettled |
| CLI result and error contract | P0-W25 | public action, output, and exit behavior | UI becomes truth or bypasses controls | types, Schema, command matrix | workflow and packaging unsettled |
| branch and preflight repair | P0-W25 plus all first-month rounds | accepted P0 and P1 identifiers and current plan headings | P1 work cannot start | script, tests, CI assertion | Prompt 4 and first ticket not accepted |
| documentation-reference validation | P0-W25 | current authority and commands | planned paths mistaken as executable | validation script | final file graph unsettled |
| interruption and reconciliation | P0-W26 | cancel, idempotency, orphan actions | repeated or hidden effects | types and crash fixtures | Root behavior not proven |
| Child and permission contract | P0-W27 | depth, active limit, independent Context, narrower grants | recursive management and authority expansion | Schema, types, validators | Root value not proven |
| Attention and delivery | P0-W27 | durable blocker and bounded result | silent grant or transcript copying | types and idempotency fixtures | Child contract unsettled |

Prompt 6 decides which candidates are worth creating. Presence in this table is not approval.

## 19. Planning risks

### Risk 1 — Planning becomes a horizontal framework design

- **Cause:** Each round touches long-term documents and broad Schemas.
- **Impact:** First-month implementation inherits broker, event, Evidence, or interface platforms.
- **Early warning:** New general catalogs, registries, services, schemas, or namespaces appear in round outputs.
- **Mitigation:** Enforce each round's accepted constraints, non-goals, implementation unlocked, and still-blocked sections.
- **Scope reduction:** Keep only the one Root workflow and one concrete operation per boundary.

### Risk 2 — Downstream rounds redefine upstream authority

- **Cause:** Lifecycle, Context, Patch, Command, Evidence, and CLI share identifiers and state references.
- **Impact:** Multiple contract owners, migrations before semantics settle, or CLI-owned product state.
- **Early warning:** A later round adds Run states, changes journal semantics, widens disclosure, or changes mutation and completion rules without reopening the owning round.
- **Mitigation:** Dependency order, one-owner rules, merge order, upstream-wins conflict rule, and Prompt 6 contract reconciliation.
- **Scope reduction:** Remove the downstream feature rather than duplicate the upstream concept.

### Risk 3 — Child planning delays or contaminates Root proof

- **Cause:** Delegation documents are detailed and attractive to implement.
- **Impact:** Orchestration-first delivery, background processes, Attention, and interface scope return before one real change works.
- **Early warning:** P0-W27 starts before Single-Run Alpha Evidence or first-month contracts add Child states and services.
- **Mitigation:** Separate authorization waves; P0-W27 requires integrated Root Evidence; deferred namespaces remain prohibited.
- **Scope reduction:** Ship Root-only version 0.1 if Scout or Verifier value is not demonstrated.

## 20. Planning reduction summary

Active planning removed from the critical path:

- TUI and ExRatatui;
- managed worktrees;
- runtime Skills;
- code and local project intelligence;
- protocols and standards coverage;
- generalized Capability, Context, Event, Evidence, Artifact, or workflow platforms;
- telemetry export;
- remote execution;
- attestations;
- broad release infrastructure;
- long-term retention policy;
- multiple providers and platforms.

Seven focused rounds replace more than twenty topic-shaped candidates. Only five precede the first-month authorization wave.

## 21. Prompt order and status control

```text
P0-W20 Prompt 4 register
→ P0-W21 through P0-W25 with Prompt 5
→ Prompt 6-A first-month conformance
→ Prompt 7-A independent review
→ Prompt 8-A adjudication and possible first-month authorization
→ authorized P1-S01 and P1-S02
→ P0-W26 and P0-W27 with Prompt 5 when prerequisites pass
→ Prompt 6-B delegated conformance
→ Prompt 7-B independent review
→ Prompt 8-B adjudication and possible P1-S03 through P1-S05 authorization
```

Prompt 7 remains immediately before Prompt 8 for each authorization boundary. Prompt 8 remains the only authorization pass.

## 22. P0-W20 completion gate

P0-W20 passes only when:

- Prompt 1 through Prompt 3 integration is confirmed;
- every material unresolved domain has one classification;
- every first-month blocker has one owning round or owner decision;
- every twelve-week dependency is visible;
- every required round contains all required register fields and a Prompt 5 bundle;
- dependencies are valid and acyclic;
- parallelization and merge order are justified;
- no deferred domain is a first-month prerequisite;
- no required first-month decision lacks an owner;
- prototype and owner registers are complete;
- Prompt 3 dispositions and Prompt 6 candidates are mapped;
- Prompt 7 remains last before Prompt 8;
- the final planning-only diff passes exact-head Repository validation.

Passing P0-W20 does not complete any focused round or issue build authorization.

## 23. Exact next action after P0-W20 integration

Run Prompt 5 for:

```text
P0-W21 — Root Run lifecycle and durable journal
```

P0-W22 may begin in parallel only after P0-W20 is accepted and integrated and OD-01 is supplied. Use separate branches and focused specifications. Merge P0-W21 first, then rebase and reconcile P0-W22 before merge.
