# Execution Evidence, Structured Results, Artifacts, and Receipts

**Document type:** Focused specification  
**Decision status:** Owner-accepted direction  
**Integration status:** Proposed on P0-W15  
**Implementation status:** Not implemented  
**Contract version:** `kiln.execution_plane/v0`

This document is part of the authoritative P0-W15 execution-plane design. `docs/TRUSTWORTHY-EXECUTION-PLANE.md` defines the governing hierarchy and isolation policy.

## Evidence model

### Stage vocabulary

Kiln uses these stages precisely:

#### `Proposed`

A bounded change, Command, strategy, or decision has been described.

Required facts:

- proposal identity;
- producer;
- target scope;
- base state when applicable;
- immutable content or request digest.

`Proposed` does not mean that bytes changed or a Command started.

#### `Implemented`

The proposed change exists in the target Repository or accepted execution configuration.

Required Evidence:

- successful Patch transaction or another authorized mutation record;
- post-change Repository state;
- exact changed paths and hashes;
- no unresolved application conflict.

`Implemented` does not mean inspected, executed, verified, accepted, or delivered.

#### `Inspected`

An authorized deterministic or human inspection evaluated the implemented state.

Possible Evidence:

- deterministic diff inspection;
- static structure inspection;
- human review record;
- policy inspection;
- source-state observation.

Inspection records scope, method, findings, omissions, and state binding.

#### `Executed`

A registered Command or accepted exceptional shell request ran and produced an observed terminal result.

Required Evidence:

- immutable execution request;
- Environment and Repository bindings;
- start and termination observations;
- exit, timeout, cancellation, or orphan state;
- output and Artifact references.

`Executed` does not imply exit zero or successful verification.

#### `Verified`

One or more acceptance criteria were evaluated against the current target state and returned `PASS` with sufficient current Evidence.

Required Evidence:

- criterion identifiers;
- exact Repository and Environment bindings;
- verification method;
- structured or raw results;
- `PASS` status;
- freshness rule;
- no unresolved blocker for the verified scope.

A completed Verifier with `FAIL` or `BLOCKED` is not `Verified`.

#### `Accepted`

The user or an accepted policy decision approves the verified outcome for the stated Task scope.

Required facts:

- acceptance decision;
- actor or policy;
- accepted scope;
- current verification references;
- recorded warnings and exclusions;
- decision time.

A model, authoring Run, test runner, Receipt, or passing check cannot accept work unless policy explicitly grants that decision authority.

#### `Delivered`

The accepted result reached its intended destination and that delivery was observed.

Examples:

- integrated into protected trunk;
- exported to an accepted path;
- published through an authorized provider;
- deployed to an accepted Environment;
- handed off as a sealed Artifact package.

Required Evidence:

- destination identity;
- delivery operation;
- resulting destination state or artifact digest;
- delivery time;
- warnings and unresolved post-delivery work.

A local commit is not automatically delivered.

### Stage transition rules

The stages are monotonic facts about a scope, not one mutable status string.

A later stage can become stale when its state binding changes. The historical fact remains recorded.

Examples:

- a new source change can make `Verified` stale without erasing the earlier verification;
- an acceptance decision can be revoked or superseded without claiming that it never occurred;
- a delivery can succeed while post-delivery verification fails;
- an implemented change can be reverted and no longer be current.

Kiln must not use `done`, `success`, or `complete` when a more precise stage is available.

### Completion Claims

Every material completion Claim records:

- Claim statement;
- stage and scope;
- Task and criterion references;
- Repository and Environment bindings;
- supporting Evidence identifiers;
- conflicting or inconclusive Evidence;
- Evidence freshness;
- producer;
- recorded time.

A Claim without sufficient current Evidence remains unsupported.

An unsupported completion attempt creates a durable event and metric. It does not advance completion readiness.

### Evidence authority

Kiln evaluates Evidence using this default order:

1. machine-native structured result with verified schema and source binding;
2. machine-normalized result with retained raw Artifact and parser provenance;
3. deterministic Repository or Environment observation;
4. raw Command output with exact execution binding;
5. human inspection or acceptance observation;
6. external source observation;
7. model interpretation or summary.

This is not an absolute truth ranking.

A structured result loses authority when:

- its schema is invalid or unsupported;
- the producer is unknown;
- the report is partial without disclosure;
- paths do not map to the evaluated Repository;
- the report predates relevant changes;
- the Environment or dependency state differs;
- the parser dropped material records;
- the report contradicts stronger current observations.

A model interpretation remains a Claim even when it accurately summarizes stronger Evidence.

### Verification result

A verification result contains:

```text
verification ID
Verifier Run or deterministic service
Task and criterion IDs
subject Repository states
subject Change sets and Artifacts
Environment and dependency fingerprints
methods and Commands
structured-result references
Evidence references
status: PASS | FAIL | BLOCKED
failure and blocker details
coverage and omissions
freshness rule
recorded time
```

`BLOCKED` cannot be normalized to `FAIL` or `PASS`.

## Structured-result ingestion

### Purpose

Structured-result adapters convert accepted external formats into Kiln-native findings while preserving the original report as an Artifact.

An adapter records:

- format and version;
- producer and version;
- source Command and Environment;
- report digest;
- parser and adapter version;
- schema validation result;
- path mapping policy;
- records considered, accepted, skipped, invalid, and truncated;
- completeness;
- normalized findings;
- warnings and omissions.

### Normalized finding

A finding can include:

```text
finding ID
result kind
rule or test identifier
severity
status
message digest and bounded message
Repository and file location
symbol or region
expected and actual values when safe
criterion links
related findings
help or documentation reference
raw result Artifact and record locator
```

The normalized result does not discard the raw report.

### SARIF

Kiln supports SARIF 2.1.0 for compatible static-analysis, lint, quality, and security tools.

The adapter preserves:

- runs and tool components;
- rule identifiers;
- result levels and kinds;
- locations and regions;
- fingerprints and partial fingerprints;
- code flows when bounded;
- fixes as proposed data only;
- invocation status;
- original SARIF Artifact.

A SARIF `fix` does not apply itself. It can become a Patch proposal after independent path, authority, and base-state validation.

### Structured test reports

The first contract supports adapter-based ingestion rather than one universal test schema.

Candidate formats include:

- JUnit-style XML;
- ExUnit formatter output designed for Kiln;
- TAP where the producer contract is known;
- language-specific JSON test reports;
- browser test result formats.

Normalized test results preserve:

- suite and test identity;
- pass, fail, skip, todo, error, or blocked status;
- duration;
- retries and attempts;
- failure details;
- source location when available;
- captured output references;
- report completeness;
- shard or partition identity.

A partial shard cannot prove the complete test suite passed.

### Compiler diagnostics

Compiler ingestion records:

- compiler and version;
- target and profile;
- diagnostic code;
- severity;
- message;
- primary and related locations;
- emitted Artifact references;
- compilation exit result;
- incremental or cached status when known.

A clean compiler report proves only the accepted compilation scope.

### Linter output

Linter results can use SARIF or a dedicated adapter.

Kiln records applied configuration, rule set, baseline, ignored findings, and whether warnings affect the acceptance criterion.

### Security findings

Security result ingestion distinguishes:

- vulnerability finding;
- secret finding;
- dependency advisory;
- configuration finding;
- policy violation;
- exploitability or reachability Claim;
- accepted suppression or risk decision.

A scanner severity is an observation from that tool. Kiln does not convert it into an accepted risk decision automatically.

Sensitive evidence can use redacted normalized fields and restricted raw Artifacts.

### Browser traces

Browser trace ingestion can retain:

- scenario and browser identity;
- browser and driver versions;
- viewport and platform;
- navigation and action steps;
- console and network summaries;
- screenshots, video, DOM, and trace Artifacts;
- assertion results;
- timing;
- redaction status.

Browser traces can contain secrets and user data. Their default sensitivity is at least `confidential` until a policy classifies them otherwise.

### Build artifacts

A build result records:

- build registration and Command;
- input Repository and dependency fingerprints;
- Environment and image digest;
- output Artifact identifiers, media types, sizes, and digests;
- structured build manifest;
- warnings and reproducibility notes;
- cache use;
- exit result.

The output digest can later become an attestation subject.

### Coverage reports

Coverage ingestion records:

- producer and format;
- source-state binding;
- measured path and branch sets;
- line, branch, function, or region coverage;
- exclusions;
- merged-shard behavior;
- completeness;
- raw report Artifact.

Coverage percentage alone does not verify behavior or acceptance.

## Artifact-store integration

### Store responsibilities

The Artifact store provides immutable content-addressed records for:

- Command stdout and stderr;
- terminal transcripts;
- Patch proposals and deterministic diffs;
- rollback content and manifests;
- structured reports;
- normalized result documents;
- build outputs;
- browser traces;
- coverage reports;
- database dumps when permitted;
- receipts and optional attestations;
- oversized telemetry or audit attachments when policy allows.

### Artifact identity

An Artifact records:

```text
Artifact ID
content digest
media type
size
kind
producer
owner scope
creation time
source Repository and Environment bindings
trust and sensitivity
retention class
compression and encoding
storage backend and location reference
access policy
redaction or transformation history
supersession when applicable
```

The content digest identifies bytes after the recorded encoding and compression rules.

### Immutability and deduplication

Artifact content is immutable after publication.

Identical content can share storage while retaining separate Artifact records for different producers, scopes, retention, or policy.

A mutable external file can be referenced only as an observed Resource. It does not become an immutable Artifact until Kiln captures and hashes it.

### Storage placement

The local Artifact store lives under a Kiln-owned data root outside active and reference repositories.

A worktree-local temporary transaction area can hold uncommitted staging bytes. Durable Artifacts move to the Kiln-owned store before cleanup.

### Artifact access

Artifact reads require:

- active Run and Capability scope;
- sensitivity and Privacy checks;
- retention status;
- source and transformation provenance;
- bounded disclosure or pagination.

Artifact existence does not imply model visibility, Evidence authority, or external-disclosure permission.

### Retention

Retention classes include:

```text
temporary
run
session
project
audit
release
policy_controlled
```

Rollback Artifacts remain until the Patch transaction and accepted recovery window close.

Receipts can outlive large raw output. A later retention cleanup preserves required digests, minimal metadata, and the fact that referenced content expired when policy permits.

## Receipt schema

### Receipt types

The execution plane supports:

```text
command_receipt
patch_receipt
verification_receipt
run_receipt
delivery_receipt
```

A Receipt is generated by deterministic code from durable records and current observations.

### Required receipt fields

Every Receipt records or references:

```text
receipt ID and schema version
receipt type and scope
Task ID and accepted Task revision
Run ID and lineage
Repository ID
commit when available
branch when available
dirty-tree fingerprint
dependency fingerprint
Environment ID, class, fingerprint, and effective isolation
model invocation when relevant
Agent and Skill versions when relevant
Capability grants used
Approvals used
exact registered Commands
redacted argv projections and request digests
exit status, signals, timeout, cancellation, and duration
relevant bounded output
warnings, denials, omissions, and unknown effects
Artifact IDs and digests
Patch and Change set IDs
acceptance criterion IDs
structured-result IDs and summaries
verification result
acceptance decision when applicable
delivery result when applicable
Trace reference
start, completion, and sealing timestamps
manifest digest
```

Secret values, raw sensitive prompts, and unrestricted source content are not embedded in the Receipt.

### Command Receipt

A Command Receipt seals:

- immutable request;
- selected registration;
- executable and Environment resolution;
- grants and Approval;
- Repository state before and after;
- lifecycle and process-tree cleanup;
- output Artifacts;
- structured results;
- Evidence produced;
- warnings and unknown effects.

### Patch Receipt

A Patch Receipt seals:

- proposal and Patch Artifact;
- base state and preconditions;
- operation list and changed regions;
- policy and lease checks;
- deterministic preview;
- application result;
- rollback manifest and outcome;
- post-application Repository state;
- formatter and focused-validation references.

### Verification Receipt

A Verification Receipt seals:

- criteria;
- subject state;
- Verifier identity;
- methods and Commands;
- structured and raw results;
- current Evidence;
- `PASS`, `FAIL`, or `BLOCKED`;
- coverage and omissions;
- freshness rule.

### Run Receipt

A Run Receipt summarizes the Run's current facts without replacing underlying records.

It includes all material Claims, Evidence, Commands, Patches, Artifacts, Attention, denials, warnings, acceptance status, and unresolved work.

### Delivery Receipt

A Delivery Receipt binds the accepted subject to one destination and observed destination result.

It does not imply that post-delivery health or behavior is verified unless separate Evidence records prove it.

### Receipt limits

Receipts contain bounded summaries and immutable references rather than complete logs, traces, reports, source, or binaries.

A Receipt can be regenerated only as a new superseding Receipt. An existing sealed Receipt is not modified.

### Receipt authority

A Receipt proves that Kiln sealed the referenced facts and digests at one time.

A Receipt cannot:

- change Repository state;
- make stale Evidence current;
- convert `FAIL` or `BLOCKED` to `PASS`;
- grant Capability authority;
- approve integration;
- accept a Task;
- prove delivery without delivery Evidence;
- claim a SLSA level.
