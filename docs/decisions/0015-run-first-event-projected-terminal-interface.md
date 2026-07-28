# ADR 0015: Use a Run-first event-projected terminal interface

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W12
- **Date:** 2026-07-28

## Context

Kiln needs a first user-facing interface that makes durable Runs, delegated work, Attention, Commands, changes, Evidence, and recovery understandable without turning the product into an Agent dashboard.

The interface must preserve the accepted internal domain. It cannot make widget state authoritative, copy Child transcripts into Parent Runs, use navigation as execution control, or let renderer failure terminate active work.

The CLI must remain complete and automation-friendly. The TUI must remain conversation-first and keyboard-complete.

P0-W12 must also choose whether ExRatatui can support the first deterministic vertical prototype.

## Decision

Kiln's initial user-facing interface is:

1. a complete cursor-control-independent CLI; and
2. a conversation-first full-screen TUI.

The Run graph is the primary navigation model for delegated work.

The main TUI screen centers the current Run transcript and composer. The Run tree, Attention inbox, Commands, changes, Artifacts, Evidence, Receipts, Context, and permissions use progressive disclosure.

The interface renders rebuildable projections from Kiln domain queries, durable events, snapshots, and replay. Widget state never owns Run, Attention, permission, Git, Evidence, or completion truth.

Client-local state includes focus, selection, navigation history, scroll, panel layout, collapsed nodes, preferences, and unsaved drafts.

Shared durable state includes Run execution, Attention, permissions, transcripts, events, Artifacts, Evidence, Receipts, Git ownership, and integration state.

Navigation is safe:

- `Alt+Left` always enters the logical Parent Run;
- `Alt+Home` always enters the Root Run;
- entering or leaving a Run never pauses, cancels, approves, merges, writes, or transfers ownership;
- starting or completing a Child never changes focus automatically.

Permission and destructive decisions require action-specific confirmation. Generic `Enter` opens details or activates non-destructive navigation. It never approves permission, integration, or cancellation.

The CLI exposes human text, versioned JSON, and JSON Lines event output without exposing internal persistence schemas.

ExRatatui 0.11.x is selected for the first vertical prototype behind a Kiln-owned renderer behaviour. The implementation must pin the accepted version, complete dependency and NIF review, and keep ExRatatui types outside domain contracts and modules.

The first prototype uses deterministic events and simulated Runs. It proves navigation, global Attention, inspection, pause, resume, cancellation, resize, renderer crash isolation, and durable projection recovery before production model integration.

The detailed design is in `docs/CLI-TUI.md`. Public interface contracts are in `docs/contracts/kiln-interface.schema.json`.

## Consequences

- The CLI remains usable without a full-screen terminal.
- The TUI can be replaced without changing domain or public interface semantics.
- Closing or crashing one Client does not imply Run failure.
- Multiple Clients can hold independent focus while sharing durable state.
- Projection sequence and revision checks make stale Clients visible.
- High-volume output must be coalesced, paged, or stored as Artifacts.
- Phase 1 must implement projection reducers and deterministic interface fixtures before a live provider loop.
- A local runtime endpoint is required so active work can survive Client disconnect.
- Phoenix, ACP, AG-UI, and remote Clients remain later projections of the same domain state.
- Terminal accessibility claims remain limited until tested.

## Rejected positions

- Agent-first navigation.
- A permanent monitoring dashboard as the default screen.
- A pane for every Child Run.
- Automatic focus changes when Children start or finish.
- Copying full Child transcripts into Parent Runs.
- Renderer-owned durable state.
- One GenServer per widget or screen region.
- Mirroring the Run graph or screen tree in OTP supervision.
- Keypress handlers that mutate domain state without commands and validation.
- Generic `Enter` approval.
- Color-only status.
- Generic `done`, `success`, or `complete` labels.
- Unbounded logs, model output, or Artifacts in active TUI memory.
- Adding Phoenix only to obtain PubSub.
- Broad framework comparison after ExRatatui satisfies the first-prototype requirements.

## Review triggers

Review this decision when:

- ExRatatui cannot pass the accepted headless navigation, resize, paste, or crash-isolation tests;
- the NIF boundary cannot meet supported platform or supply-chain requirements;
- the local runtime endpoint cannot preserve active work across Client disconnect;
- dogfooding shows the conversation-first screen hides material work;
- keyboard mappings fail on supported terminals;
- accessibility testing requires a different primary terminal mode;
- event replay or projection performance misses accepted targets under realistic history;
- ACP or a web Client requires a native projection change rather than an adapter.
