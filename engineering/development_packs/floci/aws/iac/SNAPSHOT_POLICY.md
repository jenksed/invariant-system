# Snapshot Acceleration Policy

Status: draft

Floci snapshots are acceleration caches, not authoritative completion state.

## Rule

A snapshot may reduce repeated fixture construction only when its provenance can be recomputed and matched exactly enough for the engineering question.

A clean zero-state reconstruction remains the completion authority.

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

A restore must:

1. find snapshot metadata;
2. recompute the current key;
3. refuse on mismatch;
4. load the snapshot;
5. rerun direct state/behavior assertions.

Do not silently regenerate metadata to make a stale snapshot appear valid.

## Reference implementation

`scripts/snapshot-cache` uses Floci's native AWS control-plane endpoints:

- `POST /_floci/snapshots/<name>` — save;
- `POST /_floci/snapshots/<name>/load` — load.

The script writes a sidecar metadata file beneath `.floci-artifacts/iac/snapshots/`.

FLC-02 exercises the policy by:

1. applying the HCL tracer;
2. saving a snapshot;
3. resetting Floci;
4. proving tracer resources are absent;
5. restoring only with matching metadata;
6. rerunning direct resource assertions.

## What snapshots do not prove

A restored snapshot does not prove:

- the IaC still provisions from zero;
- the provider can recreate the resources after a version change;
- migrations are valid;
- production cloud behavior;
- cross-version state compatibility unless explicitly tested.

Any workflow that only passes from a snapshot but fails from zero is not complete.
