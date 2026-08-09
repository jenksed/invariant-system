# P1-S01 slice gate Artifacts

**Document type:** Artifact location contract

This directory is where `scripts/gates/slice-01` writes its structured result
and the P1-S01-V01 slice verification manifest.

## What lands here

```text
slice-01-<commit>.json           result and manifest for a clean tree at <commit>
slice-01-<commit>-dirty.json     result and manifest for a dirty tree at <commit>
```

Generated files are runtime output. They are not committed: `.gitignore`
excludes `/artifacts/`. This README is the only tracked file in the directory.

## Durable retrieval requirement

Ignored local output is not a durable locator. When a generated manifest is required completion Evidence, closeout must also record:

- the exact generating commit and dirty-state result;
- the manifest SHA-256;
- a durable retrievable location, such as a retained GitHub Actions artifact or an owner-approved release attachment;
- the remote object or artifact identifier;
- the retention or expiry condition; and
- the retrieval command or procedure available to a fresh authorized agent.

A local path plus digest preserves provenance but does not make the bytes reproducible from a fresh checkout.

### Legacy P1-S01 gap

The final owner-machine manifest documented at `slice-01-5792ffdd3af6c45f07e07b8334ce150ad642495b.json` was generated on the accepted OD-02 machine and ignored by Git. Its recorded digest is `sha256:94a5f9ec37dcc0fbb64444e5ad48fe73e9527ec8dbae9cff2e01faf5da5d68aa`, but current Repository authority does not contain a durable remote locator for those exact bytes.

CI run `31235964412` retained a separate synthetic-merge artifact. That artifact is useful CI Evidence but is not the owner-machine manifest: its owner-machine result is `not_run` and its aggregate result is `blocked`. Do not substitute it for the missing OD-02 file.

Until the exact owner-machine manifest is uploaded to an approved durable location and its digest is rechecked, a fresh agent must report the Evidence as historically recorded but not independently retrievable.

## Why the filename carries the commit

A gate result is meaningful only against the exact state it proved. The commit
appears in the filename, and the manifest binds the commit, the dirty
fingerprint, the toolchain, the migration fingerprint, and the fixture
fingerprint into a self-integrity digest. A result generated at one commit
therefore cannot be presented as proof of another: editing the recorded commit
invalidates the digest, and `Kiln.VerificationManifest.validate/1` rejects it.

A dirty tree produces a `-dirty` filename and an `overall` of at best
`blocked`, because the proved state is not the recorded commit.

## What a manifest here is not

The manifest is bounded implementation Evidence. It is not a product Receipt.
It does not satisfy a Task, complete a Run, record product acceptance, or
authorize a later slice. Those refusals are recorded as data in the
`not_authority` section and are checked during validation.
