# FLC-05 Capability Routing Evaluation

Status: draft  
Slice: FLC-05

This directory turns capability composition into an inspectable regression surface.

FLC-05 does not evaluate natural-language intelligence with a brittle keyword classifier. The model/human resolves the **work kind** from the request; deterministic routing then proves three things independently:

1. repository evidence resolves to exactly one cloud provider or hard-stops;
2. the explicit work kind maps to the intended existing Arsenal capability;
3. that capability is actually implemented for the resolved provider.

## Assets under test

- `agent_workflows/local_cloud_router.md`
- `workflows/floci_first_cloud_feature_delivery.md`
- `engineering/development_packs/floci/providers/scripts/resolve-provider`
- `engineering/development_packs/floci/providers/scripts/route-local-cloud-capability.py`
- `flc05_cases.json`
- `verify_flc05_routing.py`

## Work-kind routes and current provider coverage

| Work kind | Current routed provider coverage |
|---|---|
| feature | AWS, Azure, GCP, OCI |
| IaC validation | AWS only |
| LocalStack migration | AWS only |
| cloud bug reproduction | AWS, Azure, GCP, OCI |
| Floci environment diagnosis | AWS, Azure, GCP, OCI |
| fidelity-gap analysis | AWS, Azure, GCP, OCI |
| cloud-aware code review | AWS, Azure, GCP, OCI |
| provider-only proof | AWS, Azure, GCP, OCI, always as escalation review |

Provider resolution and capability availability are separate facts. Resolving Azure successfully does not imply the AWS-only FLC-02 IaC preflight can validate Azure IaC.

Unsupported provider/work-kind pairs return `UNSUPPORTED_ROUTE` with exit code `5`, the candidate capability, the currently supported providers, and `execution_boundary=local-capability-gap`. They do not fall through to a public provider.

## Invariants

A green evaluation must prove:

- every routed primary/support asset exists;
- all four providers can reach the composed feature-delivery workflow;
- specialized work kinds route to the already-existing narrow Arsenal capability;
- AWS-only IaC and LocalStack migration routes reject non-AWS providers;
- ambiguous provider evidence exits `3`;
- unknown provider evidence exits `4`;
- unsupported provider/capability combinations exit `5`;
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

The receipt records case IDs, expected/actual route fields, pass/fail status, unsupported-route count, and the global no-fallback invariant.

## What this evidence proves

A pass establishes that Arsenal can deterministically compose the already-defined Local Cloud and engineering capabilities **after** provider/work-kind intent is grounded, while refusing combinations for which the provider-specific capability does not yet exist.

It does not prove that a model will always classify an arbitrary natural-language request correctly. That higher-level routing quality belongs in FLC-06 evaluation across representative harness/model combinations.

It also does not authorize or validate real-provider mutation. Provider-only execution remains a separate Cloud Execution Boundary decision.
