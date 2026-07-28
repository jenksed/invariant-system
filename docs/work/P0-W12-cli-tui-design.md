# P0-W12: Initial CLI and TUI design

- **Status:** Implemented; verification pending
- **Branch:** `work/p0-w12-cli-tui-design`
- **Depends on:** P0-W04 through P0-W11
- **Scope:** Planning and contracts only

## Objective

Define the smallest CLI and terminal user interface that lets one developer understand, navigate, control, inspect, and recover a small graph of concurrent Runs without losing conversational flow.

## Source prompt

`Pasted markdown(9).md`, Prompt 7 — Design the Initial CLI and TUI.

## Observed current state

- Run is the primary durable execution unit.
- Every delegated Task creates a Child Run.
- Focus is client-local and Attention is global.
- The accepted domain already exposes CLI and TUI as projections through the domain API.
- Phase 1 requires a basic CLI projection but does not yet define the complete terminal interaction.
- No accepted ExRatatui dependency or renderer boundary exists.
- No public interface event, snapshot, Client-state, input-intent, or CLI-result contract exists.
- The first interface must not require a live model.

## Protected invariants

This work preserves:

- `KILN-INV-001`;
- `KILN-INV-004` through `KILN-INV-010`;
- `KILN-INV-013` through `KILN-INV-022`;
- `KILN-INV-023` through `KILN-INV-034`;
- `KILN-INV-040` through `KILN-INV-056`;
- ADRs 0002, 0004, 0005, 0007, 0009, 0010, 0013, and 0014.

## Requirements

- **P0-W12-R01:** Define a Run-first, conversation-first terminal product.
- **P0-W12-R02:** Define concrete start, delegation, Attention, change, Verifier, recovery, and narrow-terminal journeys.
- **P0-W12-R03:** Define information, screen, navigation, focus, and multi-client hierarchies.
- **P0-W12-R04:** Define a complete CLI surface with text, JSON, JSONL, exit codes, safety, and idempotency.
- **P0-W12-R05:** Define keyboard, mouse, and composer behavior.
- **P0-W12-R06:** Provide main, Child-card, Run-tree, and Attention wireframes.
- **P0-W12-R07:** Define Command, Tool, Git, Evidence, Receipt, completion, failure, and recovery presentation.
- **P0-W12-R08:** Define event ordering, duplicate handling, replay, snapshots, cursors, backpressure, and stale detection.
- **P0-W12-R09:** Set initial responsiveness, memory, accessibility, and narrow-terminal targets.
- **P0-W12-R10:** Evaluate and decide ExRatatui for the first vertical prototype.
- **P0-W12-R11:** Map the design to Elixir and OTP without process-per-widget architecture.
- **P0-W12-R12:** Define pure, headless, snapshot, property, state-machine, and integration tests.
- **P0-W12-R13:** Define the deterministic first vertical prototype.
- **P0-W12-R14:** Add and validate `kiln.interface/v0`.
- **P0-W12-R15:** Update later planning without moving production model integration earlier.
- **P0-W12-R16:** Do not add production runtime code or dependencies.

## Changes

- Add `docs/CLI-TUI.md`.
- Add `docs/contracts/kiln-interface.schema.json`.
- Add ADR 0015.
- Update README, roadmap, ADR index, and contract index.
- Record P0-W12 and the Phase 1 interface proof boundary.

## Acceptance criteria

The normative criteria are `P0-W12-AC01` through `P0-W12-AC30` in `docs/CLI-TUI.md`.

Additional work-package criteria:

- **P0-W12-AC31:** The interface schema parses as JSON.
- **P0-W12-AC32:** Draft 2020-12 meta-schema validation passes.
- **P0-W12-AC33:** Representative interface event, snapshot, Client state, input intent, and CLI result documents validate.
- **P0-W12-AC34:** The diff contains documentation and JSON contracts only.
- **P0-W12-AC35:** Repository CI passes on the final branch head.
- **P0-W12-AC36:** ExRatatui is selected only behind a renderer boundary and no dependency is added.
- **P0-W12-AC37:** Existing domain, delegation, Attention, Git, Capability, Context, Evidence, and recovery decisions remain intact.

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
python -m json.tool docs/contracts/kiln-interface.schema.json
```

A Draft 2020-12 validator must validate:

- interface event;
- projection snapshot;
- Client-local state;
- normalized input intent;
- successful CLI result;
- error CLI result.

Negative cases must reject:

- sequence zero for a durable event;
- unknown event type;
- invalid Run state;
- a successful CLI result with a non-zero exit code;
- an error CLI result without an error object;
- invalid layout mode;
- a Client state without a focused Run;
- an unsupported permission action.

## Evidence

- **P0-W12-E01:** CLI/TUI specification covers every required output.
- **P0-W12-E02:** Interface schema parses and validates.
- **P0-W12-E03:** ADR 0015 records accepted and rejected interface positions.
- **P0-W12-E04:** README, roadmap, ADR index, and contract index link to the specification.
- **P0-W12-E05:** ExRatatui evaluation uses current package and primary project documentation.
- **P0-W12-E06:** Diff contains planning and contracts only.
- **P0-W12-E07:** Repository CI passes on the final branch head.

## Exclusions

This work does not implement:

- CLI modules;
- ExRatatui dependency;
- TUI renderer;
- local runtime endpoint;
- projection service;
- event bus;
- Client processes;
- SQLite migrations;
- simulated fixture runtime;
- model provider;
- Scout or Verifier runtime;
- real Git mutation;
- Phoenix;
- ACP;
- AG-UI;
- SSH transport;
- web or remote Clients.
