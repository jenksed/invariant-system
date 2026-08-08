# FLC-05 Capability Routing Evaluation

Status: draft  
Slice: FLC-05

This directory turns capability composition into an inspectable regression surface.

FLC-05 does not try to evaluate natural-language intelligence with a brittle keyword classifier. The model/human resolves the **work kind** from the request; deterministic routing then proves two things independently:

1. repository evidence resolves to exactly one cloud provider or hard-stops;
2. the explicit work kind maps to the intended existing Arsenal capability without granting real-cloud fallback.

## Assets under test

- `agent_workflows/local_cloud_router.md`
- `workflows/floci_first_cloud_feature_delivery.md`
- `engineering/development_packs/floci/providers/scripts/resolve-provider`
- `engineering/development_packs/floci/providers/scripts/route-local-cloud-capability.py`
- `flc05_cases.json`
- `verify_flc05_routing.py`

## Work-kind routes

The evaluation covers:

- feature delivery;
- IaC preflight;
- LocalStack migration;
- cloud bug reproduction;
- Floci environment diagnosis;
- fidelity-gap analysis;
- cloud-aware code review;
- provider-only escalation review.

Provider coverage includes AWS, Azure, GCP, and OCI plus ambiguous and unknown hard stops.

## Invariants

A green evaluation must prove:

- every routed primary/support asset exists;
- all four providers can reach the composed feature-delivery workflow;
- specialized work kinds route to the already-existing narrow Arsenal capability;
- ambiguous provider evidence exits `3`;
- unknown provider evidence exits `4`;
- explicit provider selection can resolve a repository with no provider evidence;
- provider-only proof returns `ESCALATION_REVIEW`;
- `automatic_real_cloud_fallback` is always false;
- explicit real-cloud authorization remains required;
- the composed delivery workflow names repository truth, provider routing, tracer tickets, TDD, diagnosis, review, independent verification, and handoff;
- no test requires real credentials or public provider mutation.

## Run

From the repository root:

```bash
python3 engineering/development_packs/floci/evaluation/verify_flc05_routing.py
```

The verifier writes:

`.floci-artifacts/flc05-routing-receipt.json`

The receipt records case IDs, expected/actual route fields, pass/fail status, and the global no-fallback invariant.

## What this evidence proves

A pass establishes that Arsenal can deterministically compose the already-defined Local Cloud and engineering capabilities **after** provider/work-kind intent is grounded.

It does not prove that a model will always classify an arbitrary natural-language request correctly. That higher-level routing quality belongs in FLC-06 evaluation across representative harness/model combinations.

It also does not authorize or validate real-provider mutation. Provider-only execution remains a separate Cloud Execution Boundary decision.
