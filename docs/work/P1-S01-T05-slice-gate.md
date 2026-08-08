# P1-S01-T05: Prove and close the durable foundation slice

**Document type:** Implementation plan  
**Status:** Accepted  
**Parent slice:** P1-S01  
**Branch:** `work/p1-s01-t05-slice-gate`  
**Depends on:** P1-S01-T04 merged and accepted (which depends on P1-S01-T06, the shared `Kiln.Workflow` application boundary)

## Slice contribution

P1-S01 enables one durable Root Session that survives restart and can be inspected through a minimal CLI.

This ticket creates the aggregate gate, exact restart demo, corruption and migration fixtures, owner-machine verification, and P1-S01-V01 slice verification manifest.

It contributes to P1-S01-G09 through G11 and closes the slice only if every gate passes against the exact integrated state.

It does not add a product Receipt or authorize P1-S02 automatically.

## Objective

Prove the complete P1-S01 durable foundation against its exact integrated state, record one bounded slice verification manifest, and either declare P1-S01 accepted or block progression without implementing any P1-S02 subsystem.

## Observed current state

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| T01 supplies accepted domain records and transitions | merged ticket Evidence | preceding sequence | current P1-S01 state |
| T02 supplies the durable store, migrations, revisions, and idempotency | merged ticket Evidence | preceding sequence | current P1-S01 state |
| T03 supplies replay, projections, and restart reconstruction | merged ticket Evidence | preceding sequence | current P1-S01 state |
| T06 supplies the shared `Kiln.Workflow` application boundary | merged ticket Evidence | preceding sequence | current P1-S01 state |
| T04 supplies the minimal foundation CLI, rebound onto the T06 Workflow boundary | merged ticket Evidence | preceding sequence | current P1-S01 state |
| The integrated deterministic suite is 351 tests, substantially larger than when this plan was authored | `mix test` at `118bcaa` | implementation agent | 2026-08-08 |
| Real governing-plan preflight is part of the standard verification path | P0-W32 merged (PR #45) | implementation agent | `118bcaa` |
| Development-agent assets carry invocation and lifecycle contracts | P0-W31 merged (PR #44) | implementation agent | `118bcaa` |
| No aggregate P1-S01 gate, demo, or verification manifest exists | Repository inspection | implementation agent | ticket entry |

## Assumptions and unknowns

### Assumptions

- **P1-S01-T05-A01:** One aggregate shell entry point can orchestrate deterministic project checks without becoming product logic.
- **P1-S01-T05-A02:** A canonical implementation Evidence manifest can be generated from exact references without using product Receipt semantics.
- **P1-S01-T05-A03:** The owner-machine fixture can use one temporary local APFS Repository and `$KILN_HOME` without reading project source content.

### Unknowns

- **P1-S01-T05-U01:** Any host-specific SQLite or filesystem limitation discovered during the aggregate run must be recorded and can block P1-S01.
- **P1-S01-T05-U02:** P1-S02 ticket boundaries can be reconsidered only after P1-S01 Evidence; this ticket cannot authorize them.

## Requirements

- **P1-S01-T05-R01:** The ticket shall create `scripts/gates/slice-01` as the sole P1-S01 aggregate command.
- **P1-S01-T05-R02:** The gate shall run all Repository conformance checks, P1-S01 deterministic tests, migration and corruption fixtures, restart demo checks, and excluded-capability checks.
- **P1-S01-T05-R03:** The gate shall emit human-readable output and one machine-readable structured result Artifact.
- **P1-S01-T05-R04:** The gate shall bind its result to exact commit, dirty fingerprint, toolchain, migration, SQLite, fixture, and Environment facts.
- **P1-S01-T05-R05:** P1-S01-D01 shall execute the accepted user-visible foundation workflow against an isolated fixture state.
- **P1-S01-T05-R06:** The demo shall stop and restart the application and shall prove that current truth comes from the journal and projection reconstruction rather than transcript inference.
- **P1-S01-T05-R07:** Corrupt journal, corrupt projection, modified migration, future-version store, stale revision, conflicting idempotency key, and nonterminal-operation restart fixtures shall produce their exact protected results. T03, T04, and T06 already own the lower-level protections; the aggregate layer proves each classification still holds when reached through the integrated `Kiln.CLI.Runtime` and `Kiln.Workflow` boundary rather than duplicating those unit fixtures.
- **P1-S01-T05-R08:** Provider, Repository source read, Context, Tool, Patch, mutation, external Command, completion Evidence, product Receipt, release, Child, TUI, and Wave B paths shall be absent or explicitly unsupported.
- **P1-S01-T05-R09:** The ticket shall create P1-S01-V01 as a canonical slice verification manifest from exact immutable references.
- **P1-S01-T05-R10:** P1-S01-V01 shall not claim Task satisfaction, Run completion, product acceptance, product Receipt authority, or authorization of P1-S02.
- **P1-S01-T05-R11:** The owner-machine gate shall record the OD-02 host, local APFS, runtime, Exqlite, SQLite, WAL, sync, migration, restart, and unsupported-control facts.
- **P1-S01-T05-R12:** A failed, blocked, unknown, dirty, or incomplete gate shall prevent slice acceptance and shall not be hidden by a successful demo.
- **P1-S01-T05-R13:** P1-S01 acceptance shall require owner review of the exact integrated diff and manifest.

## Security boundary

Allowed:

- execute Repository tests and conformance scripts;
- create isolated temporary fixture databases and metadata-only fixture Repositories;
- stop and restart Kiln locally;
- collect bounded diagnostic and test output;
- hash files and manifests;
- create one implementation Evidence manifest.

Denied:

- provider or public-network access;
- credentials;
- Repository source disclosure;
- source mutation;
- shell execution as a product Command;
- native process-group helper execution;
- criterion completion Evidence;
- product Receipt sealing;
- release packaging or installation;
- Child, TUI, or Wave B behavior;
- changing product code solely to make a gate pass without updating the owning ticket Evidence.

The aggregate script is development verification, not a model-facing Tool or registered product Command.

## Proposed changes

1. Add deterministic aggregate gate orchestration.
2. Add the exact P1-S01 restart demo fixture and runner.
3. Add protected migration, corruption, revision, idempotency, projection, and unknown-operation aggregate fixtures.
4. Add excluded-capability and no-fake-success checks.
5. Add canonical P1-S01-V01 generation and validation.
6. Run the gate on CI and on the owner’s OD-02 machine.
7. Complete the P1-S01 slice record only after all Evidence is accepted.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `scripts/gates/slice-01` | aggregate deterministic gate | Proposed |
| `scripts/demos/p1-s01` | exact restart demo runner | Proposed |
| `scripts/diagnostics/p1-s01-store-host` | finalize owner-machine output contract | Proposed |
| `lib/kiln/verification_manifest.ex` | canonical implementation Evidence manifest construction | Proposed |
| `test/kiln/slices/p1_s01_test.exs` | aggregate protected assertions | Proposed |
| `test/fixtures/p1_s01/` | complete slice fixtures | Proposed |
| `artifacts/p1-s01/README.md` | generated-Artifact location contract, not committed runtime output | Proposed |
| `docs/work/P1-S01-slice-closeout.md` | exact aggregate closeout record | Proposed |
| `scripts/gates/build_manifest.exs` | manifest generation invoked by the aggregate gate | Added during implementation |
| `test/kiln/verification_manifest_test.exs` | manifest state-binding and non-authority assertions | Added during implementation |
| `lib/mix/tasks/kiln.ex` | start the application before dispatch (integration defect correction, see Completion record) | Added during implementation |
| `.gitignore` | exclude generated gate Artifacts while tracking the location contract | Added during implementation |
| `.github/workflows/ci.yml` | run the deterministic P1-S01 gate after ticket implementation; install the pinned Vale the gate requires | Proposed |

Do not add product Receipt, provider, Repository-reader, Patch, Command, helper, release, Child, or TUI files.

## Acceptance criteria

- **P1-S01-T05-AC01**
  - **Given** the exact integrated P1-S01 candidate state
  - **When** `scripts/gates/slice-01` runs in CI
  - **Then** every P1-S01-G01 through G11 check passes and one structured result is produced
  - **Evidence:** CI aggregate gate output and structured Artifact
- **P1-S01-T05-AC02**
  - **Given** a clean isolated fixture
  - **When** P1-S01-D01 runs
  - **Then** one Session starts, is inspected, the application stops, restarts, and displays the exact reconstructed state
  - **Evidence:** deterministic demo transcript and state digests
- **P1-S01-T05-AC03**
  - **Given** every protected aggregate failure fixture
  - **When** the gate runs
  - **Then** the expected blocked or failed result appears and no false state or success is created
  - **Evidence:** fixture result matrix
- **P1-S01-T05-AC04**
  - **Given** the owner’s OD-02 host
  - **When** the owner-machine gate runs
  - **Then** required host, filesystem, SQLite, WAL, migration, restart, and unsupported-control facts are recorded and acceptable
  - **Evidence:** signed-off diagnostic Artifact or exact captured output
- **P1-S01-T05-AC05**
  - **Given** all accepted ticket and aggregate Evidence
  - **When** P1-S01-V01 is generated
  - **Then** it references exact immutable facts, validates its digest, and contains no product Receipt or completion claim
  - **Evidence:** manifest validation result
- **P1-S01-T05-AC06**
  - **Given** the complete slice state
  - **When** excluded actions and namespaces are inspected
  - **Then** no unauthorized subsystem is reachable or returns fake success
  - **Evidence:** protected exclusion check
- **P1-S01-T05-AC07**
  - **Given** the exact final branch and projected merged state
  - **When** full CI and owner review complete
  - **Then** P1-S01 is accepted or explicitly blocked with no automatic P1-S02 authorization
  - **Evidence:** exact CI, compare, owner decision, and closeout record

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
mix test
scripts/gates/slice-01
scripts/demos/p1-s01
```

Owner-machine verification:

```bash
scripts/diagnostics/p1-s01-store-host
scripts/gates/slice-01
scripts/demos/p1-s01
```

Every required command must exit zero. The fixture matrix contains internal expected failures that must be classified correctly without failing the aggregate harness itself.

## Demo contribution

```text
P1-S01-D01 complete: select fixture Repository metadata, start Session, inspect Task and Root Run, record accepted state, stop Kiln, restart, inspect identical reconstructed state, and verify P1-S01-V01.
```

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P1-S01-T05-E01 | P1-S01-T05-AC01 | aggregate CI output and structured result |
| P1-S01-T05-E02 | P1-S01-T05-AC02 | deterministic demo output and digests |
| P1-S01-T05-E03 | P1-S01-T05-AC03 | aggregate protected fixture matrix |
| P1-S01-T05-E04 | P1-S01-T05-AC04 | owner-machine diagnostic and gate output |
| P1-S01-T05-E05 | P1-S01-T05-AC05 | P1-S01-V01 and validation output |
| P1-S01-T05-E06 | P1-S01-T05-AC06 | excluded-capability audit |
| P1-S01-T05-E07 | P1-S01-T05-AC07 | exact compare, CI, owner review, and closeout |

### Slice gate contribution

| Slice gate or verification manifest | Contribution |
| --- | --- |
| P1-S01-G09 | process and durable-record ownership audit |
| P1-S01-G10 | aggregate demo, owner-machine checks, and exact state binding |
| P1-S01-G11 | excluded-capability proof |
| P1-S01-V01 | complete slice implementation Evidence manifest |

## Explicit exclusions

- No product capability beyond P1-S01.
- No provider or fake-provider execution.
- No Repository source read or mutation.
- No Context, Tool, Patch, Approval, external Command, helper, criterion completion Evidence, product Receipt, release, Child, TUI, or Wave B behavior.
- No automatic P1-S02 authorization.
- No merge when owner-machine Evidence, exact CI, or aggregate manifest is missing.

## Completion record

**Result:** Implemented; deterministic verification passes; owner-machine Evidence collected on the accepted OD-02 acceptance machine

The aggregate gate, the P1-S01-D01 demo, the protected failure matrix, the
excluded-capability audit, and P1-S01-V01 are implemented and pass at the exact
branch head. One integration defect in previously merged work was discovered and
corrected. The final owner-machine pass collected AC04 Evidence on the accepted
OD-02 acceptance machine. AC07 remains open pending owner review.

### Integration defect discovered and corrected

**Severity:** High. The entire user-visible P1-S01 CLI was non-functional outside
the test harness.

| Field | Finding |
| --- | --- |
| Owning contract | P1-S01-T04-R01: "The source-development CLI shall be invoked as `mix kiln`" |
| Observed behavior | `mix kiln start` exited 1 with an unstructured BEAM crash (`DBConnection.Watcher ... no process`), created no state database, and emitted no `kiln.cli.result/v1` envelope |
| Root cause | A Mix task does not start the current application. `Kiln.CLI.Runtime.open/2` opens an Exqlite pool that registers with `DBConnection.Watcher`, which exists only when `:db_connection` is running. `Mix.Tasks.Kiln.run/1` never started the application |
| Why prior Evidence missed it | Every T04 acceptance test calls `Kiln.CLI.run/1` in process under `mix test`, where Mix has already started `:kiln` and its dependencies. No test executed the real `mix kiln` entry point as an operating-system process, so the tests measured a proxy rather than the integrated entry point |
| Correction | `Mix.Tasks.Kiln.run/1` calls `Mix.Task.run("app.start")` before dispatch. `Kiln.Application` supervises no store at boot, so this opens no database and leaves the per-command store lifecycle with `Kiln.CLI.Runtime` |
| Protected regression Evidence | `test/kiln/slices/p1_s01_test.exs`, describe "the real mix kiln entry point runs as an operating-system process". Verified adversarially: with the correction reverted the test fails with the exact original crash; with it applied the test passes |

The correction is inside already-authorized P1-S01 behavior. It makes an accepted
T04 requirement true rather than adding capability. The gate was not weakened to
accommodate it.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T05-AC01 | Pass | P1-S01-T05-E01 | `scripts/gates/slice-01` exits 0 across 18 components; structured result written to `artifacts/p1-s01/slice-01-<commit>.json` |
| P1-S01-T05-AC02 | Pass | P1-S01-T05-E02 | `scripts/demos/p1-s01` exits 0; identifiers and digests identical across separate operating-system processes and after the projection cache is discarded |
| P1-S01-T05-AC03 | Pass | P1-S01-T05-E03 | Seven protected cases assert their exact classification through the integrated boundary; the harness itself fails if a fixture fails differently |
| P1-S01-T05-AC04 | **Pass** | P1-S01-T05-E04 | Final owner-machine pass on the accepted OD-02 acceptance machine (`hw.model = MacBookPro18,1`). See "Owner-machine Evidence" below |
| P1-S01-T05-AC05 | Pass | P1-S01-T05-E05 | `Kiln.VerificationManifest` builds and validates P1-S01-V01; 21 assertions cover state binding and non-authority |
| P1-S01-T05-AC06 | Pass | P1-S01-T05-E06 | Deterministic module, behaviour, source, and command-surface reachability checks |
| P1-S01-T05-AC07 | **Open** | P1-S01-T05-E07 | Owner review of the exact integrated diff and manifest has not been given |

### Owner-machine Evidence (AC04)

The accepted OD-02 profile names "the owner's M1 Pro MacBook Pro" as the primary
acceptance machine. Detected host on the final owner-machine pass:

```text
model:      MacBook Pro (MacBookPro18,1), Apple M1 Pro
macOS:      26.5.2 (build 25F84)
arch:       arm64
filesystem: APFS, internal (device /dev/disk3s1)
memory:     16 GB
```

This host is the named acceptance machine: `hw.model = MacBookPro18,1`. The
`scripts/gates/slice-01` owner-machine guard (`KILN_OWNER_MACHINE=1`) refuses
the assertion on any other Apple Silicon Mac, so a wrong machine cannot
produce a passing `KILN_OWNER_MACHINE=1` result. With the actual hardware
identity recorded and validated, the aggregate gate records
`owner_machine_diagnostic = pass` and P1-S01-V01 records `overall: pass`,
`owner_machine.outcome = pass`, and `owner_machine.decision = OD-02`.

The earlier implementation pass on an Apple M3 MacBook Air (`Mac15,13`) is
preserved as the machine that proved every deterministic component and the
earlier `not_run` owner-machine Evidence. The hardened hardware-model check
added at `c872c16` is what made this final pass provably distinct from that
earlier run.

### Verification executed

Executed at branch `work/p1-s01-t05-slice-gate`. Toolchain: Elixir 1.20.2,
Erlang/OTP 28.4, Exqlite 0.39.0, SQLite 3.53.3, Vale 3.14.2, jsonschema 4.26.0.

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| `scripts/agent-preflight` | 0 | selects P1-S01-T05 and `docs/work/P1-S01-T05-slice-gate.md` |
| `scripts/test-agent-preflight` | 0 | validator regression passes |
| `python3 scripts/validate_first_month_contracts.py` | 0 | 10 positive, 11 protected-negative fixtures |
| `python3 scripts/validate_json_schema_contracts.py` | 0 | jsonschema 4.26.0 |
| `scripts/validate-agent-assets` | 0 | 5 skills, 3 specialist agents, 3 prompt templates |
| `vale --glob='!{deps,_build}/**' .` | 0 | 0 errors, 0 warnings, 0 suggestions |
| `mix format --check-formatted` | 0 | clean |
| `mix compile --warnings-as-errors` | 0 | no warnings |
| `mix xref graph --format cycles --label compile-connected --fail-above 0` | 0 | no cycles |
| `mix test` | 0 | 386 tests, 386 passed (351 inherited + 14 slice + 21 manifest) |
| `scripts/gates/slice-01` | 0 | 18 components; 0 failed; 0 blocked; owner-machine `not_run` (deterministic pass) |
| `scripts/gates/slice-01` (`KILN_OWNER_MACHINE=1`) | 0 | 18 components; 0 failed; 0 blocked; `owner_machine_diagnostic = pass` on the OD-02 acceptance machine; P1-S01-V01 `overall: pass` |
| `scripts/demos/p1-s01` | 0 | P1-S01-D01 restart and journal-reconstruction parity |
| `scripts/check` | 0 | aggregate development check |
| `scripts/diagnostics/p1-s01-store-host` | 0 | ran on the accepted OD-02 acceptance machine |

### Adversarial verification of the gate itself

| Property | Method | Result |
| --- | --- | --- |
| A failed required component fails the gate | injected a formatting defect | gate exited 1 and reported `FAIL source_formatting` |
| A passing demo cannot hide a failed gate | same injected run | manifest recorded `demo: pass` with `overall: fail` |
| A regression test actually protects the defect it names | reverted the `mix kiln` correction | the entry-point test failed with the exact original crash |
| A manifest cannot be replayed against another commit | edited the recorded commit | `validate/1` returned `digest_mismatch` |
| A manifest cannot be edited into a claim | flipped `is_product_receipt` and `overall` | `not_authority_altered` and `overall_mismatch` |

### Demo and slice status

- Ticket demo contribution: P1-S01-D01 exercised; restart parity and
  journal reconstruction after cache discard both proved.
- Parent slice gate affected: P1-S01-G09 through G11.
- Slice verification manifest updated: Yes; P1-S01-V01 generated and validated,
  `overall: pass` after the owner-machine Evidence was collected on the accepted
  OD-02 acceptance machine.
- Slice completion claimed: **No.** AC07 owner review remains open.

### Failures and warnings

- AC07 is open: owner review has not been given.
- The earlier owner-machine run on an M3 MacBook Air produced a `BLOCKED`
  owner-machine component and is recorded as the limitation that the
  hardware-model check in the hardened gate and diagnostic now closes.

### Remaining unknowns and exclusions

- P1-S02 remains planned and unauthorized after this ticket unless separately
  adjudicated.

### Owner-machine Evidence (final pass, AC04)

The final owner-machine pass was executed on the accepted OD-02 acceptance
machine, the owner's M1 Pro MacBook Pro (`hw.model = MacBookPro18,1`):

| Command or check | Result |
| --- | --- |
| `scripts/diagnostics/p1-s01-store-host` | pass — recorded macOS 26.5.2 (build 25F84), APFS internal, Exqlite 0.39.0, SQLite 3.53.3, journal_mode `wal`, synchronous `2`, foreign_keys `1`, busy_timeout `2000`, quick_check `ok` |
| `KILN_OWNER_MACHINE=1 scripts/gates/slice-01` | pass — 18 components; 0 failed; 0 blocked; `owner_machine_diagnostic = pass`; manifest at `artifacts/p1-s01/slice-01-444c5a5ac47fec1982909f570a44838fdbc55d3b.json` with digest `sha256:94a5f9ec37dcc0fbb64444e5ad48fe73e9527ec8dbae9cff2e01faf5da5d68aa` |
| `scripts/demos/p1-s01` | pass — P1-S01-D01 restart parity and journal-reconstruction across separate OS processes; cache discarded, state rebuilt identically |

The earlier implementation pass on an M3 MacBook Air is preserved as the
machine that proved every deterministic component and the earlier
`not_run` owner-machine Evidence. The hardened hardware-model check is what
makes this final pass provably distinct from that earlier run.

### Repository state

- Branch: `work/p1-s01-t05-slice-gate`
- Base: `118bcaad7353e8f891e4d0101460379e78138e56`
- Diff reviewed: Yes
- Parent slice status after merge: P1-S01 candidate proved on every machine
  gate including the accepted OD-02 acceptance machine; acceptance withheld
  pending owner review (AC07).
