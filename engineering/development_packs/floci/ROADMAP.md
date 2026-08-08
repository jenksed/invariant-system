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

**Implementation status:** delivered by `engineering/development_packs/floci/aws/diagnostics/` plus four agent workflows. Lifecycle status remains `draft` until evaluation/stabilization earns stronger claims.

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

Acceptance evidence includes:

- migration never reduces to blind image-name replacement;
- LocalStack-specific environment/config assumptions are enumerated;
- unsupported differences become explicit migration blockers or redesign decisions;
- a sanitized remote-style symptom can be reduced to a versioned local fixture when Floci supports the relevant operation path;
- the reproduction signal is red-capable and a nearby one-change control turns it green;
- local diagnosis classifies boundary, runtime, fixture, application, fidelity, provider-only, or unknown outcomes instead of guessing.

## FLC-04 — Multi-cloud overlays

**Goal:** prove that the foundation is genuinely provider-neutral.

**Implementation status:** delivered by the provider overlay contract/router and runnable Azure, GCP, and OCI reference packs. Lifecycle status remains `draft` until FLC-06 evaluation/stabilization earns stronger claims.

Delivered provider order and pins:

1. Azure — `floci/floci-az:0.10.0`, port `4577`;
2. GCP — `floci/floci-gcp:0.6.0`, port `4588`;
3. OCI — `floci/floci-oci:0.2.0`, port `4599`.

Delivered:

- provider-neutral overlay contract and common completion receipt schema;
- deterministic AWS/Azure/GCP/OCI router with explicit ambiguous/unknown stops;
- provider-specific fail-closed endpoint/credential environment contracts;
- provider-specific readiness, fixture, and fidelity conventions;
- Azure Blob + Queue golden path through official Azure Python SDKs;
- GCS + Pub/Sub golden path through official Google Cloud Python SDKs;
- OCI Object Storage golden path through OCI-shaped wire routes;
- independent operation-level fidelity ledgers and completion receipts;
- FLC-04 CI with one router gate plus isolated Azure/GCP/OCI runtime jobs;
- source audit capturing release pins, authentication limits, and cross-provider differences.

Acceptance evidence includes:

- the universal Local Cloud foundations require no AWS region/account/access-key concept;
- Azure uses storage-account connection routing, GCP uses project/emulator hosts, and OCI uses tenancy/namespace/service endpoint semantics without forced translation;
- all overlays share the same start → endpoint guard → readiness → inner → golden path → receipt → teardown lifecycle;
- the router selects all four provider packs from repository evidence and returns hard-stop codes for ambiguous or unknown intent;
- each local provider refuses a public endpoint before client execution;
- provider semantics and provider-only residue remain independent in their fidelity ledgers;
- OCI deliberately uses a different golden-path service graph, proving shared lifecycle does not require fake service symmetry.

## FLC-05 — Capability routing and composed delivery

**Goal:** make Local Cloud Engineering naturally composable with the rest of Project Arsenal.

**Implementation status:** delivered by the Local Cloud router, Floci-first cloud feature delivery workflow, deterministic provider/capability router, provider-neutral diagnosis/reproduction adaptations, and FLC-05 routing evaluation. Lifecycle status remains `draft` until FLC-06 evaluation/stabilization earns stronger claims.

Delivered:

- `agent_workflows/local_cloud_router.md` with `ROUTED`, `AMBIGUOUS`, `UNKNOWN`, `UNSUPPORTED_ROUTE`, and `ESCALATION_REVIEW` outcomes;
- `workflows/floci_first_cloud_feature_delivery.md` composing repository truth, provider routing, execution boundaries, tracer tickets, TDD/diagnosis, provider-local execution, slice gates, review, independent verification, escalation, and handoff;
- integration from `agent_workflows/arsenal_router.md` and `workflows/software_feature_delivery.md` into the Local Cloud specialization;
- deterministic `route-local-cloud-capability.py` that combines an explicitly interpreted work kind with FLC-04 provider resolution;
- provider/capability availability enforcement so a resolved cloud cannot borrow a specialization that only exists for another provider;
- provider-neutral adaptation of cloud-bug reproduction and environment diagnosis while retaining AWS-specific reference implementations where they are actually AWS-specific;
- explicit current support boundaries: feature delivery, bug reproduction, environment diagnosis, fidelity audit, review, and provider-proof routing across AWS/Azure/GCP/OCI; IaC validation and LocalStack migration remain AWS-only;
- provider-only proof routed to `ESCALATION_REVIEW` rather than automatic real-cloud execution;
- 18 deterministic routing/evaluation cases and CI evidence receipt;
- registry/catalog integration at 126 registered assets across 8 registry files.

Delivered route:

```text
repository truth
→ detect cloud dependency
→ resolve provider
→ verify provider/capability availability
→ resolve operation fidelity
→ configure lowest-blast-radius execution boundary
→ fixture + implementation/TDD or diagnosis
→ slice gate
→ multi-axis review
→ independent verification
→ provider-only escalation review if required
→ evidence handoff
```

Acceptance evidence includes:

- all four providers route normal feature delivery into the composed Floci-first workflow;
- GCP cloud-bug reproduction and Azure environment diagnosis route through provider-neutralized workflows rather than AWS-shaped assumptions;
- AWS IaC and LocalStack migration route to their existing specialized packs;
- non-AWS IaC and LocalStack-migration combinations return `UNSUPPORTED_ROUTE` / exit `5` instead of borrowing AWS-only machinery;
- ambiguous provider evidence returns exit `3` and unknown provider evidence exit `4`;
- explicit provider selection can resolve a repository with no provider fingerprint;
- provider-only proof returns `ESCALATION_REVIEW` and still requires explicit authorization;
- every route preserves `automatic_real_cloud_fallback=false`;
- routed capability paths are existence-checked and the composed workflow is checked for required delegation pointers;
- FLC-03 and FLC-04 regressions remain authoritative for the diagnostic and provider layers FLC-05 composes.

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
- resolved provider plus unsupported higher-level specialization stopped before execution;
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

After FLC-05 is accepted, authorize **FLC-06 — Evaluation and stabilization**.

FLC-06 should test the complete Local Cloud routing and evidence system against adversarial, unsupported, dirty-state, migration, provider-fidelity, multi-cloud, and credential-escalation cases across representative harness/model combinations, then promote only the assets that actually earn stronger lifecycle claims.

## Program completion criterion

The Floci suite is mature when Project Arsenal can route a cloud-dependent engineering task into a safe local execution loop, reproduce the required state, exercise real-shaped provider interfaces, interpret the evidence at the correct fidelity level, and escalate only the irreducible provider-specific proof—without relying on model memory or broad cloud credentials.
