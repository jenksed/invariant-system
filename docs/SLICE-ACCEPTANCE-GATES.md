# Slice Acceptance Gates

**Document type:** Verification and integration plan  
**Decision status:** Owner-directed reconciliation  
**Integration status:** Proposed on P0-W16  
**Implementation status:** Not implemented

## Purpose

`docs/IMPLEMENTATION-SLICES.md` defines required behavior for every slice. This document defines the aggregate executable gate that proves those criteria together against one exact Repository state.

A criterion is a required behavior. A gate is the deterministic command bundle and Evidence manifest that evaluates a group of criteria. A demo is the user-visible scenario. A Receipt seals references to the gate, demo, state, warnings, and decisions.

## Gate rules

1. Every gate runs against an exact commit or head plus dirty fingerprint.
2. A gate uses deterministic fixtures and controlled time.
3. Optional live provider, language-server, protocol, or container smoke tests remain separate from required CI gates unless an accepted policy later promotes them.
4. A gate cannot silently skip an unavailable required control.
5. `BLOCKED` is distinct from `PASS` and `FAIL`.
6. A gate records command, exit status, duration, structured result, relevant output, Artifacts, warnings, and Environment fingerprint.
7. A demo cannot substitute for a gate.
8. A Receipt cannot make a failed, blocked, or stale gate pass.
9. The final slice gate runs against the projected merged state when trunk interaction can change behavior.
10. Gate scripts live under `scripts/gates/` and emit human output plus one machine-readable result Artifact.

## P1-S01 gates — Navigable simulated Runs

| Gate | Proof |
| --- | --- |
| P1-S01-G01 | Session, Task, Run, Root, Parent, Child, sibling, and depth invariants. |
| P1-S01-G02 | Ordered event reducer, duplicate rejection, and byte-stable snapshot JSON. |
| P1-S01-G03 | Breadcrumb, Child cards, Run tree, and client-local focus projections. |
| P1-S01-G04 | Parent, Root, next-sibling, and previous-sibling navigation has no execution or authority side effects. |
| P1-S01-G05 | Simulated stream ordering and bounded activity summaries under controlled time. |
| P1-S01-G06 | Headless TUI intents and renderer-independent view models. |
| P1-S01-G07 | ExRatatui renderer smoke and renderer-crash isolation after dependency acceptance. |
| P1-S01-G08 | Narrow-terminal and keyboard-complete navigation behavior. |
| P1-S01-G09 | `P1-S01-D01` demo passes. |
| P1-S01-G10 | `P1-S01-R01` seals exact state, fixture, snapshot, demo, warnings, and exclusions. |

**Aggregate command:** `scripts/gates/slice-01`

## P1-S02 gates — One real read-only Scout

| Gate | Proof |
| --- | --- |
| P1-S02-G01 | Child exists before invocation and has independent Context, grants, limits, and accounting. |
| P1-S02-G02 | Native Repository search and reads enforce path, exclude, symlink, size, and trust policy. |
| P1-S02-G03 | Context manifest ordering, provenance, disclosure, Tool projection, and digest are deterministic. |
| P1-S02-G04 | Fake-provider streaming, cancellation, timeout, token limit, and step limit. |
| P1-S02-G05 | Provider/model selection follows fixed accepted policy and cannot be changed by retrieved content. |
| P1-S02-G06 | Secret canaries and denied paths never enter provider payloads, logs, telemetry, or ordinary Artifacts. |
| P1-S02-G07 | Scout result distinguishes observations, inferences, assumptions, and unknowns with exact source Evidence. |
| P1-S02-G08 | Parent delivery is bounded and idempotent; Child transcript remains independent. |
| P1-S02-G09 | Before/after Repository fingerprints prove no mutation. |
| P1-S02-G10 | `P1-S02-D01` and `P1-S02-R01` pass; live MiniMax smoke remains separately labeled when executed. |

**Aggregate command:** `scripts/gates/slice-02`

## P1-S03 gates — Background work and Attention

| Gate | Proof |
| --- | --- |
| P1-S03-G01 | Worker lease exclusivity, scheduler ordering, and three-active-Child limit. |
| P1-S03-G02 | Background execution never changes client focus automatically. |
| P1-S03-G03 | Blocking Run transitions create Attention in the same accepted state transition. |
| P1-S03-G04 | Global and ancestor Attention projections are independent of Run depth. |
| P1-S03-G05 | Question and permission responses are explicit, revision-checked, and idempotent. |
| P1-S03-G06 | Pause and resume preserve the recorded resume state. |
| P1-S03-G07 | Child cancellation does not cancel Parent or siblings without accepted descendant policy. |
| P1-S03-G08 | Completion notifications remain informational and deduplicated. |
| P1-S03-G09 | Concurrent response and cancellation race fixtures remain deterministic. |
| P1-S03-G10 | `P1-S03-D01` and `P1-S03-R01` pass with no silently blocked Run. |

**Aggregate command:** `scripts/gates/slice-03`

## P1-S04 gates — Independent Verifier

| Gate | Proof |
| --- | --- |
| P1-S04-G01 | Verifier has independent requirement, diff, Context, Repository, and Environment package. |
| P1-S04-G02 | Verifier has no write, Patch, Git mutation, install, configuration, or repair authority. |
| P1-S04-G03 | Command registry rejects unknown executable, argv, cwd, network, secret, and side-effect shapes. |
| P1-S04-G04 | Supervised Command timeout, cancellation, output limit, and process-tree cleanup are accurate. |
| P1-S04-G05 | Raw stdout, stderr, and structured test report remain immutable Artifacts. |
| P1-S04-G06 | Structured result ingestion reports valid, invalid, partial, truncated, stale, and path-mismatched status. |
| P1-S04-G07 | `PASS`, `FAIL`, and `BLOCKED` remain distinct and every `PASS` criterion has current reproduced Evidence. |
| P1-S04-G08 | Source fingerprints prove the Verifier made no edit. |
| P1-S04-G09 | Receipt determinism and missing/stale Evidence rejection. |
| P1-S04-G10 | `P1-S04-D01` and `P1-S04-R01` pass. |

**Aggregate command:** `scripts/gates/slice-04`

## P1-S05 gates — Durable recovery

| Gate | Proof |
| --- | --- |
| P1-S05-G01 | SQLite migrations, event append, expected revision, and transaction rollback. |
| P1-S05-G02 | Session, Task, Run, transcript, Attention, execution, Evidence, and delivery projections rebuild from zero. |
| P1-S05-G03 | Checkpoint replay produces an equivalent snapshot to full journal replay. |
| P1-S05-G04 | Child creation, Command start, Attention response, and result delivery are idempotent across restart. |
| P1-S05-G05 | Artifact and Receipt metadata retains digest integrity and correct storage boundaries. |
| P1-S05-G06 | Local runtime snapshot, event replay, cursor resume, gap handling, and duplicate suppression. |
| P1-S05-G07 | Crash injection during provider, Command, Attention, and delivery produces accurate recovery state. |
| P1-S05-G08 | Unknown external effects become orphaned; stale Evidence remains stale; dirty work is preserved. |
| P1-S05-G09 | Pre-crash and post-restart navigable snapshots are semantically equivalent. |
| P1-S05-G10 | `P1-S05-D01` and `P1-S05-R01` pass. |

**Aggregate command:** `scripts/gates/slice-05`

## P1-S06 gates — Local code intelligence

| Gate | Proof |
| --- | --- |
| P1-S06-G01 | Deterministic Repository map and language/file classification. |
| P1-S06-G02 | Tree-sitter extraction, changed ranges, provenance, malformed input, and bounded failure. |
| P1-S06-G03 | Fake LSP initialization, document sync, definition, references, diagnostics, cancellation, and shutdown. |
| P1-S06-G04 | Optional real server profile is explicit and cannot auto-install or broaden authority. |
| P1-S06-G05 | Native semantic cache reuse and invalidation by source, server, extractor, and policy digest. |
| P1-S06-G06 | Documentation authority and version resolver ordering. |
| P1-S06-G07 | Skill metadata discovery, schema validation, lazy loading, and no authority effect. |
| P1-S06-G08 | Context compiler selects bounded symbols, ranges, docs, Skill, and retrieval handles. |
| P1-S06-G09 | Parser or server failure preserves durable state and reports partial intelligence. |
| P1-S06-G10 | `P1-S06-D01` and `P1-S06-R01` pass with no source write. |

**Aggregate command:** `scripts/gates/slice-06`

## P1-S07 gates — Safe writing delegation

| Gate | Proof |
| --- | --- |
| P1-S07-G01 | Writing Child has no filesystem-write or Git-mutation grant and returns one immutable Patch Artifact. |
| P1-S07-G02 | Parent owns one exclusive writable worktree and mutation lease. |
| P1-S07-G03 | Exact Patch, create, delete, move, and rename preview produce deterministic bytes and previews. |
| P1-S07-G04 | Base, hash, path, symlink, dirty state, lease, and scope conflicts block before mutation. |
| P1-S07-G05 | Multi-file staging, apply, rollback data, and result-state observation. |
| P1-S07-G06 | Injected failure produces accurately observed applied, rolled back, failed, or orphaned state. |
| P1-S07-G07 | Formatter and focused validation are separate registered Commands. |
| P1-S07-G08 | Direct and formatter-expanded changed regions remain distinguishable. |
| P1-S07-G09 | Two Child proposals cannot write simultaneously or authorize integration. |
| P1-S07-G10 | `P1-S07-D01` and `P1-S07-R01` pass. |

**Aggregate command:** `scripts/gates/slice-07`

## P1-S08 gates — Capability interoperability

| Gate | Proof |
| --- | --- |
| P1-S08-G01 | ACP and TUI project equivalent state from one sequence and reconnect without duplicate effects. |
| P1-S08-G02 | External Client actions pass native authentication, authorization, revision, and Attention rules. |
| P1-S08-G03 | JUnit-compatible and SARIF ingestion retains raw Artifact, parser, version, state, and completeness. |
| P1-S08-G04 | One concrete MCP or OpenAPI capability registers behind the broker and remains hidden until selected and granted. |
| P1-S08-G05 | Host, credential, schema, output, timeout, cancellation, and Privacy policy remain bounded. |
| P1-S08-G06 | Dev Container configuration cannot run lifecycle behavior implicitly. |
| P1-S08-G07 | OCI profile records effective image, mount, user, privilege, network, secret, limit, and cleanup controls. |
| P1-S08-G08 | Adapter failure cannot corrupt Run state or bypass Command, Patch, Artifact, Evidence, or Receipt paths. |
| P1-S08-G09 | No protocol object becomes a core domain entity. |
| P1-S08-G10 | Required `P1-S08-D01` path and `P1-S08-R01` pass; optional increments remain explicitly deferred when not justified. |

**Aggregate command:** `scripts/gates/slice-08`

## P1-S09 gates — Local project intelligence

| Gate | Proof |
| --- | --- |
| P1-S09-G01 | Indexing is disabled without accepted roots and opt-out is honored. |
| P1-S09-G02 | Canonical root, path, exclude, symlink, special-file, and policy checks repeat before every read. |
| P1-S09-G03 | Before/after Repository fingerprints prove no source, Git, lockfile, cache, or metadata mutation. |
| P1-S09-G04 | Derived data stays under Kiln-owned storage and no Command or network canary fires. |
| P1-S09-G05 | Exact, dependency, structural, text, error, test, migration, and verification queries work without a model. |
| P1-S09-G06 | Search returns at most eight deterministic compact candidates with complete provenance. |
| P1-S09-G07 | Inspection revalidates source and reports stale or partial state honestly. |
| P1-S09-G08 | Instruction quarantine, secret screening, sanitization, licensing, and disclosure policy pass adversarial fixtures. |
| P1-S09-G09 | Incremental reuse, invalidation, failure atomicity, and last-complete-snapshot recovery. |
| P1-S09-G10 | `P1-S09-D01` and `P1-S09-R01` pass with embeddings and graph database disabled. |

**Aggregate command:** `scripts/gates/slice-09`

## P1-S10 gates — Expansion evaluations

| Gate | Proof |
| --- | --- |
| P1-S10-G01 | Candidate has one concrete workflow and measured limitation in the existing path. |
| P1-S10-G02 | Candidate has a bounded contract, trust boundary, dependency cost, and removal strategy. |
| P1-S10-G03 | Spike is time-bounded, isolated, and cannot merge product code by default. |
| P1-S10-G04 | Deterministic conformance fixtures cover version, mapping, authority, Privacy, cancellation, failure, and cleanup. |
| P1-S10-G05 | Adopt, defer, or reject decision records Evidence and an ADR when architecture changes. |
| P1-S10-G06 | Deferred and rejected candidates remain outside production dependencies and model Tool catalogs. |
| P1-S10-G07 | A2A remains rejected for local Child Runs. |
| P1-S10-G08 | in-toto or SLSA format compatibility makes no unsupported signing, authenticity, or level Claim. |
| P1-S10-G09 | WASI/WIT does not become the default Command runtime without measured benefit. |
| P1-S10-G10 | `P1-S10-R01` seals the decision and cleanup or adopted implementation plan. |

**Aggregate command:** candidate-specific; there is no command that must implement every expansion candidate.

## Slice Receipt manifest

Every aggregate slice Receipt contains:

```text
slice identifier and revision
exact Repository state
required ticket and merge references
gate command and structured result
demo script and transcript Artifact
security and recovery Evidence
Artifacts and structured reports
warnings, exclusions, and unsupported paths
acceptance decision when required
manifest digest and seal time
```

A changed gate, fixture, demo, source state, warning, or decision creates a new Receipt rather than mutating the previous one.