# P1-S01-T05: Prove and close the durable foundation slice

**Document type:** Implementation plan  
**Status:** Accepted  
**Parent slice:** P1-S01  
**Branch:** `work/p1-s01-t05-slice-gate`  
**Depends on:** P1-S01-T04 merged and accepted

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
| T04 supplies the minimal foundation CLI | merged ticket Evidence | preceding sequence | current P1-S01 state |
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
- **P1-S01-T05-R07:** Corrupt journal, corrupt projection, modified migration, future-version store, stale revision, conflicting idempotency key, and nonterminal-operation restart fixtures shall produce their exact protected results.
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
| `.github/workflows/ci.yml` | run the deterministic P1-S01 gate after ticket implementation | Proposed |

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

**Result:** Implemented but unverified

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P1-S01-T05-AC01 | Pending | P1-S01-T05-E01 | pending |
| P1-S01-T05-AC02 | Pending | P1-S01-T05-E02 | pending |
| P1-S01-T05-AC03 | Pending | P1-S01-T05-E03 | pending |
| P1-S01-T05-AC04 | Pending | P1-S01-T05-E04 | pending |
| P1-S01-T05-AC05 | Pending | P1-S01-T05-E05 | pending |
| P1-S01-T05-AC06 | Pending | P1-S01-T05-E06 | pending |
| P1-S01-T05-AC07 | Pending | P1-S01-T05-E07 | pending |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| pending | pending | pending |

### Demo and slice status

- Ticket demo contribution: Not yet exercised
- Parent slice gate affected: P1-S01-G09 through G11
- Slice verification manifest updated: No
- Slice completion claimed: No

### Failures and warnings

- P1-S01 cannot close from CI alone; owner-machine Evidence is required.

### Remaining unknowns and exclusions

- P1-S02 remains planned and unauthorized after this ticket unless separately adjudicated.

### Repository state

- Commit: pending
- Branch: `work/p1-s01-t05-slice-gate`
- Diff reviewed: No
- Exact CI run: pending
- Parent slice status after merge: unchanged
