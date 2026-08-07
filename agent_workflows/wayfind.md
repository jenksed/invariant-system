# Wayfind a Large or Foggy Effort

Use this when the destination matters but the route contains enough dependent uncertainty that one reliable planning session is insufficient.

Read and follow `foundations/wayfinding.md`, `foundations/grilling.md`, and the project's domain language/decision records when present.

## Mode A — Chart a map

1. Recover project truth and existing decisions.
2. Establish the **Destination** through a short grilling pass.
3. Check whether Wayfinding is actually necessary. If the full remaining route can be resolved in one session, stop and recommend the ordinary planning/grilling flow.
4. Explore breadth-first across the effort.
5. Create decision nodes only for questions/prerequisites precise enough to state now.
6. Classify every node as `grilling`, `research`, `prototype`, or `task`.
7. Wire blocker relationships after node identities exist.
8. Put visible-but-not-yet-specifiable uncertainty into **Fog** rather than manufacturing premature nodes.
9. Record explicit **Out of scope** areas fixed by the destination.
10. Identify the current **Frontier**: open, unblocked, unclaimed nodes.
11. Start independent AFK research nodes in parallel when safe.
12. Stop after the map is coherent. Charting does not also need to resolve the map.

## Mode B — Walk an existing map

1. Load the map as the low-resolution index.
2. If the user named a frontier node, use it. Otherwise select the highest-value unclaimed frontier node.
3. Claim/mark ownership before doing work when concurrency is possible.
4. Load only that node's question, blockers, relevant prior decisions, and primary-source evidence.
5. Resolve it using the method implied by its type.
6. Record a resolution containing:
   - exact question;
   - evidence/artifact;
   - decision/result;
   - uncertainty/confidence;
   - consequences;
   - primary-source pointers;
   - invalidated/unlocked work.
7. Close/resolve the node.
8. Append only a one-line gist + pointer to the map's resolved decisions.
9. Recompute the frontier.
10. Graduate newly sharp fog into new nodes.
11. Rewrite/remove downstream nodes invalidated by the decision.
12. Move newly revealed beyond-destination work to out of scope.

Resolve one human-decision node per focused session by default. Independent research nodes may run concurrently.

## Storage fallback

Use the project's configured issue tracker when one exists and supports durable items/dependencies.

If none exists, use local Markdown:

```text
wayfinding/<effort>/
├── MAP.md
└── decisions/
    ├── 001-<name>.md
    └── 002-<name>.md
```

`MAP.md` contains Destination, Notes, Decisions so far, Fog, Out of scope, and a frontier table. Each decision file owns the detailed question and resolution. Do not duplicate detailed reasoning into the map.

## Completion

When the map has no consequential frontier or in-scope fog left, hand off to the workflow implied by the destination.

For software delivery, use `workflows/wayfind_to_delivery.md` so the map is collapsed into a buildable spec and then implementation tickets rather than implemented directly from dense planning state.