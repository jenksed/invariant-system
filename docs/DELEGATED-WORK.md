# Delegated Work Model

**Document type:** Reference  
**Decision status:** Owner-accepted direction  
**Integration status:** Proposed on P0-W11  
**Implementation status:** Not implemented  
**Contract version:** `kiln.delegation/v0`

## Purpose

This specification defines how Kiln delegates work without hiding execution, authority, cost, evidence, or failure.

Kiln does not optimize for the number of agents. Kiln delegates only when a separate Run improves inspection, independent Context, authority control, parallel read-only work, verification, cancellation, or recovery.

Every delegated Task creates a first-class Run before delegated execution starts.

A delegated Run must not become:

- an opaque background Tool call;
- a hidden transcript;
- an uninspectable subprocess;
- a copied result without provenance;
- a self-authorizing Agent;
- an identity derived from a model, Worker, process, protocol, branch, or client.

The Run is the durable work identity. Agent definitions, Workers, model invocations, Tools, Commands, processes, branches, worktrees, and protocol sessions operate within or beneath the Run.

## Accepted positions

Kiln accepts these positions:

1. Every delegated Task creates one Child Run.
2. A Child Run has independent Context, Capability grants, Artifacts, accounting, cancellation, and durable history.
3. The logical Run graph remains separate from the OTP supervision tree.
4. Foreground and background are client-interaction modes. They do not change authority or durability.
5. Scout and Verifier are the only initial delegated role contracts.
6. A Scout is read-only and returns evidence-backed investigation.
7. A Verifier independently returns `PASS`, `FAIL`, or `BLOCKED` with reproduced Evidence.
8. A Verifier cannot repair the implementation that it evaluates.
9. Repeated procedures normally become Skills, not permanent Agent personas.
10. Initial Child depth is two. Initial concurrent Child execution is three per Session.
11. Child authority is read-only by default.
12. Children do not communicate peer to peer.
13. Children do not share mutable Context.
14. A Child cannot expand its own authority or authorize another Run.
15. No Child remains silently blocked.

## Critical distinctions

| Distinction | Kiln rule |
| --- | --- |
| Delegated Task and Tool call | A delegated Task needs independent Run properties. A Tool call performs one operation inside an existing Run. |
| Run and Agent | A Run owns durable work state. An Agent is a versioned execution definition that can be bound to a Run. |
| Run and Worker | A Run survives restart. A Worker is a transient executor lease. |
| Run lineage and OTP supervision | `parent_run_id` records work lineage. OTP supervision records process lifecycle and fault containment. |
| Parent authority and Child authority | A Parent can request a grant for a Child. It cannot transfer ambient authority. |
| Parent Context and Child Context | A Child receives a new immutable Context manifest. It does not inherit the Parent transcript or working set. |
| Background and hidden | Background work does not change client focus. It remains visible in the Run graph and attention index. |
| Completed Run and satisfied Task | A Run can complete its assigned procedure while the Task remains unsatisfied. |
| Verifier `BLOCKED` and Run failure | `BLOCKED` is a valid completed Verifier result when required verification cannot run. |
| Skill and role | A Skill is a reusable procedure. A role contract defines authority, inputs, outputs, and independence requirements for a Child Run. |
| Cancellation and process death | Cancellation is a durable control decision. Process death is an observation that can require orphan reconciliation. |
| Parent crash and Parent cancellation | A process crash does not cancel Children. An accepted cancellation policy can cancel descendants. |
| Artifact and result delivery | Artifacts remain independently stored. Parent delivery sends references and a bounded structured result, not copied transcripts. |

## When to delegate

Create a Child Run when the work needs one or more of these properties:

- independent inspection;
- independent Context;
- independent Capability grants;
- independent token, cost, time, or Resource accounting;
- independent cancellation;
- foreground steering;
- background progress;
- durable recovery;
- independent Artifacts or Evidence;
- independent verification;
- concurrent read-only investigation.

Do not create a Child Run only to:

- wrap one deterministic operation;
- rename a Tool call;
- simulate an engineering organization;
- add a persona to a repeated procedure;
- hide slow work from the active Run;
- bypass Context, Capability, or token limits.

A repeated deterministic or model-guided procedure should normally become a Skill. A Skill does not create a Run by itself. The calling Run decides whether the procedure executes directly or through a delegated Run.

## Run graph specification

### Graph invariants

Each Session has exactly one Root Run.

Every non-root Run has:

- one `parent_run_id`;
- one `root_run_id`;
- one `task_id`;
- the same `session_id` as its Parent and Root Runs;
- one recorded depth;
- one immutable delegation-contract revision.

The initial depth rules are:

```text
Root Run depth:                 0
Maximum Child depth:           2
Maximum active Child Runs:     3 per Session
Maximum active Worker leases:  1 per Run
```

An active Child is in `starting`, `running`, a waiting state, `paused`, or `verifying`.

A Session can queue more than three Children, but only three can be active. The scheduler must preserve queue order unless policy records a priority change.

A Child at depth two cannot create or request another descendant.

A Child at depth one can propose a nested delegation. It cannot authorize or create it directly. The Root Run or an authorized control service evaluates the request and creates the nested Run with the proposing Child as logical Parent.

This rule supports nested work without creating a recursive manager hierarchy.

### Root Runs

The Root Run:

- has no Parent Run;
- owns the Session control projection;
- carries Project Steward responsibility by default;
- can create bounded Child Tasks and request Child Runs;
- receives unresolved delivery when a Parent cannot receive it;
- does not supervise Child processes because of lineage.

### Parent and Child Runs

A Parent Run:

- records why the Child exists;
- exposes the Child in its projection;
- receives the Child result through durable delivery;
- can request pause or cancellation when authorized;
- cannot read the full Child transcript by default;
- cannot change Child authority without a new policy decision.

A Child Run:

- has an independently compiled Context manifest;
- has independent Capability grants and limits;
- owns its own model invocations, Tool calls, Commands, Artifacts, Claims, Evidence, and Checkpoints;
- records its own token, cost, elapsed-time, and Resource accounting;
- can be inspected, entered, paused, canceled, and recovered independently;
- returns one bounded structured result to its Parent;
- cannot address a sibling directly.

### Sibling Runs

Sibling Runs can:

- read the same immutable Repository state when policy permits;
- execute concurrently within Session limits;
- produce independent Artifacts and Evidence;
- be inspected and canceled independently.

Sibling Runs cannot:

- send direct messages to each other;
- mutate shared Context;
- inspect each other's private Context or hidden reasoning;
- treat another sibling's Claim as Evidence;
- coordinate writes to one checkout.

When sibling work must be reconciled, the Parent consumes their structured results and referenced Artifacts.

### Foreground delegation

Foreground delegation changes client focus only when the user or client accepts the focus change.

Use foreground delegation when work is likely to require:

- immediate steering;
- interactive inspection;
- user answers;
- permission decisions;
- close observation of long-running activity.

The Parent can continue or enter `waiting_for_child` according to its delegation contract.

### Background delegation

Background delegation does not change client focus.

A background Child remains visible through:

- the Session Run graph;
- the Parent Child projection;
- global attention;
- status and activity events;
- Resource and token accounting;
- terminal result delivery.

Background must not mean hidden.

## Initial limits

The initial defaults are:

| Limit | Default |
| --- | --- |
| Maximum Child depth | 2 |
| Maximum active Children per Session | 3 |
| Default Child authority | Read-only |
| Peer-to-peer Child communication | Disabled |
| Shared mutable Context | Disabled |
| Recursive manager hierarchy | Disabled |
| Writing Child roles | Disabled |
| Child Git push, merge, or publication | Disabled |
| Active Worker leases | 1 per Run |

These defaults can change only through a versioned policy revision with dogfooding Evidence.

The Git Patch Artifact mode from `docs/GIT-CHANGE-ISOLATION.md` remains an accepted isolation mechanism. P0-W11 does not enable an initial model-backed authoring Child role. A later work package must define and accept that role before a Child can author a patch or mutate a worktree.

## Delegation contract

A Parent must create a durable delegation contract before the Child enters `queued`.

The contract contains:

```yaml
schema_version: kiln.delegation/v0
delegation_id: delegated_01JZ...
session_id: session_01JZ...
task_id: task_01JZ...
run_id: run_01JZ...
root_run_id: run_root_01JZ...
parent_run_id: run_parent_01JZ...
depth: 1
role: scout
role_version: 1
execution_mode: background

purpose: Find the code paths that invalidate verification Evidence.
input_contract:
  task_revision_id: taskrev_01JZ...
  context_seed_refs:
    - artifact_01JZ...
  repository_state_ref: repo_state_01JZ...
  required_fact_classes:
    - source_location
    - current_behavior

context_policy:
  independent_manifest: true
  inherit_parent_transcript: false
  inherit_parent_working_set: false

permission_profile: scout_read_only
requested_capabilities:
  - repo.read
  - repo.search
  - docs.lookup

effective_grant_ids:
  - grant_01JZ...

limits:
  max_active_elapsed_ms: 1800000
  max_wall_elapsed_ms: 7200000
  max_input_tokens: 12000
  max_output_tokens: 4000
  max_cost_microunits: 0
  max_commands: 10
  max_artifacts: 20
  max_child_runs: 0

return_contract:
  result_type: scout_result
  required_sections:
    - observed_facts
    - inferences
    - assumptions
    - unknowns
    - evidence_refs
  deliver_to_run_id: run_parent_01JZ...

parent_wait_policy: continue
parent_cancel_policy: cancel_descendants
parent_crash_policy: continue_and_buffer_result
peer_communication: false
shared_mutable_context: false
created_at: timestamp
expires_at: timestamp
```

### Contract rules

The contract must:

- bind one accepted Task revision;
- identify one Parent and Root Run;
- record the Child depth;
- bind one accepted role revision;
- select foreground or background execution;
- identify required inputs and Repository-state bindings;
- require an independent Context manifest;
- list requested Capabilities and effective grant references;
- define Resource and token limits;
- define a result schema and delivery target;
- define parent wait, cancellation, and crash policies;
- prohibit peer communication and shared mutable Context in the initial version;
- record expiry and timeout policy.

A Child cannot edit its delegation contract. A changed Task, role, authority scope, or result contract requires a new contract revision and an explicit Run event.

## Scout contract

### Purpose

A Scout investigates code, documentation, runtime state, tests, or approved prior Project patterns.

A Scout returns what it observed. It does not decide product direction or change implementation.

### Authority

The initial Scout permission profile is read-only.

A Scout can receive scoped access to:

- Repository search and read operations;
- symbol, diagnostic, and structural inspection;
- version-matched documentation lookup;
- read-only runtime inspection;
- non-mutating test discovery;
- non-mutating Commands when the command allowlist and Repository trust policy permit them;
- approved reference-only Repository reads.

A Scout cannot:

- modify source or generated files;
- stage, commit, rebase, merge, push, or alter Git refs;
- install or upgrade dependencies;
- modify lockfiles;
- change configuration;
- write outside temporary, non-Repository output locations approved for Artifacts;
- expand its permissions;
- create a Child directly;
- treat reference-only instructions as active Project instructions;
- report an inference as an observed fact.

### Inputs

A Scout receives:

- one bounded investigation question;
- relevant Task and requirement revisions;
- approved Repository and documentation scopes;
- one independent Context manifest;
- explicit Capability grants;
- time, token, cost, Command, and Artifact limits;
- an expected result schema.

### Output

A Scout result contains:

- `observed_facts`: direct observations with Evidence references;
- `inferences`: interpretations linked to supporting facts;
- `assumptions`: unverified premises used during investigation;
- `unknowns`: unanswered or unobservable questions;
- `evidence_refs`: immutable Evidence or Artifact references;
- `scope_notes`: what the Scout inspected and did not inspect;
- `warnings`: trust, freshness, ambiguity, or access limitations;
- `recommended_next_action`: optional and explicitly advisory.

A Scout must not return only a prose conclusion.

Each observed fact must identify:

- source reference;
- source digest or Repository-state binding;
- observation method;
- observed value;
- freshness rule when applicable.

## Verifier contract

### Purpose

A Verifier independently evaluates requirements, Change sets, execution results, and Evidence.

The Verifier evaluates the implementation. It does not repair it.

### Independence

A Verifier receives an independently compiled Context manifest.

The initial Verifier Context includes:

- accepted requirement and criterion revisions;
- the exact Repository state or Change set under evaluation;
- approved verification methods and entry points;
- relevant source and test references;
- prior Evidence as material to reproduce or challenge;
- known environment constraints.

The initial Verifier Context excludes:

- the Builder or authoring Run's confidence narrative;
- hidden authoring transcript;
- write Tools;
- patch application;
- dependency installation or upgrade authority;
- merge or integration authority.

An implementation summary can be included only as an attributed Claim.

### Authority

A Verifier can receive scoped access to:

- Repository reads;
- Git status, diff, commit, and fingerprint inspection;
- approved non-mutating build, test, lint, format-check, compiler, static-analysis, and runtime-inspection Commands;
- Evidence and Artifact reads;
- creation of new verification Evidence and reports.

A Verifier cannot:

- modify the implementation it evaluates;
- repair a failing test;
- format files in write mode;
- install or upgrade dependencies;
- stage, commit, rebase, merge, push, or alter refs;
- broaden its own checks or authority without a recorded request;
- convert a blocked check into a pass;
- authorize integration.

### Result

A Verifier returns exactly one outcome:

- `PASS`: required checks ran against the recorded state and reproduced Evidence supports the required criteria;
- `FAIL`: reproduced Evidence refutes one or more required criteria or identifies a material defect;
- `BLOCKED`: required evaluation could not complete because of missing access, unavailable environment, stale state, ambiguous criteria, Resource limits, or another explicit blocker.

A Verifier Run can enter `completed` with any of these outcomes. `completed` means that the Verifier returned its required result. It does not mean that the implementation passed.

The Verifier result contains:

- exact Repository and Environment state bindings;
- criterion-by-criterion outcomes;
- Commands and methods executed;
- reproduced Evidence references;
- stale or rejected prior Evidence;
- failures and blockers;
- untested areas;
- outcome rationale;
- required next action for `FAIL` or `BLOCKED`.

`PASS` requires reproduced Evidence. A copied prior result is not reproduced Evidence.

## Structured parent result delivery

A Child result is stored before delivery.

Delivery follows this sequence:

```text
Child produces result
→ result schema validates
→ result and referenced Artifacts become durable
→ Child terminal transition records the result reference
→ delivery record is created with an idempotency key
→ Parent projection receives a bounded result envelope
→ delivery is acknowledged or routed to the Root Run
```

The result envelope contains:

- Child Run and Task identifiers;
- role and role version;
- terminal Run status;
- role-specific outcome;
- bounded summary;
- Artifact, Claim, Evidence, and Receipt references;
- token, cost, elapsed-time, Command, and Resource accounting;
- failures, warnings, assumptions, and unknowns;
- delivery sequence and idempotency key.

Delivery must not copy:

- the full Child transcript;
- hidden reasoning;
- the full Child Context manifest contents;
- unbounded Command output;
- secret values.

If the Parent process is unavailable, delivery remains pending in durable state.

If the Parent Run is terminal or cannot accept the result, Kiln routes the delivery to the Root Run and creates Attention when the result affects active work.

## Run state machine

### States

| State | Meaning |
| --- | --- |
| `created` | Durable Run identity and delegation contract exist. Execution is not scheduled. |
| `queued` | The Run is authorized and waits for scheduling capacity or a dependency. |
| `starting` | Kiln acquires a Worker lease, validates state, and prepares execution. |
| `running` | The Worker actively advances the Run. |
| `waiting_for_tool` | The Run waits for an asynchronous Tool result. |
| `waiting_for_command` | The Run waits for a supervised Command to terminate or produce a required result. |
| `waiting_for_child` | The Run waits for one or more Child results required by its contract. |
| `waiting_for_user` | The Run waits for a user answer or decision. A global Attention item is open. |
| `waiting_for_permission` | The Run waits for a Capability or Approval decision. A global Attention item is open. |
| `paused` | Authorized execution is intentionally suspended at a durable safe boundary. |
| `verifying` | The Run evaluates its result or executes the Verifier procedure. |
| `completed` | The Run produced and sealed its required structured result. |
| `failed` | The Run cannot produce its required result because of a terminal error. |
| `canceled` | An authorized cancellation ended the Run attempt and effects are reconciled. |
| `orphaned` | Kiln cannot determine the state or effects of a Worker or external execution. |
| `stale` | The Run result no longer applies to the current Task, Repository, policy, Context, or Evidence state. |

`completed`, `failed`, `canceled`, and `stale` are terminal for the Run attempt.

`orphaned` is a non-success recovery state. It can transition only after reconciliation.

### Valid transitions

| From | Allowed next states |
| --- | --- |
| `created` | `queued`, `canceled`, `failed`, `stale` |
| `queued` | `starting`, `paused`, `canceled`, `failed`, `stale` |
| `starting` | `running`, `waiting_for_permission`, `failed`, `canceled`, `orphaned`, `stale` |
| `running` | `waiting_for_tool`, `waiting_for_command`, `waiting_for_child`, `waiting_for_user`, `waiting_for_permission`, `paused`, `verifying`, `completed`, `failed`, `canceled`, `orphaned`, `stale` |
| `waiting_for_tool` | `running`, `waiting_for_permission`, `paused`, `failed`, `canceled`, `orphaned`, `stale` |
| `waiting_for_command` | `running`, `verifying`, `paused`, `failed`, `canceled`, `orphaned`, `stale` |
| `waiting_for_child` | `running`, `waiting_for_user`, `paused`, `failed`, `canceled`, `stale` |
| `waiting_for_user` | recorded return state, `paused`, `failed`, `canceled`, `stale` |
| `waiting_for_permission` | recorded return state, `paused`, `failed`, `canceled`, `stale` |
| `paused` | `queued`, `canceled`, `failed`, `stale` |
| `verifying` | `waiting_for_command`, `waiting_for_user`, `waiting_for_permission`, `completed`, `failed`, `canceled`, `orphaned`, `stale` |
| `orphaned` | `queued`, `paused`, `failed`, `canceled`, `stale` |
| `completed` | none |
| `failed` | none |
| `canceled` | none |
| `stale` | none |

A return from `waiting_for_user` or `waiting_for_permission` must use the durable `resume_state` recorded when the wait began. Kiln must not guess the return state.

A new attempt after `failed`, `canceled`, or `stale` requires a new Run.

### Transition evidence

Every transition records:

- transition identifier;
- Run, Session, Task, Root Run, and Parent Run identifiers;
- previous and next state;
- reason code and bounded reason;
- actor or deterministic policy source;
- correlation and causation identifiers;
- event time and recorded sequence;
- active Worker lease, model invocation, Tool call, Command, Child, or Attention reference when applicable;
- Repository, Environment, Context, and policy bindings when material;
- resume state for user or permission waits;
- timeout or cancellation reference when applicable.

Additional evidence is required for these transitions:

| Transition | Required evidence |
| --- | --- |
| `created → queued` | validated delegation contract, accepted Task revision, role revision, Context request, and authority decision |
| `queued → starting` | scheduler decision and capacity allocation |
| `starting → running` | Worker lease and current-state validation |
| any state → `waiting_for_user` | open Attention item created in the same durable transaction |
| any state → `waiting_for_permission` | open permission Attention item and requested Capability scope created in the same durable transaction |
| `running → waiting_for_tool` | Tool call reference and expected completion contract |
| `running → waiting_for_command` | Command reference, timeout, working state, and termination contract |
| `running → waiting_for_child` | required Child delivery references |
| any active state → `paused` | pause request, safe-boundary observation, and Checkpoint or explicit reason that no Checkpoint is available |
| any state → `completed` | validated structured result, result digest, accounting record, and delivery record or delivery target |
| any state → `failed` | terminal error, failed recovery decision, and partial Artifact references |
| any state → `canceled` | cancellation record, termination outcomes, and side-effect reconciliation |
| any active state → `orphaned` | expired or lost lease plus unknown-effect observation |
| any non-terminal state → `stale` | invalidating Task, Repository, Context, policy, or Evidence change |

## Attention routing

### Global attention index

Attention belongs to the Session, not to a nesting level or active client view.

Every open Attention item appears in one global Session attention index and in:

- the originating Run projection;
- each ancestor projection through the Root Run;
- connected client notifications according to user preferences;
- the durable event journal.

Nested depth must not delay, hide, or reduce attention delivery.

### Attention types

The initial types are:

- `question`;
- `permission_request`;
- `conflict`;
- `failure`;
- `verification_blocker`;
- `merge_blocker`;
- `resource_limit`;
- `stale_evidence`.

### User actions

The user can:

- answer directly;
- enter the originating Run;
- route the question to the Parent Run;
- deny the request;
- pause the Run;
- cancel the Run.

Entering a Run changes only client focus. It does not resolve the Attention item or change execution state.

Routing to the Parent creates a routing event. It does not transfer authority or change the originating Run.

### No silent blocking

A Run cannot enter `waiting_for_user` or `waiting_for_permission` unless Kiln creates an open blocking Attention item in the same durable transaction.

A verification or merge blocker that prevents progress must also create Attention.

An open blocking Attention item must have:

- a visible summary;
- originating Run and Parent references;
- allowed user actions;
- a response schema when an answer is accepted;
- a deadline or explicit no-deadline policy;
- an escalation time;
- a deduplication key;
- current routing status.

Kiln must not:

- auto-answer an Attention item with a model guess;
- auto-grant permission after a timeout;
- hide a blocker because the originating Run is in the background;
- retry a denied request under a wider scope;
- mark a blocked Run as completed.

### Attention event schema

An Attention lifecycle uses append-only events:

```yaml
schema_version: kiln.delegation/v0
contract_type: attention_event
attention_event_id: event_01JZ...
attention_request_id: attention_01JZ...
session_id: session_01JZ...
root_run_id: run_root_01JZ...
source_run_id: run_child_01JZ...
parent_run_id: run_parent_01JZ...
type: verification_blocker
event_kind: raised
status: open
urgency: blocking
blocking: true
summary: Integration test environment is unavailable.
details_artifact_id: artifact_01JZ...
response_schema: {}
allowed_actions:
  - answer_directly
  - enter_originating_run
  - route_to_parent
  - deny_request
  - pause_run
  - cancel_run
resume_state: verifying
deduplication_key: verify-env-unavailable
created_at: timestamp
escalate_at: timestamp
expires_at: null
actor:
  kind: run
  id: run_child_01JZ...
```

Lifecycle event kinds are:

- `raised`;
- `acknowledged`;
- `routed`;
- `answered`;
- `denied`;
- `escalated`;
- `resolved`;
- `deferred`;
- `expired`;
- `withdrawn`.

## Cancellation behavior

Cancellation is a durable control flow.

Kiln performs cancellation in this order:

```text
Authorize cancellation
→ record CancellationRequested
→ stop new model, Tool, Command, Child, and permission effects
→ signal active execution owners
→ wait for the configured grace period
→ terminate remaining owned processes when policy permits
→ observe Repository and external effects
→ preserve partial Artifacts
→ reconcile unknown effects
→ record terminal Run state or orphan state
→ deliver cancellation result to Parent
```

### Cancellation scope

A user can cancel any Run that the user is authorized to control.

A Parent can request cancellation of its Child. Policy decides the request.

A Child cannot cancel a Parent or sibling.

Canceling a Child does not cancel its Parent or siblings.

Canceling the Root Run requests cancellation of all active descendants.

The initial Parent cancellation policy is `cancel_descendants`. Detached Child continuation is not supported in the initial product.

### Cancellation outcomes

A Run becomes `canceled` only when:

- active owned execution has stopped;
- no new effects can start;
- known effects are recorded;
- Repository state is observed;
- unknown external effects do not remain.

If effect state remains unknown, the Run becomes `orphaned`, not `canceled`.

Cancellation does not:

- erase history;
- delete dirty worktrees;
- roll back external effects automatically;
- imply that a Command terminated cleanly;
- invalidate useful partial Evidence automatically.

## Timeout policy

Timeouts are explicit contract fields. A hidden client or process timeout must not define Run outcome.

Kiln distinguishes:

- queue delay;
- start timeout;
- Worker heartbeat and lease timeout;
- active execution budget;
- wall-clock deadline;
- Tool timeout;
- Command timeout;
- model-invocation timeout;
- Attention escalation and expiry;
- cancellation grace period.

Initial provisional defaults are:

| Timeout | Default |
| --- | --- |
| Start timeout | 60 seconds |
| Worker heartbeat interval | 15 seconds |
| Worker lease timeout | 45 seconds |
| Cancellation grace period | 10 seconds |
| Attention escalation | 5 minutes |
| Scout active elapsed budget | 30 minutes |
| Verifier active elapsed budget | 60 minutes |
| Queue hard timeout | None; delay remains visible |
| User or permission wait | Does not consume active elapsed budget |

Every Child contract must set a wall-clock deadline or record an explicit no-deadline policy approved by the user.

A queue delay longer than the configured escalation period creates a `resource_limit` Attention item. It does not silently fail the Run.

A timeout can:

- pause the Run;
- request Attention;
- fail one Tool, Command, or invocation;
- cancel the Run when the contract explicitly requires it;
- move the Run to `orphaned` when effect state is unknown.

A timeout cannot:

- grant more authority;
- convert a blocked Verifier to `PASS`;
- treat unobserved termination as clean cancellation;
- discard partial Artifacts.

## Parent crash behavior

A Parent process crash does not cancel or erase Child Runs.

After a Parent process crash:

- durable Parent and Child state remains in the journal;
- active Children continue while their Worker leases and grants remain valid;
- completed Child results remain stored and pending delivery;
- a replacement Parent Worker reconstructs the Child projection and pending deliveries;
- duplicate Child creation is prevented by delegation idempotency keys;
- duplicate result delivery is prevented by delivery idempotency keys.

If the Parent Run becomes `failed`, `canceled`, `stale`, or otherwise terminal:

- the initial policy requests cancellation of active descendants;
- completed Child results remain historical Artifacts and Evidence;
- undelivered material results route to the Root Run;
- Kiln raises Attention when the result affects active Session work.

The Root Run process can fail independently from the Root Run identity. A replacement Steward Worker reconstructs control state from the event journal and Repository truth.

## Child crash behavior

A Child Worker crash does not erase the Child Run.

Kiln records:

- Worker crash or lease expiry;
- last heartbeat;
- active model, Tool, Command, and Terminal references;
- last durable Context, Checkpoint, Artifact, and output position;
- known Repository and external state;
- whether a safe retry is possible.

Kiln can start a replacement Worker for the same Run only when:

- the Run is non-terminal;
- the delegation contract remains current;
- authority and Context can be reconstructed;
- repeating work cannot duplicate a mutation or external effect;
- the replacement decision is recorded.

If these conditions are not met, the Run becomes `orphaned` or `failed`.

A Child failure creates Parent-visible Attention when it blocks Parent progress.

Partial Artifacts, Claims, Evidence, and accounting remain attached to the failed or orphaned Child.

## Orphan handling

`orphaned` means Kiln cannot determine execution state or effects.

An orphaned Run must not:

- report success;
- deliver a `PASS` result;
- satisfy its Task;
- authorize integration;
- start another potentially duplicate effect.

Startup and live reconciliation inspect:

- Worker leases and heartbeats;
- model-invocation status;
- Tool, Command, and Terminal state;
- Repository and worktree state;
- external operation identifiers;
- pending result deliveries;
- open Attention and cancellation records.

Reconciliation actions are classified as:

| Class | Examples |
| --- | --- |
| Automatic | Mark expired lease, rebuild projections, redeliver an idempotent stored result, reattach a known live Command stream. |
| Safe but reported | Start a replacement read-only Worker from a valid Checkpoint, mark a stale Context manifest, release an unused Resource reservation. |
| Approval required | Retry an operation with possible external effects, cancel a process not owned by the current runtime, discard an unneeded pending result. |
| Manual intervention | Unknown Git mutation, dirty worktree with unclear ownership, incomplete merge or rebase, unknown external side effect. |

Recovery prefers preservation and explicit uncertainty over aggressive cleanup.

## Persistence requirements

Kiln persists enough state to reconstruct the Run graph without transcripts or live processes.

### Durable records

Persist:

- Session, Task, Run, Root Run, and Parent Run identifiers;
- Run depth and role binding;
- delegation contract and revisions;
- foreground or background mode;
- status transitions and reasons;
- immutable Context manifests and active manifest reference;
- Capability requests, grants, denials, revocations, and policy snapshots;
- Worker leases, heartbeats, crashes, handoffs, and expiry;
- model invocations, Tool calls, Commands, Terminals, and terminal outcomes;
- Artifacts, Claims, Evidence, Receipts, and Checkpoints;
- token, cost, time, Command, Artifact, and Resource accounting;
- Attention lifecycle events and resolutions;
- cancellation and timeout records;
- Child result and delivery records;
- failures, warnings, assumptions, unknowns, and exclusions;
- Repository and Environment state bindings.

### Transient state

Do not persist as domain identity:

- BEAM PIDs or references;
- operating-system PIDs as durable Run identity;
- process monitors;
- stream buffers;
- provider sockets;
- cancellation tokens;
- timers;
- client focus;
- hidden model reasoning.

Runtime handles can appear in transient process state and bounded diagnostic observations. They do not become durable identity.

### Transaction boundaries

Kiln uses one durable transaction for each of these boundaries:

1. create Child Task, Child Run, delegation contract, and `RunCreated` event;
2. create a blocking Attention item and enter a user or permission wait state;
3. record a validated Child result, terminal transition, and delivery record;
4. record a cancellation decision and interruption request;
5. claim or replace a Worker lease;
6. resolve an Attention item and schedule the recorded resume state.

If a transaction fails, Kiln must not expose a partial state such as a waiting Run without Attention or a completed Child without a result reference.

### Event minimum

The delegated-work model records at least:

```text
DelegationRequested
DelegationAuthorized
DelegationDenied
ChildRunCreated
ChildRunQueued
RunStarting
RunStatusChanged
WorkerLeaseGranted
WorkerHeartbeatRecorded
WorkerLeaseExpired
WorkerCrashed
ContextManifestCompiled
CapabilityRequested
CapabilityGranted
CapabilityDenied
CapabilityRevoked
ToolCallStarted
ToolCallCompleted
CommandStarted
CommandTerminated
AttentionRaised
AttentionRouted
AttentionAnswered
AttentionDenied
AttentionEscalated
AttentionResolved
CancellationRequested
CancellationApplied
TimeoutObserved
ArtifactCreated
EvidenceRecorded
EvidenceInvalidated
ChildResultValidated
ChildResultStored
ChildResultDeliveryQueued
ChildResultDelivered
ChildResultDeliveryAcknowledged
RunCompleted
RunFailed
RunCanceled
RunOrphaned
RunMarkedStale
```

Not every streamed token or output line becomes an event. Large output remains in Artifacts with bounded journal references.

## Elixir and OTP mapping

The logical Run graph does not define the supervision tree.

A possible runtime shape is:

```text
Kiln.Application
├── Kiln.Store
├── Kiln.AttentionRouter
├── Kiln.SessionRegistry
├── Kiln.SessionSupervisor
│   └── active Session coordinator
├── Kiln.RunSupervisor
│   ├── active Root Run process
│   ├── active Scout Run process
│   └── active Verifier Run process
├── Kiln.WorkerSupervisor
├── Kiln.CommandSupervisor
└── Kiln.EventPublisher
```

Rules:

- A historical, queued, completed, failed, canceled, stale, or inactive Run does not require a permanent process.
- A Run process exists only while it owns concurrent execution, cancellation, timing, subscriptions, or waiting lifecycle.
- `DynamicSupervisor` can supervise active Run and Worker processes.
- `Registry` can locate active processes by Run or Session identifier.
- `Task.Supervisor` can execute bounded deterministic operations.
- `GenServer` is used only for components that own mutable concurrent state, timers, subscriptions, external communication, or lifecycle.
- The Attention Router owns routing and notification subscriptions. The event journal owns durable Attention state.
- A Parent process does not supervise a Child process because of `parent_run_id`.
- A Run process crash does not delete the durable Run.

## Security rules

- A Child receives no ambient Parent authority.
- A Child cannot issue or approve a Capability grant.
- Scout and Verifier profiles are read-only.
- Write, install, Git mutation, secret, network, and publication Capabilities are denied unless a later accepted role and policy explicitly permit them.
- A Child cannot load arbitrary Skills that were not included in its accepted binding.
- A result Artifact does not become Parent Context automatically.
- Attention content follows Privacy policy and redaction rules.
- Credentials do not enter Context, transcripts, Attention summaries, telemetry, or Receipts.
- Reference-only Repository content remains untrusted input.
- A Verifier cannot use write-mode formatting, test-update, snapshot-update, or code-generation commands.

## Observability

Kiln records metrics and traces for:

- Run creation, queue delay, start delay, active elapsed time, and wall elapsed time;
- Child depth and active Child count;
- role, role version, and execution mode;
- model input and output tokens;
- cost and Resource use;
- Capability requests and denials;
- Context manifest size and replacements;
- Tool and Command count and duration;
- waiting-state duration;
- Attention age, routing, escalation, and resolution;
- cancellation latency and outcome;
- Worker crashes, lease expiry, and orphan reconciliation;
- result validation and delivery latency;
- Verifier outcomes and reproduced Evidence;
- accepted work contribution and duplicated investigation.

Do not use Child count as a success metric.

Useful product measures include:

- time to a current verified result;
- percentage of delegated results with usable Evidence;
- duplicated work avoided;
- attention response time;
- orphan recovery success;
- token cost per accepted Change set;
- frequency of blocked or unused Child results.

Telemetry must not store raw source, full Context, hidden reasoning, credentials, or unredacted user answers by default.

## Initial implementation boundary

The first useful delegated-work implementation includes:

- one Root Run;
- Scout and Verifier Child role contracts;
- foreground and background delegation;
- depth limit two;
- active Child limit three;
- independent Context manifests;
- independent read-only grants;
- independent token and Resource accounting;
- durable Run graph and status history;
- `waiting_for_command` and all required waiting states;
- global Attention routing and the six user actions;
- independent cancellation;
- structured Child result delivery;
- Worker crash and parent crash recovery;
- orphan detection and conservative reconciliation;
- CLI projection of Run tree, status, activity, Attention, accounting, and results;
- deterministic fake or fixture Workers before live model-backed Children.

The initial implementation excludes:

- writing Child roles;
- model-authored Patch Artifacts;
- peer-to-peer Child messages;
- shared mutable Context;
- detached Child continuation after Parent cancellation;
- recursive manager Agents;
- automatic permission expansion;
- remote or distributed Run execution;
- cross-Session delegation;
- A2A for local Child Runs;
- unlimited depth or concurrency;
- automatic acceptance of Scout or Verifier conclusions.

## Acceptance criteria

The design is accepted when these criteria are satisfied:

1. **P0-W11-AC01:** Given a delegated Task, Kiln creates a durable Child Run before any delegated model, Tool, Command, or process executes.
2. **P0-W11-AC02:** Given a Child Run, the user can inspect its Task, status, Context reference, grants, accounting, Artifacts, Evidence, and terminal result independently.
3. **P0-W11-AC03:** Given a Parent-Child relationship, the logical graph does not require the Parent process to supervise the Child process.
4. **P0-W11-AC04:** Given four authorized Children, at most three are active and the remaining Child stays visibly queued.
5. **P0-W11-AC05:** Given a depth-two Child, a further delegation request is denied with a visible reason.
6. **P0-W11-AC06:** Given a Scout, source, dependency, Git, and configuration mutation operations are denied.
7. **P0-W11-AC07:** Given a Scout result, every observed fact references Evidence and remains separate from inference and assumption.
8. **P0-W11-AC08:** Given a Verifier, the initial Context excludes the author's confidence narrative and all write Tools.
9. **P0-W11-AC09:** Given a Verifier `PASS`, the result contains reproduced Evidence bound to the evaluated Repository and Environment state.
10. **P0-W11-AC10:** Given unavailable required verification, the Verifier completes with `BLOCKED`, not `PASS`.
11. **P0-W11-AC11:** Given a Run waiting for a user or permission, an open blocking Attention item exists in the same durable transaction.
12. **P0-W11-AC12:** Given Attention from a depth-two Child, the global attention index exposes all allowed user actions without requiring navigation through ancestors.
13. **P0-W11-AC13:** Given a Child cancellation, the Parent and siblings continue unless separately canceled.
14. **P0-W11-AC14:** Given a Root Run cancellation, active descendants receive cancellation requests and no new descendant effects start.
15. **P0-W11-AC15:** Given unknown external effects after cancellation or crash, the Run becomes `orphaned` and cannot report success.
16. **P0-W11-AC16:** Given a Parent process crash, active Children and stored results survive and a replacement Parent reconstructs pending delivery without duplicate Child creation.
17. **P0-W11-AC17:** Given a Child Worker crash with no possible duplicate effects, a replacement Worker can resume the same Run from durable state.
18. **P0-W11-AC18:** Given a terminal Child result, the Parent receives a validated bounded envelope and references instead of a copied transcript.
19. **P0-W11-AC19:** Given a repeated procedure, Kiln can bind a Skill without creating a permanent role persona.
20. **P0-W11-AC20:** Given restart, Kiln reconstructs Run graph, waiting states, Attention, grants, accounting, result delivery, cancellation, timeout, and orphan state from durable records and current observations.
21. **P0-W11-AC21:** Given a state transition, the transition is rejected when it is not in the accepted transition table or lacks required evidence.
22. **P0-W11-AC22:** Given a background Child, its progress and blockers remain visible without changing client focus.
23. **P0-W11-AC23:** Given sibling Runs, direct peer communication and shared mutable Context are unavailable.
24. **P0-W11-AC24:** Given a Child permission request, denial cannot be retried under wider scope without a new explicit user or policy decision.
25. **P0-W11-AC25:** The `kiln.delegation/v0` JSON Schema validates representative delegation, role result, transition, Attention, cancellation, timeout, and result-delivery documents.

## Deferred capabilities

Defer:

- Builder or other writing Child roles;
- model-authored Patch Artifact workflows;
- deeper Run graphs;
- more than three concurrent Children;
- peer messaging;
- shared working memory;
- detached Children;
- remote delegation;
- cross-Session or cross-Project delegation;
- autonomous permission negotiation;
- automatic retry of unknown side effects;
- role marketplaces or large persona catalogs;
- A2A for local Runs;
- performance-based dynamic limit changes without dogfooding Evidence.

## Foundational rule

Delegation is useful only when it remains visible, bounded, independently authorized, independently accounted, interruptible, evidence-producing, and recoverable.

Kiln must prefer direct execution over delegation when a separate Run does not improve those properties.
