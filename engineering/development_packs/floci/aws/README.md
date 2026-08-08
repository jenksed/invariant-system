# Floci AWS Golden Path

Status: draft  
Slice: FLC-01

This directory is the first operational Floci Development Pack overlay. It turns the FLC-00 evidence contract into a runnable AWS tracer:

`S3 input object -> SQS work item -> Lambda event-source mapping -> S3 result object`

It intentionally proves a small, real-shaped path instead of pretending to cover AWS broadly.

## Pinned runtime

The template pins:

`floci/floci:1.5.34-compat`

The compat image is required because the ready hook uses Python/boto3. The completion gate also records the actual pulled image ID and repo digest; a tag alone is not sufficient provenance.

The pin is an FLC-01 fixture choice, not a statement that 1.5.34 is permanently preferred. Upgrade deliberately and rerun the completion gate plus fidelity review.

## Why this tracer

It exercises:

- S3 control/data plane;
- SQS create/send/attribute operations;
- Lambda create + Docker-backed runtime execution;
- Lambda SQS event-source mapping;
- a function-side AWS SDK call back into Floci;
- deterministic init hooks;
- endpoint safety;
- clean replay and observable state assertions.

The tracer manually sends a work item to SQS after uploading the S3 object. It does **not** claim S3 notification configuration fidelity.

## Files

- `docker-compose.floci.yml` — pinned ephemeral Floci runtime.
- `env.floci.example` — synthetic host-side AWS environment.
- `init/ready.d/10-seed.py` — source-controlled seed fixture.
- `lambda/handler.py` — Lambda fixture.
- `scripts/aws-local` — fail-closed AWS CLI wrapper.
- `scripts/wait-ready` — waits for `completed.ready == true`.
- `scripts/reset` — clears emulator state and reapplies the fixture.
- `scripts/run-tracer` — executes and asserts the golden path.
- `scripts/verify-inner` — fast readiness + endpoint + fixture checks.
- `scripts/verify-slice` — clean logical reset + tracer.
- `scripts/verify-completion` — zero-state rebuild, replay, provenance, receipt.
- `FIDELITY_LEDGER.md` — operation-level evidence scope.
- `COMPLETION_RECEIPT.md` — receipt schema produced by the completion gate.

## Host prerequisites

- Docker Engine with Compose v2;
- `curl`;
- Python 3;
- AWS CLI.

The runtime pulls the Lambda Python 3.13 image on first execution.

## Start

From this directory:

```bash
cp env.floci.example .env.floci
docker compose --env-file .env.floci -f docker-compose.floci.yml up -d
./scripts/wait-ready
./scripts/verify-inner
```

Do not source arbitrary local AWS profiles for this workflow. The wrapper supplies synthetic credentials and an explicit endpoint itself.

## Run the tracer

```bash
./scripts/run-tracer
```

The gate:

1. uploads a deterministic source object;
2. sends an explicit SQS work item containing the bucket/key;
3. waits for the Lambda event-source mapping to process it;
4. downloads the result object;
5. asserts source bucket/key, byte count, and SHA-256.

## Reset

```bash
./scripts/reset
```

This calls Floci's native `POST /_floci/state/reset`, verifies the reset response, and reruns the source-controlled ready fixture inside the container.

For strongest completion evidence, `verify-completion` destroys the Compose instance and recreates it rather than relying only on logical reset.

## Verification tiers

```bash
./scripts/verify-inner
./scripts/verify-slice
./scripts/verify-completion
```

`verify-completion` writes `.floci-artifacts/completion-receipt.md`. The artifact directory should normally remain untracked.

## Endpoint safety

`scripts/aws-local` refuses execution unless the endpoint is exactly the approved local endpoint (default `http://localhost:4566`). It sets synthetic credentials directly and neutralizes profile/config credential discovery.

Application tests adopted from this pack must apply the same fail-closed principle. A passing wrapper cannot make unrelated application code safe by itself.

## CI profile

Project Arsenal exercises this template in `.github/workflows/floci-aws-golden-path.yml`.

Downstream repositories may copy the workflow shape, but should preserve their own task runner and only install the checks they need.

## Fidelity boundary

Passing this tracer establishes local protocol/behavior evidence for the operations listed in `FIDELITY_LEDGER.md`.

It does not prove:

- AWS IAM authorization equivalence;
- quotas;
- regional behavior;
- AWS timing/eventual consistency;
- Lambda Firecracker isolation characteristics;
- billing;
- undeclared operations.

See `../FIDELITY_POLICY.md`.

## Native vs compat rule

Use the standard image for repositories with no in-container seed tooling.

Use `-compat` when init hooks need AWS CLI, boto3, or Python. Do not use compat by habit when the extra tooling is unnecessary.

## Completion criterion

FLC-01's golden path is healthy when a zero-state rebuild reaches ready, the endpoint guard blocks unsafe configuration, the tracer deterministically produces the expected S3 result, the image tag/digest is captured, and the ledger/receipt prevent that local success from being reported as real-AWS verification.
