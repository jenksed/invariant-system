# ADR 0020: Prove a single-Run change loop before delegated orchestration

- **Decision status:** Proposed
- **Integration status:** Proposed on P0-W18
- **Date:** 2026-07-28
- **Supersedes if accepted:** ADR 0019 implementation order and version 0.1 milestone only

## Context

Kiln's integrated P0-W16 plan correctly replaced horizontal component packages with vertical slices and kept protocols outside the native domain.

The accepted order still begins with a simulated Run graph and TUI. It then adds a read-only Scout, background work, independent verification, and durability. The first twelve-week milestone does not modify source.

Prompt 1 established that none of these capabilities is implemented.

Current coding agents already provide terminal interfaces, provider choice, file Tools, shell execution, sessions, permissions, Skills, and subagents. A simulated Run graph or read-only model workflow does not by itself establish that Kiln is meaningfully better as a coding harness.

Kiln's distinctive product claim is stronger:

- accepted objective and criteria remain durable;
- model Context and Tools are bounded and inspectable;
- model proposals remain separate from deterministic effects;
- mutation requires explicit authority;
- verification binds to exact state;
- completion depends on current Evidence;
- interruption and unknown effects remain recoverable and honest.

The delivery order must prove that claim before delegated orchestration, interface richness, protocols, or indexes.

## Decision drivers

1. One developer must be able to deliver and dogfood the first product.
2. The first month must produce usable coding behavior, not disconnected infrastructure or simulated navigation.
3. Run must remain a durable work identity without becoming Agent-orchestration theater.
4. OTP processes must be justified by live ownership rather than domain nouns.
5. Event journaling must serve concrete recovery, replay, audit, and duplicate-effect requirements.
6. The plan must avoid rebuilding capabilities already available in coding agents before proving Kiln's differentiation.
7. The first scope must preserve least privilege and explicit mutation authority.
8. Child Runs must earn their Context, permission, scheduling, navigation, and recovery cost.

## Considered options

### Option A — Retain the P0-W16 order

```text
simulated Run graph and TUI
→ read-only Scout
→ background work
→ Verifier
→ durable recovery
```

Rejected because the first month proves an interface abstraction rather than a complete coding workflow, and the twelve-week milestone remains read-only.

### Option B — Build every trusted subsystem before product use

Complete domain, persistence, broker, Context, execution, Evidence, interface, and isolation layers before a real workflow.

Rejected because it recreates the component-first risk that ADR 0019 was intended to remove.

### Option C — Wrap an existing coding agent and add Receipts

Use an existing Agent for all state, authority, mutation, and execution, then record a completion summary.

Rejected because Kiln would not own the durable work contract, exact authority decisions, deterministic effects, or recovery state. It would become a reporting wrapper around another Agent.

### Option D — Prove one durable single-Run change loop first

Implement one complete CLI workflow with exact Repository state, one model, bounded Context and Tools, explicit Patch Approval, registered verification, current Evidence, user acceptance, and restart recovery. Add bounded Child Runs after that workflow works.

Accepted by this proposed decision.

## Decision

Kiln will prove a single-Run change loop before delegated orchestration.

The first-month target is:

```text
one Repository
→ one Session, Task, and Root Run
→ one bounded model investigation
→ one exact Patch proposal
→ explicit user Approval
→ deterministic Patch application
→ one registered verification Command
→ Evidence-backed user acceptance
→ restart recovery
```

The initial interface is the CLI.

Child Runs, Run graph navigation, background Attention, and independent Verifier delegation are adjacent version 0.1 capabilities. They are not first-month prerequisites.

Version 0.1 will support:

- one Root Run;
- one active depth-one Child at a time;
- one read-only Scout role;
- one independent Verifier role;
- no nested delegation;
- no writing Child;
- CLI Run inspection and Root-visible Attention;
- durable restart and orphan recovery.

The TUI is deferred until the CLI command and projection surface is stable and one real Child workflow exists.

## Runtime process rule

No process exists merely because a Run is active.

The first-month Kiln-owned process topology is limited to:

- the application supervisor;
- transient model invocation Workers;
- transient Command Workers.

The selected SQLite library can own its connection process or pool.

A Session coordinator, Child scheduler, Attention router, or event publisher requires a later live scheduling or subscription need.

## Journal rule

Kiln uses an append-oriented SQLite journal because the product requires:

- restart recovery;
- ordered audit;
- projection rebuild;
- duplicate-effect prevention;
- later client resume;
- honest unknown-effect reconciliation.

Kiln does not event-source every token, UI movement, static concept, Artifact payload, or rebuildable index fact.

## Mutation rule

The first month uses one selected writable checkout and one mutation owner.

The model can produce an exact Patch proposal. It cannot mutate source directly.

Patch application requires explicit user Approval for the exact digest and exact base-state validation.

Managed worktree provisioning is deferred until a measured safety or concurrency need exists.

## Consequences

- Version 0.1 now includes one real source change.
- SQLite durability moves into the first product slice.
- Provider, Patch, Command, Artifact, Evidence, and completion support enter the first month in narrow form.
- The first useful Run graph has one Root node.
- Child Runs must demonstrate independent value after the Root workflow works.
- TUI and ExRatatui are removed from the first twelve weeks.
- The earlier depth-two and three-active-Child defaults are reduced to depth one and one active Child.
- A separate Root Task is not required in the initial model.
- General Capability broker, model router, Context retrieval framework, Skills, code intelligence, protocols, telemetry, and local project intelligence remain deferred.
- Prompt 3 must reconcile existing scaffolding and JSON contracts against the reduced first-month subset.

## Retained parts of ADR 0019

This ADR does not reject these ADR 0019 principles:

- implement through vertical product slices;
- deliver user-visible proof rather than horizontal component completion;
- keep Runs as data rather than permanent processes;
- share code-intelligence primitives under separate trust policy when that capability enters scope;
- keep persistent semantics Kiln-native first;
- use Patch Artifacts for later writing Child proposals;
- keep protocols outside the native domain and behind concrete entry gates.

Only ADR 0019's slice order, first coding target, and read-only version 0.1 boundary are proposed for supersession.

## Rejected positions

- simulated TUI navigation as the first useful product;
- read-only version 0.1 after twelve weeks;
- a process per active Run;
- nested delegation in version 0.1;
- three active Children before dogfooding;
- managed worktrees for one sequential writer or harmless reads;
- a generalized broker, retrieval, Event, or Evidence platform before one complete workflow;
- protocol implementation for coverage;
- treating existing planning depth as a reason to preserve scope.

## Evidence and assumptions

### Evidence

- P0-W17 establishes that current source is only an early Mix bootstrap.
- Current P1-S01 is a simulated Run and TUI slice.
- Current P1-S05 defines a read-only version 0.1.
- Current Run planning contains depth-two, three-active-Child, and process-per-active-Run implications.
- Current accepted architecture already rejects process identity, protocol-owned domain semantics, worktrees for harmless reads, and generalized infrastructure before user value.

### Assumptions

- One narrow real source change is feasible within the first month only after required focused planning and build authorization.
- One selected writable checkout is adequate for a single sequential mutation owner.
- A CLI can prove every first-month user action.
- Dogfooding can determine whether Child concurrency, TUI, worktrees, code intelligence, and protocols justify expansion.

## Review triggers

Review this decision when:

- safe Patch application or Command execution cannot meet the first-month target without weakening controls;
- one selected checkout creates a measured safety or concurrency problem;
- the CLI cannot expose required control or Evidence without a TUI;
- one active Child or depth one blocks a measured version 0.1 workflow;
- the SQLite journal forces changes to accepted Task or Run semantics;
- a protocol is required by a concrete workflow earlier than planned;
- the twelve-week target repeatedly fails despite removing deferred scope;
- dogfooding shows the first product is not meaningfully better than an existing coding-agent workflow.

A review must identify what scope is removed as well as what is added.
