# Local Cloud Provider Completion Receipt

Provider: `<provider>`
Overlay: `<path>`
Floci image: `<image:tag>`
Runtime version/provenance: `<observed value>`
Local endpoint(s): `<approved local endpoint(s)>`
Authentication/credential mode: `<synthetic/connection-string/unsigned/local-key/...>`
Fixture: `<fixture name or digest>`

## Operations exercised

| Service | Operation/protocol | Assertion | Evidence label |
|---|---|---|---|
| `<service>` | `<operation>` | `<observable assertion>` | `<protocol/behavior/fidelity/cloud>` |

## Deterministic result

`<result identity, byte count, digest, or other stable assertion>`

## Fidelity boundary

Ledger: `<path>`

Provider-only residue:

- `<claim that still requires the real provider>`

## Cleanup

- Local resources cleaned: `<yes/no>`
- Emulator/container removed: `<yes/no>`
- Real-provider mutation performed: **no**
