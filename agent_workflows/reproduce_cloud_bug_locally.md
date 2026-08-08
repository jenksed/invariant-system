# Reproduce a Cloud Bug Locally with Floci

Status: draft

Use when an AWS, Azure, GCP, or OCI-facing bug, incident symptom, or configuration failure may be reproducible through Floci and a local red/green loop would materially improve diagnosis.

Compose this workflow with `software_engineering/diagnose_bug_feedback_loop.md`. The generic debugging method remains authoritative; this workflow supplies provider routing, cloud-emulation boundaries, state-minimization rules, and fidelity checks.

## Outcome

Produce the smallest source-controlled local fixture that reconstructs the sanitized symptom through the exact provider-shaped operations involved, preserves a red receipt, proves a nearby control can turn the signal green, and states what remains provider-only.

## 0. Resolve provider and local overlay

Use `agent_workflows/route_local_cloud_provider.md` and record the selected provider pack. Stop on ambiguous/unknown provider intent.

The selected overlay owns endpoint safety, synthetic identity, readiness, and operation-level fidelity. Do not translate Azure/GCP/OCI semantics into AWS concepts merely because the original FLC-03 reference implementation was AWS-backed.

## 1. Capture the symptom, not the production environment

Record expected vs actual behavior, timestamp/window if relevant, provider/service, exact API/event path, response/error, minimal implicated resource configuration, and only load-bearing ordering/retry/timing facts.

Do not copy credentials, account/subscription/project/tenancy state, customer payloads, private infrastructure inventories, or production IaC state into the fixture.

Use `foundations/reproducible_cloud_fixtures.md` as the provider-neutral minimization contract. The AWS reference also provides `engineering/development_packs/floci/aws/diagnostics/STATE_MINIMIZATION.md`.

## 2. Establish a fidelity hypothesis before building state

Resolve the exact operation against the selected provider's current Floci evidence and classify it as supported/directly testable, supported with deviation, unclear, unsupported, or provider-only.

If the suspected cause is outside local fidelity, a reproduction may still test application/configuration behavior but cannot prove provider causality.

## 3. Build a red-capable signal

Prefer repository integration test, provider-shaped SDK/CLI/wire reproduction, captured request/event replay, then a narrow synthetic harness.

The signal must assert the actual symptom. Run it against clean local state and preserve red evidence before changing implementation.

If it cannot turn red, revisit the fixture or classify the gap honestly.

## 4. Reconstruct only required state

Use source-controlled IaC where that provider has a supported local IaC path, otherwise init hooks, seed scripts, or direct provider-shaped API calls. Prefer synthetic names/payloads. Hash fixture inputs and record pinned runtime provenance.

Do not route non-AWS IaC through the AWS-only FLC-02 validator.

## 5. Minimize while preserving red

Remove resources, payload fields, policies, retries, event hops, callers, and auxiliary services one dimension at a time, rerunning the red signal after each removal. Stop when every remaining element is load-bearing.

## 6. Prove a nearby control

Change one causal candidate while keeping signal/fixture stable. The same signal should turn green. The FLC-03 AWS reference demonstrates this with the SQS redrive mismatch tracer; other providers should use an equivalent provider-shaped control rather than copying SQS semantics.

## 7. Diagnose one boundary at a time

If local behavior is surprising, use `agent_workflows/diagnose_floci_environment.md` before editing application code. Probe hypotheses one variable at a time and capture scoped logs only when discriminating.

## 8. Separate three possible causes

Keep application/configuration defect, emulator fidelity defect/unsupported semantic, and target-cloud-only behavior distinct. Use `agent_workflows/audit_floci_fidelity_gap.md` when evidence fits more than one category.

## 9. Convert the minimized repro into durable evidence

Where appropriate, add a regression test at the public seam, preserve the minimal fixture, retain red evidence in the investigation record, add the fixed/green test to normal verification, and remove temporary instrumentation.

## 10. Escalate only irreducible residue

If real-provider verification is required, state the exact unresolved claim, why local evidence cannot establish it, the smallest provider action, required permission scope, cleanup, and expected closing evidence. Do not widen into general cloud access.

## Completion receipt

Use `engineering/development_packs/floci/providers/PROVIDER_RECEIPT.md` as the common provenance/evidence envelope plus the selected provider's fidelity ledger/receipt fields.

For AWS, `engineering/development_packs/floci/aws/diagnostics/BUG_REPRO_RECEIPT.md` remains the richer reference template.

Include sanitized symptom, exact provider/service/operations, fixture digest, red result, control/green result, minimized state, Floci provenance, fidelity classification, provider-only residue, and cleanup result.
