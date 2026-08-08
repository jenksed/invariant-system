# Floci Suite Roadmap

Status: draft

This roadmap sequences Project Arsenal's Floci support from foundation to a mature local-cloud engineering suite.

The slices are intentionally tracer-bullet oriented. Each one should leave behind a usable vertical capability and evidence before broadening scope.

## FLC-00 — Local Cloud foundation and Floci contract

**Goal:** establish the durable reasoning/evidence model before building installers or a large prompt suite.

Deliverables:

- emulator-neutral Local Cloud Emulation method;
- Cloud Execution Boundary;
- Cloud Fidelity Ledger;
- Reproducible Cloud Fixtures method;
- Floci source audit;
- Floci Development Pack contract/reference;
- Floci fidelity and verification policies;
- registry/catalog integration;
- this implementation roadmap.

Exit criteria:

- foundations do not depend on Floci-specific commands;
- the Floci pack composes the universal Development Pack contract;
- local evidence cannot be confused with real-provider verification;
- operation-level fidelity is the durable unit, not service-count marketing;
- FLC-01 has a concrete tracer path.

## FLC-01 — AWS golden path

**Goal:** make one normal AWS-backed feature deliverable end to end through Floci with deterministic evidence.

Recommended tracer path:

`S3 object → SQS event/work item → Lambda or application consumer → observable result`

The exact first fixture may be adjusted after repository-level validation, but it should exercise both simple modeled services and at least one container/execution boundary if practical.

Deliverables:

- `adopt_floci_in_repo` workflow/prompt;
- repository environment discovery rules;
- safe AWS endpoint wrapper/profile;
- version-pinned Docker Compose template;
- native/compat image choice rule;
- deterministic `ready` wait command/script;
- source-controlled seed fixture;
- reset/cleanup command;
- inner/slice/completion gate scripts or templates;
- AWS fidelity-ledger template populated for the tracer path;
- evidence receipt template exercised on the tracer path;
- CI-ready ephemeral profile.

Acceptance examples:

- a fresh repository can install the pack without overwriting equivalent existing tooling;
- local SDK/CLI calls fail closed when the expected Floci endpoint is absent;
- clean-state replay produces the same asserted result;
- exact Floci version/digest is captured at the completion gate;
- unsupported semantics are visible in the ledger.

## FLC-02 — IaC and CI

**Goal:** turn Floci into a repeatable infrastructure preflight and isolated CI cloud.

Deliverables:

- Terraform/OpenTofu detection and endpoint adaptation;
- CloudFormation local path where supported;
- `validate_iac_with_floci` workflow;
- ephemeral per-job CI template;
- init-hook/fixture conventions for CI;
- snapshot acceleration policy + implementation example;
- artifact/evidence collection from failed CI runs;
- clean teardown including Floci-managed volumes/containers when relevant.

Acceptance examples:

- a supported IaC fixture can provision from zero in CI;
- the gate asserts post-provision state, not merely `apply` exit zero;
- the fidelity receipt names provider-only checks that IaC emulation cannot prove;
- parallel CI jobs do not share state.

## FLC-03 — Migration, reproduction, and diagnosis

**Goal:** make Floci useful for existing systems and incident/bug investigation, not only greenfield development.

Deliverables:

- `migrate_localstack_to_floci` workflow;
- LocalStack configuration inventory and compatibility mapping;
- init-script migration/compat strategy;
- `reproduce_cloud_bug_locally` workflow;
- `diagnose_floci_environment` workflow;
- fidelity-gap audit workflow;
- state capture/minimization pattern for cloud bug reproduction;
- inspection/logging evidence guidance;
- migration acceptance matrix that checks behavior after image/config changes.

Acceptance examples:

- migration never reduces to blind image-name replacement;
- LocalStack-specific environment/config assumptions are enumerated;
- unsupported differences become explicit migration blockers or redesign decisions;
- a remote symptom can be reduced to a versioned local fixture when Floci supports the relevant path.

## FLC-04 — Multi-cloud overlays

**Goal:** prove that the foundation is genuinely provider-neutral.

Order:

1. Azure
2. GCP
3. OCI

The order may change with real project demand.

For each provider, add:

- endpoint/credential environment contract;
- environment discovery;
- provider-specific fixture conventions;
- health/readiness integration;
- service/operation fidelity source strategy;
- one golden-path integration scenario;
- IaC/client compatibility guidance where supported;
- completion receipt examples.

Acceptance criteria:

- no AWS-only concept is required by the universal Local Cloud foundations;
- provider overlays can share verification/evidence machinery without pretending service semantics are identical;
- the local-cloud router can choose the correct provider pack from repository/task evidence.

## FLC-05 — Capability routing and composed delivery

**Goal:** make Local Cloud Engineering naturally composable with the rest of Project Arsenal.

Deliverables:

- `agent_workflows/local_cloud_router.md`;
- `workflows/floci_first_cloud_feature_delivery.md`;
- integration with repository-truth audit, TDD, diagnosis, tracer tickets, code review, independent verification, and handoff;
- routing rules for emulator vs real-cloud escalation;
- lifecycle/evaluation cases for the Floci capabilities.

Candidate route:

```text
repository truth
→ detect cloud dependency
→ resolve provider + operation fidelity
→ configure local execution boundary
→ fixture + implementation/TDD
→ slice gate
→ independent verification
→ provider-only escalation if required
→ evidence handoff
```

## FLC-06 — Evaluation and stabilization

**Goal:** earn `testing` and eventually `stable` lifecycle claims with evidence.

Evaluation matrix should include:

- green-path AWS feature delivery;
- unsupported operation discovered before implementation;
- documented semantic gap (for example an IAM/STS limitation);
- dirty persistent-state false positive caught by clean replay;
- endpoint variable missing and public-cloud fallback prevented;
- LocalStack migration with a compatibility difference;
- IaC apply that succeeds locally but leaves a provider-only acceptance claim;
- snapshot invalidated by emulator version change;
- multi-cloud routing case;
- agent attempt to request real credentials when local execution is sufficient.

Promotion requires repeated success across representative harness/model combinations and deterministic audit evidence where applicable.

## What not to build prematurely

Do not start with:

- copied static service matrices;
- dozens of one-off service prompts;
- a new task runner solely for Floci if repository conventions already provide one;
- a universal cloud abstraction that erases provider semantics;
- automatic real-cloud fallback;
- production deployment automation as part of the local-cloud pack;
- claims that every Floci-supported operation has provider-perfect behavior.

## Immediate next slice

After FLC-00 is accepted, authorize **FLC-01 — AWS golden path**.

The first implementation should be narrow enough to finish and verify as one coherent slice, but rich enough to exercise endpoint safety, clean fixtures, readiness, operation-level fidelity, state assertions, and a completion receipt.

## Program completion criterion

The Floci suite is mature when Project Arsenal can route a cloud-dependent engineering task into a safe local execution loop, reproduce the required state, exercise real-shaped provider interfaces, interpret the evidence at the correct fidelity level, and escalate only the irreducible provider-specific proof—without relying on model memory or broad cloud credentials.