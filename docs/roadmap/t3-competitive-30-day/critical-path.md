# Critical Path — September 30-Day (post-Pathfinder)

**Base:** PATHFINDER_HEAD_SHA = 7f947bc494218a1e73597419b0149a1bc477f3d7
**Target:** September 18, 2026 — T3-competitive operator environment
**Pathfinder complete:** WP-01..WP-06 + WP-03 decisions made

## Critical path (sequential dependencies)

```
WP-07 Kiln daemon                       ← Week 1 (blocks everything)
  ├─ adds Phoenix + Plug deps
  ├─ implements bounded Plug + WS service
  ├─ implements bounded reconnect
  └─ mix invariant serve lifecycle
        │
        ▼
WP-08 Persistent Session state            ← Week 2 (parallel after WP-07)
  ├─ Ecto + bounded migrations
  ├─ E_MUTATION_UNKNOWN_EFFECT bounded error class
  └─ restart reconciliation against authoritative observable state
        │
        ▼ (parallel)
WP-09 Temper RPC client     WP-10 Provider-runtime adapter
  ├─ HTTP + WS client        ├─ ≥1 agent-runtime adapter
  ├─ bounded reconnect        ├─ bounded subprocess via System.cmd
  └─ bounded activity stream  └─ bounded output extraction + content-validity gate
        │                            │
        └────────┬───────────────────┘
                 ▼
WP-11 Remote environment transport       ← Week 3
  ├─ SSH CLI invocation (T3 packages/ssh pattern)
  ├─ Tailscale CLI invocation (T3 packages/tailscale pattern)
  └─ bounded reconnect across machines
                 │
                 ▼
WP-12 Parent/child coordination          ← Week 4
  ├─ bounded child Session ownership
  ├─ bounded delegation preserves authority
  └─ parent-visible bounded child activity
                 │
                 ▼
WP-13 Whole-system dogfood                ← Week 4
  ├─ 5 distinct bounded tasks via Temper
  ├─ restart / stale / recovery scenarios
  ├─ remote dogfood
  └─ competitive gap closure → September release candidate
```

## Parallel candidates (no decisions consumed)

- M12-B recovery test path fix (parallel to WP-07)
- M12-C runtime Session persistence (parallel to WP-08)
- M12-D Temper operator surface UX (parallel to WP-09)
- M12-E Bench qualification CLI (parallel to WP-10)
- Evidence debt closure (always parallel-safe)
- Docs / architecture updates (always parallel-safe)

## Decision dependencies (Pathfinder outputs)

| Decision | Pathfinder output | Consumed by |
|---|---|---|
| Service boundary (HTTP+WS+Phoenix Channels) | WP-02 | WP-07, WP-09, WP-11 |
| Workspace/Git/recovery (extend bounded, no second truth) | WP-04 | WP-08, WP-11, WP-13 |
| Provider-runtime contract (direct + agent-runtime) | WP-03 | WP-10, WP-12 |
| Remote fast path (localhost → SSH → Tailscale) | WP-05 | WP-11 |
| OTP fast-track (use standard OTP/Elixir primitives) | WP-06 | WP-07, WP-08, WP-09, WP-10, WP-11, WP-12, WP-13 |

## Acceptance milestones (per week)

- **End of Week 1 (after WP-07):** local daemon boots; HTTP+WS accept connections; bounded reconnect; mix invariant serve works; bounded golden path runs via daemon
- **End of Week 2 (after WP-08/09/10):** 5 distinct bounded tasks via Temper with both providers; bounded restart preserved state; bounded recovery classification
- **End of Week 3 (after WP-11):** MacBook Air → MacBook Pro over bounded SSH/Tailscale; bounded state survives disconnect/reconnect
- **End of Week 4 (after WP-12/13):** whole-system dogfood; parent/child bounded coordination; September release candidate

## Schedule verdict

```
VERDICT = YES, WITH EXPLICIT CUTS

Conditions (all checkable):
  Pathfinder Days 1-4               = MET (WP-01..WP-06 + WP-03 done)
  WP-07 lands in Week 1             = PENDING (next gate)
  M12-A composed golden path via daemon = PENDING (Week 2 gate)
  All 5 evidence categories (per index.md O) = PENDING (Week 4 gate)

If WP-07 slips past Week 1: AT RISK (entire schedule cascades).
If Pathfinder findings not honored: NOT CREDIBLE WITHOUT EXPLICIT CUTS.
If WP-07 lands + bounded recovery works + both providers proven:
  ON TRACK (assuming explicit cuts from N. Risks and cuts are honored).
```
