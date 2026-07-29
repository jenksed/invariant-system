# P1-S01-T02: Implement the durable store boundary

**Document type:** Implementation plan  
**Status:** Accepted  
**Parent slice:** P1-S01  
**Branch:** `work/p1-s01-t02-durable-store`  
**Depends on:** P1-S01-T01 merged and accepted

## Slice contribution

P1-S01 enables one durable Root Session that survives restart.

This ticket adds the direct Exqlite store, startup checks, numbered forward migrations, append transaction, expected revision, idempotency, and integrity boundary for the pure domain actions accepted in T01.

It contributes to P1-S01-G03 and G04 and supplies store and Environment facts to P1-S01-V01.

After merge, durable records exist, but deterministic replay, current projections, and the user CLI remain incomplete.

## Objective

Implement one supervised direct Exqlite connection and one-writer store that atomically appends accepted journal entries, advances Session revision, records idempotency results, and enforces the accepted SQLite durability and migration rules without implementing product effects.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| P0-W21 selects direct Exqlite, one writer, WAL, `synchronous=FULL`, foreign keys, busy timeout, and immediate writes | focused lifecycle authority and ADR-0022 | integrated planning | current authority |
| PR 35 requires bundled SQLite 3.51.3 or newer and forbids dependency on nested first-month transactions | ADR-0022 evidence correction | Repository authority | current `main` |
| No SQLite dependency, database, migration, store process, or state path exists | `mix.exs`, `lib/`, `priv/` | Repository inspection | after T01 baseline |
| T01 supplies pure action and state types | accepted T01 plan | Prompt 8-A | preceding ticket |

## Assumptions and unknowns

### Assumptions

- **P1-S01-T02-A01:** One supervised Exqlite connection and one writer are sufficient for the single foreground first-month workflow.
- **P1-S01-T02-A02:** Numbered SQL migration files with stored checksums are sufficient; no migration framework is required.
- **P1-S01-T02-A03:** The store can use one immediate transaction per accepted application action and does not need nested transactions or savepoints.

### Unknowns

- **P1-S01-T02-U01:** The exact Exqlite release shall be selected during implementation only after verifying its bundled SQLite version is 3.51.3 or newer.
- **P1-S01-T02-U02:** The owner-machine APFS and sync observations must be collected; stronger macOS sync pragmas require measured Evidence and are not assumed.
- **P1-S01-T02-U03:** Exact corruption recovery beyond safe blocking and preservation can remain later work if the first store cannot prove repair safely.

## Requirements

- **P1-S01-T02-R01:** The application shall supervise one store connection on the accepted local state path.
- **P1-S01-T02-R02:** Store startup shall verify the OD-02 host and local filesystem requirements needed by this ticket and shall block unsupported authoritative state paths.
- **P1-S01-T02-R03:** The selected Exqlite dependency shall bundle SQLite 3.51.3 or newer.
- **P1-S01-T02-R04:** Startup shall enable and verify WAL, `synchronous=FULL`, foreign keys, a two-second busy timeout, and the accepted journal pragmas.
- **P1-S01-T02-R05:** The store shall use one writer and immediate write transactions.
- **P1-S01-T02-R06:** The implementation shall not use nested first-month transactions or depend on nested savepoint behavior.
- **P1-S01-T02-R07:** Kiln shall own numbered forward SQL migrations and persist migration checksums.
- **P1-S01-T02-R08:** Startup shall reject a modified applied migration, an unsupported future store version, failed integrity checks, or incompatible runtime version without mutating work state.
- **P1-S01-T02-R09:** One accepted action shall atomically append its journal entry or entries, advance the Session revision, and persist its idempotency result.
- **P1-S01-T02-R10:** An expected-revision mismatch shall make no durable change.
- **P1-S01-T02-R11:** Reusing an idempotency key with the same accepted action shall return the prior result without duplicate journal effects.
- **P1-S01-T02-R12:** Reusing an idempotency key with a different action digest shall fail explicitly.
- **P1-S01-T02-R13:** Transaction failure shall leave no partial journal, revision, or idempotency state.
- **P1-S01-T02-R14:** The journal shall not store complete transcript content, Artifact payloads, secrets, hidden reasoning, or Repository source.
- **P1-S01-T02-R15:** Store errors shall distinguish busy, integrity, migration, future-version, revision, idempotency-conflict, I/O, and unknown failures.

## Security boundary

Allowed:

- project-scoped Exqlite runtime dependency;
- one local SQLite database under `$KILN_HOME`;
- local migration SQL files;
- exact metadata and journal records defined by P0-W21 and T01;
- local APFS fixture databases;
- injected fault fixtures and temporary directories.

Denied:

- network access;
- provider or credential access;
- Repository source read or write;
- shell or external Command;
- product mutation, Evidence, Receipt, release, Child, TUI, or Wave B behavior;
- database repair that overwrites an unclassified corrupt store;
- nested transactions or hidden transaction retry.

A busy, corrupt, incompatible, or uncertain store blocks the action and preserves available Evidence.

## Proposed changes

1. Select and pin one Exqlite release meeting the accepted SQLite baseline.
2. Add the supervised store connection and startup validation.
3. Add numbered migration files and checksum tracking.
4. Add journal, revision, idempotency, and minimum record tables required by P1-S01.
5. Add one immediate append transaction and explicit store result mapping.
6. Add deterministic migration, rollback, busy, revision, idempotency, integrity, and future-version fixtures.
7. Add owner-machine diagnostic output for exact SQLite and filesystem facts.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `mix.exs` and `mix.lock` | pin accepted Exqlite dependency | Proposed |
| `lib/kiln/application.ex` | supervise the single store boundary | Proposed |
| `lib/kiln/store.ex` | public store startup and action transaction boundary | Proposed |
| `lib/kiln/store/connection.ex` | one supervised Exqlite connection owner | Proposed |
| `lib/kiln/store/migrations.ex` | migration discovery, checksum, and application | Proposed |
| `lib/kiln/store/journal.ex` | append, revision, and idempotency transaction | Proposed |
| `lib/kiln/store/error.ex` | stable store error mapping | Proposed |
| `priv/store/migrations/` | numbered forward SQL migrations | Proposed |
| `test/kiln/store/` | deterministic store and migration tests | Proposed |
| `test/fixtures/store/` | future-version, corruption, and migration fixtures | Proposed |
| `scripts/diagnostics/p1-s01-store-host` | bounded owner-machine diagnostics | Proposed |

Do not create provider, Repository-source, Patch, Command, Evidence, product Receipt, or CLI modules.

## Acceptance criteria

- **P1-S01-T02-AC01**
  - **Given** an empty accepted local state directory
  - **When** the store starts
  - **Then** it creates the current schema, records checksums, enables and verifies required pragmas, and reports exact SQLite version
  - **Evidence:** startup test and owner-machine diagnostic
- **P1-S01-T02-AC02**
  - **Given** one valid T01 domain action at the current revision
  - **When** the append transaction commits
  - **Then** journal, revision, and idempotency result change atomically
  - **Evidence:** transaction test and direct database observations
- **P1-S01-T02-AC03**
  - **Given** a stale revision, duplicate identical action, duplicate conflicting action, or injected transaction failure
  - **When** append is attempted
  - **Then** each receives the accepted explicit result and no false or partial durable state appears
  - **Evidence:** protected transaction fixtures
- **P1-S01-T02-AC04**
  - **Given** a valid older store, modified migration, future store, or corrupt fixture
  - **When** startup runs
  - **Then** the valid store migrates once and every unsafe fixture blocks without destructive repair
  - **Evidence:** migration and integrity fixture results
- **P1-S01-T02-AC05**
  - **Given** the implementation and tests
  - **When** reviewed
  - **Then** no nested transaction or nested savepoint dependency exists
  - **Evidence:** source inspection and a protected test that rejects nested use
- **P1-S01-T02-AC06**
  - **Given** the exact branch head
  - **When** full Repository validation runs
  - **Then** all checks pass and no unauthorized external effect exists
  - **Evidence:** exact-head CI and compare

## Deterministic verification

```bash
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test test/kiln/store
mix test
```

Owner-machine verification:

```bash
scripts/diagnostics/p1-s01-store-host
```

The diagnostic must record exact host, filesystem, Exqlite, and SQLite facts without reading Repository source or secrets.

## Demo contribution

```text
P1-S01-D01 durable-state prerequisite: create a Session action transaction, stop the application, and prove the journal and revision remain available for T03 replay.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P1-S01-T02-E01 | P1-S01-T02-AC01 | startup, pragma, migration, and version output |
| P1-S01-T02-E02 | P1-S01-T02-AC02 | atomic append transaction results |
| P1-S01-T02-E03 | P1-S01-T02-AC03 | revision, idempotency, and rollback fixture results |
| P1-S01-T02-E04 | P1-S01-T02-AC04 | migration, future-version, and corruption results |
| P1-S01-T02-E05 | P1-S01-T02-AC05 | nested-transaction source and test audit |
| P1-S01-T02-E06 | P1-S01-T02-AC06 | exact compare and CI run |
| P1-S01-T02-E07 | owner-machine gate | host and filesystem diagnostic Artifact |

### Slice gate contribution

| Slice gate or verification manifest | Contribution |
| --- | --- |
| P1-S01-G03 | store, migration, integrity, transaction, revision, and idempotency Evidence |
| P1-S01-G04 | duplicate, stale, conflict, and rollback Evidence |
| P1-S01-V01 | dependency, SQLite, migration, Environment, warnings, and exclusions |

## Explicit exclusions

- No Repository source read or mutation.
- No provider or fake-provider execution.
- No Context, Tool, Patch, Approval, Command, native helper, Evidence completion, product Receipt, CLI, release, Child, TUI, or Wave B behavior.
- No automatic corrupt-store repair.
- No nested transactions.
- No broad connection pool or generalized storage abstraction.

## Completion record

**Result:** Complete

All six acceptance criteria pass, the full deterministic verification gate ran green at the exact branch head, and the owner-machine diagnostic was executed on the OD-02 acceptance host. Review, merge, and slice acceptance remain downstream and are not claimed here.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T02-AC01 | Pass | P1-S01-T02-E01 | `Kiln.Store.start/1` on an empty directory creates the schema, records the 0001 checksum, verifies WAL / `synchronous=FULL` / foreign keys / 2s busy timeout, and reports SQLite 3.53.3 |
| P1-S01-T02-AC02 | Pass | P1-S01-T02-E02 | `Kiln.Store.Journal.commit/4` atomically appends the entry, advances the Session revision, and writes the idempotency result; direct row assertions confirm all three |
| P1-S01-T02-AC03 | Pass | P1-S01-T02-E03 | stale revision → `:revision` with current; duplicate identical → replayed prior result, no new entry; duplicate conflicting → `:idempotency_conflict`; injected fault → no partial journal, revision, or idempotency state |
| P1-S01-T02-AC04 | Pass | P1-S01-T02-E04 | fresh store migrates once; modified applied checksum → `migration_blocked`; store from a newer binary → `version_blocked`; corrupt fixture → `integrity_blocked` with the file preserved |
| P1-S01-T02-AC05 | Pass | P1-S01-T02-E05 | source uses one outer `BEGIN IMMEDIATE` per action (no savepoints); a protected test shows SQLite rejects a nested transaction |
| P1-S01-T02-AC06 | Pass | P1-S01-T02-E06 | full deterministic gate exits zero at exact head `4a9846e`; no unauthorized external effect (no Repository read, provider, shell, or network) |

Owner-machine gate (E07): `scripts/diagnostics/p1-s01-store-host` executed on the OD-02 acceptance host (this M1 Pro).

### Verification executed

Toolchain: Elixir 1.20.2 / Erlang OTP 28 (repo `mise.toml`); `jsonschema==4.26.0`. Executed at commit `4a9846e1b03a37fcd300ee2943cf364d341024ed`.

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| `scripts/test-agent-preflight` | 0 | `pass` |
| `python3 scripts/validate_first_month_contracts.py` | 0 | `pass`; 10 positive, 11 protected-negative |
| `python3 scripts/validate_json_schema_contracts.py` | 0 | `pass`; jsonschema 4.26.0 |
| `scripts/validate-agent-assets` | 0 | `pass` |
| `mix deps.get` | 0 | exqlite 0.39.0 + db_connection, elixir_make, cc_precompiler, telemetry |
| `mix format --check-formatted` | 0 | no output |
| `mix compile --warnings-as-errors` | 0 | clean |
| `mix xref graph --format cycles --label compile-connected --fail-above 0` | 0 | `No cycles found` |
| `mix test test/kiln/store` | 0 | 18 passed |
| `mix test` | 0 | 44 passed |
| `scripts/check` (aggregate) | 0 | `check: pass`; commit `68e4db0` (pre-doc), re-run clean at tip |
| `scripts/diagnostics/p1-s01-store-host` | 0 | `pass` (see owner-machine evidence below) |

Owner-machine diagnostic output (OD-02 host):

```text
macos_product_version: 26.5.2
macos_build_version: 25F84
architecture: arm64
filesystem_personality: APFS
device_location: Internal
erlang_otp: 28
elixir: 1.20.2
git: 2.50.1
exqlite: 0.39.0
embedded_sqlite: 3.53.3
store_format: kiln-state/v1
store_version: 1
journal_mode: wal  synchronous: 2  foreign_keys: 1  busy_timeout: 2000  quick_check: ok
startup: ready
```

### Demo and slice status

- Ticket demo contribution: Exercised in `Kiln.Store.JournalTest` and `Kiln.StoreTest` — a Session action transaction commits, and a fresh `Kiln.Store.start/1` restores the journal, revision, and projection from disk for T03 replay
- Parent slice gate affected: P1-S01-G03 and G04
- Slice verification manifest updated: No
- Slice completion claimed: No

### Failures and warnings

- None. All verification commands exited zero at the exact head.
- The busy fixture (`@tag :slow`) logs an expected Exqlite "database is locked" disconnect while the contending writer holds the WAL lock; the append is classified `:busy` and the test passes. No product source is affected.
- Environment note: verification used the repo-pinned mise Elixir 1.20.2 / OTP 28 toolchain and a virtualenv holding `jsonschema==4.26.0`; adding the first `deps/` required scoping the `scripts/check` Vale run to exclude `deps/` and `_build/`. No product source, dependency, or store behavior was changed to make the gate pass.

### Remaining unknowns and exclusions

- Deterministic replay (startup step 9), projection rebuild, and nonterminal-operation orphan scanning (steps 10-11) are T03; startup currently reaches `:ready` for fresh and migrated stores.
- U01 (exact Exqlite release) resolved to 0.39.0 / SQLite 3.53.3. U02 (macOS APFS sync observations) recorded via the diagnostic; `synchronous=FULL` retained, no `fullfsync` change. U03 (corruption repair) remains later work: a corrupt store blocks and preserves files, with no automatic repair.

### Repository state

- Commit: `4a9846e1b03a37fcd300ee2943cf364d341024ed`
- Branch: `work/p1-s01-t02-durable-store`
- Diff reviewed: Yes; `mix.exs`/`mix.lock`, ten `lib/kiln/store/*` and `lib/kiln/store.ex`/`application.ex` modules, `priv/store/migrations/0001_initial_state.sql`, the store test suite, and the OD-02 diagnostic (1984 insertions, 5 deletions versus `main`)
- Exact CI run: full local gate green at exact head; authoritative CI run and owner review pending on the pull request
- Parent slice status after merge: durable records exist; deterministic replay, current projections, and the CLI remain T03 and later
