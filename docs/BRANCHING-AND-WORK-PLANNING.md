# Branching and Work Planning

**Document type:** Reference

This document governs development of the Kiln Repository.

It does not define the runtime identity of a Kiln Run, Agent, Worker, branch contract, or worktree lease. Product runtime Git behavior is defined in [Git Change Isolation](GIT-CHANGE-ISOLATION.md).

## Core rules

1. Kiln uses trunk-based development.
2. `main` is the integrated Project truth.
3. Kiln MUST NOT use a permanent `develop` branch or long-lived phase branch.
4. A development branch identifies one planned work package, fix, experiment, documentation correction, maintenance action, release, or hotfix.
5. A branch is a Git coordinate. It is not an Agent identity, Run identity, Worker identity, or OTP process identity.
6. Concurrent mutation uses separate writable worktrees or Patch Artifacts.
7. Read-only inspection does not require a branch or worktree unless a stable checkout is required.
8. Stacked pull requests integrate in dependency order and MUST be retargeted after each prerequisite reaches `main`.

## Work identifiers

Kiln uses stable identifiers:

```text
P1          Phase 1
P1-W02      Phase 1 work package 2
P1-X01      Phase 1 experiment 1
ADR-0013    Architecture decision 13
```

A work-package identifier remains the same in each related Artifact.

```text
Plan:          docs/work/P1-W02-supervised-command.md
Branch:        work/p1-w02-supervised-command
Issue title:   [P1-W02] Supervised command execution
PR title:      [P1-W02] Add supervised command execution
Requirement:   P1-W02-R01
Criterion:     P1-W02-AC01
Evidence:      P1-W02-E01
```

The shared identifier connects intent, implementation, verification, and completion Evidence without a second planning taxonomy.

## Branch classes

### `work/`

Use `work/` for accepted roadmap work packages.

```text
work/p1-w02-supervised-command
work/p3-w04-evidence-freshness
```

A `work/` branch can contain code, tests, documentation, and configuration when they serve one objective.

### `fix/`

Use `fix/` for a defect in accepted behavior.

```text
fix/p1-w03-cancel-race
fix/session-replay-order
```

Use the originating work-package identifier when the defect maps to one work package.

### `spike/`

Use `spike/` for a time-bounded experiment that answers one technical unknown.

```text
spike/p1-x01-pty-options
spike/p5-x02-extension-framing
```

A spike MUST define:

- the question;
- the time or effort limit;
- the Evidence to collect;
- the decision that the Evidence will inform.

A spike MUST NOT merge experimental implementation into `main` unless it becomes an accepted work package.

### `docs/`

Use `docs/` for isolated documentation corrections that do not change requirements, architecture, or planned behavior.

```text
docs/clarify-local-setup
```

A material planning or architecture change uses `work/` and the applicable identifier.

### `chore/`

Use `chore/` for Repository maintenance that does not change product behavior.

```text
chore/update-ci-cache
chore/refresh-dev-runtime
```

### `release/`

Use `release/` only for a short-lived release preparation branch.

```text
release/v0.1.0
```

### `hotfix/`

Use `hotfix/` only for an urgent correction to a released version.

```text
hotfix/v0.1.1-session-corruption
```

## Naming grammar

Use:

```text
<class>/<work-id>-<purpose>
```

The purpose segment MUST:

- use lowercase kebab case;
- use concrete nouns or verbs;
- describe the work boundary;
- omit Agent, model, and contributor names;
- omit generic words such as `changes`, `updates`, `misc`, and `improvements`;
- omit prompts, secrets, credentials, personal data, and sensitive paths.

Examples:

```text
work/p1-w01-session-domain
work/p1-w02-event-journal
work/p1-w03-command-supervision
fix/p1-w03-descendant-cleanup
spike/p1-x01-process-group-control
```

## Branch purpose

Each branch has one primary objective.

A branch SHOULD be mergeable after one to three focused development Sessions. Split a branch when it contains independent objectives.

A branch MUST NOT:

- represent an entire roadmap phase;
- hold unreviewed work indefinitely;
- mix unrelated cleanup with the accepted objective;
- exist only because a Run or Agent exists;
- use a permanent OTP process as its ownership mechanism.

A branch can outlive the active coding Session when its purpose, owner, state, and cleanup expectation remain explicit.

## Required work-package plan

Each `work/` branch adds or updates one plan in `docs/work/`.

The plan filename starts with the work-package identifier.

```text
docs/work/P1-W03-command-supervision.md
```

The plan uses `docs/templates/IMPLEMENTATION-PLAN.md` and contains:

1. objective;
2. observed current state and Evidence;
3. assumptions and unknowns;
4. requirements;
5. proposed changes;
6. expected files or components;
7. acceptance criteria;
8. verification commands;
9. required completion Evidence;
10. explicit exclusions.

The plan identifies dependencies on other work packages.

## Requirement and Evidence identifiers

Requirements:

```text
P1-W03-R01
```

Acceptance criteria:

```text
P1-W03-AC01
```

Completion Evidence:

```text
P1-W03-E01
```

A pull request links each completion Claim to an acceptance criterion and its Evidence.

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

Commits represent meaningful implementation states. They do not record every model, Agent, or tool action.

A commit can use the work-package identifier:

```text
P1-W03: add command lifecycle types
P1-W03: supervise command cancellation
```

Commit messages do not contain private prompts, secrets, credentials, or sensitive user content.

Agent attribution belongs in the completion record and Receipt. It must not impersonate a human author.

## Pull-request rules

A pull-request title uses:

```text
[P1-W03] Add supervised command execution
```

A pull-request body states:

- objective;
- observed starting state;
- changes;
- acceptance status;
- verification Evidence;
- failures and warnings;
- unknowns and exclusions;
- dependencies.

## Merge rules

Before merge, the branch MUST:

1. contain one coherent work package;
2. satisfy its acceptance criteria or disclose each unmet criterion;
3. execute its required verification;
4. bind verification to the exact tested commit or dirty state;
5. disclose failures, warnings, unknowns, and exclusions;
6. match the completion record;
7. include an ADR for each material architectural decision;
8. update roadmap status when the merge changes phase status;
9. reconcile against current `main`;
10. verify the projected merged state when the change can interact with trunk changes.

The authoring Agent or Run does not authorize its own merge. The user or an accepted independent gate authorizes integration.

Squash merge is the default for one coherent work package. Preserve multiple commits only when their boundaries have lasting review, release, or diagnostic value.

Delete the branch after merge when:

- the branch contains no unmerged work;
- required Artifacts and Evidence are retained;
- no dirty worktree depends on it;
- cleanup is authorized.

## Parallel work

Parallel branches SHOULD have low file overlap and settled interface boundaries.

When two branches depend on an unsettled interface, complete the interface-defining work package first.

Concurrent writers MUST NOT share one writable checkout.

Independent read-only work can proceed in parallel when Repository state movement does not invalidate the task.

## Stacked pull requests

Use a stack only when one reviewable work package has a real dependency on another.

For each dependent pull request:

1. create the child branch from the exact prerequisite commit;
2. set the child pull-request base to the prerequisite branch while the prerequisite is open;
3. record the direct parent branch and commit in both plans;
4. review and verify each layer independently;
5. merge the oldest prerequisite into `main` first;
6. rebase or merge current `main` into the next child branch;
7. retarget the child pull request to `main`;
8. rerun affected verification after ancestry changes;
9. repeat in dependency order.

Do not merge a child into a prerequisite branch after that prerequisite has already merged to `main` and then assume the child reached `main`.

A changed ancestor invalidates affected descendant Evidence.

The default maximum stack depth is three. Deeper stacks require an explicit plan and owner approval.

## Candidate branches

Candidate branches are exceptional and follow `docs/GIT-CHANGE-ISOLATION.md`.

They require:

- the same accepted Task;
- the same base commit;
- independent work and Context;
- comparable verification;
- a non-author evaluator;
- explicit acceptance and rejection records.

Prefer one accepted candidate over combining fragments from several candidates.

## Temporary integration branches

Kiln does not use a permanent integration branch.

A temporary integration branch requires:

- one owner;
- one purpose;
- explicit source branches;
- one target branch;
- an expiration condition;
- a maximum lifetime;
- required integration checks;
- a cleanup plan.

Prefer branch-by-abstraction or disabled feature flags when partial work can safely enter `main` without activating incomplete behavior.

## Phase 1 branch map

The existing Phase 1 map remains provisional until the post-P0-W10 roadmap reconciliation replaces it.

| ID | Branch | Purpose | Depends on |
| --- | --- | --- | --- |
| P1-W01 | `work/p1-w01-session-domain` | Define minimum Workspace, Project, Repository, Session, Task, Run, event, policy, Context, Capability, Evidence, and Git coordination types. | P0 |
| P1-W02 | `work/p1-w02-event-journal` | Persist append-oriented domain and coordination events in SQLite and reconstruct projections. | P1-W01 |
| P1-W03 | `work/p1-w03-command-supervision` | Start, stream, time out, cancel, and record a Command. | P1-W01, P1-W02 |
| P1-W04 | `work/p1-w04-git-observation-isolation` | Observe Git state, create one isolated task worktree, bind one lease, and invalidate stale Evidence. | P1-W01, P1-W02, P1-W03 |
| P1-W05 | `work/p1-w05-cli-projection` | Expose Session, Run, execution, Context, Capability, Git, Evidence, and attention state through the command-line interface. | P1-W02 through P1-W04 |
| P1-W06 | `work/p1-w06-restart-recovery` | Reconstruct interrupted Sessions, Runs, Git ownership, and last known safe state. | P1-W02 through P1-W04 |
| P1-W07 | `work/p1-w07-phase-proof` | Execute and record the Phase 1 acceptance scenario. | P1-W05, P1-W06 |

The reconciliation can replace these packages. Each accepted implementation package requires its own plan.

## Bootstrap exception

`agent/bootstrap-project-foundation` predates this policy. It remains a one-time exception.
