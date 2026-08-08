# Diagnose a Floci Environment

Status: draft

Use when a Floci-backed test, migration, or local cloud workflow fails and you need to determine whether the problem is endpoint safety, emulator startup/readiness, init state, provider-shaped behavior, application behavior, or a fidelity gap.

## Outcome

Produce a bounded diagnosis with evidence from the lowest useful layer before changing application code or blaming the emulator.

## 1. Prove the execution boundary

Confirm:

- the intended endpoint is explicit;
- it resolves to the approved local Floci runtime;
- synthetic credentials are in use;
- ambient AWS profiles/config cannot redirect the request;
- no fallback to public AWS is possible.

The reference diagnostic refuses endpoints other than `http://localhost:4566` or `http://127.0.0.1:4566`.

If endpoint safety is not proven, stop. Do not continue diagnosis against an ambiguous target.

## 2. Check process/container reachability

Inspect the runtime before the application:

- container/process running state;
- port binding;
- Docker daemon/socket when container-backed services are involved;
- runtime image/version/digest;
- recent startup logs.

If the Floci CLI is installed, `floci status`, `floci doctor`, and `floci logs` are useful supplemental probes. They are not required for the Development Pack because direct endpoints and provider-shaped calls remain portable across harnesses.

## 3. Check initialization state

Probe:

- `/_floci/init`;
- `/_localstack/init` when compatibility mode or migrated wait strategies matter;
- hook status and failing phase;
- init script exit/timeout evidence.

Container health alone is not proof that the fixture reached its required `ready` state.

## 4. Run one read-only provider-shaped probe

Choose the smallest operation that proves routing through the service layer without mutating state.

The reference diagnostic uses S3 `ListBuckets` when AWS CLI is available.

If init is healthy but the provider-shaped probe fails, capture the exact response before changing configuration.

## 5. Narrow to the affected service/operation

Record:

- service;
- exact operation/protocol;
- request shape relevant to the failure;
- response/error;
- current local resource state;
- whether the same operation passed previously on the pinned runtime.

Avoid broad service-level claims.

## 6. Increase logging only where discriminating

Floci uses Quarkus logging.

Escalate in this order:

1. default `INFO`;
2. affected service category `DEBUG`;
3. affected service category `TRACE` if request/response payload detail is required.

Do not enable global TRACE by default.

Diagnostic logs can contain payloads and identifiers. Sanitize before publishing.

## 7. Inspect spawned service containers when relevant

For Lambda, RDS, ElastiCache, MSK, or other Docker-backed services, distinguish:

- Floci control-plane process health;
- spawned container health;
- Docker network/DNS reachability;
- image pull/runtime failure;
- service API behavior.

A healthy Floci parent does not imply every managed child is healthy.

## 8. Classify the failure

End diagnosis in one of these states:

- `BOUNDARY_DEFECT` — unsafe/wrong endpoint, credentials, routing, or ambient config;
- `RUNTIME_DEFECT` — Floci/container startup or readiness problem;
- `FIXTURE_DEFECT` — init/seed/state construction is wrong or incomplete;
- `APPLICATION_DEFECT` — application/configuration produces the observed failure on supported local semantics;
- `FIDELITY_GAP` — Floci behavior is unsupported, documented as different, or inconsistent with required provider semantics;
- `PROVIDER_ONLY` — the acceptance claim cannot be established locally;
- `UNKNOWN` — evidence is still insufficient.

Do not use `UNKNOWN` as permission to guess.

## 9. Continue through the appropriate workflow

- Application/configuration defect → `software_engineering/diagnose_bug_feedback_loop.md`.
- Cloud symptom needing local reconstruction → `agent_workflows/reproduce_cloud_bug_locally.md`.
- Fidelity uncertainty → `agent_workflows/audit_floci_fidelity_gap.md`.
- LocalStack migration issue → `agent_workflows/migrate_localstack_to_floci.md`.

## Reference command

```bash
AWS_ENDPOINT_URL=http://localhost:4566 \
  engineering/development_packs/floci/aws/diagnostics/scripts/diagnose-floci \
  .floci-artifacts/diagnostics/environment.md
```

## Handoff

Report:

- endpoint boundary result;
- runtime provenance;
- init/readiness result;
- provider-shaped probe;
- exact failing service/operation;
- logs/instrumentation captured;
- classification;
- next discriminating action;
- provider-only residue if any.
