# Resolve Merge/Rebase Conflicts by Intent

Resolve conflicts by understanding what each side was trying to accomplish, not by choosing whichever lines look newer or easier.

## Workflow

1. Inspect the in-progress merge/rebase state and all conflicting paths.
2. For each conflict, trace both sides to primary sources where available:
   - commits/messages;
   - originating issues/specs;
   - PR discussion/review;
   - tests/behavior contracts;
   - ADRs.
3. State each side's intent before editing the hunk.
4. Preserve both intents when they are compatible.
5. When they conflict semantically, choose the result that matches the current merge objective and authoritative contracts; record the tradeoff.
6. Do not invent unrelated new behavior while resolving.
7. Run the project's deterministic checks, beginning with the narrow checks most likely to catch conflict damage and ending with required full verification.
8. Finish the merge/rebase operation and report the resolution evidence.

If intent cannot be reconstructed, mark the conflict blocked rather than guessing from syntax alone.