# Floci Multi-Cloud Source Audit

Audit date: 2026-08-08

Purpose: bound FLC-04's provider overlays with current upstream evidence and preserve the differences that a universal cloud abstraction would otherwise erase.

## Release pins observed

| Provider | Upstream project | Pin used by FLC-04 | Local port |
|---|---|---:|---:|
| Azure | `floci-io/floci-az` | `0.10.0` | `4577` |
| GCP | `floci-io/floci-gcp` | `0.6.0` | `4588` |
| OCI | `floci-io/floci-oci` | `0.2.0` | `4599` |

AWS remains the existing FLC-01 reference on port `4566`; FLC-04 does not replace that pack.

## Azure findings

The Azure emulator exposes Azure/Azurite-shaped storage routing rather than an AWS-style global endpoint contract. The FLC-04 tracer therefore keeps:

- storage account `devstoreaccount1`;
- Blob path routing under `/{account}`;
- Queue path routing under `/{account}-queue`;
- Azure SDK connection-string configuration;
- `GET /health` readiness.

Source inspection of Floci-AZ 0.10.0 `SharedKeyAuthVerifier` shows development mode accepts any SharedKey signature after parsing the account name. FLC-04 therefore generates a deterministic non-secret local key at runtime instead of committing the well-known Azurite development key. This proves Azure SDK request shaping and local routing but **not** Azure SharedKey signature verification.

GitHub repository secret scanning rejected an earlier attempted tree containing the well-known Azurite development key. The durable rule is stronger than merely calling that value public test data: credential-shaped emulator material should be generated at runtime when the emulator does not require the canonical key.

Azure Functions are disabled in this tracer. Docker-backed Functions fidelity is not claimed.

## GCP findings

Floci-GCP 0.6.0 uses provider-native emulator hosts and project identity:

- `STORAGE_EMULATOR_HOST=http://localhost:4588`;
- `PUBSUB_EMULATOR_HOST=localhost:4588`;
- synthetic project `floci-local`;
- anonymous local credentials for the FLC-04 tracer.

The release added/strengthened IAM Credentials, GCS authentication, Pub/Sub filtering, and cross-repository convergence with the AWS baseline. FLC-04 nevertheless keeps GCP fidelity independent: shared implementation ancestry does not make AWS and GCP service semantics interchangeable.

The tracer uses official Google Cloud Python clients for GCS bucket/object and Pub/Sub topic/subscription/message operations. It does not claim real service-account IAM enforcement or provider token behavior.

## OCI findings

Floci-OCI 0.2.0 exposes OCI-shaped service APIs on port `4599`. The FLC-04 Object Storage tracer preserves:

- `GET /_floci-oci/health` readiness;
- namespace `floci-local`;
- synthetic/default tenancy context;
- Object Storage routes such as `GET /n`, `POST /n/{namespace}/b`, and `PUT/GET /n/{namespace}/b/{bucket}/o/{object}`.

Upstream documentation states unsigned requests can fall back to the configured default tenancy. FLC-04 makes that limitation explicit with `FLOCI_OCI_AUTH_REQUIRE_SIGNATURE=false`; the tracer validates Object Storage routing/content behavior but does not claim OCI API-key signature enforcement or IAM policy fidelity.

The OCI scenario intentionally does not add a fake queue hop merely to resemble the AWS/Azure/GCP tracers. Provider neutrality means sharing evidence discipline while allowing different provider-specific golden paths.

## Cross-provider conclusion

The universal Local Cloud layer can remain limited to:

1. provider discovery;
2. lowest-blast-radius local execution;
3. fail-closed endpoint configuration;
4. pinned runtime + readiness;
5. deterministic fixtures;
6. provider-shaped operations;
7. independent post-operation assertions;
8. operation-level fidelity accounting;
9. completion receipts;
10. teardown and explicit provider-only escalation.

It does **not** need a universal account/project/subscription/tenancy model, universal region variable, universal credential type, or universal service graph.

## Runtime validation findings

FLC-04's first live CI run exposed a shared evidence-capture defect rather than three provider defects. Each provider tracer completed and reached its PASS print, but `verify-completion` piped `run-tracer` through `head -n1` under `set -o pipefail`; `head` closed the pipe after the JSON result and the final PASS `printf` failed with SIGPIPE.

The fix captures the complete tracer output first, requires the explicit provider PASS marker, then extracts the first line with Bash parameter expansion. This avoids truncating a live producer and makes the shared completion machinery itself evidence-checked.

## Claim boundary

FLC-04 can claim that Azure, GCP, and OCI all satisfy the same **engineering lifecycle contract** through provider-specific local paths. It cannot claim semantic equivalence among their services or production-cloud verification for identity, authorization, quotas, regionality, durability, billing, managed-service timing, networking, or any operation not exercised by the corresponding ledger.

## Primary upstream evidence

- `floci-io/floci-az` release/docs/source at `0.10.0`.
- `floci-io/floci-gcp` release/docs at `0.6.0`.
- `floci-io/floci-oci` release/docs/source at `0.2.0`.
- Existing Project Arsenal `docs/source_audits/floci.md` for the AWS/FLC-00–03 baseline.
