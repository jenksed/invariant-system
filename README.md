# temper

A terminal user interface for the unified Arsenal, Loadout, and Kiln product
experience.

## Status

Stub. No source, no build, no entry point. This repository documents what
Temper would surface from the other three products and what it would refuse to
do.

The user has not yet authorized Temper implementation. Documentation is the
deliverable; product code is not.

## What this document is for

This document is a candid grounding note for a funding or implementation
review. It claims only what the other three products actually expose through
their merged code, fixtures, CLI surfaces, and READMEs as of 2026-08-12.

If a claim in this document cannot be traced to a file in
`project-arsenal`, `loadout`, `kiln`, or `engineering-system`, treat it as
unsubstantiated.

## Product position

The engineering system decision `decisions/0001-product-system.md` divides
the system across three independent products:

- Arsenal (`jenksed/project-arsenal`) owns qualified methods and engineering
  judgment.
- Loadout (`jenksed/loadout`) owns the user-facing product experience,
  Goals, Capabilities, and the Result view.
- Kiln (`jenksed/kiln`) owns runtime authority, execution, durable state,
  evidence, and acceptance readiness.

Temper is a fourth surface. It does not own any of the above. It reads
results the other three already publish and renders them in a terminal.

Temper's role is bounded by the same decision: a later interface layer
consumes native application commands and current projections and cannot
write persistence directly. That sentence is taken from
`kiln/docs/CLI-TUI.md` and is the architectural ceiling Temper must
respect.

## What Temper would surface

Each section below names the exact file or fixture the claim is grounded in.

### Arsenal — Qualified Method Record (QMR) evaluation output

Arsenal's wave-2 ARS-01 work landed through PR #26 and is present on
`main` at merge commit `486fc9d`. It introduced:

- A canonical epistemic lifecycle that maps the engineering-system decision
  `Idea -> Hypothesis -> Experimental -> Replicated/Evaluated -> Qualified`
  onto the existing `LIFECYCLE_STATES` and `EVALUATION_STATES` protocol
  vocabularies. Source:
  `project-arsenal/docs/arsenal-lifecycle.md`,
  `project-arsenal/arsenal/CAPABILITY_CONTRACT.md` (sections
  "Evaluation and lifecycle" and "ARS-01 epistemic lifecycle").
- One Qualified Method Record in `experimental` status for the Repository
  Recon / Architecture Anchor method. Source:
  `project-arsenal/evaluation/method-records/repository-recon.architecture-anchor.v0.yaml`.
- A deterministic validator, characterization tests, and CI for the
  record. Source: `project-arsenal/scripts/arsenal_method_record.py`,
  `project-arsenal/scripts/test-method-record.py`.
- A field-by-field contract map. Source:
  `project-arsenal/evaluation/method-records/contract-map.md`.

What this means for Temper: Temper would read Arsenal's method records and
capability fragments as data and present:

- the method's `status` (`experimental` or `qualified`) and the explicit
  `qualification_gap` when present;
- the canonical `capability.lifecycle` and `capability.evaluation.status`
  from `arsenal/capabilities/*.json`;
- the record's `observed_strengths`, `observed_failures`, and `exclusions`
  as first-class labels — never collapsed;
- the provenance digests (`procedure_ref`, `record_digest`,
  `arsenal_commit`) for traceability.

What Temper would not do: synthesize a qualification verdict. The
contract is explicit — qualification requires a qualification receipt
bound to the capability, target, adapter, and suite digests, and the
canonical Repository Recon record today is `experimental` with an
honest `qualification_gap`. Any Temper view that implies otherwise is a
violation.

### Loadout — Work Envelope and Run Result Envelope (simulated)

Loadout's wave-2 LOD-01 work landed through PR #3 and is present on
`main` at merge commit `93b3dcc`. It introduced a vertical slice for the
Goal "Understand this repository". Source files:

- The Capability contract in
  `loadout/src/core/capability-contract.ts` and the mirrored stable
  contract in `loadout/src/packs/repository-recon/capability.json`.
- The Goal catalogue in `loadout/src/core/goal.ts`.
- The Work Envelope compile step in `loadout/src/core/compile.ts` that
  produces a `engineering-system/work-envelope/v0` envelope.
- The deterministic in-process fake Kiln boundary in
  `loadout/src/core/fake-kiln-boundary.ts` that returns a
  `engineering-system/run-result-envelope/v0` envelope with every
  evidence item labeled `simulated: true`.
- The Result view in `loadout/src/core/result-view.ts` that presents
  success, blocked, and unknown states truthfully.
- Fixtures that prove contract stability across method substitution:
  `loadout/fixtures/qualified-method-record.v0.yaml`,
  `loadout/fixtures/qualified-method-record.v0.alt.yaml`,
  `loadout/fixtures/work-envelope.v0.yaml`,
  `loadout/fixtures/run-result-envelope.v0.yaml`.
- CLI surface (`npx loadout catalog`, `install`, `inspect`, `run`,
  `swap`, `remove`, `web`) declared in
  `loadout/docs/architecture/LOD-01.md`.

What this means for Temper: Temper would invoke Loadout's CLI as the
product-experience layer and render its outputs. The minimal rendering
inputs are:

- the Goal title and `success_conditions` from
  `envelope.goal`;
- the Capability `id` and `contract_version` from
  `envelope.capability`;
- the `method_provenance` array that binds Capability to QMR
  fixture;
- the `scope.included` and `scope.excluded` lists and the
  `constraints.must` / `constraints.must_not` arrays;
- the `proof_obligations` array with `id` and `kind` per obligation;
- the `authority_requests` array, listed but never granted by
  Temper.

For results, Temper would render:

- `run_result.status` as `completed`, `blocked`, `cancelled`, `failed`,
  or `unknown` — never collapsed to `done`;
- `evidence[].kind` as `simulated` whenever the source is the fake
  Kiln boundary;
- `proof_obligations.satisfied` vs `unsatisfied` vs `invalidated`
  counts and identifiers;
- `acceptance_readiness.ready` and its `reasons` array;
- `unknowns` as a top-level field, not hidden in tooltips.

### Kiln — Evidence and acceptance readiness (gated)

Kiln's wave-2 P1-S02-T01 Artifact/Evidence substrate work lives on
branch `work/p1-s02-t01-artifact-evidence-substrate-v2` and is NOT yet
on `main`. The branch tip is `12d43e4` ("Drop K2 validator tests that
don't match the intentional struct design"). No PR #63 is open or merged
for this work as of 2026-08-12; the only PR #62 that integrated
mainline-related work is the P0-W45 Arsenal-pin update. This is a
critical dependency.

If and when the T01 branch lands, Kiln would expose:

- `lib/kiln/evidence.ex` and `lib/kiln/evidence/record_request.ex`
  for immutable Evidence records with full validation.
- `lib/kiln/evidence/store.ex` for append-only storage with
  idempotency and admission control.
- `lib/kiln/evidence/currentness.ex` for Layer 3 freshness,
  contradiction, and purity evaluation.
- `lib/kiln/evidence/view.ex` for the first-month conformance
  projection that maps Evidence to `proof_obligations` in a Run
  Result Envelope.
- `lib/kiln/artifact.ex`, `lib/kiln/artifact/store.ex`,
  `lib/kiln/artifact/fs.ex`, and `lib/kiln/artifact/put_request.ex`
  for the Artifact substrate that backs Evidence.
- `priv/store/migrations/0003_artifacts.sql` and
  `priv/store/migrations/0004_evidence_records.sql` for the schema
  migrations.

What this means for Temper, once the substrate is on `main`:

- Temper can render Evidence identifiers and freshness per
  `proof_obligations` entry.
- Temper can render contradiction and staleness warnings when
  `Evidence.Currentness` reports them.
- Temper can render Acceptance Readiness with `ready: false` and an
  explicit `reasons` list until every required obligation has current
  passing Evidence, per the Kiln completion rules in
  `kiln/AGENTS.md` (section "Evidence and completion rules").

What Temper would not do, even after T01 lands: simulate Kiln
authority, grant permission, apply a Patch, or declare completion.
Temper is read-only against Kiln.

## Integration boundaries

### What Temper reads

| Product | Read surface | Form | Notes |
|---|---|---|---|
| Arsenal | `evaluation/method-records/*.yaml` | File | Validated by `scripts/arsenal_method_record.py`. |
| Arsenal | `arsenal/capabilities/*.json` | File | Merged through `scripts/capability_audit.py`. |
| Arsenal | `arsenal/source-model.json` facts | File | Canonical ownership of `capability.current-lifecycle` and `capability.current-evaluation`. |
| Loadout | `npx loadout catalog` / `inspect` / `run` | CLI | Output is text and JSON; documented in `loadout/docs/architecture/LOD-01.md`. |
| Loadout | `fixtures/*.yaml` | File | v0 contract fixtures; Loadout is the producer. |
| Loadout | `.loadout/runs/<run-id>.json` | File | Run history written by `npx loadout run`. |
| Kiln | CLI structured output (planned) | CLI | Stable JSON projected from the first-month status view in `kiln/docs/CLI-TUI.md`. |
| Kiln | Evidence view (planned, gated on T01) | Structured JSON | Surface defined in `lib/kiln/evidence/view.ex`; not on `main` today. |

### What Temper does not do

- Own authority, capability, or method maturity. Those are
  Arsenal-owned.
- Own Goals, Capabilities, Packs, or the Result view. Those are
  Loadout-owned.
- Own execution, evidence, acceptance readiness, or state. Those are
  Kiln-owned.
- Perform model reasoning or synthesis of new evaluation. Temper
  reads; it does not write back into the three products.
- Persist any user repository state. The workspace boundary is
  set by `kiln/AGENTS.md` section "Local-first and security rules".
- Imply real Kiln enforcement when reading the Loadout simulated
  boundary. Every Evidence item from the Loadout fake boundary
  carries `kind: simulated`.
- Expose SQLite tables, internal process identifiers, provider
  handles, or protocol-specific internal objects
  (`kiln/docs/CLI-TUI.md` "Output modes" prohibition).

## Data Temper would need to surface

Each item below is grounded in an existing file or contract:

- **QMR identity.** `method_id` and `method_version`. Source:
  `engineering-system/contracts/qualified-method-record.v0.md`.
- **Method maturity.** `status` is `experimental` or `qualified`;
  `evaluation.confidence` is `bounded`, `limited`,
  `unqualified-fixture`, or `qualified-for-declared-context`. Source:
  same contract and
  `project-arsenal/evaluation/method-records/contract-map.md`.
- **Method negative knowledge.** `qualified_for.contexts` and
  `qualified_for.exclusions`, plus `evaluation.observed_failures`.
  Source: same contract.
- **Capability lifecycle and evaluation.** `capability.lifecycle`
  and `capability.evaluation.status` from the canonical capability
  fragment. Source: `project-arsenal/arsenal/CAPABILITY_CONTRACT.md`.
- **Plan digest.** `work_id` and `created_at` from a Work Envelope,
  plus `producer.product` and `producer.version`. Source:
  `engineering-system/contracts/work-envelope.v0.md`.
- **Capability contract version.** `capability.contract_version` on
  the Work Envelope. Source: same contract.
- **Proof obligations.** `id` and `kind` per obligation on the
  envelope, mapped against `proof_obligations.satisfied`,
  `unsatisfied`, and `invalidated` on the result envelope. Source:
  `engineering-system/contracts/run-result-envelope.v0.md`.
- **Authority requests.** `authority_requests[]` on the envelope,
  with `requested`, `granted`, and `denied` arrays on the result.
  Temper never grants; it shows what was requested and what the
  boundary returned. Source: same contracts.
- **Simulated vs real labels.** `evidence[].kind == simulated`
  whenever the source is the Loadout fake boundary. Real Evidence
  items come from Kiln with `lib/kiln/evidence` shape. Source:
  `loadout/src/core/fake-kiln-boundary.ts` and
  `kiln/lib/kiln/evidence.ex` (planned).
- **Acceptance readiness.** `acceptance_readiness.ready` and
  `reasons[]` on the result envelope, plus per-obligation Evidence
  status once Kiln's view projection is on `main`. Source:
  `engineering-system/contracts/run-result-envelope.v0.md` and
  `kiln/lib/kiln/evidence/view.ex` (planned).

## Honest state of dependencies

### Available now

- Arsenal `main` exposes the ARS-01 epistemic lifecycle, the
  experimental QMR for Repository Recon / Architecture Anchor, and
  the deterministic validator. PR #26 is merged. Source:
  `project-arsenal/docs/arsenal-lifecycle.md`,
  `project-arsenal/evaluation/method-records/*.yaml`,
  `project-arsenal/scripts/arsenal_method_record.py`.
- Loadout `main` exposes the LOD-01 vertical slice: the
  `repository-recon` Capability, the Work Envelope compile step, the
  deterministic fake Kiln boundary, and the Result view. PR #3 is
  merged. Source: `loadout/src/core/*`,
  `loadout/src/packs/repository-recon/*`,
  `loadout/docs/architecture/LOD-01.md`.
- The cross-product contracts (`qualified-method-record.v0`,
  `work-envelope.v0`, `run-result-envelope.v0`) are accepted in
  `engineering-system/contracts/` and consumed by the merged code
  above.

### Depends on outstanding work

- **Kiln P1-S02-T01 must land on `main`.** The Artifact/Evidence
  substrate lives on branch
  `work/p1-s02-t01-artifact-evidence-substrate-v2` only. Source:
  `kiln/AGENTS.md` "Current authorization boundary"; `kiln/.claude/`
  working notes (untracked). Until the branch merges, Temper cannot
  render real Evidence identifiers, freshness, or contradiction
  state — only the Loadout `simulated` markers.
- **Kiln CLI status projection must stabilize.** The first-month
  status view described in `kiln/docs/CLI-TUI.md` is the contract
  Temper would consume. The document is "Proposed P0-W18
  reconciliation; owner acceptance required" and is not implemented
  as a stable JSON surface today.
- **Kiln TUI entry conditions are unmet.** Per
  `kiln/docs/CLI-TUI.md` "TUI entry conditions", Kiln itself defers
  any TUI until P1-S01 through P1-S05 complete, durable projections
  and event ordering exist, and renderer failure isolation is
  testable. Temper does not bypass that gate.
- **Arsenal wave-2 evaluation promotion is not yet a wave-2 PR.**
  The Repository Recon QMR is `experimental`; no qualification
  receipt exists. Temper surfaces this honestly. Source:
  `project-arsenal/evaluation/method-records/contract-map.md`.
- **Loadout wave-2 second-pack or capability work** is not part of
  PR #3. The Capability contract version `0.1.0-fixture` and the
  single Goal catalogue entry are the only Capability and Goal
  available today. Source: `loadout/fixtures/*.yaml`,
  `loadout/src/core/goal.ts`.

## Architectural ceiling

`kiln/docs/CLI-TUI.md` "Renderer boundary" defines the contract any
later interface must honor:

```text
native application commands and projections
→ Kiln-owned view model
→ renderer behaviour
→ selected terminal library
```

Renderer types do not enter domain, persistence, Evidence, or public
command contracts. A renderer crash must not cancel or fail active
Runs.

For Temper, this translates to:

- Temper reads from Loadout and (eventually) Kiln through their CLI
  JSON outputs. It does not read SQLite directly.
- Temper holds no state that the three products consider canonical.
- A Temper crash cannot mutate Loadout state, Kiln state, or Arsenal
  assets. A Temper crash must leave the user's selected Run resumable
  through the product's own recovery path.

## What is deliberately not documented here

- A specific terminal rendering library. `kiln/docs/CLI-TUI.md`
  explicitly notes that `ExRatatui` is a research candidate and P0-W12
  is not binding for the deferred TUI slice.
- A concrete UI layout, keybinding set, or screen flow. These are
  not grounded in any of the four repositories and would be premature
  design.
- Any capability beyond Repository Recon that Loadout might
  eventually expose. The wave-2 slice proves one Capability; this
  document does not extrapolate beyond it.
- Any Kiln authority model, Patch lifecycle, or Command lifecycle
  beyond what `kiln/docs/CLI-TUI.md` and `kiln/AGENTS.md` already
  describe. Those documents are the source of truth; Temper is a
  consumer.
- Any Marketplace, billing, organization plane, or remote
  multi-tenant feature. The Loadout product boundary
  (`loadout/docs/PRODUCT-BOUNDARY.md`) excludes them and Loadout's
  own non-goals list them; Temper has no opinion.
- Any synchronization, cache layer, or shared state between Arsenal,
  Loadout, and Kiln. The engineering-system decision explicitly
  keeps the three products independently versioned; Temper respects
  that.

## File sources referenced

The following files were inspected in read-only mode to ground every
claim above. Each is cited in the relevant section.

- `engineering-system/decisions/0001-product-system.md`
- `engineering-system/contracts/qualified-method-record.v0.md`
- `engineering-system/contracts/work-envelope.v0.md`
- `engineering-system/contracts/run-result-envelope.v0.md`
- `engineering-system/program/launch/LAUNCH-MANIFEST.yaml`
- `project-arsenal/README.md`
- `project-arsenal/AGENTS.md`
- `project-arsenal/arsenal/CAPABILITY_CONTRACT.md`
- `project-arsenal/docs/arsenal-lifecycle.md`
- `project-arsenal/evaluation/method-records/contract-map.md`
- `project-arsenal/evaluation/method-records/repository-recon.architecture-anchor.v0.yaml`
- `project-arsenal/scripts/arsenal_method_record.py` (existence and
  validator role; not transcribed)
- `loadout/README.md`
- `loadout/docs/PRODUCT-BOUNDARY.md`
- `loadout/docs/PRODUCT-OBJECTS.md`
- `loadout/docs/architecture/LOD-01.md`
- `loadout/fixtures/qualified-method-record.v0.yaml`
- `loadout/fixtures/qualified-method-record.v0.alt.yaml`
- `loadout/fixtures/work-envelope.v0.yaml`
- `loadout/fixtures/run-result-envelope.v0.yaml`
- `loadout/src/core/fake-kiln-boundary.ts` (existence and boundary
  contract; not transcribed)
- `kiln/README.md`
- `kiln/CLAUDE.md`
- `kiln/AGENTS.md`
- `kiln/docs/CLI-TUI.md`

## Closing note

Temper is implementable in principle against the current `main` of
Arsenal and Loadout, and explicitly gated on Kiln's P1-S02-T01
substrate landing on `main` and on Kiln's first-month CLI status
projection stabilizing. A reader of this document should be able to
make a funding decision based on whether that gating is acceptable
and whether the data listed in "Data Temper would need to surface" is
the right minimum set for a terminal user.