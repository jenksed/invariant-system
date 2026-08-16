# Floci Suite Roadmap

Status: delivered tracer program; ongoing Development Pack

Program owner: [`docs/roadmap/capability-system.md`](../../../docs/roadmap/capability-system.md)

The Floci program established Project Arsenal's Local Cloud engineering model through six implemented slices, FLC-00 through FLC-05.

This document is now a **pack-level roadmap/history**, not the canonical Project Arsenal frontier. Project-wide sequencing lives in the capability-system roadmap.

The former **FLC-06 — Evaluation and stabilization** is absorbed into **ARS-02 — Arsenal Bench & Evaluation Lab v0**. Floci supplies the first substantial execution-backed evaluation corpus for the general Arsenal evaluation system rather than growing a separate benchmark/lifecycle platform.

## Program thesis

Use Floci aggressively for safe, reproducible local cloud evidence while never overstating what that evidence proves.

The durable Local Cloud rules are broader than Floci:

- choose the lowest-blast-radius execution surface capable of answering the question;
- fail closed against accidental public-cloud execution;
- build deterministic, replayable fixtures;
- classify evidence at provider → service → operation → required-semantic granularity;
- separate local protocol/behavior evidence from provider verification;
- preserve provider-only residue explicitly;
- require evidence before claiming completion.

## FLC-00 — Local Cloud foundation and Floci contract

**Status:** delivered.

**Goal:** establish the reasoning, execution-boundary, fidelity, fixture, and verification contracts before building broad Floci integrations.

Delivered:

- emulator-neutral Local Cloud Emulation method;
- Cloud Execution Boundary;
- Cloud Fidelity Ledger;
- Reproducible Cloud Fixtures method;
- Floci source audit;
- Floci Development Pack and compact reference;
- fidelity and verification policies;
- registry/catalog integration;
- tracer-oriented program roadmap.

Durable result:

> Local evidence cannot silently become provider evidence, and service-count compatibility is not a substitute for operation-level fidelity.

## FLC-01 — AWS golden path

**Status:** delivered; lifecycle remains evidence-gated.

**Tracer:**

```text
S3 input object
→ explicit SQS work item
→ Docker-backed Lambda through SQS event-source mapping
→ S3 result object
```

Delivered:

- `agent_workflows/adopt_floci_in_repo.md`;
- repository discovery and fail-closed endpoint rules;
- pinned Docker Compose reference runtime;
- deterministic init/seed/reset behavior;
- inner, slice, and completion gates;
- AWS operation-level fidelity ledger;
- completion receipt and provenance;
- clean-state replay;
- CI guard proving public AWS endpoints are refused.

Important boundary:

The tracer proves the exact local AWS-shaped operations it exercises. It does not establish IAM enforcement parity, quotas, regional behavior, AWS durability, billing, service timing, or undeclared provider semantics.

## FLC-02 — IaC and CI

**Status:** delivered; lifecycle remains evidence-gated.

Delivered:

- Terraform and OpenTofu detection/adaptation;
- CloudFormation local path where supported;
- `agent_workflows/validate_iac_with_floci.md`;
- zero-state provision/assert/destroy lifecycle;
- independent post-provision state assertions;
- isolated CI cloud runtimes;
- failure evidence and teardown;
- capability-gated snapshot acceleration policy;
- two-runtime isolation proof.

Important finding:

The released Floci AWS server observed during implementation did not implement the CLI-documented native snapshot route. Snapshot support therefore became an optional runtime-proven cache capability rather than completion authority.

Durable result:

> `apply` exit zero is not provisioning proof; direct state assertions and clean teardown remain authoritative.

## FLC-03 — Migration, reproduction, and diagnosis

**Status:** delivered; lifecycle remains evidence-gated.

Delivered:

- LocalStack-specific configuration inventory;
- blocker classification before runtime replacement;
- behavior-level LocalStack→Floci migration acceptance matrix;
- compatibility-first migration strategy;
- `agent_workflows/migrate_localstack_to_floci.md`;
- `agent_workflows/reproduce_cloud_bug_locally.md`;
- `agent_workflows/diagnose_floci_environment.md`;
- `agent_workflows/audit_floci_fidelity_gap.md`;
- state capture/minimization rules;
- red/green cloud-bug reproduction fixture;
- migration and reproduction evidence receipts;
- CI gates for inventory, migration, endpoint safety, and reproduction.

Important findings included:

- unsupported `LAMBDA_REMOTE_DOCKER` must block rather than degrade silently;
- persistent `/app/data` ownership matters under the non-root runtime;
- older botocore/SQS behavior can bypass a bare `AWS_ENDPOINT_URL`, making the shipped `awslocal` endpoint forcing significant;
- evidence-generation bugs can invalidate a receipt even when the underlying behavior is green;
- diagnostic tooling must not detect its own test fixtures as target-repository blockers.

Durable result:

> Migration correctness is behavioral equivalence within declared scope, not image-name similarity.

## FLC-04 — Multi-cloud overlays

**Status:** delivered; lifecycle remains evidence-gated.

**Goal:** prove the Local Cloud foundation is provider-neutral rather than AWS-shaped underneath.

Delivered provider overlays:

1. AWS — existing FLC-01/FLC-02/FLC-03 surface;
2. Azure — Blob + Queue tracer using Azure-shaped storage routing;
3. GCP — GCS + Pub/Sub tracer using project/emulator-host semantics;
4. OCI — Object Storage tracer using OCI-shaped service/tenancy/namespace semantics.

Delivered:

- provider-neutral overlay contract;
- provider-neutral receipt schema;
- deterministic four-provider resolver;
- provider-specific endpoint/identity/readiness contracts;
- separate provider fidelity ledgers;
- isolated multi-cloud CI;
- ambiguous/unknown provider hard stops.

Durable result:

> Shared lifecycle does not require fake provider symmetry. Arsenal may normalize start/guard/readiness/evidence/teardown while each provider keeps its own identity, endpoint, resource, and fidelity semantics.

## FLC-05 — Capability routing and composed delivery

**Status:** delivered; lifecycle remains evidence-gated.

**Goal:** make Local Cloud Engineering compose naturally with the rest of Project Arsenal.

Delivered:

- `agent_workflows/local_cloud_router.md`;
- `workflows/floci_first_cloud_feature_delivery.md`;
- deterministic provider + work-kind capability router;
- integration from the top-level Arsenal router and software feature-delivery workflow;
- provider-neutral cloud-bug reproduction and environment-diagnosis contracts;
- explicit provider/capability availability checks;
- provider-only `ESCALATION_REVIEW` instead of automatic real-cloud fallback;
- 18-case deterministic routing evaluation;
- exact-head regressions against the diagnostic and provider layers.

Delivered route:

```text
repository truth
→ detect cloud dependency
→ resolve provider
→ verify provider/capability availability
→ resolve operation fidelity
→ choose lowest-blast-radius execution boundary
→ fixture + implementation/TDD or diagnosis
→ slice gate
→ multi-axis review
→ independent verification
→ provider-only escalation review if required
→ evidence handoff
```

Current higher-level capability coverage is intentionally asymmetric:

| Work kind | Provider coverage |
|---|---|
| feature delivery | AWS, Azure, GCP, OCI |
| IaC validation | AWS only |
| LocalStack migration | AWS only |
| cloud-bug reproduction | AWS, Azure, GCP, OCI |
| Floci environment diagnosis | AWS, Azure, GCP, OCI |
| fidelity-gap analysis | AWS, Azure, GCP, OCI |
| cloud-aware review | AWS, Azure, GCP, OCI |
| provider-only proof | AWS, Azure, GCP, OCI — escalation review only |

Durable result:

> Provider resolution and capability availability are separate facts. A known provider with an unavailable specialization must stop explicitly rather than borrow another provider's implementation or fall through to real cloud.

## FLC-06 — Evaluation and stabilization

**Status:** absorbed into **ARS-02 — Arsenal Bench & Evaluation Lab v0**.

Do **not** build a separate Floci evaluation/lifecycle system.

The following cases are now the Local Cloud evaluation track inside Arsenal Bench:

- green-path cloud feature delivery;
- unsupported operation discovered before implementation;
- documented provider-semantic/fidelity gap;
- dirty persistent-state false positive caught by clean replay;
- missing endpoint/public-cloud fallback prevented;
- LocalStack migration compatibility difference;
- IaC apply succeeds locally while provider-only acceptance residue remains;
- snapshot invalidation after emulator/material-input changes;
- multi-cloud routing;
- resolved provider plus unsupported higher-level specialization;
- agent attempts to request real credentials when local execution is sufficient.

Evaluation should compare representative control/treatment runs and retain model, harness, tool, budget, repository-state, verifier, cost, and failure evidence under the general ARS-02 contract.

ARS-02 v0 has now executed the first five deterministic Local Cloud routing/boundary cases under Case Health and counterfactual receipts. Six deeper Local Cloud runtime/agent cases remain explicitly `designed-not-run`. That candidate evidence is sufficient for `capability.local-cloud-feature-delivery` to enter `testing`, but it does not establish model efficacy, real-provider semantics, or `stable` maturity.

Floci assets may earn `testing` or later `stable` only through the same lifecycle evidence rules as the rest of Arsenal.

## Future Floci work

Future Floci changes should be justified by one of four needs:

1. a missing Local Cloud capability required by real engineering work;
2. an Arsenal Bench fixture or adversarial evaluation scenario;
3. a provider/runtime compatibility update;
4. a Development Pack improvement required by the shared Capability, Evaluation, Execution, Evidence, or Trust contracts.

Do not resume sequential `FLC-07`, `FLC-08`, etc. merely to keep a Floci-specific program alive.

## What not to build prematurely

Do not build:

- copied static service matrices as authority;
- dozens of one-off service prompts;
- a Floci-only benchmark framework;
- a universal cloud abstraction that erases provider semantics;
- automatic real-cloud fallback;
- production deployment automation as part of the local-cloud pack;
- claims that every Floci-supported operation has provider-perfect behavior.

## Program completion criterion

The original Floci tracer program has reached its intended architectural destination through FLC-05: Project Arsenal can route cloud-dependent engineering work into a safe local loop, reproduce required state, exercise provider-shaped interfaces, interpret evidence at the correct fidelity level, compose with general engineering capabilities, and escalate only irreducible provider-specific proof.

The remaining question is no longer “what Floci slice comes next?”

It is:

> **Does this machinery measurably improve engineering work, and which parts have earned stronger lifecycle claims?**

That question belongs to [`ARS-02 — Arsenal Bench & Evaluation Lab v0`](../../../docs/roadmap/capability-system.md#ars-02--arsenal-bench--evaluation-lab-v0).