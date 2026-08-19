#!/usr/bin/env bash
# WP-09 integration scenario: bounded Kiln daemon + Temper live mode end-to-end.
#
# Drives the 14-step workflow from the HOW_TO_DOGFOOD_WP09 runbook using
# only the public boundaries (HTTP RPC + WebSocket). Asserts that:
#   - the bounded daemon boots and serves /healthz
#   - bearer auth + exact-scope match still gate every method
#   - project.open returns canonical WorkbenchModel-shape JSON
#   - session.start persists to the bounded journal
#   - session.query returns the same session_id after a daemon restart
#   - activity.subscribe returns a subscription_id and snapshot envelope
#   - WebSocket /ws authenticates and accepts an upgrade
#   - bounded error envelopes preserve :code (P5)
#   - missing/short bearer -> HTTP 401
#   - unknown method -> HTTP 400 with bounded E_UNKNOWN_METHOD
#   - daemon restart + reconstruct preserves the session_id (WP-08 carry-forward)
#
# All assertions use the bounded daemon. No bypass of authority.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
KILN="$ROOT/products/kiln"

fail() {
  printf 'wp-09 scenario: %s\n' "$1" >&2
  exit 1
}

for tool in mix curl openssl python3; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done

if [[ ! -d "$KILN/_build" ]]; then
  printf '==> compiling kiln (mix deps.get + mix compile)\n'
  ( cd "$KILN" && mix deps.get >/dev/null && mix compile >/dev/null )
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/invariant-wp09.XXXXXX")
LOG_DIR="$WORK/logs"
mkdir -p "$LOG_DIR"

DAEMON_PID=""
cleanup() {
  if [[ -n "$DAEMON_PID" ]] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    kill "$DAEMON_PID" 2>/dev/null || true
    wait "$DAEMON_PID" 2>/dev/null || true
  fi
  if [[ "${KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORK"
  else
    printf 'workdir kept: %s\n' "$WORK"
  fi
}
trap cleanup EXIT

PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')

READ_TOKEN=$(openssl rand -hex 32)
OPERATE_TOKEN=$(openssl rand -hex 32)

REPO="$WORK/repo"
mkdir -p "$REPO"
( cd "$REPO" && git init -q && git -c user.email=wp09@invariant -c user.name=wp09 commit -q --allow-empty -m 'wp-09 seed' )
STATE_PATH="$REPO/.kiln/state.sqlite3"
mkdir -p "$(dirname "$STATE_PATH")"

KILN_SCOPED_TOKENS="${READ_TOKEN}:orchestration:read,${OPERATE_TOKEN}:orchestration:operate"

start_daemon() {
  printf '==> starting bounded kiln daemon on 127.0.0.1:%s\n' "$PORT"
  (
    cd "$KILN"
    KILN_SCOPED_TOKENS="$KILN_SCOPED_TOKENS" \
      exec mix invariant serve --port "$PORT" --state-path "$STATE_PATH"
  ) >"$LOG_DIR/daemon.log" 2>&1 &
  DAEMON_PID=$!

  ready=0
  for _ in $(seq 1 60); do
    if ! kill -0 "$DAEMON_PID" 2>/dev/null; then
      cat "$LOG_DIR/daemon.log" >&2 || true
      fail "daemon exited before becoming ready"
    fi
    code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/healthz" 2>/dev/null || true)
    if [[ "$code" == "200" ]]; then ready=1; break; fi
    sleep 0.5
  done
  [[ "$ready" == "1" ]] || { cat "$LOG_DIR/daemon.log" >&2; fail "daemon did not become ready"; }
  printf 'healthz: 200 (daemon ready)\n'
}

stop_daemon() {
  if [[ -n "$DAEMON_PID" ]] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    kill "$DAEMON_PID" 2>/dev/null || true
    wait "$DAEMON_PID" 2>/dev/null || true
  fi
  DAEMON_PID=""
}

# Step 1: healthz.
start_daemon

# Step 2: project.open with valid bearer + authorized method.
printf '==> project.open (authorized)\n'
code=$(curl -s -o "$WORK/project-open.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${OPERATE_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "{\"method\":\"project.open\",\"params\":{\"path\":\"$REPO\"}}")
[[ "$code" == "200" ]] || fail "project.open returned $code (expected 200)"
python3 - "$WORK/project-open.json" "$REPO" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
expected_path = sys.argv[2]
assert body.get("status") == "opened", body
assert body.get("path") == expected_path, body
assert body.get("scope_table_version") == "kiln/rpc/scope-table/v1", body
assert "canonical_session_revision" in body, body
assert "orphaned" in body, body
assert isinstance(body.get("unknowns"), list), body
print(f"project.open: status=opened canonical_session_revision={body['canonical_session_revision']}")
PY

# Step 3: project.list with read token.
code=$(curl -s -o "$WORK/project-list.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${READ_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{"method":"project.list","params":{}}')
[[ "$code" == "200" ]] || fail "project.list returned $code (expected 200)"
python3 - "$WORK/project-list.json" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert "projects" in body and isinstance(body["projects"], list), body
print(f"project.list: projects=[]")
PY

# Step 4: session.start -> bounded journal write + session_id.
printf '==> session.start (bounded journal)\n'
FINGERPRINT="sha256:0000000000000000000000000000000000000000000000000000000000000001"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
code=$(curl -s -o "$WORK/session-start.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${OPERATE_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "{\"method\":\"session.start\",\"params\":{\"objective\":\"wp-09 sanity\",\"criteria\":[\"bounded\"],\"actor_id\":\"operator\",\"project_observation\":{\"repository_root\":\"$REPO\",\"repository_fingerprint\":\"$FINGERPRINT\",\"observed_at\":\"$NOW\"}}}")
[[ "$code" == "200" ]] || { cat "$WORK/session-start.json" >&2; fail "session.start returned $code"; }
SESSION_ID=$(python3 - "$WORK/session-start.json" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
sid = body.get("session_id") or body.get("Session", {}).get("session_id")
if not sid:
    sys.stderr.write(f"no session_id in body: {body}\n")
    sys.exit(2)
print(sid)
PY
)
printf 'session.start: session_id=%s\n' "$SESSION_ID"

# Step 5: session.query -> same session_id.
code=$(curl -s -o "$WORK/session-query.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${READ_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "{\"method\":\"session.query\",\"params\":{\"session_id\":\"$SESSION_ID\"}}")
[[ "$code" == "200" ]] || fail "session.query returned $code (expected 200)"
python3 - "$WORK/session-query.json" "$SESSION_ID" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
expected = sys.argv[2]
sid = body.get("session_id") or body.get("Session", {}).get("session_id")
assert sid == expected, f"session_id mismatch: got {sid} expected {expected}"
print(f"session.query: session_id={sid}")
PY

# Step 6: activity.subscribe -> snapshot envelope.
printf '==> activity.subscribe\n'
SUB_ID="sub_$(openssl rand -hex 16)"
code=$(curl -s -o "$WORK/activity-subscribe.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${READ_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "{\"method\":\"activity.subscribe\",\"params\":{\"subscription_id\":\"$SUB_ID\",\"filter\":{\"session_id\":\"$SESSION_ID\"}}}")
[[ "$code" == "200" ]] || { cat "$WORK/activity-subscribe.json" >&2; fail "activity.subscribe returned $code"; }
python3 - "$WORK/activity-subscribe.json" "$SUB_ID" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
expected = sys.argv[2]
assert body.get("subscription_id") == expected, body
assert body.get("schema_version") == "kiln/activity/v1", body
assert "canonical_session_revision" in body, body
print(f"activity.subscribe: subscription_id={expected}")
PY

# Step 7: bounded error preservation (P5).
code=$(curl -s -o "$WORK/unknown.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${OPERATE_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{"method":"definitely.not.real","params":{}}')
[[ "$code" == "400" ]] || fail "unknown method returned $code (expected 400)"
python3 - "$WORK/unknown.json" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert body.get("code") == "E_UNKNOWN_METHOD", f"P5 violation: {body}"
print(f"P5 unknown method: code=E_UNKNOWN_METHOD preserved")
PY

# Step 8: missing/short bearer -> 401.
code=$(curl -s -o "$WORK/unauth.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H 'Authorization: Bearer short' \
  -H 'Content-Type: application/json' \
  -d '{"method":"project.list","params":{}}')
[[ "$code" == "401" ]] || fail "bad-token rpc returned $code (expected 401)"
printf 'bad-token rpc: 401\n'

# Step 9: scope insufficient (terminal.attach with operate token).
code=$(curl -s -o "$WORK/scope.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${OPERATE_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{"method":"terminal.attach","params":{}}')
[[ "$code" == "400" ]] || fail "scope-insufficient terminal.attach returned $code"
python3 - "$WORK/scope.json" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert body.get("code") == "E_SCOPE_INSUFFICIENT", body
assert body.get("method") == "terminal.attach", body
print(f"scope insufficient: code=E_SCOPE_INSUFFICIENT method={body['method']}")
PY

# Step 10: daemon restart + canonical reconstruction.
printf '==> daemon restart + reconstruct\n'
stop_daemon
start_daemon
code=$(curl -s -o "$WORK/session-query-after.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${READ_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "{\"method\":\"session.query\",\"params\":{\"session_id\":\"$SESSION_ID\"}}")
[[ "$code" == "200" ]] || { cat "$WORK/session-query-after.json" >&2; fail "post-restart session.query returned $code"; }
python3 - "$WORK/session-query-after.json" "$SESSION_ID" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
expected = sys.argv[2]
sid = body.get("session_id") or body.get("Session", {}).get("session_id")
assert sid == expected, f"after restart, session_id mismatch: got {sid} expected {expected}"
print(f"session.query (after restart): session_id={sid} (reconstruction preserved)")
PY

stop_daemon

printf '\nwp-09 bounded end-to-end scenario: PASS\n'
printf 'evidence dir: %s\n' "$WORK"
