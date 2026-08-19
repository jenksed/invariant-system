---
title: Engineering Traceability
description: Minimal reference model connecting acceptance properties, contracts, implementation state, evidence, review, decisions, integration identity, and documentation.
status: current
verified_at_commit: fed26fcc8b7598a56ce86e47c99d0154e6b46436
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

Traceability answers a narrow question: **what lets us confidently move this work from intended → implemented → demonstrated → reviewed → accepted without confusing one stage or state identity for another?**

Do not build a second artifact database in Markdown. Use this model to connect authoritative records that already exist.

## Trace chain

```text
requirement / acceptance property
        ↓
architectural owner + authority boundary
        ↓
contract(s) consumed or changed
        ↓
exact implementation candidate
        ↓
verification evidence
        ↓
independent review / falsification
        ↓
human decision when required
        ↓
promotion / integration identity
        ↓
documentation + roadmap/status reconciliation
```

A missing link is not automatically a failure. It is visible uncertainty that must be resolved or explicitly accepted before the next stage consumes it.

## Minimal trace record

| Field | What it must identify |
| --- | --- |
| Acceptance property | The property that must actually be true, not a task label. |
| Owner / decision authority | Component plus human/system authority allowed to decide or mutate. |
| State basis | Worktree/branch plus exact base/candidate SHA or equivalent immutable identity. |
| Accepted product candidate | Exact product SHA accepted for the work package; never silently replaced by a later docs-only integration SHA. |
| Contracts | Canonical contracts read, produced, or changed. |
| Dependencies | Decisions or artifacts that must be frozen first. |
| Implementation | Source paths and candidate SHA. |
| Required evidence | Tests/scenarios/artifacts selected to prove the property. |
| Produced evidence | Exact command/result/artifact references. |
| Verified evidence | Evidence checked against its claimed state and scope. |
| Review | Independent reviewer/falsification record, identity, scope, and reviewed candidate SHA. |
| Human decision | ACCEPT / REVISE / REJECT or the domain-specific explicit decision. |
| Integration identity | Pre/post integration SHAs when docs, promotion, or other history changes follow acceptance. |
| Documentation impact | Current docs/status/roadmap pages that must reconcile. |
| Open uncertainty | Anything intentionally unproven or deferred. |

## Evidence state is not page status

Use these words locally when useful for an evidence requirement:

- `required` — needed before the acceptance property can be judged;
- `produced` — an artifact/result exists;
- `verified` — the artifact/result has been checked against its claimed state and scope;
- `accepted` — the responsible human/system authority accepted the evidence for the decision at hand.

These do not replace documentation page statuses such as `current`, `partial`, `planned`, or `experimental`.

## Review identity

Where independence is required, record both roles and the immutable state reviewed:

```text
IMPLEMENTER =
INDEPENDENT_REVIEWER =
REVIEWED_CANDIDATE_SHA =
REVIEW_VERDICT =
HUMAN_DECISION =
```

The implementer cannot satisfy the independent-review field by performing another self-review pass. A repair after review creates a new candidate and invalidates the old review for completion purposes until the independent reviewer checks the new state.

## Integration identity

When accepted product work is followed by documentation/history integration, keep identities separate:

```text
ACCEPTED_PRODUCT_CANDIDATE_SHA =
PRE_DOCS_INTEGRATION_HEAD =
POST_DOCS_INTEGRATION_HEAD =
```

The later head may contain valid documentation changes without becoming the SHA against which product acceptance evidence was produced.

## Contract impact view

For any cross-product change, make the direction visible:

| Contract | Producer(s) | Consumer(s) | Authority implication | Compatibility decision | Evidence |
| --- | --- | --- | --- | --- | --- |
| `<contract>` | `<paths/products>` | `<paths/products>` | `<what this contract cannot grant>` | `<compatible/migration/break>` | `<tests/fixtures/scenario>` |

A producer and consumer agreeing on the same wrong local shape is not sufficient. The canonical root contract remains the semantic anchor.

## Completion check

A completion claim is credible when an independent reviewer can move from the acceptance property to the exact state, contract, evidence, review, and human decision without relying on the implementer's narrative, and when later documentation/history changes do not obscure the accepted product identity.

See [Evidence flow](../architecture/evidence-flow.md), [Cross-product contracts](../architecture/contracts.md), and the [engineering process](../development/engineering-process.md).
