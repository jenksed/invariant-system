# Arsenal Epistemic Lifecycle

Status: accepted
Owner: ARS-01
Scope: Project Arsenal canonical lifecycle and Qualified Method Record integration

## Purpose

Reconcile Arsenal's R&D role with one explicit epistemic lifecycle that maps onto the
existing `LIFECYCLE_STATES` and `EVALUATION_STATES` protocol vocabularies rather than
creating a parallel state machine. The lifecycle below describes the epistemic maturity
of a method or capability candidate. It does not grant filesystem, network, Git, or
production authority.

The lifecycle is the canonical Project Arsenal expression of the
`Idea -> Hypothesis -> Experimental -> Replicated/Evaluated -> Qualified`
chain declared in `engineering-system/decisions/0001-product-system.md`.
It is implemented entirely through existing protocol vocabulary and existing
artifacts so that downstream consumers and products (Loadout, Kiln) do not
need to learn a second state machine.

## Canonical lifecycle states

The lifecycle table describes **capability state**, not Qualified Method Record
status. A capability is the contract / productized surface; its lifecycle and
evaluation are owned by the canonical capability fragment
(`arsenal/capabilities/*.json`) and the qualification receipts under
`evaluation/qualifications/`. The two protocol values are projections of one
epistemic trajectory.

| Epistemic stage    | Existing lifecycle | Existing evaluation.status | Meaning                                                          |
|--------------------|--------------------|----------------------------|------------------------------------------------------------------|
| Idea               | `draft`            | `unassessed`               | Concept exists; no claim yet; no evidence.                       |
| Hypothesis         | `draft`            | `planned`                  | Claim declared; no execution evidence.                           |
| Experimental       | `testing`          | `candidate`                | At least one executable evidence pass; promotion not yet earned. |
| Replicated/Evaluated | `testing`        | `candidate`                | Multiple replications / contexts observed; still pre-stable.     |
| Qualified          | `stable`           | `qualified`                | Evaluation suite gate satisfied; promotion evidence complete.    |

The terminal state `deprecated` remains a non-epistemic terminal that any prior
stage may transition into. It is excluded from the epistemic chain because it
encodes retirement rather than evidence strength.

## QMR status and capability state are independent projections

A Qualified Method Record carries its own `status` field
(`experimental` or `qualified`). That status is **method maturity** — the
evidence Arsenal has gathered for a method in a declared context. It is NOT
the capability's lifecycle value, and it is NOT the capability's evaluation
status. The two projections are distinct:

| Projection | What it describes | Where it lives | Owner |
|------------|-------------------|----------------|-------|
| **QMR status** (`experimental` / `qualified`) | Method maturity for a declared context; bound to evidence in `evaluation.evidence_refs`, observed cases, observed strengths, observed failures. | The method record itself: `evaluation/method-records/*.yaml` | The method record (`arsenal.method-records` in the source model). |
| **Capability lifecycle** (`draft` / `testing` / `stable` / `deprecated`) | The epistemic state of the capability contract/productized surface. | `arsenal/capabilities/<id>.json` → `capability.lifecycle` | `arsenal.capability-fragments` in the source model. |
| **Capability evaluation.status** (`unassessed` / `planned` / `candidate` / `qualified`) | The evaluation state of the capability, recorded against the qualification suite gate. | `arsenal/capabilities/<id>.json` → `capability.evaluation.status` and the qualification receipts under `evaluation/qualifications/` | `arsenal.capability-fragments` plus the bench-emitted qualification receipts. |

Implications the record-keeping must preserve:

1. A method may be `experimental` while its underlying capability is still
   `draft` / `unassessed` (no qualification work has begun).
2. A method may be `qualified` for one context while its capability is still
   `testing` / `candidate` overall (the method-level gate is satisfied but the
   broader capability promotion criteria are not).
3. A `qualified` method does NOT automatically promote its capability. Capability
   promotion remains a separate decision with its own evidence boundary; the
   capability fragment is the canonical owner of `capability.lifecycle` and
   `capability.evaluation.status`.
4. The QMR is evidence, never authority. It binds to the capability via
   provenance (`procedure_ref`, `arsenal_commit`, `record_digest`,
   `evidence_refs`) but does not redefine the canonical values.
5. The protocol enum `LIFECYCLE_STATES` and `EVALUATION_STATES` are owned by
   `scripts/arsenal_protocol.py`. Arsenal-distribution content does not
   introduce a parallel state machine; the QMR `status` enum
   (`experimental` / `qualified`) is the closed vocabulary for method
   maturity and is separate from the capability protocol enums.

## Why this design does not create parallel authority

1. **Closed vocabulary.** The epistemic vocabulary is the projection of two
   pre-existing protocol enumerations: `LIFECYCLE_STATES` in
   `scripts/arsenal_protocol.py` and `EVALUATION_STATES` in the same module.
   Adding a new epistemic state would require extending the protocol module,
   which is forbidden for Arsenal-distribution content.

2. **Existing owner artifacts carry the values.** Lifecycle and evaluation
   values live on the canonical capability fragment (`arsenal/capabilities/*.json`)
   and on the qualification receipt (`evaluation/qualifications/*.json`). The
   source model already classifies those as the canonical owners of
   `capability.current-lifecycle` and `capability.current-evaluation`
   (see `arsenal/source-model.json` facts). The lifecycle here describes the
   same values; it does not introduce a new owner.

3. **Method records are evidence, not authority.** A Qualified Method Record
   declares that Arsenal has evaluated a method sufficiently for a named
   context. It does not promote a capability, change a lifecycle, or grant
   any authority. The capability's `lifecycle` and `evaluation.status` are
   the canonical state; the record binds to them through provenance digests.

4. **Reuses the contract.** The Qualified Method Record follows the
   `engineering-system/contracts/qualified-method-record/v0` schema. It does
   not redefine it. Existing fixtures (`qualified-method-record.v0.yaml`)
   remain loadable.

5. **No new consumer surface.** Loadout continues to consume the capability
   fragment's lifecycle and evaluation status. Kiln continues to own the
   runtime authority model. The record is a research evidence surface, not
   a runtime surface.

## Transitions

The following transitions are allowed. The direction encodes epistemic
strength. Reverse transitions are evidence-driven (e.g. a regression in a
qualified capability returns to `candidate`); Arsenal does not pre-commit to
which artifact records a regression but documents the direction here so
evidence authors can reason about it.

```text
Idea                -> Hypothesis
Hypothesis          -> Experimental
Experimental        -> Replicated/Evaluated
Replicated/Evaluated -> Qualified
(any prior state)   -> Deprecated
```

A capability cannot move to `Qualified` without the qualification suite
declaring a satisfied gate and the bench runner emitting a qualification
receipt that is bound to the capability, target, adapter, and suite digests
(see `scripts/arsenal_bench.py:build_qualification_receipt`).

## Method-record classification

A Qualified Method Record carries a `status` field that mirrors the
epistemic stage:

- `experimental` — bound to one or more observed cases that are not yet
  sufficient for qualification. This is the only honest status when
  current evidence is illustrative rather than comprehensive.
- `qualified` — bound to a satisfied qualification gate.

The contract allows `qualified` only for the declared context. A later
record may supersede a method without breaking the contract. Negative
knowledge (excluded contexts, observed failures) is first-class in the
record.

## Evidence gap policy

If the available evidence for a method cannot justify `qualified`, the
record is emitted with `status: experimental` and an explicit
`observed_failures` or `qualification_gap` entry. Arsenal does not inflate
confidence to satisfy a package name.

## Acceptance for ARS-01

ARS-01 produces:

1. this document;
2. one Qualified Method Record (experimental) for a Repository Recon method;
3. a validation script that enforces the v0 schema semantics on the record;
4. focused tests for invalid transitions, status classification, and provenance.
