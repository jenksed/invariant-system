# Reproduce a Cloud Bug Locally with Floci

Status: draft

Use when a cloud-facing bug, incident symptom, or configuration failure may be reproducible through Floci and a local red/green loop would materially improve diagnosis.

Compose this workflow with `software_engineering/diagnose_bug_feedback_loop.md`. The generic debugging method remains authoritative; this workflow supplies the cloud-emulation boundary, state-minimization rules, and fidelity checks.

## Outcome

Produce the smallest source-controlled local fixture that reconstructs the sanitized symptom through the exact provider-shaped operations involved, preserves a red receipt, proves a nearby control can turn the signal green, and states what remains provider-only.

## 1. Capture the symptom, not the production environment

Record:

- what was expected;
- what actually happened;
- timestamp/window if relevant;
- provider/service;
- exact API operation or event path when known;
- response/error/status;
- minimal resource configuration implicated;
- ordering/retry/timing facts only when load-bearing.

Do not copy credentials, whole account state, customer payloads, private infrastructure inventories, or full production Terraform state into the local fixture.

Use `engineering/development_packs/floci/aws/diagnostics/STATE_MINIMIZATION.md`.

## 2. Establish a fidelity hypothesis before building state

Resolve the exact operation against current Floci evidence.

Classify the suspected semantic as one of:

- supported and directly testable locally;
- supported with a documented deviation;
- unclear/undocumented in Floci;
- explicitly unsupported;
- provider-only.

If the suspected cause is explicitly outside Floci's fidelity boundary, a local reproduction may still test application/configuration behavior, but it cannot prove provider causality.

## 3. Build a red-capable signal

Prefer:

1. repository integration test;
2. provider-shaped CLI/SDK reproduction;
3. captured request/event replay;
4. narrow synthetic harness.

The signal must assert the actual symptom, not merely that a request failed.

Run it against clean local state and preserve the red result before changing implementation.

If the signal cannot turn red, do not invent a root cause. Revisit the fixture or classify the gap as provider-only/emulator-limited.

## 4. Reconstruct only required state

Use source-controlled IaC, init hooks, seed scripts, or direct API calls.

Prefer synthetic names and payloads that preserve structure.

Hash the fixture inputs and record the pinned Floci runtime.

## 5. Minimize while preserving red

Remove one dimension at a time:

- resources;
- payload fields;
- policies;
- retries;
- event hops;
- callers;
- auxiliary services.

Rerun the red signal after each removal.

Stop when every remaining element is load-bearing.

## 6. Prove a nearby control

Change one causal candidate while keeping the signal and fixture otherwise stable.

Examples:

- corrected queue attribute;
- corrected endpoint/config value;
- previous known-good revision;
- one policy field;
- one event field;
- alternate supported operation.

The same signal should turn green. A permanently failing reproduction is not a sufficient diagnostic loop.

The FLC-03 reference pack demonstrates this with `examples/sqs-redrive-mismatch/`.

## 7. Diagnose one boundary at a time

If local behavior is surprising, use `agent_workflows/diagnose_floci_environment.md` before editing application code.

Then probe hypotheses one variable at a time.

Capture scoped emulator logs only when they discriminate between hypotheses.

## 8. Separate three possible causes

Do not collapse these:

1. application/configuration defect;
2. emulator fidelity defect or unsupported semantic;
3. target-cloud-only behavior.

Use `agent_workflows/audit_floci_fidelity_gap.md` whenever the evidence could fit more than one category.

## 9. Convert the minimized repro into durable evidence

Where appropriate:

- add a regression test at the repository's public seam;
- preserve the minimal fixture;
- keep the red receipt in the investigation record, not as a permanently failing CI test;
- add the fixed/green test to normal verification;
- remove temporary instrumentation.

## 10. Escalate only irreducible residue

If real-provider verification is required, state:

- exact unresolved claim;
- why Floci cannot establish it;
- smallest real-provider action needed;
- credentials/permissions required;
- cleanup plan;
- expected evidence.

Do not widen the request into general production access.

## Completion receipt

Use `engineering/development_packs/floci/aws/diagnostics/BUG_REPRO_RECEIPT.md` and include:

- sanitized symptom;
- exact service/operations;
- fixture digest;
- red command/result;
- control/green command/result;
- minimized state;
- Floci provenance;
- fidelity classification;
- provider-only residue;
- cleanup result.
