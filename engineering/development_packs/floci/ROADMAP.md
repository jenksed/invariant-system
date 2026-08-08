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

**Implementation status:** delivered by the runnable AWS reference pack under `engineering/development_packs/floci/aws/` and the `agent_workflows/adopt_floci_in_repo.md` workflow. Lifecycle status remains `draft` until the later evaluation/stabilization program earns a stronger claim.

Implemented tracer path:

`S3 input object → explicit SQS work item → Lambda SQS event-source mapping → S3 result object`

The first fixture intentionally exercises both modeled services and a Docker-backed execution boundary. The S3-to-SQS hop is explicit rather than claiming S3 notification semantics.

Delivered:

- `adopt_floci_in_repo` workflow;
- repository environment discovery rules;
- safe AWS endpoint wrapper/profile behavior;
- version-pinned Docker Compose template;
- native/compat image choice rule;
- deterministic `ready` wait command;
- source-controlled seed fixture;
- reset/reseed command;
- inner/slice/completion gate scripts;
- AWS fidelity ledger populated for the tracer path;
- evidence receipt schema and generated completion receipt;
- CI-ready ephemeral profile;
- CI guard that proves a public AWS endpoint is refused.

Acceptance evidence is produced by the FLC-01 completion gate and GitHub Actions workflow:

- the pack is inspect-first and does not authorize overwriting equivalent repository tooling;
- local AWS CLI calls fail closed when the endpoint is not the approved loopback Floci endpoint;
- clean-state replay asserts the same result content by bucket/key, byte count, and SHA-256;
- the completion receipt captures the pinned image tag, Floci-reported version, container image ID, and pulled repo digest when available;
- unsupported or partial semantics remain visible in the operation-level fidelity ledger.

## FLC-02 — IaC and CI

**Goal:** turn Floci into a repeatable infrastructure preflight and isolated CI cloud.

**Implementation status:** delivered by the runnable IaC pack under `engineering/development_packs/floci/aws/iac/` and `agent_workflows/validate_iac_with_floci.md`. Terraform, OpenTofu, CloudFormation, and two-runtime isolation are exercised in CI. Snapshot acceleration is capability-gated because the released AWS server observed during validation does not implement the CLI-documented snapshot route.

Delivered:

- Terraform/OpenTofu detection and endpoint adaptation;
- CloudFormation local path where supported;
- `validate_iac_with_floci` workflow;
- ephemeral per-job CI template;
- fixture conventions for CI;
- capability-gated snapshot acceleration policy;
- artifact/evidence collection from failed CI runs;
- clean teardown including Floci-managed state boundaries.

Acceptance evidence includes:

- supported IaC fixtures provision from zero in CI;
- post-provision state is asserted independently rather than trusting `apply` exit zero;
- the fidelity receipt names provider-only checks that IaC emulation cannot prove;
- parallel Floci runtimes do not share state;
- unsupported snapshot capability is explicit evidence and does not weaken the authoritative clean provision/assert/destroy lifecycle.

## FLC-03 — Migration, reproduction, and diagnosis

**Goal:** make Floci useful for existing systems and incident/bug investigation, not only greenfield development.

**Implementation status:** delivered on the FLC-03 reference branch by `engineering/development_packs/floci/aws/diagnostics/` plus four agent workflows. Lifecycle status remains `draft` until evaluation/stabilization earns stronger claims.

Delivered:

- `migrate_localstack_to_floci` workflow;
- deterministic LocalStack configuration inventory and compatibility classification;
- init-script migration/compat strategy;
- behavior-level migration acceptance matrix;
- `reproduce_cloud_bug_locally` workflow;
- `diagnose_floci_environment` workflow;
- operation-level fidelity-gap audit workflow;
- state capture/minimization pattern for cloud bug reproduction;
- inspection/logging evidence guidance;
- a LocalStack-shaped compatibility fixture that preserves supported compatibility surfaces;
- a deliberately blocked legacy fixture proving unsupported `LAMBDA_REMOTE_DOCKER` is caught before runtime replacement;
- a red/green SQS reproduction tracer with minimized synthetic state and evidence receipt;
- CI gates for inventory, migration compatibility, endpoint fail-closed behavior, and red/green reproduction.

Acceptance target:

- migration never reduces to blind image-name replacement;
- LocalStack-specific environment/config assumptions are enumerated;
- unsupported differences become explicit migration blockers or redesign decisions;
- a sanitized remote-style symptom can be reduced to a versioned local fixture when Floci supports the relevant operation path;
- the reproduction signal is red-capable and a nearby one-change control turns it green;
- local diagnosis classifies boundary, runtime, fixture, application, fidelity, provider-only, or unknown outcomes instead of guessing.

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

After FLC-03 is accepted, authorize **FLC-04 — Multi-cloud overlays**.

FLC-04 should use Azure as the first tracer unless real project demand changes the order. Its purpose is not merely to add another emulator: it must prove that the universal Local Cloud foundations, fidelity ledger, fixture discipline, and verification tiers do not secretly require AWS concepts.

## Program completion criterion

The Floci suite is mature when Project Arsenal can route a cloud-dependent engineering task into a safe local execution loop, reproduce the required state, exercise real-shaped provider interfaces, interpret the evidence at the correct fidelity level, and escalate only the irreducible provider-specific proof—without relying on model memory or broad cloud credentials.
