# Snapshot Acceleration Policy

Status: draft

Floci snapshots are optional acceleration caches, not authoritative completion state.

## Capability precondition

Do not infer server-side snapshot support from CLI syntax or documentation alone.

At the FLC-02 audit point on 2026-08-08, the latest published Floci AWS server release is `1.5.34`. Its released server does not implement `/_floci/snapshots/...`; a POST to that path falls through to S3 routing and returns the S3 `InvalidArgument` response:

`POST requires either ?uploads, ?uploadId, ?restore or ?select parameter.`

The Floci CLI documents AWS snapshot save/load commands, so Project Arsenal treats snapshots as a capability that must be proven against the running server before it can participate in a gate.

An unavailable snapshot capability is **not** an IaC completion failure. It must be recorded explicitly as `UNSUPPORTED`/`SKIP`, and the authoritative zero-state provision + independent assertions + destroy path must still pass.

An unexpected snapshot error is a real failure and must not be downgraded to `UNSUPPORTED`.

## Rule

When the running server supports snapshots, a snapshot may reduce repeated fixture construction only when its provenance can be recomputed and matched exactly enough for the engineering question.

A clean zero-state reconstruction remains the completion authority in every case.

## Required cache-key inputs

At minimum include:

- Floci image/tag or stronger runtime provenance;
- IaC engine/version or pinned execution image;
- provider version/lock input;
- fixture/module digest;
- runtime/Compose configuration digest;
- any seed/init input that materially affects the restored state.

If an input changes, invalidate the snapshot.

## Restore contract

When snapshot support is available, a restore must:

1. find snapshot metadata;
2. recompute the current key;
3. refuse on mismatch;
4. load the snapshot;
5. rerun direct state/behavior assertions.

Do not silently regenerate metadata to make a stale snapshot appear valid.

## Reference implementation

`scripts/snapshot-cache` attempts the documented AWS control-plane shapes:

- `POST /_floci/snapshots/<name>` — save;
- `POST /_floci/snapshots/<name>/load` — load.

For `save`, the script distinguishes the exact known released-server routing signature from other failures:

- known unavailable endpoint → exit `78`, preserve the response body as evidence, and allow the caller to record a capability skip;
- successful endpoint → write provenance metadata and permit the restore exercise;
- any other failure → nonzero error that fails the gate.

The sidecar metadata file is written beneath `.floci-artifacts/iac/snapshots/` only after a successful save.

When the capability is supported, FLC-02 exercises the policy by:

1. applying the HCL tracer;
2. saving a snapshot;
3. resetting Floci;
4. proving tracer resources are absent;
5. restoring only with matching metadata;
6. rerunning direct resource assertions.

When the capability is unavailable, FLC-02 instead:

1. records the unsupported capability evidence;
2. reruns direct assertions to prove the failed capability probe did not mutate the applied state;
3. proceeds through IaC destroy and post-destroy absence assertions.

## What snapshots do not prove

A restored snapshot does not prove:

- the IaC still provisions from zero;
- the provider can recreate the resources after a version change;
- migrations are valid;
- production cloud behavior;
- cross-version state compatibility unless explicitly tested.

Any workflow that only passes from a snapshot but fails from zero is not complete.
