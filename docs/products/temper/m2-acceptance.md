---
title: M2 — Temper Durable Acceptance Record
description: Provenance, candidate SHA, and current regression authority for the M2 milestone.
status: accepted
branch: work/temper-workbench-alpha
m1_baseline: 5d152e7
m2_candidate: 4fdaa00
regression_authority: m2_probe.sh (real-daemon scenario)
audience:
  - developer
  - operator
---

# M2 — Temper Durable Acceptance Record

## Provenance reconciliation

The previously circulated M1 baseline SHA `7d3a8d9` is **not present** in this repository — not in any branch, tag, reflog, or worktree. `git rev-parse 7d3a8d9` returns `unknown revision or path not in the working tree` from every checked-out worktree. There is therefore no recoverable "human-accepted M1 baseline at 7d3a8d9" to compare against.

The actual M1 HEAD on `work/temper-workbench-alpha`, recoverable from `git log work/temper-workbench-alpha`, is:

| Slot | SHA | Subject |
|------|-----|---------|
| **accepted M1 baseline** | `5d152e7` | test(temper): add M1 real-daemon probe harness |
| M2 implementation parent | `5d152e7` | (same — M2 work branched from the M1 HEAD) |
| M2 comparison base | `5d152e7` | (same) |

`7d3a8d9` is recorded as an erroneous reference in upstream project documentation; the actionable M1 acceptance is at `5d152e7`. Future agents should compare against `5d152e7` unless repository evidence establishes otherwise.

## M2 candidate identification

The current HEAD of `work/temper-workbench-alpha` is the M2 acceptance candidate. Pinned at the moment M2 closes (front matter field `m2_candidate:`). Update this field whenever the candidate is rebased or amended.

## M2 acceptance property

> Temper may disappear and return without losing canonical work, inventing recovery state, or becoming an authority source.

Core invariant:

> **TEMPER OWNS NO INDISPENSABLE WORKFLOW TRUTH.**

## M2 slices — required evidence

### M2-A ACTIVE WORK RECONNECT

Required shape:

```
real Session
→ enter genuinely active/running governed work (session.resume ready → running)
→ capture canonical session/work identity (session_id, run_state=running,
   session_revision, projection_digest)
→ terminate only the Temper client
→ Kiln remains alive
→ fresh Temper process
→ project.open
→ session.query
→ same canonical Session
→ current canonical work/state reconstructed (run_state=running,
)
→ no client-carried workflow identity required
```

Evidence fields emitted by `m2_probe.sh`:

```
M2_A_INITIAL_SESSION_ID
M2_A_INITIAL_RUN_STATE          = running
M2_A_INITIAL_SESSION_REVISION
M2_A_INITIAL_DIGEST
M2_A_CLIENT_TERMINATED          = ok
M2_A_EXPECTED_SESSION_ID
M2_A_EXPECTED_RUN_STATE         = running
M2_A_EXPECTED_SESSION_REVISION
M2_A_RECONNECT                  = PASS | FAIL
M2_A_RECONNECTED_SESSION_ID
M2_A_RECONNECTED_RUN_STATE      = running
M2_A_RECONNECTED_SESSION_REVISION
M2_A_RECONNECTED_DIGEST
M2_A_RECONNECTED_KILN_HOME
M2_A_ADVANCED_DURING_ABSENCE    = (optional; revision delta if Kiln
                                    advanced state during client absence)
```

The fresh node process derives `session_id`, `session_revision`, `run_state`, and `projection_digest` from `project.open` + `session.query` alone. No client-side workflow truth is required to reconstruct.

### M2-B PENDING DECISION RECONNECT

```
real Session in :running (carried from M2-A)
→ review-propose (canonical pending_decision_recorded/v1 via Kiln CLI)
→ run_state advances to :waiting_for_user
→ capture canonical decision_envelope (plan_ref, patch_ref,
   result_state_digest, review_ref) and pending_decision.id
→ terminate Temper
→ fresh Temper
→ project.open
→ session.query
→ same canonical pending_decision
→ same canonical decision_envelope
→ submitHumanDecision via the bounded human.decide RPC
→ run_state advances to :ready
```

Evidence fields: `M2_B_PENDING_DECISION_ID`, `M2_B_*_REF_ID`, `M2_B_RESULT_STATE_DIGEST`, `M2_B_RECONNECTED_DECISION_ID`, `M2_B_FINAL_RUN_STATE=ready`.

### M2-C STALE CLIENT RECOVERY

```
canonical envelope captured from session.query
→ mutate result_state_digest (simulate stale client memory)
→ submitHumanDecision with the stale envelope
→ Kiln rejects with bounded code decision_context_mismatch
   (lib/kiln/workflow.ex:require_decision_context_match/2)
→ connection.resync('reconnect')
→ canonical envelope unchanged from Kiln
```

Evidence fields: `M2_C_STALE_REJECT=PASS`, `M2_C_STALE_ERROR_CODE=decision_context_mismatch`, `M2_C_REFRESH_RESULT=PASS`, `M2_C_REFRESHED_DIGEST`.

### M2-D KILN RESTART / REPLAY

```
canonical state in journal
→ SIGKILL first daemon (lsof + kill -9)
→ spawn m2_kiln_restart.exs against same KILN_HOME
→ /healthz on bounded 200ms poll
→ fresh Temper
→ session.query
→ same session_id reconstructed from Restart.reconstruct/1
```

Evidence fields: `M2_D_SECOND_DAEMON_PID`, `M2_D_REPLAY=PASS`, `M2_D_SESSION_ID` (matches `M2_A_INITIAL_SESSION_ID`), `M2_D_RUN_STATE`.

## Current regression authority for M1-C

M1 historical acceptance (at `5d152e7`) reported `M1_C_DECIDE=PASS`. The frozen `m1_probe.sh` invokes `mix kiln session-resume`, which is **not a Mix task** in the canonical CLI surface. The legacy probe currently exits non-zero on M1-C purely because of this harness defect, not because the underlying property has regressed.

To prevent a future agent from interpreting `M1_C_DECIDE=FAIL` as a real regression:

1. The legacy `m1_probe.sh` is **frozen as a historical artifact**, not current authority.
2. Current regression authority for the M1-C property is the M2-B and B-VERIFY slices of `m2_probe.sh`. They drive the real `human.decide` RPC end-to-end:
   - `Workflow.record_user_decision/2` validates the bounded envelope against `projection.references.decision_envelope`
   - `require_decision_context_match/2` rejects stale/mismatched authority
   - the journal commits `user_decision_recorded/v1`
   - `run_state` advances from `waiting_for_user` to `ready`
3. The unit-test authority is `products/kiln/test/kiln/decision_lifecycle_test.exs` (10/10 PASS at M2 candidate) which exercises the same `Workflow.record_user_decision/2` boundary directly.

A green run of `m2_probe.sh` end-to-end + `Kiln.DecisionLifecycleTest` 10/10 is the current proof that the M1-C property holds. The legacy harness defect is documented, isolated, and not load-bearing.

## Scope integrity at M2 closure

- **Kimi lane untouched** — `products/kiln/lib/kiln/kimi_adapter.ex`, `products/kiln/test/kiln/kimi_adapter_deterministic_test.exs` remain as untracked worktree files owned by a separate lane. No edits, no stages, no commits reference them.
- **no mock final acceptance** — every assertion drives a real `WorkbenchConnection` against a real `Kiln.Daemon` over real HTTP (`/api/rpc`, `/healthz`) and real WebSocket (`/ws`).
- **no direct persistence fabrication** — the probe never writes to the journal or SQLite. The only writes are `mix kiln review-propose` (CLI) and `session.resume` / `human.decide` RPCs (daemon-side).
- **no Lab-specific product behavior** — no `LAB_DEFECT` / `ENVIRONMENT_DEFECT` detection in Temper, no Lab integration shim, no Docker/Compose semantics.
- **Kiln remains canonical authority** — every workflow boolean (`session_id`, `run_state`, `pending_decision`, `decision_envelope`, `session_revision`, `projection_digest`) is read from `project.open` + `session.query`, never carried across process boundary.