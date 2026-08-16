# Cloud Fidelity Ledger

Status: draft

A **Cloud Fidelity Ledger** records what a local cloud environment can legitimately prove for one engineering path.

It exists to prevent a common evidence error: treating a successful emulator run as proof of every corresponding real-cloud semantic.

## Ledger unit

Record fidelity at the smallest useful unit:

`provider → service → operation/protocol → required behavior → emulator support → known deviation → evidence consequence`

Do not use aggregate service counts as the acceptance boundary. Service lists change, individual operations mature at different rates, and one unsupported semantic can invalidate an otherwise broad claim.

## Required fields

For every cloud-dependent acceptance path, capture:

- provider and region assumptions;
- emulator implementation and version/tag/commit when material;
- service;
- exact API operation, wire protocol, or data-plane interface exercised;
- SDK/CLI/IaC client and version when relevant;
- required behavior being asserted;
- support evidence source and retrieval date;
- known limitations or semantic differences;
- local result;
- evidence class earned;
- whether real-cloud verification remains required.

## Evidence classes

Use these labels consistently:

### Protocol verified

The request shape, endpoint routing, authentication placeholder, serialization, and client integration worked through the emulator.

This does not by itself prove the service's behavior.

### Behavior verified

The requested effect and externally observable state transition occurred under the local environment.

This remains scoped to the emulator's semantics.

### Fidelity scoped

The relevant operation support and documented limitations were checked close enough to execution time that the local result can be interpreted responsibly.

This is not a claim of perfect parity.

### Cloud verified

The path was independently exercised against the real provider under the required account/region/policy conditions.

Only use this label when that execution actually happened.

## Confidence rule

A ledger entry should lower confidence when:

- the emulator documents the operation as partial, stubbed, stored-but-inert, mock-only, or out of scope;
- the behavior depends on provider IAM, quotas, eventual consistency, billing, networking, regional availability, or control-plane timing the emulator does not reproduce;
- the support source is stale relative to a fast-moving emulator release;
- the test only checks a successful response rather than the required effect;
- the implementation swaps a real engine for a simplified model on the exercised path.

## Freshness rule

Fidelity information is versioned evidence, not timeless documentation.

Before a completion claim that materially depends on emulator parity:

1. identify the emulator version or source revision under test;
2. consult the most specific current service/operation documentation available;
3. record the retrieval date;
4. record any conflict between overview pages and operation-specific references;
5. prefer operation-specific documentation and executable compatibility tests over marketing summaries.

## Example

| Field | Value |
|---|---|
| Provider | AWS |
| Service | STS |
| Operation | `AssumeRole` |
| Required behavior | Reject caller when trust policy requires an unmet `ExternalId` condition |
| Emulator result | Request succeeds |
| Known deviation | Emulator does not evaluate trust-policy `Condition` blocks |
| Evidence consequence | Local run cannot prove ExternalId enforcement; real AWS or another authoritative verification is required |

The correct conclusion is not "STS failed locally." The correct conclusion is that this acceptance claim lies outside the emulator's fidelity boundary.

## Completion criterion

The ledger is sufficient when a reviewer can understand what the local test proved, what it did not prove, why the emulator result is trustworthy for the claimed scope, and exactly which remaining claims require another verification surface.