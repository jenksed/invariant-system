# Diagnose a Floci Environment

Status: draft

Use when a Floci-backed AWS, Azure, GCP, or OCI test/workflow fails and you need to determine whether the problem is endpoint safety, emulator startup/readiness, fixture state, provider-shaped behavior, application behavior, or fidelity.

## Outcome

Produce a bounded diagnosis with evidence from the lowest useful layer before changing application code or blaming the emulator.

## 0. Resolve the provider

Use `agent_workflows/route_local_cloud_provider.md` before provider-shaped diagnosis. If provider evidence is ambiguous or unknown, stop rather than applying the AWS diagnostic path by habit.

Use the selected provider overlay as the authority for endpoint guard, readiness, synthetic identity, and direct provider-shaped probes.

## 1. Prove the execution boundary

Confirm:

- the provider-specific local endpoint is explicit;
- it resolves to the approved local Floci runtime;
- only synthetic local identity material is in use;
- ambient provider credentials/config cannot redirect the request;
- no fallback to a public provider is possible.

Run the selected overlay's endpoint guard before continuing. The AWS reference diagnostic still refuses endpoints other than `http://localhost:4566` or `http://127.0.0.1:4566`; Azure/GCP/OCI use their own contracts and must not be translated into AWS variables.

If endpoint safety is not proven, stop.

## 2. Check process/container reachability

Inspect:

- runtime process/container state;
- provider-specific port binding;
- Docker daemon/socket when managed child containers are relevant;
- runtime image/version/digest;
- recent startup logs.

Floci CLI status/doctor/logs are supplemental when available; provider-shaped calls and direct readiness surfaces remain the portable evidence.

## 3. Check initialization/readiness state

Use the selected provider overlay's readiness contract.

For AWS, inspect `/_floci/init` and LocalStack-compatible init surfaces when relevant. Do not impose those AWS-specific surfaces on Azure, GCP, or OCI.

Container health alone is not proof that the required fixture is ready.

## 4. Run one read-only provider-shaped probe

Choose the smallest read-only operation that proves routing through the selected provider service layer without mutating state.

Examples depend on the overlay: AWS may use S3 `ListBuckets`; Azure/GCP/OCI should use the provider-shaped SDK/wire probe already represented by that overlay rather than an AWS CLI substitute.

If readiness is healthy but the provider-shaped probe fails, capture the exact response before changing configuration.

## 5. Narrow to the affected service/operation

Record:

- provider;
- service;
- exact operation/protocol;
- relevant request shape;
- response/error;
- current local resource state;
- whether the operation passed previously on the pinned runtime.

Avoid broad service-level claims.

## 6. Increase logging only where discriminating

Escalate from default logs to affected service/category DEBUG, then TRACE only if request/response payload detail is required. Avoid global TRACE and sanitize artifacts before publishing.

## 7. Inspect managed child runtimes when relevant

Distinguish parent-emulator health from child execution/runtime health for any provider feature that launches or manages auxiliary containers/processes. Do not generalize AWS Lambda-specific assumptions to another provider runtime.

## 8. Classify the failure

End in one of:

- `BOUNDARY_DEFECT`;
- `RUNTIME_DEFECT`;
- `FIXTURE_DEFECT`;
- `APPLICATION_DEFECT`;
- `FIDELITY_GAP`;
- `PROVIDER_ONLY`;
- `UNKNOWN`.

Do not use `UNKNOWN` as permission to guess.

## 9. Continue through the appropriate workflow

- Application/configuration defect → `software_engineering/diagnose_bug_feedback_loop.md`.
- Cloud symptom needing local reconstruction → `agent_workflows/reproduce_cloud_bug_locally.md`.
- Fidelity uncertainty → `agent_workflows/audit_floci_fidelity_gap.md`.
- LocalStack migration issue → `agent_workflows/migrate_localstack_to_floci.md` (AWS only).

## Reference execution

Prefer the selected provider pack's `scripts/verify-inner` and provider-specific readiness/guard surfaces.

AWS additionally provides:

```bash
AWS_ENDPOINT_URL=http://localhost:4566 \
  engineering/development_packs/floci/aws/diagnostics/scripts/diagnose-floci \
  .floci-artifacts/diagnostics/environment.md
```

That command is an AWS reference implementation, not the universal diagnostic contract.

## Handoff

Report provider, endpoint boundary, runtime provenance, readiness, provider-shaped probe, exact failing operation, captured evidence, classification, next discriminating action, and provider-only residue.
