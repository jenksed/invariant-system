# Floci Pack Reference

Status: draft

This is the small agent-facing pointer surface for the Floci Development Pack. Read the linked foundations when the task needs deeper reasoning; do not copy volatile Floci service matrices into agent context.

## Use this pack when

- application code calls AWS/Azure/GCP/OCI services that Floci can emulate;
- a cloud bug may be reproducible locally;
- Terraform/OpenTofu/CloudFormation changes can be exercised against supported local operations;
- CI needs an isolated cloud-shaped environment;
- a repository uses LocalStack and is being evaluated or migrated to Floci;
- an agent would otherwise need cloud credentials for ordinary implementation work.

## Before mutation

1. Inspect repository instructions and existing cloud/emulator configuration.
2. Identify provider, services, exact operations/protocols, and acceptance behavior.
3. Check current Floci operation-specific support and known limitations.
4. Confirm the execution endpoint is local.
5. Choose explicit state semantics: clean ephemeral, fixture replay, snapshot restore, or deliberate persistence.

## AWS quick baseline

Current documented defaults:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

Prefer `floci doctor` / `floci status` or explicit health/readiness checks before expensive work. When init hooks are used, wait for `ready`, not merely for a running container.

## Verification tiers

- **Inner loop:** prove connectivity + targeted behavior quickly.
- **Slice gate:** rebuild/restore controlled state, apply fixture, run coherent feature scenario, assert resulting state, update fidelity ledger.
- **Completion gate:** clean replay from durable inputs, full relevant test/gate suite, pinned Floci provenance, evidence receipt, explicit remaining provider-only claims.

See `VERIFICATION_CONTRACT.md`.

## Evidence language

Allowed local evidence labels:

- `Protocol verified`
- `Behavior verified`
- `Fidelity scoped`

Use `Cloud verified` only after actual execution against the provider.

See `foundations/cloud_fidelity_ledger.md` and `FIDELITY_POLICY.md`.

## Hard stops

Do not:

- silently fall back to a public cloud endpoint;
- request real cloud credentials merely because local emulation lacks an operation;
- claim provider IAM/quota/timing/billing/region behavior from a local pass without evidence;
- rely on aggregate Floci service counts as acceptance evidence;
- treat a LocalStack image replacement as complete migration without running relevant behavior;
- use a floating image tag as the only provenance for a completion claim.

## Escalation

If Floci cannot prove a required behavior, record the exact gap and follow `foundations/cloud_execution_boundary.md` to request the smallest authorized remote verification.

## Primary references

- Floci source audit: `docs/source_audits/floci.md`
- Pack contract: `engineering/development_packs/floci/README.md`
- Verification: `engineering/development_packs/floci/VERIFICATION_CONTRACT.md`
- Fidelity: `engineering/development_packs/floci/FIDELITY_POLICY.md`
- Roadmap: `engineering/development_packs/floci/ROADMAP.md`

## Completion rule

Do not say a cloud-dependent task is done until the evidence receipt distinguishes local proof from provider proof and every acceptance claim is either verified on an adequate surface or explicitly marked as remaining.