# Floci AWS IaC + CI Preflight

Status: draft  
Slice: FLC-02

This directory turns the FLC-01 AWS golden path into an infrastructure preflight that can provision, inspect, isolate, and tear down AWS-shaped infrastructure in CI, with snapshot acceleration exercised only when the running Floci server actually supports it.

The reference proof targets are:

- Terraform;
- OpenTofu;
- CloudFormation;
- independent post-provision assertions;
- capability-gated snapshot cache save/reset/load with invalidation metadata;
- isolated ephemeral CI state.

It deliberately reuses the FLC-01 runtime, endpoint guard, readiness, and evidence boundaries instead of creating a second Floci execution path.

## Source-grounded tool choices

At the FLC-02 audit point, Floci's own compatibility suite uses:

- Terraform `1.14.7`;
- AWS provider `~> 6.0`;
- an explicit per-service endpoint block for local AWS provider execution;
- a separate OpenTofu compatibility module;
- S3/DynamoDB-backed local remote-state compatibility tests.

Project Arsenal pins the tracer more tightly for deterministic evidence:

- Terraform image: `hashicorp/terraform:1.14.7`;
- OpenTofu image: `ghcr.io/opentofu/opentofu:1.8`;
- AWS provider: `6.44.0`.

These are tracer pins, not global recommendations. Downstream repositories should preserve their own supported toolchain unless the task explicitly includes an upgrade.

## Tracer infrastructure

The shared HCL fixture provisions:

- versioned S3 bucket;
- SQS queue + DLQ/redrive policy;
- DynamoDB table;
- IAM role.

Both Terraform and OpenTofu execute the same fixture. After apply, `scripts/assert-iac` checks the provider-shaped APIs directly rather than trusting the IaC engine's exit status.

The direct assertions verify:

- bucket existence;
- bucket versioning enabled;
- queue existence and visibility timeout;
- DLQ existence;
- DynamoDB table `ACTIVE`;
- IAM role existence.

The destroy phase then proves those tracer resources are absent.

## CloudFormation path

`cloudformation/template.yaml` provisions a small S3 + SQS stack through Floci's CloudFormation Query API.

`scripts/verify-cloudformation` checks the terminal stack state and then asserts the resources directly before deletion.

This is intentionally smaller than the HCL tracer. Its purpose is to prove the supported CloudFormation path exists without broadening FLC-02 into a CloudFormation parity project.

## IaC discovery

Run:

```bash
./scripts/detect-iac /path/to/repository
```

The detector emits JSON describing:

- Terraform/OpenTofu HCL files;
- Terraform/OpenTofu CLI availability;
- likely CloudFormation templates;
- lock/backend hints.

Detection is evidence collection, not automatic authorization to patch provider configuration.

## Terraform/OpenTofu execution

The reference scripts run the IaC engines from pinned Docker images so CI does not depend on mutable host installations.

From this directory:

```bash
cp ../env.floci.example ../.env.floci
./scripts/verify-terraform
./scripts/verify-opentofu
```

The scripts always:

1. reconstruct Floci from zero;
2. initialize/validate the HCL fixture;
3. plan and apply;
4. assert resulting provider state independently;
5. probe snapshot save using the documented AWS control-plane request shape;
6. if snapshots are supported, save → reset → prove absence → provenance-check restore → rerun assertions;
7. if snapshots are unavailable on the running server, record `UNSUPPORTED`/`SKIP` and reassert that the applied state remains intact;
8. destroy through the retained IaC state;
9. prove the tracer resources are absent;
10. emit a receipt and preserve logs.

A snapshot-restored pass never replaces the zero-state reconstruction at the start of the gate. Snapshot support is not required to establish the FLC-02 IaC completion claim.

## Snapshot capability and cache key

The latest published Floci AWS server observed for this slice is `1.5.34`. That released server does not implement `/_floci/snapshots/...`; the request falls through to S3 routing. The Floci CLI nevertheless documents AWS snapshot save/load commands.

Project Arsenal therefore treats snapshots as an optional runtime capability rather than assuming server support from CLI/docs alone.

When supported, the reference cache key includes:

- Floci image tag;
- IaC engine identity and pinned image;
- AWS provider pin;
- HCL fixture digest;
- Compose/runtime configuration digest.

A key mismatch refuses restore. Unexpected snapshot errors still fail the gate; only the exact known endpoint-unavailable signature is classified as a capability skip.

See `SNAPSHOT_POLICY.md`.

## CI isolation

`.github/workflows/floci-iac-ci.yml` runs Terraform, OpenTofu, CloudFormation, and an explicit two-runtime isolation probe.

Every hosted job gets an ephemeral runner. The isolation probe additionally launches two independent Floci containers on separate loopback ports, creates the same bucket name in both, writes different marker objects, and proves neither runtime can read the other's marker.

That test establishes instance-state separation; it does not claim every possible self-hosted-runner configuration is isolated.

## Failure artifacts

All verification scripts capture Floci logs on error under:

`.floci-artifacts/iac/`

The workflow uploads the hidden artifact directory with `if: always()`.

Snapshot capability responses are retained there as evidence when the server does not support the documented endpoint.

Do not put real credentials or provider secrets into these artifacts.

## Fidelity boundary

Passing FLC-02 proves that the exact local IaC path and asserted provider-shaped state worked against the pinned emulator/runtime/tool inputs.

It does not prove:

- AWS IAM enforcement parity;
- AWS account/service quotas;
- regional availability rules;
- eventual consistency/timing;
- billing/cost controls;
- production policy/SCP behavior;
- undeclared Terraform provider operations;
- semantic equivalence of every CloudFormation resource/property;
- real remote-state durability characteristics;
- Floci snapshot support unless the receipt explicitly records a successful save/restore exercise.

See `FIDELITY_RECEIPT.md` and the parent Floci fidelity policy.

## Completion criterion

FLC-02 is healthy when:

- Terraform provisions the tracer from zero and independent assertions pass;
- OpenTofu provisions the same tracer from zero and independent assertions pass;
- CloudFormation provisions and deletes its supported tracer stack;
- snapshot capability is recorded honestly: supported paths require provenance-guarded restore + post-restore assertions, unavailable paths require explicit `SKIP` evidence and intact-state reassertion;
- two independent Floci runtimes do not share tracer state;
- failure evidence is uploaded even when a gate fails;
- teardown removes containers/volumes/resources;
- Arsenal Integrity remains green.

The next program slice after acceptance is FLC-03: migration, reproduction, and diagnosis.
