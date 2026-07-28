# Execution Observability, Sensitive Data, and Attestations

**Document type:** Focused specification  
**Decision status:** Owner-accepted direction  
**Integration status:** Proposed on P0-W15  
**Implementation status:** Not implemented  
**Contract version:** `kiln.execution_plane/v0`

This document is part of the authoritative P0-W15 execution-plane design. It also owns the consolidated P0-W15 acceptance criteria.

## OpenTelemetry model

### Position

Kiln uses OpenTelemetry for traces, metrics, and selected logs that describe execution-plane behavior.

Telemetry provides operational visibility. Durable domain events, audit records, Evidence, and Receipts remain separate authorities.

The initial instrumentation follows OpenTelemetry semantic-convention principles:

- use low-cardinality operation names;
- put variable identity in attributes rather than span names;
- record errors through status and bounded attributes;
- document sensitive attributes;
- make high-cardinality and sensitive capture opt-in;
- preserve trace and span identifiers in Kiln records when useful.

### Trace structure

A user Task is the normal top-level trace scope for one accepted attempt.

Recommended span names:

```text
kiln.task
kiln.run
kiln.model.invoke
kiln.context.compile
kiln.capability.select
kiln.tool.call
kiln.command
kiln.patch
kiln.verification
kiln.attention
kiln.approval
kiln.artifact.create
kiln.completion.decide
kiln.delivery
```

Span names do not include Task text, Repository paths, model prompts, executable arguments, filenames, or user content.

Logical Parent-Child Run lineage can be represented through span parentage when timing matches. Durable Run lineage remains authoritative when spans cross restarts or asynchronous delivery.

Links are used when one operation consumes Evidence or Artifacts from another trace or when a background Child is not a strict synchronous child span.

### Common attributes

Safe default attributes include opaque or low-cardinality values such as:

```text
kiln.workspace.id
kiln.project.id
kiln.session.id
kiln.task.id
kiln.run.id
kiln.run.role
kiln.environment.class
kiln.environment.isolation_profile
kiln.capability.key
kiln.capability.decision
kiln.tool.key
kiln.command.registration_key
kiln.command.status
kiln.patch.status
kiln.verification.status
kiln.attention.type
kiln.approval.decision
kiln.artifact.kind
kiln.completion.stage
kiln.result.format
error.type
```

Repository, branch, path, command, provider, and model fields are classified before export. Public or local-only deployments can permit more detail than remote shared collectors.

### Metrics

Kiln measures at least:

```text
model input and output tokens
model cost
prompt-cache reads, writes, hits, and misses
Tool-schema tokens and bytes
Tool-result tokens and bytes
Context items and bytes
repeated retrieval count
repeated Command count
Command starts and duration
failed Commands
Command timeouts and cancellations
orphaned Commands
process-tree cleanup failures
Patch proposals and applications
failed, conflicted, rolled-back, and orphaned Patches
permission denials
network and secret denials
verification PASS, FAIL, and BLOCKED
stale Evidence events
unsupported completion attempts
Artifact bytes by kind and retention
structured-result parse failures and truncation
Attention and Approval latency
```

Metric dimensions remain bounded. Task text, source path, rule message, test name, and Command argv are not ordinary metric labels.

### Events and logs

Span events can record bounded lifecycle facts such as:

- timeout requested;
- graceful termination started;
- force termination started;
- cleanup failed;
- Patch conflict detected;
- result parser rejected a report;
- Evidence became stale;
- unsupported completion was denied.

Detailed output remains in Artifacts and durable events.

### Sampling and export

Local traces can retain more detail under local policy.

Remote exporters receive only fields permitted by Privacy policy. Sampling must preserve errors and security-relevant outcomes according to policy, but telemetry retention cannot replace durable audit or Evidence retention.

Trace export failure cannot fail a successful local Command or Patch transaction unless telemetry is an explicit acceptance criterion.

## Sensitive-data policy

### Default excluded data

Kiln does not place these values in telemetry, ordinary logs, Receipts, or model-visible execution summaries by default:

- source code;
- Patch content;
- complete diffs;
- complete Command output;
- secret values;
- environment variable values;
- raw model prompts and responses;
- user Task text;
- unredacted argv;
- local absolute paths;
- database contents;
- browser page content, cookies, tokens, or headers;
- terminal input;
- private Artifact URLs;
- remote credentials or host sockets.

### Allowed references

Kiln prefers:

- opaque identifiers;
- content digests;
- data classes;
- counts and sizes;
- status and error classes;
- bounded redacted excerpts when explicitly required;
- Artifact references subject to separate access control.

### Redaction stages

Sensitive-data handling occurs:

1. before process environment creation;
2. while streaming stdout and stderr;
3. before bounded result creation;
4. during structured-result normalization;
5. before Artifact classification and disclosure;
6. before Receipt sealing;
7. before telemetry export.

Redaction records the policy and redactor version. It does not change raw restricted Artifacts that policy requires Kiln to retain.

### Command and path disclosure

The local user can inspect exact Commands and paths when authorized.

Remote telemetry and model Context normally receive registration keys, opaque path references, and redacted argv projections.

An exact shell command is stored as a restricted audit or Artifact record, not a normal telemetry attribute.

### Model data

Model identity, token counts, cost, finish status, and invocation identifiers can enter telemetry.

Prompt and response content require separate explicit policy. Provider cache identifiers must not contain secrets or raw source.

### Structured-result sensitivity

A structured report is not safe merely because it is machine-readable.

Reports can contain:

- source excerpts;
- stack traces;
- usernames and host paths;
- secrets;
- browser data;
- dependency locations;
- test fixtures and customer data.

Adapters classify and redact normalized fields. Raw report Artifacts retain an explicit sensitivity and access policy.

## Future attestation mapping

### Position

Kiln's deterministic Receipt is the primary local record.

An optional exporter can later produce interoperable supply-chain attestations for selected immutable outputs.

Ordinary reads, edits, failed Commands, local formatting, and intermediate Patches do not require formal attestations.

### in-toto Statement mapping

An eligible Receipt can map to an in-toto Statement v1:

```text
_type
  https://in-toto.io/Statement/v1
subject
  immutable output names and digests
predicateType
  Kiln receipt predicate or accepted standard predicate
predicate
  bounded facts derived from the sealed Receipt
```

The exporter uses Artifact or commit digests as subjects.

A Task, Run, Environment, or Command that does not produce an immutable subject remains a Receipt and is not forced into an in-toto Statement.

The Statement does not include secret values, sensitive prompts, or unrestricted local paths.

### Kiln predicate

A future Kiln predicate can carry:

- Receipt identifier and manifest digest;
- Task and Run references;
- Repository and commit state;
- Environment fingerprint;
- Command registration and execution result;
- input and output Artifact digests;
- verification summary;
- warnings and unresolved gaps;
- trace reference.

The predicate version is independent from the Receipt schema version.

### SLSA provenance mapping

A build or packaging Receipt can later map to the SLSA provenance predicate when:

- one or more immutable build subjects exist;
- builder identity is stable and meaningful;
- build definition and external parameters are known;
- resolved dependencies and input digests are available to the accepted level of completeness;
- run details and timing are recorded;
- sensitive values can be excluded safely;
- the exporter validates the target SLSA schema.

Potential mapping:

```text
subject
  build Artifact digests
buildDefinition.buildType
  accepted Kiln build registration type
buildDefinition.externalParameters
  policy-approved non-secret parameters
buildDefinition.internalParameters
  omitted or minimized according to policy
buildDefinition.resolvedDependencies
  Repository, lockfile, image, and input Artifact digests
runDetails.builder
  Kiln builder identity and version
runDetails.metadata
  invocation and timing facts
runDetails.byproducts
  selected report, log, SBOM, and Receipt references
```

Kiln does not claim a SLSA Build Level merely because it can emit the predicate shape. Level claims require all applicable SLSA requirements and independent validation.

### Signatures and DSSE

A future exporter can wrap attestations in DSSE or another accepted signing envelope.

Signing requires a separate key, identity, secret, and publication design. P0-W15 does not select a signing system.

Unsigned local Receipts remain useful for deterministic local provenance but must not be represented as cryptographically authenticated.

## Runtime and OTP mapping

### `Kiln.Execution.EnvironmentBroker`

Responsibilities:

- inventory Environment registrations;
- evaluate compatibility and policy;
- select the least sufficient Environment;
- record the selection decision and effective controls;
- provision and release attached disposable Resources.

It cannot issue Capability grants.

### `Kiln.Execution.CommandRegistry`

Responsibilities:

- store accepted versioned registrations;
- validate request intent, argv, cwd, environment, network, secrets, limits, and result adapters;
- expose compact intent-level projections;
- reject unknown or superseded registrations.

The registry is data and pure validation where practical. It does not require one process per registration.

### `Kiln.Execution.CommandSupervisor`

Responsibilities:

- supervise active Command workers;
- own cancellation and timeout routing;
- ensure one tree-owning worker per Command;
- preserve failure isolation;
- reconstruct orphan and cleanup state after restart.

### `Kiln.Execution.CommandWorker`

Responsibilities:

- freeze and execute one authorized request;
- own the process tree or isolation unit;
- stream bounded output;
- capture Artifacts;
- enforce lifecycle limits;
- report exit and cleanup observations.

A Worker is transient. The Command identity is durable.

### `Kiln.Execution.PatchService`

Responsibilities:

- validate immutable proposals;
- create deterministic previews;
- coordinate Repository lease and path checks;
- stage and apply transactions;
- retain rollback records;
- observe final state;
- emit Patch and Change set events.

The Patch service does not run formatters or tests directly. It requests registered Commands after application.

### `Kiln.Execution.ResultIngestor`

Responsibilities:

- identify accepted result formats;
- validate reports;
- preserve raw Artifacts;
- normalize findings;
- map paths to Repository state;
- disclose partial, invalid, or truncated results;
- create Evidence candidates.

### `Kiln.Evidence.ReceiptService`

Responsibilities:

- read durable records and current observations;
- validate required references;
- create bounded deterministic manifests;
- compute manifest digests;
- seal immutable Receipts;
- support optional future exporters.

### `Kiln.Artifacts.Store`

Responsibilities:

- content-addressed write and read;
- immutable publication;
- sensitivity and retention;
- access and disclosure decisions;
- garbage-collection coordination;
- integrity verification.

### `Kiln.Telemetry`

Responsibilities:

- start and link spans;
- record bounded metrics and events;
- apply sensitive-data policy;
- export under Privacy policy;
- preserve Trace references in durable records when accepted.

Telemetry failure must remain isolated from domain execution.

## Durable events

Minimum execution-plane events include:

```text
EnvironmentSelectionRequested
EnvironmentSelected
EnvironmentProvisioningStarted
EnvironmentReady
EnvironmentProvisioningFailed
DisposableResourceStarted
DisposableResourceStopped
CommandRequested
CommandAuthorized
CommandDenied
CommandStarted
CommandOutputObserved
CommandTimedOut
CommandCancellationRequested
CommandTerminationStarted
CommandExited
CommandCleanupCompleted
CommandOrphaned
PatchProposed
PatchInspectionRecorded
PatchConflictDetected
PatchApplicationStarted
PatchApplied
PatchRollbackStarted
PatchRolledBack
PatchOrphaned
StructuredResultIngested
StructuredResultRejected
EvidenceRecorded
EvidenceInvalidated
VerificationRecorded
AcceptanceRecorded
DeliveryRecorded
ArtifactPublished
ReceiptSealed
UnsupportedCompletionAttempted
AttestationExported
AttestationExportFailed
```

High-volume output is not stored as one durable event per byte or line. Events contain bounded references and sequence information.

## Verification strategy

### Pure contract tests

Test:

- Environment selection;
- registry resolution;
- argv and path validation;
- network and secret policy;
- stage semantics;
- Patch preconditions and operation ordering;
- result normalization;
- Evidence authority and freshness;
- Receipt determinism;
- telemetry redaction;
- attestation eligibility and mapping.

### Command integration tests

Fixtures must prove:

- registered argv reaches the executable exactly;
- shell metacharacters remain ordinary argv without shell mode;
- cwd escape is rejected;
- environment inheritance is minimal;
- secret values do not enter durable records;
- timeout terminates descendants;
- cancellation distinguishes graceful and forced termination;
- stdout and stderr limits preserve complete Artifacts;
- process-tree cleanup failure creates `orphaned` or unknown effects;
- network modes are reported honestly;
- unrestricted shell cannot run without matching Approval and grant.

### Environment tests

Run accepted fixtures through:

- trusted host read;
- active Project Environment;
- exclusive worktree;
- accepted Dev Container fixture;
- disposable OCI worker with denied network;
- disposable database;
- degraded platform where a required control is unavailable.

The same harmless read should not be forced into a container or worktree.

### Patch tests

Test:

- exact patch;
- create;
- delete;
- move;
- case-only rename preview;
- hash mismatch;
- path escape;
- symlink target;
- conflicting unowned dirty change;
- multi-file apply;
- failure during application;
- observed safe rollback;
- rollback failure and orphan state;
- changed-region tracking;
- formatter expansion;
- AST adapter exact-one-target rule;
- isolated Child Patch Artifact application by a separate authorized Run.

Before and after fingerprints prove whether the transaction or rollback changed the intended state.

### Structured-result tests

Use fixtures for:

- valid and invalid SARIF;
- partial and complete test reports;
- compiler diagnostics;
- linter warnings;
- security findings with secret content;
- browser traces;
- build manifests;
- coverage reports;
- path mappings that escape or do not match the subject Repository;
- stale reports after a source change.

The raw Artifact and normalized records must remain linked.

### Receipt tests

Prove:

- identical durable inputs produce the same manifest digest;
- a changed Command, Artifact, Evidence, warning, or state binding changes the digest;
- Receipts reject missing required scope and state facts;
- a Receipt cannot claim `Verified` without current `PASS` Evidence;
- a Receipt cannot claim `Accepted` without a decision;
- a Receipt cannot claim `Delivered` without destination Evidence;
- sensitive values do not appear in the manifest;
- superseding produces a new immutable Receipt.

### Telemetry tests

Prove:

- required spans and metrics are emitted;
- span names remain low-cardinality;
- source, prompts, secrets, argv, and output are absent by default;
- error paths retain status without sensitive payloads;
- exporter failure does not corrupt execution;
- metric cardinality remains bounded;
- unsupported completion attempts are counted and durably recorded.

### Attestation tests

Prove:

- a build Receipt with immutable subjects maps to a valid in-toto Statement shape;
- an ineligible ordinary local action stays a Receipt;
- a SLSA provenance export includes only known and policy-approved fields;
- format export does not create a SLSA-level Claim;
- changed subjects or predicate facts change the attestation digest;
- signing remains absent unless a later accepted signing system exists.

## Acceptance criteria

- **P0-W15-AC01:** Kiln selects the least powerful Environment that satisfies correctness, authority, isolation, and Evidence requirements.
- **P0-W15-AC02:** Low-risk deterministic reads can run on the trusted host without a container or worktree.
- **P0-W15-AC03:** Project-defined execution uses an accepted Project Environment and cannot grant itself authority.
- **P0-W15-AC04:** Every independently mutating Run uses one exclusive writable worktree and mutation lease.
- **P0-W15-AC05:** Dev Container configuration is resolved and policy-checked before lifecycle behavior runs.
- **P0-W15-AC06:** Disposable OCI workers disclose effective image, mount, user, privilege, network, secret, Resource, and cleanup controls.
- **P0-W15-AC07:** Disposable databases are bounded Resources with version, schema, seed, credential-reference, readiness, and cleanup Evidence.
- **P0-W15-AC08:** WASI and WIT remain a future versioned component boundary and are not required for the first execution plane.
- **P0-W15-AC09:** The Environment broker cannot grant Capability authority.
- **P0-W15-AC10:** Network and secrets default to denied and require explicit registration and grants.
- **P0-W15-AC11:** Secret values do not enter Command documents, argv, Receipts, telemetry, or ordinary logs.
- **P0-W15-AC12:** Resource limits distinguish requested, supported, and effectively enforced controls.
- **P0-W15-AC13:** Cancellation and timeout target the full owned process tree, not only the direct child.
- **P0-W15-AC14:** Unknown descendants or effects produce `orphaned` or `effects_unknown`, not clean success.
- **P0-W15-AC15:** Ordinary Commands resolve through a versioned registry with fixed executable and argument-vector policy.
- **P0-W15-AC16:** Working directories and path arguments remain inside accepted Repository, worktree, or Environment scopes.
- **P0-W15-AC17:** The runner uses a minimal constructed environment rather than ambient shell inheritance.
- **P0-W15-AC18:** Output truncation is explicit and complete raw output remains in bounded Artifacts when retained.
- **P0-W15-AC19:** Structured Command results preserve request, Environment, state, exit, duration, output, cleanup, warning, and Artifact facts.
- **P0-W15-AC20:** An unrestricted shell requires exact explicit Approval, a dedicated grant, bounded Environment policy, and security audit.
- **P0-W15-AC21:** Patch proposals are immutable and bind to exact base state, expected hashes, path scope, operations, and producer.
- **P0-W15-AC22:** Patch validation rejects state mismatch, path escape, symlink violation, lease conflict, and unexpected targets before mutation.
- **P0-W15-AC23:** Exact patches, create, delete, move, rename preview, changed-region tracking, and Patch Artifacts are supported by one transaction contract.
- **P0-W15-AC24:** AST-aware and framework operations remain deterministic adapters that produce exact Patch previews and bytes.
- **P0-W15-AC25:** Patch application stages all operations and retains rollback information before target replacement.
- **P0-W15-AC26:** Patch results distinguish applied, rolled back, conflicted, failed, and orphaned states.
- **P0-W15-AC27:** A rollback is reported successful only after the pre-transaction state is observed.
- **P0-W15-AC28:** Formatting and focused validation run as visible registered Commands after application.
- **P0-W15-AC29:** Proposed, Implemented, Inspected, Executed, Verified, Accepted, and Delivered remain separate facts.
- **P0-W15-AC30:** Every material completion Claim references sufficient current Evidence or remains unsupported.
- **P0-W15-AC31:** Exit zero does not automatically produce `Verified`, `Accepted`, or `Delivered`.
- **P0-W15-AC32:** Machine-readable results outrank model summaries only when valid, complete, current, and subject-bound.
- **P0-W15-AC33:** Verification preserves `PASS`, `FAIL`, and `BLOCKED` without collapsing them.
- **P0-W15-AC34:** SARIF, test, compiler, linter, security, browser, build, and coverage inputs preserve raw Artifacts and adapter provenance.
- **P0-W15-AC35:** Partial, invalid, stale, truncated, or path-mismatched structured reports disclose those limitations.
- **P0-W15-AC36:** The Artifact store is immutable, content-addressed, policy-gated, and located outside active and reference repositories.
- **P0-W15-AC37:** Receipts include Task, Run, Repository, state, dependencies, Environment, Commands, Capabilities, Artifacts, criteria, results, warnings, and timestamps.
- **P0-W15-AC38:** Receipts do not make Evidence current, authorize integration, accept work, or prove delivery without the required records.
- **P0-W15-AC39:** OpenTelemetry covers Task, Run, model, Context, Capability, Tool, Command, Patch, verification, Attention, Approval, Artifact, completion, and delivery operations.
- **P0-W15-AC40:** Telemetry measures token, cost, cache, Tool overhead, repetition, failures, denials, verification, and unsupported completion without high-cardinality content labels.
- **P0-W15-AC41:** Source code, patches, secrets, sensitive prompts, raw argv, and complete output remain outside telemetry by default.
- **P0-W15-AC42:** Telemetry failure cannot replace durable Evidence or corrupt an otherwise successful local operation.
- **P0-W15-AC43:** Eligible Receipts can map to in-toto Statement v1 subjects and predicates without changing Receipt authority.
- **P0-W15-AC44:** SLSA provenance export is optional and limited to actions with appropriate immutable build subjects and known provenance fields.
- **P0-W15-AC45:** Emitting an attestation format does not claim a SLSA Build Level or cryptographic authenticity.
- **P0-W15-AC46:** Phase 1 can prove the deterministic execution plane without a live model, formal attestation service, Wasm plugin, or mandatory container for harmless work.

## Deferred

P0-W15 does not implement:

- production Command workers;
- a container or Dev Container runtime adapter;
- operating-system process-tree primitives;
- cgroup or Job Object management;
- disposable database provisioning;
- secret-provider integration;
- Patch application code;
- AST-edit dependencies;
- SARIF or report parsers;
- Artifact storage code;
- OpenTelemetry dependencies or exporters;
- WASI or WIT plugins;
- in-toto, SLSA, DSSE, or signing exporters;
- remote execution;
- production model execution.

## External standards and references

The implementation pass should verify exact supported versions before adding dependencies or format claims.

Primary references include:

- Open Container Initiative Runtime Specification;
- Development Container Specification;
- OpenTelemetry Semantic Conventions;
- SARIF 2.1.0 Plus Errata 01;
- WebAssembly Component Model WIT and WASI release documentation;
- in-toto Statement v1 and framework specification;
- SLSA specification and provenance predicate.
