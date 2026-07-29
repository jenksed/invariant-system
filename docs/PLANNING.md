# Kiln Planning Control

**Document type:** Planning authority index  
**Status:** Active  
**Build authorization:** Not issued

## Integrated planning baseline

| Pass | Integrated equivalent |
| --- | --- |
| Prompt 1 | Pull request 22, merge commit `ef487c432a04de705e58ec79569abe5bb51e3d7a` |
| Prompt 2 | Pull request 23, merge commit `33da2a718d8d5305bf89035503ac372f07e80a6e` |
| Prompt 3 | Pull request 24, merge commit `0dba694f2a54ab517a2c43bbbd5c77f526a02e65` |
| Prompt 4 | Pull request 25, merge commit `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| OD-01 | Pull request 26, merge commit `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1` |

The Prompt 4 merge and OD-01 form the Wave A focused-planning baseline.

## Current authorities

Use these files in this order:

1. [Planning Completion Baseline](PLANNING-COMPLETION-BASELINE.md) — observed planning and implementation baseline from Prompt 1.
2. [Product Scope and Minimum Architecture](PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md) — product, scope, delivery rationale, and minimum architecture from Prompt 2.
3. [Implementation Disposition Register](IMPLEMENTATION-DISPOSITION-REGISTER.md) — implementation-like asset status, blast radius, and disposition from Prompt 3.
4. [Planning Round Register](PLANNING-ROUND-REGISTER.md) — unresolved-domain classification, focused rounds, dependencies, Prompt 5 bundles, and readiness gates from Prompt 4.
5. [Owner Decision Register](OWNER-DECISIONS.md) — accepted and pending owner choices that focused rounds must consume.
6. [Root Run Lifecycle and Durable Journal](ROOT-RUN-LIFECYCLE-AND-JOURNAL.md) — proposed P0-W21 authority for the first-month lifecycle, state ownership, journal, transaction, projection, migration, restart, and unknown-effect boundaries.
7. [Planning Round Authoritative Inputs](PLANNING-ROUND-INPUTS.md) — exact Repository paths consumed by each Prompt 5 bundle.
8. [Roadmap](ROADMAP.md) — product slice and implementation-order authority.
9. [Implementation Slices](IMPLEMENTATION-SLICES.md) — slice outcomes, boundaries, tests, demos, and planned Receipts.
10. [Slice Acceptance Gates](SLICE-ACCEPTANCE-GATES.md) — aggregate proof required when each slice enters implementation.

The [Architecture](ARCHITECTURE.md), [Run Model](RUN-MODEL.md), [Session Model](SESSION-MODEL.md), accepted [ADRs](decisions/README.md), and focused specifications provide subject authority. They cannot broaden the current scope or reorder delivery without an accepted authority change.

## P0-W21 authority summary

P0-W21 proposes these first-month constraints:

- Session states are `active`, `completed`, and `abandoned`.
- Task states are `in_progress`, `satisfied`, and `abandoned`.
- Root Run states are `ready`, `running`, `waiting_for_user`, `orphaned`, `completed`, `failed`, and `canceled`.
- Workflow step, pending decision, external-operation state, and Evidence state remain separate facts.
- Session start creates Session, Task, and Root Run atomically without persisted setup states.
- Completion atomically aligns current proof, user acceptance, Run completion, Task satisfaction, and Session completion.
- External effects require a durable intent before dispatch and a terminal observation after dispatch. Missing terminal observation produces `orphaned`; Kiln does not repeat automatically.
- One immutable journal and one rebuildable Session projection own durable work state.
- Direct Exqlite, one supervised connection, one writer, Kiln-owned forward SQL migrations, WAL, full synchronous durability, and immediate write transactions define the first store.
- Transcript records, Repository source, Artifact bytes, model reasoning, and process handles remain outside authoritative work-state entries.

For the first-month subset, `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md` owns lifecycle and journal detail over broader examples in earlier subject documents and current Schemas. Prompt 6 must later reconcile machine-readable scaffolds to the complete accepted first-month planning set.

## Remaining planning process

```text
P0-W21 and P0-W22 with Prompt 5
→ P0-W23
→ P0-W24
→ P0-W25
→ Prompt 6-A justified first-month conformance
→ Prompt 7-A independent adversarial review
→ Prompt 8-A adjudication and possible bounded authorization
```

Prompt 7 remains immediately before Prompt 8. Prompt 8 is the only pass that may issue build authorization.

## Current owner decisions

- OD-01 is accepted through ADR-0021: MiniMax only, sealed Context only, Project-controlled source disclosure, and no fallback.
- OD-02 remains pending and must be accepted before P0-W24 and P0-W25 complete.

## Current next action

P0-W21 and P0-W22 are running on separate branches.

P0-W21 owns lifecycle and durable state. P0-W22 owns provider, Context, Repository reads, Tools, and disclosure. Merge P0-W21 first. Rebase P0-W22 onto the integrated P0-W21 result, remove any lifecycle or persistence overlap, validate the exact rebased head, and merge P0-W22 second.
