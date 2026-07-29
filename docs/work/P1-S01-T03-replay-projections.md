# P1-S01-T03: Implement replay, projections, and restart reconstruction

**Document type:** Implementation plan  
**Status:** Accepted  
**Parent slice:** P1-S01  
**Branch:** `work/p1-s01-t03-replay-projections`  
**Depends on:** P1-S01-T02 merged and accepted

## Slice contribution

P1-S01 enables one durable Root Session that survives restart.

This ticket adds deterministic journal replay, rebuildable Session projections, restart reconstruction, and protected handling of duplicate, stale, out-of-order, corrupt, and unknown-operation records.

It contributes to P1-S01-G04 through G07 and supplies replay and restart references to P1-S01-V01.

After merge, the application can reconstruct durable state through application APIs and tests. The user-facing foundation CLI remains T04.

## Objective

Implement one deterministic reducer and projection boundary that reconstructs the accepted current Session, initial Task, Root Run, decisions, external operations, revision, warnings, and unknowns from the journal and verifies stored projections without inferring state from transcripts.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| T01 supplies accepted pure domain types and transitions | accepted ticket output | preceding ticket | merged state |
| T02 supplies the append journal, revisions, idempotency, migrations, and integrity boundary | accepted ticket output | preceding ticket | merged state |
| P0-W21 requires one immutable journal and rebuildable current projection | focused lifecycle authority | integrated planning | current authority |
| Transcript records cannot alter work state | P0-W21 and Session authority | integrated planning | current authority |
| No projection reducer, replay, rebuild, or restart API existed at Wave A authorization | Repository inspection | Prompt 8-A | baseline |

## Assumptions and unknowns

### Assumptions

- **P1-S01-T03-A01:** One pure reducer over ordered accepted journal entries is sufficient for first-month projection rebuild.
- **P1-S01-T03-A02:** Stored current projections are caches and can be discarded and rebuilt from the journal.
- **P1-S01-T03-A03:** Repository source state is not needed for P1-S01 replay; selected-root metadata is sufficient.

### Unknowns

- **P1-S01-T03-U01:** Exact replay batching may be selected from measured fixture performance, but correctness cannot depend on batch size.
- **P1-S01-T03-U02:** Corrupt journal repair is not authorized; the cheapest safe behavior is to identify the first invalid boundary and block.

## Requirements

- **P1-S01-T03-R01:** Kiln shall reduce accepted journal entries in deterministic sequence order into one current Session projection.
- **P1-S01-T03-R02:** Replay shall start from zero and shall not trust a stored projection as source truth.
- **P1-S01-T03-R03:** The reducer shall validate sequence continuity, prior revision, action digest, resulting revision, event kind, and required payload shape.
- **P1-S01-T03-R04:** Duplicate identical action entries shall not create duplicate projected effects.
- **P1-S01-T03-R05:** Conflicting duplicate, missing sequence, out-of-order, invalid-transition, unknown-kind, or corrupt entry shall block reconstruction with the exact failing boundary.
- **P1-S01-T03-R06:** Transcript entries shall remain ordered interaction records and shall not change objective, criteria, Task, Run, decision, operation, or completion state.
- **P1-S01-T03-R07:** Restart reconstruction shall restore Session, Task, Root Run, workflow step, revision, pending decision, external-operation state, warnings, exclusions, and unknowns.
- **P1-S01-T03-R08:** A nonterminal external-operation intent without a proved terminal observation shall reconstruct as an unknown operation and an `orphaned` Root Run when P0-W21 requires it.
- **P1-S01-T03-R09:** Restart shall not dispatch, replay, or simulate an external effect.
- **P1-S01-T03-R10:** Stored projections shall include the journal sequence and reducer version used to create them.
- **P1-S01-T03-R11:** Kiln shall compare a stored projection with a rebuild and shall replace a stale or mismatched projection only after the journal validates completely.
- **P1-S01-T03-R12:** Unknown or corrupt journal state shall block normal work and preserve the database and diagnostic facts.

## Security boundary

Allowed:

- read journal and projection records from the accepted local store;
- pure deterministic reduction;
- replace rebuildable projection rows after full successful validation;
- fixture database creation in temporary test paths;
- deterministic crash and restart tests.

Denied:

- Repository source reads or writes;
- provider, network, credential, Tool, Patch, Command, helper, Evidence completion, product Receipt, release, Child, TUI, or Wave B behavior;
- inferring current state from transcript text;
- automatic replay of an external effect;
- destructive journal repair;
- skipping an unknown or corrupt entry.

## Proposed changes

1. Add the versioned journal reducer.
2. Add the current Session projection shape and persistence adapter.
3. Add rebuild-from-zero and compare-with-stored-projection operations.
4. Add startup reconstruction through the store boundary.
5. Add duplicate, out-of-order, invalid-transition, corrupt-entry, transcript-separation, and unknown-operation fixtures.
6. Add deterministic crash points around projection updates to prove the journal remains authoritative.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `lib/kiln/journal/reducer.ex` | pure versioned entry reduction | Proposed |
| `lib/kiln/journal/replay.ex` | ordered journal loading and validation | Proposed |
| `lib/kiln/projections/session.ex` | current first-month projection type | Proposed |
| `lib/kiln/projections/store.ex` | projection read, compare, and replace boundary | Proposed |
| `lib/kiln/restart.ex` | startup reconstruction result and blocking errors | Proposed |
| `lib/kiln/store.ex` | expose bounded replay and projection transactions | Proposed |
| `test/kiln/journal/` | reducer and replay tests | Proposed |
| `test/kiln/projections/` | rebuild and stored-projection tests | Proposed |
| `test/kiln/restart_test.exs` | exact restart behavior | Proposed |
| `test/fixtures/journal/` | duplicate, out-of-order, corrupt, unknown, and transcript fixtures | Proposed |

## Acceptance criteria

- **P1-S01-T03-AC01**
  - **Given** a valid journal fixture
  - **When** replay begins from zero
  - **Then** it returns the exact expected Session projection and revision byte-for-byte
  - **Evidence:** reducer fixture test and digest
- **P1-S01-T03-AC02**
  - **Given** identical duplicate submission, conflicting duplicate, missing sequence, out-of-order entry, invalid transition, or corrupt payload
  - **When** replay runs
  - **Then** the accepted duplicate has no duplicate effect and every unsafe case blocks at the exact boundary
  - **Evidence:** protected replay fixtures
- **P1-S01-T03-AC03**
  - **Given** transcript records mixed with domain entries
  - **When** replay runs
  - **Then** transcript ordering is retained without changing authoritative work state
  - **Evidence:** transcript separation fixture
- **P1-S01-T03-AC04**
  - **Given** a nonterminal operation intent at restart
  - **When** reconstruction runs
  - **Then** no effect is dispatched and the operation and Run reconstruct conservatively as required by P0-W21
  - **Evidence:** unknown-operation restart fixture
- **P1-S01-T03-AC05**
  - **Given** missing, stale, correct, or mismatched stored projections
  - **When** startup compares them with a full rebuild
  - **Then** correct projections are accepted, safe mismatches are rebuilt, and incomplete or corrupt journal state blocks
  - **Evidence:** projection compare and crash fixtures
- **P1-S01-T03-AC06**
  - **Given** the exact branch head
  - **When** full validation runs
  - **Then** all checks pass and no excluded capability is reachable
  - **Evidence:** exact-head CI and compare

## Deterministic verification

```bash
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test test/kiln/journal test/kiln/projections test/kiln/restart_test.exs
mix test
```

Every replay fixture shall use fixed journal bytes, revisions, and timestamps.

## Demo contribution

```text
P1-S01-D01 steps 6 through 9: stop the application, restart it, and display the exact reconstructed objective, criteria, Task, Root Run, decision, operation, warnings, unknowns, and revision through an internal demonstration function.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P1-S01-T03-E01 | P1-S01-T03-AC01 | valid replay output and digest |
| P1-S01-T03-E02 | P1-S01-T03-AC02 | duplicate, order, transition, and corruption fixture results |
| P1-S01-T03-E03 | P1-S01-T03-AC03 | transcript-separation projection comparison |
| P1-S01-T03-E04 | P1-S01-T03-AC04 | unknown-operation restart result |
| P1-S01-T03-E05 | P1-S01-T03-AC05 | projection rebuild and crash-injection results |
| P1-S01-T03-E06 | P1-S01-T03-AC06 | exact compare and CI run |

### Slice gate contribution

| Slice gate or verification manifest | Contribution |
| --- | --- |
| P1-S01-G04 | duplicate, stale, out-of-order, and corrupt action handling |
| P1-S01-G05 | deterministic projection rebuild |
| P1-S01-G06 | transcript separation |
| P1-S01-G07 | restart reconstruction and unknown-operation behavior |
| P1-S01-V01 | reducer version, fixture digests, results, warnings, and exclusions |

## Explicit exclusions

- No user-facing CLI.
- No Repository source read or mutation.
- No provider or fake-provider execution.
- No Context, Tool, Patch, Approval, Command, helper, criterion completion Evidence, product Receipt, release, Child, TUI, or Wave B behavior.
- No automatic journal repair or external-effect retry.
- No event bus, message broker, distributed log, or generic event-sourcing framework.

## Completion record

**Result:** Implemented but unverified

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T03-AC01 | Pending | P1-S01-T03-E01 | pending |
| P1-S01-T03-AC02 | Pending | P1-S01-T03-E02 | pending |
| P1-S01-T03-AC03 | Pending | P1-S01-T03-E03 | pending |
| P1-S01-T03-AC04 | Pending | P1-S01-T03-E04 | pending |
| P1-S01-T03-AC05 | Pending | P1-S01-T03-E05 | pending |
| P1-S01-T03-AC06 | Pending | P1-S01-T03-E06 | pending |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| pending | pending | pending |

### Demo and slice status

- Ticket demo contribution: Not yet exercised
- Parent slice gate affected: P1-S01-G04 through G07
- Slice verification manifest updated: No
- Slice completion claimed: No

### Failures and warnings

- None recorded before implementation.

### Remaining unknowns and exclusions

- User interaction is T04.

### Repository state

- Commit: pending
- Branch: `work/p1-s01-t03-replay-projections`
- Diff reviewed: No
- Exact CI run: pending
- Parent slice status after merge: unchanged
