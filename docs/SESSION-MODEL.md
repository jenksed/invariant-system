# Session Model

**Document type:** Session and Task subject authority  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Not implemented  
**Internal-domain authority:** `docs/INTERNAL-DOMAIN-MODEL.md`  
**Run authority:** `docs/RUN-MODEL.md`

## Definition

A Session is one durable attempt to move one accepted Project objective toward verified and user-accepted completion.

A Session is the objective and continuity boundary. It is not a provider conversation, terminal, protocol session, branch, or process.

## Initial hierarchy

```text
Project
└── Session: one accepted objective and complete Kiln work history
    └── Task: one desired outcome with criteria
        └── Root Run: one attempt or coordination boundary
```

The initial product does not create a separate Root Task.

The Session's initial Task represents the first accepted executable outcome for the objective. The Root Run attempts or coordinates that Task.

A later Session can contain additional Tasks when the accepted objective requires more than one bounded outcome.

## Session ownership

A Session belongs to one Project.

The initial Project has one active Repository, accepted instructions, disclosure policy, mutation policy, and one registered verification entry.

The Session owns or references:

- accepted objective revisions;
- criteria and exclusion revisions;
- Task records and dependencies when later required;
- exactly one Root Run;
- later Child Run relationships;
- journal sequence;
- current projections;
- policy and authority snapshots;
- Context package manifests;
- model, Tool, Patch, and Command references;
- Artifacts, Claims, Evidence, and Receipts;
- user decisions;
- interruption and recovery state;
- final outcome.

## Session identity

Kiln generates `session_id`.

Session identity must not use:

- provider conversation or request ID;
- client thread ID;
- terminal ID;
- protocol session ID;
- branch or worktree ID;
- BEAM or operating-system process ID.

## Session lifecycle

The minimum Session lifecycle is:

```text
created
→ active
→ completed | abandoned
→ archived
```

Interruption, waiting, cancellation, verification, failure, and orphan state belong primarily to Runs and owned operations.

A Session can remain `active` while its Root Run waits for user input, a Command, or recovery.

A Session becomes `completed` only when:

- its accepted objective and required Tasks are satisfied;
- required current Evidence exists;
- no unresolved blocking or unknown effect remains;
- required user acceptance occurs.

A Session can become `abandoned` without deleting its journal, Artifacts, or Evidence.

## Task model

A Task states one bounded desired outcome, decision, investigation, change, verification target, or reconciliation action.

A Task records:

- `task_id`;
- Session identity;
- statement and revision;
- criteria;
- constraints and exclusions;
- dependencies when present;
- status;
- related Runs;
- satisfaction, rejection, or supersession reason.

Minimum Task status:

```text
proposed
→ accepted
→ in_progress
→ satisfied | rejected | abandoned | superseded
```

Add `ready` and `blocked` only when more than one Task or dependency creates observable scheduling value.

Task status is not Run status.

A completed Run does not automatically satisfy its Task.

## Root Run

Each Session has exactly one Root Run.

The Root Run:

- references the initial Task;
- has no Parent;
- provides the primary work-control projection;
- can investigate and coordinate deterministic effects;
- can later request bounded Child Runs;
- remains subject to Project policy, explicit grants, user Approvals, and completion gates.

Replacing a Worker or restarting the application must not create a new Root Run identity.

## Child Runs

Child Runs are not required for the first useful product.

Version 0.1 can add one active depth-one Child at a time for:

- read-only Scout investigation;
- independent Verifier evaluation.

The Session records Child relationships, Attention, and result delivery. The hierarchy does not define OTP supervision.

Nested delegation and multiple active Children remain disabled through version 0.1.

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

## Conceptual workflow

```text
Intent
→ Investigation
→ Implementation
→ Verification
→ Completion
```

These are workflow stages. They are not Agent personas, mandatory model turns, Session states, or external protocol states.

## Project-control projection

The Session maintains a current projection for the developer and Root Run.

The projection can include:

- objective and criteria revision;
- Task status;
- Root and later Child Run status;
- current workflow step;
- pending user action;
- Repository state;
- policy and effective authority;
- Context package references;
- Patch proposal and application state;
- Commands and operation state;
- Artifacts, Claims, Evidence, and Receipts;
- failures, warnings, assumptions, unknowns, and exclusions;
- completion readiness.

The projection is not source truth for Git, policy, Evidence content, or user decisions. It is rebuilt from authoritative records and current observations.

## Event journal

The Session uses a bounded append-oriented journal because Kiln requires:

- restart recovery;
- ordered audit;
- projection rebuild;
- duplicate-effect prevention;
- later client resume;
- honest unknown-effect reconciliation.

The journal does not require:

- a distributed log;
- one event for every model token;
- complete Artifact payloads;
- every UI movement;
- static documentation records;
- code-index facts.

## Recovery

After restart, Kiln reconstructs:

- Session identity and lifecycle;
- objective and criteria revisions;
- Task state;
- Root and later Child relationships;
- current workflow and Run state;
- pending user decisions;
- model, Patch, and Command operation state;
- Artifacts, Evidence, and Receipts;
- cancellation and orphan state.

Kiln re-observes Git and filesystem state before mutation, verification, or completion.

Unknown effects remain orphaned until explicit reconciliation.

## Initial limits

Through the first month:

- one active Project;
- one active Repository;
- one active Session per CLI process;
- one initial Task;
- one Root Run;
- no Child Runs;
- CLI only.

Through version 0.1:

- one Root Run;
- maximum Child depth one;
- maximum one active Child;
- Scout and Verifier are the only Child roles;
- no writing Child;
- no nested delegation;
- no peer communication;
- no shared mutable Context.

## Non-goals

The Session model does not require:

- conversation identity as Session identity;
- a process per Session;
- one table for every noun;
- a Root Task concept;
- a general workflow engine;
- recursive Agent management;
- multi-user collaboration;
- remote Session ownership;
- full event sourcing of every subsystem.
