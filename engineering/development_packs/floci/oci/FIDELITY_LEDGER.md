# OCI Overlay Fidelity Ledger

Reference runtime: `floci/floci-oci:0.2.0`

| Service | Operation/protocol | Local evidence | Claim |
|---|---|---|---|
| Object Storage | Get namespace | standard OCI Object Storage path returns `floci-local` | protocol + narrow behavior verified locally |
| Object Storage | Create bucket | provider-shaped `POST /n/{namespace}/b` succeeds in synthetic tenancy | protocol + narrow behavior verified locally |
| Object Storage | Put/Get object | source bytes round-trip and SHA-256 matches | protocol + content behavior verified locally |
| Object Storage | Put/Get result object | deterministic JSON result matches bucket/key/bytes/SHA-256 | behavior verified locally |

## Authentication boundary

This tracer explicitly runs with `FLOCI_OCI_AUTH_REQUIRE_SIGNATURE=false`. It proves routing and Object Storage behavior under the emulator's unsigned default-tenancy mode. It does **not** prove OCI request signing, IAM authorization, policy evaluation, or real tenancy identity.

## Not established

No claim is made for compartments/policies, API-key verification, quotas, region behavior, production durability, replication, billing, private networking, provider latency, or Object Storage consistency beyond the narrow exercised path.
