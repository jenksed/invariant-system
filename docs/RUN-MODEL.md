# Run Model

**Document type:** Run and delegation subject authority  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Not implemented  
**Product-scope authority:** `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`  
**Architecture authority:** `docs/ARCHITECTURE.md`

## Definition

A Run is one durable, independently inspectable attempt or coordination boundary for one Task inside a Kiln Session.

A Run is Kiln's primary durable identity for:

- execution coordination;
- observation;
- cancellation;
- Evidence association;
- recovery;
- resource accounting when applicable.

A Run is not:

- an Agent persona;
- a model invocation;
- a Tool call;
- a Command;
- an operating-system or BEAM process;
- a branch or worktree;
- a protocol session;
- a conversation or transcript.

## Minimum hierarchy

```text
Workspace
└── Project
    └── Session
        └── Task
            └── Root Run
```

The first useful Kiln has one active Project, one active Repository, one Session, one Task, and one Root Run.

The initial implementation does not create a separate Root Task. The Session owns one accepted objective. Its initial Task states the desired outcome and criteria. The Root Run attempts or coordinates that Task.

## Task and Run

A Task states one bounded desired outcome, decision, investigation, change, or verification target.

A Run attempts or coordinates the Task.

A completed Run does not satisfy the Task automatically. Task satisfaction depends on:

- accepted criteria;
- current Evidence;
- observed Repository state when applicable;
- unresolved failures and unknowns;
- required user acceptance.

One Task can later have more than one Run when:

- an attempt failed or was canceled;
- Evidence became stale;
- a new approach is required;
- delegated investigation requires an independent boundary;
- independent verification requires separate Context and authority.

## Run identity

Kiln generates `run_id`.

Run identity must not use:

- role, Agent, model, or provider name;
- provider request ID;
- Tool, Command, Terminal, Worker, process, Port, or task ID;
- Git branch, commit, worktree, or checkout path;
- client, protocol thread, or transcript position.

Run identity survives Worker, process, provider, client, adapter, and application restart.

## Root Run

Each Session has exactly one Root Run.

The Root Run:

- has no Parent Run;
- references the Session's initial Task;
- references itself as `root_run_id` when that field is used;
- owns the primary work-control projection;
- can investigate, propose, apply authorized change, execute controlled verification, and coordinate later Child Runs;
- carries delivery-integrity responsibility without becoming a manager Agent.

Root is a relationship role and invariant. It does not require a separate entity type, table, supervisor, or long-lived process.

## Minimum lifecycle

Version 0.1 begins with this core lifecycle:

```text
created
→ ready
→ running
→ waiting_for_user | waiting_for_command | verifying
→ completed | failed | canceled | orphaned
```

### `created`

Kiln has accepted identity and ownership records. Prerequisites can still be incomplete.

### `ready`

Project, Repository, objective, criteria, policy, and required Environment observations permit work to begin.

### `running`

A Worker or deterministic application action can advance the Run.

### `waiting_for_user`

The Run has one explicit pending decision and durable resume point.

A pending Patch Approval is represented here in the first month.

### `waiting_for_command`

A registered Command is active or its result is required before the Run can advance.

### `verifying`

Kiln is evaluating accepted criteria against exact current state.

### `completed`

The attempt has finished and the assigned Task is satisfied through current Evidence and required acceptance.

### `failed`

The attempt cannot continue under its current contract. A new attempt requires a new Run when the Task remains active.

### `canceled`

An authorized cancellation ended the attempt and all material effects are reconciled.

### `orphaned`

Kiln cannot determine the state or effects of one or more external operations. Reconciliation is required before another attempt repeats or depends on the operation.

## Lifecycle rules

- `completed`, `failed`, and `canceled` are terminal for one attempt.
- `orphaned` is not success and cannot become success through narrative.
- A Run enters `waiting_for_user` only with an explicit pending decision and resume point.
- A Run enters `waiting_for_command` only with an owned Command reference.
- `verifying` identifies criteria revision and evaluated Repository and Environment state.
- Evidence staleness is an Evidence property in the first implementation. It does not require a separate Run state.
- Later Child workflows can add `queued`, `waiting_for_child`, `waiting_for_permission`, and `paused` only when their user-visible behavior requires them.

## Required Run state

A Run owns or references:

- `run_id`;
- `session_id`;
- `task_id`;
- `root_run_id`;
- optional `parent_run_id`;
- status and current workflow step;
- accepted Task and criteria revision;
- policy and effective-authority references;
- Context package manifests;
- model invocation references;
- Tool calls;
- Patch proposal and application references;
- Command execution references;
- Artifacts, Claims, Evidence, and Receipt references;
- failures, warnings, assumptions, unknowns, and exclusions;
- cancellation and recovery state;
- timestamps and resource accounting.

## State that does not belong in a Run

A Run does not own as identity or canonical state:

- BEAM or operating-system process identifiers;
- provider request identifiers;
- branch, commit, or worktree identity;
- complete Artifact content;
- complete Tool catalogs;
- full provider-specific prompts;
- hidden model reasoning;
- client-local selection, scroll, cursor, layout, or draft state.

## Conversation relationship

Conversation messages are ordered interaction records associated with a Run.

Conversation history can help the user inspect work. It does not become the canonical:

- objective;
- criteria;
- authority;
- mutation state;
- Evidence state;
- recovery state;
- completion state.

A new model invocation receives a bounded Context package assembled from authoritative current state and selected records. Kiln does not recover by asking a model to summarize the complete transcript.

# OTP process rule

Logical Run lineage and runtime supervision are separate relationships.

A Run is durable data. It does not receive a dedicated process merely because it is active.

A process is justified only when it owns:

- a live Resource;
- concurrent advancement;
- timing;
- cancellation;
- streaming;
- subscriptions;
- external communication;
- fault isolation.

## First-month runtime ownership

```text
Kiln.Application
└── Kiln.ExecutionSupervisor
    ├── transient model invocation Worker
    └── transient Command Worker
```

The selected SQLite library can own its connection process or pool.

The first month does not require:

- `Kiln.RunSupervisor`;
- one Root Run process;
- `Kiln.SessionRuntime`;
- a Task process;
- a Capability broker process;
- a Context compiler process;
- an Evidence or Receipt process;
- an Attention process;
- an event publisher process.

Pure modules and persisted records own deterministic rules and durable state.

## Adjacent runtime ownership

A Session coordinator becomes justified only when one background Child requires:

- scheduling;
- Worker lease ownership;
- timers;
- Attention routing;
- result delivery;
- live subscriptions.

An event publisher becomes justified only when more than one live Client or a TUI requires ordered publication and backpressure.

OTP supervision restores live process structure. SQLite state and current Repository observations restore durable work truth.

# Model invocation, Worker, Tool, and Command

## Agent

An Agent is a versioned execution definition when Kiln later needs reusable model policy, instructions, output contracts, and Tool strategy.

The first month can use one fixed Root Run model profile without a general Agent catalog.

Agent is data. It does not own Run state or authority.

## Worker

A Worker is a transient executor with a bounded lease to advance one Run operation.

A Worker can die and be replaced without changing Run identity.

Do not persist Worker runtime handles as domain identity.

## Model invocation

A model invocation is one provider request and response stream owned by a Run.

It receives one immutable Context package, explicit limits, and a fixed Tool projection.

A model invocation cannot mark a Task, Run, or Session complete by itself.

## Tool call

A Tool call performs one bounded Kiln-native operation inside a Run.

One deterministic Tool call does not become a Child Run.

## Command

A Command is one registered external-process execution owned by a Run.

A Command can require a transient Worker because it owns a process tree, timeout, cancellation, output capture, and cleanup.

Command identity does not become Run identity.

# Child Runs

Child Runs are **Important Next**, not required for the first useful version.

Version 0.1 can add two depth-one role contracts:

```text
Root Run
├── Scout Child
└── Verifier Child
```

Only one Child can be active at a time in version 0.1.

## Why create a Child

Create a Child only when work needs independent:

- purpose and result contract;
- Context;
- authority and limits;
- cancellation;
- Evidence and Artifacts;
- resource accounting;
- background visibility;
- verification independence;
- durable result delivery.

Do not create a Child to:

- wrap one deterministic operation;
- rename a Tool call;
- add a persona;
- simulate an organization;
- hide slow work;
- bypass Context or permission limits.

## Child creation authority

The Root Run can request a Child.

A deterministic application service validates:

- accepted purpose;
- role;
- Parent and Root relationship;
- depth;
- active-Child limit;
- Context inputs;
- requested authority;
- output contract;
- resource limits.

A Child cannot create, authorize, or request a descendant in version 0.1.

## Version 0.1 limits

```text
Maximum Child depth:          1
Maximum active Child Runs:    1 per Session
Nested delegation:            disabled
Peer communication:           disabled
Shared mutable Context:       disabled
Writing Child:                disabled
Child permission expansion:   disabled
```

The earlier depth-two and three-active-Child planning limits are superseded for version 0.1 by this narrower scope.

Expansion requires dogfood Evidence and an accepted roadmap change.

## Parent relationship

A Parent Run:

- records why the Child exists;
- exposes Child status and current bounded activity;
- can request cancellation when authorized;
- receives one bounded structured result;
- does not inherit or transfer ambient authority;
- does not supervise the Child process because of lineage.

Parent is a relationship role, not an entity or Agent persona.

## Child authority

Effective Child authority is the intersection of:

```text
Workspace maximum
∩ Project policy
∩ Repository role and path scope
∩ Session limits
∩ Parent maximum
∩ Child role profile
∩ explicit Child grant
∩ current Approval when required
```

The Child can only receive equal or narrower authority.

The Child receives no ambient:

- Parent transcript;
- Tool schemas;
- Skill body;
- write scope;
- secrets;
- network destinations;
- provider cache;
- sibling state.

## Scout Child

A Scout investigates the active Repository through read-only Tools and returns:

- observed facts with Evidence references;
- inferences;
- assumptions;
- unknowns;
- scope and freshness limits;
- optional advisory next action.

A Scout cannot modify source, Git, dependencies, configuration, policy, or permissions.

## Verifier Child

A Verifier evaluates accepted criteria against exact current state.

A Verifier:

- receives independently compiled Context;
- treats the authoring conclusion as a Claim;
- receives no write or Patch Tool;
- cannot repair the implementation;
- returns `PASS`, `FAIL`, or `BLOCKED`;
- requires reproduced current Evidence for `PASS`.

A completed Verifier Run can carry any of the three outcomes. Run completion does not imply verification passed.

## Background and foreground

Foreground and background are interaction modes. They do not change identity, authority, durability, or accounting.

A background Child does not change client focus. It remains visible from Root status and the Run list.

Background never means hidden.

## Attention

A Child that requires user input, permission, conflict resolution, or failure handling creates Root-visible Attention.

A permission request is not a grant.

No Child can remain silently blocked.

## Cancellation

Canceling a Child targets its Worker and owned external effects.

It does not cancel the Root automatically.

Unknown effects produce `orphaned`, not `canceled`.

## Result delivery

A Child returns one bounded structured result with:

- role outcome;
- summary;
- Evidence and Artifact references;
- accounting;
- failures;
- warnings;
- assumptions;
- unknowns.

Delivery is durable and idempotent.

The Parent does not receive a copied Child transcript or full Context.

# Navigation

The CLI is sufficient for version 0.1.

Required later Child actions are:

- list Runs;
- inspect Child;
- enter Child view;
- return to Root;
- answer or deny Attention;
- cancel Child;
- inspect result and Evidence.

Navigation changes client-local focus only. It cannot pause, cancel, approve, mutate, grant, or accept work implicitly.

The TUI is deferred until real Child navigation exists and the CLI command and projection surface is stable.

# Writing isolation

The first-month Root Run is the only mutation owner in one selected writable checkout.

There is no concurrent writer and no managed worktree requirement.

Scout and Verifier Children are read-only.

A later writing Child can propose an immutable Patch Artifact. The Root or another authorized applying Run owns application and verification.

No Child owns a shared writable checkout in version 0.1.

# Recovery

After restart, Kiln reconstructs:

- Session, Task, Root, and Child relationships;
- last durable Run state and current workflow step;
- objective and criteria revisions;
- policy, Context, and grant references;
- model and Command operation state;
- Patch proposal and application state;
- unresolved Attention;
- Artifacts, Claims, Evidence, and Receipts;
- pending Child result delivery;
- cancellation and orphan state.

Recovery never converts interruption, failure, cancellation, or unknown effects into success.

A replacement Worker cannot repeat an uncertain mutation or external effect without explicit reconciliation and a new idempotency decision.

# Foundational rule

Run is Kiln's durable work identity.

Processes, models, Agents, Tools, Commands, branches, worktrees, protocols, interfaces, and transcripts operate within or around a Run. None replaces Run identity, authority, Evidence, or recovery state.
