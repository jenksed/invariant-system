# Floci AWS Migration and Diagnostic Pack

Status: draft

This is the runnable FLC-03 reference pack for moving existing LocalStack-backed repositories to Floci and for reducing cloud symptoms into local, evidence-producing reproductions.

The pack composes rather than replaces:

- `software_engineering/diagnose_bug_feedback_loop.md`;
- `foundations/cloud_execution_boundary.md`;
- `foundations/cloud_fidelity_ledger.md`;
- `foundations/reproducible_cloud_fixtures.md`;
- the FLC-01 AWS endpoint, readiness, reset, and evidence machinery;
- the FLC-02 IaC/CI preflight.

## Governing rule

A migration or local reproduction is complete only when it preserves a behavioral claim with evidence.

Changing `localstack/localstack` to `floci/floci` is configuration work. It is not migration proof.

Similarly, making a remote symptom disappear locally is not evidence that the original issue is fixed. A reproduction must first prove the symptom with a red-capable signal, then minimize state, then distinguish application behavior from emulator fidelity and provider-only semantics.

## Capability surface

### LocalStack migration inventory

Run:

```bash
engineering/development_packs/floci/aws/diagnostics/scripts/inventory-localstack .
```

The inventory scans repository text/configuration for known LocalStack-specific assumptions and classifies them as:

- `BLOCKER` — must be redesigned or explicitly resolved before runtime replacement;
- `TRANSLATE` — a Floci equivalent or compatibility translation exists, but behavior still needs verification;
- `KEEP_COMPAT` — Floci intentionally supports the compatibility surface; preserve first, simplify later;
- `VERIFY` — support is contextual, security-sensitive, or runtime-dependent;
- `REMOVE` — LocalStack-only configuration should be deliberately removed.

Use `--format json` for machine-readable output and `--fail-on-blocker` for a hard migration gate.

The inventory is deliberately conservative. It finds known assumptions; absence of findings is not proof of semantic parity.

### Environment diagnosis

With the intended local endpoint active:

```bash
AWS_ENDPOINT_URL=http://localhost:4566 \
  engineering/development_packs/floci/aws/diagnostics/scripts/diagnose-floci \
  .floci-artifacts/diagnostics/environment.md
```

The diagnostic refuses non-loopback AWS endpoints, checks native and LocalStack-compatible init surfaces, and performs a provider-shaped read-only S3 probe when AWS CLI is available.

Use it before modifying application code when a Floci-backed test suddenly fails.

### Reproduction tracer

The reference case under `examples/sqs-redrive-mismatch/` models a sanitized remote symptom:

> the worker queue is configured with `maxReceiveCount=3` while the acceptance contract requires `5`.

The tracer intentionally starts red, proves the exact mismatch through `GetQueueAttributes`, applies a narrow control change, and proves the same signal turns green. This demonstrates the diagnostic contract without pretending the example came from a real incident.

Run the completion proof:

```bash
engineering/development_packs/floci/aws/diagnostics/scripts/verify-reproduction
```

The result is a receipt under `.floci-artifacts/diagnostics/`.

## LocalStack compatibility facts used by this pack

As of the 2026-08-08 source audit:

- Floci uses the same default AWS edge port `4566`.
- Dummy AWS credentials remain valid.
- LocalStack init directories under `/etc/localstack/init/` are accepted.
- `/_localstack/init` and `/_localstack/health` compatibility surfaces are available.
- several LocalStack environment variables are translated automatically unless parity translation is disabled;
- Floci-native configuration wins when both native and translated values are set;
- `LAMBDA_REMOTE_DOCKER` is explicitly unsupported;
- LocalStack persistence path `/var/lib/localstack` differs from Floci `/app/data`;
- Floci's standard image does not promise AWS CLI/boto3 in init scripts; use the pinned `-compat` image when those tools are required;
- the `-compat` image ships `awslocal`, which forces `--endpoint-url` because older botocore service resolvers can bypass `AWS_ENDPOINT_URL` for SQS;
- persistent `/app/data` must be writable by Floci's container user; a Docker named volume is the reference migration fixture because a host bind can inherit incompatible ownership in CI.

Do not copy aggregate service counts from migration documentation into Arsenal. Capability truth remains provider + service + exact operation/protocol + required semantic.

## Compatibility lessons proven by the FLC-03 tracer

The runtime gate intentionally preserves the LocalStack init script byte-for-byte:

```sh
awslocal s3 mb s3://arsenal-flc03-migration
awslocal sqs create-queue --queue-name arsenal-flc03-migration
```

That detail is load-bearing. During FLC-03 validation, replacing `awslocal` with bare `aws` allowed the S3 call to work while the SQS call escaped the emulator through an older botocore service-specific resolver and reached public AWS, which rejected the synthetic credentials with `InvalidClientTokenId`. Floci's shipped `awslocal` wrapper exists specifically to force the local endpoint for this class of client behavior.

The first persistent-state fixture also used a host bind to `/app/data`; on the GitHub runner that directory ownership was incompatible with Floci's non-root container user. The corrected fixture uses a Docker named volume. Do not "fix" this class of migration failure by making the emulator run as root unless the target repository has a separately justified requirement.

These findings reinforce the migration method: preserve supported compatibility behavior first, run it, and let evidence identify which differences actually require adaptation.

## Migration acceptance contract

Use `MIGRATION_ACCEPTANCE_MATRIX.md`.

At minimum, a migration must prove:

1. the LocalStack-specific assumptions were inventoried;
2. unresolved blockers are zero;
3. the target Floci image/version is pinned;
4. the execution endpoint remains fail-closed to loopback;
5. init hooks reach `ready`;
6. the workload's exact provider-shaped operations execute;
7. pre-migration behavioral expectations are preserved or intentionally revised;
8. known LocalStack/Floci differences are recorded;
9. provider-only residue remains explicit;
10. clean reconstruction produces the same result.

A repository may retain LocalStack compatibility paths after migration. Native-path cleanup is optional and must not be confused with migration correctness.

## Bug reproduction contract

A local cloud reproduction must include:

- a sanitized statement of the remote symptom;
- exact service/operation scope;
- minimal versioned fixture inputs;
- a red-capable command or test;
- a preserved red receipt;
- evidence that removing or correcting the suspected condition flips the signal;
- a fidelity classification for every claim used to infer root cause;
- explicit residual provider-only questions.

Production payloads, credentials, account IDs, secrets, and customer data must not be copied into the fixture. Preserve structure and causal inputs, not sensitive state.

## Diagnosis order

Prefer this order:

1. execution boundary and endpoint safety;
2. emulator process/container reachability;
3. init-hook readiness;
4. pinned runtime provenance;
5. exact provider-shaped operation;
6. direct state inspection;
7. scoped emulator logs;
8. application logs/traces;
9. operation-level fidelity evidence;
10. minimal provider escalation only for irreducible residue.

Do not jump from "local failure" to "Floci bug" or from "local pass" to "AWS verified."

## Logging

Floci uses Quarkus logging. The normal diagnostic escalation is:

- default `INFO`;
- affected service category at `DEBUG`;
- affected service category at `TRACE` only when payload-level evidence is required.

Avoid global TRACE by default. Diagnostic artifacts can contain payloads and identifiers; sanitize before attaching them to issues or public PRs.

## CI reference

`.github/workflows/floci-diagnostics-ci.yml` proves three FLC-03 properties:

- the LocalStack inventory recognizes a known unsupported assumption;
- a LocalStack-style init/config fixture runs through Floci compatibility mode and reaches the expected seeded state while retaining the init script byte-for-byte;
- the SQS redrive reproduction is red-capable, then green-capable after the control change.

Existing FLC-01 and FLC-02 workflows remain regression authority for the underlying local cloud execution surface.

## Completion evidence

A FLC-03 completion receipt should name:

- repository revision;
- Floci image/version/digest when available;
- migration inventory artifact;
- unresolved blockers;
- exact migrated behaviors checked;
- reproduction case ID and fixture digest when applicable;
- red signal;
- control/green signal;
- diagnostic artifact;
- fidelity gaps;
- provider-only residue;
- cleanup result.

The goal is not "works on Floci." The goal is:

> the migrated or reproduced behavior is reconstructable, bounded to exact operations, diagnostic evidence is preserved, and no local result is overstated as provider verification.
