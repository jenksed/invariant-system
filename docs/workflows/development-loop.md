---
title: Governed Engineering Loop
description: Normative change process connecting intent, contracts, bounded implementation, evidence, independent review, human decision, promotion, and documentation reconciliation.
status: current
verified_at_commit: fed26fcc8b7598a56ce86e47c99d0154e6b46436
source_paths:
  - AGENTS.md
  - invariant.boundaries.json
  - docs/development/engineering-process.md
  - docs/architecture/contracts.md
  - docs/architecture/evidence-flow.md
audience:
  - developer
  - operator
---

# Governed Engineering Loop

This page specifies the **engineering process shape** Invariant work should follow. It does not claim that every stage is automated by current product code. Use [Current system status](../status.md) for implementation maturity.

```mermaid
flowchart LR
    G[Goal / problem]
    R[Recon + state basis]
    A[Acceptance property]
    C[Contract + dependency freeze]
    I[Bounded implementation]
    V[Verification]
    Q[Independent review]
    H[Human decision]
    P[Promotion / integration]
    D[Docs + roadmap reconciliation]

    G --> R --> A --> C --> I --> V --> Q --> H --> P --> D
    V -. defect .-> I
    Q -. defect / weak proof .-> I
    H -. revise .-> I
```

## What must be true at each transition

| Transition | Minimum condition |
| --- | --- |
| Recon → acceptance | Current state, ownership, and relevant prior evidence are identified. |
| Acceptance → contract freeze | The intended property is explicit enough to distinguish proof from proxy. |
| Contract freeze → implementation | Shared contracts/decisions consumed by implementation are resolved or explicitly bounded. |
| Implementation → verification | Candidate state is immutable/identifiable and relevant checks target that state. |
| Verification → review | Evidence artifacts are available with scope and limitations; implementer narrative is not the only source. |
| Review → human decision | Review is independent where required, bound to the exact candidate, and material defects/uncertainty are classified. |
| Human decision → promotion | The authorized state and exact decision are recorded; rejected/revise states cannot be promoted as complete. |
| Promotion → docs reconciliation | Current docs, status, roadmap, and historical records reflect the new truth without rewriting history or rebinding product evidence to a later docs-only SHA. |

## Independent review

Where the work contract requires independence:

```text
IMPLEMENTER != INDEPENDENT_REVIEWER
```

The reviewer is read-only against the candidate. The reviewer reports demonstrated defects, speculative concerns, and unproven properties separately. If the implementer repairs anything, the candidate changes and the reviewer must re-check the new candidate.

Review approval does not equal human acceptance unless that authority relationship is explicitly defined. Do not infer it from workflow convenience.

## Acceptance-sensitive documentation

Documentation may be consumed before promotion without entering the evidence-bound worktree's history. When the current candidate is not yet explicitly accepted, prefer an exact-SHA detached documentation worktree and keep `HUMAN_DECISION = PENDING` unless an authoritative decision record says otherwise.

## Visibility requirement

Every consequential lane should expose enough [traceability](../reference/traceability.md) to answer:

```text
what property?
which owner/authority?
which contract?
which exact product candidate?
which evidence?
which independent reviewer and reviewed SHA?
which human decision?
which promotion/integration identity?
which documentation/status changed because of it?
```

A compact authoritative handoff/state file is preferable to repeating the same information in every lane.

## Parallel work

Parallel execution is cheap; independent work is not. Fan out recon, falsification, documentation, or tests only when they do not consume unresolved shared decisions. Shared contract/authority decisions should be frozen before dependent implementation lanes proceed.

## Completion

A model saying “done,” a clean diff, or a green test suite may be necessary evidence. None is sufficient by itself. Completion is the accepted result of the governed process for the stated property.
