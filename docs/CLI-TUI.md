# Initial CLI and TUI

**Document type:** Product and interface specification  
**Decision status:** Owner-directed planning pass  
**Integration status:** Proposed on P0-W12  
**Implementation status:** Not implemented  
**Interface contract:** `kiln.interface/v0`

## Purpose

This specification defines Kiln's first user-facing command-line interface and terminal user interface.

The interface must let one developer start and continue work, understand the current Run, observe delegated work, enter and leave Child Runs, respond to blocked work, inspect Commands, changes, Evidence, and Receipts, pause or cancel work, and recover after interruption.

The interface does not redesign the domain from the screen outward. It renders and controls the accepted Kiln domain through commands, queries, durable events, and rebuildable projections.

## Product position

The Run graph is Kiln's primary navigation model for delegated work.

It is not a secondary jobs panel.

The interface remains conversation-first:

```text
Work in the current Run
→ observe a delegated Child
→ enter the Child
→ inspect or steer its work
→ inspect its Evidence
→ return to the Parent
→ continue the original Task
```

Kiln optimizes the interface for moving work through:

```text
Intent
→ Investigation
→ Implementation
→ Verification
→ Completion
```

Kiln does not optimize the interface for the largest possible number of Agents, logs, panes, metrics, or permanent dashboards.

## Accepted positions

1. The primary navigable object is a Run.
2. Agent role, model, and Skill are Run properties, not primary navigation.
3. The current Run transcript and input composer remain central.
4. Interface state is projected from Kiln domain state and durable events.
5. TUI widget state is never authoritative for Runs, Attention, permissions, Git ownership, Evidence, or completion.
6. Closing or crashing a renderer cannot cancel or fail a Run.
7. The user always has one predictable Parent action and one predictable Root action.
8. Navigation never implies pause, cancel, approval, merge, write ownership, or permission change.
9. Every essential action is keyboard-complete.
10. Status uses text and symbols. Color is only reinforcement.
11. Full transcripts, logs, Artifacts, diffs, and Receipts remain available on demand.
12. The Parent projection receives bounded Child summaries and references, not copied Child transcripts.
13. Focus, selection, history, scroll, layout, and drafts are client-local.
14. Run execution, Attention, permissions, approvals, transcripts, events, Artifacts, Evidence, and Receipts are shared durable state.
15. The first useful interface targets one Root Run and at most three active Child Runs.
16. ExRatatui is the selected prototype TUI framework behind a Kiln-owned renderer boundary.
17. The CLI is a complete interface. It is not only a TUI launcher.
18. The first vertical prototype uses simulated Runs and deterministic events. It does not require a model.

## Preserved domain boundaries

The interface preserves these accepted distinctions:

| Distinction | Interface rule |
| --- | --- |
| Run state and interface focus | A Run can continue while no Client focuses it. Focus changes do not change Run state. |
| Shared Run state and client navigation | Run state is shared and durable. Focus, selection, back history, scroll, layout, and drafts are client-local. |
| Current Run and selected Run | The current Run receives composer input. A selected Run is highlighted for preview or action. Selection does not retarget input. |
| Active Run and foreground Run | Active means executing or waiting. Foreground is a Client presentation mode. |
| Run status and Command status | Both labels remain visible when a Run waits on a Command. |
| Child summary and Child transcript | Parent views use bounded cards. The full transcript stays in the Child view. |
| Attention and notification | Attention requires a response or control decision. Notifications are informational and do not block work. |
| Permission request and question | Permission uses an explicit security-sensitive decision surface. A question uses a response composer. |
| Evidence and activity | Activity shows what happened. Evidence records an immutable observation with method and state binding. |
| Receipt and Evidence | A Receipt references Evidence and outcomes. It does not make Evidence current. |
| Artifact and transcript | An Artifact is immutable content or a durable reference. Transcript text is a conversational projection. |
| Proposed, applied, verified, integrated | Each is a distinct label and state. No generic `done` label replaces them. |
| Branch state and Run state | Branch and worktree information appears as Repository metadata. It is not a Run lifecycle. |
| Worktree owner and TUI focus | Entering a Run never transfers mutation ownership. |
| Pause and navigation | Leaving a screen does not pause. Pause is an explicit domain command. |
| Command cancel and Run cancel | Command cancellation targets one execution. Run cancellation terminates the Run attempt by policy. |
| Child cancel and Parent cancel | Canceling a Child does not cancel its Parent or siblings. |
| Client disconnect and Run failure | Disconnect changes Client state only. Durable work continues or becomes recoverable. |
| Shared state and stale projection | Each projection carries a sequence cursor and stale marker. The server remains authoritative. |

## User journeys

### Journey 1 — Start a new Root Run

1. The user runs `kiln` or `kiln start` inside a Project.
2. Kiln identifies the Workspace, Project, Repository, current branch, dirty state, existing Session, and local runtime availability.
3. The interface shows a concise preflight summary.
4. The user enters an intent in the composer or passes it through CLI arguments.
5. The interface shows the initial permission profile and its important exclusions.
6. Starting requires an explicit action. A permission profile is not silently broadened.
7. Kiln creates the Session, root Task, and Root Run through the domain service.
8. The TUI opens the Root Run only after durable creation succeeds.
9. Streamed output and bounded Tool or Command activity appear as event projections.
10. Large output becomes an Artifact and remains available through a reference.

Failure behavior:

- A dirty Repository is shown before start.
- A conflicting active Session requires a choice: resume, start a separate Session, or cancel.
- If durable state cannot be opened, Kiln does not create an in-memory substitute.
- If the TUI cannot start, the CLI prints the created Run identifier and recovery command.

### Journey 2 — Delegate investigation

1. The current Run creates a read-only Scout Child through the accepted delegation contract.
2. The Parent either continues or enters `waiting_for_child` according to its recorded policy.
3. The Parent transcript receives one compact Child card.
4. The Child starts without moving Client focus automatically.
5. The user can open the Child card, press the enter action, or use `kiln run enter`.
6. The Child view shows its independent Context summary, permission profile, current activity, accounting, and Evidence.
7. Parent navigation remains visible.
8. On completion, the Child result validates and becomes durable before delivery.
9. The Parent card updates with observed facts, inferences, assumptions, unknowns, Evidence count, and Artifact references.
10. The Parent does not receive the full Child transcript.

### Journey 3 — Respond to blocked Child work

1. A Child raises normalized Attention.
2. The Attention item appears in the global inbox, the originating Run, and ancestor summaries.
3. The header shows category, severity, age, and blocking effect.
4. For a simple question, the user can answer from the inbox without entering the Child.
5. For a permission request, the interface shows requested Capability, Resource scope, duration, policy source, and effects.
6. The user can answer, enter the originating Run, route to the Parent, deny, pause, or cancel.
7. Permission approval requires an explicit approval action. Generic `Enter` never approves.
8. The first valid durable response wins. Concurrent responders receive the current resolution and a conflict message.
9. The Child resumes only through its recorded `resume_state`.
10. A blocking item remains visible until resolved, denied, expired, withdrawn, or superseded.

### Journey 4 — Inspect implementation work

The user opens the Change view from the current Run or a Child card.

The view shows:

- Repository;
- branch;
- base commit;
- current head commit;
- worktree identifier;
- mutation-owner Run;
- dirty state;
- changed-file count;
- proposed or applied Patch status;
- exact verification binding;
- Evidence freshness;
- merge blockers;
- integration status.

The summary uses this progression:

```text
Proposed
→ Applied
→ Inspected
→ Executed
→ Verified
→ Accepted
→ Integrated
→ Delivered
```

The interface does not infer later stages from earlier stages.

A changed file is not verified because it exists. A passing check is not integrated. A mergeable branch is not accepted. A Receipt is not Evidence.

### Journey 5 — Enter an independent Verifier

1. The user opens the Verifier Child.
2. The header labels it `Verifier` and shows the exact Repository and Environment state received.
3. The Context panel shows accepted criteria and source references, not the Builder confidence narrative.
4. Verification Commands appear as independent Command activity.
5. The result shows `PASS`, `FAIL`, or `BLOCKED`.
6. `PASS` links to reproduced Evidence.
7. `FAIL` links to reproduced defects and failing criteria.
8. `BLOCKED` shows the missing access, environment, criteria, state, or Resource.
9. The user can inspect the Evidence and return to the implementation Run with the Parent action.
10. The interface never offers a repair action inside the Verifier Run.

### Journey 6 — Recover after restart

1. A Client reconnects to the local Kiln runtime or starts it in recovery mode.
2. Kiln opens durable storage and reconstructs the Session projection.
3. The Client receives a projection snapshot with an event sequence.
4. The Run graph, unresolved Attention, Artifacts, Evidence, Receipts, and deliveries return.
5. Active external work is reconciled before it is labeled active.
6. Unknown execution state becomes `orphaned`.
7. Invalidated results become `stale`.
8. Dirty or uncertain worktrees remain preserved.
9. Client-local focus is restored only if the focused Run still exists and is visible.
10. Otherwise focus falls back to the nearest surviving ancestor, then the Root Run.
11. The interface states whether the restored location came from durable Run state or client-local history.

### Journey 7 — Use a narrow terminal

In a terminal from 50 to 79 columns:

- the header becomes stacked text;
- the breadcrumb shows Root, an ellipsis when needed, Parent, and current Run;
- Child cards collapse to three to five lines;
- the Run tree and Attention inbox open as full-screen overlays;
- only one inspection surface is visible at a time;
- status labels remain text;
- the composer remains visible;
- Parent and Root keys remain visible;
- approval and denial remain explicit;
- command output is summarized and paged.

Below 50 columns or 16 rows, Kiln enters constrained mode. It renders one region at a time and displays the CLI equivalent for every unavailable layout action. It does not silently hide essential control actions.

## Information hierarchy

### Always visible

In standard and wide layouts:

- Project;
- current Run purpose or identifier;
- current Run state;
- logical breadcrumb;
- transcript or active content;
- Attention count and highest severity;
- input composer and target;
- Parent and Root navigation hints.

In narrow layouts the same information can use stacked rows.

### Usually visible when relevant

- Repository and branch;
- worktree or Workspace status;
- current permission profile;
- active Child summary;
- current Tool or Command summary;
- verification result;
- Evidence freshness;
- Context and token pressure;
- stale projection marker;
- local runtime connection state.

### On demand

- complete Run tree;
- complete Tool history;
- complete Command logs;
- complete Child transcripts;
- detailed token metrics;
- Capability catalog;
- permission matrix;
- raw telemetry;
- complete Artifact bodies;
- complete Receipts;
- full Git history;
- complete event history.

## Screen hierarchy

```text
Kiln terminal client
├── Main Run screen
│   ├── location and status header
│   ├── transcript and structured messages
│   ├── inline Child cards
│   ├── compact activity strip
│   ├── Evidence and verification strip
│   └── composer
├── Run tree
│   ├── overlay in narrow and standard layouts
│   └── optional side panel in wide layout
├── Attention inbox
│   ├── list
│   ├── item details
│   ├── question responder
│   └── permission decision
├── Inspection surfaces
│   ├── Run details
│   ├── Command and Tool activity
│   ├── changes and diff
│   ├── Artifact reader
│   ├── Evidence reader
│   ├── Receipt reader
│   ├── Context summary
│   └── permission summary
├── Command palette
├── Confirmation dialog
└── Recovery and stale-state view
```

The main Run screen is the default center. Other surfaces are overlays, drawers, or explicit screens. The Run tree is not a permanent dashboard.

## Main screen

### Standard layout

```text
┌ Kiln · kiln · main@4ab19c2 · worktree clean · Attention: 1 BLOCKING ┐
│ root › implementation › verifier                    [VERifying]     │
├ Conversation ────────────────────────────────────────────────────────┤
│ USER  Verify the accepted requirements.                              │
│                                                                     │
│ VERIFIER  Running the Project verification entry point.             │
│                                                                     │
│ ┌ Child · Scout · COMPLETED ──────────────────────────────────────┐  │
│ │ Investigated prior cancellation patterns · Evidence 4 · 2.1k t │  │
│ │ Result: 3 facts · 1 inference · 2 unknowns      [Enter] [Evidence]│ │
│ └─────────────────────────────────────────────────────────────────┘  │
│                                                                     │
│ CMD  mix test · RUNNING · 18s · output stored after 200 lines        │
├ Evidence: CURRENT @4ab19c2 · Verification: RUNNING · Context: 61% ──┤
│ To: verifier run_01J...                                               │
│ > _                                                                  │
├ Alt+← Parent · Alt+Home Root · Ctrl+G Runs · Ctrl+A Attention ──────┤
└──────────────────────────────────────────────────────────────────────┘
```

### Wide layout

At 120 columns or more, the user can toggle a Run-tree side panel. The default remains conversation-first.

```text
┌ Runs ───────────────────────┬ Kiln · project · repository · branch · Attention 1 ┐
│ ▾ root RUNNING              │ root › implementation › verifier [VERIFYING]        │
│   ├─ scout COMPLETED E4     ├ Conversation ────────────────────────────────────────┤
│   ├─ implementation RUNNING │ ...                                                   │
│   │  └─ verifier VERIFYING  │ ...                                                   │
│   └─ docs BLOCKED !         │                                                       │
│                             ├ Activity / Evidence / Composer ───────────────────────┤
└─────────────────────────────┴───────────────────────────────────────────────────────┘
```

The side panel is user-controlled. It does not appear automatically when Children start.

### Narrow layout

```text
Kiln · kiln
root › … › verifier
VERIFYING · ATTENTION 1 · Evidence CURRENT
──────────────────────────────────────────
VERIFIER  Running mix test.

Scout completed · Evidence 4
[Enter] [Evidence]

CMD mix test · RUNNING · 18s
──────────────────────────────────────────
To: verifier
> _
──────────────────────────────────────────
Alt← Parent · AltHome Root · ^G Runs · ^A Attn
```

## Breadcrumb and location

### Meaning

The breadcrumb represents logical Run parentage only.

It does not represent:

- OTP supervision;
- Git branch ancestry;
- process hierarchy;
- screen hierarchy;
- navigation history.

### Visible length

- Wide layout: at most five Run segments.
- Standard layout: at most four Run segments.
- Narrow layout: at most three Run segments.
- Root and current Run are always preserved.
- When ancestors are hidden, use `…` between Root and the nearest visible ancestor.
- The current segment is followed by its text state label when space permits.

Example:

```text
root › … › implementation › verifier [VERIFYING]
```

The full ancestry is available from the Run tree and breadcrumb details action.

### Navigation

- `Alt+Left`: enter the logical Parent Run.
- `Alt+Home`: enter the Root Run.
- `Alt+Up`: previous sibling by stable creation order.
- `Alt+Down`: next sibling by stable creation order.
- `Alt+Right`: move forward through client-local navigation history.
- `Ctrl+G`: open the Run tree.
- Browser-style back history is client-local and does not replace Parent navigation.

`Alt+Left` always means Parent. It never means generic history.

### Run lifecycle effects

- A viewed Child that completes remains open. Focus does not jump.
- A Parent that completes while the user views a Child remains a valid Parent destination.
- A canceled Run remains inspectable in history.
- An orphaned Run remains inspectable and is marked `ORPHANED`.
- A stale Run remains inspectable and is marked `STALE`.
- A deleted or unavailable client-local target falls back to the nearest surviving ancestor.
- Durable Runs are not deleted by the interface. Archival and retention are separate policy actions.

## Child cards

Cards update from projected events. They show meaningful changes, not every token or file read.

### Running Child

```text
┌ Scout · RUNNING · phase: investigation ─────────────────────────────┐
│ Find prior recovery patterns                                         │
│ Now: reading docs/SESSION-MODEL.md and cancellation tests             │
│ Scope: read-only · Context 54% · 2.1k input / 430 output tokens       │
│ Inspected: 6 files · 3 symbols · Evidence 2 · Updated 8s ago          │
│ [Enter] [Steer] [Pause] [Cancel]                                     │
└───────────────────────────────────────────────────────────────────────┘
```

Required fields:

- purpose and role;
- Run state;
- blocking state;
- phase;
- last meaningful activity;
- inspected files, symbols, Commands, or Artifacts;
- changed-file count when applicable;
- token use or pressure;
- permission profile;
- Attention state;
- Evidence count;
- active elapsed time or last meaningful update.

### Completed Child

```text
┌ Verifier · COMPLETED · outcome: FAIL ────────────────────────────────┐
│ 7 criteria evaluated · 5 PASS · 2 FAIL · reproduced Evidence 9       │
│ Failure: cancellation leaves one Command orphaned                     │
│ Receipt: rcpt_01J... · Artifacts 3 · Verification @4ab19c2            │
│ [Result] [Transcript] [Evidence] [Commands] [Artifacts]               │
└───────────────────────────────────────────────────────────────────────┘
```

The Run state and role result remain separate:

```text
Run: COMPLETED
Verifier outcome: FAIL
```

### Blocked or failed Child

```text
┌ Scout · WAITING_FOR_PERMISSION · BLOCKING ───────────────────────────┐
│ Request: read network host hexdocs.pm                                 │
│ Last success: indexed local ExDoc · Evidence remains CURRENT          │
│ Needed: approve scope, deny, route, pause, or cancel                  │
│ Retry: safe after decision                                            │
│ [Respond] [Enter] [Route] [Pause] [Cancel]                            │
└───────────────────────────────────────────────────────────────────────┘
```

The card states:

- blocker or failure category;
- last successful activity;
- required action;
- retry safety;
- current Evidence validity;
- applicable actions.

## Run tree

### Purpose

The Run tree answers:

- Where am I?
- What else is running?
- What is blocked?
- What requires Attention?
- Which Runs mutate source?
- Which Runs verify work?
- Which Runs completed?
- Which results remain uninspected?
- Which Evidence is stale?
- Which Run owns a branch or worktree?

### Symbols

Symbols always have text alternatives in details and ASCII fallback.

| Symbol | Meaning | ASCII fallback |
| --- | --- | --- |
| `▶` | running or starting | `>` |
| `…` | waiting | `~` |
| `!` | blocking Attention | `!` |
| `✓` | completed | `C` |
| `×` | failed | `F` |
| `■` | canceled | `X` |
| `?` | orphaned | `?` |
| `↺` | stale | `S` |
| `V+` | Verifier PASS | `V+` |
| `V-` | Verifier FAIL | `V-` |
| `VB` | Verifier BLOCKED | `VB` |
| `W` | mutation owner | `W` |
| `U` | uninspected result | `U` |

Color can reinforce these states. Text and symbols remain authoritative.

### Wide panel

```text
Runs [all] [attention] [active] [verify]
▾ root · RUNNING
  ├─ scout: recovery patterns · ✓ E4 U
  ├─ implementation · ▶ W branch task/cancel
  │  └─ verifier · VB !
  └─ scout: docs · … WAITING_FOR_USER !
```

### Overlay

```text
┌ Run tree ─ Search: cancel_ ─ Filter: attention ───────────────────────┐
│ root                                                                  │
│ ├─ implementation · RUNNING · W task/cancel                           │
│ │  └─ verifier · COMPLETED · FAIL · E9                                │
│ └─ scout: docs · WAITING_FOR_USER · !                                 │
│                                                                       │
│ Enter open · Alt← parent · Alt↑/↓ sibling · / search · f filter       │
└───────────────────────────────────────────────────────────────────────┘
```

### Behavior

- Arrow keys move stable selection.
- Events update rows without moving selection.
- If a selected Run changes filter membership, keep it visible until the next deliberate navigation action and mark it `filtered`.
- Collapsed state is client-local.
- Search matches purpose, role, short Run ID, Task ID, branch, and worktree label.
- Filters include state, active, Attention, stale, verification, mutation owner, and uninspected.
- Clicking a row selects it.
- Double-clicking or pressing `Enter` enters it.
- Mouse hover is never required.
- The tree never becomes the authoritative Run graph.

## Attention inbox

### Inbox

```text
┌ Attention · 3 open ──────────────────────────────────────────────────┐
│ ! BLOCKING  permission_request  docs scout        2m                  │
│   Read network host hexdocs.pm · changes permissions                 │
│ ! HIGH      verification_blocker verifier         5m                  │
│   Integration environment unavailable · Evidence refs 2              │
│   NORMAL    stale_evidence      implementation    9m                  │
│   Verification no longer matches head commit                         │
│                                                                       │
│ Enter details · R respond · O origin · P parent · D deny · X cancel  │
└───────────────────────────────────────────────────────────────────────┘
```

### Item details

Every item shows:

- originating Run;
- Parent context;
- category;
- bounded description;
- severity;
- created time;
- blocking effect;
- allowed responses;
- expiry or no-expiry policy;
- escalation time;
- Evidence and Artifact references;
- whether a response changes permission, source, execution, or integration state;
- current revision and resolution state.

### Categories

The interface distinguishes:

- informational notification;
- question;
- permission request;
- destructive confirmation;
- blocking failure;
- security-sensitive request;
- verification blocker;
- merge blocker;
- Resource limit;
- stale Evidence;
- orphan recovery decision.

### Response safety

- `Enter` opens details only.
- `R` opens a question responder when allowed.
- `A` opens an approval review for permission or integration requests.
- `D` opens denial with optional reason.
- `O` enters the originating Run.
- `P` routes to the Parent.
- `Space` acknowledges informational notices.
- Approval requires the explicit `A` flow and a labeled confirmation.
- Cancellation requires the explicit `X` flow and a labeled confirmation.
- A destructive confirmation is completed with the action-specific key shown in the dialog. Generic `Enter` does not confirm.

## Focus and multi-client model

### Shared durable state

- Sessions, Tasks, Runs, and Run states;
- Run graph and structured results;
- transcripts and durable output segments;
- Attention lifecycle;
- permissions, approvals, and denials;
- Capability grants;
- Commands, Tool calls, and Terminals;
- Artifacts, Change sets, Claims, Evidence, and Receipts;
- Git branch, worktree, lease, and mutation ownership;
- event sequence and projection snapshots.

### Client-local state

- focused Run;
- selected Run;
- navigation history;
- scroll position;
- collapsed Run-tree nodes;
- active overlay or inspection screen;
- panel layout and width;
- composer draft unless explicitly saved;
- input history;
- local timestamp and color preferences;
- last applied event sequence;
- read state for non-blocking notifications when configured per Client.

Blocking Attention resolution is always shared.

### Conflict behavior

#### Two Clients answer the same question

The response command includes the Attention ID and expected revision.

The first valid response appends the durable resolution. The second receives exit or result code `conflict` with the winning resolution and current revision. Kiln does not append two answers.

#### Two Clients approve the same request

An identical approval is idempotent and returns the existing decision. A conflicting approval or denial returns `conflict`. No Client can broaden the original requested scope during response.

#### Pause and resume races

Commands include the expected Run state. The first valid transition wins. A repeated request for the current state is idempotent. An incompatible request returns the current state and allowed transitions.

#### Cancel races

Cancellation is idempotent by target and active cancellation record. Repeating the same cancellation returns the existing record. A pause or resume after cancellation begins is rejected.

#### Simultaneous Run input

General steering messages are serialized by the server event sequence and retain Client identity.

A schema-bound Attention response accepts only one durable response.

When a Run has an exclusive active model turn, later steering input is queued as a visible pending input event unless policy rejects it. The interface never silently overwrites input.

#### Inspect while state changes

Inspection views carry `as_of_sequence`. When newer state arrives, the view shows `NEWER STATE AVAILABLE`. It does not silently replace a diff or Receipt being read.

#### Reconnect with stale projection

The Client sends its snapshot ID and last sequence. The service replays events when possible. If the cursor is too old, missing, or inconsistent, the service sends a new snapshot and subsequent events. The Client labels the projection stale until resynchronization completes.

## CLI design

### General rules

The CLI is cursor-control independent and works in pipes, scripts, CI, and basic terminals.

Output formats:

- `text`: stable human-readable summaries;
- `json`: one versioned result envelope;
- `jsonl`: one versioned event envelope per line for streaming commands.

The public CLI schema is an interface contract. It is not the SQLite schema and does not expose internal table layouts.

Global options:

```text
--project PATH
--session SESSION_ID
--format text|json|jsonl
--no-color
--ascii
--timeout DURATION
--connect ENDPOINT
--expected-revision REVISION
```

Mutating commands accept idempotency keys where repeated execution can create duplicate effects:

```text
--idempotency-key KEY
```

### Exit codes

| Code | Meaning |
| --- | --- |
| `0` | command completed as requested |
| `2` | invalid arguments or usage |
| `3` | Project, Session, Run, Attention, Artifact, Evidence, or Receipt not found |
| `4` | invalid lifecycle state, stale target, or unsupported transition |
| `5` | permission denied or policy blocked |
| `6` | concurrent modification or expected-revision conflict |
| `7` | work remains blocked or Attention is required |
| `8` | local runtime or required Resource unavailable |
| `9` | partial result; bounded output or recovery decision required |
| `10` | durable state is unavailable, corrupt, or cannot be trusted |
| `124` | CLI-side timeout while waiting for a response |
| `130` | Client interrupted; server-side Run state is reported separately |

An exit code never substitutes for the structured `status` field.

### Runtime-not-running behavior

Read-only commands can start a one-shot local query service against durable storage when the store is healthy and no active-runtime reconciliation is required.

Control commands start or connect to the local Kiln runtime service. They do not mutate durable state through a separate offline path.

When an active external execution could exist but the runtime is absent, Kiln enters recovery and returns `8` or `9` until reconciliation determines safe control.

The local service-launch mechanism is deferred to the first runtime implementation plan. The interface contract assumes a local domain endpoint and does not require a particular daemon manager.

### Commands

#### `kiln`

Purpose: open the current Project.

- With a TTY: connect to or start the local runtime and open the TUI.
- Without a TTY: behave as `kiln status --format text`.
- Safety: never starts a new Root Run without an intent and explicit start action.
- Exit: returns the TUI exit reason, not the Run outcome.

#### `kiln start`

```text
kiln start [--intent TEXT | --intent-file PATH] [--permission-profile PROFILE]
           [--no-tui] [--idempotency-key KEY]
```

Purpose: create one Session, root Task, and Root Run.

Interactive behavior: prompt for missing intent, display Repository and permission preflight, then require explicit start.

Non-interactive behavior: all required values must be supplied. It returns usage error rather than guessing.

Human output: IDs, objective summary, Repository state, permission profile, and attach command.

Machine output: `start_result` envelope.

Safety: refuses unreviewed permission expansion and reports dirty Repository state.

Idempotency: the idempotency key returns the original created Session and Run.

#### `kiln resume`

```text
kiln resume [SESSION_ID | RUN_ID] [--tui | --no-tui]
```

Purpose: reconnect to an existing Session or inspect a recoverable Run.

Interactive behavior: when no ID is supplied, show resumable Sessions.

Non-interactive behavior: an ID is required when more than one Session exists.

Stale or terminal Run: opens inspection; it does not create a new attempt.

Orphaned Run: opens recovery state and returns `7` or `9` in non-interactive mode.

#### `kiln runs`

```text
kiln runs [--status STATE] [--attention] [--role ROLE] [--search TEXT]
```

Purpose: list Run projections.

Human output: stable table with state, purpose, Parent, role, Attention, verification, Evidence, and mutation marker.

JSON output: bounded list with continuation cursor.

JSONL: optional follow mode with `--follow`.

When runtime is absent: use one-shot projection rebuild if safe.

#### `kiln run show`

```text
kiln run show RUN_ID [--at-sequence N] [--include summary|activity|accounting|authority]
```

Purpose: show one Run without changing Client focus.

Completed or stale Run: remains inspectable.

Orphaned Run: includes unknown effects and recovery actions.

Machine output: `run_projection`, not the persistence record.

#### `kiln run enter`

```text
kiln run enter RUN_ID
```

Purpose: open a Run in an interactive Client.

Requires a TTY. In non-TTY use, return usage error and suggest `kiln run show`.

Navigation changes Client-local focus only.

#### `kiln run pause`

```text
kiln run pause RUN_ID [--reason TEXT] [--expected-revision REV]
```

Purpose: request a durable pause at a safe boundary.

Interactive behavior: show target and active executions.

Non-interactive behavior: requires Run ID.

Idempotency: already paused returns success with current pause record.

Completed, failed, canceled, or stale: return invalid state.

Orphaned: require recovery; pause cannot prove control of unknown execution.

#### `kiln run resume`

```text
kiln run resume RUN_ID [--expected-revision REV]
```

Purpose: resume a paused Run through its accepted return state.

Idempotency: running or queued returns current state when the request is equivalent.

Stale Run: requires a new Run attempt, not resume.

Orphaned Run: requires reconciliation.

#### `kiln run cancel`

```text
kiln run cancel RUN_ID [--scope target|descendants|session]
                       [--reason TEXT] [--yes] [--idempotency-key KEY]
```

Purpose: request cancellation.

Interactive behavior: show target, descendants, active Commands, worktree state, and unknown-effect risk. Confirmation uses the explicit cancel action.

Non-interactive behavior: requires `--yes`, target, and scope.

Idempotency: returns existing active or completed cancellation record.

A canceled Child does not cancel Parent or siblings unless scope explicitly includes descendants of the target.

#### `kiln attention`

```text
kiln attention [list | show ATTENTION_ID] [--blocking] [--category CATEGORY]
```

Purpose: inspect the global Session Attention index.

Human output distinguishes questions, permissions, failures, blockers, stale Evidence, and recovery decisions.

Machine output includes allowed actions and expected revision.

#### `kiln answer`

```text
kiln answer ATTENTION_ID --text TEXT [--expected-revision REV]
```

Purpose: answer a schema-compatible question.

It cannot approve permission or integration.

Idempotency: replay of the same accepted answer returns the existing resolution. A different answer returns conflict.

#### `kiln approve`

```text
kiln approve ATTENTION_ID --scope SCOPE [--expires DURATION]
                          [--reason TEXT] --yes [--expected-revision REV]
```

Purpose: approve exactly the requested permission or integration decision.

Interactive use can omit `--yes` and use an explicit approval confirmation.

The command cannot broaden scope beyond the original request.

Generic `Enter`, piped empty input, and absent `--yes` never approve.

#### `kiln deny`

```text
kiln deny ATTENTION_ID [--reason TEXT] [--expected-revision REV]
```

Purpose: deny a question escalation, permission, destructive request, or recovery proposal when denial is valid.

Denial is durable and visible to the originating Run.

A Child cannot retry under broader scope without a new request.

#### `kiln artifacts`

```text
kiln artifacts [list | show ARTIFACT_ID] [--run RUN_ID] [--offset N] [--limit N]
```

Purpose: list or read immutable Artifacts.

Large content is paged. Binary content returns metadata and an export action.

Missing Artifact returns `3`; a missing external target returns `9` with the durable reference.

#### `kiln evidence`

```text
kiln evidence [list | show EVIDENCE_ID] [--run RUN_ID] [--current | --stale]
```

Purpose: inspect Evidence, method, producer, state binding, freshness, and invalidation.

Human output never substitutes activity for Evidence.

#### `kiln receipts`

```text
kiln receipts [list | show RECEIPT_ID] [--run RUN_ID]
```

Purpose: inspect sealed outcome manifests.

The output shows Evidence references, unresolved failures, warnings, unknowns, state binding, and integration status.

#### `kiln status`

```text
kiln status [--watch]
```

Purpose: show Project, runtime, Session, focused or latest Run, Attention, Repository, worktree, verification, and recovery state.

`--watch --format jsonl` emits public interface events.

## Keybinding proposal

All essential actions have CLI equivalents.

| Key | Action |
| --- | --- |
| `Tab` / `Shift+Tab` | move focus through visible interactive regions |
| `Ctrl+G` | open or close Run tree |
| `Ctrl+A` | open or close Attention inbox |
| `Ctrl+P` | open command palette |
| `Alt+Left` | enter logical Parent Run |
| `Alt+Home` | enter Root Run |
| `Alt+Up` / `Alt+Down` | previous or next sibling |
| `Alt+Right` | forward through client-local history |
| `Ctrl+L` | open activity view |
| `Ctrl+E` | open Evidence view |
| `Ctrl+O` | open Artifact and Receipt picker |
| `Ctrl+D` | open Change view |
| `Enter` | open selected non-destructive item or submit one-line input |
| `Ctrl+J` or `Alt+Enter` | insert newline in composer |
| `Ctrl+X` | cancel the active composer draft or response mode after confirmation when non-empty |
| `Esc` | close the top overlay or cancel selection; never cancel a Run |
| `?` | show context-sensitive keys and text alternatives |
| `/` in list views | search |
| `f` in Run tree | cycle filters |
| `A` in permission details | open explicit approval confirmation |
| `D` in Attention details | open denial |
| `P` in Attention details | route to Parent |
| `O` in Attention details | enter originating Run |
| `X` in Run or Attention details | open explicit cancellation confirmation |

Key handling must account for terminals that do not distinguish some modified keys. The command palette and CLI equivalents are the fallback.

## Mouse behavior

Mouse support is optional convenience.

- Primary click selects a card, Run, Attention item, tab, or button.
- Double-click or a dedicated open button enters a selected Run.
- Wheel scrolls the region under the pointer.
- Clicking a breadcrumb segment enters that Run.
- Clicking a destructive or permission action opens a confirmation. It does not apply the action.
- The final confirmation requires clicking a labeled action button or using the action-specific key.
- Drag selection must not trigger domain commands.
- Hover-only information is prohibited.
- Mouse capture failure must not remove keyboard access.

## Input composer

### Target visibility

The composer always shows one target:

```text
To: current Run run_01J...
```

Attention response mode shows:

```text
Reply to: attention_01J... from scout run_01J...
```

Local command mode shows:

```text
Local client command:
```

Kiln command mode shows:

```text
Kiln domain command:
```

### Input classes

- Plain text: message or steering input to the current Run.
- Leading `/`: Kiln domain command entered through the composer.
- Leading `:`: client-local TUI command.
- Attention responder: schema-bound response to one Attention item.
- Permission decision: dedicated approval or denial surface; never plain text.
- File or Artifact attachment: explicit reference added to the submission preview.

No mode is invisible. The target line, border label, and preview identify the mode.

### Editing

- Single-line input submits with `Enter`.
- `Ctrl+J` or `Alt+Enter` inserts a newline.
- `Ctrl+X` cancels the draft after confirmation when content exists.
- Up and Down show input history only when the composer is empty.
- Long input can open `$EDITOR` through an explicit composer action.
- Draft history is client-local unless the user explicitly saves a draft Artifact.

### Paste safety

Bracketed paste is enabled when supported.

A paste larger than 4 KiB or 20 lines:

1. never submits automatically;
2. becomes a reviewed draft block;
3. shows byte and line count;
4. offers keep inline, store as Artifact, attach file, or discard;
5. redacts or warns about detected secret classes through policy;
6. preserves literal text without interpreting leading `/` or `:` until confirmed.

## Tool and Command activity

### Compact activity

The main screen shows the most relevant current activity:

```text
TOOL repo.search · AUTHORIZED · RUNNING · 320ms
CMD  mix test · RUNNING · 18s · output 142 lines · Artifact pending
```

### Lifecycle labels

Tool activity distinguishes:

```text
REQUESTED
AUTHORIZED
DENIED
QUEUED
RUNNING
COMPLETED
FAILED
CANCELED
ORPHANED
```

Command activity distinguishes:

```text
CREATED
AUTHORIZED
STARTING
RUNNING
EXITED
TIMED_OUT
CANCELED
KILLED
ORPHANED
FAILED_TO_START
```

Model interpretation appears as a separate transcript message after the result. It is not merged into the Command record.

### Details

On demand show:

- Tool intent and selected implementation;
- authority decision;
- input digest;
- start and completion time;
- duration;
- native exit status;
- output summary;
- truncation;
- Artifact references;
- cancellation and process-tree result;
- retry safety;
- Repository or Environment binding.

Large output does not stream indefinitely into the transcript.

Initial output policy:

- retain at most 200 recent display lines per active Command;
- coalesce rapid output into segments no more often than every 100 milliseconds;
- externalize complete output to Artifacts according to policy;
- display explicit truncation and continuation;
- page Artifact reads at no more than 256 KiB or 2,000 lines per request.

## Change and Git visibility

### Compact summary

```text
Git: task/cancel @4ab19c2 · base main@9132fe1 · worktree wt_01J...
Owner: implementation run_01J... · dirty: yes · changed: 7
Change: APPLIED · Verification: STALE · Integration: BLOCKED
```

This summary appears only when relevant.

### On-demand Change view

Sections:

1. Repository and worktree.
2. branch, base, head, merge base, ahead, and behind.
3. mutation-owner Run and lease.
4. changed paths and counts.
5. Patch or Change-set status.
6. commits.
7. verification bindings and freshness.
8. projected-merge result.
9. conflicts and blockers.
10. integration decision and Receipt.

Candidate branches and stacked dependencies remain deferred from the initial product but the view can reserve labeled sections for future data.

Entering a Run never transfers branch, worktree, lease, or mutation ownership.

## Evidence and completion

### Completion language

Kiln uses precise labels:

- `PROPOSED`;
- `APPLIED`;
- `INSPECTED`;
- `EXECUTED`;
- `VERIFIED`;
- `ACCEPTED`;
- `INTEGRATED`;
- `DELIVERED`.

A summary can contain several labels at once:

```text
Implementation: APPLIED
Verification: FAIL
Acceptance: BLOCKED
Integration: NOT_REQUESTED
Delivery: RESULT_AVAILABLE
```

### Completion presentation

The completion surface answers:

- What was requested?
- What changed?
- What was inspected?
- What was executed?
- What passed?
- What failed?
- What remains unknown?
- Which commit or dirty fingerprint was verified?
- Which Evidence supports each material Claim?
- Which Receipt records the result?
- Is the result proposed, accepted, or integrated?
- Which Attention or blockers remain?

The presentation does not celebrate completion when verification failed, is blocked, or became stale.

Model confidence is displayed only as a Claim when it is material. It is never Evidence.

## Failure and recovery states

| Failure state | What the user sees | What remains safe or active | Recovery actions | Retry and approval |
| --- | --- | --- | --- | --- |
| Model failure | Run state, invocation failure, last durable output, token use | Run, prior Artifacts, Commands, and Evidence remain | retry invocation, change model through policy, pause, fail Run | retry requires a new invocation; permission re-evaluated |
| Tool failure | Tool status, implementation, error, partial output | Run can continue if contract allows | inspect, safe retry, choose accepted fallback, pause | retry is idempotent only when Tool contract says so |
| Command failure | exit code, signal, bounded stderr, Artifact refs | Repository and prior Evidence remain bound to recorded state | inspect logs, retry in same or new Command, fail Run | mutation retry requires state check |
| Command timeout | `TIMED_OUT`, grace and termination result | partial output preserved | extend through new decision, retry, cancel Run | no automatic extension |
| Process cancellation | target and process-tree outcomes | unrelated Runs continue | inspect partial Artifacts, reconcile effects | repeated cancel is idempotent |
| Child Run crash | lease loss and last durable Child state | Parent and siblings continue | safe Worker replacement, pause, fail, orphan | duplicate effects must be ruled out |
| Parent Run crash | Parent process unavailable; Child cards remain | Children continue; result delivery buffers | restart Parent process, route delivery to Root | no duplicate Child creation |
| Kiln restart | recovery banner and replay progress | durable state preserved; external state uncertain until checked | reconcile, resume, inspect orphaned items | automatic retry only for proven idempotent work |
| Lost terminal connection | `CLIENT DISCONNECTED` on reconnect | runtime work continues | reconnect and replay | no Run approval required |
| Stale client projection | visible `STALE VIEW` and last sequence | server state remains authoritative | request replay or snapshot | Client commands include expected revision |
| Missing Artifact | metadata and missing target reason | durable reference and other Evidence remain | re-fetch when allowed, mark unavailable, replace Artifact | network or source access may require approval |
| Missing worktree | Run and lease mismatch | branch and durable records remain | inspect Git, reconstruct if safe, mark orphaned | destructive cleanup requires approval |
| Dirty abandoned worktree | preserved-work warning and changed paths | user work remains untouched | inspect, assign owner, export Patch, archive | never auto-delete |
| Permission denial | denied scope and policy reason | Run can continue within existing grants | revise Task, ask narrower scope, fail or cancel | no retry under wider scope without new request |
| Verification failure | Verifier `FAIL`, criteria, reproduced Evidence | implementation remains proposed or applied | return to implementation, create new Run, inspect | Verifier cannot repair |
| Stale Evidence | `STALE` label, invalidating event and state | historical Evidence remains available | rerun verification against current state | no automatic current status |
| Branch conflict | conflict category and paths | source and worktree preserved | inspect, resolve in authorized writing Run, abandon | model resolution requires accepted authority |
| Attention timeout | item age, escalation, no auto-decision | Run stays blocked or follows explicit timeout policy | answer, route, deny, pause, cancel | permission never auto-granted |
| Orphaned Run | unknown execution or effect summary | history and known Artifacts remain | reconcile, mark failed, cancel after proof, create new Run | no success or integration until resolved |
| Partial event replay | gap marker and last good sequence | displayed earlier state is marked stale | request missing range or snapshot | controls blocked when safety depends on missing state |
| Corrupt or unavailable durable state | critical integrity screen and affected path | no inferred in-memory success state | stop control operations, preserve files, restore or repair store | mutating actions require recovered trusted state |

## Event and projection model

### Minimum durable event classes

The interface consumes normalized domain events including:

- `RunCreated`;
- `RunStarted`;
- `RunStateChanged`;
- `RunOutputSegmentRecorded`;
- `ChildRunLinked`;
- `ToolRequested`;
- `ToolAuthorized`;
- `ToolStarted`;
- `ToolCompleted`;
- `CommandStarted`;
- `CommandOutputSegmentRecorded`;
- `CommandCompleted`;
- `AttentionRaised`;
- `AttentionResolved`;
- `PermissionGranted`;
- `PermissionDenied`;
- `ArtifactCreated`;
- `EvidenceRecorded`;
- `EvidenceInvalidated`;
- `ReceiptSealed`;
- `ChangeSetUpdated`;
- `VerificationCompleted`;
- `RunCompleted`;
- `RunFailed`;
- `RunCanceled`;
- `RunOrphaned`;
- `RunMarkedStale`;
- `ClientProjectionSnapshotCreated` when a durable snapshot is retained.

Not every token, progress tick, cursor change, hover, scroll, or widget transition becomes durable.

### Event identity and ordering

Each public interface event contains:

- interface schema version;
- unique event ID;
- Session ID;
- per-Session durable sequence;
- event type;
- occurred time;
- recorded time;
- aggregate type and ID;
- causation and correlation IDs when present;
- bounded payload or Artifact reference;
- sensitivity and redaction class.

The journal sequence is authoritative for one Session.

Events from different Sessions have no implied total order.

### Duplicate and delayed events

- Clients deduplicate by event ID.
- Replayed events at or below the last applied sequence are ignored after digest consistency check.
- Events above the next expected sequence are buffered within a bounded gap window.
- A persistent gap triggers range replay.
- A missing or compacted range triggers a fresh snapshot.
- The Client never fabricates intermediate states.

### Snapshots

A projection snapshot contains:

- snapshot ID and schema version;
- Session ID;
- `through_sequence`;
- projection digest;
- Run graph summary;
- current Run summaries;
- open Attention summaries;
- current Git, Evidence, verification, Artifact, and Receipt summaries;
- continuation cursors for omitted history.

A snapshot is rebuildable from durable state. It is not a second authority.

### Client cursor

Each Client tracks:

- snapshot ID;
- last applied sequence;
- last acknowledged notification sequence;
- focused Run ID;
- local selection and history version.

The server can reject a command based on stale expected revision even when the Client can still inspect older state.

### Backpressure and high-volume output

Events are classified:

1. **Never drop:** lifecycle, Attention, permission, cancellation, Evidence invalidation, result, integration, and recovery events.
2. **Coalesce:** progress, repeated activity summaries, token-pressure updates, and rapid output segments.
3. **Externalize:** complete logs, large model streams, diffs, and Artifact bodies.

Initial Client queue targets:

- high-water mark: 500 pending events or 2 MiB encoded data;
- output segment refresh: at most 10 updates per second per visible execution;
- render cap: 30 frames per second for ordinary interaction;
- on overflow: preserve never-drop events, coalesce transient events, mark projection resync required.

### Projection rebuilding

Projection reducers are pure where practical.

A reducer receives:

```text
projection + ordered event → new projection
```

Reducers must be idempotent for duplicate events and reject impossible sequence regressions.

The TUI can rebuild from a snapshot plus later events. It must not poll Run processes to reconstruct truth.

## Performance and responsiveness targets

These are prototype targets, not production guarantees.

| Operation | Initial target |
| --- | --- |
| keyboard input to visible local feedback | p95 under 50 ms |
| domain event received to visible update | p95 under 200 ms |
| normal frame build and render | p95 under 33 ms |
| terminal resize response | under 100 ms |
| open Run tree with 1,000 historical Runs | under 200 ms |
| filter 1,000 Run summaries | under 100 ms |
| attach to 10 active Runs from current snapshot | under 500 ms |
| replay 1,000 bounded events | under 1 second |
| open first page of a local Artifact | under 300 ms excluding disk stall |
| recover Client focus after reconnect | under 500 ms after projection ready |

The prototype must remain usable with:

- 10 active Runs, even though initial scheduling limits active Children to three;
- 1,000 historical Run summaries;
- transcript history externalized and paged;
- command-output bursts of 200 events per second before coalescing;
- slow disk reads that do not block input or rendering;
- slow model output that does not force animation.

The Client keeps only bounded recent transcript segments, visible list slices, and loaded Artifact pages in active memory.

## Accessibility

### Required

- full keyboard operation;
- text labels and ASCII fallback for every status symbol;
- configurable color and contrast;
- `--no-color` and `--ascii`;
- reduced animation and no-animation setting;
- stable focus order;
- context-sensitive key help;
- copyable error and status text;
- configurable absolute, relative, or local timestamps;
- narrow layout;
- no rapidly changing full-screen region by default;
- paging instead of unbounded scrolling;
- a plain CLI text alternative for every essential action.

### Screen readers

Full-screen terminal interfaces can work poorly with terminal screen readers because redraws replace large regions.

Kiln must:

- offer non-interactive CLI equivalents;
- support a reduced-update mode;
- keep status text stable;
- avoid decorative animation;
- expose structured text output;
- test at least one supported terminal and screen-reader combination before claiming compatibility.

Kiln does not claim full accessibility before testing.

## ExRatatui evaluation

### Decision

Use ExRatatui 0.11.x for the first vertical TUI prototype behind a Kiln-owned renderer behaviour.

Pin the accepted version during implementation. Do not expose ExRatatui widget or event types in domain modules or public interface contracts.

### Requirement fit

| Requirement | Assessment |
| --- | --- |
| Keyboard handling | Supported through key events and injectable test events. |
| Mouse handling | Supported. Keyboard remains authoritative. |
| Resize handling | Supported through resize events and headless injection. |
| Streaming updates | OTP messages and reducer or callback updates can render projected events. |
| Scrollable transcript | Paragraph, Scrollbar, WidgetList, and viewport slicing can implement bounded transcript pages. |
| Markdown | Markdown widget exists. Full fidelity is not required initially. |
| Code blocks and syntax | CodeBlock support exists. Initial prototype can use plain styled text when needed. |
| Overlays | Clear, Popup, Block, and layout primitives can implement overlays. |
| Tables and lists | Supported. |
| Trees | No Kiln-specific tree widget is required. Build the Run tree from List or WidgetList rows. |
| Forms and input | TextInput and Textarea exist. Kiln still owns target and mode semantics. |
| Clipboard and paste | Bracketed paste events and documented clipboard guidance exist. Paste safety remains Kiln policy. |
| Unicode | Rich text and terminal cells support Unicode; Kiln requires ASCII fallback and terminal testing. |
| Headless testing | Headless terminal, test mode, event injection, buffer assertions, and runtime snapshots exist. |
| Snapshot testing | Cell and buffer output can support carefully bounded golden tests. |
| SSH | Supported by the framework but deferred for Kiln's first local interface. |
| Performance | Diff rendering, render suppression, list slicing, and telemetry support the prototype. |
| OTP fit | Supervised callback and reducer runtimes fit Client lifecycle and event subscriptions. |
| Maintenance | The project is active but young and pre-1.0. |
| API stability | Pre-1.0. Kiln must isolate it and pin the version. |
| Documentation | Current guides cover architecture, testing, performance, paste, transports, and telemetry. |
| Accessibility | Terminal limitations remain. The library does not prove Kiln accessibility. |

### Risks

1. ExRatatui is young and pre-1.0.
2. It crosses a Rustler NIF boundary.
3. Precompiled NIF distribution adds supply-chain and platform concerns.
4. Terminal and Unicode behavior varies by emulator.
5. Framework examples can encourage renderer-owned state if used without Kiln boundaries.
6. Full Markdown, screen-reader behavior, and large-history behavior need Kiln-specific tests.

### Required mitigations

- dependency review before addition;
- exact version pin in the prototype;
- checksum and precompiled-binary review;
- macOS arm64 and Linux x86_64 smoke tests;
- renderer behaviour and pure screen-model boundary;
- no ExRatatui types in domain events or contracts;
- headless navigation, resize, duplicate-event, and crash-isolation tests;
- plain CLI fallback;
- telemetry for render and event lag;
- a documented removal path.

### Exit strategy

`Kiln.Interface.TerminalRenderer` owns a renderer behaviour.

A replacement framework must implement:

- start Client surface;
- receive a screen model;
- emit normalized input intents;
- render narrow and wide layouts;
- report resize, paste, keyboard, and mouse events;
- provide headless test support or a compatible adapter.

Domain commands, Run projections, navigation semantics, Attention, and CLI output remain unchanged if ExRatatui is replaced.

No concrete blocker affects the first useful interface. Broad framework comparison stops here.

## Elixir and OTP component map

```text
Kiln.Application
├── durable domain and execution supervisors
├── Kiln.Interface.Supervisor
│   ├── Kiln.Interface.ProjectionService
│   ├── Kiln.Interface.EventBus
│   ├── Kiln.Interface.ClientRegistry
│   ├── Kiln.Interface.ClientSupervisor
│   │   ├── ClientSession
│   │   └── TerminalRenderer
│   └── Kiln.Interface.TaskSupervisor
└── Run, Command, Tool, Git, and Evidence supervisors remain separate
```

### `Kiln.Interface.ProjectionService`

State owned:

- reconstructible hot Session and Run projections;
- latest durable sequence by Session;
- snapshot cache and replay cursors;
- subscription metadata.

Why a process is required:

- consumes event notifications;
- serializes projection updates;
- serves concurrent Clients;
- coordinates replay and stale detection.

Durable recovery source:

- append-oriented journal, domain queries, and current Repository observations.

Restart:

- rebuild ETS tables and snapshots;
- publish a new projection generation;
- Clients resynchronize.

Subscriptions:

- receives durable-event notifications;
- publishes bounded projection updates.

Failure isolation:

- supervised separately from Run and execution processes;
- failure cannot stop active Runs.

Scope:

- shared.

### `Kiln.Interface.EventBus`

State owned:

- transient subscribers and delivery backpressure only.

Implementation:

- start with an internal event bus using OTP primitives.
- Do not add Phoenix solely for `Phoenix.PubSub`.
- Reevaluate Phoenix.PubSub when Phoenix is already an accepted dependency or cross-node semantics require it.

Durable recovery source:

- none. The journal is durable.

Restart:

- subscribers reconnect and replay from cursors.

Scope:

- shared transient infrastructure.

### `Kiln.Interface.ClientRegistry`

Use:

- active Client IDs and process lookup;
- duplicate Client detection;
- metrics.

Candidate primitive:

- `Registry`.

It does not store authoritative Client or Run state.

### `Kiln.Interface.ClientSupervisor`

Use:

- dynamically supervise active interactive Clients.

Candidate primitive:

- `DynamicSupervisor`.

It exists because Clients have independent lifecycles. It does not mirror the Run graph.

### `Kiln.Interface.ClientSession`

State owned:

- focused Run;
- selected Run;
- navigation history;
- active overlay;
- scroll and panel state;
- composer draft;
- last applied sequence;
- local preferences.

Why a process is required:

- owns concurrent input, subscriptions, timers, and Client lifecycle.

Durable recovery source:

- optional Client-state record plus shared projection.
- drafts remain local unless explicitly saved.

Restart:

- reconnect, load saved convenience state, validate focus, resubscribe, replay.

Failure isolation:

- one Client failure cannot affect another Client or a Run.

Scope:

- client-local.

### `Kiln.Interface.TerminalRenderer`

State owned:

- terminal handle;
- current frame and dimensions;
- normalized input event adapter;
- no durable Run state.

Implementation:

- ExRatatui behind `Kiln.Interface.TerminalRenderer` behaviour.

Restart:

- terminal restored;
- ClientSession survives when possible or reconnects;
- active Runs continue.

Failure isolation:

- renderer runs under the Client branch, not Run supervision.

Scope:

- client-local.

### `Kiln.Interface.TaskSupervisor`

Use:

- bounded Artifact reads;
- diff formatting;
- syntax highlighting;
- expensive screen-model derivation;
- snapshot compression.

Candidate primitive:

- `Task.Supervisor`.

Tasks are async and unlinked to the Client process. Results carry request IDs and are discarded when stale.

### ETS

Use ETS for reconstructible hot projections and indexes:

- Run summaries;
- Attention index;
- event cursor;
- search and filter keys;
- bounded transcript segment cache.

ETS is not durable and is rebuilt after restart.

### Plain data

Use structs and pure modules for:

- screen models;
- wireframe regions;
- Run-tree rows;
- breadcrumb construction;
- child-card view data;
- Attention prioritization;
- CLI envelopes;
- key intents;
- layout decisions;
- event reducers.

Do not create a GenServer for a widget, card, breadcrumb, pane, list row, Artifact page, or Receipt.

### Telemetry

Emit `:telemetry` for:

- event-to-projection latency;
- projection-to-render latency;
- frame build and draw duration;
- event queue depth;
- coalesced and dropped transient events;
- replay count and duration;
- snapshot size and rebuild time;
- stale projection duration;
- renderer crashes;
- Artifact page load duration;
- input-to-command latency.

Metrics use IDs, counts, durations, and classes, not sensitive transcript content.

## Test strategy

### Pure state and projection tests

Test:

- ordered event reduction;
- duplicate and delayed events;
- snapshot plus replay;
- Run-tree construction;
- stable selection;
- breadcrumb truncation and Parent path;
- Child cards for every lifecycle and Verifier outcome;
- Attention priority and allowed actions;
- Evidence freshness;
- narrow layout decisions;
- key-to-intent mapping;
- permission response validation;
- public CLI envelope encoding;
- completion-stage labels.

### Headless interaction tests

Use ExRatatui test mode and event injection for:

- enter Child;
- return to Parent;
- reach Root;
- navigate siblings;
- open and filter Run tree;
- respond to a question;
- open permission details;
- prove `Enter` does not approve;
- approve through the explicit action;
- deny;
- pause and resume;
- cancel with confirmation;
- reconnect after interruption;
- preserve focus while unrelated events arrive;
- resize among wide, standard, narrow, and constrained layouts;
- handle duplicate, delayed, and replayed events;
- recover from stale projection;
- keep current Run target distinct from selected Run;
- prevent renderer crash from affecting simulated Runs.

### Golden tests

Use small intentional snapshots for:

- main screen at 120, 80, and 50 columns;
- running, completed, failed, blocked, orphaned, and stale Child cards;
- Attention question and permission screens;
- completion summary;
- recovery screen;
- ASCII and no-color modes.

Snapshots are not the only behavioral proof.

### Property and state-machine tests

Evaluate properties:

- focus always references a visible Run or a deterministic fallback;
- Parent navigation is always available for a non-root Run;
- Root navigation always reaches the Session Root;
- duplicate replay is idempotent;
- sequence regression never mutates projection;
- selecting a Run never retargets composer input;
- navigation never changes Run state;
- permission approval cannot use generic activation;
- one Attention resolution wins;
- stale Evidence never renders as current;
- terminal width never removes access to Parent, Root, Attention, and composer.

### Integration tests

Test:

- SQLite restart and projection reconstruction;
- multiple Clients with independent focus;
- shared Attention resolution;
- CLI and TUI consistency;
- local runtime attach and disconnect;
- Command cancellation;
- Artifact page loading;
- permission enforcement;
- projection gap recovery;
- renderer crash isolation;
- dirty worktree preservation;
- orphan recovery.

## First vertical prototype

### Purpose

Prove this question:

> Can a user understand, navigate, control, and recover a small graph of concurrent Runs without losing conversational flow?

### Fixture

The deterministic fixture contains:

- one Root Run;
- two or three Child Runs;
- one running Scout;
- one blocked Scout;
- one completed Verifier;
- one depth-two Child;
- one simulated streaming transcript;
- one simulated Command;
- one permission request;
- one global Attention item;
- one Artifact;
- one Evidence record;
- one Receipt;
- one stale-Evidence event;
- one pause, resume, and cancellation flow;
- one restart and projection reconstruction.

### Required interactions

- open Root Run;
- enter each Child;
- return to Parent;
- reach Root;
- navigate siblings;
- open Run tree;
- open Attention inbox;
- answer a question;
- review and deny or approve a permission request through explicit action;
- inspect Command summary and Artifact output;
- inspect Evidence and Receipt;
- observe stale Evidence;
- pause and resume;
- cancel one Child without canceling Parent;
- resize the terminal;
- crash and restart the renderer;
- restart the local runtime projection and recover state.

### Not required

- real model;
- MCP;
- ACP;
- LSP;
- browser automation;
- real Git mutation;
- remote service;
- full Markdown;
- inline images;
- embedded terminal multiplexer;
- production styling;
- plugin widgets;
- dozens of active Runs.

## Initial implementation boundary

Include:

- one local Project;
- local runtime endpoint;
- one Root Run;
- maximum three active Child Runs;
- deterministic simulated events;
- conversation-first main screen;
- breadcrumb;
- Child cards;
- Run-tree overlay;
- optional wide Run-tree panel;
- global Attention inbox;
- keyboard-complete navigation;
- basic mouse;
- input composer with explicit target and modes;
- Command, change, Evidence, Artifact, and Receipt inspection;
- bounded streaming and Artifact externalization;
- durable restart and replay;
- CLI inspection and control commands;
- JSON and JSONL output;
- ExRatatui renderer boundary;
- headless tests.

Explicitly exclude:

- production model integration;
- rich dashboards;
- arbitrary pane layouts;
- plugin-defined widgets;
- full IDE behavior;
- inline image rendering;
- complex charts;
- multi-user collaboration;
- remote web Client;
- AG-UI;
- ACP synchronization;
- complete Markdown fidelity;
- embedded terminal multiplexing;
- extensive theming;
- custom animation systems;
- remote SSH TUI;
- dozens of concurrent visible Runs.

## Acceptance criteria

- **P0-W12-AC01:** The main screen always identifies Project, current Run, Run state, breadcrumb, Attention, composer target, Parent action, and Root action.
- **P0-W12-AC02:** Supporting detail is available on demand without replacing the conversation-first center.
- **P0-W12-AC03:** The current Run and selected Run are separate Client states.
- **P0-W12-AC04:** A user can enter a Child, return to Parent with `Alt+Left`, navigate siblings, and reach Root with `Alt+Home`.
- **P0-W12-AC05:** Starting or finishing a background Child never changes Client focus automatically.
- **P0-W12-AC06:** Blocked Children create global visible Attention.
- **P0-W12-AC07:** Simple questions can be answered from the inbox without entering the Child.
- **P0-W12-AC08:** Permission requests show scope and effects and cannot be approved through generic `Enter`.
- **P0-W12-AC09:** Destructive actions require action-specific confirmation.
- **P0-W12-AC10:** Activity, Evidence, and Receipts use distinct labels and views.
- **P0-W12-AC11:** Proposed, applied, verified, accepted, integrated, and delivered states remain distinct.
- **P0-W12-AC12:** Git and worktree state is available without dominating the main screen.
- **P0-W12-AC13:** Evidence invalidation immediately produces a stale label and Attention when blocking.
- **P0-W12-AC14:** Shared and client-local state are explicitly separated.
- **P0-W12-AC15:** Concurrent Client commands use revisions and idempotency rules.
- **P0-W12-AC16:** Reconnect uses snapshot and replay and visibly marks stale projections.
- **P0-W12-AC17:** Restart preserves Runs, Attention, dirty worktrees, Artifacts, Evidence, and Receipts.
- **P0-W12-AC18:** Orphaned and corrupt states cannot render as success.
- **P0-W12-AC19:** The narrow layout retains transcript, composer, Run tree, Attention, Parent, Root, and approval or denial access.
- **P0-W12-AC20:** Every essential action has a keyboard and CLI path.
- **P0-W12-AC21:** Duplicate, delayed, and replayed events cannot produce false state.
- **P0-W12-AC22:** Renderer failure cannot terminate active Runs.
- **P0-W12-AC23:** OTP processes own lifecycle, subscriptions, timing, or failure isolation only. Widgets remain data.
- **P0-W12-AC24:** The first prototype uses deterministic events and proves navigation, Attention, control, inspection, resize, and recovery.
- **P0-W12-AC25:** ExRatatui types remain outside domain contracts and modules.
- **P0-W12-AC26:** The CLI provides text, JSON, and JSONL without exposing persistence schemas.
- **P0-W12-AC27:** Performance targets use bounded projections, pagination, lazy loading, and output externalization.
- **P0-W12-AC28:** Accessibility claims remain limited to tested behavior.
- **P0-W12-AC29:** No production model integration is added by this planning pass.
- **P0-W12-AC30:** Later planning is updated so Phase 1 proves this deterministic interface before provider-backed delegation.

## Explicit exclusions

This design does not accept:

- Agent-first navigation;
- a permanent monitoring dashboard as the default;
- one pane per Child;
- automatic focus changes when Children start or finish;
- copied Child transcripts in Parent Runs;
- color-only status;
- generic `done`, `success`, or `complete` labels;
- keypress handlers that mutate domain state directly;
- renderer-owned durable state;
- one GenServer per widget;
- Run graph mirroring in the supervision tree;
- screen hierarchy mirroring in the supervision tree;
- implicit approval through `Enter`;
- navigation that pauses, cancels, merges, or changes ownership;
- unbounded output in active TUI memory;
- automatic cleanup of dirty or uncertain work;
- ExRatatui types in the domain model.

## Deferred capabilities

- real model streaming;
- model-backed Scout and Verifier;
- writing Child role;
- ACP synchronization;
- AG-UI;
- Phoenix web Client;
- remote multi-user Clients;
- SSH transport;
- arbitrary layouts;
- plugin widgets;
- full Markdown and syntax fidelity;
- inline images;
- terminal multiplexing;
- embedded shell;
- collaborative cursors;
- remote runtime;
- cloud Session service;
- advanced themes;
- animation;
- charts;
- voice input;
- dozens of concurrent active Runs;
- persistent unsent drafts across machines.

## Required changes to later planning

1. Add `kiln.interface/v0` public event, snapshot, Client-state, and CLI-result contracts to Phase 1 contract consolidation.
2. Implement projection reducers before the ExRatatui renderer.
3. Add a deterministic local runtime endpoint that survives Client disconnect.
4. Expand the Phase 1 CLI package into CLI and TUI projection, control, replay, and recovery.
5. Prove simulated Root, Scout, blocked Child, and Verifier flows before a live provider.
6. Add global Attention race tests and expected-revision commands.
7. Add renderer crash-isolation tests.
8. Add ExRatatui dependency review and platform smoke tests before adding the dependency.
9. Keep Phoenix, ACP, and AG-UI after the native event and projection model.
10. Keep writing Child interfaces deferred until a writing role is accepted.

## Planning closeout

### Files inspected

Kiln authorities:

- `README.md`;
- `docs/ARCHITECTURE.md`;
- `docs/INTERNAL-DOMAIN-MODEL.md`;
- `docs/RUN-MODEL.md`;
- `docs/DELEGATED-WORK.md`;
- `docs/PROJECT-STEWARDSHIP.md`;
- `docs/CAPABILITY-INTEGRATION.md`;
- `docs/CONTEXT-SYSTEM.md`;
- `docs/GIT-CHANGE-ISOLATION.md`;
- `docs/SECURITY-MODEL.md`;
- `docs/ROADMAP.md`;
- `docs/PROJECT-INVARIANTS.md`;
- domain, execution, delegation, Git, Context, Capability, and Evidence contracts;
- ADRs 0004, 0005, 0007, 0010, 0013, and 0014.

ExRatatui sources:

- package project definition and version;
- current module and widget inventory;
- architecture guide;
- testing guide;
- performance guide;
- paste and clipboard guide;
- telemetry and transport documentation.

### Files changed

- `docs/CLI-TUI.md`;
- `docs/contracts/kiln-interface.schema.json`;
- `docs/decisions/0015-run-first-event-projected-terminal-interface.md`;
- `docs/work/P0-W12-cli-tui-design.md`;
- `README.md`;
- `docs/ROADMAP.md`;
- `docs/contracts/README.md`;
- `docs/decisions/README.md`.

### Existing decisions preserved

- Run is the primary durable execution unit.
- Every delegated Task creates a Child Run.
- Focus is client-local.
- Attention is global and depth-independent.
- Run lineage is not OTP supervision.
- Child Context and grants are independent.
- Scout and Verifier are the only initial Child roles.
- Verifiers cannot repair evaluated work.
- Git and the filesystem remain source truth.
- One writable worktree has one mutation owner.
- Evidence binds to exact state and can become stale.
- Interfaces consume domain commands, queries, events, and projections.
- SQLite and the event journal own durable recovery.
- CLI remains independent of Phoenix.
- External protocols remain adapters.

### New decisions accepted

- CLI and TUI are the initial terminal interfaces.
- The main screen is conversation-first and Run-first.
- `Alt+Left` is the invariant Parent action.
- `Alt+Home` is the invariant Root action.
- ExRatatui 0.11.x is selected for the first prototype behind a renderer behaviour.
- The reducer or callback runtime can manage Client-local state only.
- A shared projection service and client-local sessions separate shared and local state.
- The first prototype includes deterministic simulated Runs, Attention, Evidence, Receipts, resize, cancellation, and restart.
- CLI text, JSON, and JSONL are public interface contracts.
- Generic `Enter` never approves permission or destructive actions.
- High-volume output is coalesced and externalized.

### Decisions modified

- “Initial interface: command-line interface” now means a complete CLI plus an optional full-screen TUI.
- The Phase 1 basic CLI projection expands to deterministic CLI and TUI projection, navigation, control, replay, and recovery.
- The architecture projection branch now includes a shared projection service and supervised Client sessions.
- P0 exit moves after P0-W12 and the Phase 1 order reconciliation.

### Decisions rejected

- Agent-first navigation.
- A permanent Run dashboard.
- Automatic focus changes.
- Renderer-owned domain state.
- Keypress-to-domain coupling.
- One process per widget.
- Color-only status.
- Hidden approval.
- Full logs in the main transcript.
- Broad TUI-framework comparison after ExRatatui met the first-prototype requirements.

### Unknowns

- exact local runtime endpoint and service-launch mechanism;
- exact ExRatatui patch version at implementation time;
- terminal emulator support matrix;
- screen-reader behavior;
- exact retained transcript page size after measurement;
- whether `Registry` or `:pg` is the better first internal event bus implementation;
- exact public CLI naming and shell completion design;
- exact store-compaction window for event replay;
- whether Client-local state is persisted in SQLite or a separate local preference file.

### Deferred questions

- remote Clients and authentication;
- Phoenix and AG-UI projection reuse;
- ACP multi-client synchronization;
- SSH TUI;
- writing Child interaction;
- terminal multiplexing;
- plugin-defined views;
- collaborative editing;
- remote Artifact stores;
- framework replacement only if implementation exposes a concrete blocker.

### Prototype boundary

The prototype is one local runtime, one Project, one Root Run, at most three active Children, deterministic events, one blocked Child, one completed Verifier, conversation-first navigation, global Attention, inspection surfaces, pause, resume, cancel, resize, renderer restart, and durable projection recovery.

### Evidence supporting conclusions

- Accepted Kiln documents establish Run-first navigation, client-local focus, durable events, global Attention, independent Child Context, Git ownership, exact-state Evidence, and renderer-independent recovery.
- The ExRatatui 0.11.x package exposes keyboard, mouse, resize, paste, TextInput, Textarea, Markdown, CodeBlock, Popup, List, Table, WidgetList, supervised runtimes, telemetry, transport boundaries, and a headless backend with event injection.
- ExRatatui's performance guidance supports render suppression, viewport slicing, cell diffing, and supervised asynchronous work.
- The framework remains pre-1.0 and uses Rustler NIFs, which justifies version pinning, dependency review, platform smoke tests, and a Kiln-owned renderer boundary.
