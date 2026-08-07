# P1-S01-T04: Implement the foundation CLI

**Document type:** Implementation plan  
**Status:** Accepted  
**Parent slice:** P1-S01  
**Branch:** `work/p1-s01-t04-foundation-cli`  
**Depends on:** P1-S01-T03 merged and accepted; P1-S01-T06 merged and accepted

## Slice contribution

P1-S01 enables a developer to create and inspect one durable Root Session before model or mutation complexity exists.

This ticket exposes only the implemented P1-S01 actions and queries through a minimal foreground CLI development entry point with equivalent text and structured results.

It contributes to P1-S01-G08 and G11 and enables the user-facing steps of P1-S01-D01.

After merge, the CLI does not expose provider, Context, Repository-source, Patch, Command, completion, Receipt, release, Child, or Wave B commands.

## Objective

Implement a minimal foreground CLI surface for Project selection metadata, Session start, status, inspect, supported cancellation, and restart-aware resume guidance without redefining domain or persistence semantics and without claiming the final packaged `kiln` release exists.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| T01 supplies domain actions and explicit errors | accepted ticket output | preceding ticket | merged state |
| T02 supplies the store and action transaction | accepted ticket output | preceding ticket | merged state |
| T03 supplies current projection queries and restart reconstruction | accepted ticket output | preceding ticket | merged state |
| P0-W25 defines the final CLI contract, but release packaging is not authorized in P1-S01 | focused CLI authority and Prompt 8-A | integrated planning | current authority |
| No user-facing CLI parser or renderer existed at Wave A authorization | Repository inspection | Prompt 8-A | baseline |

## Assumptions and unknowns

### Assumptions

- **P1-S01-T04-A01:** A project-scoped Mix task named `mix kiln` is the smallest development entry point and does not replace the later arm64 Mix-release launcher.
- **P1-S01-T04-A02:** A small explicit parser is sufficient for the authorized command set; no CLI framework dependency is required unless the implementation proves otherwise and returns to planning.
- **P1-S01-T04-A03:** One JSON document per non-streaming invocation is sufficient for structured output.

### Unknowns

- **P1-S01-T04-U01:** Terminal color and formatting details can remain minimal because product branding and packaged delivery are later work.
- **P1-S01-T04-U02:** Interactive confirmation wording can be refined in later product CLI work, but no bypass or fake success can enter now.

## Requirements

- **P1-S01-T04-R01:** The source-development CLI shall be invoked as `mix kiln` and shall identify itself as a development entry point, not the packaged product release.
- **P1-S01-T04-R02:** The CLI shall support only `start`, `status`, `inspect`, `cancel`, and `resume` guidance for implemented P1-S01 actions.
- **P1-S01-T04-R03:** `start` shall accept one Repository root, objective, and one or more criteria and shall map to the accepted atomic Session-start action.
- **P1-S01-T04-R04:** `status` shall query the current projection and shall not infer state from transcript text.
- **P1-S01-T04-R05:** `inspect` shall show exact Session, Task, Root Run, workflow, revision, decision, operation, warning, exclusion, and unknown facts available in P1-S01.
- **P1-S01-T04-R06:** `cancel` shall be accepted only when P0-W21 permits a known cancellation without an unresolved external effect.
- **P1-S01-T04-R07:** `resume` shall not perform hidden work; it shall report the current projection and valid next P1-S01 actions.
- **P1-S01-T04-R08:** Every invocation shall support text and `--format json` output with equivalent status, identifiers, revisions, warnings, errors, and next actions.
- **P1-S01-T04-R09:** Structured output shall use `kiln.cli.result/v1` and the accepted status and exit mappings.
- **P1-S01-T04-R10:** Unsupported future commands shall be absent or shall return explicit `unsupported` with exit 9. They shall not return fake success.
- **P1-S01-T04-R11:** Stale revision, blocked store, invalid input, known failure, and unknown or orphaned state shall map to the accepted distinct exits.
- **P1-S01-T04-R12:** CLI rendering shall not become domain or store authority.
- **P1-S01-T04-R13:** CLI logs and errors shall not include Repository source, secrets, complete transcript text, or hidden payloads.
- **P1-S01-T04-R14:** The ticket shall not create release, installer, Homebrew, daemon, TUI, or auto-update behavior.

## Security boundary

Allowed:

- read accepted P1-S01 projection and metadata through application query functions;
- submit accepted P1-S01 domain actions through the application boundary;
- parse bounded UTF-8 arguments and local file paths for objective or criteria input;
- render text or one JSON result;
- return explicit unsupported results for excluded commands.

Denied:

- direct database access from renderer or parser;
- Repository source reads;
- provider or network access;
- credentials;
- source mutation;
- shell or external Commands;
- product completion, product Receipt, release packaging, Child, TUI, or Wave B behavior;
- `--yes`, auto-approval, auto-acceptance, or hidden action chaining.
- direct `Journal.commit/4`, `Domain.*` construction, `Restart.reconstruct/1`, `Projections.*`, or `Store.start/1` from the CLI dispatcher.

## Proposed changes

1. Add a small CLI request parser for the authorized P1-S01 command set.
2. Dispatch every command exclusively through `Kiln.Workflow`. The CLI aliases no `Kiln.Domain.*` module other than `Kiln.Domain.Error` (used solely to consume and pattern-match `%Kiln.Domain.Error{}` returns from `Kiln.Workflow`), and aliases no `Kiln.Store.Journal`, `Kiln.Restart`, or `Kiln.Projections.*` module. Direct journal commits, domain construction, direct domain behavior invocation, restart reconstruction, and projection rebuilds are forbidden from the dispatcher.
3. Add text and JSON renderers with stable result and error mapping.
4. Add a source-development Mix task entry point.
5. Add golden and structural tests proving text and JSON describe equivalent state.
6. Add protected unsupported-command and no-fake-success fixtures.
7. Add a narrow `Kiln.CLI.Runtime` lifecycle helper that owns store open / stop only and never reaches into the application domain.
8. Add a single-source `Kiln.CLI.ErrorMap` covering every `%Kiln.Domain.Error{}` code.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `lib/kiln/cli.ex` | parse, dispatch, and result boundary | Implemented |
| `lib/kiln/cli/request.ex` | bounded command and option types (`--actor-id`, `KILN_ACTOR_ID` env fallback, `--kiln-home` canonicalisation) | Implemented |
| `lib/kiln/cli/result.ex` | accepted result and error envelope | Implemented |
| `lib/kiln/cli/text_renderer.ex` | deterministic text rendering | Implemented |
| `lib/kiln/cli/json_renderer.ex` | canonical JSON-compatible result construction | Implemented |
| `lib/kiln/cli/runtime_bootstrap.ex` | narrow lifecycle-only helper (`open/2` with `:read` / `:write` mode, idempotent `stop/0`) | Implemented |
| `lib/kiln/cli/error_map.ex` | single-source mapping from every `%Kiln.Domain.Error{}` code to `(status, exit_code)` | Implemented |
| `lib/mix/tasks/kiln.ex` | source-development `mix kiln` entry point | Implemented |
| `test/kiln/cli/` | parser, dispatch, output, exit, and unsupported-command tests; new `runtime_bootstrap_test.exs` and `error_map_test.exs` | Implemented |
| `lib/kiln/workflow.ex` | added `current_session/0` for single-Session resolution; expanded `query_result` shape with `journal_head_digest`, `orphaned`, and `session_id`; `capability_for/1` collapses effective-orphaned Sessions to `[]`; `classify_error/1` translates `Kiln.Store.Error` to `Kiln.Domain.Error`; passes the `:no_existing_session` precondition into `Journal.commit` | Implemented |
| `lib/kiln/store/error.ex` | gains a `:precondition` class as the narrow T02 Store-error vocabulary extension for transaction-level precondition rejections | Implemented |
| `lib/kiln/store/journal.ex` | accepts the Store-owned precondition atoms `:no_existing_session` and `nil`; rejects unsupported precondition atoms before any transaction opens with `Kiln.Store.Error{class: :precondition, code: :unsupported_precondition}`; evaluates the precondition inside the existing `BEGIN IMMEDIATE` transaction; precondition failure raises a typed `%Kiln.Store.Error{}` so the Store error contract is never violated by an arbitrary caller term | Implemented |
| `test/kiln/store/journal_test.exs` | direct Store tests for `:no_existing_session` precondition (fresh commit succeeds, second distinct key rolls back with the Store error and zero writes, same idempotency key still replays, unsupported atom is rejected with the typed Store error, nil is equivalent to omission); `independent SQLite connection contention` describe block exercises SQLite file-level writer-lock serialization across two Exqlite handles (task_a calls `Journal.commit` on `ctx.conn`, task_b calls it on `second_store.conn`) | Implemented |

JSON output uses the Elixir 1.20 stdlib `JSON` module. No JSON dependency is added.

## Acceptance criteria

- **P1-S01-T04-AC01**
  - **Given** an empty accepted state directory and bounded start input
  - **When** `mix kiln start` runs
  - **Then** it creates one durable Session, Task, and Root Run and returns exact identifiers and revision in text and structured forms
  - **Evidence:** CLI start integration tests
- **P1-S01-T04-AC02**
  - **Given** current or restarted P1-S01 state
  - **When** `status` and `inspect` run
  - **Then** text and JSON outputs describe equivalent authoritative facts and safe next actions
  - **Evidence:** golden and structural equivalence tests
- **P1-S01-T04-AC03**
  - **Given** a valid known cancellation state or an orphaned or blocked state
  - **When** `cancel` runs
  - **Then** valid cancellation records the accepted action and unsafe cancellation returns the correct explicit result without changing state
  - **Evidence:** cancellation and no-change fixtures
- **P1-S01-T04-AC04**
  - **Given** stale revision, invalid input, blocked store, known failure, unknown state, or unsupported command
  - **When** CLI dispatch runs
  - **Then** each result uses the accepted status and exit code and none returns success
  - **Evidence:** protected result matrix
- **P1-S01-T04-AC05**
  - **Given** the CLI source and tests
  - **When** reviewed
  - **Then** no renderer or parser accesses SQLite directly or performs an excluded effect
  - **Evidence:** boundary source inspection and tests
- **P1-S01-T04-AC06**
  - **Given** the exact branch head
  - **When** full validation runs
  - **Then** all checks pass and no excluded command is reachable
  - **Evidence:** exact-head CI and compare
- **P1-S01-T04-AC07**
  - **Given** the rewritten dispatcher
  - **When** the source guard and integration tests run
  - **Then** every command routes through `Kiln.Workflow`; the dispatcher aliases no `Kiln.Domain.*` module except `Kiln.Domain.Error`; the dispatcher may consume and pattern-match `%Kiln.Domain.Error{}` values returned by `Kiln.Workflow` but it must not construct `%Kiln.Domain.*{}` values, call any `Kiln.Domain.*` behavior, invoke `Kiln.Store.Journal`, call `Kiln.Restart.reconstruct/1`, or call any `Kiln.Projections.*` module
  - **Evidence:** source guards in `test/kiln/cli_test.exs` (alias, fully-qualified construction, fully-qualified behavior invocation, and aliased Error construction/call guards) and `test/kiln/cli/runtime_bootstrap_test.exs`; full `mix test` run

## Deterministic verification

```bash
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/validate-agent-assets
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test test/kiln/cli
mix test
```

Focused manual fixture commands may use temporary `$KILN_HOME` paths and must not require network access.

## Demo contribution

```text
P1-S01-D01 user-visible path: start a Session, show Task and Run status, inspect durable facts, stop the application, restart, and show the same projection through `mix kiln`.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P1-S01-T04-E01 | P1-S01-T04-AC01 | start command text and structured results |
| P1-S01-T04-E02 | P1-S01-T04-AC02 | output-equivalence fixture results |
| P1-S01-T04-E03 | P1-S01-T04-AC03 | cancellation and blocked-state results |
| P1-S01-T04-E04 | P1-S01-T04-AC04 | complete exit and error matrix |
| P1-S01-T04-E05 | P1-S01-T04-AC05 | layer-boundary review |
| P1-S01-T04-E06 | P1-S01-T04-AC06 | exact compare and CI run |
| P1-S01-T04-E07 | P1-S01-T04-AC07 | source-guard and Workflow rebind tests (`test/kiln/cli_test.exs`, `test/kiln/cli/runtime_bootstrap_test.exs`) — alias, fully-qualified construction, fully-qualified behavior, and aliased Error construction guards |

### Slice gate contribution

| Slice gate or verification manifest | Contribution |
| --- | --- |
| P1-S01-G08 | equivalent text and structured output and exit mapping |
| P1-S01-G11 | excluded commands absent or unsupported |
| P1-S01-V01 | command inventory, result fixtures, warnings, and exclusions |

## Explicit exclusions

- No packaged `kiln` Mix release, installer, checksum, Homebrew formula, daemon, or auto-update.
- No provider or fake-provider execution.
- No Repository source reads.
- No Context, Tool, Patch, Approval, mutation, Command, helper, criterion completion Evidence, product Receipt, Child, TUI, or Wave B behavior.
- No direct store access from CLI rendering.
- No hidden multi-step workflow or fake success.

## Completion record

**Result:** Implemented and verified.

Code-bearing implementation head (final):
  `7d2718724f39c0ba564ba22bf2035b85d0957527` — the I9–I11 closure that corrected the cross-connection concurrency test to race two DISTINCT candidate Sessions across two SQLite connections, constrained the losing rejection to `:precondition/:session_already_exists` or `:busy/:store_busy`, and recorded the `:precondition` Store error class as the accepted narrow T02 vocabulary extension.

Exact CI for the code-bearing implementation head:
  GitHub Actions run `31207753767` (both `test` and `prose` jobs green).

Current PR/evidence head:
  `7d2718724f39c0ba564ba22bf2035b85d0957527` — the same SHA, because the I9–I11 closure commit is the final head and no subsequent documentation-only commit was needed.

The current branch head contains every correction from the F1–F9 review pass, the I1–I5 final closure pass, the I6–I8 narrow Store-error-boundary closure, and the I9–I11 cross-connection test correction. The Orphan-capability authority is fixed; concurrent-start cross-process invariant is proven within the existing SQLite transaction by both a same-connection Workflow caller test and a distinct-candidate independent-SQLite-connection Store test; the Store error boundary is restored and the `:precondition` class is recorded in `docs/work/P1-S01-T02-durable-store.md` as the narrow T02 vocabulary extension.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T04-AC01 | Verified (pre-correction, historical) | P1-S01-T04-E01 | GitHub Actions run 31142579605 on commit bb4b8a4 |
| P1-S01-T04-AC02 | Verified (pre-correction, historical) | P1-S01-T04-E02 | GitHub Actions run 31142579605 on commit bb4b8a4 |
| P1-S01-T04-AC03 | Verified (pre-correction, historical) | P1-S01-T04-E03 | GitHub Actions run 31142579605 on commit bb4b8a4 |
| P1-S01-T04-AC04 | Verified (pre-correction, historical) | P1-S01-T04-E04 | GitHub Actions run 31142579605 on commit bb4b8a4 |
| P1-S01-T04-AC05 | Verified (pre-correction, historical) | P1-S01-T04-E05 | GitHub Actions run 31142579605 on commit bb4b8a4 |
| P1-S01-T04-AC06 | Verified (pre-correction, historical) | P1-S01-T04-E06 | GitHub Actions run 31142579605 on commit bb4b8a4 |
| P1-S01-T04-AC07 | Verified (pre-correction, historical) | P1-S01-T04-E07 | GitHub Actions run 31142579605 on commit bb4b8a4 — wording then updated to permit `Kiln.Domain.Error` consumption while forbidding Domain construction / direct behavior invocation |
| Correction pass — F1 (single nonterminal vocabulary) | Verified | P1-S01-T04-E08 | `test/kiln/operation_lifecycle_parity_test.exs` (superseded by F8) |
| Correction pass — F2 (cli_result schema conformance) | Verified | P1-S01-T04-E09 | `test/kiln/cli/json_renderer_test.exs`, `scripts/validate_cli_result_schema.py` |
| Correction pass — F3 (no Domain construction in dispatcher) | Verified | P1-S01-T04-E10 | source-guard inside `test/kiln/cli_test.exs` |
| Correction pass — F4 (KILN_HOME precedence) | Verified | P1-S01-T04-E11 | `test/kiln/cli/request_test.exs` |
| Correction pass — F5 (capability-driven next actions) | Verified | P1-S01-T04-E12 | `test/kiln/cli_test.exs` capability-driven describe blocks |
| Correction pass — F6 (sequential one-Session guard) | Verified | P1-S01-T04-E13 | `test/kiln/cli_test.exs` "second start is rejected with SESSION_ALREADY_EXISTS and writes zero durable rows" |
| Correction pass — F7 (Workflow-owned capability authority) | Verified | P1-S01-T04-E14 | `test/kiln/cli_test.exs` `assert_mutating_subset/3` plus F2 capability-authority describe block; canceled/orphan states exercise the empty-capability contract |
| Correction pass — F8 (explicit `:started` operation-state parity) | Verified | P1-S01-T04-E15 | `test/kiln/operation_lifecycle_parity_test.exs` partition + persisted-`:started` fixture |
| Correction pass — F9 (AC07 Domain Error boundary + strengthened source guard) | Verified | P1-S01-T04-E16 | `test/kiln/cli_test.exs` alias / fully-qualified / aliased-Error guards |
| Final closure — I1 (orphan capability authority at Workflow) | Verified | P1-S01-T04-E17 | `Kiln.Workflow.capability_for/1` collapses effective-orphaned Sessions to `[]`; `test/kiln/cli_test.exs` proves the CLI does not advertise a mutation Workflow would then reject for both `intent_recorded` and `:started` orphan states |
| Final closure — I2 (empty-DB control flow) | Verified | P1-S01-T04-E18 | `test/kiln/cli_test.exs` "initialized empty DB + status/inspect/cancel/resume return blocked NO_SESSION without crash" + "invalid start + subsequent status does not crash" |
| Final closure — I3 (resume semantics distinction) | Verified | P1-S01-T04-E19 | `Kiln.CLI.translate_capability/1` maps only `:cancel_session -> cancel`; `test/kiln/cli_test.exs` start-result and cancel-result tests assert `resume` is never presented as a Workflow-owned mutation |
| Final closure — I4 (concurrent starts, Outcome B) | Verified | P1-S01-T04-E20 | `Kiln.Workflow.start_session` passes `:no_existing_session` into `Journal.commit`'s existing `BEGIN IMMEDIATE` transaction; `test/kiln/workflow_test.exs` "two competing start_session calls through the supervised connection produce exactly one Session" (same-BEAM, same-connection) and `test/kiln/store/journal_test.exs` "two independent Store connections to the same DB file produce exactly one Session" (cross-connection, exercises SQLite file-level writer-lock serialization) |
| Final closure — I5 (CLAUDE.md disposition) | Verified | P1-S01-T04-E21 | `CLAUDE.md` removed from PR #40 (not on `origin/main`); commit-message convention retained in `AGENTS.md` |
| Final closure — small cleanup (ErrorMap doc, store_id comment, resume doc) | Verified | P1-S01-T04-E22 | local sandbox run; comment changes document actual code behaviour and pass `scripts/check` |
| Final closure — I6 (Store error boundary restoration) | Verified | P1-S01-T04-E23 | `Kiln.Store.Journal.commit/4` accepts the Store-owned atom `:no_existing_session` (and `nil`); any other precondition atom is rejected up front with `%Kiln.Store.Error{class: :precondition, code: :unsupported_precondition}`. `Kiln.Store.Error` gains a `:precondition` class. Workflow translates `Kiln.Store.Error{class: :precondition, code: :session_already_exists}` into the existing public `session_already_exists` Domain error. `test/kiln/store/journal_test.exs` `:no_existing_session precondition` describe block proves zero-write rollback, supported-replay, and rejection-of-unsupported-precondition. |
| Final closure — I7 (cross-connection concurrency proof) | Verified | P1-S01-T04-E24 | `test/kiln/store/journal_test.exs` "independent SQLite connection contention" constructs two **distinct** start candidates (different Session/Task/Run IDs, different action IDs, different idempotency keys, different request digests) and races them across two `Store.start/1` connections to the same DB file: task_a calls `Journal.commit` on `ctx.conn`, task_b calls `Journal.commit` on `second_store.conn`. The test asserts exactly one success, exactly one typed rejection (constrained to `:precondition/:session_already_exists` or `:busy/:store_busy`), that the persisted `journal_entries.session_id` is exactly the winner's candidate, and that the durable counts are 1 / 1 / 1. The distinct candidates make the test sensitive to removal or breakage of the global `:no_existing_session` precondition; the reducer's `:session_already_started` rejection can no longer mask a missing precondition. Passes deterministically across 10 consecutive runs. |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| `scripts/test-agent-preflight` | pass | local sandbox run, 2026-08-07 |
| `python3 scripts/validate_first_month_contracts.py` | pass (10 positive / 11 negative) | local sandbox run, 2026-08-07 |
| `python3 scripts/validate_json_schema_contracts.py` | pass (10 positive / 8 schema-rejected / 3 semantic-only) | local sandbox run, 2026-08-07 |
| `scripts/validate-agent-assets` | pass | local sandbox run, 2026-08-07 |
| `vale --glob='!{deps,_build}/**' .` | pass (0 errors / 0 warnings / 0 suggestions) | local sandbox run, 2026-08-07 |
| `mix format --check-formatted` | pass | local sandbox run, 2026-08-07 |
| `mix compile --warnings-as-errors` | pass | local sandbox run, 2026-08-07 |
| `mix xref graph --format cycles --label compile-connected --fail-above 0` | pass (no cycles) | local sandbox run, 2026-08-07 |
| `mix test test/kiln/store/journal_test.exs` | 14 passed | local sandbox run, 2026-08-07 |
| `mix test test/kiln/operation_lifecycle_parity_test.exs` | 5 passed | local sandbox run, 2026-08-07 |
| `mix test test/kiln/workflow_test.exs` | 91 passed | local sandbox run, 2026-08-07 |
| `mix test test/kiln/cli` | 37 passed | local sandbox run, 2026-08-07 |
| `mix test` | 351 passed | local sandbox run, 2026-08-07 |
| `scripts/check` | pass | local sandbox run, 2026-08-07 |
| GitHub Actions `test` job on final head | success | GitHub Actions run 31207753767 on commit 7d27187 |
| GitHub Actions `prose` job on final head | success | GitHub Actions run 31207753767 on commit 7d27187 |
| Historical exact-head CI runs preserved for provenance: | | |
| GitHub Actions run 31142579605 on commit bb4b8a4 | (historical, pre-correction) | superseded |
| GitHub Actions run 31194974919 on commit ece4537 | (historical, F1–F9 final) | superseded |
| GitHub Actions run 31199247425 on commit f3fe050 | (historical, I1–I5 closure) | superseded |
| GitHub Actions run 31199785234 on commit 35cb2c3 | (historical, baseline at start of I6–I8) | superseded |
| GitHub Actions run 31206150176 on commit 2ede2b8 | (historical, I6–I8 code-bearing head) | superseded |
| GitHub Actions run 31206737852 on commit a6b6c6a | (historical, evidence-only update) | superseded |
| GitHub Actions run 31207584661 on commit 1528148 | (historical, I9–I11 prior head) | superseded by 31207753767 |

### Demo and slice status

- Ticket demo contribution: Implemented locally; aggregate owner-machine demo is T05
- Parent slice gate affected: P1-S01-G08 and G11
- Slice verification manifest updated: Yes (the F1–F9, I1–I5, and I6–I8 closure passes are owned by T04, not T05)
- Slice completion claimed: Yes — verified on final head `7d27187` by GitHub Actions run `31207753767`

### Failures and warnings

- This is a source-development entry point, not the delivered release.
- The pre-T06 remote head (`b15aaaa5d5634f72984da4877ae1b7a07f0d6b86`) was archived as tag and branch `archive/pr40-pre-workflow` before the rewrite commits landed.
- The dispatcher rewrite and every subsequent F1–F9, I1–I5, and I6–I8 closure pass landed on the same branch (`work/p1-s01-t04-foundation-cli`) and PR (#40) without `--force-with-lease` after the initial rewrite. No new PR was opened.

### Remaining unknowns and exclusions

- Aggregate owner-machine demo of the foundation CLI is T05.
- The Workflow/Restart orphan classification tension (a Session with `orphaned: true` per `Workflow.orphaned?/1` but with `run.state == :running`) is closed for the T04 surface: `Kiln.Workflow.capability_for/1` collapses the capability matrix to `[]` for any effectively-orphaned projection regardless of the underlying Run state. A future Workflow/Restart reconciliation ticket could tighten the orphan-flag / run-state semantics for non-T04 consumers; that work is not required for the T04 contract.
- The T04 `resume` command is permanently guidance-only (R07); the deferred `Workflow.resume_session/2` mutation is not exposed as an executable T04 CLI command and would belong to a future ticket.
- The `:precondition` Store error class is the narrow T02 vocabulary extension accepted by this PR; it is documented in `lib/kiln/store/error.ex` and represents the semantically correct result of a transaction-level precondition rejection. No migration, schema version, or architecture change is implied.
- No additional architecture changes are required to merge.

### Repository state

- **Final implementation head:** `7d2718724f39c0ba564ba22bf2035b85d0957527` — the I9–I11 closure that corrected the cross-connection concurrency test to race two DISTINCT candidate Sessions across two SQLite connections, constrained the losing rejection to `:precondition/:session_already_exists` or `:busy/:store_busy`, recorded the `:precondition` Store error class as the accepted narrow T02 vocabulary extension in `docs/work/P1-S01-T02-durable-store.md`, and replaced the stale provisional completion statement. Verified by GitHub Actions run `31207753767` (both `test` and `prose` jobs green).
- **Code-bearing implementation head:** `7d2718724f39c0ba564ba22bf2035b85d0957527` (same SHA — the I9–I11 commit is itself the final head and no subsequent documentation-only commit was needed).
- Branch: `work/p1-s01-t04-foundation-cli`
- Historical heads preserved for provenance:
  - `b15aaaa` (pre-Workflow-rebind) — archived as `archive/pr40-pre-workflow`
  - `bb4b8a4` (pre-correction) — verified by GitHub Actions run `31142579605`
  - `ece4537` (F1–F9 final) — verified by GitHub Actions run `31194974919`
  - `f3fe050` (I1–I5 closure) — verified by GitHub Actions run `31199247425`
  - `35cb2c3` (corrected-head baseline at start of I6–I8 pass) — verified by GitHub Actions run `31199785234`
  - `2ede2b8` (I6–I8 code-bearing head) — verified by GitHub Actions run `31206150176`
  - `a6b6c6a` (evidence-only update) — verified by GitHub Actions run `31206737852`
  - `1528148` (I9–I11 prior head, same-connection contention; superseded by distinct-candidate fix) — verified by GitHub Actions run `31207584661`
  - `7d27187` (I9–I11 final head with distinct-candidate cross-connection proof) — verified by GitHub Actions run `31207753767` ← **final**
- Parent slice status after merge: P1-S01-T04 satisfied; P1-S01-T05 unblocked
