# Run Model

**Document type:** Reference  
**Status:** Foundational direction  
**Internal-domain authority:** `docs/INTERNAL-DOMAIN-MODEL.md`  
**Delegation authority:** `docs/DELEGATED-WORK.md`

A Run is one independently inspectable execution or coordination attempt for one Task inside a Kiln Session.

The Run is Kiln's primary durable execution unit.

## Required properties

A Run must be independently:

- identifiable;
- inspectable;
- interruptible;
- resumable when recovery is valid;
- measurable;
- permission-scoped;
- Context-scoped;
- Evidence-producing;
- cancellable.

A Run can be model-backed, deterministic, command-oriented, human-steered, verification-focused, or coordination-focused.

## Domain hierarchy

```text
Workspace
└── Project
    └── Session
        ├── Task
        │   ├── Run
        │   └── later Run attempt
        └── Root Task
            └── Root Run
                ├── Scout Run
                ├── Verifier Run
                └── Child Run
                    └── nested Child Run
```

This hierarchy represents ownership and logical work lineage. It does not represent an organization chart, Git branch graph, or OTP supervision tree.

## Task and Run

A Task states one bounded desired outcome or decision.

A Run is one execution or coordination attempt for that Task.

Every Run references exactly one Task.

One Task can have several Runs because:

- an earlier Run failed or was canceled;
- Evidence became stale;
- a different approach is required;
- independent verification requires a separate Run;
- concurrent read-only investigation uses bounded Child Runs.

A completed Run does not automatically satisfy its Task. Task satisfaction is derived from accepted criteria and current Evidence.

## Run identity

A Run has a Kiln-generated `run_id`.

Run identity must not use:

- Agent or role name;
- model or provider name;
- provider request ID;
- protocol task, thread, or session ID;
- Worker identity;
- BEAM PID or reference;
- operating-system PID;
- Tool call, Command, or Terminal ID;
- Git branch, commit, or worktree ID.

Run identity survives every Worker, process, model invocation, client, adapter connection, and restart.

## Run roles and relationships

### Root Run

Each Session has exactly one Root Run.

The Root Run:

- references the Session root Task;
- has no Parent Run;
- references itself as `root_run_id`;
- owns the Session control projection;
- carries Project Steward responsibility by default.

Root is a relationship role and invariant. It does not require a separate entity, table, struct, or process type.

### Parent Run

A Parent Run is the Run referenced by a Child Run's `parent_run_id`.

The Parent:

- records why the Child exists;
- exposes the Child in its projection;
- receives a bounded structured result;
- can request interruption or Attention routing when authorized;
- does not transfer ambient authority or Context;
- does not supervise the Child process because of lineage.

Parent is a relationship role, not a separate entity or Agent persona.

### Child Run

Every delegated Task creates a Child Run before delegated execution starts.

Create a Child Run when work needs independent:

- inspection or steering;
- Context;
- Capability grants;
- token, cost, time, or Resource accounting;
- Artifacts, Claims, or Evidence;
- cancellation;
- durable history or recovery;
- structured result delivery.

A Child Run is not an opaque Tool call, hidden transcript, uninspectable subprocess, copied result, or organizational subordinate.

A Child inherits neither the Parent transcript nor ambient authority.

### Sibling and nested Runs

Sibling Runs can execute concurrently when policy and Session limits permit. They cannot communicate peer to peer or share mutable Context.

A Child at depth one can propose one nested delegation. An authorized control service creates the nested Run. A Child cannot authorize or create a descendant directly.

A Child at depth two cannot delegate further.

The initial product supports a maximum Child depth of two and a maximum of three active Children per Session.

## Initial delegated role contracts

Kiln initially supports two first-class Child role contracts.

### Scout

A Scout investigates code, documentation, runtime state, tests, or approved prior Project patterns.

A Scout is read-only and returns:

- observed facts with Evidence references;
- inferences;
- assumptions;
- unknowns;
- scope and freshness limitations;
- optional advisory next action.

A Scout cannot modify source, install dependencies, mutate Git, change configuration, expand permissions, or report inference as observation.

### Verifier

A Verifier independently evaluates requirements, Change sets, execution results, and Evidence.

A Verifier:

- uses independently compiled Context;
- treats the authoring Run's conclusion as a Claim;
- receives no write Tools in its initial profile;
- cannot repair the implementation it evaluates;
- returns `PASS`, `FAIL`, or `BLOCKED`;
- must provide reproduced Evidence for `PASS`.

A Verifier Run can be `completed` with any role outcome. Run completion means that the required Verifier result was delivered. It does not mean that the implementation passed.

Additional repeated procedures normally become Skills rather than permanent role personas.

See `docs/DELEGATED-WORK.md` for the complete Scout and Verifier contracts.

## Agent, Worker, and model invocation

### Agent

An Agent is a versioned execution definition.

It can define instruction Artifacts, model-selection policy, Skill bindings, result schemas, and Tool-use strategy.

An Agent is data. It does not own Run state, Capability grants, policy, or completion readiness.

### Worker

A Worker is a transient executor with a bounded lease to advance one Run.

A Worker process can die and be replaced without changing Run identity.

Do not persist Worker runtime handles. Record lease, heartbeat, handoff, crash, and termination events when material.

The initial default is one active Worker lease per Run.

### Model invocation

A model invocation is one provider request and response stream owned by a Run.

A Run can contain zero, one, or many model invocations.

A model invocation:

- uses one immutable Context manifest;
- uses one Agent binding snapshot when present;
- can request Tool calls;
- records normalized events, usage, output, failure, and cancellation;
- cannot mark the Task, Run, or Session complete by itself.

## Required Run data

A Run has or references:

```elixir
%Kiln.Run{
  id: run_id,
  session_id: session_id,
  task_id: task_id,
  root_run_id: root_run_id,
  parent_run_id: parent_run_id,
  status: status,
  context_manifest_id: context_manifest_id,
  agent_binding: agent_binding,
  limits: limits,
  created_at: created_at,
  updated_at: updated_at
}
```

The exact Elixir type remains provisional.

Each Run also owns or references:

- accepted Task and criteria revisions;
- delegation-contract revision when it is a Child;
- Context manifests;
- Agent and role binding when present;
- Worker leases;
- model invocations, Tool calls, Commands, and Terminals;
- requested Capabilities and active grants;
- Attention, cancellation, and timeout state;
- Artifacts, Change sets, Claims, Evidence, Receipts, and Checkpoints;
- token, cost, time, Command, Artifact, and Resource accounting;
- failures, warnings, assumptions, unknowns, and exclusions;
- structured result and delivery state.

## Run lifecycle

Kiln uses these states:

```text
created
queued
starting
running
waiting_for_tool
waiting_for_command
waiting_for_child
waiting_for_user
waiting_for_permission
paused
verifying
completed
failed
canceled
orphaned
stale
```

Every transition records the Run, previous and next state, reason, actor or causation, event time, recorded sequence, and related Worker, execution, Child, Attention, timeout, cancellation, or Evidence references.

A Run cannot enter `waiting_for_user` or `waiting_for_permission` without an open blocking Attention item in the same durable transaction.

`completed`, `failed`, `canceled`, and `stale` are terminal for one Run attempt.

`orphaned` is a non-success recovery state. It means that Kiln cannot determine execution state or effects. It can leave `orphaned` only after explicit reconciliation.

A canceled, failed, or stale attempt does not resume. A new attempt requires a new Run.

The complete transition table and required evidence are in `docs/DELEGATED-WORK.md`.

## Run lineage and OTP supervision

Logical lineage and runtime supervision are separate relationships.

```text
Logical Run graph

Root Run
├── Scout Run
├── Verifier Run
└── Child Run
    └── nested Child Run
```

```text
Possible runtime supervision

Kiln.RunSupervisor
├── active Root Run process
├── active Scout Run process
├── active Verifier Run process
└── active nested Run process
```

`parent_run_id` defines work lineage, navigation, result delivery, and coordination.

OTP supervision defines process startup, restart policy, termination, and fault containment.

A Parent process crash does not erase or automatically cancel Child Runs. A Child process crash does not corrupt Parent state. The event journal restores durable Run state. OTP restores active process structure.

## Foreground and background delegation

Foreground and background are interaction modes. They do not change Run identity, authority, accounting, or durability.

A foreground Child is likely to need immediate user steering. Client focus changes only when the user or client accepts the change.

A background Child does not change client focus. It remains visible through the Run graph, Parent projection, global Attention, accounting, events, and result delivery.

Background must not mean hidden.

## Client-local focus

The Session stores the shared Run graph. Each connected Client owns its focused Run.

A focus change does not:

- pause a Run;
- alter another Client's focus;
- change the Root Run;
- reassign authority;
- change scheduling or execution state;
- resolve Attention.

## Parent projection and Child result

A Parent projection includes:

- Child Task and role;
- status and current activity;
- elapsed time and accounting;
- effective-authority summary;
- Attention state;
- Artifact and Evidence counts;
- structured result when available.

The Parent does not receive a copied Child transcript or full Context.

Child result delivery is durable and idempotent. The bounded delivery envelope contains role outcome, summary, references, accounting, failures, warnings, assumptions, and unknowns.

If a Parent process is unavailable, delivery remains pending. If a Parent Run is terminal, material delivery routes to the Root Run and creates Attention when it affects active work.

## Context and authority

Each Run has one current immutable Context manifest. A later package creates a new manifest.

A Child receives the minimum required inputs in an independently compiled Context. It does not receive the Parent transcript, Tool schemas, Skill body, or working set by default.

Each Child receives explicit Capability grants and limits.

A Parent can request a Child grant. Policy and an authorized actor decide it. A Child cannot expand or issue authority.

Effective authority is the intersection of availability, Workspace limits, Project Repository trust, Privacy policy, Session limits, the active Run grant, and Resource scope.

## Tools, Commands, and delegation

A Tool call performs one Kiln-native operation inside a Run.

A Tool call does not automatically become a Child Run.

Use a Child Run only when the work needs independent execution properties. Use direct deterministic operations or Skills when a separate Run adds no value.

A Run enters `waiting_for_command` while it waits for a supervised Command whose completion is required to advance the Run.

## Attention and interruption

Any Run can raise global Attention for:

- questions;
- permission requests;
- conflicts;
- failures;
- verification blockers;
- merge blockers;
- Resource limits;
- stale Evidence.

Attention routing is depth-independent.

The user can answer directly, enter the originating Run, route to the Parent, deny, pause, or cancel.

No Child can remain silently blocked.

Pause can be resumable. Cancel is terminal when effects are reconciled. Unknown effects produce `orphaned`, not `canceled`.

See `docs/DELEGATED-WORK.md` for Attention, cancellation, timeout, crash, and orphan contracts.

## Writing isolation

Kiln does not allow multiple writing Runs to mutate one checkout concurrently.

The initial delegated roles are read-only. No initial Scout or Verifier owns a writable worktree or authors a Patch Artifact.

`docs/GIT-CHANGE-ISOLATION.md` defines worktree and Patch Artifact isolation for later accepted writing roles.

## Initial delegation limits

```text
Maximum Child depth:          2
Maximum active Children:      3 per Session
Default Child authority:      read-only grants
Initial Child roles:          Scout and Verifier
Peer communication:           disabled
Shared mutable Context:       disabled
Default writing Children:     disabled
Default active Workers:       1 per Run
```

These limits are provisional until dogfooding produces Evidence.

## Recovery

After restart, Kiln reconstructs:

- the Run graph and Task relationships;
- each Run's last durable state and transition evidence;
- role, Agent, Context, authority, limits, and accounting;
- Worker lease, crash, and orphan status;
- unresolved Attention, cancellation, and timeout records;
- Artifacts, Claims, Evidence, Receipts, and Checkpoints;
- pending Child results and delivery state;
- interrupted executions;
- client-independent Session state.

Recovery does not transform interruption, failure, or unknown effects into success.

A replacement Worker cannot repeat a mutation or external effect without an idempotency decision.

## Interface requirements

CLI, TUI, Phoenix, headless, and adapter Clients use the same Run commands and queries.

Required commands include creating Child Task and Run, requesting grants, starting work, steering, pausing, resuming, canceling, resolving Attention, setting client focus, returning Child results, and recording Evidence.

Required queries include Run ancestry and descendants, status, activity, Context, grants, accounting, Attention, Artifacts, Evidence, traces, results, and completion readiness.

## Non-goals

The initial Run model does not require:

- unlimited recursive delegation;
- peer-to-peer Child communication;
- Agent-manager hierarchies;
- shared mutable model Context;
- writing Scout or Verifier roles;
- automatic product decisions;
- automatic permission expansion;
- hidden background work;
- a process or table for every noun;
- an external Agent protocol as the internal model.

## Foundational rule

A delegated Task creates a first-class Run.

The Run remains the durable work identity across Agents, Workers, model invocations, Tools, Commands, processes, clients, adapters, branches, interruption, cancellation, recovery, accounting, and Evidence production.
