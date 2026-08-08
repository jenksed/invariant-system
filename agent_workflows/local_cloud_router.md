# Local Cloud Engineering Router

Use this when an engineering task depends on AWS, Azure, GCP, or OCI and the correct Project Arsenal path is not yet obvious.

The router chooses the **smallest existing capability sequence that is actually implemented for the selected provider**. It is not a replacement for provider packs, software-engineering methods, or verification workflows.

## Outcome

Return one of:

- `ROUTED` — one provider and one supported primary Arsenal capability are selected;
- `AMBIGUOUS` — provider evidence conflicts;
- `UNKNOWN` — there is not enough grounded cloud intent to introduce Local Cloud tooling;
- `UNSUPPORTED_ROUTE` — the provider is known but the requested specialization is not implemented for it;
- `ESCALATION_REVIEW` — local evidence is insufficient for an acceptance-critical provider semantic and explicit real-provider authorization is required.

**Never default to AWS.** Never turn emulator or capability absence into automatic public-cloud fallback.

## Inputs

Recover these from the repository and request before asking the user:

- repository root and governing instructions;
- requested outcome;
- current-state claims;
- cloud provider evidence;
- exact service/operation surface when known;
- work kind;
- acceptance criteria and any explicit real-cloud authorization.

If repository state itself is uncertain, delegate first to `agent_workflows/repository_truth_audit.md`.

## Route in three dimensions

### 1. Resolve the provider

Delegate provider selection to `agent_workflows/route_local_cloud_provider.md` and, when available:

`engineering/development_packs/floci/providers/scripts/resolve-provider . --format json`

Provider ambiguity is a hard stop. Do not infer a provider from familiarity.

### 2. Resolve the work kind

Prefer explicit task intent:

| Work kind | Primary capability | Current provider coverage |
|---|---|---|
| feature | `workflows/floci_first_cloud_feature_delivery.md` | AWS, Azure, GCP, OCI |
| iac | `agent_workflows/validate_iac_with_floci.md` | AWS only |
| migration | `agent_workflows/migrate_localstack_to_floci.md` | AWS/LocalStack only |
| bug | `agent_workflows/reproduce_cloud_bug_locally.md` | AWS, Azure, GCP, OCI |
| environment | `agent_workflows/diagnose_floci_environment.md` | AWS, Azure, GCP, OCI |
| fidelity | `agent_workflows/audit_floci_fidelity_gap.md` | AWS, Azure, GCP, OCI |
| review | `software_engineering/code_review_multi_axis.md` | AWS, Azure, GCP, OCI |
| provider-proof | `foundations/cloud_execution_boundary.md` | all providers; escalation review only |

### 3. Verify provider/capability availability

Run:

`python3 engineering/development_packs/floci/providers/scripts/route-local-cloud-capability.py --repo . --task-kind <kind> --format json`

The machine router intentionally does **not** guess natural-language work kind. Human/model interpretation selects the kind; deterministic code verifies provider, provider support, and the canonical capability.

If the provider is resolved but the specialization is not implemented for that provider, return `UNSUPPORTED_ROUTE` / exit `5`. Record the candidate capability and supported-provider list, then stop. Do not reinterpret that gap as a provider-only semantic or permission to use real cloud.

## Composition rules

1. **Repository truth before mutation.** Do not plan from stale status text.
2. **Provider before provider-shaped execution.** Resolve exactly one cloud or stop.
3. **Capability availability before execution.** A provider overlay existing does not imply every higher-level workflow exists for that provider.
4. **Operation fidelity before claims.** Name service + operation + required semantic.
5. **Lowest blast radius first.** Use the lowest boundary that can answer the question.
6. **Reuse the narrow method.** Features use behavioral TDD; hard bugs use the red-capable diagnosis loop; broad implementation can use tracer tickets.
7. **Review and verification are separate.** Code review does not substitute for deterministic evidence.
8. **Handoff preserves residue.** Provider-only proof, skipped checks, capability gaps, and fidelity gaps survive into continuation.
9. **No automatic real-cloud fallback.** `provider-proof` means escalation review, not permission to obtain credentials or mutate a provider.

## Escalation decision

Escalate beyond Floci only when all are true:

- the exact acceptance claim cannot be established by a lower execution boundary;
- the missing semantic is identified at provider/service/operation granularity;
- local evidence already covers the reducible portion;
- the provider-only check is narrowly specified;
- blast radius, credentials, cost, cleanup, and data sensitivity are bounded;
- explicit authorization exists for the real-provider action.

A missing Arsenal specialization is **not** by itself evidence that real-provider execution is required.

Without explicit authorization, return `ESCALATION_REVIEW` and the exact provider-only proof that remains.

## Required handoff

Report:

- work kind;
- provider and evidence;
- selected provider overlay;
- capability support result;
- primary Arsenal capability or candidate capability;
- supporting capabilities;
- exact operations/fidelity scope;
- chosen execution boundary;
- local evidence available or required;
- provider-only residue;
- route status and next executable action.

## Stop conditions

Stop rather than guessing when:

- provider evidence is ambiguous or unknown;
- work kind is consequentially ambiguous;
- the provider/work-kind specialization is unsupported;
- the required local operation is unsupported and no redesign is authorized;
- a command would contact a public provider unexpectedly;
- provider-only semantics are acceptance-critical but real-provider execution is not explicitly authorized.
