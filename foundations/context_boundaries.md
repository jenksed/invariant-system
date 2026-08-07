# Context Phase Boundaries

Status: draft

Context changes should happen at work boundaries, not randomly in the middle of reasoning. Treat context as a working set with explicit transition choices.

## The choices

At the end of a coherent phase, choose the cheapest transition that preserves what the next phase actually needs:

1. **Continue** — keep the current context when the next phase needs the primary reasoning or enough working capacity remains.
2. **Clear** — start clean when the completed phase is irrelevant to what follows.
3. **Handoff** — create a portable continuation artifact when work must move to another harness, repo/directory, collaborator, or independently resumed session.
4. **Delegate** — give a tightly scoped AFK task its own context and receive a result/evidence artifact back.
5. **Compact** — summarize into a new working context when prior reasoning remains relevant but carrying the full primary source is too expensive.

Harnesses may expose these operations differently. The decision model is independent of the command names.

## Primary-source rule

Every transition except Continue risks replacing primary reasoning with a lossy secondary representation.

Prefer Continue when the next phase needs the exact reasoning that produced a decision. Prefer pointers to durable primary artifacts over copying their content into handoffs.

## Handoff rule

A handoff is for portability, not routine summarization.

A good handoff:

- states the next objective;
- names verified current state;
- references specs, decisions, commits, issues, diffs, and evidence rather than duplicating them;
- records unresolved risks and exact continuation point;
- redacts secrets and unrelated personal information.

## Delegation rule

Delegate when the task can complete without steering and its output can be evaluated independently. Research, focused code review, and bounded verification often fit. Ambiguous product or architecture decisions usually do not.

## Completion criterion

A phase boundary is handled correctly when the next worker has enough trustworthy context to proceed without either redoing completed discovery or inheriting stale/noisy material that no longer affects the task.