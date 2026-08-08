# FLC-02 IaC Fidelity Receipt

Status: draft

Use this receipt for IaC/CI evidence produced by the Floci AWS Development Pack.

## Provenance

- Project Arsenal revision:
- IaC engine:
- IaC engine version/image:
- AWS provider version:
- Floci image tag:
- Floci reported version:
- Floci image ID/digest:
- HCL/template digest:
- CI run/job:
- execution endpoint:
- storage mode:

## Provisioning evidence

- init/validate:
- plan:
- apply/create:
- direct post-provision assertions:
- snapshot capability: `SUPPORTED` | `UNSUPPORTED` | `NOT_EXERCISED`
- snapshot save: `PASS` | `SKIP`
- reset/absence assertion: `PASS` | `SKIP`
- snapshot provenance match: `PASS` | `SKIP`
- snapshot restore: `PASS` | `SKIP`
- post-restore assertions: `PASS` | `SKIP`
- post-snapshot-probe assertions: `PASS` | `NOT_APPLICABLE`
- destroy/delete:
- post-destroy absence assertions:
- teardown:

Snapshot fields must not be marked `PASS` unless the running Floci server actually executed the corresponding control-plane operation. When the server does not implement the documented snapshot endpoint, record the capability as `UNSUPPORTED`, preserve the probe response, and continue only after reasserting the applied IaC state.

## Operations/semantics exercised

Record the exact service operations or resource semantics that matter to the acceptance claim.

| Surface | Required operation/semantic | Local evidence | Fidelity notes |
|---|---|---|---|
| S3 | bucket create/head + versioning | | |
| SQS | queue/DLQ create + attributes/redrive | | |
| DynamoDB | table create/describe/delete | | |
| IAM | role create/get/delete | | |
| CloudFormation | create/describe/delete supported stack | | |
| Floci control plane | reset; snapshot save/load only when supported by running server | | |

## Provider-only residue

Explicitly list claims that remain unverified against AWS, for example:

- IAM authorization/enforcement parity;
- organization/SCP behavior;
- quotas;
- region-specific behavior;
- AWS timing/eventual consistency;
- billing/cost controls;
- CloudFormation properties/resource types not exercised;
- provider operations not present in this receipt.

## Allowed completion statement

When snapshots are supported and exercised:

> The declared IaC revision provisioned from zero against the pinned Floci environment and the required provider-shaped state was independently asserted. Snapshot restore was accepted only with matching provenance and post-restore assertions. The declared provider-only residue remains unverified against AWS.

When snapshots are unavailable:

> The declared IaC revision provisioned from zero against the pinned Floci environment, the required provider-shaped state was independently asserted, and destroy returned the tracer resources to the expected absent state. The running Floci server did not support the documented snapshot control-plane endpoint, so snapshot acceleration was explicitly skipped and is not claimed. The declared provider-only residue remains unverified against AWS.

Do not shorten either statement into "AWS verified" or "production ready."
