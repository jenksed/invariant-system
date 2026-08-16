# ADR-0027: Ship an arm64 macOS Mix release first

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Integrated through pull request 33  
**Date:** 2026-07-28  
**Work package:** P0-W25  
**Depends on:** OD-02 and ADR-0022/0026

## Context

Kiln will include ERTS, Exqlite native code, and an arm64 macOS process-group helper. The first product needs a user-local CLI package that does not require a system Elixir installation at runtime and does not imply cross-platform compatibility.

Mix releases package the application, dependencies, and ERTS. Official Mix documentation requires target architecture, operating system/vendor, and ABI compatibility, including native dependencies.

## Decision drivers

- support only OD-02 Apple Silicon macOS;
- include ERTS and native dependencies;
- provide one `kiln` CLI;
- no root or daemon;
- explicit checksum and build provenance;
- side-by-side local versions;
- no auto-update or broad package ecosystem before the workflow works.

## Considered options

### Option A: Mix release

Advantages:

- includes ERTS and application dependencies;
- standard Elixir release mechanism;
- supports native dependencies for one target;
- provides a stable package boundary.

Disadvantages:

- target-specific build;
- larger than an escript;
- release and native helper packaging must be tested.

### Option B: escript

Advantages:

- simple single entry file for pure BEAM tools.

Disadvantages:

- still depends on compatible Erlang runtime;
- awkward for Exqlite and a native host helper;
- not the selected self-contained delivery boundary.

### Option C: require `mix run`

Advantages:

- easy during development.

Disadvantages:

- requires source checkout, build toolchain, and matching dependencies;
- not a product delivery contract.

### Option D: Homebrew formula or macOS package

Advantages:

- familiar installation.

Disadvantages:

- adds publication, signing, update, and ecosystem work before product proof;
- can imply support breadth not yet earned.

## Decision

Select Option A.

1. Build one `kiln` Mix release for `arm64-apple-darwin` with a macOS 15.0 baseline.
2. Include ERTS, Kiln, Exqlite native code, and the arm64 command-host helper.
3. Build on a clean supported host and record the exact host, toolchain, native dependency, and helper identities.
4. Publish a `.tar.gz`, SHA-256 file, and canonical build manifest.
5. Install user-locally under `~/Library/Application Support/Kiln/releases/<version>/`.
6. Use `~/.local/bin/kiln` as an explicit user-controlled launcher link.
7. Install versions side by side and update a `current` link only after compatibility and doctor checks.
8. Do not require root, a daemon, Homebrew, notarization, auto-update, or a public installer initially.
9. Do not claim Linux, Windows, Intel macOS, or universal binary support.
10. `Kiln.version/0` derives from application or release metadata rather than an independent literal.

## Consequences

### Positive

- runtime and native dependencies are packaged together for one known target;
- installation does not require system Elixir or Erlang;
- host compatibility remains explicit;
- upgrades can retain prior release binaries and durable state.

### Negative

- the package is target-specific;
- public download UX and Gatekeeper handling are not yet productized;
- build reproducibility and package verification require later implementation Evidence.

### Neutral or operational

- source builds remain available to developers but are not the delivery contract.
- code signing and notarization can be reconsidered before wider public distribution.
- release rollback cannot downgrade an incompatible migrated state store.

## Verification

The authorized delivery ticket must prove:

- clean arm64 macOS release build;
- ERTS, Exqlite, and helper inclusion;
- build manifest and checksum correctness;
- user-local install and invocation;
- doctor and version behavior;
- side-by-side upgrade;
- state preservation;
- no root, daemon, auto-update, or unsupported-host claim.
