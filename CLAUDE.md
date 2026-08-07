# CLAUDE.md

This file is a concise entrypoint for Claude-based development in Kiln. It does not duplicate project authority.

## Start here

1. Read `AGENTS.md` completely.
2. Read `docs/ENGINEERING-DOCTRINE.md` as the default engineering decision framework.
3. Follow the authority order, current authorization boundary, branch discipline, verification requirements, and accepted work plan defined by `AGENTS.md`.
4. Read the subject documents, ADRs, invariants, source, tests, and Evidence required by the current work package before making material changes.

## How to use the doctrine

The doctrine guides choices that remain open inside accepted project authority. It does not widen scope, reverse an ADR, relax an invariant, or convert planned work into authorized work.

For material design choices, make the reasoning inspectable. In particular, identify the relevant failure mode, deterministic enforcement opportunity, Evidence boundary, Capability boundary, and future option being preserved when those factors matter.

Do not turn doctrine references into ritual. Cite or discuss the principles that materially affect the decision; do not mechanically enumerate all 24 principles.

## Claude-specific expectations

- Treat model reasoning as proposal and analysis, not as persistence, permission, verification, or acceptance authority.
- Prefer deterministic repository tooling, tests, schemas, static analysis, and explicit checks when they can decide the question reliably.
- Keep Context bounded and task-specific instead of accumulating conversation history.
- Preserve the distinction between observed, inferred, proposed, assumed, and unknown information.
- Do not claim completion without current Evidence from the exact relevant state.
- Do not add speculative architecture merely because a future seam can be imagined.
- When a significant mechanism is proposed, be able to state the credible failure mode it addresses.
- Respect the current branch's accepted scope and stop when new Evidence invalidates the plan.

If this file and `AGENTS.md` appear to conflict, `AGENTS.md` and the accepted project authorities it names govern. `docs/ENGINEERING-DOCTRINE.md` remains the decision framework for choices those authorities leave open.
