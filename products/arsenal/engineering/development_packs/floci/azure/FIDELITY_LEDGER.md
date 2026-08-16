# Azure Overlay Fidelity Ledger

Reference runtime: `floci/floci-az:0.10.0`

| Service | Operation/protocol | Local evidence | Claim |
|---|---|---|---|
| Blob Storage | Create container | official Azure Python SDK succeeds through path-routed local endpoint | protocol + narrow behavior verified locally |
| Blob Storage | Upload/download blob | source bytes round-trip and SHA-256 matches | protocol + content behavior verified locally |
| Queue Storage | Create queue | official Azure Python SDK succeeds | protocol + narrow behavior verified locally |
| Queue Storage | Send/receive/delete message | one explicit work item round-trips and is deleted after processing | protocol + narrow behavior verified locally |
| Blob Storage | Write/read result | deterministic JSON result matches container/key/bytes/SHA-256 | behavior verified locally |

## Authentication boundary

The overlay generates a deterministic, non-secret local SharedKey value at runtime. In Floci-AZ 0.10.0 development mode, SharedKey parsing accepts any signature after extracting the account name. The tracer therefore proves SDK request shaping/routing, **not** Azure SharedKey signature validation.

## Not established

This ledger does not establish Azure Entra authentication, SharedKey verification, RBAC, subscription/account policy, quotas, geo-replication, production durability, service latency, billing, private networking, or provider-specific eventual consistency. Azure Functions are disabled in this tracer so no Docker-backed Functions fidelity is claimed.
