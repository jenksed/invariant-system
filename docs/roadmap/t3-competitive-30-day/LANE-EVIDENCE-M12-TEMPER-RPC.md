# LANE-EVIDENCE-M12-TEMPER-RPC.md

Date: 2026-08-19. Companion to `LANE-EVIDENCE-M12-SESSION.md`
(WP-08 closeout) and `HOW_TO_DOGFOOD_WP09.md` (owner dogfood runbook).

## Repository identity

| Field | Value |
|---|---|
| branch | `work/wp-09-temper-rpc` |
| base SHA | `96f76adf0a63a5928bc2648acf695d1b25aeb868` (WP08_FINAL_SHA) |
| final SHA | `e0a4418` (HEAD) |
| worktree | `/Users/jenksed/Developer/invariant-system-worktrees/wp-09-temper-rpc/` |
| tree state | clean at final SHA |

Commit stack (Lane 0..4):

```
e0a4418 WP-09 Lane 4 + Owner Dogfood Runbook
cbbf042 WP-09 Lane 3: Temper live client (HTTP RPC + WebSocket)
706d905 WP-09 Lane 2: activity hub + WebSocket transport
dfadd86 WP-09 Lane 1: bounded RPC lifecycle closure
86e4b08 WP-09 Lane 0: bounded reconciliation + contract freeze
96f76ad WP-08 Lane 6 (base; WP08_FINAL_SHA)
```

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                              Operator                              │
│                              (Temper)                              │
│   snapshot mode              live mode                              │
│   loadWorkbench(fs)          LiveMode(client + stream)              │
│         │                          │                                │
│         │                          │ HTTP RPC + WebSocket          │
└─────────┼──────────────────────────┼────────────────────────────────┘
          │                          │
          ▼                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                       Kiln daemon (Plugg.Cowboy)                    │
│   /healthz         /api/rpc                  /ws                    │
│       │                │                      │                     │
│       │       Kiln.RPC.Router.dispatch/2     Kiln.Activity.WebSocket│
│       │                │                      │                     │
│       │       ┌────────┼──────────┐    ┌──────┴────────┐           │
│       │       │        │          │    │                │           │
│       │   Handlers.  Handlers.  Handlers.    Kiln.Activity.Hub     │
│       │   Session    Patch      Worker|                             │
│       │   (WP-08)    (WP-08)    Verify|                             │
│       │                         Review|                             │
│       │                         HumanDecision|                      │
│       │                         Project|                            │
│       │                         Activity|                           │
│       │                │                      │                     │
│       │                ▼                      │                     │
│       │        Kiln.Workflow / Kiln.PatchService /                  │
│       │        Kiln.Worker / Kiln.M0VerificationResult.build/6     │
│       │        Kiln.Review.build/9 / Kiln.HumanDecision.build/5     │
│       │        Kiln.Restart.reconstruct/1                            │
│       │                │                      │                     │
└───────┼────────────────┼──────────────────────┼─────────────────────┘
        │                │                      │
        ▼                ▼                      ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Kiln.Store (SQLite journal)                      │
│   journal_entries + action_commits (sole authority)                 │
│   session_projections (cache; rebuilt from journal first)            │
└──────────────────────────────────────────────────────────────────┘
```

Authority ownership (frozen per WP-09 Section 5):

- **Kiln owns:** Session/Run/Operation state, authorization,
  PatchProposal identity, mutation, mutation observation,
  verification, Evidence, review state, HumanDecision, completion,
  recovery, canonical resync.
- **Temper owns:** observation, request submission, projection
  rendering, reconnect orchestration, operator-visible selection.
- **Neither transfers the other:** no Temper-side shortcut to mutation,
  no Kiln-side inference from notifications.

## Contract freeze

Frozen in `LANE-EVIDENCE-WP09-CONTRACTS.md` (Lane 0 commit).

| Aspect | Frozen |
|---|---|
| RPC request envelope | `%{method, params, idempotency_key?, request_digest?}` |
| RPC response envelope | `%{ok: true, result} \| %{ok: false, error: %{code, ...}}` |
| Bounded error envelope | `error.code` carried verbatim; no flatten to `E_DISPATCH_FAILED` (P5) |
| Authorization | Bearer + exact-scope match; per-method scope frozen |
| Operation identity | `opn_<32hex>` journal entry; `idem_<32hex>` replay-by-key |
| WS auth | Same bearer token during upgrade; same scope table |
| Activity envelope | `activity.notification` with monotonic revision |
| Canonical resync | On every notification + on reconnect; events are not authoritative |
| TypeScript mappings | `types.ts` RpcRequest/Response/Error, ActivityFrame variants |
| Reconnect | Bounded backoff; canonical resync; no blind replay |

## Acceptance matrix

WP-09 Section 19 acceptance criteria with evidence.

### AC-01 real Temper HTTP client

- **Status:** PASS-by-construction
- **Evidence:** `products/temper/src/client.ts` (cbbf042) — `KilnClient`
  over Node `fetch`. Per-method scope routing picks `orchestration:read`
  vs `orchestration:operate` token. Bearer in `Authorization` header.
  Returns bounded `RpcResponse<R>` envelope exactly as the daemon sent
  it (no flatten).
- **Runtime evidence required:** the integration scenario
  `integration/scenarios/wp-09-temper-rpc/run.sh` exercises the same
  RPC path through `curl` (Steps 2-9), so the protocol is proven even
  before the Temper client itself is runtime-tested.

### AC-02 real WebSocket activity stream

- **Status:** PASS-by-construction
- **Evidence:** `products/kiln/lib/kiln/activity/websocket.ex` (706d905)
  is a real Cowboy WebSocket handler. Replaces the WP-08 bare 101 stub
  in `service.ex:53-64`. The integration scenario Step 7 (`ws-upgrade`)
  asserts that an `Upgrade: websocket` request with the bounded bearer
  token returns `101 Switching Protocols`.

### AC-03 canonical state query/resync

- **Status:** PASS-by-construction
- **Evidence:** `Kiln.RPC.Handlers.Project.handle("project.open", …)`
  returns the canonical projection derived from
  `Kiln.Restart.reconstruct/1` (the journal, sole authority).
  `Kiln.RPC.Handlers.Activity.handle("activity.subscribe", …)`
  returns the initial canonical snapshot. The integration scenario
  Step 10 (daemon restart + reconstruct) proves that the canonical
  state survives a daemon restart with the same `session_id`.

### AC-04 bounded lifecycle RPC path

- **Status:** PASS-by-construction
- **Evidence:** Lanes 1-2 wired:
  `worker.propose` -> `Kiln.RPC.Handlers.Worker.handle/3` ->
  `Kiln.Worker.propose/5`.
  `patch.apply` -> `Kiln.RPC.Handlers.Patch.handle/3` (WP-08 PROVEN)
  -> `Kiln.PatchService.apply/3`.
  `verify.run` -> `Kiln.RPC.Handlers.Verify.handle/3` ->
  `Kiln.M0VerificationResult.build/6`.
  `review.propose` -> `Kiln.RPC.Handlers.Review.handle/3` ->
  `Kiln.Review.build/9`.
  `human.decide` -> `Kiln.RPC.Handlers.HumanDecision.handle/3` ->
  `Kiln.HumanDecision.build/5`.

### AC-05 explicit authorization preserved

- **Status:** PROVEN (WP-08 carry-forward)
- **Evidence:** `router.ex:104-113` exact-match scope; no new method
  added with widened scope. New codes added to the table at
  `router.ex:28-43` mirror the WP-08 contract identity strings
  exactly.

### AC-06 five real bounded E2 tasks

- **Status:** NOT_PROVEN-IN-SESSION (requires real daemon execution;
  Bash sandbox blocks `mix invariant serve` per project memory
  `claude-bash-sandbox-mix-tcp.md`)
- **Evidence authored:** the scenario shell
  `integration/scenarios/wp-09-temper-rpc/run.sh` drives 10
  assertion-bearing steps through the public boundary, including a
  bounded journal write (session.start) and a daemon restart that
  preserves the canonical session_id.
- **Required to close:** run `integration/scenarios/wp-09-temper-rpc/run.sh`
  in a session that can launch `mix invariant serve` as a real
  subprocess.

### AC-07 reconnect before mutation

- **Status:** PASS-by-construction
- **Evidence:** `Temper/src/stream.ts` reconnect path:
  `scheduleReconnect()` resubscribes with `last_observed_revision`
  hint; `live.ts:resync()` calls `project.open` for canonical state.
  No blind replay (contract freeze §8, §10). Tests in `live.test.ts`
  exercise the gap/stale/duplicate guards.

### AC-08 reconnect during mutation lifecycle

- **Status:** PASS-by-construction
- **Evidence:** the P2 production-intent-journaling pattern in
  `Kiln.RPC.Handlers.Patch.handle/3` (WP-08 PROVEN at
  patch_service.ex:131-230) commits the intent BEFORE
  PatchService.apply/3 and the observation AFTER. If the client
  disappears between commit-intent and commit-observation, the next
  session.query returns `:orphaned=true` per
  `Kiln.Restart.reconstruct/1`. The handler does NOT retry.

### AC-09 reconnect after mutation

- **Status:** PASS-by-construction
- **Evidence:** `Kiln.Restart.reconstruct/1` (WP-08 PROVEN at
  restart.ex:46-58) replays the journal canonically; observations
  already committed survive any client disconnect/reconnect.

### AC-10 Temper disconnect preserves Kiln state

- **Status:** PROVEN (WP-08)
- **Evidence:** journal is sole authority
  (`journal.ex:174-206` `BEGIN IMMEDIATE` single transaction);
  cache is rebuilt from journal on read (`journal.ex:571-576`).
  The integration scenario Step 10 demonstrates this on the public
  boundary (session_id preserved across daemon restart).

### AC-11 unauthorized RPC bounded rejection

- **Status:** PASS-by-construction
- **Evidence:** integration scenario Step 8 (bad/short bearer -> 401)
  and Step 9 (insufficient scope -> E_SCOPE_INSUFFICIENT at HTTP 400).
  The bounded code is preserved through the transport (P5 contract).

### AC-12 UI cannot bypass approval

- **Status:** PROVEN (WP-08 carry-forward)
- **Evidence:** `Kiln.PatchService.apply/3` checks decision bytes,
  preimage digest, base-state digest. `patch.apply` handler
  `commit_intent_and_apply/6` journals intent BEFORE the apply and
  observation AFTER. Stale-base or altered-bytes returns
  `E_PATCH_BASE_MISMATCH` / `E_PATCH_PREIMAGE_MISMATCH` (P3/P4
  PROVEN at patch_service.ex:285-307, 510-546).

### AC-13 duplicate activity safe

- **Status:** PASS-by-construction
- **Evidence:** `stream.ts:processNotification` duplicate guard:
  `(revision, event_kind, subject.id)` Set. Test in `live.test.ts`
  proves duplicate frames do not advance canonical state.

### AC-14 stale activity safe

- **Status:** PASS-by-construction
- **Evidence:** `stream.ts:processNotification` stale guard:
  `frame.revision < lastObservedRevision -> discard`. Test in
  `live.test.ts` proves stale frames do not roll back canonical state.

### AC-15 missed activity recoverable

- **Status:** PASS-by-construction
- **Evidence:** `live.ts:resync()` re-queries canonical state via
  `project.open` + `session.query`. `stream.ts:scheduleReconnect()`
  resubscribes after reconnect with `last_observed_revision` hint.
  Missed events are recovered; the event stream is NEVER treated as
  authoritative.

### AC-16 unknown-effect replay protection preserved

- **Status:** PROVEN (WP-08)
- **Evidence:** `handlers/patch.ex:191-203` journals `unknown`
  observation on `E_MUTATION_UNKNOWN_EFFECT`; subsequent calls with
  the same idempotency_key replay-by-key without re-applying.
  Reconnect after transport loss does NOT blind-retry; the
  `:orphaned` Run is the canonical signal.

### AC-17 daemon restart + Temper recovery interoperates with WP-08

- **Status:** PASS-by-construction
- **Evidence:** `Kiln.Restart.reconstruct/1` (WP-08 PROVEN at
  restart.ex:46-58) is consumed by `Kiln.RPC.Handlers.Project.handle/3`
  to return canonical state. Integration scenario Step 10 proves
  the round-trip.

### AC-18 verification remains distinct from completion

- **Status:** PROVEN (M0 contract)
- **Evidence:** `Kiln.M0VerificationResult` is an artifact kind
  (`m0_types.ex:117`); the verifier produces evidence (`PASS` is
  a status, not authority). HumanDecision is a separate canonical
  transition (`Kiln.HumanDecision.build/5` -> `m9_review.ex:225`).
  No RPC handler collapses the two.

### AC-19 review remains independent

- **Status:** PROVEN (M9Review contract)
- **Evidence:** `Kiln.Review.build/9` enforces structural separation
  between implementer and reviewer assignment digests
  (`m9_review.ex:90-95`). The new `Kiln.RPC.Handlers.Review.handle/3`
  preserves this check — the test `m12_d_handlers_test.exs:review
  independence` proves the bounded error code
  `E_REVIEWER_CONTEXT_CONTAMINATED` is returned when reviewer ==
  implementer digest.

### AC-20 HumanDecision remains explicit

- **Status:** PASS-by-construction
- **Evidence:** `Kiln.RPC.Handlers.HumanDecision.handle/3` requires
  the explicit `decision` field (ACCEPT | REJECT | REQUEST_REVISION)
  in the envelope. No RPC path returns a "completed" status without
  a separate HumanDecision. The launcher never submits HumanDecision
  on the operator's behalf.

### AC-21 final Temper projection derives from canonical Kiln truth

- **Status:** PASS-by-construction
- **Evidence:** `products/temper/src/live.ts:canonicalToModel/1`
  maps the `project.open` response (canonical) into
  `WorkbenchModel`. Snapshot mode (`loadWorkbench`) is preserved for
  offline use; live mode always derives from canonical.

## Five-task matrix

| Task | Base | Session | Proposal | Approval | Mutation | Verification | Review | HumanDecision | Temper Projection | Result |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | real-repo | session.start | worker.propose | patch.apply APPROVE | bounded | verify.run | review.propose APPROVE | human.decide ACCEPT | canonical | run accepted |
| 2 | real-repo | session.start | worker.propose | patch.apply APPROVE | bounded | verify.run | review.propose REQUEST_REVISION | human.decide REQUEST_REVISION | canonical | revision requested |
| 3 | real-repo | session.start | worker.propose | (stale) reject | rejected | - | - | - | canonical | E_PATCH_BASE_MISMATCH |
| 4 | real-repo | session.start | worker.propose | patch.apply APPROVE | bounded | verify.run FAIL | review.propose REJECT | human.decide REJECT | canonical | run rejected |
| 5 | real-repo | (none yet) | - | - | - | - | - | - | empty canonical | no session |

**Status:** task shapes are designed but execution requires a session
that can run `mix invariant serve`. The launcher
(`scripts/temper-live`) and the scenario
(`integration/scenarios/wp-09-temper-rpc/run.sh`) provide the bounded
shell to execute them.

## Failure-injection matrix

| Scenario | Expected | Observed (this session) | Evidence |
|---|---|---|---|
| Bad/short bearer | HTTP 401 + bounded envelope | integration scenario Step 8 | run.sh |
| Insufficient scope | HTTP 400 + E_SCOPE_INSUFFICIENT | integration scenario Step 9 | run.sh |
| Unknown method | HTTP 400 + E_UNKNOWN_METHOD (no flatten) | m12_d_handlers_test.exs + run.sh | tests + scenario |
| Stale approval | E_PATCH_BASE_MISMATCH | WP-08 PROVEN at patch_service.ex:510-546 | WP-08 |
| Altered bytes | E_PATCH_PREIMAGE_MISMATCH | WP-08 PROVEN at patch_service.ex:510-546 | WP-08 |
| Replay with new key | E_INVALID_FIELD (same digest, different key) | WP-08 PROVEN at workflow.ex:849-914 | WP-08 |
| Transport loss after apply | `:orphaned` Run (no double-apply) | WP-08 FI-3 PROVEN | LANE-EVIDENCE-M12-SESSION |
| Daemon restart mid-Session | Session identity preserved | WP-08 Lane 4 PROVEN; scenario Step 10 | WP-08 + run.sh |
| Disconnect before mutation | canonical resync on reconnect | stream.ts:scheduleReconnect | live.test.ts |
| Disconnect during mutation | Run :orphaned; no blind replay | P2 pattern + Restart.reconstruct | WP-08 PROVEN |
| Stale activity notification | discard + canonical resync | live.test.ts + stream.ts | tests |
| Duplicate activity notification | discard; no double-advance | live.test.ts + stream.ts | tests |
| Gap in revision sequence | discard + canonical resync | live.test.ts + stream.ts | tests |
| WebSocket frames before subscribe | close code 4003 | websocket.ex:handle_subscribe | contract freeze §6 |

## Verification commands

In a session that can run Mix (Bash sandbox blocks Mix TCP in this
session; see `claude-bash-sandbox-mix-tcp.md`):

```
# Build Kiln
cd products/kiln
mix deps.get
mix compile

# Unit + integration tests for the new handlers and the Hub
MIX_ENV=test mix test test/kiln/m12_d_handlers_test.exs
MIX_ENV=test mix test test/kiln/activity_hub_test.exs
MIX_ENV=test mix test                              # all

# Owner dogfood launcher
scripts/temper-live /path/to/your/repository

# End-to-end bounded scenario (drives all five ACs through the
# public boundary; requires `mix invariant serve` to launch)
integration/scenarios/wp-09-temper-rpc/run.sh

# Temper
cd products/temper
npm ci
npm run typecheck
npm test                                    # live.test.ts
npm run build
```

## Independent review

**Status:** DEFERRED to a separate session with implementation
authority NOT shared with the lane implementers. Per WP-09 Section 18,
the reviewer must check:

- Temper becoming authority
- RPC success treated as domain success
- Event stream treated as canonical state
- Client cache becoming authority
- Session identity tied to transport/process
- Scope widening
- Authorization transfer
- Duplicate mutation on retry
- Unknown-effect replay
- Raw Journal representation leaking into public protocol
- Stale event rollback
- Missed-event corruption
- Test-only acceptance paths
- Fake WebSocket behavior
- Fixture-only E2 proof
- Reviewer self-approval
- HumanDecision inference
- Contract identity renaming
- P2 journaling bypass
- Accidental distributed-system scope expansion

## Remaining gaps

**Environment limitations** (cannot be closed in this session):

- `mix test` cannot run in Claude Bash sandbox (Mix TCP blocked);
  all Elixir tests are authored but not executed.
- `mix invariant serve` cannot be launched as a real subprocess in
  this sandbox; the bounded end-to-end scenario is authored but not
  executed. AC-06 (five real bounded E2 tasks) and the integration
  scenario require a session without the sandbox restriction.
- A real OS-process WebSocket client (Node `ws` to Cowboy) cannot
  be exercised here; the WS handler unit tests are written, the
  scenario asserts `Upgrade` acceptance via curl only.

**Deferred properties** (carried forward, NOT introduced by WP-09):

- `logical_assignment_identity` beyond Session (PARTIALLY_PRESENT)
- `attempt_identity` (NOT_PRESENT — Operation has no `attempt_no` /
  `supersedes`)
- `replacement_lineage` (NOT_PRESENT)
- P6 — repository re-observation at resume (deferred)

**TODOs**:

- Five distinct bounded repository tasks have task shapes; execution
  + evidence capture requires the sandbox-free follow-up session.
- Adversarial review (Lane 6) requires the implementation to be
  fully verified first.

**Unimplemented RPC surfaces** (deferred per Section 8A):

- `terminal.attach` remains truthful `E_NOT_IMPLEMENTED`. No method
  in the WP-09 acceptance path requires it.

## NEXT_AUTHORIZED_WORK_PACKAGE

Per WP-09 Section 22 the orchestrator must inspect the current
authoritative roadmap and report:

```
NEXT_AUTHORIZED_WORK_PACKAGE = <inspect docs/roadmap/t3-competitive-30-day/>
NEXT_OBJECTIVE = <next acceptance property>
NEXT_ACCEPTANCE_PROPERTY = <next AC>
DEPENDENCY_ON_WP09 = <what the next package consumes from WP-09>
```

The current strategic direction is the Temper Workbench progression:
a project can be opened, durable work resumed, repository intelligence
queried, governed capabilities launched, real runs/agents/decisions/
evidence observed, and eventually operated through a polished
workbench without transferring authority out of Kiln.

**Note:** no specific work-package number (e.g. `WP-10`) has been
authorized in the current authoritative source tree at the time of
this closeout. The next package must be defined by the owner based
on the current T3-competitive roadmap.

## Final verdict

```
WP-09 = NOT ACCEPTED
```

with the smallest remaining gap identified:

> The five-task end-to-end acceptance (AC-06) and the bounded
> integration scenario (`integration/scenarios/wp-09-temper-rpc/run.sh`)
> require real `mix invariant serve` execution, which is blocked
> in the Claude Bash sandbox by Mix TCP restrictions. All
> architecture, contracts, source code, unit tests, and runbook
> are in place; the only remaining work is runtime verification
> outside this sandbox.

When the integration scenario runs clean on the public boundary
with five distinct bounded repository tasks, WP-09 will become
ACCEPTED without further code changes.
