# P0-W16: Integrated architecture and implementation roadmap

- **Status:** Implemented, verified, and integrated through pull request 20
- **Planning branch:** `work/p0-w16-integrated-architecture-roadmap`
- **Integration commit:** `57493016b052e5c1c1390ca0360845940dc56917`
- **Depends on:** P0-W05 through P0-W15
- **Scope:** Planning and documentation only
- **Verified design head:** `0ef8543502fc3bb76e68768a866ce0c2dd34c5f9`
- **GitHub CI:** run `30405701680`, success

## Objective

Integrate all accepted Kiln planning passes into one coherent architecture, remove duplication and contradictions, and replace the component-shaped implementation plan with the smallest vertical-slice roadmap that can deliver the intended product.

## Inputs reconciled

- planning baseline and pending reconciliation;
- internal domain, Session, Task, Run, and Steward models;
- delegation, Scout, Verifier, Attention, and recovery;
- CLI and TUI;
- Capability broker and permission policies;
- Context compiler and model routing;
- LSP, Tree-sitter, persistent semantic indexing, documentation, and Skills;
- MCP, ACP, OpenAPI, protocol, and standards positions;
- Git isolation, Commands, Patches, Artifacts, Evidence, Receipts, and OpenTelemetry;
- local project intelligence and its security boundary;
- README, roadmap, contracts, ADRs, templates, and work-planning rules.

## Accepted integration decisions

1. Runs remain durable records and projections. A permanent process per Run is rejected.
2. One active-code intelligence path owns Tree-sitter, on-demand LSP, documentation resolution, Skills, and native semantic facts.
3. Approved-root intelligence reuses extraction and index primitives under separate reference trust, instruction quarantine, Privacy, and no-execution policy.
4. Persistent semantics use Kiln-native normalized facts first. SCIP, embeddings, vector storage, and a dedicated graph database remain optional later evaluations.
5. The first writing Child remains read-only and returns an immutable Patch Artifact. The Parent owns one exclusive writable worktree and applies the selected proposal.
6. Protocol seams remain, but implementations enter only through concrete vertical workflows.
7. OpenTelemetry begins after durable operation semantics stabilize and remains observation rather than state or Evidence.
8. Version 0.1 is the read-only Durable Operator Kernel through P1-S05.

## Vertical implementation order

```text
P1-S01  Navigable simulated Runs
P1-S02  One real read-only Scout
P1-S03  Background work and Attention
P1-S04  Independent Verifier
P1-S05  Durable recovery
P1-S06  Local code intelligence
P1-S07  Safe writing delegation
P1-S08  Capability interoperability
P1-S09  Local project intelligence
P1-S10  Expansion capability evaluations
```

## Integrated documents

- `docs/ARCHITECTURE.md` — integrated architecture authority;
- `docs/ROADMAP.md` — vertical implementation order and milestones;
- `docs/IMPLEMENTATION-SLICES.md` — detailed slice contracts, tickets, security, tests, demos, and Receipts;
- `docs/SLICE-ACCEPTANCE-GATES.md` — aggregate gate identifiers and machine-readable gate expectations;
- `docs/PROTOCOL-CAPABILITY-MAP.md` — slice-linked protocol and standards entry map;
- `docs/BRANCHING-AND-WORK-PLANNING.md` — slice and ticket work governance;
- `docs/templates/IMPLEMENTATION-PLAN.md` — slice-aware plan template;
- `docs/decisions/0019-implement-kiln-through-vertical-product-slices.md` — accepted reconciliation decision.

## Acceptance status

| Criterion | Result | Evidence |
| --- | --- | --- |
| One integrated architecture explains every required subsystem and dependency direction. | Pass | `docs/ARCHITECTURE.md` |
| No protocol, UI, model, index, or process becomes parallel domain authority. | Pass | architecture dependency rules and ADR 0019 |
| One permanent process per Run is rejected. | Pass | integrated runtime shape |
| Active and reference intelligence share primitives but retain separate trust policy. | Pass | architecture and P1-S06/P1-S09 boundaries |
| Persistent semantics do not require SCIP, embeddings, vector storage, or graph storage. | Pass | architecture, roadmap, and protocol map |
| Writing delegation selects a Child Patch Artifact applied by the Parent. | Pass | P1-S07 and ADR 0019 |
| The P1-W01 through P1-W13 component order is superseded. | Pass | roadmap, reconciliation record, contract index, and work-planning rules |
| Every slice defines value, concepts, dependencies, modules, security, criteria, tests, Receipt, demo, exit, and deferrals. | Pass | `docs/IMPLEMENTATION-SLICES.md` |
| Explicit aggregate gates exist for every slice. | Pass | `docs/SLICE-ACCEPTANCE-GATES.md` |
| Version 0.1 stops after P1-S05 and remains read-only. | Pass | README, architecture, roadmap, and ADR 0019 |
| The first coding task and twelve-week target are explicit and pruned. | Pass | roadmap and slice plan |
| Planning and protocol authorities no longer imply component-first implementation. | Pass | planning baseline, reconciliation, protocol map, and document hierarchy |
| Work governance supports small tickets without false aggregate completion. | Pass | branching rules and implementation-plan template |
| Diff changes documentation only. | Pass | pull request 20 compare against `main` |
| Repository CI passes on the integrated design head. | Pass | run `30405701680` |

## Verification executed

GitHub CI run `30405701680` passed on design head `0ef8543502fc3bb76e68768a866ce0c2dd34c5f9`:

- Vale prose checks;
- agent preflight behavior;
- Project agent-asset validation;
- dependency installation;
- Elixir formatting;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit tests.

Pull request 20 then integrated that exact head into `main` at merge commit `57493016b052e5c1c1390ca0360845940dc56917`.

## Evidence index

- **P0-W16-E01:** integrated architecture authority;
- **P0-W16-E02:** ten detailed vertical slice contracts;
- **P0-W16-E03:** aggregate slice gate registry;
- **P0-W16-E04:** vertical roadmap, milestones, dependency graph, first task, and twelve-week target;
- **P0-W16-E05:** slice-linked protocol and standards map;
- **P0-W16-E06:** ADR 0019;
- **P0-W16-E07:** historical planning records no longer compete with current authority;
- **P0-W16-E08:** slice/ticket work governance and implementation-plan template;
- **P0-W16-E09:** documentation-only pull request 20;
- **P0-W16-E10:** successful design-head CI run `30405701680`;
- **P0-W16-E11:** merge commit `57493016b052e5c1c1390ca0360845940dc56917` contains the verified design head.

## Exclusions

P0-W16 implements no production domain, TUI, persistence, provider, broker, Context, Command, Git, Patch, Artifact, LSP, Tree-sitter, Skill, protocol, container, knowledge, telemetry, or attestation runtime.