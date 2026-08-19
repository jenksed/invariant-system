# ARS-000: Arsenal Research Operating Contract

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft
Owner: ARS-00
Scope: Foundational operating contract for all Arsenal research experiments.

## Purpose

This contract defines how Arsenal produces evidence about agentic engineering methods. Every experiment record, negative-knowledge entry, and promotion packet authored under the Arsenal Research Program must conform to the invariants below. This contract does not grant filesystem, network, Git, or production authority, and it does not extend the closed protocol enums in `scripts/arsenal_protocol.py`.

## The Arsenal thesis

> Arsenal exists to determine which agentic engineering methods deserve to become infrastructure. It studies the conditions under which agents remain reliable, work remains independent, evidence remains trustworthy, repositories remain healthy, and humans can operate increasingly autonomous engineering systems without losing understanding or authority. Its output is not merely benchmarks. Arsenal produces raw evidence, derived evidence, negative knowledge, supported hypotheses, falsified hypotheses, qualified methods, rejected methods, promotion candidates, and the experimental basis for proposed changes across Kiln, Loadout, Manifold, Bench, and Temper. A method does not become Invariant doctrine because it is popular, intuitive, published, impressive in a demonstration, or successful once. Arsenal attempts to falsify it first.

## Lifecycle

The canonical research trajectory is:

```text
observation
  → hypothesis
  → experiment protocol
  → evidence
  → falsified / inconclusive / supported
  → replication where warranted
  → qualified method where warranted
  → promotion candidate
  → explicit external promotion decision
  → runtime adoption
```

Critical invariant: **SUPPORTED ≠ QUALIFIED ≠ PROMOTED**. A supported hypothesis is still pre-qualified. A qualified method is still pre-promotion. A promotion candidate is a proposal awaiting an external authority decision. "NO IMPROVEMENT — DO NOT PROMOTE" is a successful result when the evidence warrants it.

Arsenal never sets `PROMOTED` itself. `PROMOTED` is recorded only after an external authority decision in Kiln, Loadout, Manifold, or Temper.

## Source hierarchy

Evidence and claims must be traced to the strongest applicable source. When sources conflict, preserve the conflict rather than silently upgrade the weaker source.

1. **Executable repository / runtime evidence.** A reproducible run against a pinned repository/runtime identity, with fixture digests, harness identity, and raw evidence locations recorded. This is the strongest source for claims about behavior.
2. **Reproducible experiment evidence.** A documented experiment whose protocol, inputs, and outputs are inspectable and, where deterministic, produce a stable digest.
3. **Existing Invariant contracts and authoritative documentation.** `contracts/`, `products/arsenal/arsenal/*/CONTRACT.md`, capability fragments (`products/arsenal/arsenal/capabilities/*.json`), and accepted doctrine (`engineering/doctrine/`).
4. **Research papers / primary external technical sources.** Peer-reviewed papers, official specifications, and primary source code.
5. **Transcripts / talks / interviews / demonstrations / anecdotal reports.** A transcript claim is a hypothesis source, not evidence. It may motivate an experiment; it may not justify a conclusion.
6. **Inference.** Explicit reasoning from the above. Inference is the weakest source and must disclose its premises.

Never silently upgrade an observation or a transcript claim into doctrine. Preserve and investigate conflicts rather than averaging them away.

## Mandatory experiment record fields

Every experiment record must carry the following fields. Each field is defined in one line.

| Field | Definition |
|---|---|
| `experiment_id` | Stable identifier in the Arsenal experiment namespace (`ars-NNN`; see `evaluation/experiments/experiment-protocol.schema.json`). |
| `title` | Human-readable title summarizing the experiment. |
| `research_program` | Owning program (e.g. `arsenal-research-program`). |
| `source_observation` | The observation, transcript, contract gap, or prior result that motivated the experiment. |
| `research_question` | The precise question the experiment is designed to answer. |
| `hypothesis` | The falsifiable claim under test. |
| `falsifier` | An observable outcome that would falsify the hypothesis. |
| `system_under_test` | The method, capability, or behavior being studied. |
| `baseline_conditions` | The control or reference conditions against which the candidate is compared. |
| `candidate_conditions` | The treatment or changed conditions whose effect is being measured. |
| `controlled_variables` | Variables held constant to isolate the effect of interest. |
| `perturbations` | Deliberate variations introduced across repetitions, if any. |
| `fixture_identity` | Identity and digest of the fixture or starting state. |
| `task_identity` | Identity of the task or case exercised. |
| `model_identity` | Model identifier when a model is in the loop; `not-applicable` otherwise. |
| `harness_identity` | Harness or evaluator identifier and version/digest. |
| `runtime_identity` | Runtime, substrate, or execution environment identity. |
| `repository_identity` | Repository SHA(s) or exact state identifier(s) relevant to reproducibility. |
| `primary_metrics` | Metrics that decide the falsifier. |
| `secondary_metrics` | Additional metrics recorded for context but not used to decide the falsifier. |
| `repetition_policy` | How many repetitions, under what conditions, and whether they are independent or dependent. |
| `seed_policy_if_relevant` | How seeds are set, recorded, and varied for non-deterministic runs. |
| `stop_conditions` | Criteria that terminate data collection before or after the planned repetitions. |
| `protocol_version` | Version of the experiment protocol. Changes require a new version. |
| `protocol_frozen_at` | Timestamp or commit at which the protocol entered `RUNNING` and was frozen. |
| `raw_evidence_locations` | Paths, URIs, or content identifiers to the raw evidence. |
| `derived_evidence_locations` | Paths to derived metrics and the scripts that produced them. |
| `result` | Outcome class: `falsified`, `inconclusive`, `supported`, or terminal negative state. |
| `limitations` | Honest limitations that bound what the result can claim. |
| `counterevidence` | Observations that challenge the hypothesis or the interpretation of the result. |
| `negative_findings` | Findings that belong in the Negative Knowledge Catalog. |
| `possible_promotion_targets` | Kiln, Loadout, Manifold, Bench, or Temper surfaces the result might inform, if any. |
| `qualification_status` | Experiment-artifact state mapped to the epistemic chain (see below). |
| `promotion_status` | `not-proposed`, `promotion-candidate`, `promoted`, or `rejected`. `promoted` is recorded only from an external authority decision; Arsenal never sets it. |

## Experiment state vocabulary

The following states describe an experiment artifact. They are **not** an extension of the closed `LIFECYCLE_STATES` and `EVALUATION_STATES` enums in `scripts/arsenal_protocol.py`; they are the experiment-artifact vocabulary, a distinct artifact class.

| State | Definition | Allowed transitions |
|---|---|---|
| `IDEA` | A concept or observation exists; no protocol. | `DESIGNED`, `REJECTED` |
| `DESIGNED` | Protocol drafted but not yet complete or reviewed. | `READY`, `REJECTED` |
| `READY` | Protocol complete, fixtures and identities recorded, readiness gate satisfied; no evidence accumulated. | `RUNNING`, `REJECTED` |
| `RUNNING` | Evidence accumulation has begun; protocol is frozen. | `INCONCLUSIVE`, `FALSIFIED`, `SUPPORTED`, `REJECTED` |
| `INCONCLUSIVE` | Evidence does not falsify or support the hypothesis. | `RUNNING` (new protocol version), `REJECTED` |
| `FALSIFIED` | The falsifier was observed; hypothesis is rejected. | `REJECTED` (terminal) |
| `SUPPORTED` | Evidence supports the hypothesis but has not been replicated. | `REPLICATED`, `REJECTED` |
| `REPLICATED` | The supported result has been independently replicated or reproduced. | `QUALIFIED`, `REJECTED` |
| `QUALIFIED` | The method satisfies the QMR gate for a declared context. | `PROMOTION_CANDIDATE`, `REJECTED` |
| `PROMOTION_CANDIDATE` | A promotion packet has been authored and awaits external decision. | `PROMOTED`, `REJECTED`, `QUALIFIED` (if withdrawn) |
| `PROMOTED` | Recorded only after an external authority decision. This is not an Arsenal-owned state. | (recorded for traceability only) |
| `REJECTED` | Terminal negative state; may occur at any stage. | (terminal) |

### Mapping onto the canonical epistemic chain

| Experiment state | Epistemic chain stage | Existing lifecycle / evaluation projection |
|---|---|---|
| `IDEA` | Idea | `draft` / `unassessed` |
| `DESIGNED`, `READY` | Hypothesis | `draft` / `planned` |
| `RUNNING`, `INCONCLUSIVE`, `FALSIFIED` | Experimental (terminal-negative for `FALSIFIED`) | `testing` / `candidate` |
| `SUPPORTED`, `REPLICATED` | Replicated/Evaluated | `testing` / `candidate` |
| `QUALIFIED` | Qualified | `stable` / `qualified` |
| `PROMOTION_CANDIDATE` | Qualified (pre-external-decision) | `stable` / `qualified` |
| `PROMOTED` | External adoption | (recorded for traceability only; not Arsenal-owned) |
| `REJECTED` | Terminal negative | may transition to `deprecated` by external owners |

This mapping is a projection, not a new state machine. The canonical capability lifecycle and evaluation status remain owned by the capability fragment and qualification receipts as described in `products/arsenal/docs/arsenal-lifecycle.md`.

## Protocol freezing

Once an experiment enters `RUNNING`, its protocol is frozen and `protocol_frozen_at` is set. Any design change after evidence accumulation begins requires a new `protocol_version`. The prior version and the reason for the change must be preserved. Two runs whose `protocol_version` and `protocol_frozen_at` differ are different experiments for digest and interpretation purposes.

## Readiness gate

An experiment may enter `RUNNING` only when all of the following are satisfied:

- The protocol is complete per the mandatory field list above.
- `fixture_identity` is recorded with a digest where applicable.
- `harness_identity` is recorded.
- Harness determinism is demonstrated where the harness is deterministic: two runs against the same fixture produce identical run digests.
- Primary and secondary metrics are operationally defined.
- `stop_conditions` are declared.
- The `falsifier` is stated as an observable outcome.
- The provenance block records `arsenal_commit`, `harness`, `model`, `adapter`, and `remote_credentials_used: false`.

## Evidence discipline

The following rules are mandatory for every experiment:

- Never manufacture evidence.
- Never convert a missing measurement into an estimate labeled `measured`.
- Never convert an anecdote into a result.
- Never convert a single successful run into a generalized conclusion.
- Never discard failed runs because they are inconvenient.
- Negative results belong in the Negative Knowledge Catalog.
- Preserve raw evidence whenever practical.
- Derived metrics must be reproducible from raw evidence.
- Prefer scripts over hand-calculated results.

Missing measurements are recorded as `not-observed`, matching the Bench metrics vocabulary (`products/arsenal/evaluation/BENCH_CONTRACT.md`). They are not converted into zeroes, estimates, or silent omissions.

## Model / harness discipline

- Record `model_identity`, `harness_identity`, `runtime_identity`, and `repository_identity` with SHAs or digests whenever reproducibility could be affected.
- A model's output is never itself experimental evidence merely because the model produced it. Model output is evidence only when grounded in inspectable artifacts, measurements, or deterministic transformations.
- Implementers never grade their own experimental success.
- Reviewer output is analysis unless grounded in inspectable evidence.
- `remote_credentials_used` is always `false` for Arsenal research artifacts.

## Relationship to existing Arsenal surfaces

- Experiments reference Bench cases and receipts where applicable (`products/arsenal/evaluation/BENCH_CONTRACT.md`, `products/arsenal/evaluation/evaluation-case.schema.json`, `products/arsenal/evaluation/evaluation-receipt.schema.json`).
- Qualification of a method still requires the QMR path (`engineering-system/qualified-method-record/v0`). Experiments feed evidence into QMR evaluation; they do not replace the QMR.
- Promotion packets (`products/arsenal/evaluation/promotion/PACKET-TEMPLATE.md`) are the only channel toward runtime change.
- The Knowledge Plane (`products/arsenal/arsenal/knowledge/CONTRACT.md`) may ingest experiment records as typed `Experiment`, `NegativeKnowledge`, and `ReconsiderationTrigger` entities, but ingestion is read-only and does not create authority.
- Learning observations (`contracts/learning-observation.v0.md`) may motivate experiments but are not themselves experiment results.
