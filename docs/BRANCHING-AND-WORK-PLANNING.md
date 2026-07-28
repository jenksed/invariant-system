# Branching and Work Planning

**Document type:** Development-process authority

This document governs development of the Kiln Repository.

It does not define the runtime identity of a Kiln Run, Agent, Worker, branch contract, or worktree lease. Product runtime Git behavior is defined in [Git Change Isolation](GIT-CHANGE-ISOLATION.md).

## Core rules

1. Kiln uses trunk-based development.
2. `main` is the integrated Project truth.
3. Kiln does not use a permanent `develop` branch or long-lived phase branch.
4. A development branch identifies one coherent ticket, slice-level integration step, fix, experiment, documentation correction, maintenance action, release, or hotfix.
5. A branch is a Git coordinate. It is not an Agent, Run, Worker, Session, slice, or OTP process identity.
6. Concurrent mutation uses separate writable worktrees or Patch Artifacts.
7. Read-only inspection does not require a branch or worktree unless a stable checkout is required.
8. Stacked pull requests integrate in dependency order and must be retested after ancestry changes.
9. A vertical slice can require several small pull requests. One slice must not become a giant branch merely because its demo spans several internal concepts.
10. Every merged ticket must leave `main` coherent, tested, and compatible with the slice's accepted contract.

## Work identifiers

Kiln uses separate identifiers for planning passes, vertical slices, tickets, experiments, and decisions:

```text
P0-W16        Phase 0 planning work package 16
P1-S01        Phase 1 vertical slice 1
P1-S01-T01    Slice 1 implementation ticket 1
P1-X01        Phase 1 experiment 1
ADR-0019      Architecture decision 19
```

The earlier `P1-W01` through `P1-W13` component identifiers are historical. New Phase 1 implementation uses slice and ticket identifiers from `docs/ROADMAP.md` and `docs/IMPLEMENTATION-SLICES.md`.

### Slice identity

A slice is a product-delivery boundary with:

- user-visible value;
- a defined security boundary;
- cross-ticket acceptance criteria;
- deterministic tests;
- a demo script;
- one aggregate slice Receipt;
- explicit exit and deferred scope.

A slice is not one required branch, process, table, runtime entity, or pull request.

### Ticket identity

A ticket is one mergeable implementation step within a slice.

A ticket should normally fit one to three focused coding Sessions and have one primary objective. It can add code, tests, documentation, migrations, fixtures, or configuration when they serve that objective.

Example:

```text
Slice:         P1-S01 Navigable simulated Runs
Ticket:        P1-S01-T01 Minimal Run event model and pure projection
Plan:          docs/work/P1-S01-T01-run-event-projection.md
Branch:        work/p1-s01-t01-run-event-projection
PR:            [P1-S01-T01] Add minimal Run event projection
Requirement:   P1-S01-T01-R01
Criterion:     P1-S01-T01-AC01
Evidence:      P1-S01-T01-E01
Slice gate:    P1-S01-G01
Slice demo:    P1-S01-D01
Slice Receipt: P1-S01-R01
```

The shared identifiers connect intent, implementation, verification, slice completion, and Evidence without creating a runtime Slice entity.

## Branch classes

### `work/`

Use `work/` for accepted roadmap tickets and material planning work.

```text
work/p1-s01-t01-run-event-projection
work/p1-s04-t04-command-worker
work/p0-w16-integrated-architecture-roadmap
```

A slice-level branch is allowed only for a small integration-only change after its tickets have merged. Do not hold the entire slice open on one long-lived branch by default.

### `fix/`

Use `fix/` for a defect in accepted behavior.

```text
fix/p1-s03-attention-response-race
fix/session-replay-order
```

Use the originating slice or ticket identifier when the defect maps clearly to one.

### `spike/`

Use `spike/` for a time-bounded experiment that answers one technical unknown.

```text
spike/p1-x01-exratatui-headless
spike/p1-x02-process-tree-control
```

A spike must define:

- the question;
- the time or effort limit;
- the Evidence to collect;
- the decision that the Evidence will inform;
- the cleanup or archive condition.

A spike does not merge experimental implementation into `main` unless it becomes an accepted ticket or slice change.

### `docs/`

Use `docs/` for isolated documentation corrections that do not change requirements, architecture, or planned behavior.

A material planning or architecture change uses `work/` and an accepted identifier.

### `chore/`

Use `chore/` for Repository maintenance that does not change product behavior.

### `release/`

Use `release/` only for short-lived release preparation.

### `hotfix/`

Use `hotfix/` only for an urgent correction to a released version.

## Naming grammar

Use:

```text
<class>/<work-id>-<purpose>
```

The purpose segment must:

- use lowercase kebab case;
- use concrete nouns or verbs;
- describe the work boundary;
- omit Agent, model, and contributor names;
- omit generic words such as `changes`, `updates`, `misc`, and `improvements`;
- omit prompts, secrets, credentials, personal data, and sensitive paths.

Examples:

```text
work/p1-s01-t01-run-event-projection
work/p1-s02-t03-context-manifest
work/p1-s04-t04-command-worker
fix/p1-s04-process-tree-cleanup
spike/p1-x01-exratatui-headless
```

## Branch purpose

Each branch has one primary objective.

A branch must not:

- represent an entire roadmap phase;
- represent a large slice when independent tickets can merge safely;
- hold unreviewed work indefinitely;
- mix unrelated cleanup with the accepted objective;
- exist only because a Run, Agent, Worker, or process exists;
- use a permanent OTP process as its ownership mechanism.

A branch can outlive one coding Session when its purpose, owner, state, and cleanup expectation remain explicit.

## Required ticket plan

Each `work/` implementation branch adds or updates one plan in `docs/work/`.

```text
docs/work/P1-S01-T01-run-event-projection.md
```

The plan uses `docs/templates/IMPLEMENTATION-PLAN.md` and records:

1. parent slice and its user-visible outcome;
2. ticket objective;
3. observed current state and Evidence;
4. assumptions and unknowns;
5. requirements;
6. proposed changes;
7. expected files or components;
8. acceptance criteria;
9. deterministic verification;
10. required ticket Evidence;
11. contribution to the slice demo and aggregate Receipt;
12. explicit exclusions.

The plan identifies dependencies on prior tickets and slices.

A planning-only work package such as P0-W16 may use the same template without a parent slice.

## Requirement and Evidence identifiers

Ticket requirements:

```text
P1-S01-T01-R01
```

Ticket acceptance criteria:

```text
P1-S01-T01-AC01
```

Ticket completion Evidence:

```text
P1-S01-T01-E01
```

Slice gates, demos, and Receipts:

```text
P1-S01-G01
P1-S01-D01
P1-S01-R01
```

A pull request links each completion Claim to a ticket criterion and current Evidence.

The final ticket or integration step for a slice must also update the aggregate slice gate and Receipt status. Earlier ticket Evidence can be referenced rather than copied.

## Slice integration

A slice can be delivered through several pull requests when:

- each ticket is independently coherent;
- contracts remain backward-compatible within the slice or migrations are explicit;
- incomplete behavior is unreachable, simulated, fixture-only, or safely disabled;
- the final user-visible demo is not claimed before all required gates pass;
- no ticket creates ambient authority for a later ticket;
- the aggregate Receipt binds the exact final commit and all required Evidence.

Do not use a permanent slice branch.

When an integration-only branch is necessary, it must:

- contain no unrelated feature work;
- be short-lived;
- state which ticket heads it integrates;
- rerun the entire slice gate;
- disappear after integration.

## Worktree use during Kiln development

The development process follows the same isolation principles as the product specification.

- One coding writer can use the primary checkout when no other writer mutates it.
- Concurrent mutating work uses separate writable worktrees.
- One writable worktree has one active mutation owner.
- Read-only reviewers can inspect a checkout without receiving a branch.
- A verifier does not edit the branch that it evaluates.
- Untrusted or tightly restricted work can return a Patch Artifact instead of owning a worktree.
- Dirty or uncertain worktrees are preserved until the owner approves cleanup.

These development controls do not claim that the Kiln runtime has implemented worktree leases.

## Commit rules

Commits represent meaningful implementation states. They do not record every model, Agent, Tool, or protocol action.

A commit can use the ticket identifier:

```text
P1-S01-T01: add Run event envelope
P1-S01-T01: add deterministic projection tests
```

Commit messages do not contain private prompts, secrets, credentials, or sensitive user content.

Agent attribution belongs in the completion record and Receipt. It must not impersonate a human author.

## Pull-request rules

A pull-request title uses:

```text
[P1-S01-T01] Add minimal Run event projection
```

A pull-request body states:

- parent slice and user-visible contribution;
- objective;
- observed starting state;
- changes;
- acceptance status;
- verification Evidence;
- security boundary;
- failures and warnings;
- unknowns and exclusions;
- dependencies;
- effect on the slice demo and Receipt.

A pull request must not claim the whole slice complete unless it executes the aggregate gate and demo against its exact head.

## Merge rules

Before merge, the branch must:

1. contain one coherent ticket or planning work package;
2. satisfy its acceptance criteria or disclose every unmet criterion;
3. execute required deterministic verification;
4. bind verification to the exact tested commit or dirty state;
5. disclose failures, warnings, unknowns, and exclusions;
6. match its completion record;
7. include an ADR for each material architecture change;
8. update roadmap or slice status when the merge changes milestone state;
9. reconcile against current `main`;
10. verify projected merged state when the change can interact with trunk changes;
11. preserve the parent slice's security boundary and deferred scope.

The authoring Agent or Run does not authorize its own merge. The user or an accepted independent gate authorizes integration.

Squash merge is the default for one coherent ticket. Preserve multiple commits only when their boundaries have lasting review, release, or diagnostic value.

Delete the branch after merge when:

- it contains no unmerged work;
- required Artifacts and Evidence are retained;
- no dirty worktree depends on it;
- cleanup is authorized.

## Parallel work

Parallel tickets should have low file overlap and settled interfaces.

When two tickets depend on an unsettled interface, complete the contract-defining ticket first.

Concurrent writers must not share one writable checkout.

Independent read-only work can proceed in parallel when Repository state movement does not invalidate the Task.

Parallel tickets within one slice must not each invent separate versions of the same domain event, projection, Capability, or adapter contract.

## Stacked pull requests

Use a stack only when one reviewable ticket has a real dependency on another and both remain independently understandable.

For each dependent pull request:

1. create the child branch from the exact prerequisite commit;
2. set the child pull-request base to the prerequisite branch while it is open;
3. record the direct parent branch and commit in both plans;
4. review and verify each layer independently;
5. merge the oldest prerequisite into `main` first;
6. rebase or merge current `main` into the next child branch;
7. retarget the child pull request to `main`;
8. rerun affected verification after ancestry changes;
9. repeat in dependency order.

Do not assume a child reached `main` because it merged into an already-merged prerequisite branch.

A changed ancestor invalidates affected descendant Evidence.

The default maximum stack depth is three. Deeper stacks require explicit owner approval and a reason that simpler sequencing cannot satisfy.

## Candidate branches

Candidate implementations are exceptional and follow `docs/GIT-CHANGE-ISOLATION.md`.

They require:

- the same accepted Task and ticket contract;
- the same base commit;
- independent work and Context;
- comparable verification;
- a non-author evaluator;
- explicit acceptance and rejection records.

Prefer one accepted candidate over combining fragments from several candidates.

## Temporary integration branches

Kiln does not use permanent integration branches.

A temporary integration branch requires:

- one owner;
- one purpose;
- explicit source branches;
- one target;
- creation and expiration conditions;
- required integration checks;
- cleanup rules.

Prefer direct sequential integration when it can safely prove the slice.

## Slice completion

A slice is complete only when:

1. every required ticket is integrated;
2. the slice acceptance gates pass against one exact `main` or projected-merge state;
3. the deterministic demo script passes;
4. the required aggregate Receipt is sealed;
5. unresolved warnings, exclusions, and deferred concerns remain visible;
6. the user or accepted policy accepts the milestone when acceptance is required;
7. roadmap and milestone status are updated.

A model summary, collection of merged tickets, or passing individual CI run does not complete the slice by itself.