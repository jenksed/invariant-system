# Validate IaC with Floci

Status: draft

Use this workflow when a repository contains AWS Infrastructure as Code and the engineering question can be answered safely against Floci before any real-provider execution.

## Outcome

Produce evidence that a supported infrastructure revision can be provisioned from zero against Floci, that the resulting resources have the required local state, and that any provider-only claims remain explicitly unverified.

A successful `plan` or `apply` is not completion evidence by itself.

## Preconditions

- Read the repository's `AGENTS.md`, `CLAUDE.md`, engineering doctrine, and project-local verification commands first.
- Inspect existing Terraform/OpenTofu/CloudFormation conventions before adding anything.
- Reuse an existing local-cloud/emulator path if it already satisfies the same contract.
- Do not overwrite provider configuration, backend configuration, wrappers, or CI jobs merely to install the reference pack.
- Do not request real AWS credentials when the local execution question can be answered with synthetic credentials.

## 1. Discover the IaC surface

Run the deterministic detector when the Floci Development Pack is available:

```bash
engineering/development_packs/floci/aws/iac/scripts/detect-iac .
```

Then inspect the returned files rather than inferring intent from file extensions alone.

Record:

- IaC engine(s) actually used by the repository;
- authoritative module/root directories;
- AWS provider version constraints and lock files;
- backend/state configuration;
- resource types in scope;
- exact operations/semantics the acceptance criteria depend on;
- existing local endpoint seams or test-only provider configuration;
- CI conventions and concurrency assumptions.

Do not treat the presence of `*.tf` as proof that both Terraform and OpenTofu are supported by the repository.

## 2. Choose the adaptation strategy

Prefer, in order:

1. an existing repository-owned local endpoint variable/profile;
2. a test-only provider configuration already present in the repository;
3. an isolated copied fixture/module used only for local verification;
4. a narrow repository change that introduces an explicit local endpoint seam.

Do not inject a second default AWS provider block into an existing module blindly. Terraform/OpenTofu provider configuration is part of the repository's architecture, not text to patch generically.

For AWS-provider local execution, the reference FLC-02 tracer uses explicit service endpoints, synthetic credentials, metadata/credential validation skips, and path-style S3. Adapt only the service endpoints actually required by the target module.

## 3. Establish the execution boundary

Before initialization, planning, or apply:

- require the approved loopback Floci endpoint;
- use synthetic credentials only;
- disable EC2 metadata credential discovery;
- neutralize ambient AWS profiles when using wrappers;
- prohibit automatic real-AWS fallback;
- start from a known Floci state.

If the repository's IaC tooling cannot be made fail-closed, stop and report the boundary defect before provisioning.

## 4. Run the smallest useful preflight

For Terraform/OpenTofu, the normal progression is:

```text
init
→ validate
→ plan
→ apply
→ post-apply state assertions
→ optional snapshot cache exercise
→ destroy
→ post-destroy absence assertions
```

For CloudFormation:

```text
create-stack
→ wait/describe
→ state assertions
→ delete-stack
→ absence assertions
```

A plan-only run can answer syntax/diff questions, but it cannot satisfy a provisioning acceptance claim.

## 5. Assert state independently of the IaC engine

After apply/create, inspect the provider-shaped APIs directly.

Examples:

- S3 bucket exists and has expected versioning/configuration;
- SQS queue exists and exposes expected attributes;
- DynamoDB table exists with the expected key shape/status;
- IAM role exists with the expected trust-policy shape;
- CloudFormation reports the expected terminal stack state.

Do not accept `terraform apply` exit `0` as proof that the resources have the required semantics.

## 6. Treat snapshots as caches

Snapshot acceleration is allowed only when:

- the snapshot is bound to a reproducible cache key;
- the key includes emulator/runtime provenance and fixture/tool inputs;
- a mismatch refuses restore;
- post-restore assertions rerun;
- the authoritative completion gate can still rebuild from zero.

Never promote a snapshot-restored run to stronger evidence than a clean reconstruction can establish.

## 7. Prove CI isolation

Each CI job must have its own emulator state boundary.

Preferred forms:

- a fresh hosted runner/VM plus ephemeral Floci instance per job;
- unique Compose project/container/port boundaries on a shared worker;
- explicit multi-account isolation only when the task is actually testing account isolation.

Do not share writable Floci persistence between parallel jobs unless the test is specifically about shared state.

## 8. Capture failure evidence

On failure, preserve enough evidence to reproduce the issue:

- IaC engine/version;
- provider lock/version;
- Floci image/version/digest when available;
- plan/apply output;
- direct assertion failures;
- Floci logs;
- snapshot/cache metadata if used;
- teardown result.

Do not preserve secrets. The local pack should use only synthetic credentials.

## 9. Classify the proof

Report separately:

- IaC syntax/validation evidence;
- local provisioning evidence;
- post-provision behavior/state evidence;
- Floci fidelity evidence;
- provider-only unknowns.

A valid final statement looks like:

> The module provisioned from zero against the pinned Floci runtime, the required S3/SQS/DynamoDB/IAM state was independently asserted, and teardown returned the emulator to the expected empty state. This does not establish AWS IAM enforcement parity, quotas, regional behavior, billing, service timing, or undeclared provider semantics.

## 10. Escalate only the residue

Request real-provider verification only for acceptance claims that the local fidelity ledger cannot establish.

State:

- the exact unresolved claim;
- why Floci cannot prove it;
- the minimum real-provider action required;
- the credentials/permissions/blast radius needed;
- the cleanup/evidence plan.

Do not widen the cloud execution scope beyond that residue.

## Project Arsenal reference implementation

See:

- `engineering/development_packs/floci/aws/iac/README.md`
- `engineering/development_packs/floci/aws/iac/FIDELITY_RECEIPT.md`
- `engineering/development_packs/floci/aws/iac/SNAPSHOT_POLICY.md`

The reference implementation is a tracer and reusable pattern, not a mandate to replace repository-native IaC structure.
