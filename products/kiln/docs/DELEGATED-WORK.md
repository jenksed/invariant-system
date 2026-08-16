# Delegated Work Model

**Document type:** Delegation subject authority  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Not implemented  
**Run authority:** `docs/RUN-MODEL.md`

## Purpose

This document defines the first justified delegated workflows after the single-Run change loop works.

Kiln does not optimize for the number of Agents or Runs.

A Child Run exists only when a separate durable boundary improves:

- Context isolation;
- authority control;
- cancellation;
- Evidence;
- result delivery;
- background visibility;
- independent verification.

## Delivery position

Child Runs are not required for the first useful Kiln.

The first month uses one Root Run.

Version 0.1 can add:

```text
Root Run
├── one read-only Scout Child
└── one independent Verifier Child
```

Only one Child can be active at a time.

Nested delegation, multiple active Children, and writing Children remain disabled through version 0.1.

## Foundational distinctions

| Distinction | Rule |
| --- | --- |
| Delegated Task and Tool call | A delegated Task needs an independent durable boundary. A Tool call performs one bounded operation inside a Run. |
| Run and Agent | A Run owns durable work state. An Agent is optional versioned execution data. |
| Run and Worker | A Run survives restart. A Worker transiently advances one live operation. |
| Run lineage and OTP supervision | `parent_run_id` records logical work lineage. Supervision owns live process failure and restart. |
| Parent and Child authority | A Parent can request Child authority. A Child receives a separately evaluated equal or narrower grant. |
| Parent and Child Context | A Child receives a new bounded Context package. It does not inherit the Parent transcript or working set. |
| Background and hidden | Background does not change focus. It remains visible through Root status, Run listing, and Attention. |
| Completed Run and satisfied Task | A completed Child can return a result while the Parent Task remains unsatisfied. |
| Verifier `BLOCKED` and failure | `BLOCKED` is a valid completed Verifier result when required verification cannot run. |
| Artifact and result delivery | Artifacts remain stored independently. Delivery sends references and a bounded result, not copied transcripts. |

## When to create a Child

Create a Child when the work requires one or more independent properties:

- purpose and output contract;
- Context;
- Capability grants;
- token, cost, time, or Resource accounting;
- cancellation;
- foreground inspection;
- background progress;
- Artifacts or Evidence;
- verification independence;
- durable result delivery.

Do not create a Child only to:

- wrap one deterministic operation;
- rename a Tool call;
- add an Agent persona;
- imitate an engineering organization;
- hide slow work;
- bypass limits or permissions;
- increase visible activity.

Repeated procedures can later become Skills. A Skill does not create a Run or grant authority.

# Graph invariants

Each Session has exactly one Root Run.

Every Child has:

- one `run_id`;
- one `session_id` shared with Root and Parent;
- one `task_id`;
- one `root_run_id`;
- one `parent_run_id`;
- depth one in version 0.1;
- one immutable delegation-contract revision;
- one explicit role;
- one bounded purpose;
- one result contract;
- explicit limits and grants.

Version 0.1 limits:

```text
Root Run depth:                 0
Maximum Child depth:           1
Maximum active Child Runs:     1 per Session
Maximum active Worker leases:  1 per Run operation
Nested delegation:             disabled
Peer communication:            disabled
Shared mutable Context:        disabled
Writing Child:                 disabled
Child Git mutation:            disabled
```

The earlier depth-two and three-active-Child planning defaults are superseded for version 0.1.

## Creation

The Root Run requests a Child.

A deterministic application service validates:

- accepted purpose;
- role;
- Parent, Root, Session, and Task relationship;
- depth and active-Child limit;
- requested Context inputs;
- requested authority;
- provider and Tool profile;
- resource limits;
- result schema;
- cancellation and timeout policy.

The Child exists durably before delegated model, Tool, Command, or Worker execution begins.

A Child cannot create, authorize, or request a descendant in version 0.1.

## Root and Parent

The Root Run:

- owns the Session control projection;
- records why the Child exists;
- exposes Child status and bounded current activity;
- receives Root-visible Attention;
- can request cancellation when authorized;
- receives one bounded structured result;
- remains responsible for Task satisfaction and completion recommendation.

The Root does not supervise a Child process because of lineage.

The Root does not receive the Child's full transcript or Context by default.

# Delegation contract

Before execution, Kiln records an immutable contract with:

- Session, Task, Root, Parent, and Child identifiers;
- role and purpose;
- accepted input references;
- expected result shape;
- Context policy;
- effective-authority request;
- Tool and provider profile;
- token, step, time, Command, and Artifact limits;
- foreground or background mode;
- cancellation and timeout policy;
- Evidence requirements;
- delivery target;
- contract digest.

Changing purpose, role, authority, or result contract requires a new contract revision or new Child.

# Context and authority

A Child receives one independent Context package.

The package can include:

- accepted delegated purpose;
- relevant criteria;
- selected current Repository references;
- explicit role instructions;
- limits;
- output contract;
- permitted Tool schemas;
- existing Evidence needed for the delegated purpose.

The Child does not inherit ambient:

- Parent transcript;
- hidden prompt content;
- complete Tool catalog;
- Skill body;
- write scope;
- secrets;
- network destinations;
- provider cache;
- sibling state.

Effective Child authority is:

```text
Workspace maximum
∩ Project policy
∩ Repository role and path scope
∩ Session limits
∩ Root maximum
∩ Child role profile
∩ explicit Child grant
∩ current Approval when required
```

A Child cannot widen any upper-layer denial.

A permission request creates Attention. It does not create a grant.

# Scout Child

## Purpose

A Scout investigates one bounded Repository question through read-only operations.

## Inputs

- delegated question;
- accepted source scope;
- current Repository fingerprint;
- selected instructions and criteria;
- read-only Tool profile;
- limits and output contract.

## Authority

A Scout can receive:

- bounded Repository read;
- exact search;
- Artifact read when explicitly selected;
- one configured provider invocation.

A Scout cannot:

- modify source or Git;
- propose or apply a Patch in version 0.1;
- execute general Commands;
- install dependencies;
- change configuration;
- change policy or criteria;
- grant authority;
- create another Run.

## Result

A Scout returns:

- observations with Evidence references;
- inferences;
- assumptions;
- unknowns;
- scope, freshness, and completeness limits;
- optional advisory next action;
- Artifact references;
- resource accounting.

An inference or assumption cannot be labeled as observation.

# Verifier Child

## Purpose

A Verifier independently evaluates accepted criteria against exact current Repository and Environment state.

## Inputs

- criteria revision;
- exact Repository state;
- Patch and changed-region references;
- accepted verification methods;
- current Evidence relevant to freshness;
- read-only authority and registered Commands.

The initial package excludes:

- author confidence narrative;
- persuasive completion summary;
- write or Patch Tools;
- repair instructions;
- unrelated author transcript.

## Authority

A Verifier can receive:

- bounded Repository read;
- Artifact read;
- registered verification Commands;
- structured report ingestion.

A Verifier cannot:

- edit or repair source;
- apply a Patch;
- install dependencies;
- change configuration;
- change criteria;
- accept its own result;
- create another Run.

## Result

A Verifier returns:

- `PASS` with current reproduced Evidence for every required criterion;
- `FAIL` with reproduced defects and affected criteria;
- `BLOCKED` with the missing tool, access, Environment, state, or requirement information.

A Verifier Run can be completed with any result. Completion of the Run does not imply `PASS` or Task satisfaction.

# Foreground and background

Foreground and background are Client-interaction modes.

They do not change:

- Run identity;
- authority;
- durability;
- accounting;
- Evidence requirements.

## Foreground

Foreground mode can change CLI focus only after the user chooses to inspect or enter the Child.

## Background

Background mode does not change focus.

The Child remains visible through:

- Root status;
- Run listing;
- current activity summary;
- Attention;
- resource accounting;
- result delivery.

Background never means hidden.

# Attention

A Child can create Root-visible Attention for:

- question;
- permission request;
- conflict;
- failure;
- verification blocker;
- resource limit;
- orphan reconciliation;
- completion notification.

A blocking wait records:

- originating Child;
- category;
- requested decision;
- allowed responses;
- resume state;
- revision;
- creation time;
- escalation or cancellation policy.

No Child can remain silently blocked.

Generic activation cannot approve permission, mutation, cancellation, or acceptance.

# Cancellation and timeout

Cancellation is a durable user or accepted-policy decision.

Kiln targets the Child Worker and its owned model or Command operations.

Cancellation does not cancel the Root automatically.

Kiln records:

- request and issuer;
- target operations;
- termination attempts;
- cleanup observations;
- resulting Run and operation state;
- unknown effects.

Unknown effects produce `orphaned`, not `canceled` or `completed`.

A timeout follows the same evidence rules.

# Result delivery

Delivery is durable and idempotent.

The envelope contains:

- Child and Parent identifiers;
- role result;
- bounded summary;
- Evidence and Artifact references;
- failures, warnings, assumptions, and unknowns;
- accounting;
- contract and result digest;
- delivery sequence and status.

The Parent receives references and bounded data. It does not receive a copied transcript or full Context package.

A duplicate delivery has no duplicate effect.

# Navigation

Version 0.1 uses CLI actions:

- list Runs;
- inspect Child;
- enter Child view;
- return to Root;
- inspect Attention;
- answer or deny;
- cancel Child;
- inspect delivered result and Evidence.

Navigation changes client-local focus only.

Navigation cannot pause, cancel, approve, grant, mutate, verify, or accept implicitly.

A TUI is deferred until this CLI surface is stable and one real Child workflow proves value.

# Persistence and recovery

Durable records include:

- Child identity and contract;
- Parent and Root relationship;
- current status;
- Context and grant references;
- model and Command operation references;
- Attention;
- cancellation and timeout;
- Artifacts, Claims, Evidence, and result;
- delivery state;
- resource accounting.

Transient state includes:

- Worker PID or Port;
- provider socket;
- stream buffer;
- process-tree handle;
- subscription handle.

After restart, Kiln restores durable Child state and re-observes external effects.

A replacement Worker cannot repeat uncertain work automatically.

# Writing delegation

Writing Children are deferred beyond version 0.1.

A later accepted writing workflow can allow a read-only Child to return an immutable Patch Artifact.

The Root or another authorized applying Run owns:

- writable checkout or worktree;
- Patch inspection and Approval;
- application;
- rollback;
- formatting;
- verification.

No Child receives a shared writable checkout by default.

# Anti-theater rules

Kiln shall not:

- create permanent role hierarchies;
- create Children for every phase or Tool call;
- permit Child-created descendants in version 0.1;
- optimize for active Child count;
- treat Agent names as Run identity;
- allow peer-to-peer Child messaging;
- copy full transcripts between Runs;
- let delegation broaden permission;
- call hidden background model activity a Child Run after execution already started.

# Expansion triggers

Review the version 0.1 delegation limits only when dogfooding shows:

- one active Child blocks a valuable workflow;
- depth one cannot complete a measured delegated Task;
- a writing Child materially reduces completion time without weakening review;
- CLI inspection is insufficient for actual concurrent work;
- a new role has stable authority, input, output, and independence requirements.

A review must identify scope removed as well as added.
