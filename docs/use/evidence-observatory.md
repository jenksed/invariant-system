# Evidence Observatory / Agent Flight Recorder

Status: ARS-07 v0

ARS-07 normalizes existing Arsenal receipts into one inspectable Flight Record without requiring an observability backend or private reasoning capture.

## What the record answers

A Flight Record is designed to answer:

- what run happened;
- which capability or evaluation suite it concerned;
- what repository state was involved;
- what model/harness/adapter was actually observed;
- what authority profile applied;
- which context sources were referenced;
- what tools/selectors executed;
- what evidence was accepted;
- what limitations survived normalization;
- why the final verdict was claimable.

## v0 inputs

Two real Arsenal evidence families are supported:

### ARS-06 executable-world receipt

```bash
python3 scripts/arsenal_observe.py record-dagger \
  --source .arsenal-evidence/ars-06-tdd-python-container.json \
  --output .arsenal-observatory/dagger-flight.json \
  --instance-id local:dagger:1 \
  --repository-sha "$(git rev-parse HEAD)"
```

### ARS-02 Bench receipt

```bash
python3 scripts/arsenal_observe.py record-bench \
  --source .arsenal-bench/local-cloud-receipt.json \
  --output .arsenal-observatory/bench-flight.json \
  --instance-id local:bench:1 \
  --repository-sha "$(git rev-parse HEAD)"
```

## Verify a record

```bash
python3 scripts/arsenal_observe.py verify \
  --record .arsenal-observatory/dagger-flight.json
```

Verification checks the record contract, privacy policy, evidence binding, source-receipt digest, timeline ordering, runtime identity semantics, and deterministic fingerprint.

## Compare equivalent runs

`instance_id` identifies an operational run. `fingerprint` identifies the stable execution/evidence facts.

Generate the same record from the same evidence with another instance ID, then compare:

```bash
python3 scripts/arsenal_observe.py compare \
  --left .arsenal-observatory/dagger-flight-a.json \
  --right .arsenal-observatory/dagger-flight-b.json
```

Equivalent records may have different instance IDs and the same fingerprint.

A repository-state change, evidence change, capability version change, runtime version change, authority change, or outcome change should alter the fingerprint.

## Privacy default

The default policy is **metadata-first, content-off**.

The v0 record explicitly says:

```text
secrets_recorded             false
prompt_content_recorded      false
completion_content_recorded  false
chain_of_thought_recorded    false
```

Context sources are represented through IDs, paths, digests, and observed volume—not copied prompt bodies.

Raw content capture is not a hidden switch in v0. It requires a future explicit policy contract.

## Evidence remains independently verifiable

Normalization does not replace the source receipt.

Each accepted evidence item keeps:

- its source path;
- its SHA-256 digest;
- its claim scope;
- its limitations.

If the source receipt changes after the Flight Record is created, verification fails.

## OpenTelemetry boundary

ARS-07 defines an interoperability mapping only:

```text
Flight Record
→ trace
→ operation spans
→ log-based events for checkpoints/outcomes
```

Arsenal-specific attributes use `arsenal.*`, not the reserved `otel.*` namespace.

No collector, vendor, SDK, or dashboard is required to validate a Flight Record.

## What v0 deliberately does not fake

Current deterministic Dagger and Bench tracers do not involve a coding model, so their model provenance is `not-applicable`.

Token volume is likewise `not-applicable` for those layers.

When Arsenal captures a real agent/model run later, the same envelope can record observed model, harness, token, timing, and cost data. Until then those fields must remain explicit unknown/not-applicable values rather than invented telemetry.
