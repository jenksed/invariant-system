# Floci-First Cloud Feature Delivery

Use this composed workflow for a **cloud-dependent software feature or fix** that should move from uncertain repository state to independently verified evidence with the lowest practical blast radius.

This workflow specializes `workflows/software_feature_delivery.md`. It sequences existing Arsenal capabilities around the Local Cloud execution and fidelity boundary rather than replacing them.

## Core promise

A cloud-backed feature is not complete because unit tests pass while the provider boundary is mocked, Floci accepts API calls, IaC exits zero, an emulator looks similar to production, or an agent says the feature is done.

Completion means requested behavior is implemented, the strongest safe local evidence has been collected, claims are bounded to exact semantics exercised, independent verification supports them, and irreducible provider-only proof is explicit.

## Phase 0 — Establish repository truth

Delegate to `agent_workflows/repository_truth_audit.md` whenever branch, status, existing tooling, prior implementation, or completion claims are uncertain. Recover governing instructions, branch/base/diff, test/task-runner conventions, existing emulator tooling, provider SDK/IaC surfaces, acceptance criteria, and dirty/unrelated state.

Do not install a second emulator path merely because Floci is available.

## Phase 1 — Resolve provider, capability support, and operation scope

Delegate to `agent_workflows/local_cloud_router.md`, which uses `agent_workflows/route_local_cloud_provider.md`.

Before implementation, require both:

1. exactly one provider resolved;
2. the requested specialization is actually supported for that provider.

`UNSUPPORTED_ROUTE` is a hard capability boundary, not permission to borrow an AWS-specific workflow for another cloud.

Record an operation contract:

| Field | Required |
|---|---|
| provider | AWS / Azure / GCP / OCI |
| overlay | provider-owned Floci pack |
| service | exact provider service |
| operation | exact API/behavior exercised |
| semantic required | what must actually be true |
| local evidence level | protocol / behavior / fidelity-scoped |
| provider-only residue | what Floci cannot prove |

## Phase 2 — Select the execution boundary

Apply `foundations/cloud_execution_boundary.md`.

Prefer the lowest boundary that answers the acceptance question: pure local deterministic test → provider-shaped Floci path → local auxiliary runtime → explicitly authorized disposable provider → shared non-production → production only when separately authorized/unavoidable.

There is no automatic step from emulator to provider. A local failure is diagnostic evidence, not permission to use real credentials.

## Phase 3 — Shape the implementation frontier

When work is broader than one reliable context, delegate to `software_engineering/work_to_tracer_tickets.md`. Each tracer ticket carries one observable vertical behavior, provider/service/operation scope, acceptance criteria, local fixture, allowed fidelity claim, provider-only residue, blockers, and exclusions.

## Phase 4 — Build the red-capable seam

For new behavior, delegate to `software_engineering/tdd_vertical_slice.md`.

For a bug/regression whose cause is not established, delegate first to `software_engineering/diagnose_bug_feedback_loop.md` and preserve red evidence before fixing.

The preferred seam is the highest stable interface that observes real feature behavior while exercising the provider-shaped boundary required by acceptance. Mocks may isolate unrelated dependencies but cannot establish a semantic they remove.

## Phase 5 — Configure provider-local execution

Use the selected overlay:

- AWS → `engineering/development_packs/floci/aws/`
- Azure → `engineering/development_packs/floci/azure/`
- GCP → `engineering/development_packs/floci/gcp/`
- OCI → `engineering/development_packs/floci/oci/`

Preserve repository-native runners/conventions. Pin runtime, use synthetic identity, activate provider-specific endpoint guard, prove readiness, reconstruct fixture state, and prevent public-provider fallback.

## Phase 6 — Red → green vertical implementation

For each tracer slice: preserve expected red evidence; implement only enough; run targeted static/compile checks; run provider-local behavior; independently assert resulting state; classify evidence using the provider ledger; keep provider-only residue visible.

When a slice exposes environment or fidelity uncertainty, route to `agent_workflows/diagnose_floci_environment.md` or `agent_workflows/audit_floci_fidelity_gap.md` rather than changing application code speculatively.

## Phase 7 — Slice gate

Close a slice only when behavior is green at its public seam, endpoint safety is proven, fixture/state is reconstructable, postconditions are independently asserted, fidelity claims are recorded, provider-only residue is explicit, and no unrelated regression is known.

Use the provider pack's strongest applicable gate. For IaC-bearing slices, compose `agent_workflows/validate_iac_with_floci.md` **only when the router reports that IaC specialization is supported for the provider**. At FLC-05, the checked-in IaC validator is AWS-only.

## Phase 8 — Review on independent axes

Delegate to `software_engineering/code_review_multi_axis.md` for requirement/spec fidelity, engineering/design quality, and verification/evidence quality.

Specifically challenge accidental public-provider access, sensitive fixture data, emulator success overstated as provider verification, provider semantics erased by fake universal abstraction, unproven cleanup/isolation, unsupported provider/capability combinations, and omitted provider-only criteria.

## Phase 9 — Independent verification

Delegate to `agent_workflows/independent_verification_and_receipts.md`. Build a claim/evidence matrix separating behavior proven without cloud, behavior proven through Floci, emulator-fidelity assumptions, provider-only checks completed, provider-only checks still required, capability gaps, and skipped/unavailable evidence.

Self-reported implementation results are inputs, not the verdict.

## Phase 10 — Provider-only escalation, only if required

If an acceptance-critical semantic remains provider-only, return to `foundations/cloud_execution_boundary.md` and specify the smallest real-provider proof: provider/service/operation, unresolved semantic, disposable target, permission scope, expected mutation, cleanup, cost/data sensitivity, and closing evidence.

A missing local capability is not equivalent to a provider-only semantic. Do not execute real-provider mutation without explicit authorization.

After authorized provider proof, rerun independent verification.

## Phase 11 — Evidence handoff

Delegate to `agent_workflows/session_handoff_and_continuation.md`. Preserve repository/branch/revision, provider/overlay, capability support result, operation contract, tracer tickets, local commands/receipts, fidelity claims, provider-only residue, code-review findings, verification verdict, cleanup/state, and exact next action.

## Completion criterion

Stop when requested feature behavior is implemented, applicable local gates pass, independent verification supports the bounded completion claim, and every provider-only requirement is either proven with explicit authorization or clearly excluded/remaining.

The desired final statement is not "works on Floci."

> This revision implements the requested behavior; these exact provider operations and semantics were exercised through a fail-closed local boundary; these postconditions were independently verified; these claims remain emulator-scoped; and only this explicitly named provider-only residue remains.
