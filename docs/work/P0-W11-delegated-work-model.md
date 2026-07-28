# P0-W11: Delegated work model

- **Status:** Implemented; verification pending
- **Branch:** `work/p0-w11-delegated-work-model`
- **Depends on:** P0-W04 through P0-W10
- **Scope:** Planning and contracts only

## Objective

Define how Kiln creates, displays, controls, verifies, interrupts, recovers, and records delegated work.

The work must make delegation useful without optimizing for Agent count or creating hidden work.

## Observed current state

- ADR 0004 requires first-class Runs for delegated work.
- ADR 0007 makes Run the primary durable execution unit.
- `docs/RUN-MODEL.md` defines Root, Parent, Child, foreground, background, Context, authority, and initial limits.
- `docs/PROJECT-STEWARDSHIP.md` defines bounded delegation and Project Steward responsibility.
- P0-W08 requires independent Child and Verifier Context.
- P0-W10 requires Git isolation and prevents Verifiers from repairing evaluated work.
- The existing Run state list does not include `waiting_for_command`.
- The existing Attention contract does not include verification blockers, merge blockers, Resource limits, stale Evidence, or the complete user action set.
- Scout and Verifier descriptions do not yet provide machine-readable role-result contracts.
- Cancellation, timeout, result delivery, and crash behavior require more precise rules.

## Protected invariants

This work preserves:

- `KILN-INV-001`;
- `KILN-INV-004` through `KILN-INV-009`;
- `KILN-INV-013` through `KILN-INV-022`;
- `KILN-INV-024` through `KILN-INV-034`;
- `KILN-INV-045` through `KILN-INV-056`;
- ADRs 0004, 0005, 0007, 0010, and 0013.

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

- Add `docs/DELEGATED-WORK.md`.
- Add `docs/contracts/kiln-delegation.schema.json`.
- Add ADR 0014.
- Update `docs/RUN-MODEL.md` with the authoritative delegation specification and missing state.
- Update `docs/PROJECT-STEWARDSHIP.md` to make Scout and Verifier the only initial Child roles.
- Update core and execution schemas where the existing contracts conflict with P0-W11.
- Update Project invariants, README, roadmap, ADR index, and contract index.

## Acceptance criteria

The normative criteria are `P0-W11-AC01` through `P0-W11-AC25` in `docs/DELEGATED-WORK.md`.

Additional work-package criteria are:

- **P0-W11-AC26:** The diff contains documentation and JSON contracts only.
- **P0-W11-AC27:** Repository CI passes on the final branch head.
- **P0-W11-AC28:** The delegation schema passes Draft 2020-12 meta-schema validation.
- **P0-W11-AC29:** Representative positive and negative delegation documents validate as expected.
- **P0-W11-AC30:** Existing Git isolation, Context, authority, Evidence, and recovery decisions remain intact.

## Verification

Repository checks:

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Contract checks:

```bash
python -m json.tool docs/contracts/kiln-delegation.schema.json
```

A Draft 2020-12 validator must validate representative documents for:

- delegation contract;
- Scout result;
- Verifier `PASS`, `FAIL`, and `BLOCKED` results;
- Run transition;
- Attention event;
- cancellation record;
- timeout policy;
- Child result delivery.

Negative cases must reject:

- depth greater than two;
- a Scout with Verifier permissions;
- a Verifier `PASS` without reproduced Evidence;
- a blocking Attention event without escalation;
- a user or permission wait transition without Attention and resume state;
- peer communication or shared mutable Context enabled;
- a Child role with `max_child_runs` greater than zero.

## Evidence

- **P0-W11-E01:** Delegated-work specification covers every required output.
- **P0-W11-E02:** Delegation schema parses and validates.
- **P0-W11-E03:** ADR 0014 records accepted and rejected positions.
- **P0-W11-E04:** Run, Steward, roadmap, README, invariant, ADR, and contract authorities link to the specification.
- **P0-W11-E05:** Diff contains planning and contracts only.
- **P0-W11-E06:** Repository CI passes on the final branch head.

## Exclusions

This work does not implement:

- Run processes;
- Worker leases;
- scheduling;
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
