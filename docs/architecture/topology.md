# LOD-01 Topology

Quick reference for which product object lives where in this slice.

| Object                  | Source file                       | Notes                                           |
| ----------------------- | --------------------------------- | ----------------------------------------------- |
| Workspace               | `src/core/workspace.ts`           | Persisted as `.loadout/` inside the target repo |
| Snapshot digest         | `src/core/snapshot.ts`            | Hashes `HEAD` + sorted tracked path set         |
| Goal catalogue          | `src/core/goal.ts`                | One goal: `Understand this repository`          |
| Goal compile            | `src/core/compile.ts`             | Produces Work Envelope v0                       |
| Capability contract     | `src/core/capability-contract.ts` | Stable contract schema (zod)                    |
| Capability registry     | `src/core/capability-registry.ts` | Resolves id -> contract + skill                 |
| Skill                   | `src/core/skill.ts`               | Power-user swappable                            |
| Pack                    | `src/core/pack.ts`                | Manifest + install/inspect/run/remove           |
| Catalog                 | `src/core/catalog.ts`             | Indexes `src/packs/*/pack.json`                 |
| Connector (config-only) | `src/core/connector.ts`           | No effect driver                                |
| Fake Kiln boundary      | `src/core/fake-kiln-boundary.ts`  | Deterministic simulated boundary                |
| Result view             | `src/core/result-view.ts`         | Truthful presentation; always `simulated`       |
| CLI                     | `src/cli.ts`                      | `loadout <subcommand>`                          |
| Web surface             | `src/web.ts`                      | `loadout web` opens static page                 |
