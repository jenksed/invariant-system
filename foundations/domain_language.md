# Domain Language and Durable Decisions

Status: draft

Agents and humans work faster when the project has a small, shared vocabulary for its domain and a durable record of the few decisions that would otherwise be surprising later.

## Domain glossary

Maintain a project glossary when terminology is meaningful enough to affect design, code, requirements, or communication.

A glossary entry should define:

- the canonical term;
- what it means in this project;
- important relationships to other terms;
- terms that should not be used as synonyms when the distinction matters.

The glossary describes the domain, not the implementation. Do not turn it into a spec, architecture document, project diary, or dumping ground.

## Active domain work

When discussing or implementing a change:

1. Notice vague, overloaded, or conflicting language.
2. Check the existing glossary before inventing new terms.
3. Challenge contradictions immediately.
4. Stress-test domain relationships with concrete edge cases.
5. Compare claimed behavior against repository evidence when code already exists.
6. Update the glossary when a term genuinely crystallizes.

Do not create terminology merely to make the glossary look complete.

## Durable decision records

Record an ADR or equivalent decision note only when the decision is:

1. **Costly to reverse** — changing it later would meaningfully affect the system or organization.
2. **Non-obvious** — a future maintainer could reasonably wonder why this path was chosen.
3. **A real tradeoff** — credible alternatives existed and were rejected for specific reasons.

If one of those conditions is missing, normal code, tests, issue history, or documentation is usually enough.

A useful decision record captures:

- context and forces;
- options considered;
- chosen option;
- reasons/evidence;
- consequences;
- reconsideration triggers.

## Relationship to Wayfinding

Wayfinding decision nodes are primary-source decision artifacts during exploration. Not every node deserves an ADR.

When a Wayfinding decision satisfies the durability test above, promote its settled result into the project's durable decision system and point back to the original resolution evidence.

## Principle

Use shared language to remove repeated interpretation cost. Use durable records to preserve reasoning whose loss would cause expensive re-litigation.