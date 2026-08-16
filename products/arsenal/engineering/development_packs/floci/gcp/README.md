# Floci GCP Overlay

FLC-04 GCP tracer. The overlay preserves GCP's project and emulator-host model instead of translating it into AWS region/account terminology.

## Pin

`floci/floci-gcp:0.6.0`

## Local contract

- port: `4588`
- project: `floci-local`
- GCS: `STORAGE_EMULATOR_HOST=http://localhost:4588`
- Pub/Sub: `PUBSUB_EMULATOR_HOST=localhost:4588`
- credential mode: anonymous/no real GCP credentials
- storage mode: memory for clean CI replay.

## Golden path

`GCS input -> explicit Pub/Sub work item -> host worker -> GCS result`

The official Google Cloud Python clients create the buckets/topic/subscription, publish and pull one work item, round-trip source bytes, write a deterministic result, acknowledge the message, and independently read the result back.

## Run

```bash
cp env.floci-gcp.example .env.floci-gcp
python3 -m pip install -r requirements.txt
./scripts/start
./scripts/verify-inner
./scripts/run-tracer
```

Completion from zero:

```bash
./scripts/verify-completion
```

## Safety

The overlay requires explicit loopback emulator hosts for both GCS and Pub/Sub. Missing or public hosts fail before the SDK clients are invoked.

## Evidence boundary

See `FIDELITY_LEDGER.md`. Passing locally does not prove production GCP IAM, quotas, project/org policy, regionality, durability, billing, or managed-service timing.
