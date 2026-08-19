---
title: WP-09 Closeout
description: Final acceptance record, evidence identities, defect history, and post-acceptance followups for WP-09 Temper client/server RPC + activity stream.
status: current
verified_at_commit: 755696052cd3b122de906ab9690dfaf6811efeb6
source_paths:
  - products/kiln/lib/kiln/service.ex
  - products/kiln/lib/kiln/daemon.ex
  - products/kiln/lib/kiln/activity/hub.ex
  - products/kiln/lib/kiln/activity/websocket.ex
  - products/kiln/lib/kiln/rpc/router.ex
  - products/kiln/lib/kiln/rpc/handlers/patch.ex
  - products/kiln/lib/kiln/rpc/handlers/worker.ex
  - products/kiln/lib/kiln/rpc/handlers/verify.ex
  - products/kiln/lib/kiln/rpc/handlers/review.ex
  - products/kiln/lib/kiln/rpc/handlers/human_decision.ex
  - products/kiln/lib/kiln/rpc/handlers/project.ex
  - products/kiln/lib/kiln/rpc/handlers/activity.ex
  - products/temper/src/client.ts
  - products/temper/src/stream.ts
  - products/temper/src/live.ts
  - products/temper/src/types.ts
  - integration/scenarios/wp-09-temper-rpc/run.sh
  - integration/scenarios/wp-09-five-tasks/run.py
  - invariant.boundaries.json
audience:
  - developer
  - operator
---

# WP-09 Closeout

## Final disposition

```text
WORK_PACKAGE       = WP-09
STATUS             = ACCEPTED
HUMAN_DECISION     = ACCEPT
ACCEPTED_CANDIDATE_SHA = 755696052cd3b122de906ab9690dfaf6811efeb6
ACCEPTED_SHORT_SHA = 7556960
```

WP-09 is closed. The accepted product identity is permanently `755696052cd3b122de906ab9690dfaf6811efeb6`. Do not rebind accepted evidence to a later documentation-integration commit.

## Owner verification (gates green)

```text
GATE 1 = 25/25   PASS — focused WP-09 Kiln gate (handlers + activity hub)
GATE 2 = 90/90   PASS — WP-08 inherited regressions + WP-09 daemon guards
GATE 3 = 1031/1031 PASS — full Kiln suite (includes M12-E1 composed golden path)
GATE 4 = 33/33   PASS — Temper tests
```

## Lane outcomes

```text
LANE 1 — Kiln RPC lifecycle closure     PASS
LANE 2 — Activity / WebSocket transport  PASS
LANE 3 — Temper live client              PASS
LANE 4 — Reconnect and failure behavior   PASS
LANE 5 — Five-task E2E acceptance         PASS
LANE 6 — Independent adversarial review  APPROVE
```

Lane 6 found no demonstrated candidate defects and no evidence-lineage defects.

## Evidence modes

| Property | Mode | Anchor |
|---|---|---|
| Bounded RPC envelope + error preservation | EXECUTABLE_TEST_EVIDENCE | `m12_d_handlers_test.exs` + `live.test.ts` |
| Activity stream discard/resync | EXECUTABLE_TEST_EVIDENCE | `live.test.ts` (stale/duplicate/gap) + `activity_hub_test.exs` |
| Scope-table exact-match | EXECUTABLE_TEST_EVIDENCE | `m12_d_scope_regression_test.exs` |
| Reviewer independence | EXECUTABLE_TEST_EVIDENCE | `m12_d_handlers_test.exs` reviewer==implementer rejection |
| Patch preimage (P3) | EXECUTABLE_TEST_EVIDENCE | `m12_d_handlers_test.exs` stale bytes test |
| Approval-bypass rejection | EXECUTABLE_TEST_EVIDENCE | `m12_d_handlers_test.exs` patch.apply without prior approval |
| Full bounded chain | COMPOSED_GOLDEN_PATH | `m12_e1_composed_golden_path_test.exs` — bounded completion → PatchProposal → governed apply (`EXACT_TARGET_STATE_OBSERVED`) → VerificationResult (`PASS`) → Review (`APPROVE`) → HumanDecision (`ACCEPT`) → RunResultProjection |
| Owner-machine reconnect | LIVE_OWNER_MACHINE_E2E | `/Users/jenksed/wp09-lane6-evidence/wp09-l5-reconnect.mjs` crosses real Cowboy 2.18 WebSocket boundary |
| Daemon lifecycle | LIVE_OWNER_MACHINE_E2E | `integration/scenarios/wp-09-temper-rpc/run.sh` (real `mix invariant serve` subprocess) |
| Five-task E2E | LIVE_OWNER_MACHINE_E2E | `integration/scenarios/wp-09-five-tasks/run.py` |
| Acceptance decision | OWNER_HUMAN_DECISION | This closeout record |
| Independent review | INDEPENDENT_REVIEW | Lane-6 review report |

### Live owner-machine evidence identities

```text
PatchProposal      = pp_b2bf1df271512bc3
Governed apply     = ape_759ded1684b1536d
effect             = EXACT_TARGET_STATE_OBSERVED
post_state_digest  = sha256:adf88bba3a057218d1c5ef8f9bab41ef24515565348ea719d25cfb38ad9e292d
VerificationResult = ver_32d3097add68ef3d
Review             = rev_f6e7c48d925642a0
HumanDecision      = hd_b64bac7ecb589299
RunResultProjection = rj_71c00419fcda075d
```

## Defect history (repairs landed before acceptance)

These are historical context, not reasons to reject the final SHA. Each repair has a regression guard.

| Repair | Defect | Regression guard |
|---|---|---|
| Repair-11 | Gate-3 reconciliation (test-state leakage + stale fixtures; 22 apparent failures collapsed into root causes) | test-only repair; no new code |
| Repair-12 | `project.open` rejected real directories via `File.regular?/1` (excludes directories) | `m12_d_handlers_test.exs` directory + regular-file path tests |
| Repair-13 | `normalize_store_error/1` returned `{:error, map}` that wrapped again into `{:error, {:error, ...}}` → HTTP 500 | `m12_d_handlers_test.exs` patch.apply error-envelope test |
| Repair-14 | `Kiln.Activity.WebSocket.init/2` used obsolete Cowboy 1.x five-tuple upgrade shape; every live WS upgrade crashed | `activity_websocket_test.exs` 3-tuple assertion + explicit 5-tuple refusal; live harness opens `ws://` |

## Post-acceptance followups (non-blocking)

These were identified by Lane 6 and do not block acceptance. They are engineering debt for the post-WP09 program state.

### Followup 1 — Reconnect harness fabrication check

The reconnect harness's `fabricated_completion` predicate for `RECONNECT_PRE_MUTATION`, `RECONNECT_MID_WORKFLOW`, and `DISCONNECT_SAFETY` inspects `f?.event?.kind === 'run_completed'` and `f?.kind === 'run_completed'`. The actual `activity.notification` envelope shape is `{type, subscription_id, revision, emitted_at, subject: {kind, id}, event_kind, canonical_session_revision}` — neither `event.kind` nor root `kind` exists. The predicate is structurally incapable of returning true; the PASS outcomes for these three properties are evidence-light by their negative form.

**Underlying property still holds:** the bounded `Kiln.Activity.Hub` holds no authoritative state (unit-tested by `activity_hub_test.exs`); the bounded `Restart.reconstruct/1` classifies non-terminal ops as `:orphaned` (unit-tested); the bounded `stream.ts` discards stale/duplicate/gap and triggers resync on gap (`live.test.ts`). The live harness demonstrates the real Cowboy 2.18 WS upgrade; it does not strongly assert the negative fabrication property by name.

**Future action:** strengthen the acceptance harness against the actual activity frame shape — assert `f?.event_kind !== 'state_changed' || f?.subject?.kind === 'session'` only after explicit canonical resync query, etc.

### Followup 2 — Canonical resync unconditional PASS

`CANONICAL_RESYNC` is recorded as `record('CANONICAL_RESYNC', true, ...)` (line 293) — an unconditional PASS without explicit canonical-state equality check.

**Underlying property still holds:** real `session.query` round-trip is asserted by `RECONNECT_POST_MUTATION`; `LiveMode.resync` is unit-tested via `live.test.ts` indirectly.

**Future action:** replace unconditional `true` with an explicit canonical-state equality check comparing post-reconnect `session.query` result against pre-disconnect canonical projection.

### Followup 3 — Five-task scenario name vs behavior

The scenario name `wp-09-five-tasks` and its descriptions overstate what Tasks 2–4 directly exercise. Those tasks call `worker.propose` and assert P5 envelope preservation. They do **not** drive the full bounded chain via RPC.

**Underlying property still holds:** the complete bounded chain is independently proven by `m12_e1_composed_golden_path_test.exs` (Gate 3) — bounded completion → `PatchProposal.build` → `PatchService.apply` (`EXACT_TARGET_STATE_OBSERVED`) → `VerificationResult.build` (`PASS`) → `Review.build` (`APPROVE`) → `HumanDecision.build` (`ACCEPT`) → `RunResultProjection.build`. The integration scenario `integration/scenarios/wp-09-temper-rpc/run.sh` drives the daemon lifecycle end-to-end through `session.start`, `session.query`, `activity.subscribe`, and reconstructs canonical state across daemon restart.

**Future action:** make the scenario description accurately distinguish direct coverage (RPC envelope + P5 preservation) from composed-golden-path evidence.

## Candidate-defect history (already landed)

```text
Repair-11  test-only reconciliation
Repair-12  project.open repository-directory validation
Repair-13  bounded patch error-envelope normalization
Repair-14  Cowboy 2.x WebSocket upgrade compatibility
```

No additional candidate defects discovered during Lane 6 adversarial review.

## Lessons preserved

1. Raw failure count is not defect count. Classify before mutation: `CANDIDATE_DEFECT` / `TEST_OR_SCENARIO_DEFECT` / `ENVIRONMENT_DEFECT` / `EVIDENCE_CAPTURE_DEFECT` / `CONTRACT_MISUNDERSTANDING` / `ACCEPTANCE_PROPERTY_NOT_PROVEN` / `UNKNOWN`.
2. Green unit/integration tests do not prove the real runtime boundary works. Repair-14 is the concrete example: mock WebSocket tests were green while every real Cowboy WebSocket upgrade crashed.
3. Deterministic seams must emulate canonical protocol shape.
4. Negative fixtures must genuinely reach the property they claim to test.
5. UNKNOWN EFFECT cannot be manufactured from a preflight rejection.
6. Recovery requires honest canonical observation.
7. Architecture guards should test prohibited semantics rather than stale source topology.
8. Independent review must separate: demonstrated defects, speculation, unproven properties, evidence gaps, documentation drift, evidence-lineage defects.
9. Review APPROVE is not HumanDecision. HumanDecision ACCEPT is the final WP-09 authority.

Do not overgeneralize beyond what WP-09 demonstrated.

## Successor state

```text
SUCCESSOR_BRANCH          = post-wp09/workbench-foundation
SUCCESSOR_BASE_SHA        = 755696052cd3b122de906ab9690dfaf6811efeb6
DOCS_INTEGRATION_SHA      = see successor branch HEAD
DOCS_HEAD                 = f26cd4d60330f67a356c619e69b01d3982f65f7e
DOCS_HEAD_ALREADY_ANCESTOR = NO (history-preserving merge applied)
```

## Next body of work

`TEMPER WORKBENCH ALPHA` — see `docs/_meta/post-wp09-product-direction.md` for the accepted direction and `docs/roadmap/strategic-programs.md` for the T3 Challenge relationship.

Do not begin Workbench implementation in this session. Start a fresh post-WP09 Workbench planning session.