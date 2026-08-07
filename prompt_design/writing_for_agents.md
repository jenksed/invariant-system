# Writing for Agents

Status: draft

Write agent-facing documents so they produce a reliable process while loading only the information needed for the current branch of work.

## Context pointers

A **context pointer** is a short reference that tells an agent both what material exists and when to load it.

A useful pointer contains:

- the subject of the referenced material;
- the conditions/branches that should trigger reading it.

Pointers are part of the behavior. A critical document behind a vague pointer is effectively unreliable.

## Two costs

Agent documentation spends two different budgets:

- **Context load** — material always present in the model's working set.
- **Cognitive load** — material the human must remember exists or deliberately invoke.

Do not optimize one blindly. Put universal, frequently needed rules high in the hierarchy. Put branch-specific reference behind precise pointers.

## Information hierarchy

Prefer this order:

1. **Immediate steps** — what the agent must do now, in execution order.
2. **Local reference** — definitions/rules needed by most paths through the document.
3. **Progressively disclosed reference** — branch-specific or detailed material in a separate document reached by a pointer.

Keep related definitions, rules, and caveats together. Scattering one concept across a document forces the agent to reconstruct it repeatedly.

## Completion criteria

Each step should end with an observable condition that distinguishes complete from incomplete.

Strong criteria are:

- checkable;
- demanding enough to force the intended legwork;
- specific about evidence when evidence matters;
- local to the step.

Vague criteria encourage premature completion.

## Single sources of truth

Keep each behavioral rule in one authoritative place. Other documents should point to it rather than restate it.

The environment is also a source of truth. Avoid caching information an agent can cheaply inspect from:

- package/task scripts;
- config files;
- directory structure;
- generated help output;
- schemas and code.

Document the things the environment cannot explain by itself: why, policy, non-obvious conventions, decision boundaries, and known traps.

## Leading concepts

Use compact, meaningful vocabulary when it genuinely compresses a repeated behavior—examples include **frontier**, **fog**, **seam**, **receipt**, **blast radius**, and **tight loop**.

A shared leading concept is useful only when its definition is stable and it removes repeated prose. Do not coin jargon simply to sound systematic.

## Positive instructions

Prefer telling the agent what to do over repeatedly activating the behavior you are trying to prohibit. Reserve explicit prohibitions for true guardrails and pair them with the desired positive behavior.

## Pruning

Periodically remove:

- stale branches;
- duplicated meanings;
- exposition that does not change behavior;
- instructions the model/environment already satisfies reliably;
- references whose target no longer exists.

Shorter is not automatically better. The goal is high signal density and predictable execution.

## Invocation-aware packaging

If a capability should be reachable automatically, its discovery description must contain the actual trigger branches. If it should run only by explicit human choice, do not spend permanent context teaching the model to invoke it.

See `arsenal/INVOCATION_MODEL.md` for Project Arsenal's packaging semantics.