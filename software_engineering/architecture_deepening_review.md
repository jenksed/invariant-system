# Architecture Deepening Review

Survey a codebase for places where complexity leaks through weak interfaces, then explore only the candidates whose expected leverage justifies change.

## Vocabulary

Use these concepts consistently:

- **Module** — behavior behind an interface, at any scale.
- **Interface** — everything callers must know: operations, invariants, ordering, errors, configuration, performance expectations.
- **Seam** — the location where behavior can vary/be exercised through an interface.
- **Adapter** — a concrete implementation occupying a seam.
- **Depth** — useful behavior hidden per unit of interface complexity.
- **Leverage** — caller benefit from a deep interface.
- **Locality** — how strongly change/knowledge/bugs concentrate behind that interface.

## Scope the survey

Prefer areas that are changing, painful, bug-prone, hard to test, or explicitly named by the user. Do not scan the entire repository for theoretical refactors when no change pressure exists.

Read domain language and existing ADRs first.

## Find candidates

Look for:

- understanding one concept requires bouncing through many shallow modules;
- callers must know implementation details;
- testing requires reaching past the public interface;
- related behavior changes in scattered places;
- pass-through wrappers add vocabulary but little leverage;
- multiple real adapters exist without a coherent seam;
- a frequent change repeatedly causes shotgun edits.

Apply a deletion test: if deleting the module mostly removes ceremony, it may be shallow; if its complexity would spill into many callers, it may already earn its existence.

## Present candidates before redesigning

For each candidate show:

- current friction/evidence;
- affected concept/area;
- why deepening could improve locality/leverage/testability;
- recommendation strength: strong / worth exploring / speculative;
- ADR or compatibility constraints.

Do not design all interfaces yet. Let the user choose which candidate is worth architectural attention.

## Design it more than once

For a chosen candidate, generate at least three materially different interface shapes with different optimization pressures, for example:

1. smallest interface / highest leverage;
2. maximum flexibility/extensibility;
3. optimized common caller path;
4. ports/adapters when an external dependency genuinely varies.

Compare depth, locality, seam placement, migration cost, type/invariant strength, and operational impact. Recommend one or a justified hybrid.

## Doctrine guardrail

One hypothetical alternative does not automatically justify an abstraction. Preserve the doctrine: identify future seams early, but implement a seam when variation or policy control is real enough to earn it.