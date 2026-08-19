# Arsenal Experiment Protocol Template

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


State: IDEA

Use this template to draft a protocol under `evaluation/experiments/<ars-NNN-short-name>/PROTOCOL.md`. Do not mutate a frozen protocol. When a protocol changes, increment `protocol_version` and create a new frozen artifact; the old version remains available.

## Readiness gate

Before this protocol may leave `IDEA` and enter `DESIGNED`, it must:

- state a falsifiable research question;
- define an observable falsifier, not a vibes statement;
- identify the system under test, baseline, candidate, and controlled variables;
- declare identity fields with paths or digests where known;
- specify primary metrics and stop conditions;
- be reviewed against `../../docs/arsenal-experiment-contract.md` (ARS-000).

Before it may leave `DESIGNED` and enter `READY`, the protocol must be frozen (`protocol_frozen_at` ISO-8601 timestamp) and registered in `evaluation/experiments/README.md`.

## experiment_id

`<placeholder>`

Stable identifier of the form `ars-NNN` matching the directory name and registry entry.

## title

`<placeholder>`

Short, specific title describing the claim under test.

## research_program

`<placeholder>`

Link to the owning research program artifact, e.g. `../../docs/arsenal-research-program.md`.

## source_observation

`<placeholder>`

The observation, anomaly, or registry entry (e.g. `research/REGISTRY.md#BR-NNN`) that motivated the experiment.

## research_question

`<placeholder>`

A single falsifiable question. It must be possible to answer no.

## hypothesis

`<placeholder>`

The candidate claim. Include scope and necessary assumptions.

## falsifier

`<placeholder>`

An observable outcome or measurement that, if observed, would falsify the hypothesis. Must be concrete, not a vibes statement such as "the model seems worse."

## system_under_test

`<placeholder>`

The component, method, prompt, workflow, or surface whose behavior is being measured.

## baseline_conditions

`<placeholder>`

The control condition against which the candidate is compared. Must be reproducible.

## candidate_conditions

`<placeholder>`

The treatment condition. Differences from baseline must be explicit and bounded.

## controlled_variables

`<placeholder>`

Variables held constant across arms. List as an array of strings or structured objects.

## perturbations

`<placeholder>`

Intentional variations applied to test robustness. List as an array.

## fixture_identity

`<placeholder>`

Path to the fixture and its digest in the form `sha256:<64-hex>`. If the fixture is not yet bound, state the expected path and `sha256:0000000000000000000000000000000000000000000000000000000000000000`.

## task_identity

`<placeholder>`

Task or case identifier and digest when available.

## model_identity

`<placeholder>`

Model identifier, version, and provider when known; otherwise `unknown`.

## harness_identity

`<placeholder>`

Harness or runner identity and version.

## runtime_identity

`<placeholder>`

Runtime or execution substrate identity and version.

## repository_identity

`<placeholder>`

Repository revision (SHA) or starting-state digest under test.

## primary_metrics

`<placeholder>`

Array of metrics that decide the hypothesis. No composite scores.

## secondary_metrics

`<placeholder>`

Array of supporting metrics.

## repetition_policy

`<placeholder>`

Number of repetitions, sampling strategy, and rationale.

## seed_policy_if_relevant

`<placeholder>`

Seed or randomization policy if the experiment is sensitive to it.

## stop_conditions

`<placeholder>`

Rules for terminating data collection. Include success, failure, and inconclusive thresholds.

## protocol_version

`<placeholder>`

Semantic version of this protocol, e.g. `0.1.0`.

## protocol_frozen_at

`<placeholder>`

ISO-8601 timestamp at which this version was frozen. Empty until frozen.

## raw_evidence_locations

`<placeholder>`

Array of paths to raw evidence artifacts with digests.

## derived_evidence_locations

`<placeholder>`

Array of paths to derived evidence artifacts (analysis, summaries, reproduction commands).

## result

`<placeholder>`

Final qualitative result. Allowed values: `INCONCLUSIVE`, `FALSIFIED`, `SUPPORTED`, `REPLICATED`, `QUALIFIED`, `REJECTED`, or left blank while running.

## limitations

`<placeholder>`

Array of known limitations that bound the claim scope.

## counterevidence

`<placeholder>`

Array of observations that contradict or weaken the hypothesis.

## negative_findings

`<placeholder>`

Array of negative results produced by the experiment. Negative knowledge is first-class; publish losses per `../BENCH_CONTRACT.md`.

## possible_promotion_targets

`<placeholder>`

Array of products, contracts, or capabilities that could be affected if the result is later promoted. Arsenal does not promote; it only records candidate targets.

## qualification_status

`<placeholder>`

One of `unassessed`, `experimental`, `qualified`. Default `unassessed`.

## promotion_status

`<placeholder>`

One of `not-proposed`, `promotion-candidate`, `promoted`, `rejected`. Default `not-proposed`. `promoted` is recorded only from an external promotion decision.
