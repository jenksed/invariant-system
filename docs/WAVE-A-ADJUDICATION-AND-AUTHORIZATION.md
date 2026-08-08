# Wave A Adjudication and Development Authorization

**Document type:** Final Wave A adjudication and build-authorization authority  
**Status:** Historical adjudication. Merged at `118bcaa`; P1-S01 authorization consumed by PR #46 (P1-S01 integrated at `db02198`). This document is preserved for provenance; the live authorization state lives in `AGENTS.md`, `docs/ROADMAP.md`, `docs/IMPLEMENTATION-SLICES.md`, and `docs/PLANNING.md`.  
**Branch:** `work/p0-w29-wave-a-adjudication` (historical, merged)  
**Authorization level:** Vertical Slice Authorized (historical, consumed)  
**Authorized scope:** P1-S01-T01 through P1-S01-T05 (historical, consumed)  
**Wave B:** Blocked

## Purpose

This document closes Wave A.

It:

- records the Prompt 8-A entry gate;
- adjudicates the independent Prompt 7-A findings;
- reconciles active authority and conformance defects;
- defines the exact executable P1-S01 handoff;
- authorizes bounded development after this pull request merges.

It does not implement Kiln.

Prompt 8-A is the current executable-scope authority. Roadmap prose, historical Schemas, earlier component plans, and unauthorised ticket names do not independently permit work.

# 1. Entry gate

## Observed facts

| Fact | Evidence | Result |
| --- | --- | --- |
| Prompt 6-A is integrated into `main` | pull request 34 | Pass |
| Prompt 6-A final branch head | `7b9afe5552ca0d336d343d4bfbe17ce7d14cc955` | Recorded |
| Prompt 6-A merge commit and entry `main` | `57a5790d2266cf1ab59f107d0b429c31c618e0ae` | Recorded |
| Prompt 6-A exact-head CI | run `30425270052`, success | Pass |
| PR 35 provider and SQLite corrections are integrated | PR 35 merge `d76402a30e178d577d363384750baffd062cf9ef` and synchronized Prompt 6-A commits | Pass |
| No later commit invalidated the baseline before Prompt 8-A began | current `main` equaled the Prompt 6-A merge | Pass |
| Product runtime remains substantially unimplemented | bootstrap modules plus three conformance modules only | Pass |
| Prompt 6-A added conformance only and issued no authorization | PR 34 compare and work scope | Pass |

The entry gate passed.

# 2. Owner decisions

## Schedule adjudication

The independent review argued that the complete first-month target could take longer than one month.

The owner rejects that estimate as a reason to reduce the accepted product or architecture.

Accepted owner decision:

- the first-month target remains aggressive;
- estimate uncertainty is accepted;
- schedule pessimism alone cannot remove durability, safety, recovery, Evidence, CLI, packaging, or delivery requirements;
- work remains divided into bounded tickets and exact gates;
- a missed schedule causes replanning;
- timing pressure cannot silently weaken accepted behavior;
- no feature is removed solely because an external reviewer predicts a longer schedule.

This pass does not re-litigate the estimate.

## Provider and host

- OD-01 remains MiniMax only, sealed Context disclosure only, deterministic fake for tests, and no fallback.
- ADR-0023 remains MiniMax M3 through the selected OpenAI-compatible endpoint, subject to exact live implementation acceptance tests.
- OD-02 remains Apple Silicon macOS 15.0 or later, local APFS, one interactive local user, and the owner's M1 Pro Mac as the primary validation host.

# 3. Prompt 7-A findings adjudicated

## Accepted findings

### A-01 — Prompt 6-A closeout was stale

**Decision:** Accept.

**Reason:** The integrated work record still claimed incomplete and unverified work despite exact-head green CI and merge.

**Correction:** `docs/work/P0-W28-wave-a-conformance.md` now records:

- complete, verified, accepted, and integrated status;
- final head;
- merge commit;
- CI run;
- each acceptance result;
- compare scope;
- conformance-only boundary;
- no build authorization.

### A-02 — Actual Draft 2020-12 Schema validation was missing

**Decision:** Accept.

**Reason:** The existing Python script protected important semantic relationships but was not a complete JSON Schema implementation.

**Correction:**

- retain `scripts/validate_first_month_contracts.py` as semantic validation;
- pin `jsonschema==4.26.0` in `requirements/conformance.txt`;
- add `scripts/validate_json_schema_contracts.py` using `Draft202012Validator`;
- validate Schema shape and every positive fixture;
- make every negative fixture declare Schema and semantic disposition;
- reject remote `$ref` values;
- run both validators locally and in CI;
- keep the Python package outside Elixir product dependencies.

Schema validation and semantic validation remain distinct.

### A-03 — Active authority documents contradicted the focused specifications

**Decision:** Accept.

**Reason:** Active summaries still included `created`, `waiting_for_command`, and `verifying` Run states and placed Receipt sealing before durable completion.

**Correction:**

- `docs/ARCHITECTURE.md`, `docs/RUN-MODEL.md`, and `docs/SESSION-MODEL.md` now summarize the focused authorities rather than duplicate conflicting rules;
- Run status is the exact P0-W21 seven-state set;
- workflow, decision, operation, and Evidence state remain separate;
- user acceptance and P0-W21 atomic completion precede product Receipt sealing;
- Child and Wave B behavior is not active first-month scope;
- managed worktrees, generalized brokerage, TUI-first assumptions, shell execution, fallback, and exit-zero proof are absent from active scope;
- `docs/PLANNING.md` and this document control integration status for focused specifications whose branch-era headers remain embedded in long documents.

The detailed focused specifications remain authoritative. Their old branch-era `proposed` metadata is superseded by the integrated work records, ADR index, planning index, and this adjudication. The old metadata must not be copied into new work.

### A-04 — P1-S01 misused product Receipt terminology

**Decision:** Accept.

**Reason:** A product Receipt cannot exist before user-accepted product completion.

**Correction:**

- P1-S01 uses ticket closeout records and `P1-S01-V01`, a slice verification manifest;
- P1-S01 no longer includes a product Receipt responsibility or process;
- `docs/IMPLEMENTATION-SLICES.md`, `docs/SLICE-ACCEPTANCE-GATES.md`, `docs/templates/IMPLEMENTATION-PLAN.md`, and `docs/BRANCHING-AND-WORK-PLANNING.md` use the corrected terminology;
- P1-S02 retains the first product Receipt, sealed only after P0-W21 atomic completion.

### A-05 — MiniMax M3 documentation is current

**Decision:** Accept.

**Reason:** MiniMax's official model introduction identifies `MiniMax-M3` as the current frontier coding model.

**Correction:** ADR-0023 now:

- removes the stale claim that official model documentation still identifies M2.7 as newest;
- retains M3, the OpenAI-compatible endpoint, no fallback, and deterministic fake;
- requires later live Evidence for authentication, non-streaming, streaming, Tool calls, Tool-result continuation, usage, reasoning separation, output limits, service tier, timeout, malformed results, connection loss, and no fallback.

The live tests are acceptance gates, not reasons to reopen the owner model decision.

## Rejected or narrowed findings

### R-01 — Replace the durable journal with mutable current-state tables

**Decision:** Reject.

P0-W21's append-oriented journal, revisions, idempotency, deterministic replay, rebuildable projections, migrations, corruption checks, restart reconstruction, orphan classification, and no-repeat rule remain accepted.

Ticket sequencing is narrowed, but durability is not weakened.

### R-02 — Reduce the accepted Patch contract to one file

**Decision:** Reject as an architecture change; narrow implementation sequencing only.

The accepted Patch remains multi-path complete-text `add`, `replace`, and `delete` within P0-W23 limits. Later implementation may begin with one-file fixtures, but it cannot replace the contract with fuzzy diffs, `git apply`, shell mutation, unrestricted editing, or model-owned mutation.

Patch implementation is not authorized in P1-S01.

### R-03 — Remove the macOS Command helper

**Decision:** Reject.

ADR-0026 remains accepted. Later implementation must prove process-group creation, TERM/KILL escalation, wait, and group absence on the supported host.

A failed experiment returns `blocked`, `degraded`, `unsupported`, or `unknown`. It cannot become a silent cleanup claim.

The helper is not authorized in P1-S01.

### R-04 — Remove packaging from the accepted product

**Decision:** Reject.

The arm64 macOS Mix-release decision remains accepted. Packaging is not the first ticket and is not authorized in P1-S01. It must pass before the Single-Run Alpha is locally deliverable.

### R-05 — Remove the accepted CLI contract

**Decision:** Reject; narrow initial implementation.

The complete CLI contract remains the product target. P1-S01 authorizes only the minimum commands backed by implemented foundation operations.

Future commands remain absent or explicitly unsupported. They cannot return fake success.

### R-06 — Remove product Receipts

**Decision:** Reject.

The post-completion product Receipt remains accepted. Only pre-completion implementation records were renamed.

### R-07 — Remove Prompt 6-A conformance because runtime is absent

**Decision:** Reject with targeted revisions.

Conformance remains useful when it protects accepted enums, limits, behavior seams, negative cases, and deferred scope.

Misleading or unnecessarily locking scaffolds are revised or removed as recorded below.

# 4. Prompt 6-A scaffold disposition

| Scaffold | Decision | Action |
| --- | --- | --- |
| `Kiln.Conformance.FirstMonth` | Revise and retain | keep protected constants and transitions; remove `scaffold_status/0`; clarify non-product authority |
| `Kiln.Conformance.Provider` | Retain temporarily | broad `map()` callbacks remain planning seams only; later provider ticket must replace them with accepted typed requests and results |
| `Kiln.Conformance.CommandHost` | Retain temporarily | later Command ticket must define typed host-helper protocol records before implementation |
| constant and transition tests | Retain | protect W21 through W25 decisions |
| absent-runtime-module test | Remove | listing future module names created namespace lock-in and would block authorized implementation |
| first-month Schema | Revise and retain | add actual Draft 2020-12 validation and keep bounded scope |
| positive fixtures | Retain | required by both validators |
| protected negative fixtures | Revise and retain | declare Schema and semantic disposition |
| semantic validator | Retain | protects cross-field invariants |
| preflight | Retain | current P0 and P1 grammar is required |
| CI and `scripts/check` | Revise and retain | install pinned validator and run both validation paths |

No scaffold performs a product effect or grants authority.

# 5. Active authority reconciliation

## Focused authority order

1. P0-W21: Root lifecycle, journal, revision, migration, restart, orphan, completion transaction.
2. P0-W22: MiniMax M3, Context, Tools, Repository reads, disclosure, secrets.
3. P0-W23: complete-text Patch, Approval, mutation, rollback, uncertain effect.
4. P0-W24: registered Command, Artifacts, criterion Evidence, acceptance, completion input, post-completion Receipt.
5. P0-W25: complete CLI and arm64 macOS local delivery contract.

## Status authority

P0-W21 through P0-W25 are accepted and integrated through PRs 27 through 33.

Any branch-era metadata inside their large focused specification files that says `proposed`, names the old branch, or says `owner acceptance required` is stale status text. This document, `docs/PLANNING.md`, the ADR index, and the integrated work records control status.

The detailed decisions inside those specifications remain active unless this adjudication explicitly changes them.

## Historical documents

Earlier architecture, Capability, Context, worktree, delegation, TUI, knowledge, protocol, telemetry, and broad Schema documents remain historical or deferred inputs.

They cannot:

- add Run states;
- authorize Child Runs;
- require managed worktrees;
- create a general Capability broker;
- make TUI an initial prerequisite;
- allow fallback or unrestricted shell;
- convert exit zero or model confidence into Evidence;
- move Receipt sealing before completion;
- authorize implementation.

# 6. Final authorization decision

## Level

> **Vertical Slice Authorized**

This means development may begin after the Prompt 8-A pull request merges at an exact green head.

It does not authorize every accepted subsystem or the complete Single-Run Alpha at once.

## Exact authorized slice

Only P1-S01 — Durable single-Run foundation.

## Exact authorized tickets

| Order | Ticket | Branch |
| --- | --- | --- |
| 1 | P1-S01-T01 — durable domain foundation | `work/p1-s01-t01-domain-foundation` |
| 2 | P1-S01-T02 — durable store | `work/p1-s01-t02-durable-store` |
| 3 | P1-S01-T03 — replay and projections | `work/p1-s01-t03-replay-projections` |
| 4 | P1-S01-T04 — foundation CLI | `work/p1-s01-t04-foundation-cli` |
| 5 | P1-S01-T05 — aggregate gate and slice verification manifest | `work/p1-s01-t05-slice-gate` |

The accepted plans are in `docs/work/`.

## Dependency order

The tickets run sequentially. A later ticket begins only after the previous ticket:

- merges to `main`;
- passes exact-head CI;
- completes its plan record;
- satisfies its deterministic acceptance criteria;
- preserves all exclusions;
- receives owner integration approval.

Parallel implementation of these tickets is not authorized.

# 7. Permitted implementation and effects

## P1-S01-T01

Permitted:

- pure identifiers, structs, enums, constructors, actions, transitions, and errors;
- deterministic unit tests.

External effects: none.

## P1-S01-T02

Permitted:

- pinned Exqlite runtime dependency meeting the accepted SQLite baseline;
- one local SQLite state database under `$KILN_HOME`;
- forward migrations, integrity checks, WAL, `synchronous=FULL`, foreign keys, busy timeout, immediate transactions;
- atomic journal, revision, and idempotency writes;
- owner-machine store diagnostics.

Forbidden:

- nested first-month transactions;
- network, source read or mutation, shell, or provider effects.

## P1-S01-T03

Permitted:

- journal reads;
- deterministic replay and projection rebuild;
- safe projection replacement after complete validation;
- restart reconstruction and corruption blocking.

Forbidden:

- external-effect dispatch or automatic retry;
- destructive journal repair.

## P1-S01-T04

Permitted:

- source-development `mix kiln` entry point;
- P1-S01 start, status, inspect, accepted cancel, and resume guidance;
- text and structured output over implemented application operations.

Forbidden:

- packaged release claim;
- unsupported commands returning success;
- direct store access from renderers;
- future subsystem commands.

## P1-S01-T05

Permitted:

- deterministic aggregate gate;
- isolated restart demo;
- owner-machine diagnostics;
- slice verification manifest;
- CI wiring for the P1-S01 gate.

The aggregate script is development verification, not a product Command or Tool.

# 8. Work still prohibited

Prompt 8-A does not authorize:

- real MiniMax calls;
- deterministic fake-provider execution;
- Repository source read, search, or disclosure;
- Context package construction;
- model-facing Tools;
- source mutation;
- Patch proposal, Approval, application, or rollback;
- external registered Command execution;
- native macOS process helper execution;
- criterion completion Evidence;
- aggregate completion evaluation;
- user completion acceptance;
- product Receipt sealing;
- arm64 Mix-release packaging or installation;
- Child Runs;
- Scout;
- Verifier Child;
- Attention;
- TUI;
- managed worktrees in the product;
- protocols;
- telemetry;
- remote execution;
- P0-W26 or P0-W27;
- any Wave B implementation;
- broad build authorization.

P1-S02 is planned but not authorized.

# 9. Required deterministic and owner-machine Evidence

## Every ticket

- exact branch and head;
- exact compare with current `main`;
- completed implementation plan;
- all required tests;
- semantic and Draft 2020-12 conformance validation;
- format, warnings-as-errors compilation, cycle check, and ExUnit;
- no unauthorized file or effect;
- exact-head CI;
- projected merged-state review when relevant.

## Store tickets and slice closeout

Owner-machine Evidence must record:

- Apple Silicon architecture;
- exact macOS version and build;
- local APFS for authoritative state and fixture Repository;
- Erlang, Elixir, Exqlite, and SQLite versions;
- SQLite 3.51.3 or newer;
- effective WAL and `synchronous=FULL`;
- immediate one-writer transaction behavior;
- no nested first-month transaction dependency;
- migration, restart, corruption, and unsupported-version behavior;
- unsupported or degraded controls honestly.

# 10. Merge, rollback, and pause rules

## Merge gates

A ticket cannot merge when:

- any required criterion is pending, failed, blocked, unknown, stale, or contradicted;
- exact-head CI is missing or not green;
- owner-machine Evidence is required but missing;
- the plan record is incomplete;
- the branch contains unauthorized scope;
- projected merged state was not checked when needed;
- a later subsystem becomes reachable;
- warnings or unknowns are hidden.

## Rollback conditions

Before release, rollback normally means revert the ticket merge or restore the prior compatible source state.

For store changes:

- never downgrade or overwrite an incompatible migrated store automatically;
- preserve the database and diagnostic Evidence;
- block use by an older binary when store compatibility is unknown;
- use test backups only for fixture recovery;
- return to planning when migration rollback would be required.

## Pause and return to planning

Pause development when:

- an authorized ticket needs a prohibited external effect;
- a focused authority conflict appears;
- Exqlite cannot meet the accepted SQLite baseline;
- implementation requires nested first-month transactions;
- integrity, migration, revision, idempotency, replay, projection, or restart behavior cannot be proved;
- a deterministic fixture cannot reproduce the claimed result;
- the minimal CLI requires an unreviewed runtime dependency or packaged-delivery decision;
- runtime behavior would need a new state or authority rule;
- P1-S02, Child, TUI, worktree, protocol, telemetry, or remote behavior begins to enter;
- timing pressure is used to weaken an accepted gate.

# 11. Wave B gate

Wave B remains blocked.

P0-W26 and P0-W27 begin only after an authorized Single-Run Alpha produces accepted runtime Evidence showing:

- one real source change;
- durable restart;
- controlled Patch authority;
- registered verification;
- criterion-bound Evidence;
- a valid post-completion Receipt;
- observed failure or interruption behavior.

Then Wave B still requires Prompt 6-B, Prompt 7-B, and Prompt 8-B before delegated implementation.

# 12. Unresolved unknowns

- Exact Exqlite release and owner-machine behavior remain P1-S01-T02 Evidence.
- Exact MiniMax M3 protocol compatibility remains later P1-S02 Evidence.
- Exact macOS process-group helper behavior remains later Command-ticket Evidence.
- The P1-S02 ticket split can be revisited after P1-S01 runtime Evidence, without changing the accepted final product.
- The aggressive first-month target remains uncertain but accepted.

# 13. Exact next action

After this Prompt 8-A pull request is inspected, exact-head green, and merged:

```text
create branch work/p1-s01-t01-domain-foundation
follow docs/work/P1-S01-T01-domain-foundation.md
```

Do not begin T02 before T01 merges and is accepted.

Do not begin P1-S02, P0-W26, P0-W27, or Wave B work.
