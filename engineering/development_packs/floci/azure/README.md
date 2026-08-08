# Floci Azure Overlay

FLC-04 Azure tracer. This overlay proves the universal Local Cloud process does not require AWS endpoint, region, account, or access-key concepts.

## Pin

`floci/floci-az:0.10.0`

## Local contract

- REST port: `4577`
- readiness: `GET /health`
- storage account: Azurite-compatible `devstoreaccount1`
- Blob endpoint: `http://localhost:4577/devstoreaccount1`
- Queue endpoint: `http://localhost:4577/devstoreaccount1-queue`
- credential material: a runtime-generated, non-secret local SharedKey inside an Azurite-compatible connection string
- Functions are disabled for this tracer; no Docker socket is required.

## Golden path

`Blob input -> explicit Queue work item -> host worker -> Blob result`

The worker downloads the source blob, computes byte count and SHA-256, writes a deterministic JSON result blob, deletes the queue message, and independently reads the result back.

## Run

```bash
cp env.floci-az.example .env.floci-az
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

Every client path is guarded against public Azure storage endpoints. The committed fixture contains no Azure development or production key; a synthetic base64 key is generated locally at runtime, which is sufficient because Floci-AZ development mode parses the account name but does not verify the SharedKey signature. A missing or non-loopback Blob/Queue endpoint is a hard failure; there is no public-cloud fallback.

## Evidence boundary

See `FIDELITY_LEDGER.md`. Passing this tracer is local protocol/behavior evidence only. It is not Azure subscription, RBAC, SharedKey-verification, durability, quota, regional, or billing proof.
