# Agent Operating Model

## Roles

| Role | Default model | Authority |
|---|---|---|
| Program manager/integrator | GPT-5.6 or owner-selected frontier reviewer | program artifacts, dependency reconciliation, launch/stop recommendation; no implicit product merges |
| Arsenal implementer | MiniMax M3 with thinking enabled | ARS-01 only |
| Loadout implementer | MiniMax M3 with thinking enabled | LOD-01 only |
| Kiln implementer | MiniMax M3 with thinking enabled | existing P1-S02-T01 authority and KIL-01 non-runtime documentation boundary |
| Routine verifier | independent MiniMax M3 session | read-only review and deterministic verification |
| Escalation verifier | GPT-5.6 | boundary, authority, security, migration, or conflicting-evidence adjudication |

Models are replaceable. Repository contracts, deterministic tests, and human authority—not the model name—establish acceptance.

## Concurrency

- One writer per lane; lane owns a non-overlapping primary-path set.
- Permitted to run two lanes in parallel only when their primary-path
  sets are disjoint (the M3 ∥ M4 pair in the merge train is the
  canonical example; all other gates are single-lane).
- Each lane uses one branch rooted at `main` (`m0/<lane-slug>`) and
  one worktree outside the monorepo tree.
- Read-only scouts are allowed only when they do not consume the
  writer's context or mutate the checkout.
- Stagger full verification suites when local resource pressure would
  create misleading failures.
- Maximum concurrent active lanes: 2.

## Prompt construction

Every prompt must place indexed source material before the final task and include:

1. owner domain and paths (one writer per lane, not per repository);
2. base merge gate (the M# from the merge train that this lane merges at);
3. accepted decision and contract versions;
4. objective and user-visible outcome;
5. owned paths and prohibited changes;
6. dependency fixtures;
7. verification commands (TEST COMMANDS + NEGATIVE TESTS from the refined work package);
8. stop conditions (lane-level + work-package-level);
9. required closeout format (LANE-EVIDENCE.md at the lane branch root).

## Escalation triggers

Escalate without continuing when:

- base drift vs current main (the lane's start-gate precondition is
  no longer satisfied);
- required authority is absent or ambiguous;
- implementation requires a shared-contract change;
- a task would move responsibility between products;
- deterministic verification contradicts the agent's conclusion;
- a runtime effect may have occurred but cannot be established;
- the only path forward widens scope.

