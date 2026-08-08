# Floci-First Cloud Feature Delivery

Use this composed workflow for a **cloud-dependent software feature or fix** that should move from uncertain repository state to independently verified evidence with the lowest practical blast radius.

This workflow specializes `workflows/software_feature_delivery.md`. It does not replace its component capabilities; it sequences them around the Local Cloud execution and fidelity boundary.

## Core promise

A cloud-backed feature is not complete because:

- unit tests pass while the provider boundary is mocked;
- Floci accepts the API calls;
- IaC exits zero;
- a local emulator looks similar to production; or
- an agent says the feature is done.

Completion means the requested behavior is implemented, the strongest safe local evidence has been collected, claims are bounded to the exact semantics exercised, independent verification supports those claims, and any irreducible provider-only proof is explicit.

## Phase 0 — Establish repository truth

Delegate to `agent_workflows/repository_truth_audit.md` whenever branch, status, existing tooling, prior implementation, or completion claims are uncertain.

Recover:

- governing instructions;
- current branch/base and relevant diff;
- existing test/task-runner conventions;
- existing local cloud/emulator tooling;
- provider SDK/IaC surfaces;
- current acceptance criteria;
- dirty state and unrelated work.

Do not install a second emulator path merely because Floci is available.

## Phase 1 — Resolve provider and operation scope

Delegate to `agent_workflows/local_cloud_router.md`, which in turn uses `agent_workflows/route_local_cloud_provider.md`.

Record an operation contract before implementation:

| Field | Required |
|---|---|
| provider | AWS / Azure / GCP / OCI |
| overlay | provider-owned Floci pack |
| service | exact provider service |
| operation | exact API/behavior exercised |
| semantic required | what must actually be true |
| local evidence level | protocol / behavior / fidelity-scoped |
| provider-only residue | what Floci cannot prove |

If the provider is ambiguous or unknown, stop before provider-shaped mutation.

## Phase 2 — Select the execution boundary

Apply `foundations/cloud_execution_boundary.md`.

Prefer, in order, the lowest boundary that can answer the acceptance question:

1. pure deterministic/local test;
2. provider-shaped Floci emulator path;
3. local auxiliary container/runtime;
4. explicitly authorized disposable provider environment;
5. shared non-production provider;
6. production only when separately authorized and unavoidable.

There is no automatic step from 2 to 4. A local failure is diagnostic evidence, not permission to use real credentials.

## Phase 3 — Shape the implementation frontier

When the requested work is broader than one reliable context, delegate decomposition to `software_engineering/work_to_tracer_tickets.md`.

Each tracer ticket should carry:

- one observable vertical behavior;
- provider/service/operation scope;
- acceptance criteria;
- required local fixture;
- fidelity claim allowed if green;
- provider-only residue;
- blockers and exclusions.

Do not create horizontal tickets such as "finish all cloud infrastructure" when a vertical behavior can be proven independently.

## Phase 4 — Build the red-capable seam

For new behavior, delegate to `software_engineering/tdd_vertical_slice.md`.

For a bug/regression whose cause is not already established, delegate first to `software_engineering/diagnose_bug_feedback_loop.md` and preserve the red receipt before fixing.

The preferred seam is the highest stable interface that can observe the real feature behavior while still exercising the provider-shaped boundary needed by the acceptance criteria.

Mocks may isolate unrelated dependencies, but a test that mocks away the exact cloud semantic under review cannot establish that semantic.

## Phase 5 — Configure provider-local execution

Use the provider overlay selected by the router:

- AWS → `engineering/development_packs/floci/aws/`
- Azure → `engineering/development_packs/floci/azure/`
- GCP → `engineering/development_packs/floci/gcp/`
- OCI → `engineering/development_packs/floci/oci/`

Preserve repository-native task runners and conventions. Add only the smallest fixture/endpoints needed.

Before provider-shaped clients run:

- pin the emulator/runtime version;
- use synthetic local identity material;
- activate the provider-specific endpoint guard;
- prove readiness;
- make fixture state reconstructable;
- prevent public-cloud fallback.

## Phase 6 — Red → green vertical implementation

For each tracer slice:

1. run the behavioral seam and preserve expected red evidence;
2. implement only enough to satisfy the slice;
3. run targeted static/compile checks;
4. run the provider-local behavior;
5. assert resulting state independently rather than trusting command exit status;
6. classify the evidence using the provider fidelity ledger;
7. keep provider-only residue visible.

When the slice exposes environment or emulator uncertainty, route to `agent_workflows/diagnose_floci_environment.md` or `agent_workflows/audit_floci_fidelity_gap.md` instead of changing application code speculatively.

## Phase 7 — Slice gate

A slice may close only when:

- the intended behavior is green at its public seam;
- provider endpoint safety is proven;
- fixture/state is reconstructable;
- provider-shaped postconditions are independently asserted;
- exact local fidelity claims are recorded;
- provider-only residue is explicit;
- no unrelated regression is known.

Use the provider pack's strongest applicable gate. For IaC-bearing slices, also compose `agent_workflows/validate_iac_with_floci.md`.

## Phase 8 — Review on independent axes

Delegate branch/change review to `software_engineering/code_review_multi_axis.md`.

Review separately for:

1. requirement/spec fidelity;
2. engineering/design quality;
3. verification/evidence quality.

A reviewer should specifically challenge:

- accidental public-provider access;
- credentials or customer data in fixtures;
- emulator success overstated as provider verification;
- provider semantics erased behind a fake universal abstraction;
- unproven cleanup or state isolation;
- provider-only acceptance criteria omitted from the final claim.

## Phase 9 — Independent verification

Delegate to `agent_workflows/independent_verification_and_receipts.md`.

Build a claim-to-evidence matrix that distinguishes:

- behavior proven without cloud;
- behavior proven through Floci;
- emulator-fidelity assumptions;
- provider-only checks completed;
- provider-only checks still required;
- skipped/unavailable evidence.

Self-reported implementation results are inputs, not the verdict.

## Phase 10 — Provider-only escalation, only if required

If an acceptance-critical semantic remains provider-only, return to `foundations/cloud_execution_boundary.md`.

Specify the **smallest** real-provider proof:

- exact provider/service/operation;
- exact unresolved semantic;
- disposable target environment;
- credential and permission scope;
- expected mutation;
- cleanup;
- cost/data sensitivity;
- evidence that will close the claim.

Do not execute real-provider mutation without explicit authorization. Never broaden credentials merely because a lower-fidelity check was insufficient.

After authorized provider proof, rerun independent verification with the new evidence.

## Phase 11 — Evidence handoff

Delegate continuation/closeout to `agent_workflows/session_handoff_and_continuation.md`.

The handoff must preserve:

- repository/branch/revision;
- provider and overlay;
- operation contract;
- tracer tickets completed/remaining;
- local commands and receipts;
- exact fidelity claims earned;
- provider-only residue;
- code-review findings;
- independent-verification verdict;
- cleanup/state status;
- exact next action if anything remains.

## Completion criterion

Stop when the requested feature behavior is implemented, applicable local gates pass, independent verification supports the bounded completion claim, and every provider-only requirement is either proven with explicit authorization or clearly excluded/remaining.

The desired final statement is not "works on Floci."

It is:

> This revision implements the requested behavior; these exact provider operations and semantics were exercised through a fail-closed local boundary; these postconditions were independently verified; these claims remain emulator-scoped; and only this explicitly named provider-only residue remains.
