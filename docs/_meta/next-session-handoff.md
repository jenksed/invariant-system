---
title: Next-Session Engineering Handoff
description: Compact handoff from WP-09 closeout to the next engineering session for Temper Workbench Alpha.
status: current
verified_at_commit: 222860d14dbc5fcfd0207f53ab12c5c4a30e09a7
source_paths:
  - docs/roadmap/t3-competitive-30-day/work-packages/wp-09-closeout.md
  - docs/_meta/post-wp09-product-direction.md
  - docs/status.md
audience:
  - developer
---

# Next-Session Engineering Handoff

This is the canonical handoff from the WP-09 closeout session to the next engineering session. It is intentionally compact: everything needed to resume work, nothing more.

## Base state

```text
CURRENT_BASE                  = 222860d14dbc5fcfd0207f53ab12c5c4a30e09a7
BRANCH                        = post-wp09/workbench-foundation
ACCEPTED WP-09 PRODUCT SHA    = 755696052cd3b122de906ab9690dfaf6811efeb6
ACCEPTED WP-09 SHORT SHA      = 7556960
WP-09 STATUS                  = ACCEPTED / CLOSED
DOCS STATUS                   = INTEGRATED / RECONCILED
```

`CURRENT_BASE` is the successor engineering starting point. It is NOT the accepted product identity — that is permanently `755696052cd3b122de906ab9690dfaf6811efeb6`.

## Post-acceptance followups (non-blocking, future work)

| # | Surface | Issue |
|---|---|---|
| 1 | `wp09-l5-reconnect.mjs` `RECONNECT_PRE_MUTATION` / `RECONNECT_MID_WORKFLOW` / `DISCONNECT_SAFETY` | `fabricated_completion` predicate inspects `f?.event?.kind` shape that does not match the actual `activity.notification` envelope; assertions are structurally trivial by negative form |
| 2 | `wp09-l5-reconnect.mjs` `CANONICAL_RESYNC` | Recorded as unconditional `true` rather than an explicit canonical-state equality check |
| 3 | `integration/scenarios/wp-09-five-tasks/run.py` Tasks 2–4 | Scenario name and description overstate direct exercise; Tasks 2–4 call `worker.propose` and assert P5 preservation, not the full bounded chain. The full chain is established by `m12_e1_composed_golden_path_test.exs` |

The underlying properties still hold; the harness assertions need strengthening. Documented in `wp-09-closeout.md`.

## Next objective

```text
NEXT OBJECTIVE = TEMPER WORKBENCH ALPHA
```

Target acceptance property:

> From a repository directory, an operator can start Temper with one obvious command, enter a persistent project-centric workbench, see the current governed Session and repository state, inspect live activity/changes/evidence, take required human actions, recover after disconnect, and hand source editing to Zed without transferring execution authority out of Kiln.

```text
temper .
```

should open a real project workbench that:

- identifies/opens the repository;
- connects to or starts the appropriate Kiln control surface;
- resumes governed Session state;
- projects canonical repository/workflow state;
- exposes live activity without treating events as truth;
- exposes proposed/current changes;
- exposes Verification/Evidence/Review/HumanDecision state;
- allows bounded human actions;
- survives reconnect;
- uses canonical resync;
- preserves Kiln authority;
- preserves Zed as editing surface rather than execution authority.

### Stretch (not in baseline)

Temper on the operator Mac connects to Kiln running against the repository on the other Mac.

### Hard prohibitions

Do not yet introduce:

- distributed scheduler;
- arbitrary agent DAG;
- worker pools;
- distributed database;
- arbitrary multi-agent trees;
- editor replacement;
- execution authority in Temper.

Preserve the seam now. Build those subsystems only when an acceptance property requires them.

## First action next session

```text
FIRST ACTION NEXT SESSION =
  bounded reconnaissance / acceptance-contract freeze for the Workbench
```

Do NOT begin Workbench implementation in the next session. Begin with:

1. Re-read `docs/_meta/post-wp09-product-direction.md` for accepted direction.
2. Re-read `docs/roadmap/t3-competitive-30-day/work-packages/wp-09-closeout.md` for evidence identities and defect history.
3. Re-read `docs/architecture/product-boundaries.md` and `docs/architecture/authority-flow.md` to confirm authority boundaries before designing Workbench seams.
4. Establish the Workbench acceptance contract:
   - required observable behavior;
   - required properties (canonical projection, live activity, bounded human actions, reconnect/recovery);
   - evidence modes (live, executable-test, composed-golden-path, independent-review, owner-HumanDecision);
   - non-blocking vs acceptance-blocking distinctions.
5. Freeze the contract before implementation, per the engineering-process gates in `docs/development/engineering-process.md`.

Do not authorize implementation beyond that first planning/recon gate unless the existing engineering process explicitly already authorizes it.

## Stable facts preserved across handoff

- Accepted product identity: `755696052cd3b122de906ab9690dfaf6811efeb6` (immutable).
- Kiln owns authority / execution / canonical governed state.
- Temper owns operator experience / projection / client surface.
- Activity/WebSocket is notification, not canonical truth.
- Canonical state is obtained by authoritative query/reconstruction, not event-history completeness.
- Distinct concerns: mutation, verification, Evidence, Review, HumanDecision, completion/projection. Do not collapse them.
- Review APPROVE is not HumanDecision. HumanDecision ACCEPT is the final authority.

## What NOT to assume

- The reconnect harness's PASS outcomes for the three negative properties are structurally weak; do not cite them as live demonstration of fabrication-rejection without first strengthening them.
- The five-task scenario's Tasks 2–4 do not directly drive the full chain; do not cite them as such.
- The compiled dispatch table is correct at HEAD; do not treat cowboy/ranch upgrades as a known risk.