# P0-W23: Patch, Approval, mutation, and recovery

**Document type:** Focused planning work package  
**Status:** In progress  
**Branch:** `work/p0-w23-patch-approval-mutation`  
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
- Existing execution and Git Schemas contain broader worktree, environment, and transactional Patch concepts than the first-month target.

## Questions resolved by this round

- Authoritative Patch representation and human review representation.
- Base and Repository-state binding.
- Canonical Patch digest.
- Supported operations, path and size limits, and unsupported content.
- Stale Patch behavior.
- User Approval subject, lifetime, invalidation, denial, and one-time use.
- Mutation authority and checkout lease.
- Preparation, rollback bundle, progress manifest, deterministic operation order, and post-state observation.
- Partial failure, rollback success, rollback failure, crash, and unknown-effect recovery.
- Exact W21 and W22 ownership consumption.

## Requirements

- Use one Patch representation.
- Bind every proposal to exact Repository state and per-path before state.
- Define one canonical digest and deterministic preview.
- Define Approval authority, subject, lifetime, invalidation, denial, consumption, and replay behavior.
- Define one mutation owner and no concurrent writer.
- Define application preconditions and deterministic operation order.
- Define rollback data before the first file effect.
- Define progress observation and restart classification without automatic replay.
- Define known failure versus unknown effect.
- Preserve P0-W21 lifecycle and P0-W22 Repository and provider authority.
- Do not add Command execution, Evidence completion, CLI syntax, Child Runs, worktrees, or implementation.

## Expected files

- `docs/PATCH-APPROVAL-AND-MUTATION.md`
- `docs/decisions/0024-use-complete-text-after-images-for-first-patches.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W23-patch-approval-mutation.md`

## Acceptance criteria

- One Patch representation, base binding, digest, path, operation, and size contract exists.
- Unified diff is review output rather than mutation authority.
- Approval authority, lifetime, invalidation, denial, one-time use, and replay are explicit.
- One mutation owner and one checkout lease exist.
- Preparation, rollback bundle, progress manifest, apply order, post-state validation, and cleanup are explicit.
- Partial failure, rollback, interruption, restart, unknown effect, and next actions are explicit.
- No fuzzy application, hidden formatting, automatic Command, automatic Git staging, commit, push, or merge exists.
- No W21 lifecycle or W22 Repository boundary is redefined.
- Exact final-head CI passes.

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

## Required completion evidence

- P0-W23-E01: W21 and W22 integrated merge Evidence.
- P0-W23-E02: Patch representation, canonicalization, digest, and base-binding contract.
- P0-W23-E03: Approval and authority contract.
- P0-W23-E04: mutation preparation, progress, rollback, and post-state contract.
- P0-W23-E05: partial failure, crash, restart, and unknown-effect matrix.
- P0-W23-E06: W21 and W22 ownership audit.
- P0-W23-E07: planning-only compare and exact final-head CI.

## Explicit exclusions

P0-W23 does not:

- implement Patch application or add dependencies;
- define or modify lifecycle, journal, projection, migration, or provider behavior;
- define registered Commands, formatting, tests, Evidence, Receipts, completion evaluation, or CLI presentation;
- add binary Patch, symlink, mode change, rename semantics, worktrees, concurrent writers, commit, push, merge, deploy, or remote execution;
- run Wave B work;
- issue build authorization.
