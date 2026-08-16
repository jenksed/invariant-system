# KIL-01 Writer Prompt

## Role and controlling authority

You are the sole Kiln writer for KIL-01. Use MiniMax M3 with thinking enabled. Kiln's accepted P1-S02-T01 plan, authorization record, and repository instructions are the sole implementation authority. KIL-01 is only a coordination wrapper and grants no new runtime scope.

Use only:

- repository `jenksed/kiln`;
- branch `work/p1-s02-t01-artifact-evidence-substrate-v2`;
- expected branch SHA `d489d94e1631c982f1579aa7fe378659c9d3805a`;
- canonical `main` SHA `0f6164b0eb1f1c8e2f890e18d6636f3c0311347b`;
- accepted engineering-system contract ref declared in `engineering-system/program/work-packages/KILN-01.md`.

Do not create a second Kiln writer or a replacement implementation branch.

## Preflight reconciliation

1. Verify the branch, both SHAs, clean worktree, and exclusive writer ownership.
2. Read root `AGENTS.md`, the accepted P1-S02-T01 plan, its authorization record, applicable migrations/schema contracts, and `engineering-system/program/work-packages/KILN-01.md`.
3. Fetch canonical `main` and merge exactly `0f6164b0eb1f1c8e2f890e18d6636f3c0311347b` into the authorized branch without rebasing, rewriting, or force-pushing.
4. Stop if the merge conflicts or changes T01 runtime content. The expected reconciliation should preserve the already-matching Arsenal pin/verifier content and add only the missing merged history/documentation from PR #62.
5. Run `scripts/agent-preflight` and inspect the full reconciled diff before continuing.

## Objective

Continue the already-authorized P1-S02-T01 Artifact/Evidence substrate from its actual current checkpoint to the next valid accepted checkpoint. Do not add more runtime surface if the accepted criteria are already satisfied; in that case, verify, reconcile required derived governance, and prepare the PR/closeout.

## Work sequence

1. Build an acceptance matrix from the accepted T01 plan against the exact current branch. Mark each item observed satisfied, failed, blocked, or unknown with evidence.
2. Treat the existing Artifact/Evidence/currentness implementation and tests as work to verify and finish, not permission to redesign.
3. Implement only the smallest missing T01 requirement justified by that matrix.
4. Preserve append-only evidence, artifact identity, recovery, idempotency, currentness, contradiction, and state-binding semantics required by the accepted plan.
5. Add at most one non-normative documentation note mapping existing Kiln concepts to Run Result Envelope v0. Do not implement the envelope or adapter.
6. Reconcile mutable governance prose only as deterministically allowed by Kiln's accepted authorization model.

## Prohibited

- No Work Envelope ingestion, Loadout adapter, Capability, Pack, or UI.
- No broad Project Intelligence, knowledge graph, context selector, or Quality Compiler.
- No P1-S02-T02 or later work.
- No weakening migrations, schema constraints, evidence currentness, or tests to reach green.
- No use of stale ECC PR #2.
- No writes to Arsenal, Loadout, or engineering-system.

## Verification

Run every command required by the accepted T01 plan and current CI. At minimum:

```text
scripts/agent-preflight
scripts/test-agent-preflight
scripts/validate_first_month_contracts.py
scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
git diff --check
```

Record failures before changing code. Do not attribute environmental failures to product defects without evidence.

## Stop conditions

Stop if either ref drifts, another writer owns the branch, authorization is absent/withdrawn/inapplicable, reconciliation conflicts, effects from prior attempts are unknown, required work belongs to another product or future package, or the only path widens T01.

## Closeout

Commit coherent checkpoints and push the existing branch. Open or update one reviewable T01 PR without merging it. Report pre- and post-reconciliation SHAs, ending SHA, changed files, acceptance matrix, commands/results, contract mapping status, assumptions, unknowns, negative knowledge, and deferred work without self-authorizing it.
