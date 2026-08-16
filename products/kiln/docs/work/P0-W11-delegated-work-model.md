# P0-W11: Delegated work model

- **Status:** Implemented and verified; review pending
- **Branch:** `work/p0-w11-delegated-work-model`
- **Depends on:** P0-W04 through P0-W10
- **Scope:** Planning and contracts only

## Objective

Define how Kiln creates, displays, controls, verifies, interrupts, recovers, and records delegated work.

The work makes delegation useful without optimizing for Agent count or creating hidden work.

## Observed starting state

- ADR 0004 required first-class Runs for delegated work.
- ADR 0007 made Run the primary durable execution unit.
- `docs/RUN-MODEL.md` defined Root, Parent, Child, foreground, background, Context, authority, and initial limits.
- `docs/PROJECT-STEWARDSHIP.md` defined bounded delegation and Project Steward responsibility.
- P0-W08 required independent Child and Verifier Context.
- P0-W10 required Git isolation and prevented Verifiers from repairing evaluated work.
- The Run state list omitted `waiting_for_command`.
- Attention did not include verification blockers, merge blockers, Resource limits, stale Evidence, or the complete user action set.
- Scout and Verifier did not have machine-readable result contracts.
- Cancellation, timeout, result delivery, crash, and orphan behavior needed precise rules.

## Protected invariants

This work preserves:

- `KILN-INV-001`;
- `KILN-INV-004` through `KILN-INV-009`;
- `KILN-INV-013` through `KILN-INV-022`;
- `KILN-INV-024` through `KILN-INV-034`;
- `KILN-INV-045` through `KILN-INV-056`;
- ADRs 0004, 0005, 0007, 0010, and 0013.

ADR 0014 and `docs/DELEGATED-WORK.md` add detailed delegated-work constraints without reversing these invariants.

## Requirements

- **P0-W11-R01:** Every delegated Task creates a first-class Child Run before delegated execution.
- **P0-W11-R02:** Define Root, Parent, Child, sibling, nested, foreground, and background Run behavior.
- **P0-W11-R03:** Define independent Context, grants, Artifacts, accounting, cancellation, and durable history.
- **P0-W11-R04:** Define Scout and Verifier role contracts.
- **P0-W11-R05:** Define the complete Run state machine, including `waiting_for_command`.
- **P0-W11-R06:** Define global depth-independent Attention and user actions.
- **P0-W11-R07:** Define cancellation and timeout policy.
- **P0-W11-R08:** Define Parent crash, Child crash, orphan, and recovery behavior.
- **P0-W11-R09:** Define structured Parent result delivery and idempotency.
- **P0-W11-R10:** Define durable and transient persistence boundaries.
- **P0-W11-R11:** Keep logical Run lineage separate from OTP supervision.
- **P0-W11-R12:** Keep additional repeated procedures in Skills unless a role contract is justified.
- **P0-W11-R13:** Preserve conservative initial limits.
- **P0-W11-R14:** Add and validate `kiln.delegation/v0` contracts.
- **P0-W11-R15:** Do not implement production runtime code.

## Changes

- Added `docs/DELEGATED-WORK.md`.
- Added `docs/contracts/kiln-delegation.schema.json`.
- Added ADR 0014.
- Reconciled `docs/RUN-MODEL.md` with the complete state list and initial delegated roles.
- Reconciled `docs/PROJECT-STEWARDSHIP.md` with Scout and Verifier as the only initial Child role contracts.
- Updated README, roadmap, ADR index, and contract index.
- Recorded `kiln.delegation/v0` as the detailed v0 authority for delegated transitions and Attention.
- Deferred consolidation of the generic `kiln.domain/v0` Run status and `kiln.domain/v0` Attention snapshot schemas to the Phase 1 contract work package. Runtime implementation must not use the older generic subsets as complete delegated-work validators before that consolidation.

## Acceptance criteria

The normative criteria are `P0-W11-AC01` through `P0-W11-AC25` in `docs/DELEGATED-WORK.md`.

Additional work-package criteria:

- **P0-W11-AC26:** Pass. The diff contains documentation and JSON contracts only.
- **P0-W11-AC27:** Pass. GitHub CI run `30391491391` passed on the design head.
- **P0-W11-AC28:** Pass. The delegation schema passed Draft 2020-12 meta-schema validation.
- **P0-W11-AC29:** Pass. Ten positive documents validated and seven protected negative cases were rejected.
- **P0-W11-AC30:** Pass. Git isolation, Context, authority, Evidence, and recovery decisions remain intact.

## Verification Evidence

### Repository CI

GitHub CI run `30391491391` passed:

- Vale prose checks;
- agent preflight behavior;
- Project agent-asset validation;
- dependency installation;
- Elixir formatting;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit tests.

### Contract validation

The schema passed:

- JSON parsing;
- Draft 2020-12 meta-schema validation;
- representative positive validation for delegation contract, Scout result, Verifier `PASS`, Verifier `FAIL`, Verifier `BLOCKED`, Run transition, Attention event, cancellation record, timeout policy, and Child result delivery.

The schema rejected:

- depth greater than two;
- Scout with Verifier permissions;
- peer communication enabled;
- shared mutable Context enabled;
- Child delegation allowance greater than zero;
- Verifier `PASS` without reproduced Evidence;
- user or permission wait with null or missing Attention and resume state;
- blocking Attention with null or missing escalation.

## Evidence register

- **P0-W11-E01:** `docs/DELEGATED-WORK.md` covers all requested outputs and acceptance criteria.
- **P0-W11-E02:** `docs/contracts/kiln-delegation.schema.json` parses and validates.
- **P0-W11-E03:** ADR 0014 records accepted and rejected positions.
- **P0-W11-E04:** Run, Steward, roadmap, README, ADR, and contract authorities link to the specification.
- **P0-W11-E05:** The branch comparison contains planning and contracts only.
- **P0-W11-E06:** GitHub CI run `30391491391` passed.

## Exclusions

This work does not implement:

- Run processes or scheduling;
- Worker leases;
- model-backed Child Runs;
- Scout or Verifier runtime code;
- Attention routing;
- cancellation signaling;
- Command supervision;
- SQLite migrations;
- CLI or TUI views;
- writing Child roles;
- remote delegation;
- A2A;
- peer communication;
- shared mutable Context;
- deeper or wider delegation limits.

## Completion statement

Implemented and verified as a planning-and-contract package. Review and owner acceptance remain before integration.
