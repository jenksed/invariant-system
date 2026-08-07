# Wayfinding

Status: draft

Wayfinding is a multi-session decision-orchestration method for ambitious work where the destination is visible but the route is not.

It exists because some efforts cannot be responsibly planned inside one agent context. Instead of forcing the work into prematurely small implementation chunks, Wayfinding preserves the ambition and incrementally clears the unknowns that prevent a reliable plan.

## When Wayfinding applies

Use Wayfinding when all of the following are true:

1. The effort has a meaningful destination.
2. Important decisions remain unresolved.
3. Resolving those decisions requires more work than one reliable working session can hold: research, prototypes, human discussion, external tasks, or dependent investigations.
4. The result will materially benefit from preserving the primary sources behind those decisions.

If the route can be made clear in one normal grilling/planning session, do that instead. Wayfinding is an escalation path for real fog, not the default ceremony for every feature.

## Core model

### Destination

The outcome the map is trying to make reachable. A destination may be:

- a buildable specification;
- a strategic or architectural decision;
- an implementation-ready migration plan;
- a product plan;
- a real-world action plan;
- or, when explicitly desired, the completed change itself.

The destination fixes the scope. If the destination changes materially, reconsider the map rather than quietly stretching it.

### Map

The durable low-resolution view of the effort. It contains:

- destination;
- standing constraints/notes;
- resolved decisions as pointers and one-line gists;
- current fog;
- explicit out-of-scope areas.

The map is an index. Detailed reasoning lives in the decision artifact that produced it.

### Decision node

A bounded question or prerequisite whose resolution moves the effort toward the destination. Each node must fit in one reliable working session.

Node types:

- **Grilling** — a human decision is required; use Decision-Tree Grilling.
- **Research** — authoritative external or repository evidence is required.
- **Prototype** — a cheap concrete artifact is needed to answer a design/behavior question.
- **Task** — work must happen before a later decision becomes answerable; the task may be agent-run or human-run.

The type describes how the node is resolved, not its subject matter.

### Blocking edge

A dependency between nodes. A blocked node cannot be responsibly resolved until all of its blockers are resolved.

### Frontier

The open, unblocked, unclaimed decision nodes that can be worked now.

The frontier is the operational edge of the map. Independent frontier nodes may be resolved in parallel when their state and evidence do not overlap unsafely.

### Fog

In-scope uncertainty that is visible but not yet precise enough to become a decision node.

Fog is not a backlog of guessed tickets. Keep an item in fog until you can state the exact question or prerequisite it represents. Resolution of frontier nodes should cause some fog to sharpen, disappear, split, or become out of scope.

### Out of scope

Known work beyond the destination. Out-of-scope items do not graduate from fog unless the destination is deliberately changed.

## Decision resolution record

Every resolved decision node should preserve:

- the exact question;
- node type;
- evidence or artifact used;
- decision/result;
- confidence/uncertainty where relevant;
- consequences and constraints introduced;
- primary-source pointers;
- nodes invalidated, changed, or newly unlocked.

A resolution is not merely “done.” It changes the map.

## Charting a map

1. **Recover context.** Inspect existing project evidence, terminology, constraints, and prior decisions.
2. **Name the destination.** Use grilling if necessary. Make “done” concrete enough to govern scope.
3. **Check whether Wayfinding is warranted.** If the whole route can be settled in one working session, stop and use the normal planning flow.
4. **Explore breadth-first.** Identify decisions already sharp enough to become nodes and broader areas still hidden by fog.
5. **Create only presently specifiable nodes.** Do not manufacture downstream detail whose prerequisites are unresolved.
6. **Wire blocking edges.** The resulting dependency graph determines the initial frontier.
7. **Start safe AFK research where useful.** Independent research nodes may run in parallel.
8. **Stop charting.** Charting establishes the map; it does not need to resolve the whole frontier in the same context.

## Walking a map

1. Load the map, not every detailed resolution.
2. Select one frontier node, unless parallel independent research is explicitly safe.
3. Claim/identify ownership before work when multiple sessions may operate concurrently.
4. Load only the primary sources needed for that node.
5. Resolve it using its method: grilling, research, prototype, or task.
6. Record the resolution and evidence at the node.
7. Update the map with a short gist and pointer rather than duplicating the full decision.
8. Recompute dependencies and frontier.
9. Graduate newly specifiable fog into nodes.
10. Invalidate or rewrite downstream nodes made obsolete by the result.
11. Move newly revealed beyond-destination work to out of scope.

## Parallelism

Parallel work is safe when nodes:

- are both on the frontier;
- do not mutate shared state in conflicting ways;
- do not depend on each other's unresolved result;
- produce independently mergeable evidence.

Research is the easiest form of parallelism. Human-decision nodes usually benefit from serial resolution when they touch the same conceptual area.

## Completion

A Wayfinding map is complete when:

- no unresolved frontier node remains;
- no in-scope fog remains that matters to the destination;
- every load-bearing decision has a primary-source pointer or explicit evidence record;
- contradictions and invalidated decisions have been reconciled;
- the destination is now directly reachable by the next workflow.

## Handoff to execution

When the destination is a buildable spec, collapse the map into a spec using the resolved decisions while retaining links back to their primary sources. Then decompose the spec into implementation slices.

Decision nodes and implementation tickets are different objects:

- **Decision nodes** answer what should be true or what path should be taken.
- **Implementation tickets** deliver behavior.

Do not implement directly from a dense map when a synthesis/specification step is needed; that discards the structure that made the map trustworthy.

A specification produced from Wayfinding is a transition artifact, not necessarily permanent operational truth. Once verified behavior is embodied in the system, the code, tests, schemas, and durable decision records become authoritative; the spec becomes historical evidence unless the project explicitly treats specs as living contracts.

## Storage model

Wayfinding is tracker-agnostic. The method needs only:

- a durable map artifact;
- durable decision artifacts;
- dependency edges;
- status/claim state;
- primary-source links.

GitHub Issues, Linear, Jira, local Markdown, or a future native execution system can all implement that contract.

## Design principle

Wayfinding should let the ambition determine the planning effort—not force the ambition to fit the current context window.