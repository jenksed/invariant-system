# ADR-0024: Use complete text after-images for first Patches

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Proposed on `work/p0-w23-patch-approval-mutation`  
**Date:** 2026-07-28  
**Work package:** P0-W23  
**Depends on:** P0-W21 and P0-W22

## Context

Kiln's first useful workflow must review and apply one exact source change in one selected checkout. It needs a Patch representation that is deterministic, digestible, bound to exact Repository state, safe to approve, and recoverable after partial effects.

Unified diffs are effective review artifacts and interchange formats, but hunk application can introduce context matching, offset, whitespace, and reject semantics. The first-month product does not need arbitrary third-party Patch compatibility, binary Patches, renames, mode changes, or worktree merging.

## Decision drivers

- Bind Approval to exact final content.
- Avoid fuzzy or context-dependent mutation.
- Make stale-base detection explicit.
- Prepare complete rollback data before mutation.
- Keep the first mutation path text-only and bounded.
- Separate human review from authoritative application.
- Support deterministic restart classification.
- Avoid Git staging, commit, merge, and worktree scope.

## Considered options

### Option A: Canonical complete after-images

Represent each add or replace with the complete target text content digest and each delete with exact before-state absence intent. Generate a unified diff for review.

Advantages:

- exact target content;
- stable canonical digest;
- no hunk fuzz or offset;
- straightforward before and after observation;
- complete rollback data is explicit;
- simple add, replace, and delete contract.

Disadvantages:

- larger payloads than hunks;
- first-month size limits are necessary;
- large and binary files need later paths.

### Option B: Unified diff as authority

Advantages:

- familiar;
- compact for small changes;
- common Tool output.

Disadvantages:

- application semantics vary;
- fuzzy matching and whitespace options can change results;
- exact target content is indirect;
- partial reject handling adds complexity;
- harder to bind Approval to final bytes without applying in a sandbox first.

### Option C: Git tree or index object mutation

Advantages:

- Git-native object identity and tree operations.

Disadvantages:

- introduces index, object-writing, staging, and commit-adjacent concepts;
- can diverge from the selected worktree state;
- exceeds the first-month local file-mutation requirement.

### Option D: AST or structured edits

Advantages:

- semantic transformations for supported languages.

Disadvantages:

- language-specific;
- requires parser and formatter decisions;
- does not cover general Repository text;
- code intelligence is deferred.

## Decision

Select Option A.

The first Patch contract:

1. Uses a canonical manifest of `add`, `replace`, and `delete` operations.
2. Supports only regular UTF-8 text files.
3. Stores complete add and replacement after-images as content-addressed Artifacts.
4. Binds replace and delete operations to exact before digests.
5. Binds the whole Patch to one W22 Repository observation and state digest.
6. Computes one SHA-256 digest over canonical manifest bytes and ordered after-image digests.
7. Generates a deterministic unified diff for review only.
8. Does not use unified diff, fuzzy matching, offset search, whitespace relaxation, or reject files as mutation authority.
9. Represents renames as delete-plus-add without rename identity.
10. Denies binary, symlink, special-file, mode, submodule, Git metadata, and out-of-root changes.
11. Applies no more than 32 paths and four MiB of total after-image content in the first contract.
12. Requires complete verified rollback data before the P0-W21 operation intent commits.

## Consequences

### Positive

- Approval binds exact target bytes.
- Stale and unexpected file state is deterministic.
- Application and rollback can compare before and after digests directly.
- Model-generated diffs cannot directly mutate files.
- Prompt 6-A can create narrow Patch and Approval contract fixtures.

### Negative

- Complete content can use more storage and Context than hunks.
- Large files are blocked.
- Rename and mode intent is not preserved.
- A multi-file filesystem update is not atomic and requires progress and rollback handling.

### Neutral or operational

- Unified diff remains the normal user review view.
- P0-W24 formatting and verification occur after Patch application as separate Commands.
- A later accepted contract can add binary, structured, or Git-object mutation without changing historical Patch manifests.

## Evidence and assumptions

### Observed evidence

- The first-month product supports one selected writable checkout and one mutation owner.
- P0-W22 already supplies canonical paths, state digests, bounded text reads, and `change.propose`.
- Existing production code has no Patch implementation or compatibility constraint.

### Inference

Complete text after-images are the smallest representation that makes the target state and Approval subject exact without needing a second application engine.

### Unknowns

- Measured storage and preview cost under real Single-Run Alpha changes.
- Exact supported-host filesystem replacement and fsync behavior, which OD-02 and authorized implementation must verify.
- Whether later language-aware edits justify a second proposal adapter.

## Verification

The authorized Patch ticket must prove:

- canonical digest stability;
- exact before and after binding;
- no fuzzy application;
- deterministic preview;
- size and path denials;
- complete rollback preparation;
- add, replace, and delete target observation;
- partial failure and reverse rollback;
- crash classification into exact base, exact target, or unknown state;
- no automatic reapplication, Command, Git staging, commit, push, merge, or publication.
