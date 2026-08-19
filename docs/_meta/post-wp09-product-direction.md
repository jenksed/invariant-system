---
title: Post-WP-09 Product Direction
description: Accepted near-term product direction for Temper Workbench, durable operator recovery, and distributed Kiln authority.
status: planned
verified_at_commit: fed26fcc8b7598a56ce86e47c99d0154e6b46436
source_paths:
  - invariant.boundaries.json
  - docs/architecture/product-boundaries.md
  - docs/architecture/authority-flow.md
  - docs/workflows/recovery.md
audience:
  - developer
  - operator
---

# Post-WP-09 Product Direction

This page records accepted roadmap intent. It is **not implementation evidence** and does not advance any capability on the [current status](../status.md) page.

The direction begins after WP-09 is accepted against its own immutable candidate/evidence and explicit human decision. Until that acceptance is recorded in the repository context being documented, WP-09-dependent capabilities remain planned or otherwise conservatively classified.

## Target claims

### Product entry point

```text
temper .
```

should turn the current repository into an operable Invariant project workbench: project discovery, current governed Session visibility, activity/evidence traversal, changes, verification, review, explicit human attention, and governed human actions.

### Durable operator model

Temper may disappear and later reconstruct the current governed Session from Kiln. Temper-local persistence must not become a second canonical workflow store.

### Distributed authority

Temper should be able to operate separately from the repository/execution host, exercise governed human authority through Kiln, disconnect, and later reconstruct current Session state without transferring execution authority to the operator machine.

## Stable current boundaries and planned control behavior

The current canonical boundary assigns Temper `operator experience` and `projection`. It does not currently assign Temper mutation/execution authority or `governed action initiation` as an owned responsibility.

The roadmap plans richer control-surface behavior without changing the intended authority relationship:

- Kiln owns canonical governed Session/execution truth and evaluates runtime authority.
- Temper is planned to initiate governed requests and then project the authoritative result; that is planned control-surface behavior, not current ownership.
- Zed or another editor may receive editing/context handoff without receiving Kiln execution authority.
- Filesystem path, project identity, repository identity, Session identity, Kiln identity, execution host, and operator host are distinct concepts.
- Recovery means reconstruction from authoritative state and explicit reconciliation of uncertain effects, not merely restoring UI state.

If Workbench implementation requires a genuine canonical ownership change, freeze and review that architecture decision before dependent implementation proceeds. Do not alter the canonical boundary solely to make this roadmap appear current.

## T3 Challenge preservation

The T3 Challenge / 30-day competitive program remains a strategic program layered over the product roadmap. Workbench, recovery, remote operation, and other product capabilities may advance that program, but the product roadmap must not be renamed into or rewritten around the T3 Challenge.

Existing T3 Challenge artifacts are protected program records. Preserve their milestones, failures, incomplete work, and historical intent. Prefer additive cross-links from current roadmap pages. Do not modify a protected T3 record unless a later instruction explicitly authorizes that file.

See [Strategic programs](../roadmap/strategic-programs.md) for the documentation relationship and [Temper roadmap](../roadmap/temper.md) for the near-term operator sequence.
