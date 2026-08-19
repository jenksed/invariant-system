# HOW_TO_DOGFOOD_WP09

**Audience:** owner / operator with no prior knowledge of the implementation.

**Goal:** start the bounded Kiln daemon, connect Temper in live mode, and
exercise the complete bounded workflow (open repo -> bounded plan ->
bounded dispatch -> bounded apply -> bounded verify -> bounded review ->
bounded HumanDecision) using only the canonical `scripts/temper-live`
launcher and the documented commands below.

**Authority boundaries preserved:**
- The launcher never POSTs to `/api/rpc` on the operator's behalf.
- Bearer tokens are minted at runtime; nothing in source.
- Kiln is the sole authority for Session / Run / Operation state.
- Activity notifications are NOT authoritative; canonical state is
  re-fetched via `session.query` (or `project.open`) on every resync.

---

## Prerequisites

| Tool | Version | Required by |
|---|---|---|
| bash | >= 4 | launcher |
| elixir / mix | OTP 26+, Elixir 1.15+ | Kiln compile + daemon |
| node | >= 22.0.0 (global `WebSocket`) | Temper live mode |
| npm | >= 9 | Temper build |
| curl | any | smoke tests |
| openssl | any | runtime token generation |
| python3 | >= 3.8 | integration assertions |
| git | any | real repository under test |

Check:

```
elixir --version
mix --version
node --version
npm --version
curl --version
openssl version
python3 --version
git --version
```

The launcher (`scripts/temper-live --help`) checks these and refuses
to proceed if any are missing.

---

## 1. Build (one-time per checkout)

```
(cd products/kiln    && mix deps.get && mix compile)
(cd products/temper  && npm ci && npm run build)
```

The launcher runs these on demand the first time, but explicit builds
surface errors earlier.

## 2. Daemon startup

```
scripts/temper-live /path/to/your/repository
```

Equivalent manual invocation (what the launcher runs under the hood):

```
KILN_SCOPED_TOKENS="$(openssl rand -hex 32):orchestration:read,$(openssl rand -hex 32):orchestration:operate" \
  mix invariant serve \
    --state-path /path/to/your/repository/.kiln/state.sqlite3 \
    --port 4000
```

The launcher prints the canonical 14-step workflow after both processes
are ready. Ctrl-C stops both.

## 3. State-path selection

Default: `<repository>/.kiln/state.sqlite3`. The launcher creates the
parent directory if missing. Override with `--state-path <PATH>`.

This is the **only** persistence surface for the bounded Kiln daemon.
Removing it loses the journal; restarting with the same path replays
the journal canonically via `Kiln.Restart.reconstruct/1`.

## 4. Authentication / token setup

The launcher generates two scoped tokens at runtime (64 hex chars each):

- `orchestration:read` — `session.query`, `session.next_actions`,
  `activity.subscribe`, `project.list`
- `orchestration:operate` — all session lifecycle + `worker.propose`,
  `patch.apply`, `verify.run`, `human.decide`, `project.open`

The launcher exposes them to Temper via `KILN_READ_TOKEN` /
`KILN_OPERATE_TOKEN` env vars and persists them only in the workdir
(`/tmp/temper-live.XXXXXX/token.read` and `token.operate`); the
workdir is removed on clean shutdown unless `--keep-workdir` is set.

The daemon enforces exact-scope match (`lib/kiln/rpc/router.ex:104-113`).
There is no way to widen a scope; a token with scope `orchestration:read`
**cannot** dispatch `worker.propose`.

## 5. Temper live-mode startup

Handled by the launcher. Manual:

```
KILN_URL=http://127.0.0.1:4000 \
KILN_READ_TOKEN=$READ \
KILN_OPERATE_TOKEN=$OPERATE \
KILN_WS_URL=ws://127.0.0.1:4000/ws \
  node products/temper/dist/cli.js --live /path/to/your/repository
```

The launcher passes these env vars to Temper and waits for the WS to
become ready before printing the workflow. If any env var is missing,
Temper exits 2 with a clear error message.

## 6. Repository / project opening

Temper renders the canonical projection after a single `project.open`
RPC. Manual verification:

```
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{"method":"project.open","params":{"path":"/path/to/your/repository"}}'
```

Expected response:

```json
{
  "status": "opened",
  "path": "/path/to/your/repository",
  "kiln_home": "/path/to/your/repository/.kiln",
  "session_id": null,
  "canonical_session_revision": 0,
  "orphaned": false,
  "unknowns": []
}
```

## 7. Starting or resuming a bounded Session

Start:

```
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"session.start",
    "params":{
      "objective":"<bounded objective>",
      "criteria":["<bounded criterion>"],
      "actor_id":"operator",
      "project_observation":{
        "repository_root":"/path/to/your/repository",
        "repository_fingerprint":"sha256:<64hex>",
        "observed_at":"2026-08-19T13:30:00Z"
      }
    }
  }'
```

Resume (after disconnect / daemon restart):

```
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"session.resume",
    "params":{
      "session_id":"ses_<32hex>",
      "actor_id":"operator",
      "expected_session_revision":<int>
    }
  }'
```

The `expected_session_revision` MUST match the canonical state; a stale
revision returns `E_STALE_REVISION` (bounded error envelope, P5).

## 8. Observing live activity

Temper renders notifications as they arrive. To drive them manually,
subscribe via RPC:

```
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $READ" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"activity.subscribe",
    "params":{
      "subscription_id":"sub_<32hex>",
      "filter":{"session_id":"ses_<32hex>"}
    }
  }'
```

Then open the WebSocket at `ws://127.0.0.1:4000/ws` with
`Authorization: Bearer $OPERATE` and send:

```
{"type":"activity.subscribe","subscription_id":"sub_<32hex>","filter":{"session_id":"ses_<32hex>"}}
```

The daemon replies with `activity.snapshot` then forwards
`activity.notification` frames as bounded Kiln transitions occur.

## 9. Approving a proposed mutation

The M0 PatchProposal flow has TWO RPCs:

```
# Step A: worker proposes bounded candidate (bounded envelope).
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"worker.propose",
    "params":{
      "assignment":{...},
      "eligibility":{...},
      "profile":{...},
      "request_attrs":{...},
      "repository_root":"/path/to/your/repository"
    }
  }'

# Step B: operator (or Temper UI) submits the bounded PatchProposal +
# APPROVE_EXACT_BYTES decision. P2 production intent/observation
# journaling commits an intent entry BEFORE PatchService.apply/3 and an
# observation entry AFTER.
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"patch.apply",
    "params":{
      "proposal":{...},
      "decision":{"decision":"APPROVE_EXACT_BYTES","base_state_digest":"sha256:..."},
      "operations_with_bytes":[{"op":"add","path":"README.md","bytes":"..."}],
      "session_id":"ses_<32hex>",
      "run_id":"run_<32hex>",
      "operation_id":"opn_<32hex>",
      "subject_id":"<bounded>",
      "actor_id":"operator",
      "idempotency_key":"idem_<32hex>",
      "request_digest":"sha256:<64hex>"
    }
  }'
```

Stale-base approval returns `E_PATCH_BASE_MISMATCH`; altered bytes return
`E_PATCH_PREIMAGE_MISMATCH`; unknown-effect returns
`E_MUTATION_UNKNOWN_EFFECT`. All three codes are preserved through the
transport (P5 contract).

## 10. Observing apply + verification + review

```
# After patch.apply succeeds, observe the resulting session state.
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $READ" \
  -H 'Content-Type: application/json' \
  -d '{"method":"session.query","params":{"session_id":"ses_<32hex>"}}'

# Run a bounded verifier against the post-mutation state.
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"verify.run",
    "params":{
      "plan_ref":<ArtifactRef>,
      "patch_ref":<ArtifactRef>,
      "result_state_digest":"sha256:...",
      "registered_verifier":<ArtifactRef>,
      "status":"PASS",
      "evidence_refs":[{...}]
    }
  }'

# Submit an independent bounded review.
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"review.propose",
    "params":{
      "implementer_assignment_ref":<ArtifactRef>,
      "plan_ref":<ArtifactRef>,
      "patch_ref":<ArtifactRef>,
      "result_state_digest":"sha256:...",
      "verification_ref":<ArtifactRef>,
      "reviewer_assignment_ref":<ArtifactRef>,
      "verdict":"APPROVE",
      "findings":["..."],
      "context_manifest_ref":<ArtifactRef>
    }
  }'
```

## 11. Submitting HumanDecision

```
curl -sS -X POST http://127.0.0.1:4000/api/rpc \
  -H "Authorization: Bearer $OPERATE" \
  -H 'Content-Type: application/json' \
  -d '{
    "method":"human.decide",
    "params":{
      "plan_ref":<ArtifactRef>,
      "patch_ref":<ArtifactRef>,
      "result_state_digest":"sha256:...",
      "review_ref":<ArtifactRef>,
      "decision":"ACCEPT"
    }
  }'
```

HumanDecision is the ONLY authoritative transition; `verify.run`
returns `PASS` is evidence, not authority. A separate
`human.decide` invocation is mandatory for canonical acceptance.

## 12. Disconnecting and reconnecting Temper

Disconnect: `pkill -f "node products/temper"` (or Ctrl-C the launcher).
Temper retains `session_id`, `last_observed_revision`, and UI selection
as client-side hints only.

Reconnect: re-run the same `node products/temper/dist/cli.js --live …`
command (or the launcher). Temper will:

1. Re-authenticate (bearer token during WS upgrade).
2. Re-query canonical state via `project.open` + `session.query`.
3. Subscribe to the activity stream with `since_revision =
   last_observed_revision` as a hint (NOT authoritative).
4. Render the canonical projection. Any local Temper state is replaced.

Missed events are recovered via canonical resync; the daemon does NOT
replay events Temper happened to receive.

## 13. Restarting Kiln and reconstructing the Session

```
# Stop the daemon (e.g. kill -TERM the daemon PID, or Ctrl-C the launcher).
# Re-run scripts/temper-live /path/to/your/repository.
```

`mix invariant serve --state-path <same path>` boots with the journal
intact. `Kiln.Restart.reconstruct/1` replays the journal canonically
(WP-08 Lane 4 PROVEN), classifying nonterminal operations as
`:orphaned` without appending journal entries. Temper reconnects and
sees the canonical state via `session.query`.

A Run that was orphaned at restart is NOT blind-retried. The operator
must explicitly invoke `recover/3` (via `human.decide`) to advance.

## 14. Clean shutdown

```
# In the launcher's terminal:
Ctrl-C
```

The launcher:
- kills Temper (SIGTERM, then SIGKILL after 5s)
- kills the daemon (same)
- removes the workdir (unless `--keep-workdir`)
- exits 0

If the launcher was terminated abruptly:

```
pkill -f 'mix invariant serve'
pkill -f 'node products/temper'
```

These do NOT remove the journal; restart `scripts/temper-live` against
the same repository to recover.

---

## Negative paths (the security boundaries)

These are the failures the launcher / workflow is REQUIRED to produce
when mis-configured. None of them should ever result in a successful
mutation, an authoritative transition, or a silent replay.

| Misuse | Expected | Observed at the public boundary |
|---|---|---|
| Omit `Authorization` header | HTTP 401 + `E_UNAUTHORIZED` envelope | ✓ |
| Wrong-scope token for `worker.propose` | HTTP 400 + `E_SCOPE_INSUFFICIENT` envelope | ✓ |
| `patch.apply` with stale base | HTTP 400 + `E_PATCH_BASE_MISMATCH` (P3/P4 preserved) | ✓ |
| `patch.apply` with altered bytes | HTTP 400 + `E_PATCH_PREIMAGE_MISMATCH` (P3) | ✓ |
| Replay `patch.apply` with new bytes, same `idempotency_key` | HTTP 200 + `status=replayed` (no second journal row) | ✓ |
| `patch.apply` transport loss after apply | `:orphaned` Run, no double-apply (P2 + WP-08 PROVEN) | ✓ |
| `human.decide` from a stale UI panel | HTTP 400 + `E_STALE_REVISION` (bounded rejection) | ✓ |
| Unknown method name | HTTP 400 + `E_UNKNOWN_METHOD` (no flattening to `E_DISPATCH_FAILED`) | ✓ |
| WebSocket frames before subscribe | WS close code 4003 (no upgrade leak) | ✓ |
| Activity notification with stale revision | Temper discards + canonical resync | ✓ |
| Activity notification with revision gap | Temper discards + canonical resync | ✓ |
| Activity notification duplicate | Temper discards (no double-advance) | ✓ |
| `client_id` / daemon PID / hostname in any envelope | Rejected at boundary (`E_INVALID_FIELD`) | ✓ |
| Launcher shortcutting any RPC | Not possible — launcher is a coordinator only | ✓ |

---

## Final owner-facing evidence

```
HOW_TO_DOGFOOD_WP09
===================
<exact commands above>

Launcher: scripts/temper-live
Scenario: integration/scenarios/wp-09-temper-rpc/run.sh
Contracts: docs/roadmap/t3-competitive-30-day/LANE-EVIDENCE-WP09-CONTRACTS.md
Reconciliation: docs/roadmap/t3-competitive-30-day/LANE-EVIDENCE-WP09-RECON.md
```
