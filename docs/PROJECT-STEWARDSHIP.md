# Project Stewardship

**Document type:** Explanation  
**Status:** Foundational direction  
**Delegation authority:** `docs/DELEGATED-WORK.md`

The Project Steward is Kiln's Session-level delivery responsibility.

The Steward uses the Run graph, Repository Evidence, Capability policy, accepted specifications, Context state, Git ownership, and completion gates to move one objective toward a working, verified result.

The Steward is not an artificial manager persona. It is a constrained control role attached to the Root Run.

## Purpose

Project Stewardship protects delivery integrity while increasing development leverage.

Kiln must be able to show:

- which intent and specifications govern the work;
- how work was decomposed;
- which Runs performed each Task;
- which inputs, Context, grants, and limits each delegated Run received;
- which files and Artifacts changed;
- which verification evaluated the current Repository state;
- which risks, failures, blockers, and unknowns remain;
- why the Session is or is not ready for integration or completion.

The Steward should reduce repeated orientation, duplicated investigation, hidden delegation, specification drift, stale verification, silent blockers, unsupported completion claims, and user effort spent reconstructing Session state.

## Relationship to the Root Run

Each Session has exactly one Root Run.

The Root Run carries Project Steward responsibility by default.

```text
Session objective
└── Root Run: Project Steward responsibility
    ├── Scout Run
    ├── Verifier Run
    └── nested read-only Child Run when justified
```

The role describes responsibility. It does not require one fixed prompt persona or permanent model.

## Steward authority

The Steward may:

- maintain the active intent and completion contract;
- trace requirements to planned and completed work;
- decompose work into bounded Tasks and Runs;
- choose foreground or background delegation;
- request Capability grants for Child Runs;
- assign Resource, token, time, and cost limits;
- request pause or cancellation;
- route global Attention;
- request independent verification;
- compare implementation state with accepted specifications;
- identify stale Context and Evidence;
- propose the next highest-value action;
- block integration or completion recommendations when proof is missing;
- produce final reconciliation.

The Steward cannot grant itself or a Child new authority. Capability and Approval policy remains authoritative.

## Steward limits

The Steward must not:

- override user authority;
- change accepted product intent without disclosure and approval;
- bypass Capability, Repository trust, Privacy, Git ownership, or integration policy;
- treat BEAM isolation as operating-system containment;
- modify Repository truth through an unrecorded path;
- mark stale Evidence as current;
- hide failed or blocked verification;
- convert unknown state into success;
- allow concurrent writers in one checkout;
- create delegation only to simulate an organization;
- delegate final reconciliation to an opaque Child;
- treat Child count as a product-success metric;
- report completion while blocking Attention remains unresolved.

Deterministic systems remain authoritative for Repository fingerprints, Git state, event ordering, Capability decisions, Context bindings, Evidence freshness, acceptance status, Resource ceilings, cancellation status, and recovery state.

The Steward can interpret those facts. It cannot rewrite them through narrative.

## Stewardship loop

```text
Understand objective
→ establish specification and completion contract
→ orient to current Repository state
→ identify the next uncertainty or change
→ execute directly or delegate a bounded Run
→ observe results and mutations
→ update risks, unknowns, and traceability
→ independently verify current state
→ reconcile intent, changes, and Evidence
→ continue, block, integrate, or recommend completion
```

### Establish objective

Record:

- requested outcome;
- accepted constraints;
- explicit exclusions;
- applicable ADRs and invariants;
- completion criteria.

A material specification gap remains an `Unknown`. The Steward must not invent a requirement.

### Orient

Establish the smallest sufficient current Context for the next action, including Repository identity, branch, commit, dirty state, governing instructions, relevant specifications, verification entry points, and unresolved prior work.

Orientation facts require freshness and invalidation rules.

### Select work

Prefer:

- the cheapest reliable test of an unknown;
- deterministic inspection before model speculation;
- direct execution when delegation adds no value;
- one bounded change over broad mutation;
- independent verification for material Claims;
- Skills for repeated procedures.

### Delegate when useful

Create a Child Run when work benefits from:

- isolated Context;
- concurrent read-only investigation;
- specialized model or Tool access;
- independent review;
- independent Evidence and accounting;
- user steering;
- separate cancellation or recovery.

Every delegated Task creates a Child Run before execution.

The Steward provides:

- one accepted Task revision;
- bounded purpose and required inputs;
- independent Context policy;
- explicit Capability requests and grants;
- Resource and token limits;
- expected result schema;
- parent wait, cancellation, crash, and delivery policies;
- completion or return condition.

A Child does not receive the full Session or Parent transcript by default.

### Maintain delivery traceability

Maintain this relationship:

```text
Intent
→ requirement
→ Task and Run
→ Capability and Context
→ mutation or Artifact
→ verification
→ Evidence
→ integration and completion status
```

The delivery projection identifies:

- unassigned requirements;
- active and queued Runs;
- changes without accepted intent;
- criteria without current Evidence;
- failed or stale verification;
- unresolved Attention;
- pending Child results;
- accepted exclusions.

### Control quality

Use narrow mutation boundaries, explicit criteria, deterministic checks, independent verification, final diff inspection, exact-state Evidence, and disclosure of failures and unknowns.

Distinguish implemented, verified, inferred, proposed, blocked, and unknown behavior.

### Reconcile

Before integration or completion, compare:

- current user instruction;
- accepted specifications and ADRs;
- completed and active Runs;
- Repository mutations;
- current verification Evidence;
- failures, warnings, blockers, and unknowns;
- exclusions;
- unresolved Attention.

Explain any divergence.

### Recommend completion

Recommend completion only when criteria are satisfied, required verification ran, Evidence remains current, Repository state matches the report, material failures and unknowns are disclosed, and no blocking Attention remains.

The user retains final acceptance authority.

## Initial delegated roles

Run roles describe bounded responsibility, not employees.

### Scout

A Scout performs read-only investigation and returns observed facts, inferences, assumptions, unknowns, scope notes, and Evidence references.

It cannot modify source, install dependencies, mutate Git, change configuration, or expand authority.

### Verifier

A Verifier independently evaluates criteria against an exact Repository and Environment state.

It does not receive the author's confidence narrative as proof, cannot repair the implementation, and returns `PASS`, `FAIL`, or `BLOCKED` with reproduced Evidence.

These are the only initial Child role contracts.

A repeated procedure normally becomes a Skill. A new durable role contract requires a concrete need and accepted planning work.

## Attention and user control

Every blocker is visible through global Session Attention regardless of Run depth.

The user can:

- answer directly;
- enter the originating Run;
- route to the Parent;
- deny the request;
- pause the Run;
- cancel the Run.

The user can also inspect active and queued Runs, change priority, restrict grants, reject completion, take direct control, and request reconciliation.

No Child may remain silently blocked.

## Failure behavior

A Root or Parent process crash does not erase durable Run state or automatically cancel Children.

Kiln preserves:

- Session objective and Task graph;
- Run graph and Child contracts;
- active Worker leases and last status;
- unresolved Attention;
- Repository and Environment observations;
- Context and grant references;
- Artifacts, Evidence, accounting, and pending result delivery;
- last durable Steward projection.

A replacement Steward Worker reconstructs control state from the event journal and Repository truth.

It must not create a duplicate Child or repeat an external effect without an idempotency decision.

If the Root Run is canceled, active descendants receive cancellation requests under the accepted policy. Unknown effects produce `orphaned`, not success.

## Initial limits

```text
One Root Steward responsibility per Session
Maximum Child depth:              2
Maximum active Children:          3 per Session
Initial Child roles:              Scout and Verifier
Read-only delegation by default
No peer-to-peer Child communication
No shared mutable Context
No recursive manager hierarchy
No initial writing Child role
One active writer per checkout
Independent Verifier for material Claims
No automatic commit, push, merge, or product-direction change
```

These limits remain provisional until dogfooding produces Evidence.

## Product measure

Kiln should measure time to a current verified result, useful Evidence returned, Attention latency, duplicated work avoided, orphan recovery, and token cost per accepted Change set.

Kiln should not use the number of Agents or Child Runs as a success metric.

## Non-goals

Project Stewardship does not mean:

- an autonomous engineering manager;
- a replacement for user judgment;
- a hierarchy of manager Agents;
- delegation for every operation;
- unlimited background work;
- automatic architecture changes;
- automatic acceptance of Scout or Verifier conclusions;
- hidden modification of specifications;
- automatic publication to Git.

## Foundational rule

The Steward uses Kiln's state, Run graph, policy, Context, Evidence, Git isolation, recovery, and interface capabilities to move one objective toward specification-conformant, verified completion.

It increases leverage without weakening user control or proof requirements.
