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

## Status update (post-Governance-Compression-01)

Slice 1 of Track A has been implemented and merged as a separate
PR. The change introduced a closed governance vocabulary in
`scripts/arsenal_governance.py`, a small source-model schema and
instance at `arsenal/source-model.json`, a loader
(`scripts/arsenal_source_model.py`), a fail-closed validator
(`scripts/arsenal_source_validate.py`), and characterization tests
(`scripts/test-arsenal-governance.py`). The implementation:

* keeps the canonical governance vocabulary out of
  `arsenal_protocol.py` (governance is a separate closed surface,
  not a protocol/execution concern);
* treats ownership and state role as orthogonal dimensions, with
  `state_role` further separated from materialization
  (`authored` vs `generated`) where the evidence demands it;
* makes the source model an *index* of where facts live rather
  than a duplicate copy of their values; the loader rejects
  value-shaped keys inside the model;
* classifies `.arsenal.lock` as `generated + normative` and a
  qualification receipt as `generated + historical` to prove that
  materialization is not a synonym for `derived`.

The roadmap below is updated to record:

* Track A item 1 (`Artifact / state role vocabulary`) is now
  `ACCEPTED` in shape and the implementation is merged; only
  *extensions* remain to be discussed.
* Track A items 2–8 remain `PROPOSED`/`DEFERRED`.
* Track B items remain independent of Track A.

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

1. Artifact/state role vocabulary (ACCEPTED problem, ACCEPTED
   shape — implemented as `scripts/arsenal_governance.py` plus
   `scripts/arsenal_source_model.py` / `arsenal_source_validate.py`).
2. Minimal authoritative source model — the list of files that own
   which facts (ACCEPTED in foundation; the source-model index is
   implemented, but its coverage of every governance fact across
   the program remains PROPOSED).
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

## Empirical classification results

The Governance Compression 01 slice produced the following
classifications from repository evidence (not from prior
assumption). They are recorded here so that future slices do not
have to re-litigate them.

* `scripts/arsenal_protocol.py`,
  `scripts/arsenal_governance.py`, every protocol
  schema under `arsenal/`, `evaluation/`, `arsenal/observability/`,
  `arsenal/knowledge/`, and `arsenal/trust/`, and the
  `arsenal/source-model.schema.json` are `arsenal-protocol` +
  `normative` + `authored`. These define what valid Arsenal data
  IS, not which concrete instances Project Arsenal ships.
* `arsenal/distribution.compiler.targets` (supported targets and
  adapter versions), `arsenal/distribution.compiler.export-plan`,
  `arsenal/distribution.schema-registry` (canonical schema $id
  URLs), the generated `distribution/agent-skills/<pkg>/{SKILL.md,
  references/, arsenal-manifest.json}` family, and the Project
  Arsenal-owned qualification evidence under
  `evaluation/qualifications/*.json` are `arsenal-distribution`.
  A consumer may select a subset (`enabled_targets`) but does
  not redefine the supported targets, the schema $id registry,
  the export plan, or Project Arsenal's own distribution
  packages.
* `arsenal/capabilities/*.json` is `arsenal-distribution` +
  `normative` + `authored`. These are canonical Project Arsenal
  capability fragments; a consumer project installs/uses them
  but does not redefine them. A fork or vendor must publish its
  own fragment family and its own source-model.
* `arsenal/registry.json` and the
  `arsenal/registry.d/*.json` family are `arsenal-distribution` +
  `normative` + `authored`. Per `arsenal/ASSET_CONTRACT.md` both
  the base and the `.d` fragments are independently authored;
  the merged view is the canonical read.
* `arsenal/distribution.compiler.export-plan` owns the
  capability→target mapping. The fragment owns the canonical
  capability lifecycle/evaluation; the lockfile owns the
  *pinned* lifecycle/evaluation. These are different facts, not
  duplicate normative owners.
* `evaluation/cases/{core-engineering,local-cloud,distribution-qualification*}.json`
  are `arsenal-distribution` + `normative` + `authored`. The
  evaluation schemas (`*.schema.json`) are protocol; the
  concrete suite instances are Project Arsenal distribution
  content.
* `arsenal/knowledge/fixtures/kft-0-kiln.json` and
  `docs/field-trials/KFT-0-kiln.md` are `arsenal-distribution` +
  `historical`. The SUBJECT of the field trial is Kiln, but the
  OWNER is Project Arsenal: Project Arsenal decides whether the
  fixture/report is published, updated, or rewritten.
* `docs/roadmap/post-pr-24-deferred-architecture.md` and
  `docs/roadmap/capability-system.md` are `arsenal-distribution` +
  `narrative` + `authored`. A consumer does not redefine Project
  Arsenal's canonical roadmaps by configuring its installation.
* `engineering/doctrine/ARCHITECTURE.md` is `arsenal-protocol` +
  `normative` + `authored` (it sets authoritative ownership/state
  boundaries; treat it as canonical architecture, not as a
  free-form explainer).
* `arsenal/source-model.json` is `arsenal-distribution` +
  `normative` + `authored`. The schema
  `arsenal/source-model.schema.json` is `arsenal-protocol`. The
  instance is Project Arsenal's own classification index.
* `arsenal.project.json` is `consumer-deployed` + `normative` +
  `authored`. It is the only consumer-authored artifact in this
  repository. It never absorbs current branch / current PR /
  current qualification.
* `.arsenal.lock` is `consumer-deployed` + `normative` +
  `generated`. It is the canonical `generated + normative`
  counter-example to a `generated == derived` shortcut. It owns
  PINNED facts (`lockfile.pinned-capability-*`), not duplicate
  copies of canonical capability facts.

The source-model also exposes an "impossible in this repository"
property: a generated artifact may be `generated + normative`
(the lockfile) or `generated + historical` (a receipt) without
becoming `derived`. Future slices that propose a universal
`authored/generated` vocabulary as a first-class axis should
weigh whether their evidence requires the dimension before
encoding it.

## Discovered ambiguities

* The old "Layer 4 — Fixtures, tests, historical evidence"
  conflates ownership with epistemic role. The implementation
  records three ownership layers (`arsenal-protocol`,
  `arsenal-distribution`, `consumer-deployed`) and lets
  `state_role = historical` carry the "evidence" half. This is
  the more honest decomposition and avoids permanently encoding
  the older ambiguity.
* `materialization` is recorded per-artifact where it is
  meaningful rather than declared as a mandatory third axis. The
  slice does not assume a future axis is needed.
* An initial draft of the source model classified
  `arsenal/capabilities/*.json` and the asset registry as
  `consumer-deployed`. The reconciliation pass moved both to
  `arsenal-distribution` because they are canonical Project
  Arsenal content, not per-installation state.
* An initial draft of the source model classified qualification
  receipts, KFT-0 evidence, and Project Arsenal roadmaps as
  `consumer-deployed`. The reconciliation pass moved all three to
  `arsenal-distribution` because ownership answers "who is
  permitted to define/revise?", not "what is the subject?" or
  "who consumes?".
* The source-model schema and the source-model instance are
  intentionally distinct: the schema is `arsenal-protocol` and
  the instance is `arsenal-distribution`. The schema defines
  the structure of a valid source-model; the instance is
  Project Arsenal's own classification of its own content. A
  fork/vendor publishes its own instance.
* The lockfile's lifecycle/evaluation values were initially
  treated as a duplicate of the canonical lifecycle. The
  reconciliation pass split them into distinct facts
  (`capability.current-lifecycle` vs
  `lockfile.pinned-capability-lifecycle`) so the lockfile is a
  consumer-accepted pin, not a duplicate normative owner.

## Items carried forward

The remaining items from the earlier draft are retained with their
priority within Track A or Track B. They are not re-litigated here.

Track A order (post vocabulary, post-source-model foundation):
Decision Records + commit roles, governance projection, lifecycle
separation artifact, stop-condition taxonomy, consistency lint,
generated review summary.

The source model itself is intentionally narrow in this slice:
coverage of the load-bearing artifacts above is in. A future slice
should consider whether the source model should additionally index
domain facts that are currently described only in prose
(architecture boundaries, program-roadmap items, evaluation
claim-scope text). That expansion is PROPOSED and remains
non-blocking.

Track B order: consumer integration contract, checkout topology
qualification, dependency / materialization ownership, local / CI
verification parity, deliberate consumer upgrade lifecycle.

## Relationship to the program roadmap

These items do not establish a competing frontier. They feed into
existing ARS-NN slices or, where they are new, defer to the first
post-#24 program slice that adopts them. The classification above
gives that slice a starting order.