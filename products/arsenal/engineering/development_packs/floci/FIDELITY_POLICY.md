# Floci Fidelity Policy

Status: draft

This policy defines how Project Arsenal interprets evidence produced by Floci.

## Policy

**Floci is trusted as an executable local implementation for the behavior it demonstrably supports, not as an unconditional proxy for AWS, Azure, GCP, or OCI truth.**

Every material cloud acceptance path should resolve fidelity at:

`provider + service + exact operation/protocol + required semantic`

## Evidence priority

When sources disagree, prefer evidence in this order:

1. executable compatibility/conformance tests against the Floci version under use;
2. current operation-specific service documentation and explicit known limitations;
3. current source implementation when documentation is incomplete and code inspection is practical;
4. canonical service matrix for whether an operation is implemented;
5. overview/product pages;
6. aggregate service counts and marketing parity claims.

A lower-priority source never overrides an explicit limitation in a higher-priority source.

## Required fidelity states

Classify each material acceptance operation as one of:

### Supported — behavior adequate

The exact operation/protocol exists and no known deviation affects the behavior being asserted.

Local evidence may earn `Protocol verified`, `Behavior verified`, and—after current support review—`Fidelity scoped`.

### Supported — material deviation

The operation exists, but a documented semantic difference affects or may affect the acceptance claim.

The local test may still prove narrower behavior. Record the deviation and do not generalize beyond it.

### Stubbed / inert / mock-only

The surface exists primarily so clients/provisioners can proceed, while the underlying behavior is absent or simplified.

A successful response generally proves client/provisioning integration only unless the acceptance claim is exactly about the modeled control-plane state.

### Unsupported

The required operation or protocol is not implemented.

Do not silently redirect to the public provider. Redesign the local test or cross the Cloud Execution Boundary deliberately.

### Unknown

Current evidence is insufficient to determine whether Floci can prove the claim.

Unknown is not supported. Investigate before using the result as completion evidence.

## Known-gap pattern

A service can be broadly implemented while one acceptance semantic remains outside the fidelity boundary.

Example: Floci's documented STS `AssumeRole` behavior can evaluate several trust-policy forms when IAM enforcement is enabled, while documented limitations exclude trust-policy `Condition` evaluation and the caller's required identity-policy side of cross-account authorization.

Therefore:

- role-assumption request/response behavior may be locally testable;
- an `ExternalId` enforcement claim is not locally proven by that path;
- full AWS cross-account authorization semantics require another verification surface when they matter.

Apply the same reasoning to every service-specific limitation.

## Version and freshness

For completion-quality evidence:

- identify the Floci release/tag/digest or source revision under test;
- record the documentation/source retrieval date for material fidelity conclusions;
- re-check fast-moving or recently changed services rather than carrying old ledger entries forward indefinitely;
- treat a version upgrade as a potential invalidation event for fidelity assumptions, fixtures, snapshots, and expected errors.

## Floating tags

`latest` and equivalent floating tags are convenient for development, but they are not sufficient provenance for a durable completion receipt.

A project may use floating tags in the inner loop while recording the resolved image version/digest at the slice/completion gate.

## Real-engine rule

A real Docker-backed engine can improve data-plane fidelity without proving the provider's entire managed-service control plane.

For example, PostgreSQL/MySQL/Redis/Kafka-compatible engines can establish useful protocol/data behavior while provider provisioning, IAM, networking, failover, limits, observability, and lifecycle semantics may remain modeled by Floci.

Record the layer the acceptance claim actually depends on.

## Overview-count conflict rule

If aggregate service counts or overview pages disagree, do not spend effort reconciling the count unless the count itself is the research question.

For engineering work, jump directly to the exact service/operation evidence required by the task.

## IaC fidelity

A successful local IaC apply proves that the configured provider/tool can drive the supported local control plane and reach asserted postconditions.

It does not automatically prove:

- every provider validation rule;
- permission boundaries;
- policy evaluation;
- quota/limit behavior;
- region-specific availability;
- cost;
- asynchronous provider lifecycle behavior.

## Error fidelity

Tests that depend on exact provider errors should explicitly verify that Floci documents or tests the relevant error behavior.

Do not infer error parity from successful-path support.

## Fidelity ledger minimum

For each material operation record:

```text
Provider:
Service:
Operation/protocol:
Required semantic:
Floci version:
Support state:
Known deviation:
Evidence source:
Evidence retrieved:
Local result:
Evidence class earned:
Provider-only verification remaining:
```

## Completion criterion

A Floci-backed acceptance claim is responsible when the exact behavior under test lies inside a current, documented or executable fidelity boundary—or the evidence report narrows the claim and explicitly identifies what Floci cannot establish.