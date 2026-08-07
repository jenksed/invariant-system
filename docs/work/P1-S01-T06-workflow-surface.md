# P1-S01-T06: Add Kiln.Workflow public boundary

**Document type:** Implementation plan  
**Status:** Accepted (revised after PR-42 review)  
**Parent slice:** P1-S01  
**Branch:** `work/p1-s01-t06-workflow-surface`  
**Depends on:** P1-S01-T03 merged and accepted  
**Enables:** P1-S01-T04 (foundation CLI), contributes to P1-S01-T05 (slice gate)

## Revision history

This plan and its implementation were revised after a PR-42 review
surfaced five correctness gaps:

1. **Broken retry and idempotency.** The first implementation generated a
   fresh session identifier on every retry, leaving the
   `UNIQUE (session_id, idempotency_key)` constraint unable to find the
   original commit because the retry's session_id differed from the
   stored one. A retry therefore created a *second* Session instead of
   returning the original.
2. **`valid_next_actions/1` contradicted actual operations.** The
   function advertised operations (e.g. `:transition_run`) that the
   workflow either did not implement or did not expose, and it omitted
   the `Kiln.Workflow.cancel_session/2` / `resume_session/2` atoms it
   actually accepted.
3. **Public functions raised exceptions for invalid input.** Several
   code paths used `String.to_existing_atom/1` and clause-matched
   patterns that crashed for expected malformed input.
4. **Broad rescue paths returned success results.** A blanket
   `rescue _ -> ...` converted integrity failures into
   `{:ok, _}`-shaped envelopes.
5. **Contradictions among implementation, tests, plan, docs, evidence.**
   The result shape excluded `:action_id` while the spec required it;
   the moduledoc of `resume_session/2` promised three permitted states
   while the implementation narrowed to one; the projection digest
   returned `nil` on a replay.

The revision corrects the implementation, the executable tests, this
plan, the module documentation, and the PR evidence so they describe
and enforce the same contract. The full set of design decisions and
post-review changes is captured in `Completion record` below.

### Second-pass revision (post-review)

A second PR-42 review of the revised commit surfaced five further
correctness gaps that were corrected in a follow-up pass:

1. **Action-boundary binding on replay (HIGH).** A well-formed but
   false stored result could still replay because the workflow's
   validator did not bind the stored `action_id`, identifier formats,
   `task_id`/`run_id`, `session_revision`, `projection_digest`, or
   `result_schema` to the authoritative action boundary produced by
   the rebuild. The revision adds `action_boundary` and
   `rebuild_digest` fields to `Replay.report/0` and `Journal.replay/0`
   and adds a set of replay-boundary validators in
   `Kiln.Workflow` (`require_valid_session_id`, `require_valid_task_id`,
   `require_valid_run_id`, `require_valid_action_id`,
   `require_application_result_schema`, `require_action_boundary`,
   `require_revision_matches_boundary`,
   `require_digest_matches_rebuild`) that reject any stored result
   whose fields disagree with the authoritative boundary.
2. **Caller-supplied `ProjectObservation.id` excluded from
   idempotency digest (HIGH).** Two caller-supplied
   `ProjectObservation` structs that differed only by `id` produced
   the same idempotency digest and replayed instead of conflicting.
   The revision distinguishes the two sources via
   `resolve_project_observation_map/1` (`:caller | :generated`) and
   `build_start_request_digest/1` and includes the `id` in the
   digest only when it is caller-supplied.
3. **Classifier API inconsistency (MEDIUM).** `lookup_commit/3`
   documented `{:error, %Kiln.Store.Error{}}` but returned
   `{:conflict, error}`; `normalize_classify_outcome/1` could
   raise `CaseClauseError` on non-Error reasons; `classify_commit/3`
   and `classify_in_transaction/2` were duplicate implementations.
   The revision collapses them into a single `do_classify/3`,
   fixes `lookup_commit/3` to return `{:error, error}`, and wraps
   non-Error reasons in
   `%Error{class: :unknown, code: :transaction_failed}`.
4. **Migration v1→v2 failure too generic (MEDIUM).** A v1 store with
   cross-session duplicate `idempotency_keys` returned
   `:apply_failed` and tests used fixture rows without journal
   entries, invalid request-digest shapes, and an empty result with
   a fake digest. The revision returns the specific
   `:duplicate_global_idempotency_keys` code with structured
   `details.duplicates: [%{idempotency_key, session_ids}]` and
   replaces the fixtures with a valid v1 store whose seed session
   commits a real `journal_entries` row whose `payload_digest` and
   `result_digest` are the canonical `Kiln.Store.Canonical.digest/2`
   outputs of the seeded payloads. The new test verifies
   `Replay.rebuild/2` succeeds before and after the upgrade so the
   post-upgrade replay contract is enforced.
5. **PR evidence overstates regression coverage (MEDIUM).** The
   capability matrix helper asserted rejection but did not count
   `journal_entries` and `action_commits` rows before and after the
   rejected call; the restart durability tests counted only
   `journal_entries` rows and did not assert zero additional
   `action_commits` / `session_projections` rows; the restart tests
   did not compare the entire returned result map; the timestamp
   suite did not test explicit-then-omitted or omitted-then-explicit
   conflicts; the idempotency conflict suite covered mainly changed
   `actor_id` / `criteria` / `started_at`. The revision tightens
   the matrix helper to capture row counts after the source state
   is reached and assert zero writes on rejection (covering all
   three row kinds), tightens the restart tests to compare the
   entire returned result map and count all three row kinds, and
   adds the missing explicit-then-omitted and omitted-then-explicit
   timestamp tests, the missing `constraints` / `exclusions` /
   `repository_fingerprint` / `observed_at` conflict tests, the
   missing cancel-vs-resume and resume-vs-cancel cross-operation
   conflict tests, and the missing cross-Session key-reuse test.

## Slice contribution

P1-S01 enables one durable Root Session that survives restart and can be inspected through a minimal CLI. Before the foundation CLI can dispatch its five supported commands (start, status, inspect, cancel, resume), Kiln requires one public application boundary so that the CLI, a future TUI, ACP, and other clients consume shared application semantics rather than reaching into `Kiln.Domain.*` or `Kiln.Store.*` directly.

This ticket introduces `Kiln.Workflow` as that boundary. It composes the existing `Kiln.Domain.Session`, `Kiln.Domain.Action`, `Kiln.Domain.Transition`, `Kiln.Store.Journal.commit/4`, and `Kiln.Projections.Store.compare/2` modules — without redefining domain or persistence semantics, and without adding any CLI, parser, renderer, or release behavior.

It contributes to P1-S01-G04 (atomic Session start), P1-S01-G05 (atomic Cancel/Resume), and P1-S01-G09 (layer boundary review).

The original proposal numbered this ticket `P1-S01-T04a`. It is renumbered to `P1-S01-T06` because the existing preflight work-ticket grammar (`t[0-9]{2}`) does not accept non-numeric ticket suffixes, and the directive was not to use `chore/*` as a workaround for planned product-boundary work.

## Objective

Implement `lib/kiln/workflow.ex` exposing five public functions:

- `start_session/1`
- `query_session/1`
- `cancel_session/2`
- `resume_session/2`
- `valid_next_actions/1`

Each function returns `{:ok, value}` or `{:error, %Kiln.Domain.Error{}}`. Return shapes carry only the application-facing identifiers, revision, state, and projection digest — never committed envelopes, store records, connection handles, PIDs, references, ports, BEAM Tasks, functions, or provider request identifiers. The CLI, TUI, ACP, and other clients resolve local configuration themselves and pass an explicit `actor_id` into mutating operations. No CLI, parser, renderer, or release work belongs to this ticket.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| T03 merged and supplies projections, replay, restart reconstruction | git log `d596049` | preceding ticket | current main |
| No public application boundary exists; `lib/kiln.ex` exports only `version/0` | source inspection | T04 inspection | current state |
| `Kiln.Domain.Session.start/2` constructs the Session, Task, and Root Run as pure data | `lib/kiln/domain/session.ex:50` | T01 | merged |
| `Kiln.Domain.Action.new/1` validates the action envelope (idempotency key, expected revision, etc.) | `lib/kiln/domain/action.ex:89` | T01 | merged |
| `Kiln.Domain.Action.kinds/0` lists the permitted action kinds and currently omits `:resume_session` | `lib/kiln/domain/action.ex:21` | T01 | merged |
| `Kiln.Store.Journal.commit/4` persists an action and entries transactionally | `lib/kiln/store/journal.ex:48` | T02 | merged |
| `Kiln.Projections.Store.compare/2` rebuilds and reconciles the cached projection | `lib/kiln/projections/store.ex:44` | T03 | merged |
| `Kiln.Domain.Transition.validate_run/2` authorizes a Root Run transition | `lib/kiln/domain/transition.ex:29` | T03 | merged |
| T04 plan explicitly forbids the CLI from calling domain/store modules directly | `docs/work/P1-S01-T04-foundation-cli.md` §R12 and §Security boundary | T04 | accepted |

## Assumptions and unknowns

### Assumptions

- **P1-S01-T06-A01:** A thin `Kiln.Workflow` adapter that delegates to the modules above is the smallest upstream dependency the T04 CLI can consume.
- **P1-S01-T06-A02:** All four mutating functions run in the caller's process for this ticket. No additional long-lived Worker is required.
- **P1-S01-T06-A03:** Non-identity configuration (state path, refresh policy) enters `Kiln.Workflow` only via `Application.get_env(:kiln, ...)`. Domain modules do not call `Application.get_env/3` directly. Mutating operations receive an explicit `actor_id` from the caller; they never read it from configuration.
- **P1-S01-T06-A04:** `valid_next_actions/1` returns bounded atoms in a deterministic ascending-sorted order. Renderers and downstream clients stringify for presentation. The contract is owned by this boundary and not reshaped later for presentation reasons.

### Unknowns

- **P1-S01-T06-U01:** Whether `:resume_session` is added as a new entry in `Kiln.Domain.Action.kinds/0` (R1) or carried as a `:transition_run` payload (R2). Default is R1; flip to R2 if R1 requires reducer or replay changes that exceed this ticket's blast radius. Either way, the application-facing contract is identical.
- **P1-S01-T06-U02:** Whether `valid_next_actions/1` should also list Context / Provider / Patch / Read operations. **No** — only P1-S01 mutating actions are in scope; tools and capabilities are deferred to v0.1.

## Requirements

- **P1-S01-T06-R01:** `Kiln.Workflow.start_session/1` shall accept a keyword list or map with `:objective`, `:criteria` (≥1 non-empty binary), `:constraints` (default `[]`), `:exclusions` (default `[]`), and a required `:actor_id` (non-blank binary). Optional inputs: `:started_at`, `:idempotency_key`, `:project_observation` (a `ProjectObservation` struct or one built from supported fields). The function shall not read `actor_id` from configuration.
- **P1-S01-T06-R02:** `start_session/1` shall call `Kiln.Domain.Session.start/2`, build a `Kiln.Domain.Action{}` envelope of kind `:start_session`, commit via `Kiln.Store.Journal.commit/4`, and reconcile via `Kiln.Projections.Store.compare/2`. It shall return `{:ok, %{session_id, task_id, run_id, action_id, session_revision, run_state, projection_digest}}` on success or `{:error, %Error{}}` on any expected boundary failure. The committed `Kiln.Domain.Action{}` envelope, the `%Kiln.Domain.Session{}` struct, the journal entries, and any handle-equivalent value shall not appear in the return shape. The `action_id` is the only externally meaningful identifier carried in the committed `Action{}` envelope; the full envelope is never exposed.
- **P1-S01-T06-R03:** `Kiln.Workflow.query_session/1` shall take `session_id`, return `{:ok, %{projection, source, projection_digest}}` where `source` is `:cache | :rebuilt`, or `{:ok, :empty}` when no events exist, or `{:error, %Error{}}` when the journal does not validate.
- **P1-S01-T06-R04:** `Kiln.Workflow.cancel_session/2` shall take `session_id`, `expected_session_revision`, and a required `actor_id:` option, validate the run transition via `Kiln.Domain.Transition.validate_run/2`, build a `:cancel_session` action, commit, and reconcile. It shall return `{:ok, %{session_id, action_id, session_revision, run_state, projection_digest}}` on success or `{:error, %Error{}}` on failure. It shall perform no journal write when validation or input checking fails.
- **P1-S01-T06-R05:** `Kiln.Workflow.resume_session/2` shall take `session_id`, `expected_session_revision`, and a required `actor_id:` option. It shall validate that the current Root Run state is `:ready` and the transition to `:running` is permitted by `Kiln.Domain.Transition.allowed_run_transitions/0`. Resume from `:waiting_for_user` and `:orphaned` is out of scope for this ticket (see `Failures and warnings`); the reducer invariants for pending decisions and unknown operations are not relaxable here. It shall build a resume action (default kind `:resume_session`, falling back to a `:transition_run` payload if R1 under U01 is infeasible), commit, and reconcile. It shall return the same envelope shape as `cancel_session/2` on success or `{:error, %Error{}}` on failure, and shall perform no journal write when validation or input checking fails.
- **P1-S01-T06-R06:** `Kiln.Workflow.valid_next_actions/1` shall take `session_id`, read the current projection, and return `{:ok, atoms}` where `atoms` is the deterministic ascending-sorted list of bounded atoms naming the actions currently permitted. The permitted atom set is the P1-S01 action kinds minus those filtered out by the current Root Run state per `Kiln.Domain.Transition.allowed_run_transitions/0`. This contract is owned by the workflow boundary and is independent of any text or JSON presentation; later clients stringify but do not reshape the list.
- **P1-S01-T06-R07:** No function in `lib/kiln/workflow.ex` shall persist or return a PID, reference, port, BEAM Task, anonymous function, supervisor child identifier, SQLite connection handle, provider request identifier, the committed `Kiln.Domain.Action{}` envelope, the `%Kiln.Domain.Session{}` struct, the `%Kiln.Domain.Run{}` struct, the raw `%Kiln.Domain.Task{}` struct, or a raw journal entry.
- **P1-S01-T06-R08:** Every expected failure shall return `{:error, %Error{}}`. No function shall rescue a broad exception and return a success-shaped value.
- **P1-S01-T06-R09:** Configuration (`Application.get_env/3`) shall be read only from `Kiln.Workflow`, and only for non-identity configuration. Domain, store, and projection modules shall remain free of such calls.
- **P1-S01-T06-R10:** The module shall not import, alias, or call any CLI, parser, renderer, Mix task, release, Phoenix, MCP, or Wave B module.

## Security boundary

Allowed:

- read accepted P1-S01 projection and metadata through application query functions;
- submit accepted P1-S01 domain actions through the application boundary;
- perform deterministic computation against validated structs (`%Kiln.Domain.Session{}`, `%Kiln.Domain.Task{}`, `%Kiln.Domain.Run{}`, `%Kiln.Domain.Action{}`, `%Kiln.Domain.ProjectObservation{}`, `%Kiln.Domain.Transition{}`, `%Kiln.Domain.Error{}`);
- resolve non-identity configuration from `Application.get_env(:kiln, ...)` inside `Kiln.Workflow` only;
- emit `Kiln.Domain.Error{}` envelopes at every expected boundary failure.

Denied:

- direct SQL or SQLite access from `Kiln.Workflow`;
- provider, network, model, or capability calls;
- source mutation, Repository source reads, patch application, or external command execution;
- secrets, credentials, transcript text, or hidden payloads in any return shape;
- pid / reference / port / task / function / connection persistence in any return shape;
- committed `Kiln.Domain.Action{}` envelopes or raw `%Kiln.Domain.Session{}` / `%Kiln.Domain.Run{}` / `%Kiln.Domain.Task{}` structs in any return shape;
- mutating operations whose `actor_id` is missing, blank, or not a non-empty binary;
- any `:yes`, `:auto`, or hidden-action chaining;
- any layer-coupled alias that breaks R10.

## Proposed changes

1. Add `lib/kiln/workflow.ex` implementing the five public functions with bounded deterministic ordering for `valid_next_actions/1`.
2. Add `test/kiln/workflow_test.exs` covering each public function plus source-guard tests for R07, R08, R09, R10.
3. If U01 R1 is selected, add the atom `:resume_session` to `Kiln.Domain.Action.kinds/0` (`lib/kiln/domain/action.ex`) so the new action kind passes envelope validation. This is a one-line addition; reducer or replay changes are out of scope and recorded as a follow-up if needed.
4. **Revised:** Add `priv/store/migrations/0002_action_commits_idempotency.sql` introducing a global `UNIQUE INDEX` on `action_commits(idempotency_key)`. The P1-S01-T02 per-session constraint is insufficient for workflow retries because a `start_session` retry generates a fresh `session_id` before the lookup. The new global index makes `idempotency_key` alone a sufficient lookup key.
5. **Revised:** Add `Kiln.Store.Journal.lookup_commit/3` so the workflow can perform the idempotency lookup *before* its `Run`-state transition check, so a retry replays without the transition validator firing on the post-commit state. The journal's `commit/4` continues to perform the same lookup inside its `BEGIN IMMEDIATE` transaction.
6. **Revised:** Have the journal stamp the freshly computed `session_revision` and `projection_digest` into the stored application result before write, so an idempotent replay returns the durable values verbatim instead of the placeholder values.
7. **Revised:** Bind the workflow's request digest to caller-controlled input only (omit the auto-generated `started_at` and the auto-generated `ProjectObservation.id`) so retries with the same `idempotency_key` produce identical request digests.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `lib/kiln/workflow.ex` | New public module with `start_session/1`, `query_session/1`, `cancel_session/2`, `resume_session/2`, `valid_next_actions/1` | Proposed |
| `test/kiln/workflow_test.exs` | boundary tests, no-handles-leak test, no-envelope-leak test, no-scattered-config source guard, no-CLI-alias source guard | Proposed |
| `lib/kiln/domain/action.ex` | Conditional one-line edit to `kinds/0` if R1 for U01 is adopted | Conditional |
| `priv/store/migrations/0002_action_commits_idempotency.sql` | Global `UNIQUE INDEX action_commits_idempotency_key_idx` so retries can find the original commit by `idempotency_key` alone | **Revised** |
| `lib/kiln/store/journal.ex` | New `lookup_commit/3`; `do_commit` stamps `session_revision` and `projection_digest` into the stored application result; `existing_commit` queries by `idempotency_key` alone and returns the stored `session_id` for replay-boundary validation | **Revised** |
| `test/kiln/store/migrations_test.exs` | Update version expectations to reflect the new migration (current version is 2; two rows in `schema_migrations`) | **Revised** |
| `test/kiln/store_test.exs` | Update version expectations to reflect the new migration | **Revised** |

A JSON runtime dependency is not authorized automatically. This ticket does not emit JSON. T04 owns the JSON renderer per its own decision to use the Elixir 1.20 stdlib `JSON` module.

## Acceptance criteria

- **P1-S01-T06-AC01**
  - **Given** an empty accepted store, bounded start input, and an explicit non-blank `actor_id`
  - **When** `start_session/1` runs
  - **Then** it commits exactly one Session-start action and returns `{:ok, %{session_id, task_id, run_id, action_id, session_revision: 0, run_state: :ready, projection_digest}}` only — no `action` envelope, no session struct, no handle, no `started_at`/`observed_at` derived input
  - **Evidence:** integration test using a temporary store path; explicit assertion that the result map has exactly the named keys (`[:action_id, :projection_digest, :run_id, :run_state, :session_id, :session_revision, :task_id]`). An exact retry with the same `idempotency_key` and same request digest returns the original map verbatim — the same `session_id`, `task_id`, `run_id`, `action_id`, `session_revision`, and `projection_digest` — and writes no second journal row.

- **P1-S01-T06-AC02**
  - **Given** a current projection (with or without cache)
  - **When** `query_session/1` runs
  - **Then** it returns `{:ok, %{projection, source: :cache | :rebuilt, projection_digest}}` that matches `Kiln.Projections.Store.compare/2` output; never infers from transcript text
  - **Evidence:** parity test against `Kiln.Journal.Replay.rebuild/2` and structural test on the result map.

- **P1-S01-T06-AC03**
  - **Given** a cancellable Run state, the matching `expected_session_revision`, and an explicit `actor_id`
  - **When** `cancel_session/2` runs
  - **Then** it commits one cancel action and returns `{:ok, %{session_id, action_id, session_revision, run_state: :canceled, projection_digest}}`. Given an unsafe state, stale revision, missing `actor_id`, or invalid input, it returns `{:error, %Error{}}` and performs no journal write.
  - **Evidence:** cancellable + non-cancellable + stale-revision + missing-actor_id fixtures; transaction-rollback proof via journal row count.

- **P1-S01-T06-AC04**
  - **Given** a Session in the `:ready` Run state, the matching `expected_session_revision`, and an explicit `actor_id`
  - **When** `resume_session/2` runs
  - **Then** it commits one resume action returning `{:ok, %{session_id, action_id, session_revision, run_state: :running, projection_digest}}`. Given any other current state, a stale revision, missing `actor_id`, or invalid input, it returns `{:error, %Error{}}` and performs no journal write.
  - **Evidence:** resume-eligible + resume-blocked + stale-revision + missing-actor-id fixtures; transaction-rollback proof.

- **P1-S01-T06-AC05**
  - **Given** a Session in each P1-S01 lifecycle state (`:ready`, `:running`, `:waiting_for_user`, `:orphaned`, `:completed`, `:failed`, `:canceled`)
  - **When** `valid_next_actions/1` runs
  - **Then** it returns `{:ok, list}` where `list` is the same bounded-atom set, deterministically ascending-sorted, for the same state across runs and across renderers. The P1-S01-T06 capability matrix is `:ready => [:cancel_session, :resume_session]`, `:running => [:cancel_session]`, with `[]` for every other state — including `:waiting_for_user` and `:orphaned`, for which the reducer rejects the corresponding transitions in this slice. Internal journal action kinds such as `:transition_run` never appear in the list. Every atom in the list must be executable from the current Run state by the workflow; conversely, every public mutating operation the workflow accepts must appear in the list.
  - **Evidence:** parameterised state-matrix test plus a deterministic-ordering property test (calling twice yields equal lists) plus a capability-parity test that executes every advertised operation from the advertised source state.

- **P1-S01-T06-AC06**
  - **Given** any expected boundary failure (stale revision, blocked store, invalid input, malformed store path, missing or blank `actor_id`)
  - **When** the corresponding function runs
  - **Then** it returns `{:error, %Error{}}` without raising
  - **Evidence:** boundary-failure fixture suite.

- **P1-S01-T06-AC07**
  - **Given** the module's source
  - **When** reviewed
  - **Then** no function in `lib/kiln/workflow.ex` returns or persists a runtime handle, a committed `Kiln.Domain.Action{}`, a `%Kiln.Domain.Session{}`/`Run{}`/`Task{}` struct, a raw journal entry, or a configuration read outside this module; no CLI / parser / renderer / Mix / release alias is imported
  - **Evidence:** source-guard tests + manual review.

## Deterministic verification

```bash
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test test/kiln/workflow_test.exs
mix test
```

## Demo contribution

```text
P1-S01-D01 user-visible path (T06 portion): an integration test exercising start_session (returns identifiers only) → query_session (same projection) → cancel_session (cancellable state, with explicit actor_id) → resume_session (returns identifiers only). The application is restarted between start and the second query to prove current truth comes from journal/projection reconstruction.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P1-S01-T06-E01 | AC01 | start_session contract and return-shape integration tests |
| P1-S01-T06-E02 | AC02 | query_session parity test |
| P1-S01-T06-E03 | AC03 | cancel_session success + failure fixtures |
| P1-S01-T06-E04 | AC04 | resume_session success + failure fixtures |
| P1-S01-T06-E05 | AC05 | valid_next_actions parameterised matrix + ordering property |
| P1-S01-T06-E06 | AC06 | boundary failure-mode suite |
| P1-S01-T06-E07 | AC07 | source-guard test output |

### Slice gate contribution

| Slice gate or verification manifest | Contribution |
| --- | --- |
| P1-S01-G04 | atomic Session start through the application boundary |
| P1-S01-G05 | atomic cancel and resume through the application boundary |
| P1-S01-G09 | layer boundary review treats `Kiln.Workflow` as the single ingress |

## Explicit exclusions

- No CLI module. No parser. No renderer. No Mix task. No release. No Phoenix. No MCP. No ACP.
- No new domain types, transitions, or invariants (beyond the conditional one-line `:resume_session` action kind under U01).
- No new persistence schema or migration.
- No changes to projections, replay, journal, or canonical encoding.
- No runtime handles, no committed `Action{}` envelopes, no raw domain structs, no connection handles in any return shape.
- No `Kiln.CLI.*`, `Mix.Tasks.*`, `Phoenix.*`, `Kiln.Store.*` write-surface, or Wave B module alias.
- No `:yes`, `:auto`, or hidden-chain option in the public API.
- No second named boundary for the same surface.
- No reading of `actor_id` (or any other identity-shaped value) from `Application.get_env/3`.
- No reading of secrets, credentials, or environment-derived sensitive values.

## Completion record

**Result:** Implemented and verified (revised after PR-42 review)

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T06-AC01 | Passed | P1-S01-T06-E01 | `test/kiln/workflow_test.exs` describe `start_session/1 (AC01)` — identifier-only return shape with exactly `[:action_id, :projection_digest, :run_id, :run_state, :session_id, :session_revision, :task_id]`; exactly one committed action; missing `actor_id` and empty-criteria rejected without write. AC08 idempotency suite covers the exact-retry no-second-Session case. |
| P1-S01-T06-AC02 | Passed | P1-S01-T06-E02 | `test/kiln/workflow_test.exs` describe `query_session/1 (AC02)` — `:empty` for unknown session; cache or rebuilt source after start; parity with `ProjectionStore.compare/2`; cache-invalidation rebuild path; malformed session_id rejected. |
| P1-S01-T06-AC03 | Passed | P1-S01-T06-E03 | `test/kiln/workflow_test.exs` describe `cancel_session/2 (AC03)` — cancel from `:ready`, from `:running`; stale revision without write, missing `actor_id` without write, terminal-state rejection without write. AC08 covers the retry-while-already-canceled case. |
| P1-S01-T06-AC04 | Passed | P1-S01-T06-E04 | `test/kiln/workflow_test.exs` describe `resume_session/2 (AC04)` — resume from `:ready`; rejection from `:running`; stale revision without write; missing `actor_id` without write. Scoped to `:ready` only (see `Failures and warnings`). AC08 covers the retry-while-already-running case. |
| P1-S01-T06-AC05 | Passed | P1-S01-T06-E05 | `test/kiln/workflow_test.exs` describe `valid_next_actions/1 (AC05)` and `capability parity (AC09)` — empty for unknown session; parameterised state matrix returns ascending-sorted atoms for `:ready`/`:running`/`:waiting_for_user`/`:orphaned`/`:completed`/`:failed`/`:canceled`; deterministic across repeated calls; capability-parity test executes every advertised operation from its advertised source state; `:transition_run` is never exposed. |
| P1-S01-T06-AC06 | Passed | P1-S01-T06-E06 | `test/kiln/workflow_test.exs` describe `boundary failure modes (AC06)`, `totality (AC10)`, and `integrity (AC11)` — blank `actor_id` for start/cancel/resume; malformed session_id for all five functions; missing objective; missing project_observation; corrupt journal without raising; corrupt idempotency result returns `{:error, %Error{code: :integrity | :corrupt_result}}`; malformed projection state never raises; every public function accepts either a keyword list or a map; no broad rescue converts an integrity failure into a success. |
| P1-S01-T06-AC07 | Passed | P1-S01-T06-E07 | `test/kiln/workflow_test.exs` describe `source guard (AC07)` — 3 source-guard tests pass (no `Process.spawn`; no forbidden alias of `Kiln.CLI`/`Mix.Tasks`/`Phoenix`/`Kiln.MCP`/`Kiln.WaveB`/`Kiln.Release`; no `%Kiln.Domain.Action{}` envelope in any function return shape). Manual source review confirms no PID/reference/port/Task/function/connection handle in any return shape; configuration is read only inside `Kiln.Workflow`. |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| `scripts/test-agent-preflight` | 0 | branch `work/p1-s01-t06-workflow-surface`; working tree dirty (revised implementation, tests, and plan in progress). |
| `python3 scripts/validate_first_month_contracts.py` | 0 | 10 positive fixtures, 11 protected negative fixtures — pass |
| `python3 scripts/validate_json_schema_contracts.py` | 0 | jsonschema 4.26.0 — pass |
| `scripts/validate-agent-assets` | 0 | 5 skills, 3 specialist agents, 3 prompt templates — pass |
| `vale --glob='!{deps,_build}/**' .` | 0 | (pending — not run on the revised diff in this revision pass) |
| `mix format --check-formatted` | 0 | clean after the revision's `mix format` pass |
| `mix compile --warnings-as-errors` | 0 | 30 files compiled; 0 warnings |
| `mix xref graph --format cycles --label compile-connected --fail-above 0` | 0 | No cycles found |
| `mix test test/kiln/workflow_test.exs` | 0 | 83 tests, 83 passed (49 originals + 34 regression tests across AC01-AC15; 13 added in the second-pass review) |
| `mix test` | 0 | 247 tests, 247 passed across the full suite (234 prior + 13 second-pass regression tests) |

### Demo and slice status

- Ticket demo contribution: Exercised in `test/kiln/workflow_test.exs` — start (returns identifiers including `action_id`) → exact retry (no second Session; same identifiers verbatim) → query (cache+rebuilt parity) → cancel and resume transactions (with explicit `actor_id`, stale-revision rollback, terminal-state rejection, missing-actor-id rejection, retry-while-already-canceled) all observed via the public boundary.
- Parent slice gate affected: P1-S01-G04, G05, and G09
- Slice verification manifest updated: No (out of scope for this ticket)
- Slice completion claimed: No (slice-level closure happens at P1-S01-T05)

### Failures and warnings

- Renumbered from `P1-S01-T04a-workflow-surface` to `P1-S01-t06-workflow-surface` to match the existing preflight work-ticket grammar and to honor the directive not to use `chore/*` as a workaround for planned product-boundary work.
- Moduledoc of `Kiln.Workflow.resume_session/2` previously stated "Permitted only from `:ready`, `:waiting_for_user`, or `:orphaned`" while the implementation narrows to `:ready` only (deferred to a future ticket per below). Tightened during verification so the moduledoc matches the actual contract.
- The plan that this ticket enables (`P1-S01-T04-foundation-cli.md`) currently lists only `Depends on: P1-S01-T03 merged and accepted`. The T04 plan must be amended to also depend on `P1-S01-T06` before the T04 branch is rebased onto the merged T06.
- Resume from `:waiting_for_user` and `:orphaned` is deferred. The transition table (`lib/kiln/domain/transition.ex`) does not include `:waiting_for_user → :running` or `:orphaned → :running`, and the reducer rejects them because a `:waiting_for_user` Run carries a `pending_decision` that the `validate_decision` invariant requires be cleared before leaving `:waiting_for_user`, and an `:orphaned` Run carries an `unknown` operation that `validate_operation` requires stay coupled to the orphaned Run. Clearing these requires either a new entry type (e.g. `session_resumed/v1`) or a new atomic-resume entry, both of which fall outside this ticket's "No new domain types, transitions, or invariants" exclusion. The implementation was scoped to `:ready` only (per R2 from U01), and `valid_next_actions/1` advertises `:cancel_session` only from `:ready` and `:running`. A future ticket (e.g. P1-S01-T07) must introduce the necessary entry type before resume from those states can be wired through `Kiln.Workflow.resume_session/2`.
- **Revised:** PR-42 review surfaced five correctness gaps that were corrected during this revision pass:
    1. **Broken retry / idempotency.** The first implementation looked up the action_commits row by `(session_id, idempotency_key)`, but the workflow's retry generates a fresh `session_id` before the lookup, so the retry missed the original commit and committed a *second* Session. Added `priv/store/migrations/0002_action_commits_idempotency.sql` introducing `UNIQUE INDEX action_commits_idempotency_key_idx` and changed `Journal.existing_commit` to look up by `idempotency_key` alone. Added `Journal.lookup_commit/3` so the workflow can perform the lookup *before* its `Run`-state transition check, allowing a retry to replay without the transition validator firing on the post-commit state.
    2. **`valid_next_actions/1` contradicted actual operations.** The first implementation listed `:request_decision`, `:revise_intent`, `:transition_run`, etc. — operations the workflow does not implement. Replaced with a capability matrix as the single authority: `:ready => [:cancel_session, :resume_session]`, `:running => [:cancel_session]`, terminal states `[]`. `:transition_run` (the internal journal action kind for both cancel and resume) is never exposed.
    3. **Public functions raised exceptions for invalid input.** Replaced `String.to_existing_atom/1` with a bounded `@run_state_to_atom` map; added normalize/validate helpers (`normalize_start_opts/1`, `normalize_transition_opts/1`, `require_actor_id_map/1`, `require_nonempty_string_map/3`, `require_string_list_map/4`, `optional_string_list_map/3`, `require_session_id_format/1`); ensured every public function returns `{:error, %Error{}}` for malformed input. Removed the broad `rescue _ -> ...` that converted integrity failures into `{:ok, _}`-shaped envelopes.
    4. **Result shape contradictions.** The first implementation omitted `:action_id` from the start result and returned `projection_digest: nil` on replay. The result map now contains the seven stable fields; `projection_digest` and `session_revision` are stamped into the stored application result by the journal before write so an idempotent replay returns the durable values verbatim. The request digest is bound to caller-controlled input only (the auto-generated `started_at` and the auto-generated `ProjectObservation.id` are excluded) so retries with the same `idempotency_key` produce identical request digests.
    5. **Plan / docs / tests / implementation drift.** Tightened the moduledoc of `resume_session/2`, updated AC01 to include `:action_id`, updated AC05 to reflect the actual capability matrix, updated `Expected files or components` to include the new migration, journal edits, and revised test files, and updated `Completion record` with the new evidence IDs.
- **Second-pass PR-42 review.** Five further gaps surfaced and were corrected in the follow-up commit:
    1. **Action-boundary binding on replay.** A well-formed but false stored result could still replay because the workflow's validator did not bind stored `action_id`, identifier formats, `task_id`/`run_id`, `session_revision`, `projection_digest`, or `result_schema` to the authoritative action boundary the rebuild produced. Added `action_boundary` to `Replay.report/0` and `Journal.replay/0` and a set of replay-boundary validators in `Kiln.Workflow` (`require_valid_session_id`, `require_valid_task_id`, `require_valid_run_id`, `require_valid_action_id`, `require_application_result_schema`, `require_action_boundary`, `require_revision_matches_boundary`, `require_digest_matches_rebuild`).
    2. **Caller-supplied `ProjectObservation.id` distinguished.** Two distinct caller-supplied `ProjectObservation` structs shared an idempotency digest because the auto-generated `id` was excluded from it. The revision makes `id` participation conditional via `resolve_project_observation_map/1` (`:caller | :generated`) and `build_start_request_digest/1`, so caller-supplied ids participate in the digest and auto-generated ids do not.
    3. **Classifier API unified.** `lookup_commit/3` documented `{:error, %Kiln.Store.Error{}}` but returned `{:conflict, error}`; `normalize_classify_outcome/1` could raise `CaseClauseError`; `classify_commit/3` and `classify_in_transaction/2` were duplicates. Collapsed into a single `do_classify/3`; `lookup_commit/3` now returns `{:error, error}`; non-Error reasons are wrapped in `%Error{class: :unknown, code: :transaction_failed}`.
    4. **Migration specific duplicate-key code.** The v1→v2 upgrade now returns `:duplicate_global_idempotency_keys` with structured `details.duplicates: [%{idempotency_key, session_ids}]` instead of a generic `:apply_failed`. `reject_duplicate_idempotency_keys/3` pre-detects the duplicates in a read-only query, guarded by `action_commits_table_exists?/1` so a fresh-store first migration skips the check entirely. The migration SQL comment spells out operator remediation: per-key deduplication, removal of associated journal entries, and retry of the migration.
    5. **Valid v1 fixture with replay-safety proof.** The previous fixture planted rows in `action_commits` directly with fake digests and no associated `journal_entries`, which could not actually be replayed through `Replay.rebuild/2`. The new `seed_v1_session!/4` fixture writes a real `journal_entries` row whose `payload_digest` equals `Kiln.Store.Canonical.digest("session_started/v1", payload)` (unprefixed) and a real `action_commits` row whose `result_digest` equals `Kiln.Store.Canonical.digest("action_result/v1", result)` (unprefixed) and whose `request_digest` is `"sha256:" <> payload_digest` (prefixed). The test asserts `Replay.rebuild/2` returns `{:ok, report}` with the seeded projection both *before* and *after* the v2 upgrade.
    6. **Regression-evidence assertions tightened.** The capability matrix helper now captures `journal_entries`, `action_commits`, and `session_projections` row counts *after* the source state is reached and asserts all three counts are unchanged on rejection. The restart durability tests now assert zero additional rows of all three kinds and compare the entire returned result map (`assert replayed == first`). The timestamp suite now covers explicit-then-omitted and omitted-then-explicit conflicts. The idempotency conflict suite now covers changed `constraints`, `exclusions`, `repository_fingerprint`, `observed_at`, cancel-vs-resume and resume-vs-cancel cross-operation reuse, transition-revision conflicts on cancel and resume, actor-id conflicts on cancel, and cross-Session key reuse.

### Remaining unknowns and exclusions

- Approach R1 vs R2 for the `:resume_session` action kind (U01). Either way, the contract surface to callers is identical. Default: R1 (one-line addition to `Kiln.Domain.Action.kinds/0`). R2 is the fallback if R1 turns out to require reducer or replay changes out of scope here. **Resolved:** R2 was selected during implementation — `resume_session/2` uses a `:transition_run` payload, and resume is scoped to Root Run state `:ready` only. See `Failures and warnings` for the deferral of resume from `:waiting_for_user` and `:orphaned`.
- Whether a future ticket introduces `session_resumed/v1` (or an equivalent atomic-resume entry) and the corresponding reducer invariants for clearing `pending_decision` and `unknown` operation states. Until then, the workflow's resume surface is `:ready` only.

### Repository state

- Branch: `work/p1-s01-t06-workflow-surface`
- Commit: pending
- Diff reviewed: Yes (full re-run of all deterministic verification gates; results captured above).
- Implementation note: capability matrix narrowed from the originally proposed `:ready`/`:running`/`:waiting_for_user`/`:orphaned` to `:ready`/`:running` to match the P1-S01-T06 slice. The new migration (`0002_action_commits_idempotency.sql`) bumps the store version from 1 to 2; the store and migrations test suites were updated to match.
- Parent slice status after merge: enables P1-S01-T04 (foundation CLI) and contributes to P1-S01-T05 (slice gate)
