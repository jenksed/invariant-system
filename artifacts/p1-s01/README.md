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
