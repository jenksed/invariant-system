@AGENTS.md

# Claude Code Specific Instructions

The repository's `AGENTS.md` is the primary engineering contract. Treat its Engineering Doctrine as paramount during planning, implementation, review, verification, and completion.

Before substantial implementation, explicitly account for the doctrine when work involves architecture, public contracts, persistence, permissions, consequential mutation, destructive operations, or significant refactoring.

Do not claim completion without the evidence required by `AGENTS.md`. If required verification cannot be run, report that limitation explicitly and do not silently treat the task as fully verified.

Prefer deterministic tools and repository-native verification over additional model reasoning whenever those tools can answer the question reliably.
