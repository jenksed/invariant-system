# Floci OCI Overlay

FLC-04 OCI tracer. The overlay keeps OCI tenancy, namespace, and service-endpoint concepts intact rather than converting them into another provider's account/project model.

## Pin

`floci/floci-oci:0.2.0`

## Local contract

- port: `4599`
- readiness: `GET /_floci-oci/health`
- Object Storage namespace: `floci-local`
- default synthetic tenancy: `ocid1.tenancy.oc1..flocilocaltenancy...`
- endpoint: `http://localhost:4599`
- this tracer disables signature enforcement and uses the emulator's documented unsigned default-tenancy behavior
- Functions are mocked so the Object Storage tracer needs no Docker socket sidecar.

## Golden path

`Object Storage namespace -> source bucket/object -> deterministic result bucket/object`

Unlike AWS/Azure/GCP, this tracer intentionally does not manufacture a messaging hop merely for symmetry. It proves the shared verification/evidence lifecycle can accommodate a provider-specific scenario without erasing OCI semantics.

## Run

```bash
cp env.floci-oci.example .env.floci-oci
./scripts/start
./scripts/verify-inner
./scripts/run-tracer
```

Completion from zero:

```bash
./scripts/verify-completion
```

## Safety

Only loopback `4599` endpoints are accepted. No OCI config/profile or real API key is required. Public OCI endpoints are rejected before the tracer runs.

## Evidence boundary

See `FIDELITY_LEDGER.md`. The unsigned local mode is an explicit fidelity limitation, not a claim that OCI authentication is equivalent locally.
