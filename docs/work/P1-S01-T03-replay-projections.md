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

**Result:** Complete after four PR #39 review rounds

Four review rounds corrected defects the green test suite did not catch. Review `4810420585` found five issues (D1 to D5); review `4812134584` found three (D6 to D8); review `4812387784` found four (D9 to D12); review `4813027808` found three plus a hardening audit (D13 to D15). All are corrected with protected tests that fail before each fix. All six acceptance criteria pass at the new exact head. Review, merge, and slice acceptance remain downstream and are not claimed here.

### Final hardening corrections (review 4813027808)

The central invariant is now established: every accepted journal prefix either deterministically produces one internally valid projection or blocks at a stable, bounded, inspectable boundary. It never produces contradictory state, silently accepts an invalid fact, or crashes on corrupt durable input.

- **D13 Contradictory projections were possible.** The reducer validated individual transitions but could produce an internally impossible projection (a pending decision on a ready Run, a nonterminal operation outside running, a terminal Run without coordinated Task and Session state). Fix: `Kiln.Projections.Session.validate/1`, one pure invariant validator applied after every reduction in both commit and replay. The reducer now enforces the start contract, coordinates terminal Run, Task, and Session state, uses an operation-state progression (`started` keeps the Run running; regression blocks), and rejects a start whose payload Session id or states contradict the contract.
- **D14 Decision responses were unvalidated.** `user_decision_recorded/v1` checked the decision id but not the response. Fix: the response must be a non-empty string present in the pending decision's `permitted_responses`, else `:decision_response_not_permitted`.
- **D15 Corrupt durable input could crash or misbehave.** Replay performed arithmetic on unverified revisions and sequences, schemas were unbound, opaque ids unvalidated, and commit could crash on malformed input, a corrupt stored idempotency result, or a corrupt cache. Fix: revisions and sequences are validated as non-negative integers before any arithmetic; envelope and payload schemas bind to one shared authority; opaque ids validate through `Kiln.Domain.Id.validate/2`; and `commit/4` is total for an empty or malformed batch, a corrupt stored result, and a corrupt cache, each returning a stable classified error with no durable change.

### Verified hardening statements

- All accepted journal facts pass the projection-invariant validator.
- Invalid decision responses block.
- Durable numeric corruption cannot trigger arithmetic exceptions.
- Entry and payload schemas are bound to one shared authority.
- Terminal Run state agrees with Session and Task state.
- Operation observations follow a defined state progression.
- Commit and replay remain byte-identical.
- No external effect is dispatched during replay or restart.

### Third review corrections (review 4812387784)

- **D9 Session start could store contradictory facts.** The decoder accepted any known states and the reducer copied them, so a start entry could record a completed Session with an orphaned Run, and the payload Session id was not bound to the envelope. Fix: the reducer enforces the atomic start contract (active Session, in_progress Task, ready Root Run, intent step) and binds the payload Session id to the envelope Session id. A start-contract violation at commit rolls back cleanly as `:invalid_entry`.
- **D10 Validation order regressed idempotent replay.** Entry decoding ran before the idempotency check, so a valid duplicate with regenerated entries could fail instead of replaying. Fix: decode entries only after `existing_commit/2` returns `:none`; a duplicate replays its stored result first.
- **D11 Corrupt sequence bounds could exhaust memory.** Replay built `Enum.to_list(first..last)` from database values. Fix: validate the bounds arithmetically (integer, `first <= last`, row count, per-index sequence) and never materialize an untrusted range.
- **D12 Restart digest did not describe the returned projection.** For a nonterminal operation the returned projection changed but the digest stayed the journal digest. Fix: expose `journal_projection_digest` and `reconstructed_projection_digest`; the reconstructed digest matches the returned projection.

### Second review corrections (review 4812134584)

- **D6 Commit and replay did not share entry validation.** Replay decoded entries; `Kiln.Store.Journal.commit/4` inserted and reduced raw entries. An entry could commit and then fail on restart replay. Fix: `commit/4` now decodes every entry with `Kiln.Journal.Entry.decode/2` before the transaction opens; an invalid entry writes no journal row, no action commit, and no projection. Commit and replay share one decoder and reducer. The invariant holds: if an entry can commit, it can replay.
- **D7 Wrong workflow-step authority.** `Kiln.Journal.Entry` accepted invented steps (`execution`, `completion`) and omitted accepted ones. Fix: the journal steps are derived from `Kiln.Domain.Run.workflow_steps/0` and converted to strings at the decoding boundary, so commit-time and replay-time validation cannot drift.
- **D8 Session discovery ignored action commits.** `Replay.sessions/1` read only `journal_entries`, so an action commit with missing journal rows reported an empty store. Fix: discovery is the distinct union of `journal_entries` and `action_commits` session ids; a commit with missing rows now blocks on `:missing_journal_rows`, and the projection cache never creates a candidate.

### Observed defects (PR #39 review)

- **D1 Multi-entry actions lost entries.** T02 lets one accepted action append several journal entries that share its idempotency key. Replay deduplicated by idempotency key, so it applied only the first entry and skipped the rest. The commit-time projection and the restart projection could differ. The original test suite did not exercise a real multi-entry action, so CI stayed green.
- **D2 Replay integrity was not enforced.** Replay did not load `action_id`, did not use `action_commits` as the transaction boundary, and did not validate sequence continuity or the declared sequence range. A fabricated row with a valid payload could be accepted as committed truth.
- **D3 Malformed payloads were under-validated.** The reducer checked only top-level key presence and ignored the recorded `run.from`. A malformed nested payload could raise or build a projection with missing identifiers.
- **D4 A corrupt cache could crash restart.** `Store.load/2` used a raising JSON decode and did not verify cache metadata.
- **D5 Restart silently chose the oldest Session.** `Restart.reconstruct/1` took the first Session and discarded the rest.

### Accepted contract requirements confirmed

- Replay reconstructs the committed truth from the journal (R01, R02).
- Replay validates action, sequence, revision, digest, kind, and transition (R03, R05).
- A truly duplicate request writes no second journal row at commit time, so a duplicate journal row is invalid durable state, not a benign skip (R04).
- Projections are non-authoritative caches; the journal blocks, the cache does not (R11, R12).
- Restart dispatches no effect (R09).

### Implementation decisions

- Replay validates and applies whole action batches keyed on `action_commits`, not deduplicated rows (`Kiln.Journal.Replay`).
- Typed, non-raising per-entry decoding validates the full accepted payload shape (`Kiln.Journal.Entry`); the reducer enforces `run.from`, current-decision, and current-operation correspondence.
- Cache load is total; `compare/2` rebuilds and reconciles in one immediate-transaction snapshot and classifies the cache by its metadata.
- Restart selects the Session by an explicit rule (0 empty, 1 reconstruct, more than 1 blocks `:multiple_sessions`) and returns a structured report with a bounded `journal_head_digest`.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T03-AC01 | Pass | P1-S01-T03-E01 | replay reproduces the committed projection byte-for-byte, including a real multi-entry action (`replay_test.exs`) |
| P1-S01-T03-AC02 | Pass | P1-S01-T03-E02 | missing commit, missing rows, foreign or extra row, mismatched key or digest, wrong first or last sequence, noncontiguous or non-following revision, corrupt payload, and invalid transition each block at the exact boundary (`action_batch_test.exs`, `replay_test.exs`) |
| P1-S01-T03-AC03 | Pass | P1-S01-T03-E03 | transcript records leave the projection digest unchanged and keep their own ordering |
| P1-S01-T03-AC04 | Pass | P1-S01-T03-E04 | a nonterminal operation reconstructs as unknown operation and `orphaned` Run, appends nothing, dispatches nothing, and is idempotent on repeat |
| P1-S01-T03-AC05 | Pass | P1-S01-T03-E05 | missing, malformed, metadata-mismatched, and stale caches are replaced after full journal validation; a matching cache is kept; a corrupt journal blocks and preserves the cache |
| P1-S01-T03-AC06 | Pass | P1-S01-T03-E06 | full deterministic gate exits zero at exact head `58c43a4`; no excluded capability is reachable |

### Verification executed

Toolchain: Elixir 1.20.2 / Erlang OTP 28 (repo `mise.toml`); `jsonschema==4.26.0`. Executed at commit `58c43a40`.

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| `scripts/test-agent-preflight` | 0 | `pass` |
| `python3 scripts/validate_first_month_contracts.py` | 0 | `pass`; 10 positive, 11 protected-negative |
| `python3 scripts/validate_json_schema_contracts.py` | 0 | `pass`; jsonschema 4.26.0 |
| `scripts/validate-agent-assets` | 0 | `pass` |
| `mix format --check-formatted` | 0 | no output |
| `mix compile --warnings-as-errors` | 0 | clean |
| `mix xref graph --format cycles --label compile-connected --fail-above 0` | 0 | `No cycles found` |
| `mix test test/kiln/store` | 0 | 21 passed |
| `mix test test/kiln/journal` | 0 | reducer, entry, replay, action-batch fixtures |
| `mix test test/kiln/projections` | 0 | cache classification and rebuild |
| `mix test test/kiln/restart_test.exs` | 0 | restart, orphan, multiple-Session, idempotence |
| `mix test test/kiln/journal test/kiln/projections test/kiln/restart_test.exs` | 0 | 78 passed |
| `mix test` | 0 | 125 passed |
| `scripts/check` (aggregate) | 0 | `check: pass` |

### New protected tests

- `test/kiln/journal/replay_test.exs` — real multi-entry action applied in full; corrupt payload; revision discontinuity; transcript separation.
- `test/kiln/journal/action_batch_test.exs` — missing commit, missing rows, extra or foreign row, mismatched idempotency key and request digest, wrong first and last sequence, noncontiguous batch revisions, cross-action revision gap.
- `test/kiln/journal/entry_test.exs` — malformed nested payloads, unknown states and steps, invalid operation class and state, bad revision types, malformed lists, unexpected null, and `run.from`, decision, and operation correspondence.
- `test/kiln/projections/store_test.exs` — missing, matching, malformed, metadata-mismatch, and stale cache reconciliation; corrupt journal blocks with a preserved cache.
- `test/kiln/restart_test.exs` — full restore, orphaned operation, empty store, explicit multiple-Session block, corrupt-journal block, and idempotent unknown markers.

### Demo and slice status

- Ticket demo contribution: Exercised in `Kiln.RestartTest` — the application stops, restarts, and reconstructs the exact objective revision, criteria revision, Task, Root Run, workflow step, pending decision, operation state, unknowns, and revision from the journal
- Parent slice gate affected: P1-S01-G04 through G07
- Slice verification manifest updated: No
- Slice completion claimed: No

### Failures and warnings

- The first submission overstated AC02 and R03. The original green CI did not exercise the multi-entry action path or the action and sequence boundaries. This is corrected; the remediation adds tests that fail before the fix.
- No external effect is dispatched or appended during replay or restart. Reconstruction is read-only.
- Environment note: verification used the repo-pinned mise Elixir 1.20.2 / OTP 28 toolchain and a virtualenv holding `jsonschema==4.26.0`. No product source was changed to make the gate pass.

### Remaining unknowns and exclusions

- U01 (replay batching) resolved to a per-action ordered fold; correctness does not depend on batch size. U02 (corrupt repair) resolved to blocking at the first invalid boundary and preserving the database, with no repair.
- User interaction (the foundation CLI) is T04. Reconstruction is exposed through application APIs and tests only.
- Persisting an orphan-classification journal fact at restart is left to the workflow layer; reconstruction is read-only.
- Deep decision and operation subject validation beyond identity and class belongs to later tickets; replay preserves the references faithfully and blocks obvious contradictions.

### Repository state

- Commit: `58c43a40a8080119ef827cbf4d081309dacf65bc` (code and tests verified locally; the final PR head is the closeout documentation commit on top, and the authoritative CI run is for that PR head)
- Branch: `work/p1-s01-t03-replay-projections`
- Diff reviewed: Yes; adds `lib/kiln/journal/*` (entry, reducer, replay), `lib/kiln/projections/*`, `lib/kiln/restart.ex`, refactors `lib/kiln/store/journal.ex` and `lib/kiln/store.ex`, removes `lib/kiln/store/projection.ex`, and adds the replay, projection, restart, entry, and action-batch test suites (3404 insertions, 133 deletions versus `main`)
- Exact CI run: full local gate green at exact head; authoritative CI run and owner review pending on the pull request
- Parent slice status after merge: the application can reconstruct durable state through APIs and tests; the user-facing foundation CLI remains T04
