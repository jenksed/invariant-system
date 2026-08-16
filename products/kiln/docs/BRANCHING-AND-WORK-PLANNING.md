# Branching and Work Planning

**Document type:** Development-process authority  
**Status:** Active  
**Implementation authorization:** `docs/WAVE-A-ADJUDICATION-AND-AUTHORIZATION.md`

This document governs development of the Kiln Repository.

It does not define runtime Run identity, product branch behavior, or managed worktree support. Product runtime Git behavior remains separately planned and managed worktrees are deferred.

## Core rules

1. Kiln uses trunk-based development.
2. `main` is the integrated Project truth.
3. Kiln does not use a permanent `develop` branch or long-lived phase branch.
4. One development branch identifies one coherent ticket, bounded planning package, fix, experiment, documentation correction, maintenance action, release, or hotfix.
5. A branch is a Git coordinate. It is not an Agent, Run, Worker, Session, slice, or process identity.
6. Concurrent coding writers use separate writable worktrees. This is a development-process control and does not claim product worktree support.
7. Read-only review does not require a branch unless a stable checkout is required.
8. Dependent pull requests integrate in dependency order and are retested after ancestry changes.
9. A vertical slice can use several small pull requests.
10. Every merged ticket leaves `main` coherent, tested, and within its accepted slice boundary.
11. A plan or ticket name does not authorize work. Prompt 8-A currently authorizes only P1-S01-T01 through T06 in their recorded merge order (T01 → T02 → T03 → T06 → T04 → T05).

## Work identifiers

```text
P0-W29        planning work package
P1-S01        vertical slice
P1-S01-T01    implementation ticket
P1-X01        experiment
ADR-0027      architecture decision
```

Earlier component-oriented P1 work identifiers are historical. New Phase 1 work uses slice and ticket identifiers from the accepted roadmap.

## Slice identity

A slice is a product-delivery boundary with:

- user-visible value;
- a security boundary;
- cross-ticket acceptance criteria;
- deterministic gates;
- a demo;
- one slice verification manifest;
- explicit exit and deferred scope.

A slice verification manifest is implementation Evidence. It is not a product Receipt.

A product Receipt is sealed only after committed product completion under P0-W24.

A slice is not one required branch, process, table, runtime entity, or pull request.

## Ticket identity

A ticket is one mergeable implementation step within a slice.

A ticket has:

- one primary objective;
- one accepted branch;
- one plan under `docs/work/`;
- explicit requirements, criteria, Evidence, and exclusions;
- bounded contribution to the slice gate, demo, and verification manifest;
- a completed closeout record before merge.

Current authorized example:

```text
Slice:                  P1-S01 Durable single-Run foundation
Ticket:                 P1-S01-T01 Durable domain foundation
Plan:                   docs/work/P1-S01-T01-domain-foundation.md
Branch:                 work/p1-s01-t01-domain-foundation
PR:                     [P1-S01-T01] Implement durable domain foundation
Requirement:            P1-S01-T01-R01
Criterion:              P1-S01-T01-AC01
Evidence:               P1-S01-T01-E01
Slice gate:             P1-S01-G01
Slice demo:             P1-S01-D01
Verification manifest:  P1-S01-V01
```

## Branch classes

### `work/`

Use for accepted roadmap tickets and material planning work.

```text
work/p1-s01-t01-domain-foundation
work/p1-s01-t02-durable-store
work/p0-w29-wave-a-adjudication
```

A slice-level branch is allowed only for a small integration-only change after its tickets merge. Do not hold an entire slice on one long-lived branch by default.

### `fix/`

Use for a defect in accepted behavior.

### `spike/`

Use for a time-bounded experiment that answers one technical unknown.

A spike defines:

- the question;
- effort limit;
- Evidence to collect;
- decision informed;
- cleanup or archive condition.

Experimental implementation does not merge unless it becomes accepted work.

### `docs/`, `chore/`, `release/`, and `hotfix/`

Use these only for their narrow conventional purposes. A material planning or architecture change uses `work/` and an accepted work identifier.

## Naming grammar

```text
<class>/<work-id>-<purpose>
```

The purpose uses lowercase kebab case, describes the work boundary, omits contributor or model names, and contains no prompts, secrets, credentials, personal data, or sensitive paths.

Current accepted P1-S01 branches are:

```text
work/p1-s01-t01-domain-foundation
work/p1-s01-t02-durable-store
work/p1-s01-t03-replay-projections
work/p1-s01-t06-workflow-surface
work/p1-s01-t04-foundation-cli
work/p1-s01-t05-slice-gate
```

## Required ticket plan

Each `work/` implementation branch adds or updates exactly one matching plan under `docs/work/`.

The plan uses `docs/templates/IMPLEMENTATION-PLAN.md` and records:

1. parent slice and exact contribution;
2. objective;
3. observed current state and Evidence;
4. assumptions and unknowns;
5. requirements;
6. security boundary;
7. proposed changes;
8. expected files or components;
9. acceptance criteria;
10. deterministic verification;
11. demo contribution;
12. required completion Evidence;
13. contribution to slice gates and verification manifest;
14. explicit exclusions;
15. completion record.

The plan identifies exact dependencies. A dependent ticket does not begin until its prerequisite merges and is accepted.

## Evidence identifiers

```text
P1-S01-T01-R01     ticket requirement
P1-S01-T01-AC01    ticket acceptance criterion
P1-S01-T01-E01     ticket completion Evidence
P1-S01-G01         slice gate
P1-S01-D01         slice demo
P1-S01-V01         slice verification manifest
```

A pull request links each completion Claim to current ticket Evidence.

The final ticket updates the aggregate gate, demo, closeout, and verification manifest. Earlier Evidence is referenced rather than copied.

## Branch purpose

A branch has one primary objective.

It does not:

- represent an entire phase;
- contain multiple independently mergeable tickets;
- mix unrelated cleanup with implementation;
- reserve speculative architecture;
- exist because a runtime Run or process exists;
- widen authorization through incidental files.

## Slice integration

A slice can use several pull requests when:

- each ticket is independently coherent;
- contracts remain compatible or migrations are explicit;
- incomplete behavior is absent or explicitly unsupported;
- the final demo is not claimed before all gates pass;
- no ticket grants ambient authority to later work;
- the final verification manifest binds the exact integrated commit and Evidence.

Do not use a permanent slice branch.

An integration-only branch, when required, is short-lived, contains no feature work, lists exact ticket heads, reruns the entire slice gate, and disappears after integration.

## Worktree use during development

- One coding writer can use the primary checkout when no other writer mutates it.
- Concurrent mutating work uses separate writable worktrees.
- One writable worktree has one mutation owner.
- Read-only reviewers can inspect without write authority.
- A verifier does not edit the branch it evaluates.
- Dirty or uncertain worktrees remain until cleanup is authorized.

These controls do not mean the Kiln product has implemented managed worktrees.

## Commit and pull-request rules

Commits represent meaningful implementation states and can use the ticket identifier.

A pull-request title uses:

```text
[P1-S01-T01] Implement durable domain foundation
```

The pull-request body states:

- parent slice and contribution;
- objective and starting state;
- changes;
- acceptance status;
- verification Evidence;
- security boundary;
- failures, warnings, unknowns, and exclusions;
- dependencies;
- effect on slice gates, demo, and verification manifest.

A pull request does not claim the slice complete unless the exact aggregate gate and demo pass.

## Merge rules

Before merge, a branch:

1. contains one coherent ticket or planning package;
2. satisfies criteria or discloses every unmet criterion;
3. executes required deterministic verification;
4. binds verification to the exact tested commit;
5. records failures, warnings, unknowns, and exclusions;
6. completes its closeout record;
7. includes an ADR for a material architecture change;
8. updates slice or roadmap status when required;
9. reconciles with current `main`;
10. verifies projected merged state when trunk interaction matters;
11. preserves the parent slice security boundary;
12. remains inside explicit Prompt 8-A authorization.

The authoring agent does not authorize its own merge. The user or accepted independent gate authorizes integration.

Delete the branch after merge when no unmerged work or retained worktree depends on it.

## Sequential P1-S01 rule

P1-S01 tickets are not parallel work.

Merge and accept in this order:

```text
T01 domain foundation
→ T02 durable store
→ T03 replay and projections
→ T06 shared Kiln.Workflow application boundary (consumed by T04)
→ T04 foundation CLI
→ T05 aggregate gate and slice verification manifest
```

Any ticket that requires a later subsystem pauses and returns to planning.

## Stacked pull requests

Use a stack only when each layer remains independently understandable and the user chooses to overlap review.

Merge the oldest prerequisite first, rebase the dependent branch onto current `main`, rerun exact validation, and resolve conflicts in favor of the accepted upstream ticket.
