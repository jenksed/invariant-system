---
title: Security Advisory — cowlib 2.19.0
description: Classification of EEF-CVE-2026-43969 / 43971 / 43966 against the M4-Q1C repair candidate. No dependency mutation.
status: current
verified_at_commit: 11ba660037f33c87f8bbbf671b4b94873d7e6b3f
source_paths:
  - products/kiln/mix.lock
  - products/kiln/lib/kiln/daemon.ex
  - products/kiln/lib/kiln/activity/websocket.ex
audience:
  - developer
  - operator
---

# Security Advisory — cowlib 2.19.0

## Advisories

- `EEF-CVE-2026-43969 / CVE-2026-43969` — LOW
- `EEF-CVE-2026-43971 / CVE-2026-43971` — MEDIUM
- `EEF-CVE-2026-43966 / CVE-2026-43966` — MEDIUM

These advisories were reported by `mix deps.get` against the repair candidate. The repair candidate pins `cowlib 2.19.0` via `cowboy 2.18.0` (`mix.lock`).

## Reachability analysis

`cowlib` is reachable in the candidate via the following paths:

1. `products/kiln/lib/kiln/daemon.ex` — `mix invariant serve` boots `Plug.Cowboy` which links `:cowboy_router` and `:cowlib` to expose the bounded RPC router.
2. `products/kiln/lib/kiln/activity/websocket.ex` — `@behaviour :cowboy_websocket`; the bounded activity stream WebSocket handler is loaded into Cowboy at daemon boot.

Both paths are operator-exposed in `integration/scenarios/wp-09-temper-rpc/run.sh` and the Tier 2 scenarios. The Kiln daemon is the canonical entry point for both the local Temper client (`mix invariant serve`) and the remote operator topology referenced in the WP-09 closeout.

## Classification

**REQUIRES_SEPARATE_SECURITY_REVIEW.**

Reasoning:

- `cowlib` IS reachable in the candidate's runtime paths (the Kiln daemon listens via Cowboy on `:cowlib` transport).
- No directly exploitable current path has been demonstrated within the M4-Q1C repair scope.
- The CVE severity classifications (LOW and MEDIUM) and the affected component (low-level HTTP parsing) warrant a separate review pass that evaluates operator network exposure, request-shaping threats, and authentication boundary coverage.
- The M4-Q1C repair scope explicitly forbids broad dependency upgrades and unrelated changes. A `cowlib` upgrade would force a Cowboy upgrade and would expand the change beyond the proven integration/qualification defects.

## Disposition

- No dependency mutation in this lane.
- The repair candidate remains at `cowlib 2.19.0` (current `mix.lock`).
- A separate security-review work package should:
  - Read the three CVE descriptions from the EEF advisory feed.
  - Map each CVE to the specific `cowlib` symbol that handles the affected HTTP/WebSocket shape.
  - Confirm whether the Kiln daemon's RPC router and activity WebSocket exercise the affected shapes.
  - Decide on an upgrade window (Cowboy 2.x → 2.y, or Erlang `cowlib` upstream, or both).
- Promotion qualification does NOT block on this advisory; the M4-Q1C defects are unrelated.

## What this lane did not do

- Did not upgrade `cowlib` or `cowboy`.
- Did not introduce request-hardening changes in the RPC router or activity handler.
- Did not add network-firewall or rate-limiting scope that belongs to a different work package.