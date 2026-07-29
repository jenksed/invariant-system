# CLI and Deferred TUI

**Document type:** Interface specification  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** Not implemented  
**Architecture authority:** `docs/ARCHITECTURE.md`

## Purpose

This document defines the permanent CLI and the entry conditions for a later TUI.

The CLI must support the complete first-month and version 0.1 workflows.

The TUI is deferred until runtime correctness, durable projections, and one real Child workflow exist.

The prior P0-W12 detailed TUI design remains in Git history as design input. Its simulated-Run-first sequence, three-active-Child assumption, and early ExRatatui selection no longer define implementation order.

# Interface principles

1. Interface state is not domain authority.
2. CLI and later Clients consume the same application commands and current projections.
3. Git, journal, policy, Evidence, and user decisions remain authoritative in their own boundaries.
4. Generic activation never approves permission, Patch application, cancellation, acceptance, merge, publication, or another destructive action.
5. Human text and structured output describe the same current state.
6. An interface crash cannot turn active work into success or cancel it implicitly.
7. Client-local focus, selection, history, scroll, layout, and drafts remain separate from shared Run state.
8. Large transcripts, logs, Patches, reports, and Receipts remain Artifacts or on-demand views.
9. Status labels preserve `PASS`, `FAIL`, `BLOCKED`, stale, canceled, failed, and orphaned distinctions.
10. The interface must disclose unavailable controls rather than hide or simulate them.

# First-month CLI

## User workflow

The CLI supports:

```text
open Repository
→ start Session and Task
→ inspect Root Run and current state
→ start bounded investigation
→ inspect Patch proposal
→ approve or reject exact Patch digest
→ apply accepted Patch
→ run registered verification
→ inspect Evidence by criterion
→ accept completion or continue
→ restart and resume
```

## Required actions

Names remain provisional until the accepted ticket plan, but the CLI must support equivalent actions for:

- initialize or open one Project;
- start one Session with objective and criteria;
- show Session, Task, and Root Run status;
- inspect current Repository observation;
- inspect Context package summary and disclosure decision;
- start or cancel model investigation;
- inspect Claims and source Evidence;
- inspect one Patch proposal and digest;
- approve or reject the exact Patch;
- apply the approved Patch;
- run one registered verification Command;
- inspect Command result and output Artifact references;
- inspect criterion `PASS`, `FAIL`, or `BLOCKED` status;
- inspect warnings, stale Evidence, unknown effects, and orphan state;
- accept completion or continue work;
- resume after restart;
- reconcile orphaned state.

## Output modes

The CLI provides:

- concise human-readable text;
- stable structured JSON for programmatic use;
- optional JSON Lines for ordered event or operation streams after those surfaces stabilize.

Structured output must not expose SQLite tables, internal process identifiers, provider handles, or protocol-specific internal objects.

## Exit status

Exit status communicates operation result, not Task completion by implication.

The exact code registry requires bounded implementation planning, but it must distinguish at least:

- success for the requested CLI operation;
- invalid input or usage;
- denied authority or Approval;
- not found or unavailable Resource;
- `FAIL` verification;
- `BLOCKED` verification;
- conflict or stale base;
- cancellation;
- orphaned or unknown effect;
- internal failure.

A CLI command that prints a failed criterion must not exit as though verification passed.

## Status projection

The first-month status view includes:

- Project and Repository identity;
- branch, commit, dirty state, and freshness;
- Session objective and criteria revision;
- Task and Root Run status;
- current workflow step;
- pending user decision;
- provider operation state;
- Patch proposal and application state;
- Command state and cleanup;
- Evidence status by criterion;
- Artifacts and Receipt references;
- failures, warnings, assumptions, unknowns, and exclusions;
- completion readiness.

The CLI does not need a permanent dashboard or metric wall.

## Composer and input

The first-month CLI can use explicit commands and bounded input prompts.

A free-form conversational composer is optional. It must not obscure:

- which Run receives input;
- whether input is user instruction, answer, Approval, or ordinary message;
- the exact proposed destructive action;
- the active objective and criteria revision.

Large paste or attachment handling is deferred unless the first model workflow requires it.

# Version 0.1 Child CLI

After P1-S04 and P1-S05, the CLI supports:

- list Root and Child Runs;
- inspect one Child;
- enter a Child-focused view;
- return to Root;
- inspect Child purpose, role, Context summary, grants, limits, status, activity, Attention, accounting, Artifacts, Evidence, and result;
- answer a Child question;
- approve or deny a bounded permission request through an explicit action;
- cancel a Child;
- inspect bounded result delivery;
- compare Root completion recommendation with Verifier `PASS`, `FAIL`, or `BLOCKED` result.

Version 0.1 has maximum depth one and one active Child.

## Navigation rules

- Root is always directly addressable.
- A Child identifies its Parent and Root.
- Entering or leaving a Child view changes client-local focus only.
- Navigation does not pause, cancel, approve, grant, mutate, verify, accept, or deliver work.
- Starting or completing a Child does not change focus automatically.
- Background never means hidden.

# Attention

Attention enters with the first Child workflow.

Attention can represent:

- question;
- permission request;
- conflict;
- failure;
- verification blocker;
- resource limit;
- orphan reconciliation;
- completion notification.

A blocking item shows:

- originating Run;
- category;
- requested decision;
- allowed responses;
- revision;
- resume state;
- creation time;
- escalation or cancellation rule.

Permission requests require a dedicated approval or denial action. Generic `Enter` or message submission cannot approve authority.

Notifications remain informational and do not block work.

# Patch and Command presentation

## Patch

The CLI distinguishes:

- proposed;
- awaiting Approval;
- approved;
- rejected;
- applied;
- conflicted;
- rolled back;
- failed;
- orphaned.

It shows:

- proposal digest;
- exact base state;
- affected paths;
- operation types;
- changed-region summary;
- policy and Approval status;
- rollback reference;
- observed result state.

The user must be able to inspect full Patch content on demand before Approval.

## Command

The CLI distinguishes:

- requested;
- authorized;
- running;
- timed out;
- canceled;
- failed;
- completed;
- cleanup incomplete;
- orphaned.

It shows:

- registered Command key and version;
- bounded argv summary;
- working directory;
- side-effect class;
- start and end time;
- exit or signal;
- timeout and cleanup;
- stdout and stderr Artifact references;
- normalized result;
- criteria evaluated.

Sensitive environment and secret values remain hidden.

# Evidence and completion presentation

The interface preserves these distinctions:

```text
proposed change
applied change
executed Command
verified criterion
user-accepted result
delivered external outcome
```

The status view must not collapse them into `done`.

For each criterion, show:

- required method;
- current `PASS`, `FAIL`, or `BLOCKED` result;
- Evidence reference;
- exact state binding;
- freshness;
- completeness;
- contradiction or warning when present.

Completion readiness explains every blocker.

A Receipt link is available after sealing. Receipt existence does not imply user acceptance or delivery.

# Interruption and recovery presentation

After restart, the CLI shows:

- last durable workflow step;
- current Repository observation;
- active or interrupted model and Command records;
- Patch application and rollback state;
- pending user decision;
- stale Evidence;
- unknown effects;
- required reconciliation action.

The CLI must not describe an uncertain effect as canceled, rolled back, verified, or complete.

Dirty or uncertain work remains visible until accepted cleanup.

# TUI entry conditions

The TUI enters only after:

1. P1-S01 through P1-S05 are complete;
2. CLI commands and structured results are stable;
3. durable projections and event ordering are implemented;
4. one real Scout and Verifier workflow creates useful navigation;
5. renderer failure isolation can be tested;
6. the selected library passes dependency, native-code, packaging, accessibility, and headless-test review;
7. a focused TUI slice and gate are accepted.

No TUI dependency is added before these conditions pass.

ExRatatui remains one research candidate. P0-W12 selection is not binding for the deferred TUI slice.

# Deferred TUI product shape

A later TUI can remain conversation-first while adding:

- current Run transcript and input area;
- breadcrumb and direct Root action;
- one bounded Child card;
- Run list or tree;
- global Attention view;
- Patch, Command, Evidence, and Receipt summaries;
- Context, authority, Repository, and recovery warnings;
- narrow-terminal fallback;
- keyboard-complete operation;
- text and symbols independent of color.

The TUI must not become a permanent dashboard filled with metrics and panels.

The first version does not need:

- arbitrary panes;
- many concurrent visible Runs;
- embedded terminal multiplexing;
- full Markdown fidelity;
- inline images;
- plugin widgets;
- extensive themes or animation.

# Renderer boundary

A later TUI uses:

```text
native application commands and projections
→ Kiln-owned view model
→ renderer behaviour
→ selected terminal library
```

Renderer types do not enter domain, persistence, Evidence, or public command contracts.

A renderer crash must not cancel or fail active Runs.

# Accessibility

CLI and later TUI shall:

- remain operable without color;
- use text labels for state;
- provide keyboard-complete actions;
- avoid animation as required information;
- expose complete details on demand;
- preserve stable ordering;
- avoid ambiguous generic destructive controls.

The deferred TUI requires a focused accessibility review before implementation.

# Multi-client and remote scope

Version 0.1 does not require multiple simultaneous Clients.

Client cursors, replay gaps, multi-client races, ACP, web, SSH TUI, and remote control remain deferred until one local CLI workflow is stable.

A later Client must consume the same native commands and projections and cannot write persistence directly.

# Interface testing

## CLI

Required tests include:

- command parsing and validation;
- human and JSON result equivalence;
- exit status by operation result;
- destructive-action confirmation and revision mismatch;
- status projection from fixtures;
- truncation and Artifact references;
- restart and orphan output;
- Child navigation after P1-S04;
- Attention response idempotency;
- verification and completion blocker explanations.

## TUI

A later TUI slice requires:

- pure view-model tests;
- normalized intent tests;
- headless renderer tests;
- golden narrow and standard layouts;
- keyboard navigation;
- duplicate and delayed event tests;
- renderer-crash isolation;
- accessibility checks;
- CLI and TUI projection equivalence.

# Non-goals

The interface does not:

- define domain state from screen layout;
- make the Run graph the first product proof;
- require a TUI for complete operation;
- approve destructive action through generic activation;
- expose SQLite schemas;
- expose complete Tool catalogs;
- hide failed or blocked verification;
- turn a renderer into a Run process owner;
- require Phoenix or a browser;
- optimize for the number of panes, logs, Agents, or Runs.
