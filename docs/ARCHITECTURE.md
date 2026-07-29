# Integrated Architecture

**Document type:** Architecture summary  
**Decision status:** Accepted  
**Integration status:** Reconciled by Prompt 8-A  
**Implementation status:** P1-S01 authorized after Prompt 8-A merges  
**Detailed subject authorities:** P0-W21 through P0-W25

## Purpose

This document summarizes the minimum architecture for one durable, controlled, evidence-backed Repository change.

It does not redefine the focused authorities. When a detail conflicts with a focused specification, use these documents in order:

1. `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`;
2. `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`;
3. `docs/PATCH-APPROVAL-AND-MUTATION.md`;
4. `docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md`;
5. `docs/CLI-AND-LOCAL-DELIVERY-CONTRACT.md`.

The roadmap and final Wave A authorization control implementation order. This summary cannot authorize work or add early scope.

## Product loop

```text
Intent
→ bounded investigation
→ explicit Patch proposal
→ user Approval
→ controlled application
→ registered verification
→ criterion-bound Evidence
→ user acceptance
→ atomic completion
→ post-completion Receipt sealing and delivery
```

Kiln optimizes for completed trustworthy work. It does not optimize for Agent count, Run count, protocol count, process count, panes, indexes, or Tool catalogs.

## Non-negotiable rules

1. A Task states desired work. A Run attempts or coordinates it.
2. Run is the durable execution and observation identity.
3. A Run is not an Agent, model request, Tool call, Command, process, branch, worktree, protocol session, or transcript.
4. The first useful product has one Root Run and no Child Run requirement.
5. Logical Run lineage does not define OTP supervision.
6. A durable record does not require a permanent process.
7. Git and the filesystem remain Repository source truth.
8. SQLite records Kiln work and recovery facts. It does not replace Git or source files.
9. Model output is a proposal or Claim. It cannot grant authority, apply its own Patch, verify itself, or accept completion.
10. Capability availability, policy allowance, explicit grant, and user Approval are separate facts.
11. Context selection cannot grant authority.
12. A successful Command does not imply that a criterion passed.
13. Passing Evidence is current, complete, state-bound, and non-contradicted.
14. A product Receipt has no authority and is sealed only after committed completion.
15. Other repositories are disabled in the first product.
16. Large, sensitive, binary, or unbounded content remains outside the journal and normal model Context.
17. The smallest reliable implementation wins. Speculative flexibility is deferred.

## First useful system

```text
Developer
   │
   ▼
foreground CLI
   │
   ▼
Single-Run workflow application
   ├── domain rules and current projections
   ├── effective-authority checks
   ├── sealed Context package builder
   ├── bounded active-Repository reads
   ├── one MiniMax provider adapter and deterministic fake
   ├── exact Patch and Approval path
   ├── registered Command execution
   ├── Artifact and Evidence functions
   ├── completion evaluator and post-completion Receipt
   └── SQLite journal and projection store
           │
           └── transient model and Command Workers
```

The first-month target has one active Project, one active Repository, one Session, one initial Task, and one Root Run.

It does not require:

- Child Runs;
- a TUI;
- background scheduling;
- a general Capability broker;
- a retrieval framework;
- managed worktrees;
- code intelligence;
- protocol adapters;
- telemetry export;
- local project intelligence;
- remote execution.

## Core durable subset

### Project

One active Repository plus accepted instructions, disclosure policy, mutation policy, and registered verification configuration.

### Session

One accepted objective and its complete Kiln work history.

First-month persisted states are:

```text
active
completed
abandoned
```

### Task

One accepted desired outcome with criteria, constraints, and exclusions.

First-month persisted states are:

```text
in_progress
satisfied
abandoned
```

### Root Run

One durable, independently inspectable attempt or coordination boundary.

First-month persisted states are exactly:

```text
ready
running
waiting_for_user
orphaned
completed
failed
canceled
```

Workflow step, pending user decision, external-operation state, and Evidence state are separate facts. Do not add `created`, `waiting_for_command`, `verifying`, `stale`, or Child-oriented states to the first-month Run status.

## Durable state and operations

The Session journal records accepted work facts and material external-effect boundaries.

It supports:

- ordered sequence and revision;
- expected-revision checks;
- idempotency;
- deterministic replay;
- rebuildable current projections;
- forward migrations;
- restart reconstruction;
- conservative unknown-effect classification.

The first store uses direct Exqlite, one supervised connection, one writer, WAL, `synchronous=FULL`, foreign keys, a bounded busy timeout, and immediate write transactions. It does not depend on nested first-month transactions.

An external operation records durable intent before dispatch. If restart cannot prove a terminal result or effect, the operation is unknown and the Run is `orphaned`. Kiln does not repeat the effect automatically.

## State ownership

### Git and filesystem

Own source content, commits, refs, branch and checkout state, dirty state, and source history.

### Kiln journal

Owns accepted objective and criteria revisions, Session, Task and Run transitions, user decisions, operation intents and observations, Evidence state, recovery facts, and final completion.

### Rebuildable projections

Provide current status, workflow step, pending decisions, operation state, Patch state, criterion evaluations, warnings, unknowns, and readiness.

### Transcript

Preserves interaction history. It cannot change objective, criteria, authority, mutation, Evidence, recovery, or completion state.

## External boundaries

### Provider

MiniMax M3 is the only real initial provider. The deterministic fake is required for tests. There is no fallback.

Only the sealed Context package and required provider metadata may leave the machine under accepted Project disclosure policy.

### Repository reads

Reads and literal search remain inside one canonical selected checkout. Path escape, symlink traversal, special files, binary content, invalid encoding, stale digests, and mandatory secret paths are denied.

### Patch mutation

The authoritative Patch is a manifest of complete UTF-8 after-images for `add`, `replace`, and `delete`. Unified diff is review output only.

Only exact user Approval for the current Patch and base can permit one mutation operation. No fuzzy application, shell mutation, Git staging, commit, push, merge, publish, or deploy occurs.

### Command execution

Only registered absolute executables and validated argv can run. No shell string or arbitrary model Command is allowed.

On the supported host, a dedicated process-group helper must prove cleanup. Missing proof is unknown, not a successful timeout or cancellation.

### Evidence and completion

Exit zero, model confidence, a summary, or a Receipt cannot prove completion.

Every required criterion must have current, complete, non-contradicted passing Evidence. User acceptance binds the current aggregate evaluation. P0-W21 owns the atomic Run, Task, Session, acceptance, and proof-reference completion transaction.

A product Receipt is sealed afterward from immutable references. Receipt failure blocks delivery, not the truth of already committed completion.

## Runtime ownership

Permanent processes are justified only for live Resource ownership.

The initial runtime can include:

- one supervised SQLite connection and writer;
- transient model invocation Workers;
- transient mutation Workers;
- transient Command Workers;
- the macOS Command-host helper process used by a registered Command.

There is no process per Session, Task, Run, Evidence item, Receipt, or static policy record.

## Supported host

The first supported profile is Apple Silicon macOS 15.0 or later, local APFS, and one interactive local user. Other hosts are unsupported until their complete workflow passes host conformance and review.

## Implementation order

Prompt 8-A authorizes only P1-S01-T01 through P1-S01-T05 in exact sequence.

That sequence establishes domain state, durable store, deterministic replay and projections, the minimum foundation CLI, and the P1-S01 aggregate gate and slice verification manifest.

It does not authorize MiniMax calls, Repository source disclosure, Patch mutation, external Commands, product Evidence completion, product Receipt sealing, release packaging, Child Runs, TUI, or Wave B work.

## Deferred expansion

After the authorized Single-Run Alpha produces accepted runtime Evidence, later planning may address interruption refinement and bounded delegation.

Managed worktrees, TUI, code intelligence, generalized interoperability, local project intelligence, telemetry, and remote execution remain evidence-gated later work.
