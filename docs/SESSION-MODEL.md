# Session Model

**Document type:** Session and Task subject summary  
**Decision status:** Accepted  
**Integration status:** Reconciled by Prompt 8-A  
**Implementation status:** P1-S01 integrated at `db02198` via PR #46  
**Focused lifecycle authority:** `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`

## Definition

A Session is one durable attempt to move one accepted Project objective toward verified and user-accepted completion.

A Session is the objective and continuity boundary. It is not a provider conversation, terminal, protocol session, branch, worktree, or process.

This document summarizes the accepted first-month model. P0-W21 controls exact persisted state, transitions, journal, restart, orphan, and completion behavior.

## First useful hierarchy

```text
Project
└── Session: one accepted objective and complete Kiln work history
    └── initial Task: one desired outcome with criteria
        └── Root Run: one attempt or coordination boundary
```

The first product does not create a separate Root Task.

The user accepts the objective, criteria, constraints, and exclusions before Session creation. The atomic start transaction creates:

- Session in `active`;
- initial Task in `in_progress`;
- Root Run in `ready`.

## Session ownership

A first-month Session belongs to one Project and references one active Repository.

It owns or references:

- accepted objective and criteria revisions;
- one initial Task;
- exactly one Root Run;
- journal sequence and current projection;
- user decisions;
- external-operation intents and observations;
- policy and authority snapshots;
- Context, provider, Tool, Patch, Command, Artifact, and Evidence references only after their subsystems are authorized;
- interruption, orphan, and recovery state;
- final outcome and post-completion Receipt reference.

## Identity

Kiln generates `session_id`.

Session identity must not use:

- provider conversation or request ID;
- client thread ID;
- terminal ID;
- protocol session ID;
- branch or worktree ID;
- BEAM or operating-system process ID.

## First-month Session states

```text
active
completed
abandoned
```

### `active`

The Session can contain current work, a pending decision, an active or unknown operation, or an orphaned Root Run.

Waiting, verification, interruption, operation, and Evidence facts do not become Session states.

### `completed`

The atomic completion transaction proved:

- the initial Task is satisfied;
- the Root Run is completed;
- all required Evidence is current and passing;
- no unknown effect or blocking decision remains;
- user acceptance is recorded;
- the accepted proof reference is current.

### `abandoned`

The first-month one-attempt Session will not continue after a terminal failed or canceled Root Run.

Abandonment does not delete the journal, Artifacts, Evidence, or recovery records.

`created` and `archived` are not first-month persisted Session states.

## First-month Task states

```text
in_progress
satisfied
abandoned
```

### `in_progress`

The accepted initial Task is active from the Session start transaction.

### `satisfied`

Only the accepted completion transaction can satisfy the Task.

### `abandoned`

The first-month Session ends without satisfaction after a known terminal failed or canceled Root Run.

Proposed, accepted, ready, blocked, rejected, and superseded are not first-month Task states. A blocked criterion or operation is a workflow or proof fact, not Task status.

A completed Run does not satisfy a Task through status alone.

## Root Run relationship

Each first-month Session has exactly one Root Run.

The Root Run:

- references the initial Task;
- has no Parent;
- provides the primary work-control projection;
- remains subject to Project policy, explicit authority, user Approvals, Evidence gates, and completion rules;
- survives application and Worker restart without changing identity.

Exact Run states and transitions are defined by P0-W21 and summarized in `docs/RUN-MODEL.md`.

## Durable state and transcript separation

The Session journal records accepted work facts and material external-effect boundaries.

Transcript records preserve interaction history but do not own:

- objective or criteria truth;
- Task satisfaction;
- Run status;
- authority;
- Patch application state;
- Evidence freshness;
- user acceptance;
- completion.

Kiln reconstructs continuity from durable state and exact Repository observations. It does not ask a model to infer current state from the full transcript.

## Workflow

The accepted first-month workflow steps are:

```text
intent
investigation
proposal
approval
application
verification
acceptance
reconciliation
```

These are workflow steps. They are not Session states, Run states, Agent personas, required model turns, or protocol states.

P1-S01 implements only the foundation required for durable intent, status, cancellation, restart, and recovery truth. Later subsystems remain unreachable until separately authorized.

## Current projection

The Session projection can include:

- objective and criteria revision;
- Session, Task, and Root Run state;
- workflow step;
- pending user decision;
- external-operation state;
- Repository observation;
- policy and authority references;
- Patch and Command state when authorized;
- Artifact, Evidence, warnings, unknowns, and completion readiness when authorized.

The projection is rebuildable. It is not source truth for Git, policy, Evidence content, or user decisions.

## Journal and restart

The append-oriented journal exists for:

- durable sequence and revision;
- restart recovery;
- ordered audit;
- projection rebuild;
- duplicate-effect prevention;
- explicit unknown-effect reconciliation.

It does not record every model token, complete Artifact payload, UI movement, static documentation, or code-index fact.

After restart, Kiln reconstructs accepted Session, Task, Root Run, decisions, operations, warnings, and projection state. It re-observes Git and filesystem state before a later mutation, verification, or completion action.

Unknown effects remain orphaned until explicit reconciliation. Kiln does not repeat them automatically.

## Initial limits

During the authorized P1-S01 foundation:

- one active Project;
- one active Repository;
- one Session in the foreground CLI action;
- one initial Task;
- one Root Run;
- no provider invocation;
- no Repository source disclosure;
- no source mutation;
- no external Command;
- no product completion Receipt;
- no Child Runs;
- CLI only.

Wave B can later consider one active depth-one read-only Child only after the Single-Run Alpha produces accepted runtime Evidence and P0-W26 through Prompt 8-B complete.

## Product Receipt

A product Receipt is not a Session creation or ticket-closeout record.

After the accepted completion transaction, P0-W24 can seal a non-authoritative Receipt from immutable references. Receipt failure affects delivery, not the already committed completion fact.

Implementation-ticket closeout and P1-S01 aggregate proof use an implementation Evidence manifest or slice verification manifest, not a product Receipt.

## Non-goals

The first Session model does not require:

- conversation identity as Session identity;
- a process per Session;
- one table per noun;
- a Root Task concept;
- a general workflow engine;
- recursive Agent management;
- multi-user collaboration;
- remote Session ownership;
- full event sourcing of every subsystem.
