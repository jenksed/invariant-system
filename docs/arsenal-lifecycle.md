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
