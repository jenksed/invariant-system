# GCP Overlay Fidelity Ledger

Reference runtime: `floci/floci-gcp:0.6.0`

| Service | Operation/protocol | Local evidence | Claim |
|---|---|---|---|
| Cloud Storage | Create bucket | official Google Cloud Python client succeeds through `STORAGE_EMULATOR_HOST` | protocol + narrow behavior verified locally |
| Cloud Storage | Upload/download object | source bytes round-trip and SHA-256 matches | protocol + content behavior verified locally |
| Pub/Sub | Create topic/subscription | official Pub/Sub client succeeds through emulator host | protocol + narrow behavior verified locally |
| Pub/Sub | Publish/pull/ack | explicit work item is published, pulled, and acknowledged | protocol + narrow behavior verified locally |
| Cloud Storage | Write/read result | deterministic result matches bucket/key/bytes/SHA-256 | behavior verified locally |

## Not established

This does not establish Google IAM enforcement, service-account policy, production token behavior, quotas, project/org policy, regionality, production durability, billing, networking, or provider timing/eventual consistency.
