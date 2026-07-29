# P0-W23: Patch, Approval, mutation, and recovery

**Document type:** Focused planning work package  
**Status:** Implemented, verified, accepted, and integrated  
**Integrated through:** Pull request 30, merge commit `58720bcfba815d77c6d815e0ca004e0546cb9a6e`  
**Final design head:** `2800736164763ed931782714a5ee5b84ab18d53a`  
**Depends on:** P0-W21 and P0-W22 integrated  
**Scope:** Patch proposal, user Approval, single-checkout mutation, rollback, and uncertain-effect recovery only  
**Build authorization:** Not issued

## Objective

Define one exact text-Patch representation, one Approval binding, one mutation owner, deterministic application preconditions, rollback expectations, and conservative recovery after partial or uncertain filesystem effects.

## Entry evidence

- P0-W21 integrated at `ca21d0bbc25ddf5861191f8bde374e0761d86c0a` and controls operation intent, terminal-or-unknown observation, restart, orphan, and completion boundaries.
- P0-W22 integrated at `abbded1af773981c40e0810c19ce043b9485daeb` and controls Repository observation, canonical paths, source reads, Context, `change.propose`, and disclosure.
- The first-month product has one selected writable checkout and one mutation owner.
- Production source contains no Patch, Approval, mutation, rollback, or recovery implementation.

## Accepted decisions

P0-W23 established:

1. Use one canonical Patch manifest of complete UTF-8 text after-images.
2. Support `add`, `replace`, and `delete` only.
3. Use generated unified diff for review only, never as mutation authority.
4. Bind the Patch to one W22 Repository state and exact before facts for each path.
5. Compute SHA-256 over canonical manifest bytes and ordered after-image digests.
6. Limit the first contract to 32 paths, one MiB per after-image, and four MiB total after-image and rollback content.
7. Deny binary, symlink, special-file, mode, submodule, Git metadata, and out-of-root mutation.
8. Require explicit local-user Approval for the exact Patch, base, paths, warnings, preview, objective, criteria, and Session revision.
9. Allow only `approve` or `deny`; modifications create a new Patch.
10. Expire Approval after 30 minutes or any bound state change.
11. Consume Approval when the P0-W21 `patch_application` operation intent commits.
12. Use one mutation coordinator and one selected-checkout lease.
13. Prepare and verify rollback data and staged after-images before intent commit.
14. Maintain an operation-specific progress manifest for reconciliation.
15. Apply add and replace before delete in deterministic path order.
16. Observe every path and final target state.
17. Attempt reverse-order rollback after partial failure.
18. Treat exact base restoration as known failure and exact target as known success.
19. Treat mixed or unclassified state as unknown and orphaned under P0-W21.
20. Never retry or reapply automatically after uncertainty.
21. Patch application does not format, test, stage, commit, push, merge, publish, or deploy.

## Files integrated

- `docs/PATCH-APPROVAL-AND-MUTATION.md`
- `docs/decisions/0024-use-complete-text-after-images-for-first-patches.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W22-model-context-repository-boundary.md`
- `docs/work/P0-W23-patch-approval-mutation.md`

The final branch contained six Markdown files, 1,240 additions, and 126 deletions. It changed no production source, tests, dependencies, configuration, JSON Schemas, CI, scripts, preflight, Skills, prompts, agents, or scaffolding.

## Acceptance evidence

| Criterion | Result | Evidence |
| --- | --- | --- |
| One Patch representation and exact base binding | Pass | Patch sections 2 and 3 |
| Canonical digest and deterministic preview | Pass | canonicalization and review sections |
| Supported operations and limits | Pass | operation and limit sections |
| Approval authority, lifetime, denial, invalidation, consumption, and replay | Pass | Approval section |
| One mutation owner and lease | Pass | ownership section |
| Rollback and staging precede effects | Pass | preparation section |
| Deterministic application and target observation | Pass | application section |
| Partial failure and reverse rollback | Pass | failure section |
| Restart classification and unknown-effect behavior | Pass | restart matrix |
| W21 and W22 authority unchanged | Pass | upstream audit |
| Review-head Repository validation | Pass | CI `30421607273` on `3e6045c95a10a9bc5445a0210281b95ba965b5ac` |
| Exact final-head validation | Pass | CI `30421678305` on `2800736164763ed931782714a5ee5b84ab18d53a` |

## Upstream ownership audit

P0-W23 consumes W21 operation identity, intent-before-dispatch, terminal-or-unknown result, expected revision, idempotency, restart, and orphan rules. It consumes W22 canonical root, Repository observation, path controls, `change.propose`, and Artifact references.

It does not change Session, Task, or Run states; transitions; journal, projection, migration, provider, Context, Tool projection, Repository reads, disclosure, or secret policy. Any conflict resolves in favor of the upstream authority.

## Verification

Final head `2800736164763ed931782714a5ee5b84ab18d53a` passed GitHub CI run `30421678305`.

The run passed Vale, current preflight behavior tests, Project agent-asset validation, dependency installation, formatting, warnings-as-errors compilation, compile-connected cycle detection, and ExUnit.

The current preflight result proves obsolete P0 mechanics only. It does not prove P1 ticket compatibility.

## Explicit exclusions

P0-W23 did not implement mutation; add dependencies; alter lifecycle, persistence, provider, Context, or Repository authority; define Command, formatting, Evidence, Receipt, completion, or CLI behavior; add binary, symlink, mode, worktree, concurrent writer, Git publication, deployment, or Wave B scope; or issue build authorization.

## Gate verdict

**P0-W23 passed and is integrated.**

Build authorization remains denied.

## Exact next action

Record OD-02 and run P0-W24 on current `main`.
