# Kiln Planning Control

**Document type:** Planning authority index  
**Status:** Proposed by P0-W20  
**Build authorization:** Not issued

## Integrated planning baseline

| Pass | Integrated equivalent |
| --- | --- |
| Prompt 1 | Pull request 22, merge commit `ef487c432a04de705e58ec79569abe5bb51e3d7a` |
| Prompt 2 | Pull request 23, merge commit `33da2a718d8d5305bf89035503ac372f07e80a6e` |
| Prompt 3 | Pull request 24, merge commit `0dba694f2a54ab517a2c43bbbd5c77f526a02e65` |

The Prompt 3 merge was the current `main` head when P0-W20 began. No later commit changed the product target, implementation inventory, dispositions, first-month target, twelve-week target, or planning dependencies.

## Current authorities

Use these files in this order:

1. [Planning Completion Baseline](PLANNING-COMPLETION-BASELINE.md) — observed planning and implementation baseline from Prompt 1.
2. [Product Scope and Minimum Architecture](PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md) — product, scope, delivery rationale, and minimum architecture from Prompt 2.
3. [Implementation Disposition Register](IMPLEMENTATION-DISPOSITION-REGISTER.md) — implementation-like asset status, blast radius, and disposition from Prompt 3.
4. [Planning Round Register](PLANNING-ROUND-REGISTER.md) — unresolved-domain classification, focused rounds, dependencies, Prompt 5 bundles, readiness gates, and owner decisions from Prompt 4.
5. [Planning Round Authoritative Inputs](PLANNING-ROUND-INPUTS.md) — exact repository paths consumed by each Prompt 5 bundle.
6. [Roadmap](ROADMAP.md) — product slice and implementation-order authority.
7. [Implementation Slices](IMPLEMENTATION-SLICES.md) — slice outcomes, boundaries, tests, demos, and planned Receipts.
8. [Slice Acceptance Gates](SLICE-ACCEPTANCE-GATES.md) — aggregate proof required when each slice enters implementation.

The [Architecture](ARCHITECTURE.md), [Run Model](RUN-MODEL.md), [Session Model](SESSION-MODEL.md), accepted [ADRs](decisions/README.md), and focused specifications provide subject authority. They cannot broaden the current scope or reorder delivery without an accepted authority change.

## Remaining planning process

```text
Prompt 4 Planning Round Register
→ Prompt 5 once per required focused round
→ Prompt 6 for justified conformance scaffolding
→ Prompt 7 independent adversarial review
→ Prompt 8 adjudication and possible bounded build authorization
```

The first-month and delegated targets use separate conformance, review, and authorization waves. Prompt 7 remains immediately before Prompt 8. Prompt 8 is the only pass that may issue build authorization.

## Current next action

After P0-W20 is reviewed, accepted, and integrated, run Prompt 5 for:

```text
P0-W21 — Root Run lifecycle and durable journal
```

P0-W22 may start in parallel only after P0-W20 is integrated and owner decision OD-01 is supplied. Merge P0-W21 first, then rebase and reconcile P0-W22 before merge.
