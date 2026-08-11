# Post-#24 Deferred Architecture Work

Status: findings record, not doctrine
Scope: architectural items surfaced by Kiln field-trial dogfooding that
PR #24 intentionally does not implement, captured here for the
post-#24 program.

PR #24's success criterion is "a coherent, fail-closed architectural
foundation without prematurely implementing the next generation of
governance and consumer-integration behavior." The items below are
therefore catalogued and triaged, not built. This document is a
roadmap and findings record. It is not doctrine; it does not bind
later implementation choices, and it deliberately preserves the
distinction between observations, inferences, and proposals.

## Classification scheme

Each item carries one or more of the following labels. The labels are
about the *kind of claim*, not about priority.

- **OBSERVED** — directly observed in the field trial or in code.
  Evidence cited.
- **INFERRED** — reasoned conclusion from OBSERVED evidence. Marked
  as inference so a reviewer can challenge the conclusion without
  challenging the observation.
- **PROPOSED** — concrete mechanism or shape that addresses an
  OBSERVED or INFERRED need. Has not been implemented.
- **ACCEPTED** — problem statement is agreed; the implementation is
  not yet chosen.
- **DEFERRED** — work that will happen, in a documented order.
- **REJECTED** — explicit declination, with the reason.

Priority is encoded separately as the order in the priority tables
below, not by the label.

## Two tracks

Field-trial friction clustered into two largely independent concerns.
The tracks share Arsenal primitives but should not be forced to share
implementation order.

### Track A — Governance Compression

Reduces ceremony around authoritative state by replacing
hand-maintained narrative summaries with deterministic, schema-bound
projections. The Kiln trial repeatedly lost time to staleness in
narrative status summaries; this track addresses that directly.

Ordering inside Track A:

1. Artifact/state role vocabulary (ACCEPTED problem, PROPOSED shape).
2. Minimal authoritative source model — the list of files that own
   which facts (PROPOSED).
3. Structured Decision Records + commit-role vocabulary (PROPOSED).
4. First generated governance-status projection (PROPOSED,
   deferred).
5. Technical-contract / lifecycle separation artifact, if a
   separate lifecycle file proves necessary (ACCEPTED problem,
   PROPOSED shape, not yet chosen).
6. Stop-condition taxonomy (PROPOSED).
7. Consistency lint — deterministic checks against the role
   vocabulary (PROPOSED).
8. Generated review summary — deterministic summary of exact HEAD
   state replacing narrative PR-body state claims (PROPOSED).

### Track B — Consumer Reliability

Strengthens the consumer-side boundary so installation, upgrade,
checkout, and verification behavior are deliberate rather than
emergent. Track B does not depend on Track A.

Ordering inside Track B (independent of Track A):

1. Consumer integration contract (PROPOSED).
2. Checkout topology qualification (PROPOSED, deferred).
3. Dependency / materialization ownership (PROPOSED).
4. Local / CI verification parity (PROPOSED).
5. Deliberate consumer upgrade lifecycle (PROPOSED).

The two tracks may converge on shared primitives (for example, a
common stop-condition vocabulary) once each has at least one
implemented slice, but neither track gates the other on evidence
available today.

## Lifecycle-sidecar contradiction (resolved)

Earlier drafts of this document classified "separation of digest-
bound technical contracts from mutable lifecycle state" as NEXT and
classified "mutable lifecycle sidecars" as REJECTED. Those two
classifications are inconsistent unless the rejection is read
narrowly.

The corrected position:

### Accepted problem (OBSERVED)

The Kiln trial showed that lifecycle and status information drifts
whenever it is maintained by hand alongside a digest-bound
technical contract. Coupling them inside one file increases the
risk that a status edit silently changes what the contract
appears to authorize.

### Candidate implementation (PROPOSED, not chosen)

A separate, strictly schema-bound lifecycle artifact is one possible
implementation. For example:

```text
T01.contract.md
    technical scope
    requirements
    acceptance criteria
    digest-bound

T01.lifecycle.yaml
    lifecycle state
    progress
    next action
    references
    schema-bound
```

This is **not** accepted as the final file format. A future slice
must choose between this shape, a single authoritative record with
a strict schema, or another mechanism.

### Explicitly rejected (REJECTED)

Reject: an unconstrained or free-form lifecycle sidecar that can
carry requirements, acceptance criteria, technical scope, or other
substantive contract changes outside the authorized digest.

The architectural separation is preserved; only the unconstrained
shape is rejected.

## Decision Record dependency direction (corrected)

Earlier drafts stated that structured Decision Records depend on
generated governance-status projections. That is the wrong direction
on the available evidence.

The corrected dependency direction:

```text
artifact / state roles
    |
    v
Decision Record + commit-role vocabulary
    |
    v
deterministic permitted consequences
    |
    v
generated governance projections
```

A Decision Record is an input to projection generation, not a
downstream consumer of one. Decision Records and commit-role
vocabulary may ship as separate implementation slices, but neither
encodes a backwards dependency on the projections.

## Governance projection priority (corrected)

Kiln field evidence (OBSERVED): repeated hand-maintained
authorization status was the single largest source of ceremony and
stale references in the field trial.

Recommended ordering once Track A begins:

```text
Artifact role vocabulary
    |
    v
minimal authoritative source model
    |
    v
first generated status projection
    |
    v
broader propagation elimination
```

Governance projections are not buried behind unrelated future work
in Track A. They are the direct response to the largest observed
ceremony source, and they sit immediately after the role vocabulary
and source-model slices.

Do not implement here. Track A owns this work in a future slice.

## Consumer Reliability independence (preserved)

Dependency / materialization ownership, checkout topology
qualification, local/CI parity, and deliberate upgrade lifecycle are
separate architectural concerns from the governance work above.
Track B carries them; Track A does not.

The two tracks may share Arsenal primitives later but neither track
gates the other on current evidence.

## Rejections preserved

The following are explicitly rejected and remain rejected:

- **Automatic consumer dependency updates.** Arsenal preserves the
  inspect / compare / propose / review / change-pin / materialize /
  verify chain rather than automatically following upstream. The
  Kiln trial confirmed that authorization must remain a deliberate
  human-mediated act, not a side effect of a tagged release.

- **NLP-first governance architecture.** Replacing structured
  state with model interpretation when deterministic representation
  is practical erodes the exact-state property. This does not
  prohibit all model-assisted review; the preferred rule is:
  structured and deterministic checks first; model judgment only
  for unresolved semantic questions. Generated review summaries
  (Track A item 8) are deterministic; an NLP classifier of PR
  prose is not.

## Items carried forward

The remaining items from the earlier draft are retained with their
priority within Track A or Track B. They are not re-litigated here.

Track A order (post vocabulary): source model, Decision Records +
commit roles, governance projection, lifecycle separation artifact,
stop-condition taxonomy, consistency lint, generated review summary.

Track B order: consumer integration contract, checkout topology
qualification, dependency / materialization ownership, local / CI
verification parity, deliberate consumer upgrade lifecycle.

## Relationship to the program roadmap

These items do not establish a competing frontier. They feed into
existing ARS-NN slices or, where they are new, defer to the first
post-#24 program slice that adopts them. The classification above
gives that slice a starting order.