# Local Cloud Engineering Router

Use this when an engineering task depends on AWS, Azure, GCP, or OCI and the correct Project Arsenal path is not yet obvious.

The router's job is to choose the **smallest existing capability sequence** that can safely produce the required evidence. It is not a replacement for the provider packs, software-engineering methods, or verification workflows it delegates to.

## Outcome

Return one of:

- `ROUTED` — one provider and one primary Arsenal capability are selected;
- `AMBIGUOUS` — provider or work-kind evidence conflicts;
- `UNKNOWN` — there is not enough grounded cloud intent to introduce Local Cloud tooling;
- `ESCALATION_REVIEW` — local evidence is insufficient for an acceptance-critical provider semantic and explicit real-provider authorization is required.

Never default to AWS. Never turn emulator failure into automatic public-cloud fallback.

## Inputs

Recover these from the repository and request before asking the user:

- repository root and governing instructions;
- requested outcome;
- current-state claims;
- cloud provider evidence;
- exact service/operation surface when known;
- whether the task is feature delivery, IaC, migration, bug reproduction, environment diagnosis, fidelity analysis, review, or provider-only proof;
- acceptance criteria and any explicit real-cloud authorization.

If repository state itself is uncertain, delegate first to `agent_workflows/repository_truth_audit.md`.

## Route in two dimensions

### 1. Resolve the provider

Delegate provider selection to `agent_workflows/route_local_cloud_provider.md` and, when available, its deterministic resolver:

`engineering/development_packs/floci/providers/scripts/resolve-provider . --format json`

Provider ambiguity is a hard stop. Do not infer a provider from familiarity.

### 2. Resolve the work kind

Prefer explicit task intent. Use these routes:

| Work kind | Primary capability |
|---|---|
| feature | `workflows/floci_first_cloud_feature_delivery.md` |
| iac | `agent_workflows/validate_iac_with_floci.md` |
| migration | `agent_workflows/migrate_localstack_to_floci.md` |
| bug | `agent_workflows/reproduce_cloud_bug_locally.md` |
| environment | `agent_workflows/diagnose_floci_environment.md` |
| fidelity | `agent_workflows/audit_floci_fidelity_gap.md` |
| review | `software_engineering/code_review_multi_axis.md` |
| provider-proof | `foundations/cloud_execution_boundary.md` with explicit escalation review |

For machine-readable routing after the work kind is known:

`python3 engineering/development_packs/floci/providers/scripts/route-local-cloud-capability.py --repo . --task-kind <kind> --format json`

The machine router intentionally does **not** guess natural-language work kind. Human/model interpretation selects the kind; deterministic code verifies the provider and maps that kind to an existing capability.

## Composition rules

1. **Repository truth before mutation.** Do not plan from stale status text.
2. **Provider before provider-shaped execution.** Resolve exactly one cloud or stop.
3. **Operation fidelity before claims.** Name the service + operation + required semantic; do not promote broad emulator support into provider verification.
4. **Lowest blast radius first.** Pure local evidence outranks emulator only when it can answer the question; emulator outranks provider mutation when it can answer the question.
5. **Reuse the narrow method.** New feature behavior uses behavioral TDD; hard bugs use the red-capable diagnosis loop; broad implementation work can be decomposed with tracer tickets.
6. **Review and verification are separate.** Code review does not substitute for deterministic evidence or independent verification.
7. **Handoff preserves residue.** Provider-only proof, skipped checks, and unresolved fidelity gaps must survive into the continuation record.
8. **No automatic real-cloud fallback.** `provider-proof` means escalation review, not permission to obtain credentials or mutate a provider.

## Escalation decision

Escalate beyond Floci only when all are true:

- the exact acceptance claim cannot be established by a lower execution boundary;
- the missing semantic is identified at provider/service/operation granularity;
- local evidence already covers the reducible portion;
- the provider-only check is narrowly specified;
- blast radius, credentials, cost, cleanup, and data sensitivity are bounded;
- explicit authorization exists for the real-provider action.

Without explicit authorization, return `ESCALATION_REVIEW` and the exact provider-only proof that remains.

## Required handoff

Report:

- work kind;
- provider and evidence;
- selected provider overlay;
- primary Arsenal capability;
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
- the required local operation is unsupported and no redesign is authorized;
- a command would contact a public provider unexpectedly;
- provider-only semantics are acceptance-critical but real-provider execution is not explicitly authorized.
