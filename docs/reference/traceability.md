---
title: Engineering Traceability
description: Minimal reference model connecting acceptance properties, contracts, implementation state, evidence, review, decisions, and documentation.
status: current
verified_at_commit: 325b1b5fe2e65c35bde9a1cd75e099a540b283aa
source_paths:
  - contracts/
  - docs/architecture/contracts.md
  - docs/architecture/evidence-flow.md
  - docs/development/engineering-process.md
audience:
  - developer
  - operator
---

# Engineering Traceability

Traceability answers a narrow question: **what lets us confidently move this work from intended → implemented → demonstrated → accepted without confusing one stage for another?**

Do not build a second artifact database in Markdown. Use this model to connect authoritative records that already exist.

## Trace chain

```text
requirement / acceptance property
        ↓
architectural owner + authority boundary
        ↓
contract(s) consumed or changed
        ↓
exact implementation state
        ↓
verification evidence
        ↓
independent review / falsification
        ↓
human decision when required
        ↓
documentation + roadmap/status reconciliation
```

A missing link is not automatically a failure. It is visible uncertainty that must be resolved or explicitly accepted before the next stage consumes it.

## Minimal trace record

| Field | What it must identify |
| --- | --- |
| Acceptance property | The property that must actually be true, not a task label. |
| Owner / authority | Component and human/system authority allowed to decide or mutate. |
| State basis | Worktree/branch plus exact base/candidate SHA or equivalent immutable identity. |
| Contracts | Canonical contracts read, produced, or changed. |
| Dependencies | Decisions or artifacts that must be frozen first. |
| Implementation | Source paths and candidate SHA. |
| Required evidence | Tests/scenarios/artifacts selected to prove the property. |
| Produced evidence | Exact command/result/artifact references. |
| Review | Independent reviewer/falsification record and scope. |
| Human decision | ACCEPT / REVISE / REJECT or the domain-specific explicit decision. |
| Documentation impact | Current docs/status/roadmap pages that must reconcile. |
| Open uncertainty | Anything intentionally unproven or deferred. |

## Evidence state is not page status

Use these words locally when useful for an evidence requirement:

- `required` — needed before the acceptance property can be judged;
- `produced` — an artifact/result exists;
- `verified` — the artifact/result has been checked against its claimed state and scope;
- `accepted` — the responsible human/system authority accepted the evidence for the decision at hand.

These do not replace documentation page statuses such as `current`, `partial`, `planned`, or `experimental`.

## Contract impact view

For any cross-product change, make the direction visible:

| Contract | Producer(s) | Consumer(s) | Authority implication | Compatibility decision | Evidence |
| --- | --- | --- | --- | --- | --- |
| `<contract>` | `<paths/products>` | `<paths/products>` | `<what this contract cannot grant>` | `<compatible/migration/break>` | `<tests/fixtures/scenario>` |

A producer and consumer agreeing on the same wrong local shape is not sufficient. The canonical root contract remains the semantic anchor.

## Completion check

A completion claim is credible when a reviewer can move from the acceptance property to the exact state, contract, evidence, review, and decision without relying on the implementer's narrative.

See [Evidence flow](../architecture/evidence-flow.md), [Cross-product contracts](../architecture/contracts.md), and the [engineering process](../development/engineering-process.md).
