# P1-S01-T01: Implement the durable domain foundation

**Document type:** Implementation plan  
**Status:** Accepted  
**Parent slice:** P1-S01  
**Branch:** `work/p1-s01-t01-domain-foundation`  
**Depends on:** Prompt 8-A merged at an exact green head

## Slice contribution

P1-S01 enables one durable Root Session that can be inspected and restored after restart.

This ticket adds the pure domain records, identifiers, invariants, actions, and transition rules required by later persistence and CLI tickets.

It contributes to P1-S01-G01 and P1-S01-G02 and supplies domain-contract references to P1-S01-V01.

After merge, no state is persisted and no user workflow is operational.

## Objective

Implement the smallest pure Elixir domain foundation that expresses the accepted first-month Project observation, Session, initial Task, Root Run, pending decision, external-operation intent and observation, journal action, revision, idempotency, and transition rules without performing any external effect.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| Product runtime contains only bootstrap and conformance support | `lib/`, `mix.exs` | Prompt 8-A inspection | `57a5790d2266cf1ab59f107d0b429c31c618e0ae` |
| P0-W21 defines exact first-month states and transition authority | `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md` | integrated planning | current authority |
| No product identifier, Session, Task, Run, decision, operation, or action type exists | Repository inspection | Prompt 8-A | current baseline |
| No product implementation is authorized outside P1-S01 | `docs/WAVE-A-ADJUDICATION-AND-AUTHORIZATION.md` | Prompt 8-A | after merge |

## Assumptions and unknowns

### Assumptions

- **P1-S01-T01-A01:** Opaque string identifiers with validated prefixes are sufficient before a database representation exists.
- **P1-S01-T01-A02:** Plain structs and pure functions are sufficient; no process is required.
- **P1-S01-T01-A03:** Domain actions can carry expected revision and idempotency key without selecting storage behavior.

### Unknowns

- **P1-S01-T01-U01:** Exact serialized field names can change in T02 if migration design reveals a conflict, but accepted semantics and conformance fixtures cannot silently change.
- **P1-S01-T01-U02:** Exact time representation must be selected from existing Elixir types and tested without a live clock.

## Requirements

- **P1-S01-T01-R01:** Kiln shall generate and validate identifiers for Project observation, Session, Task, Run, decision, operation, journal action, and idempotency subject.
- **P1-S01-T01-R02:** Session construction shall create one `active` Session, one `in_progress` initial Task, and exactly one `ready` Root Run as one validated result.
- **P1-S01-T01-R03:** The initial Task shall not create a separate Root Task concept.
- **P1-S01-T01-R04:** Root Run state shall be limited to `ready`, `running`, `waiting_for_user`, `orphaned`, `completed`, `failed`, and `canceled`.
- **P1-S01-T01-R05:** Workflow step, pending decision, external-operation state, and future Evidence state shall remain separate from Run state.
- **P1-S01-T01-R06:** Transition validation shall accept only the P0-W21 transition table and shall reject terminal-state escape and direct `orphaned` completion.
- **P1-S01-T01-R07:** A domain action shall carry Session identity, expected revision, idempotency key, actor, action kind, and validated payload.
- **P1-S01-T01-R08:** External-operation intent and observation records shall express `intent_recorded`, `started`, `succeeded`, `failed`, `canceled`, and `unknown` without dispatching an effect.
- **P1-S01-T01-R09:** Pending decisions shall identify exact subject, revision, actor, permitted responses, and resume action.
- **P1-S01-T01-R10:** Constructors and transitions shall return explicit errors and shall never return a success-like placeholder for unsupported behavior.
- **P1-S01-T01-R11:** Domain records shall not store process identifiers, provider request identifiers, branch or worktree identity, complete transcript content, hidden reasoning, or Artifact payloads.

## Security boundary

Allowed:

- pure Elixir structs, enums, constructors, validators, reducers, and error types;
- deterministic identifier generation using an injected entropy source in tests;
- deterministic timestamp values supplied by the caller;
- conformance fixtures and unit tests.

Denied:

- filesystem access;
- SQLite or any durable write;
- Repository source read;
- network or provider access;
- credentials;
- source mutation;
- external Commands or shell;
- processes or supervision changes;
- completion Evidence, product Receipt, release, Child, TUI, or Wave B behavior.

A malformed action, stale subject shape, unsupported state, or invalid transition returns an explicit error.

## Proposed changes

1. Add opaque identifier generation and validation.
2. Add first-month Project observation, Session, Task, and Root Run records.
3. Add pending decision and external-operation record shapes.
4. Add domain action and error types.
5. Add pure constructors and lifecycle/action validation.
6. Map accepted conformance constants to domain tests without making `Kiln.Conformance` product authority.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `lib/kiln/domain/id.ex` | identifier generation and validation | Proposed |
| `lib/kiln/domain/project_observation.ex` | selected Repository metadata boundary | Proposed |
| `lib/kiln/domain/session.ex` | first-month Session record and constructor | Proposed |
| `lib/kiln/domain/task.ex` | initial Task record | Proposed |
| `lib/kiln/domain/run.ex` | Root Run record | Proposed |
| `lib/kiln/domain/decision.ex` | pending user-decision record | Proposed |
| `lib/kiln/domain/operation.ex` | external-operation record | Proposed |
| `lib/kiln/domain/action.ex` | expected-revision and idempotency action envelope | Proposed |
| `lib/kiln/domain/transition.ex` | pure lifecycle/action validation | Proposed |
| `lib/kiln/domain/error.ex` | stable domain error type | Proposed |
| `test/kiln/domain/` | deterministic unit and property-oriented table tests | Proposed |

Do not add placeholder modules for later provider, Repository reader, Patch, Command, Evidence, Receipt, CLI, or Child systems.

## Acceptance criteria

- **P1-S01-T01-AC01**
  - **Given** accepted objective, criteria, Project observation metadata, deterministic time, and identifier source
  - **When** the Session constructor runs
  - **Then** it returns one `active` Session, one `in_progress` Task, and one `ready` Root Run with distinct stable identifiers
  - **Evidence:** ExUnit constructor fixture
- **P1-S01-T01-AC02**
  - **Given** every accepted and protected invalid Run transition
  - **When** transition validation runs
  - **Then** accepted transitions pass and all other transitions return explicit errors
  - **Evidence:** complete transition-table test
- **P1-S01-T01-AC03**
  - **Given** a decision or operation shape
  - **When** it is constructed
  - **Then** exact subject, revision, actor, state, and idempotency fields are validated without performing an effect
  - **Evidence:** decision and operation tests
- **P1-S01-T01-AC04**
  - **Given** a product domain record
  - **When** its fields are inspected
  - **Then** no runtime handle, provider identity, branch, worktree, hidden reasoning, or payload content is accepted as durable identity
  - **Evidence:** protected negative tests
- **P1-S01-T01-AC05**
  - **Given** the exact branch head
  - **When** Repository validation runs
  - **Then** all checks pass and no external-effect dependency or behavior exists
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
mix test test/kiln/domain
mix test
```

Every command must exit zero. Tests must use injected deterministic time and identifier sources.

## Demo contribution

```text
P1-S01-D01 steps 2 and 3: construct and display the accepted Session, initial Task, and Root Run in a test-only demonstration without persistence.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P1-S01-T01-E01 | P1-S01-T01-AC01 | constructor test output and exact struct fields |
| P1-S01-T01-E02 | P1-S01-T01-AC02 | complete transition-table result |
| P1-S01-T01-E03 | P1-S01-T01-AC03 | decision and operation fixture results |
| P1-S01-T01-E04 | P1-S01-T01-AC04 | protected identity-field negatives |
| P1-S01-T01-E05 | P1-S01-T01-AC05 | exact compare and CI run |

### Slice gate contribution

| Slice gate or verification manifest | Contribution |
| --- | --- |
| P1-S01-G01 | identifiers and Session, Task, Root Run invariants |
| P1-S01-G02 | accepted transition table |
| P1-S01-V01 | commit, tests, warnings, exclusions, and contract references |

## Explicit exclusions

- No `mix.exs` runtime dependency change.
- No application supervision change.
- No SQLite, files, migrations, journal persistence, or projections.
- No provider or fake-provider execution.
- No Repository source reads.
- No Patch, Approval, mutation, rollback, Command, helper, Evidence, completion, product Receipt, CLI, release, Child, TUI, or Wave B behavior.

## Completion record

**Result:** Complete

All required acceptance criteria pass and the full deterministic verification gate ran at the exact branch head. Review, merge, and slice acceptance remain downstream and are not claimed here.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T01-AC01 | Pass | P1-S01-T01-E01 | `Session.start/2` returns one `active` Session, one `in_progress` Task, and one `ready` Root Run with three distinct identifiers and no `root_task_id` |
| P1-S01-T01-AC02 | Pass | P1-S01-T01-E02 | Complete 7x7 transition matrix accepts only the P0-W21 table; terminal escape, direct `orphaned` completion, and unsupported states return explicit errors |
| P1-S01-T01-AC03 | Pass | P1-S01-T01-E03 | Decision and Operation constructors validate subject, revision, actor, state, and idempotency fields with no effect dispatched |
| P1-S01-T01-AC04 | Pass | P1-S01-T01-E04 | Action rejects `pid`, `process_id`, `provider_request_id`, `branch`, `worktree`, `transcript`, `hidden_reasoning`, `artifact_payload`, runtime handles, and tuples in payloads |
| P1-S01-T01-AC05 | Pass | P1-S01-T01-E05 | Aggregate `scripts/check` exits zero at exact head `3707cf72` with a clean working tree and no external-effect dependency |

### Verification executed

Toolchain: Elixir 1.20.2 / Erlang OTP 28 (repo `mise.toml` pin); `jsonschema==4.26.0` from `requirements/conformance.txt`. Executed at commit `3707cf724d4906dffdbb8b152420495e2641f570`.

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| `scripts/test-agent-preflight` | 0 | `test-agent-preflight: pass` |
| `python3 scripts/validate_first_month_contracts.py` | 0 | `pass`; 10 positive, 11 protected-negative fixtures |
| `python3 scripts/validate_json_schema_contracts.py` | 0 | `pass`; jsonschema 4.26.0; 10 positive, 8 schema-rejected, 3 semantic-only negatives |
| `scripts/validate-agent-assets` | 0 | `pass`; 5 skills, 3 agents, 3 templates |
| `vale .` | 0 | 0 errors, 0 warnings, 0 suggestions in 120 files |
| `mix format --check-formatted` | 0 | no output |
| `mix compile --warnings-as-errors` | 0 | 15 files compiled, `Generated kiln app` |
| `mix xref graph --format cycles --label compile-connected --fail-above 0` | 0 | `No cycles found` |
| `mix test test/kiln/domain` | 0 | 14 passed |
| `mix test` | 0 | 21 passed |
| `scripts/check` (aggregate) | 0 | `check: pass`; `working tree: clean`; commit `3707cf72` |

### Demo and slice status

- Ticket demo contribution: Exercised through `Kiln.Domain.SessionTest`, which constructs and asserts the accepted Session, initial Task, and Root Run without persistence
- Parent slice gate affected: P1-S01-G01 and G02
- Slice verification manifest updated: No
- Slice completion claimed: No

### Failures and warnings

- None. All verification commands exited zero at the exact head with a clean working tree.
- Environment note: this host's Homebrew Elixir is 1.19.5 and its system Python is PEP 668 externally managed. Verification used the repo-pinned mise Elixir 1.20.2 / OTP 28 toolchain and a virtualenv holding the pinned `jsonschema==4.26.0`. No source, dependency, or repository state was changed to make the gate pass.

### Remaining unknowns and exclusions

- Persistence and runtime behavior remain T02 and later work. No SQLite, migration, or store work was started.
- Serialized field names (U01) and time representation (U02) remain adjustable in T02 without changing accepted semantics.

### Repository state

- Commit: `3707cf724d4906dffdbb8b152420495e2641f570`
- Branch: `work/p1-s01-t01-domain-foundation`
- Diff reviewed: Yes; only the ten `lib/kiln/domain/*.ex` modules and five `test/kiln/domain/*.exs` tests (1639 insertions, 0 deletions) versus `main`
- Exact CI run: Full local gate green at exact head; authoritative CI run and owner review pending on the pull request
- Parent slice status after merge: unchanged (no state persisted, no workflow operational)
