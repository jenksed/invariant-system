# Kiln Planning Control

**Document type:** Planning authority index  
**Status:** Active  
**Build authorization:** Not issued

## Integrated planning baseline

| Pass or decision | Integrated equivalent |
| --- | --- |
| Prompt 1 | Pull request 22, merge commit `ef487c432a04de705e58ec79569abe5bb51e3d7a` |
| Prompt 2 | Pull request 23, merge commit `33da2a718d8d5305bf89035503ac372f07e80a6e` |
| Prompt 3 | Pull request 24, merge commit `0dba694f2a54ab517a2c43bbbd5c77f526a02e65` |
| Prompt 4 | Pull request 25, merge commit `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| OD-01 | Pull request 26, merge commit `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1` |
| P0-W21 | Pull request 27, merge commit `ca21d0bbc25ddf5861191f8bde374e0761d86c0a` |
| P0-W21 closeout | Pull request 28, merge commit `6c80436b9c220a93b0ff37372deacb1f7ec0fd32` |

## Current authorities

Use these files in this order:

1. [Planning Completion Baseline](PLANNING-COMPLETION-BASELINE.md) — observed planning and implementation baseline from Prompt 1.
2. [Product Scope and Minimum Architecture](PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md) — product, scope, delivery rationale, and minimum architecture from Prompt 2.
3. [Implementation Disposition Register](IMPLEMENTATION-DISPOSITION-REGISTER.md) — implementation-like asset status, blast radius, and disposition from Prompt 3.
4. [Planning Round Register](PLANNING-ROUND-REGISTER.md) — unresolved-domain classification, focused rounds, dependencies, Prompt 5 bundles, and readiness gates from Prompt 4.
5. [Owner Decision Register](OWNER-DECISIONS.md) — accepted and pending owner choices that focused rounds must consume.
6. [Root Run Lifecycle and Durable Journal](ROOT-RUN-LIFECYCLE-AND-JOURNAL.md) — integrated P0-W21 authority for first-month lifecycle, state ownership, journal, transaction, projection, migration, restart, and unknown-effect boundaries.
7. [Model, Context, and Repository Boundary](MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md) — proposed P0-W22 authority for MiniMax M3, sealed Context, fixed Tools, active-Repository reads, disclosure, and secret screening.
8. [Planning Round Authoritative Inputs](PLANNING-ROUND-INPUTS.md) — exact Repository paths consumed by each Prompt 5 bundle.
9. [Roadmap](ROADMAP.md) — product slice and implementation-order authority.
10. [Implementation Slices](IMPLEMENTATION-SLICES.md) — slice outcomes, boundaries, tests, demos, and planned Receipts.
11. [Slice Acceptance Gates](SLICE-ACCEPTANCE-GATES.md) — aggregate proof required when each slice enters implementation.

The [Architecture](ARCHITECTURE.md), [Run Model](RUN-MODEL.md), [Session Model](SESSION-MODEL.md), accepted [ADRs](decisions/README.md), and focused specifications provide subject authority. They cannot broaden the current scope or reorder delivery without an accepted authority change.

The P0-W21 work record and this index control W21 integration status. Any branch-era status text remaining in its large specification is non-authoritative bookkeeping and must not be copied.

## Integrated P0-W21 authority

P0-W21 established:

- Session states `active`, `completed`, and `abandoned`;
- Task states `in_progress`, `satisfied`, and `abandoned`;
- Root Run states `ready`, `running`, `waiting_for_user`, `orphaned`, `completed`, `failed`, and `canceled`;
- separate workflow, pending-decision, operation, and Evidence state;
- atomic Session start and terminal alignment;
- durable operation intent before external dispatch;
- conservative unknown-effect and orphan behavior;
- one immutable journal and one rebuildable Session projection;
- direct Exqlite, one supervised connection, one writer, Kiln-owned migrations, WAL, full synchronous durability, and immediate write transactions.

P0-W22 and every later round consume these decisions. They cannot add Run states or redefine transition, journal, projection, migration, restart, or completion transaction authority.

## Proposed P0-W22 authority

P0-W22 proposes:

- MiniMax M3 as the only real initial model under OD-01;
- direct OpenAI-compatible HTTP and JSON mapping behind a Kiln-native provider behaviour;
- one deterministic fake provider;
- no fallback or automatic retry after dispatch;
- one sealed ordered Context package capped at 32,000 estimated input tokens;
- exactly four possible Tools: `repo.search`, `repo.read`, `artifact.read`, and `change.propose`;
- fixed workflow-step Tool projection with unused schemas absent;
- canonical-root, no-symlink, text-only, size, digest, ignore, and stale-source controls;
- default-denied hosted source disclosure under accepted Project policy;
- mandatory secret-path and content screening;
- transient provider-native reasoning that cannot become durable Context, Evidence, or Receipt content;
- unknown-effect classification through P0-W21 when a dispatched invocation lacks a terminal result.

ADR-0023 owns the proposed concrete MiniMax M3 endpoint and model profile.

## W21 ownership audit

P0-W22 consumes operation identity, intent-before-dispatch, terminal-or-unknown result, expected revision, idempotency, restart, and orphan rules.

P0-W22 does not define or change Session, Task, or Run states; transitions; journal entries; projections; migrations; store startup; terminal alignment; or completion transaction prerequisites. Any conflict resolves in favor of P0-W21.

## Wave A sequence

```text
P0-W21 integrated
→ validate and integrate P0-W22
→ P0-W23
→ record OD-02 before P0-W24 and P0-W25 complete
→ P0-W24
→ P0-W25
→ Prompt 6-A justified first-month conformance
→ Prompt 7-A independent adversarial review
→ Prompt 8-A adjudication and possible bounded authorization
```

Prompt 7-A remains immediately before Prompt 8-A. Prompt 8-A is the only pass that may issue first-month build authorization.

## Current owner decisions

- OD-01 is accepted through ADR-0021: MiniMax only, sealed Context only, Project-controlled source disclosure, and no fallback.
- OD-02 remains pending and must be accepted before P0-W24 and P0-W25 complete.

## Wave B entry gate

P0-W26 and P0-W27 do not run during Wave A.

They require accepted runtime Evidence from an authorized Single-Run Alpha showing:

- one real source change;
- durable restart behavior;
- controlled Patch authority;
- registered verification;
- criterion-bound Evidence;
- one valid Receipt;
- observed failure or interruption behavior.

Only after that Evidence exists:

```text
P0-W26
→ P0-W27
→ Prompt 6-B
→ Prompt 7-B
→ Prompt 8-B
→ only the delegated implementation scope explicitly authorized by Prompt 8-B
```

## Current next action

Complete P0-W22 review, exact W21 ownership audit, and exact-head validation. Integrate P0-W22 second. Then begin P0-W23.
