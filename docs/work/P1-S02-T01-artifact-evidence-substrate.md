# P1-S02-T01: Artifact content-addressed substrate and typed Evidence module

**Document type:** Implementation plan  
**Status:** Rejected (PR #48 adjudication completed; plan requires correction before any replacement authorization)  
**Parent slice:** P1-S02  
**Branch:** `work/p1-s02-t01-artifact-evidence-substrate`  
**Depends on:** P1-S01-V01 accepted (P1-S01-T05 slice closeout merged at `db02198` via PR #46)

## Slice contribution

P1-S02 turns the P1-S01 durable foundation into the first complete, evidence-backed single-Run change loop required by `AGENTS.md` "Current delivery boundary — First month".

This ticket adds the durable Artifact storage module, its forward SQL migration, the typed Evidence module with method, producer, state binding, freshness, completeness, and contradiction classes, and the protected failure matrix the later P1-S02 capabilities record into. Every later P1-S02 ticket (registered Commands, fake provider, Repository read Tool, sealed Context, Patch engine, Gate execution, completion, Receipt) writes into this shared substrate without redefining Artifact identity or Evidence semantics.

It contributes prerequisite substrate to P1-S02-G06 (state-bound observations), P1-S02-G10 (freshness, completeness, and contradiction outcomes), and P1-S02-G16 (raw Artifact retention). T01 cannot satisfy any aggregate P1-S02 gate by itself.

After merge, no provider call, no Repository source read, no Patch, no Tool surface, no Gate execution, no completion, and no product Receipt exists.

## Objective

Implement one content-addressed, immutable Artifact store and one typed Evidence module bound to the existing `kiln-state/v1` store format with two new numbered forward SQL migrations, deterministic content digesting, producer/consumer vocabulary enforcement, and a protected failure matrix covering `replay_attack`, `contradiction`, `freshness_expired`, `incomplete`, and `stale_state_binding`, without introducing any process, provider call, Repository read, Patch, Tool surface, Command lifecycle, completion, Receipt, Child, TUI, or Wave B behavior.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| P1-S01-V01 accepted: durable foundation integrated with `kiln-state/v1`, 18 components, owner-machine OD-02 pass | `artifacts/p1-s01/slice-01-5792ffdd3af6c45f07e07b8334ce150ad642495b.json` | integrated planning | `db021984a9278ed582804d0bf3acd74207ad32e9` on `main` |
| T02 store layer supports numbered forward SQL migrations, checksum tracking, immediate transactions, and idempotency; no Artifact or Evidence tables exist | `lib/kiln/store/migrations.ex`, `priv/store/migrations/0001_initial_state.sql`, `priv/store/migrations/0002_action_commits_idempotency.sql` | Repository inspection | current `main` |
| `Kiln.Store.Error` class vocabulary is closed at `:busy, :integrity, :migration, :future_version, :revision, :idempotency_conflict, :precondition, :io, :unknown` | `lib/kiln/store/error.ex` | Repository inspection | current `main` |
| Conformance `first_month.ex` already declares `evidence_statuses = [:pass, :fail, :blocked, :unknown]` and `tools_for_step/1` references `artifact.read` — these are contract references, not implementations | `lib/kiln/conformance/first_month.ex` lines 43–45, 105, 128 | Repository inspection | current `main` |
| Provider behaviour contract exists with no implementation; Command host behaviour contract exists with no implementation | `lib/kiln/conformance/provider.ex`, `lib/kiln/conformance/command_host.ex` | Repository inspection | current `main` |
| Workflow capability matrix pattern established as single source of truth, with `valid_next_actions/1` | `lib/kiln/workflow.ex` `@capability_matrix` (lines 145–148) | Repository inspection | current `main` |
| Candidate T01 implementation exists but was produced before valid Repository authorization | PR #48 at `60367874bfc3c0e6d8cbd736f58e1ae17938943b` | KFT-0 authority review | candidate only; not accepted or merge-authorized |

## Assumptions and unknowns

### Assumptions

- **P1-S02-T01-A01:** Content-addressed Artifacts with SHA-256 over canonical bytes plus a stable row shape are sufficient for the durable identity needed by every later P1-S02 capability.
- **P1-S02-T01-A02:** Two forward SQL migrations (`0003_artifacts.sql` and `0004_evidence_records.sql`) are sufficient and preserve the `kiln-state/v1` format without requiring a new format version.
- **P1-S02-T01-A03:** The Artifact and Evidence modules can be implemented as pure Elixir structs and pure functions; no process, supervisor child, or registry is required.
- **P1-S02-T01-A04:** The protected failure matrix (replay_attack, contradiction, freshness_expired, incomplete, stale_state_binding) is complete enough for this slice and can be extended in later tickets without breaking the canonical Evidence digest.

### Unknowns

- **P1-S02-T01-U01:** The exact `producer_kind` vocabulary needed by later tickets (Command, provider, Pack, Patch) may grow; this ticket establishes the bounded initial set and the rejection rule.
- **P1-S02-T01-U02:** The freshness TTL semantics for non-`:transient` freshness classes will be defined by the Gate execution ticket (P1-S02-T06); this ticket defines the construction and validation surface only.
- **P1-S02-T01-U03:** Exact JSON Schema strings for `kiln.artifact/v1` and `kiln.evidence/v1` will be added under `priv/schemas/` and validated by `scripts/validate_json_schema_contracts.py`; the schema content is the source of truth for canonical bytes.

## Requirements

- **P1-S02-T01-R01:** Kiln shall persist Artifacts in a new `artifacts` table with columns `artifact_id` (sha256:hex), `byte_size`, `content_kind` (`:text | :json | :binary | :unstructured`), `encoding` (`:utf_8 | :utf_8_bom`), `media_type`, `retention_class` (`:transient | :durable`), `producer_kind` (bounded atoms), `producer_id`, `recorded_at`, `source_digest`, `schema` (`kiln.artifact/v1`).
- **P1-S02-T01-R02:** `Kiln.Artifact.Store.put/2` shall compute the content digest from canonical bytes, insert one row, and reject a `producer_kind`, `content_kind`, `encoding`, or `media_type` outside the bounded set with `{:error, %Kiln.Store.Error{class: :artifact}}`.
- **P1-S02-T01-R03:** The same canonical bytes shall produce the same `artifact_id`; different bytes shall produce a different `artifact_id`.
- **P1-S02-T01-R04:** Evidence shall be persisted in a new `evidence_records` table with columns `evidence_id` (canonical sha256:hex digest of the Evidence struct), `subject_id`, `subject_kind`, `subject_state_digest`, `producer_kind`, `producer_id`, `method` (`:observed | :derived | :computed | :reported`), `freshness_class` (`:transient | :stable | :durable`), `freshness_ttl_seconds` (nil for `:durable`), `completeness_class` (`:complete | :partial | :incomplete`), `observed_at`, `recorded_at`, `artifact_id` (nullable), `schema` (`kiln.evidence/v1`).
- **P1-S02-T01-R05:** `Kiln.Evidence.new/1` shall compute a deterministic canonical digest over the canonical bytes of the struct, reject unknown `method`/`freshness_class`/`completeness_class` atoms with `{:error, %Kiln.Store.Error{class: :evidence}}`, and reject any `producer_kind` outside the bounded set.
- **P1-S02-T01-R06:** When the protected failure matrix is exercised (replay_attack, contradiction, freshness_expired, incomplete, stale_state_binding), each fixture shall return its classified protected result and shall produce no false or partial durable state.
- **P1-S02-T01-R07:** Two new migrations `0003_artifacts.sql` and `0004_evidence_records.sql` shall apply cleanly on a fresh store and on a v1 store upgraded through 0002, with stored checksums and no `schema_format` version change.
- **P1-S02-T01-R08:** The Artifact and Evidence modules shall not introduce a process, supervisor child, registry, or external dependency.
- **P1-S02-T01-R09:** The implementation shall not introduce nested transactions, savepoints, or transaction retry.
- **P1-S02-T01-R10:** The Artifact and Evidence modules shall not store secrets, denied paths, raw transcript, or Repository source content beyond what the bounded retention policy declares.

## Security boundary

Allowed:

- extend `Kiln.Store.Error` class vocabulary with `:artifact` and `:evidence` only;
- add two numbered forward SQL migrations with stored checksums;
- pure Elixir SHA-256 digesting over canonical bytes;
- deterministic fixture databases under `$KILN_HOME`;
- local JSON Schema files under `priv/schemas/`.

Denied:

- provider call (real or fake);
- Repository source read or mutation;
- Context package or Tool surface;
- Patch proposal or application;
- Command lifecycle, process-group helper, or shell;
- Gate execution, Finding, Assurance, completion, or product Receipt;
- nested transactions or hidden retry;
- any process, supervisor child, or registry added solely for Artifact metadata or Evidence;
- any Child, TUI, MCP, or Wave B behavior;
- automatic commit, push, merge, publish, deploy, or install dependencies;
- shims, compatibility paths, or speculative flexibility.

## Proposed changes

1. Add `Kiln.Artifact.Store`, `Kiln.Artifact.Canonical`, and `Kiln.Artifact.Error` modules implementing content-addressed immutable Artifact storage and bounded vocabulary validation.
2. Add `Kiln.Evidence`, `Kiln.Evidence.Freshness`, and `Kiln.Evidence.Completeness` modules implementing typed Evidence construction with canonical digesting and bounded vocabulary validation.
3. Extend `Kiln.Store.Error.classes/0` to include `:artifact` and `:evidence` while preserving every existing class.
4. Add `priv/store/migrations/0003_artifacts.sql` defining the `artifacts` table per R01 with indexes on `producer_id` and `recorded_at`.
5. Add `priv/store/migrations/0004_evidence_records.sql` defining the `evidence_records` table per R04 with a unique constraint on `evidence_id` and indexes on `(subject_id, recorded_at)` and `(producer_kind, producer_id)`.
6. Add `priv/schemas/kiln.artifact/v1.json` and `priv/schemas/kiln.evidence/v1.json` as the canonical-byte source of truth for Artifact and Evidence digest computation.
7. Add deterministic fixture databases and tests covering content addressing equality/inequality, vocabulary rejection, replay_attack, contradiction, freshness_expired, incomplete, stale_state_binding, and nested-transaction rejection.
8. Extend `test/kiln/store/migrations_test.exs` with clean-apply, post-0004 replay, and protected-upgrade-from-v1 cases.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `lib/kiln/artifact/store.ex` | content-addressed put + vocabulary validation | Proposed |
| `lib/kiln/artifact/canonical.ex` | canonical bytes for digest | Proposed |
| `lib/kiln/artifact/error.ex` | thin shim over `Kiln.Store.Error` `:artifact` class | Proposed |
| `lib/kiln/evidence.ex` | typed Evidence construction + canonical digest | Proposed |
| `lib/kiln/evidence/freshness.ex` | freshness class vocabulary | Proposed |
| `lib/kiln/evidence/completeness.ex` | completeness class vocabulary | Proposed |
| `lib/kiln/store/error.ex` | add `:artifact` and `:evidence` to `@classes` | Proposed (vocabulary extension only) |
| `priv/store/migrations/0003_artifacts.sql` | new `artifacts` table | Proposed |
| `priv/store/migrations/0004_evidence_records.sql` | new `evidence_records` table | Proposed |
| `priv/schemas/kiln.artifact/v1.json` | Artifact canonical schema | Proposed |
| `priv/schemas/kiln.evidence/v1.json` | Evidence canonical schema | Proposed |
| `test/kiln/artifact/store_test.exs` | content addressing, vocabulary, equality tests | Proposed |
| `test/kiln/evidence_test.exs` | canonical digest, vocabulary, rejection tests | Proposed |
| `test/kiln/store/migrations_test.exs` | extended for 0003 + 0004 | Proposed |
| `test/fixtures/artifact/` | deterministic fixture databases | Proposed |
| `test/fixtures/evidence/` | protected failure matrix fixtures | Proposed |

Do not create provider, Repository-source, Context, Tool, Patch, Command, Gate, Finding, completion, Receipt, Child, TUI, MCP, or Wave B files.

## Acceptance criteria

- **P1-S02-T01-AC01** — Given an empty accepted local state directory; When `Kiln.Store.start/1` runs after migration 0004 is added; Then migrations 0001..0004 apply once, the new `artifacts` and `evidence_records` tables exist, and every accepted SQLite pragma remains verified. Evidence: startup test, schema introspection test, and `scripts/diagnostics/p1-s01-store-host` regression.
- **P1-S02-T01-AC02** — Given a deterministic byte payload; When `Kiln.Artifact.Store.put/2` runs; Then one Artifact row is recorded with `sha256:` content digest, `byte_size`, `content_kind`, `encoding`, `media_type`, `retention_class`, `producer_kind`, `producer_id`, `recorded_at`, `source_digest`; the same bytes produce the same digest; a different byte produces a different digest. Evidence: equality/inequality tests with fixture databases.
- **P1-S02-T01-AC03** — Given a malformed `producer_kind`, missing `content_kind`, or invalid digest; When `Kiln.Artifact.Store.put/2` is called; Then it returns `{:error, %Kiln.Store.Error{class: :artifact | :evidence}}` and writes no row. Evidence: vocabulary rejection fixtures.
- **P1-S02-T01-AC04** — Given a typed Evidence construction call (method, producer, subject_id, state_binding, freshness_class, completeness_class); When `Kiln.Evidence.new/1` runs; Then it returns a struct with deterministic canonical digest, rejects unknown freshness/completeness atoms, and rejects any `producer_kind` outside the bounded set. Evidence: canonical digest test, vocabulary rejection test.
- **P1-S02-T01-AC05** — Given the protected failure fixtures (replay_attack, contradiction, freshness_expired, incomplete, stale_state_binding); When the aggregate fixtures run; Then each receives its classified protected result (`:contradiction`, `:stale`, `:incomplete`, `:integrity`) and no false or partial durable state appears. Evidence: protected fixture matrix in `test/kiln/evidence_test.exs`.
- **P1-S02-T01-AC06** — Given the implementation and tests; When reviewed; Then no process exists solely for Artifact metadata or Evidence, no provider or Repository-source read is reachable, no nested transactions are introduced, and the existing `kiln-state/v1` format is preserved. Evidence: source inspection and a protected test that rejects nested use.
- **P1-S02-T01-AC07** — Given the exact branch head; When full Repository validation runs; Then all checks pass and no unauthorized external effect exists. Evidence: exact-head CI run and diff.

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test test/kiln/artifact test/kiln/evidence test/kiln/store
mix test
scripts/diagnostics/p1-s01-store-host
```

Owner-machine verification:

```bash
scripts/diagnostics/p1-s01-store-host
```

The diagnostic must continue to record exact host, filesystem, Exqlite, and SQLite facts and confirm the `store_format` remains `kiln-state/v1` after migrations 0003 and 0004 apply.

## Demo contribution

```text
P1-S02-D01 durable-substrate prerequisite: create one Artifact row from a deterministic byte payload, construct one typed Evidence row bound to the Artifact, exercise every protected failure fixture, and prove the resulting state survives restart through the existing kiln-state/v1 journal.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P1-S02-T01-E01 | P1-S02-T01-AC01 | startup, migration 0003 + 0004 apply, pragma verification output |
| P1-S02-T01-E02 | P1-S02-T01-AC02 | content-addressing equality and inequality fixture results |
| P1-S02-T01-E03 | P1-S02-T01-AC03 | producer/content_kind/encoding/media_type rejection fixture results |
| P1-S02-T01-E04 | P1-S02-T01-AC04 | canonical digest, vocabulary, and rejection fixture results |
| P1-S02-T01-E05 | P1-S02-T01-AC05 | protected failure matrix (replay_attack, contradiction, freshness_expired, incomplete, stale_state_binding) |
| P1-S02-T01-E06 | P1-S02-T01-AC06 | source review (no nested tx, no process, no provider/repo/patch/capability reachable) |
| P1-S02-T01-E07 | P1-S02-T01-AC07 | exact compare and CI run |

### Slice gate contribution

| Slice gate | Contribution |
| --- | --- |
| P1-S02-G06 | Prerequisite only: typed Evidence binds observations to an exact subject state; later Repository and model paths must prove the aggregate gate |
| P1-S02-G10 | Prerequisite only: freshness, completeness, contradiction, and stale-state classifications; later completion evaluation must prove the aggregate gate |
| P1-S02-G16 | Prerequisite only: durable raw Artifact substrate; later Gate registration, execution, cleanup, and terminal classification must prove the aggregate gate |

## Explicit exclusions

- No provider or fake-provider execution.
- No Repository source read or mutation.
- No Context, Tool, Patch, Approval, Command, native helper, Gate execution, Finding, Assurance, completion Evidence, product Receipt, release, Child, TUI, MCP, or Wave B behavior.
- No arm64 Mix release pipeline.
- No automatic corrupt-store repair or speculative flexibility.

## Completion record

**Result:** Candidate rejected; plan requires governance correction before replacement implementation.

### Exact adjudication state

- Authority base recorded by P0-W35: `dc375d923c99b9c754d9b53d601b214b0c8941a5`.
- Invalid first rebase: `01d4258c6abc9f53f0ddb1fb5e3999734af1dbca`; CI run [31293701028](https://github.com/jenksed/kiln/actions/runs/31293701028) failed authorization preflight because P0-W35 carried an incorrect plan digest.
- Corrected authority source: `d0f9cf424297d1b55f6d3d2bad9478555ebe03ed` through P0-W36.
- Correctly authorized adjudication head: `7ba158bddff76ade9aca79cb8501e675bd0cded9`.
- Exact-state CI: [31294035484](https://github.com/jenksed/kiln/actions/runs/31294035484), fully green.
- Pull request: PR #48, closed without merge.
- Runtime state on `main`: unchanged; no T01 implementation integrated.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S02-T01-AC01 | Not accepted | P1-S02-T01-E01 | migrations compile/test, but full accepted package failed adjudication |
| P1-S02-T01-AC02 | Not accepted | P1-S02-T01-E02 | content identity tests pass, but public API is `put/3` rather than accepted `put/2` |
| P1-S02-T01-AC03 | Not accepted | P1-S02-T01-E03 | bounded rejection tests pass; package rejected on higher-priority defects |
| P1-S02-T01-AC04 | Fail | P1-S02-T01-E04 | Evidence omits invariant-required result and has no persistence path |
| P1-S02-T01-AC05 | Fail | P1-S02-T01-E05 | tests do not produce required integrity/contradiction/stale/incomplete classifications |
| P1-S02-T01-AC06 | Not accepted | P1-S02-T01-E06 | narrow process boundary holds, but package is incomplete |
| P1-S02-T01-AC07 | Fail as completion Evidence | P1-S02-T01-E07 | CI green but required criteria are not satisfied |

### Blocking findings

1. `KILN-INV-030` requires Evidence to include method, producer, result, state binding, and freshness; the accepted plan and candidate omit result.
2. R04 says Evidence is persisted, while the candidate explicitly provides no runtime persistence path.
3. AC05/R06 requires protected classifications and no false durable state; the tests only observe metadata and defer classification.
4. Migration 0004 permits durable non-nil TTL and negative TTL through direct persistence.
5. The accepted plan names `Kiln.Artifact.Store.put/2`; the candidate exposes `put/3`.

### Required next action

Return to governance planning. Reconcile the Evidence result/status shape with `KILN-INV-030`, define persistence ownership, specify protected-classification semantics, correct the TTL database invariant, and resolve the Artifact API arity. Only then may the owner accept a replacement T01 plan and issue a new authorization. No P1-S02 runtime work is currently authorized.
