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

- Launch three writing agents: one per product repository.
- Permit read-only scouts only when they do not consume the writer's context or mutate the checkout.
- Never assign two writing agents to the same repository in the first wave.
- Use a dedicated branch/worktree per work package.
- Stagger full verification suites when local resource pressure would create misleading failures.

## Prompt construction

Every prompt must place indexed source material before the final task and include:

1. role and repository;
2. starting SHA;
3. accepted decision and contract versions;
4. objective and user-visible outcome;
5. owned paths and prohibited changes;
6. dependency fixtures;
7. verification commands;
8. stop conditions;
9. required closeout format.

## Escalation triggers

Escalate without continuing when:

- observed HEAD differs from the package;
- required authority is absent or ambiguous;
- implementation requires a shared-contract change;
- a task would move responsibility between products;
- deterministic verification contradicts the agent's conclusion;
- a runtime effect may have occurred but cannot be established;
- the only path forward widens scope.

