# Adopt Floci in a Repository

Status: draft

Use this workflow when an existing repository needs a safe, reproducible local AWS surface backed by Floci.

The outcome is not "add Docker Compose." The outcome is a repository-local cloud loop whose endpoint cannot silently fall through to AWS, whose state can be reconstructed from source control, and whose evidence is scoped to Floci's actual fidelity.

## Inputs

Inspect before changing anything:

- repository instructions (`AGENTS.md`, `CLAUDE.md`, contribution docs);
- existing Docker/Compose/Testcontainers/devcontainer setup;
- existing LocalStack, Moto, MinIO, ElasticMQ, WireMock, fake-cloud, or provider-emulator configuration;
- package/task runners and CI workflows;
- AWS SDK/CLI/IaC usage and endpoint configuration;
- cloud services and exact operations exercised by the intended slice;
- existing fixtures, seed scripts, snapshots, and teardown behavior;
- credential sources and public-cloud deployment commands.

Do not install a second local-cloud mechanism when an equivalent existing mechanism already satisfies the required evidence contract.

## Required decisions

Before mutation, resolve:

1. **Provider** — FLC-01 supports AWS only.
2. **Operations** — name the exact AWS operations/protocols the repository needs.
3. **Execution boundary** — local Floci by default; no automatic AWS fallback.
4. **Image** — standard vs compat. Use compat when init hooks need Python, boto3, or AWS CLI.
5. **Version** — pin a release tag for repeatable gates. Record the image digest at completion.
6. **State** — memory for ephemeral/CI unless persistence is a tested requirement.
7. **Fixture** — source-controlled and replayable.
8. **Container services** — decide whether Docker socket access is needed and keep it narrowly scoped.
9. **Verification** — identify repository-native inner, slice, and completion gates.
10. **Fidelity** — identify provider-only semantics that remain outside local proof.

## Installation strategy

Prefer adapting the FLC-01 AWS golden-path template under:

`engineering/development_packs/floci/aws/`

Copy only the pieces the target repository needs. Preserve its existing task runner and naming conventions.

Minimum installed capability:

- a pinned Floci Compose/Testcontainers/runtime definition;
- explicit synthetic AWS environment;
- an endpoint guard or wrapper that refuses non-local endpoints;
- deterministic readiness;
- source-controlled seed state;
- deterministic reset/reconstruction;
- one observable end-to-end cloud behavior;
- a fidelity ledger;
- a completion receipt;
- CI or equivalent clean-machine execution.

## Fail-closed rule

A local verification command must stop before invoking `aws`, an SDK test, or IaC when:

- `AWS_ENDPOINT_URL` is absent;
- the endpoint is not the repository's approved Floci endpoint;
- real or unknown credentials are present;
- a profile/config can override the synthetic credentials unless the wrapper neutralizes it.

Never "try AWS if Floci is unavailable."

## Existing tooling

If LocalStack or another emulator is already present:

- inventory the operations it covers;
- identify emulator-specific environment variables, inspection endpoints, init hooks, persistence, and container behavior;
- do not replace it merely because Floci exists;
- if migration is justified, preserve behavior first and defer broad migration work to FLC-03.

## Golden-path proof

For initial adoption, implement one thin vertical path before broadening coverage.

FLC-01's reference path is:

`S3 object -> SQS work item -> Lambda event-source mapping -> S3 result`

The S3-to-SQS hop is deliberately application/workflow-driven rather than claiming S3 notification semantics. This keeps the tracer focused on explicit, supported operations.

## Completion

Do not call adoption complete until:

- the repository can reconstruct the local cloud from zero;
- endpoint safety fails closed;
- the golden path produces and asserts an observable result;
- the exact Floci tag and pulled image digest are recorded;
- the fidelity ledger names every material operation in the tracer;
- CI or an equivalent clean environment exercises the same gate;
- remaining AWS-only verification is explicit.

Return the installed paths, commands, evidence receipt, fidelity limits, and any intentionally deferred provider proof.
