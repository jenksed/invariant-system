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
- snapshot save:
- reset/absence assertion:
- snapshot provenance match:
- snapshot restore:
- post-restore assertions:
- destroy/delete:
- post-destroy absence assertions:
- teardown:

## Operations/semantics exercised

Record the exact service operations or resource semantics that matter to the acceptance claim.

| Surface | Required operation/semantic | Local evidence | Fidelity notes |
|---|---|---|---|
| S3 | bucket create/head + versioning | | |
| SQS | queue/DLQ create + attributes/redrive | | |
| DynamoDB | table create/describe/delete | | |
| IAM | role create/get/delete | | |
| CloudFormation | create/describe/delete supported stack | | |
| Floci control plane | snapshot save/load + reset | | |

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

> The declared IaC revision provisioned from zero against the pinned Floci environment and the required provider-shaped state was independently asserted. Snapshot restore was accepted only with matching provenance and post-restore assertions. The declared provider-only residue remains unverified against AWS.

Do not shorten this into "AWS verified" or "production ready."
