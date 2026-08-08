# Floci Provider Overlay Contract

Status: draft

FLC-04 proves that Project Arsenal's Local Cloud methods are provider-neutral without pretending cloud providers have interchangeable semantics.

## Contract boundary

The shared layer standardizes only the engineering lifecycle and evidence shape:

1. discover the provider from repository/task evidence;
2. choose the provider-owned local execution boundary;
3. fail closed before any provider-shaped client can reach a public endpoint;
4. start a pinned emulator from clean state;
5. wait on the provider's own readiness surface;
6. construct a minimal source-controlled fixture;
7. exercise real provider-shaped client or wire operations;
8. assert post-operation state independently;
9. write an operation-level fidelity ledger and completion receipt;
10. tear the local environment down without real-cloud fallback.

The shared layer MUST NOT invent a universal resource model for buckets, accounts, projects, regions, subscriptions, tenancies, credentials, queues, functions, or IAM.

## Required overlay fields

Every provider overlay MUST state:

- provider identifier;
- pinned Floci image and version;
- approved local endpoint(s);
- credential/authentication mode;
- provider-native environment variables or connection material;
- readiness endpoint or deterministic readiness probe;
- fixture/reset strategy;
- golden-path scenario;
- exact provider services/operations exercised;
- unsupported or provider-only semantics;
- inner, slice, and completion gates;
- evidence artifact location;
- cleanup boundary.

## Verification tiers

### Inner loop

Prove the local runtime is reachable through the approved endpoint and the provider client is configured for local execution.

### Slice gate

Run the smallest provider-shaped behavior required by the fixture and assert its result.

### Completion gate

Reconstruct from zero, rerun the golden path, record emulator/runtime provenance, emit a receipt, and tear down.

The names are shared. The commands and service semantics belong to each provider overlay.

## Endpoint hard stop

Each overlay owns a provider-specific endpoint guard. A guard MUST reject a configuration that could route the tested client to the public provider.

Examples of deliberately non-unified local contracts:

- AWS: explicit endpoint + synthetic access keys + region.
- Azure: Azurite-compatible storage connection string with path-routed Blob/Queue endpoints.
- GCP: emulator-host variables and synthetic project identity.
- OCI: explicit service endpoint with synthetic/default tenancy context; authentication enforcement is a separate fidelity question.

No provider may silently fall back to public cloud when its local endpoint is absent or invalid.

## Fidelity rule

The durable fidelity key is:

`provider -> service -> operation/protocol -> required semantic`

A passing Azure Blob operation says nothing about GCS, OCI Object Storage, or S3 beyond the shared engineering process. Even similarly named services retain independent ledgers.

## Completion receipt

Every provider completion receipt MUST include at minimum:

- provider;
- image tag;
- local endpoint(s);
- auth/credential mode;
- fixture identity;
- services/operations exercised;
- observed deterministic result;
- evidence label(s);
- fidelity ledger path;
- provider-only residue;
- cleanup result.

Use `PROVIDER_RECEIPT.md` as the common schema while allowing provider-specific fields.

## Anti-abstraction test

An overlay is invalid if it requires one provider's vocabulary to explain another provider's local contract. In particular, Azure subscriptions/accounts, GCP projects, OCI tenancies/compartments, and AWS accounts/regions remain provider concepts.
