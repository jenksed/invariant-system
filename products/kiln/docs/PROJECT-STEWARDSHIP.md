# Project Stewardship

**Document type:** Supporting explanation  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Run authority:** `docs/RUN-MODEL.md`  
**Delegation authority:** `docs/DELEGATED-WORK.md`

## Definition

Project Stewardship is Kiln's constrained delivery-integrity responsibility for one Session.

The Root Run carries this responsibility by default.

The responsibility is not:

- an autonomous manager persona;
- a permanent Agent;
- an organizational hierarchy;
- a separate source of policy, Repository truth, Evidence, or acceptance;
- a reason to create Child Runs.

The user retains final authority.

## Purpose

The Steward maintains a coherent relationship between:

```text
accepted objective and criteria
→ current Repository state
→ Task and Run activity
→ authority and Context
→ proposed and applied change
→ Commands and results
→ Evidence
→ user acceptance and completion
```

Kiln should be able to show:

- which objective and criteria govern the Session;
- which Repository state was inspected and changed;
- what the model proposed;
- which user decisions authorized effects;
- which Commands ran;
- which Evidence supports or blocks each criterion;
- what failures, warnings, and unknown effects remain;
- why the Session is or is not ready for acceptance.

## Initial single-Run responsibility

The first useful Kiln has one Root Run and no Child Runs.

The Root Run directly coordinates:

- orientation to Project and Repository state;
- bounded model investigation;
- Patch proposal inspection;
- explicit user Approval;
- controlled Patch application;
- registered verification;
- Evidence reconciliation;
- completion readiness;
- restart and orphan recovery.

Project Stewardship therefore does not require a Run graph, scheduler, manager Agent, or Session process in the first month.

## Adjacent delegated responsibility

Version 0.1 can add:

```text
Session objective
└── Root Run: delivery-integrity responsibility
    ├── one read-only Scout Child when active
    └── one independent Verifier Child when active
```

Only one Child can be active at a time.

The Root Run can request a Child when independent Context, authority, cancellation, Evidence, background visibility, or verification creates concrete value.

The Root cannot create nested management layers in version 0.1.

## Steward actions

The Steward responsibility can:

- preserve the accepted objective and criteria revisions;
- identify current Repository state and freshness;
- choose direct execution before delegation;
- request one bounded Child under accepted limits;
- request explicit authority and user decisions;
- identify blockers, conflicts, failures, and unknown effects;
- request deterministic verification;
- later request independent Verifier evaluation;
- compare Claims with current Evidence;
- block completion readiness when required proof is missing;
- propose the next action;
- produce a final reconciliation summary.

## Steward limits

The Steward responsibility cannot:

- override user authority;
- change objective or criteria without an accepted revision;
- grant itself, the Root, or a Child authority;
- bypass Repository, Privacy, Context, Command, Patch, or security policy;
- treat process isolation as operating-system containment;
- change Git or filesystem truth through narrative;
- apply a model Patch without exact user Approval;
- turn exit zero into criterion `PASS` without evaluation;
- mark stale, blocked, contradictory, or missing Evidence as current;
- hide failure or orphan state;
- allow concurrent writers in one checkout;
- create delegation to imitate an organization;
- treat Child count as a product measure;
- accept its own completion recommendation;
- report completion while required Evidence or user decisions remain unresolved.

Deterministic systems remain authoritative for:

- Repository observations;
- journal ordering;
- transition validity;
- authority decisions;
- Context manifests;
- Patch application state;
- Command execution state;
- Evidence freshness;
- acceptance status;
- cancellation and recovery state.

The Steward interprets those facts. It cannot rewrite them.

## Stewardship loop

```text
record objective and criteria
→ observe current Repository state
→ identify the next uncertainty or change
→ execute directly or later request one bounded Child
→ inspect Claims, effects, and Evidence
→ surface failures and unknowns
→ verify exact current state
→ reconcile criteria and Evidence
→ continue, block, or recommend user acceptance
```

## Establish objective

Record:

- requested outcome;
- accepted criteria;
- constraints;
- explicit exclusions;
- applicable ADRs and invariants;
- required verification and acceptance.

A material specification gap remains an Unknown. The Steward does not invent a requirement.

## Orient

Establish the smallest sufficient current information for the next action:

- Project and Repository identity;
- branch, commit, and dirty state;
- accepted active instructions;
- objective and criteria revision;
- verification entry point;
- prior incomplete or orphaned work;
- current Evidence and freshness.

Orientation remains bounded and inspectable. It does not load the complete transcript or Repository by default.

## Select work

Prefer:

- deterministic observation before model speculation;
- the cheapest reliable test of an unknown;
- direct Root execution when another Run adds no value;
- one bounded Patch over broad mutation;
- one registered Command over arbitrary shell;
- current machine-readable Evidence over summary;
- user Approval for exact effects;
- omission over speculative infrastructure.

## Delegate when useful

After the single-Run workflow works, request a Child when the Task benefits from:

- independent Context;
- narrower authority;
- read-only background investigation;
- independent cancellation;
- independent Evidence and accounting;
- independent verification.

Every delegated Task creates a Child before delegated execution.

The Root supplies:

- accepted purpose;
- required inputs;
- independent Context policy;
- requested grants and limits;
- result contract;
- foreground or background mode;
- cancellation and timeout policy;
- Evidence requirements;
- delivery target.

The Child receives no full Root transcript, ambient Tools, secrets, write scope, or ability to create descendants.

## Maintain traceability

Maintain:

```text
Objective
→ criteria
→ Task
→ Run
→ Context and authority
→ Claim or effect
→ Artifact and Evidence
→ verification
→ acceptance and completion
```

The current projection identifies:

- criteria without current Evidence;
- proposed change without Approval;
- applied change without verification;
- failed, blocked, stale, contradictory, or orphaned results;
- pending user decisions;
- later Child state and undelivered results;
- accepted exclusions.

## Reconcile

Before completion, compare:

- current user instruction;
- accepted objective and criteria;
- current Repository state;
- proposed and applied Patch;
- Commands and cleanup state;
- current Evidence by criterion;
- failures, warnings, unknowns, and exclusions;
- later Child and Attention state;
- required user acceptance.

Explain every material divergence.

## Completion recommendation

The Root Run can recommend completion only when:

- the accepted change is the observed Repository state;
- every required criterion has current passing Evidence;
- no required operation is blocked or orphaned;
- no unknown effect remains;
- all required user decisions are recorded;
- the user can inspect the bounded Receipt and retained Artifacts.

The user retains final acceptance authority.

## Product measures

Useful measures include:

- elapsed time from accepted intent to accepted verified result;
- number of unsupported completion attempts blocked;
- repeated orientation avoided after restart;
- stale Evidence detected before acceptance;
- unknown effects surfaced rather than hidden;
- Context and Tool-schema cost per accepted change;
- Child Run value when delegation enters scope.

Do not use Agent count, Run count, process count, Tool count, or token use alone as product-success measures.

## Non-goals

Project Stewardship does not require:

- a manager Agent;
- recursive delegation;
- a company simulation;
- a separate Root Task;
- one process per Run;
- automatic acceptance;
- automatic product decisions;
- hidden final reconciliation;
- permanent role personas.
