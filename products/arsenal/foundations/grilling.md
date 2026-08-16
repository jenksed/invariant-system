# Decision-Tree Grilling

Status: draft

A grilling session is a structured interview for resolving consequential decisions before action. It is not a generic clarification loop and it is not permission to ask the user facts the agent can discover itself.

## Core model

Represent the unresolved design as a dependency-aware **decision tree**.

- A **decision** is a choice that materially changes the plan, design, scope, interface, or outcome.
- A **prerequisite** is a fact or earlier decision that must be settled before another decision can be answered responsibly.
- The **frontier** is the set of unresolved decisions whose prerequisites are already settled.
- A **branch** is a downstream decision unlocked by a prior answer.
- A **fact gap** is missing evidence that the agent should retrieve rather than delegate back to the user.

Do not precompute the whole tree as if the future were already known. Each round changes what becomes relevant.

## Operating rules

1. Recover existing decisions and evidence before asking anything.
2. Separate facts from decisions. Resolve facts with repository inspection, tools, research, or experiments whenever possible.
3. Ask only frontier questions. If Q2 depends on the answer to Q1, Q2 belongs in a later round.
4. Ask the useful frontier in one round rather than serializing independent questions unnecessarily.
5. For each question, give a recommended answer and the engineering/product reasoning behind it. The user should be able to accept the recommendation quickly or disagree precisely.
6. Treat an answer as a decision record: capture what was chosen, why, and what it unlocks.
7. Recompute the frontier after every round.
8. Stop when no unresolved in-scope branch remains.
9. Before acting on the result, summarize the shared understanding and identify any remaining assumptions.

## Question quality

A good grilling question:

- asks exactly one consequential decision;
- is answerable with the evidence already available;
- explains the tradeoff when the choice is not obvious;
- avoids asking for information the agent can retrieve;
- includes a strong default recommendation;
- changes what will happen next.

A question is noise when either answer would produce the same plan.

## Evidence and uncertainty

When a decision rests on uncertain evidence, label the basis explicitly:

- **Confirmed** — directly supported by authoritative evidence.
- **Strong signal** — well-supported but not definitive.
- **Hypothesis** — plausible and testable.
- **Unknown** — insufficient evidence.

When a hypothesis can be cheaply tested, prefer an experiment, prototype, or research step over debating it abstractly.

## Completion criterion

Grilling is complete when:

- every in-scope decision reachable from the current understanding is resolved or intentionally deferred;
- no frontier question remains;
- unresolved facts are explicitly recorded rather than silently assumed;
- the user confirms the resulting shared understanding.

## Use this method when

Use grilling when ambiguity is itself the blocker: architecture, product behavior, scope, interfaces, tradeoffs, policy, or a decision with several plausible branches.

Do not invoke a full grilling session for a small request whose intended outcome is already clear. The method should reduce ambiguity, not manufacture process.