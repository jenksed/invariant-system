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
- `scripts/start` — resolves Docker-socket group access, starts Floci, waits for ready.
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
- a local Unix Docker socket at `/var/run/docker.sock` for the Docker-backed Lambda tracer;
- `curl`;
- Python 3;
- AWS CLI.

The runtime pulls the Lambda Python 3.13 image on first execution.

Floci runs non-root. `scripts/start` and `scripts/verify-completion` read the host Docker socket's numeric GID and add that GID as a supplemental group to the Floci container. This avoids assuming that the host's `docker` group uses the same numeric ID everywhere and avoids running Floci as root merely to reach the socket.

## Start

From this directory:

```bash
cp env.floci.example .env.floci
./scripts/start
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

`scripts/aws-local` refuses execution when `AWS_ENDPOINT_URL` is absent or differs from the approved local endpoint (default `http://localhost:4566`). Explicit process environment overrides the repository env file, so an unsafe caller override cannot be silently masked by `.env.floci`. The wrapper sets synthetic credentials directly and neutralizes profile/config credential discovery.

Application tests adopted from this pack must apply the same fail-closed principle. A passing wrapper cannot make unrelated application code safe by itself.

## CI profile

Project Arsenal exercises this template in `.github/workflows/floci-aws-golden-path.yml`.

The CI gate specifically proves both a missing endpoint and a public AWS endpoint are refused before starting Floci. It then reconstructs the runtime from zero and executes the Docker-backed tracer.

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
