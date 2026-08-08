# Floci Development Pack

Status: draft

The Floci Development Pack adapts Project Arsenal's Local Cloud Engineering foundations and Development Pack contract to the Floci emulator family.

It is intentionally **local-cloud first, provider-truth conservative**: use Floci aggressively for safe implementation and deterministic evidence, but never claim a real provider behavior that the local fidelity evidence does not establish.

## Authority

This pack composes:

- `engineering/development_packs/CONTRACT.md`
- `foundations/local_cloud_emulation.md`
- `foundations/cloud_execution_boundary.md`
- `foundations/cloud_fidelity_ledger.md`
- `foundations/reproducible_cloud_fixtures.md`
- `docs/source_audits/floci.md`

Floci's current service/operation documentation remains authoritative for what Floci itself supports. This pack must not freeze a copied service matrix.

## Scope

FLC-00 establishes the pack contract and AWS-first design. It does not yet install a complete project adapter or claim stable multi-cloud coverage.

The mature pack should support:

- detecting existing Floci/LocalStack/cloud configuration;
- selecting the provider emulator and local endpoint explicitly;
- safe credential/environment setup;
- reproducible initialization fixtures;
- ephemeral CI and optionally persistent local development;
- deterministic readiness checks;
- provider-shaped SDK/CLI/IaC execution;
- operation-level fidelity recording;
- three verification tiers;
- explicit real-cloud escalation when a required semantic is outside Floci's fidelity boundary.

## Design principles

### 1. Floci is an adapter, not a foundation

Universal local-cloud methods remain independent of Floci. A future emulator can implement the same Arsenal contract without rewriting the foundation.

### 2. AWS is the tracer implementation

Start with AWS because Floci's AWS surface is currently deepest and exposes enough real fidelity edge cases to pressure-test the model.

Azure, GCP, and OCI are follow-on provider overlays. Do not force a lowest-common-denominator abstraction prematurely.

### 3. Exact operations beat service-count claims

Before relying on a local result, identify the required service and operation/protocol and consult the most specific current Floci evidence.

If an operation is unsupported, partial, stubbed, stored-but-inert, mock-only, or behaviorally divergent, encode that in the fidelity ledger and adjust the evidence claim.

### 4. Fail closed on endpoints

Pack-provided commands and fixtures should make the local endpoint explicit and verify it before mutation.

Never design a wrapper where an unset endpoint silently sends a request to the normal public provider endpoint.

### 5. Pin completion evidence

Floating image tags are acceptable for exploratory inner loops when a project chooses that tradeoff. Slice/completion evidence should identify the exact Floci version/tag/digest or source revision used.

### 6. Reset is part of verification

A green result against unknown accumulated local state is not completion-quality evidence.

The pack should make clean startup, fixture application, readiness, teardown/reset, and replay straightforward.

## AWS baseline

The current documented AWS local baseline is:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

These values are Floci pack defaults, not application configuration that should leak into production.

Prefer wrappers or test configuration that assert the expected loopback endpoint before mutating resources.

## Storage profiles

Recommended intent profiles:

- **CI / clean replay:** `memory`
- **interactive local development:** `hybrid` unless the repository has a reason to choose another mode
- **durability-sensitive local testing:** explicit `persistent` or `wal` with cleanup/provenance rules

Do not rely on undocumented/default storage behavior.

## Fixture lifecycle

For AWS, use Floci's ordered initialization phases where suitable:

- `boot` — host/storage setup before AWS APIs are available;
- `start` — service API available;
- `ready` — all start hooks completed; preferred gate before tests;
- `stop` — cleanup while the HTTP surface still exists.

When fixture scripts need the AWS CLI or boto3 inside the container, use the documented compat image or install equivalent tooling deliberately. Do not assume the standard image includes them.

## Verification model

See `VERIFICATION_CONTRACT.md` for the pack's inner-loop, slice-gate, and completion-gate requirements.

The completion gate should normally produce a compact receipt containing:

- Floci implementation/version;
- provider/endpoint;
- storage/reset mode;
- fixture source or snapshot provenance;
- readiness evidence;
- test/command results;
- material resulting-state assertions;
- fidelity-ledger entries for the cloud path;
- remaining real-cloud verification, if any.

## Fidelity model

See `FIDELITY_POLICY.md`.

A local green run can earn protocol, behavior, and fidelity-scoped evidence. It cannot earn `Cloud verified` without actual provider execution.

## Roadmap

See `ROADMAP.md` for the implementation slices that turn this contract into an operational suite.

## Completion criterion for this pack

The Floci pack is mature when a normal cloud-dependent code change can move from repository discovery through local setup, deterministic fixture creation, implementation, replayable verification, fidelity interpretation, and evidence handoff without repeated model judgment for mechanically decidable state—and without accidental access to a real cloud account.