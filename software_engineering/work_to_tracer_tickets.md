# Decompose Work Into Tracer-Bullet Tickets

Turn a spec/plan into implementation tickets that each deliver a narrow, complete, independently verifiable path through the system.

## Tracer-bullet rules

Each ticket should:

- produce observable behavior or verifiable system capability;
- cut vertically through the layers needed for that behavior rather than completing one horizontal layer for the whole feature;
- fit in one fresh reliable implementation context;
- have explicit acceptance criteria;
- declare its blockers.

A ticket with no unresolved blockers is on the implementation frontier.

## Prefactoring

If a small structural change will materially simplify all later slices, make it an explicit first ticket and explain the leverage it creates. Do not disguise speculative architecture as prefactoring.

## Wide-refactor exception

Some mechanical changes cannot land as independent vertical behavior slices because one atomic representation change breaks many callers.

Use **expand → migrate → contract**:

1. **Expand** — introduce the new form alongside the old while preserving compatibility.
2. **Migrate** — move callers in bounded batches sized by blast radius; keep verification green between batches when possible.
3. **Contract** — remove the old form only after every migration is verified.

If intermediate batches cannot independently remain green, use an explicit integration branch/gate rather than pretending each batch is independently releasable.

## Ticket contract

For each ticket record:

- title;
- what behavior/capability it delivers;
- blocked by;
- acceptance criteria;
- relevant decision/spec pointers;
- explicit exclusions when adjacent scope is tempting.

Avoid implementation choreography that the future agent can rediscover from the current codebase.

## Review before publishing

Check:

- granularity;
- blocker correctness;
- whether tickets are actually vertical;
- whether any slice silently depends on an unresolved product decision;
- whether tickets could run safely in parallel.

Do not send unresolved decision work into implementation tickets. Return that work to grilling/Wayfinding first.