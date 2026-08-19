# WP-09 Section 7 — RPC / Activity / Auth / Reconnect Contract Freeze

Date: 2026-08-19. Companion to `LANE-EVIDENCE-WP09-RECON.md`.

This document freezes the WP-09 wire contracts. **No implementation lane may
begin until this freeze is approved.** Once approved, any contract change
requires an explicit amend entry in `LANE-EVIDENCE-WP09-CONTRACT-CHANGELOG.md`.

Authority boundaries enforced by these contracts:

- **Kiln** owns: Session / Run / Operation state, authorization, PatchProposal
  identity, mutation, mutation observation, verification, Evidence, review
  state, HumanDecision, completion, recovery, canonical resync.
- **Temper** owns: observation, request submission, projection rendering,
  reconnect orchestration, operator-visible selection.

A button click, an HTTP 200, a successful WS send, a local cached value, a
green verification, a review recommendation, or a closed UI panel **never**
causes an authoritative transition.

## 1. RPC request envelope

All unary RPCs are POST `application/json` to `/api/rpc`.

```jsonc
{
  "method": "session.start",                    // required, string
  "params": { /* method-specific */ },          // required, object
  "idempotency_key": "idem_<32hex>",            // optional, string
  "request_digest": "sha256:<64hex>"            // optional, string
}
```

Rules:

- `idempotency_key` and `request_digest` may be omitted; Workflow auto-mints
  when absent (workflow.ex:908-910, router.ex:88-92).
- Per-call envelope-level keys are forwarded to handlers via `opts`. Handlers
  may also receive method-specific `params["idempotency_key"]` /
  `params["request_digest"]`; envelope values win on conflict
  (handlers/patch.ex:436-453).
- Both must be non-empty strings when present; anything else is ignored and
  the downstream handler raises a bounded `:E_INVALID_FIELD` /
  `:E_MISSING_FIELDS` error.
- Method names are exactly the strings frozen in `router.ex:26-43` and the
  `Kiln.RPC.Handlers.Worker|Verify|Review|HumanDecision|Project` dispatch
  tables added by WP-09. **No method-name rename.**

## 2. RPC response envelope

Success (`200 OK`, `application/json`):

```jsonc
{
  "ok": true,
  "result": { /* method-specific */ }
}
```

Bounded error (`400 OK` / `401 Unauthorized`, `application/json`):

```jsonc
{
  "ok": false,
  "error": {
    "code": "E_MUTATION_UNKNOWN_EFFECT",   // atom from Kiln.Domain.Error
                                           // or bounded WP-09 enum
    "reason": "human-readable",            // optional string
    "scope": "orchestration:operate",      // present on E_SCOPE_INSUFFICIENT
    "method": "patch.apply",               // present on E_SCOPE_INSUFFICIENT / E_UNKNOWN_METHOD
    "field": "session_id",                 // present on E_INVALID_FIELD
    "fields": ["session_id", "actor_id"],  // present on E_MISSING_FIELDS
    "details": { /* bounded payload */ }
  }
}
```

Rules:

- The HTTP status code is always `200` for `ok: true`, `400` for any
  bounded handler error carrying a `:code`, `401` for auth failures,
  `404` for unknown paths.
- Bounded error codes carry `:code` atomically from the handler through
  `Router.dispatch/2` without flattening (router.ex:65-72, P5 contract
  PROVEN in WP-08).
- `error.code` strings are exactly the atoms declared in
  `lib/kiln/domain/error.ex`, `lib/kiln/rpc/error.ex`, and the new
  `lib/kiln/rpc/handlers/*.ex` modules. **No code renaming.**

## 3. Bounded error envelope

Canonical codes that the transport preserves unchanged:

```
E_BODY_READ_FAILED
E_MALFORMED_REQUEST
E_UNKNOWN_METHOD
E_SCOPE_INSUFFICIENT
E_NOT_IMPLEMENTED
E_MISSING_FIELDS
E_INVALID_FIELD
E_INVALID_DIGEST
E_INVALID_PROJECT_OBSERVATION
E_STORE_UNAVAILABLE
E_JOURNAL_COMMIT_FAILED
E_DISPATCH_FAILED                 # ONLY when handler returned a non-:code error
E_MUTATION_UNKNOWN_EFFECT          # preserved end-to-end (P5)
E_PATCH_PREIMAGE_MISMATCH          # preserved end-to-end (P3, P5)
E_PATCH_BASE_MISMATCH              # preserved end-to-end
E_PATCH_AFTER_IMAGE_MISMATCH       # preserved end-to-end
E_PATCH_POSTIMAGE_MISMATCH         # preserved end-to-end
E_PATCH_DECISION_INVALID           # preserved end-to-end
E_PATCH_DECISION_NOT_APPROVE       # preserved end-to-end
E_PATCH_REPOSITORY_INVALID         # preserved end-to-end
E_PATCH_RECOVERY_DENIED            # preserved end-to-end (P4)
```

New WP-09 codes (handler-defined):

```
E_INVALID_VERIFIER          # verify.run
E_VERIFICATION_BUILD_FAILED # verify.run
E_REVIEW_BUILD_FAILED       # review.propose
E_HUMAN_DECISION_FAILED     # human.decide
E_WORKER_BUILD_FAILED       # worker.propose
E_PROJECT_INVALID_PATH      # project.open / project.list
E_PROJECT_NOT_FOUND         # project.open
E_ACTIVITY_NOT_FOUND        # activity.subscribe (session/run not in journal)
```

## 4. Authorization

- **Bearer token** in `Authorization: Bearer <token>` header.
- Tokens map to exactly one scope via the `:scoped_tokens` app env
  (service.ex:113-121, WP-08 PROVEN).
- Scope table is exact-match (router.ex:104-113). WP-09 adds no new methods
  with widened scope.
- All new RPCs declared in this freeze receive exactly one scope each:
  - `worker.propose`     → `orchestration:operate`  (already in scope table)
  - `verify.run`         → `orchestration:operate`  (already in scope table)
  - `review.propose`     → `review:write`           (already in scope table)
  - `human.decide`       → `orchestration:operate`  (already in scope table)
  - `project.open`       → `orchestration:operate`  (already in scope table)
  - `project.list`       → `orchestration:read`     (already in scope table)
  - `activity.subscribe` → `orchestration:read`     (already in scope table)
- **No scope widening.** No method may accept `orchestration:operate` for
  read-only intent, and no method may accept `orchestration:read` for
  mutations.

## 5. Operation / idempotency identity

Per Kiln Domain.Id + WP-08 P1 (PROVEN):

- `session_id`   — `ses_<32hex>`
- `run_id`       — `run_<32hex>`
- `operation_id` — `opn_<32hex>`
- `idempotency_key` — `idem_<32hex>` (or caller-supplied opaque string)
- `request_digest`  — `sha256:<64hex>`

Identity rules:

- `idempotency_key` is the operation identity at the wire layer. Same key +
  same request_digest → replay returns stored result, no second journal row.
- Different request_digest + same key → bounded `:invalid_idempotency_key`
  error (workflow.ex:849-914, preserved through handler).
- The key is opaque to Kiln; Kiln never inspects content. Temper mints it
  deterministically from canonical action inputs (plan ref, patch ref,
  decision kind) so retries land on the same key.

## 6. WebSocket authentication

- Single mechanism: same bearer token used for HTTP, sent as
  `Authorization: Bearer <token>` during the HTTP upgrade request.
- The existing `authenticate/1` in `service.ex:106-111` runs before the
  upgrade. On success the connection proceeds; on failure it returns
  `401` JSON and closes (no upgrade).
- The accepted client for WP-09 is Temper via Node `ws`, which sends
  custom headers natively. Browser-grade token exchange is **out of scope**
  for WP-09 (carried forward to a future desktop-client work package).
- The WS connection lifetime is **independent** of any session/run identity.
  The first frame after upgrade MUST be an `activity.subscribe` envelope
  (§7). Frames before subscribe are rejected with `4000` close code.

## 7. Activity notification envelope

The first frame after upgrade is the subscribe envelope:

```jsonc
{
  "type": "activity.subscribe",
  "subscription_id": "sub_<32hex>",            // minted by Temper
  "filter": {
    "session_id": "ses_<32hex>"                // optional
  },
  "since_revision": 42                         // optional; default 0
}
```

Notification frames:

```jsonc
{
  "type": "activity.notification",
  "subscription_id": "sub_<32hex>",
  "revision": 43,                              // monotonic per-session
  "emitted_at": "2026-08-19T13:30:00Z",
  "subject": {
    "kind": "session" | "run" | "operation",
    "id":   "ses_<32hex>" | "run_<32hex>" | "opn_<32hex>"
  },
  "event_kind": "state_changed",               // bounded enum
  "canonical_session_revision": 12             // current authoritative
                                              // session revision
                                              // (after replay)
}
```

Rules:

- `revision` is **monotonic per session_id**, derived from authoritative
  `session_revision` after journal replay. It is **not** event count,
  timestamp, daemon uptime, or connection count.
- If a subscriber receives a `revision` that is older than its last
  observed `canonical_session_revision`, the notification is stale and
  MUST be discarded.
- If `revision` shows a gap (e.g. subscriber last saw `42`, daemon sends
  `45`), the subscriber MUST re-synchronize via `session.query` and
  resume from the latest `canonical_session_revision`. The notification
  itself is discarded.
- Duplicate notifications (same `revision` + `event_kind` + `subject.id`)
  are discarded without effect.
- `Kiln.Activity.Hub` MUST publish only after the journal commit succeeds;
  no speculative notifications.
- The notification payload does NOT carry the Journal entry shape, the
  PatchService Evidence shape, the action payload, or any process /
  hostname / PID information. The notification is a small pointer; the
  full canonical state is obtained by querying.

## 8. Canonical resync behavior

Temper on reconnect (or on any state divergence):

```
connection_lost / startup / divergence_detected
  → authenticate (bearer)
  → open WS, send activity.subscribe (with last_observed_revision if known)
  → POST /api/rpc  { method: "session.query", params: { session_id } }
  → POST /api/rpc  { method: "project.open", params: { path } }  (if no session yet)
  → replace local WorkbenchModel with canonical response
  → resume activity subscription; treat subsequent notifications as deltas
```

Rules:

- Temper NEVER reconstructs authoritative state by replaying local events.
- `last_observed_revision` is a hint to the daemon, not authoritative state.
- The daemon does not require `since_revision`; subscribers can always
  start at the latest and pull via `session.query`.

## 9. TypeScript mappings

In `products/temper/src/types.ts`, add:

```ts
export type RpcScope =
  | 'orchestration:read'
  | 'orchestration:operate'
  | 'review:write'
  | 'terminal:operate';

export interface RpcRequest<M extends string, P> {
  method: M;
  params: P;
  idempotency_key?: string;
  request_digest?: string;
}

export type RpcResponse<R> =
  | { ok: true; result: R }
  | { ok: false; error: RpcError };

export interface RpcError {
  code: string;
  reason?: string;
  scope?: RpcScope;
  method?: string;
  field?: string;
  fields?: string[];
  details?: Record<string, unknown>;
}

export interface ActivitySubscribe {
  type: 'activity.subscribe';
  subscription_id: string;
  filter?: { session_id?: string };
  since_revision?: number;
}

export interface ActivityNotification {
  type: 'activity.notification';
  subscription_id: string;
  revision: number;
  emitted_at: string;
  subject: {
    kind: 'session' | 'run' | 'operation';
    id: string;
  };
  event_kind: 'state_changed';
  canonical_session_revision: number;
}

export type ActivityFrame = ActivitySubscribe | ActivityNotification;

// Per-method result types
export interface WorkerProposeResult {
  worker_output_id: string;
  semantic_digest: string;
  attempt_ref: string;
  assignment_ref: ArtifactRef;
  profile_ref: ArtifactRef;
  output_kind: string;
  raw_completion_ref: ArtifactRef;
  parsed_candidate_digest: string;
  base_commit: string;
  base_state_digest: string;
  adapter_implementation_digest: string;
}

export interface VerifyRunResult {
  verification_id: string;
  semantic_digest: string;
  status: 'PASS' | 'FAIL' | 'TIMEOUT' | 'ERROR';
  result_state_digest: string;
  registered_verifier: ArtifactRef;
  evidence_refs: ArtifactRef[];
}

export interface ReviewProposeResult {
  review_id: string;
  semantic_digest: string;
  status: 'APPROVE' | 'REQUEST_REVISION' | 'REJECT';
  // ...
}

export interface HumanDecisionResult {
  human_decision_id: string;
  semantic_digest: string;
  decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION';
  // ...
}

export interface ProjectOpenResult {
  status: 'opened';
  path: string;
  kiln_home: string;
  session_id?: string;
  canonical_session_revision?: number;
  unknowns?: string[];
  orphaned?: boolean;
}
```

## 10. Reconnect semantics

- Temper retains ONLY client-side hints: `session_id`, `last observed
  revision`, UI selection, current focus.
- All authoritative state is fetched fresh on reconnect.
- No retry of any consequential operation (worker.propose, patch.apply,
  verify.run, review.propose, human.decide) without first obtaining
  canonical state.
- If `patch.apply` returns no response (transport lost), Temper MUST
  query canonical state. If Run is `:orphaned`, Temper MUST NOT blind-
  retry; the operator must explicitly trigger `recover` or `human-decide`.
- Daemon restart during reconnect uses WP-08's `Restart.reconstruct/1`
  path (PROVEN). Temper sees this as a slow reconnect, not a special case.

## 11. Consequential operation audit (mandatory per Section 10)

For each of `worker.propose`, `patch.apply`, `verify.run`, `review.propose`,
`human.decide`, the RPC handler implementation MUST answer, before declaring
it complete:

1. **Operation identity** — `opn_<32hex>` minted by Kiln, persisted in journal.
2. **Authorized bounded input** — exact params shape + scope match.
3. **Expected pre-state** — Session in expected state; revision matches
   `expected_session_revision`.
4. **Durable intent recorded** — `external_operation_intent_recorded/v1`
   journal entry BEFORE the operation (P2 pattern, same shape as
   `handlers/patch.ex:289-298`).
5. **Performs the effect** — calls existing bounded domain function
   (`Worker.propose/5`, `PatchService.apply/3`, `VerificationResult.build/6`,
   `M9Review`, `Authority.decide/1`); NO new domain implementation.
6. **Effect-occurred proof** — `external_operation_observed/v1` entry with
   terminal state.
7. **Duplicate request** — same idempotency_key returns stored result;
   no second intent entry.
8. **Effect happened, response lost** — `Restart.reconstruct/1` classifies
   Run as `:orphaned` if observation missing; subscriber sees notification.
9. **Reconnect + retry** — same as (7); bounded replay-by-key.
10. **Canonical reconciliation** — `session.query` returns truthful state;
    `Restart.reconstruct/1` re-derives Run/Operation classification.

## 12. Activity Hub invariants

- One `Kiln.Activity.Hub` process, named `Kiln.Activity.Hub`.
- Subscribers register with `{subscription_id, session_id_filter,
  since_revision}`; receive notifications via `GenStage` or direct
  `send/2`. Implementation choice frozen at Lane 2 implementation; the
  external contract is what matters.
- Publishers (`Kiln.RPC.Handlers.*`, `Kiln.Workflow.*` transition sites)
  publish only AFTER journal commit returns `{:ok, _}`.
- Hub holds no authoritative state; it is a fan-out. Reconstructing
  missed notifications is the subscriber's job (canonical resync).

## 13. Contract changelog

Any deviation from these frozen contracts requires an amend record in
`LANE-EVIDENCE-WP09-CONTRACT-CHANGELOG.md` with: date, file:line of the
deviation, rationale, and explicit re-approval. Implementation PRs that
silently deviate are rejected.

## 14. Contract freeze approval

Status: **FROZEN 2026-08-19, basis: WP-09 Section 6 reconciliation complete,
WP-08 P1/P2/P3/P4/P5 contracts preserved.**

Subsequent amendments follow the changelog rule.
