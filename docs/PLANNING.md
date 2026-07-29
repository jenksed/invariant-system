# Kiln Planning Control

**Document type:** Planning authority index  
**Status:** Active  
**Build authorization:** Not issued

## Integrated planning baseline

| Pass or decision | Integrated equivalent |
| --- | --- |
| Prompt 1 | Pull request 22, merge commit `ef487c432a04de705e58ec79569abe5bb51e3d7a` |
| Prompt 2 | Pull request 23, merge commit `33da2a718d8d5305bf89035503ac372f07e80a6e` |
| Prompt 3 | Pull request 24, merge commit `0dba694f2a54ab517a2c43bbbd5c77f526a02e65` |
| Prompt 4 | Pull request 25, merge commit `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| OD-01 | Pull request 26, merge commit `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1` |
| P0-W21 | Pull request 27, merge commit `ca21d0bbc25ddf5861191f8bde374e0761d86c0a` |
| P0-W21 closeout | Pull request 28, merge commit `6c80436b9c220a93b0ff37372deacb1f7ec0fd32` |
| P0-W22 | Pull request 29, merge commit `abbded1af773981c40e0810c19ce043b9485daeb` |

## Current authorities

Use these files in this order:

1. [Planning Completion Baseline](PLANNING-COMPLETION-BASELINE.md).
2. [Product Scope and Minimum Architecture](PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md).
3. [Implementation Disposition Register](IMPLEMENTATION-DISPOSITION-REGISTER.md).
4. [Planning Round Register](PLANNING-ROUND-REGISTER.md).
5. [Owner Decision Register](OWNER-DECISIONS.md).
6. [Root Run Lifecycle and Durable Journal](ROOT-RUN-LIFECYCLE-AND-JOURNAL.md) — integrated lifecycle and persistence authority.
7. [Model, Context, and Repository Boundary](MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md) — integrated provider, Context, Tool, Repository-read, disclosure, and secret authority.
8. [Patch, Approval, and Mutation](PATCH-APPROVAL-AND-MUTATION.md) — proposed Patch, Approval, mutation, rollback, and uncertain-effect authority.
9. [Planning Round Authoritative Inputs](PLANNING-ROUND-INPUTS.md).
10. [Roadmap](ROADMAP.md).
11. [Implementation Slices](IMPLEMENTATION-SLICES.md).
12. [Slice Acceptance Gates](SLICE-ACCEPTANCE-GATES.md).

The Architecture, Run Model, Session Model, accepted ADRs, and focused specifications provide subject authority. They cannot broaden scope or reorder delivery without an accepted authority change.

The P0-W21 and P0-W22 work records and this index control their integration status. Branch-era status text remaining in large focused specifications is non-authoritative bookkeeping.

## Integrated upstream authority

### P0-W21

P0-W21 owns Session, Task, and Root Run states; transitions; operation intent and observation; journal, projection, migration, restart, orphan, and completion-transaction boundaries.

### P0-W22

P0-W22 owns MiniMax M3, deterministic fake provider, sealed Context, four-Tool projection, active-Repository reads, disclosure, secrets, and transient provider-message behavior.

Later rounds cannot redefine either authority.

## Proposed P0-W23 authority

P0-W23 proposes:

- one canonical Patch manifest of complete UTF-8 text after-images;
- `add`, `replace`, and `delete` operations only;
- generated unified diff as review output only;
- exact Repository and per-path before-state binding;
- SHA-256 Patch digest over canonical manifest and after-image digests;
- maximum 32 paths and four MiB total after-image data;
- explicit one-time user Approval bound to Patch, base, paths, warnings, and Session revision;
- Approval expiry after 30 minutes or any bound state change;
- one mutation owner and one selected-checkout lease;
- complete rollback bundle and progress manifest before the first file effect;
- deterministic add, replace, and delete ordering;
- exact target and base observation;
- reverse rollback after partial failure;
- unknown-effect and orphan handling when neither base nor target can be proved;
- no automatic retry or reapplication;
- no formatting, Command, Git staging, commit, push, merge, publish, deploy, worktree, binary, symlink, or mode-change scope.

ADR-0024 owns the proposed complete-after-image representation.

## Upstream ownership audit

P0-W23 consumes W21 operation identity, intent-before-dispatch, terminal-or-unknown result, idempotency, restart, and orphan rules. It consumes W22 Repository observation, canonical paths, file controls, `change.propose`, and Artifact references.

It does not change lifecycle, persistence, provider, Context, Tool projection, Repository reads, or disclosure. Any conflict resolves in favor of the upstream authority.

## Wave A sequence

```text
P0-W21 integrated
→ P0-W22 integrated
→ validate and integrate P0-W23
→ record OD-02
→ P0-W24
→ P0-W25
→ Prompt 6-A
→ Prompt 7-A
→ Prompt 8-A
```

Prompt 7-A remains immediately before Prompt 8-A. Prompt 8-A is the only pass that may issue first-month build authorization.

## Current owner decisions

- OD-01 is accepted through ADR-0021.
- OD-02 remains pending and must be accepted before P0-W24 and P0-W25 complete.

## Wave B entry gate

P0-W26 and P0-W27 remain blocked until an authorized Single-Run Alpha produces accepted Evidence for one real change, durable restart, controlled Patch authority, registered verification, criterion-bound Evidence, one valid Receipt, and observed failure or interruption behavior.

Only then:

```text
P0-W26
→ P0-W27
→ Prompt 6-B
→ Prompt 7-B
→ Prompt 8-B
→ only delegated scope authorized by Prompt 8-B
```

## Current next action

Complete P0-W23 review and exact-head validation. Integrate it, then record OD-02 and begin P0-W24.
