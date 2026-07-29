# ADR-0022: Use direct Exqlite for the first state store

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Integrated through pull request 27  
**Date:** 2026-07-28  
**Work package:** P0-W21  
**Supersedes:** None

## Context

Kiln needs one local durable store for the first-month Session, Task, Root Run, journal, action-idempotency, current-projection, migration, transcript-reference, and restart-reconstruction contracts.

The first store has a small explicit schema and one local writer. Its primary operations are ordered append, atomic projection update, deterministic replay, migration, and recovery. Kiln does not yet need a relational domain model, association loading, a query builder, multiple database adapters, or a general persistence framework.

The selected library will own the live SQLite connection process. Kiln will own the SQL, migrations, transaction boundaries, domain mapping, replay, and error classification.

## Decision drivers

- Keep journal transaction and recovery behavior explicit.
- Add only the dependency needed for one SQLite store.
- Preserve one-writer and one-connection assumptions.
- Avoid an ORM or repository abstraction before a real query need exists.
- Support supervised connection ownership, transactions, busy handling, interruption, and current SQLite behavior.
- Keep migration checksums and startup failures visible to Kiln.
- Avoid depending on nested-transaction behavior that the selected driver does not model robustly.
- Pin a bundled SQLite version that contains the accepted WAL-reset corruption fix.

## Considered options

### Option A: Direct Exqlite

Use `:exqlite` directly through `Exqlite.Connection` and its DBConnection-compatible interface.

**Advantages**

- Small boundary around SQLite.
- Direct control of SQL, transaction mode, pragmas, migrations, and result-code handling.
- One supervised connection process is sufficient for the first local writer.
- Avoids Ecto schemas, changesets, repositories, and migration conventions that Kiln does not need yet.
- Keeps replay and projection ownership in Kiln.

**Disadvantages**

- Kiln must own SQL and row mapping.
- Kiln must define and test its migration runner.
- Exqlite's current nested transaction implementation does not support arbitrary savepoint depth.
- Later complex query needs might justify a higher-level boundary.

### Option B: Ecto with `ecto_sqlite3`

Use an Ecto Repository, Ecto schemas, and Ecto migrations.

**Advantages**

- Mature data mapping and migration tooling.
- Familiar query and changeset interfaces.
- Easier expansion if a broad relational model becomes necessary.

**Disadvantages**

- Adds Ecto and adapter concepts before the product needs them.
- Encourages one schema or table per domain noun.
- Can hide the journal transaction and projection boundary behind repository conventions.
- Increases dependency and configuration surface for one explicit local store.

### Option C: Raw SQLite port, CLI, or custom NIF

Own the SQLite boundary without Exqlite.

**Advantages**

- Maximum implementation control.

**Disadvantages**

- Reimplements mature connection, resource, and error handling.
- Adds safety and maintenance work with no current product value.

## Decision

Select Option A.

The first state-store boundary is:

1. Use direct Exqlite.
2. Start one supervised Exqlite connection for `$KILN_HOME/state.sqlite3`.
3. Use one writer connection and no pool expansion in the first month.
4. Let the Exqlite connection process own the live database Resource.
5. Keep `Kiln.Store` as plain modules and functions that own SQL, migrations, transactions, row mapping, projection persistence, and error classification.
6. Use WAL mode, `synchronous=FULL`, foreign keys, a two-second busy timeout, immediate write transactions, and local-host storage.
7. Use Kiln-owned forward SQL migrations with stable checksums.
8. Do not add Ecto, `ecto_sqlite3`, an ORM, one table per domain noun, or a generalized persistence behaviour for the first store.
9. Reconsider a higher-level data layer only after accepted implementation Evidence shows repeated relational-query, mapping, or multi-store needs that direct Exqlite cannot meet cleanly.
10. Pin an Exqlite release whose bundled SQLite contains the WAL-reset corruption fix introduced in SQLite 3.51.3. The current reviewed Exqlite 0.39.0 line bundles SQLite 3.53.3.
11. Do not enable `EXQLITE_USE_SYSTEM=1` in the first supported build unless the effective system SQLite version, compile options, and compatibility are explicitly verified and recorded.
12. Do not use nested first-month store transactions or depend on nested savepoints. One application action owns one outer store transaction; a called store function must participate in that transaction rather than begin another.
13. Keep `synchronous=FULL` as the accepted initial durability setting. Do not add macOS `fullfsync` or `checkpoint_fullfsync` based only on secondary claims. A later change requires primary-source review plus measured OD-02 host Evidence because official SQLite documentation treats these as optional macOS-specific sync controls and states that `checkpoint_fullfsync` is irrelevant when `fullfsync` is enabled.

## Consequences

### Positive

- P1-S01 can implement the accepted journal and projection contract without a second persistence architecture.
- The first justified supervised child owns a real connection Resource.
- SQLite transaction, busy, corruption, and migration behavior remain visible.
- Domain records and projections stay plain data.
- The first store avoids a known WAL-reset bug class and does not rely on fragile nested savepoint behavior.

### Negative

- Kiln must maintain explicit SQL and mappings.
- Migration and compatibility checks are Kiln responsibilities.
- Developers cannot rely on Ecto conveniences in the initial store.
- Store functions must be structured around one explicit outer transaction rather than composable nested transactions.

### Neutral or operational

- The dependency is selected by planning but must not be added until Prompt 8 authorizes the relevant ticket.
- Exact supported Exqlite version will be pinned and reviewed in the authorized dependency change.
- The state database is not a portable snapshot unless the WAL state is handled through an accepted SQLite backup or closed-store procedure.
- Stronger macOS sync behavior can be considered after actual latency and durability Evidence exists; it is not silently assumed from a research note.

## Evidence and assumptions

### Observed evidence

| Claim | Evidence | Date or commit |
| --- | --- | --- |
| Kiln needs one append-oriented SQLite journal | ADR-0002; ADR-0020; `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md` | P0-W21 |
| The current product has no persistence dependency or implementation | `mix.exs`; `docs/IMPLEMENTATION-ASSET-INVENTORY.md` | `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| Exqlite exposes a connection and transaction boundary suitable for direct use | official Exqlite documentation and source | rechecked 2026-07-29 |
| Exqlite source states its current transaction-state implementation does not handle more than two transaction levels | upstream `Exqlite.Connection` source | rechecked 2026-07-29 |
| SQLite permits one writer and supports WAL and immediate transactions | official SQLite documentation | rechecked 2026-07-29 |
| SQLite 3.51.3 fixed the WAL-reset database corruption bug | official SQLite release notes | rechecked 2026-07-29 |
| Exqlite 0.38.0 updated its bundled SQLite to 3.53.3 and 0.39.0 did not downgrade it | upstream Exqlite changelog | rechecked 2026-07-29 |
| `fullfsync` and `checkpoint_fullfsync` are optional macOS controls; `checkpoint_fullfsync` is irrelevant when `fullfsync` is enabled | official SQLite PRAGMA documentation | rechecked 2026-07-29 |

### Inferences

- Direct Exqlite is the smallest sufficient boundary because the first store has one writer, explicit SQL, and a journal-centered access pattern.
- Ecto would provide useful capabilities, but those capabilities do not address a current first-month blocker.
- Avoiding nested transactions is simpler and safer than designing around a driver limitation the first workflow does not need.
- Pinning a bundled SQLite with the WAL-reset fix is a low-cost safety requirement.

### Assumptions

- Exqlite remains compatible with the accepted Elixir and OTP versions when implementation begins. The authorized dependency ticket must verify the exact current release.
- One connection meets first-month throughput and concurrency requirements.

### Unknowns

- **Unknown:** Exact performance under the eventual journal fixtures. Verify during the authorized store ticket without changing the one-writer contract unless Evidence requires a new decision.
- **Unknown:** Whether later read-heavy projections need separate read connections. Reconsider only after measured need.
- **Unknown:** Whether enabling `fullfsync` on the owner's OD-02 host provides an acceptable durability benefit for its latency cost. This is not a first-month default without measured Evidence.

## Verification

The authorized persistence ticket must prove:

- one supervised Exqlite connection starts and stops cleanly;
- the exact Exqlite version is pinned;
- the effective bundled SQLite version is reported and is at least 3.51.3;
- system SQLite substitution is absent or explicitly verified;
- accepted pragmas and immediate transactions are applied;
- no store path relies on nested transactions or nested savepoints;
- append, projection update, and action result commit atomically;
- busy, migration, unsupported-version, corruption, rollback, and uncertain-commit fixtures produce the planned results;
- no Ecto, ORM, pool expansion, or process per domain record enters the implementation.

## Superseded decisions

None.
