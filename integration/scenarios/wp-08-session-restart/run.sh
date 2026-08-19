#!/usr/bin/env bash
# WP-08 Lane 5 integration scenario: bounded Session survives a real OS-process
# kill -9 + restart, queryable from a freshly started daemon with identical
# canonical projection_digest.
#
# This is the shell-level proof of Lane 4's Elixir property. Lane 4 is the
# in-process unit test; this script is the OS-process integration test.
#
# Acceptance property (spec):
#   Running ./integration/scenarios/wp-08-session-restart/run.sh from the
#   worktree root proves a bounded Session created via `mix invariant serve`
#   survives a real daemon process kill and is queryable from a freshly
#   started daemon, with identical canonical projection digest.
#
# Everything executes from this one checkout. Temporary state lives in a
# mktemp directory and is removed on exit unless KEEP_WORKDIR=1.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
KILN="$ROOT/products/kiln"

fail() {
  printf 'wp-08-session-restart scenario: %s\n' "$1" >&2
  exit 1
}

for tool in mix curl openssl python3 jq lsof; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done

# Build product artifacts from this checkout when missing.
if [[ ! -d "$KILN/_build" ]]; then
  printf '==> compiling kiln (mix deps.get && mix compile)\n'
  (cd "$KILN" && mix deps.get >/dev/null && mix compile >/dev/null)
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/invariant-scenario-wp08-restart.XXXXXX")
STATE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/invariant-scenario-wp08-state.XXXXXX")
KILN_STATE_PATH="$STATE_DIR/state.sqlite3"
DAEMON1_PID=""
DAEMON2_PID=""
STATE_PATH_DIR="$STATE_DIR"

cleanup() {
  if [[ -n "$DAEMON1_PID" ]] && kill -0 "$DAEMON1_PID" 2>/dev/null; then
    kill -9 "$DAEMON1_PID" 2>/dev/null || true
    wait "$DAEMON1_PID" 2>/dev/null || true
  fi
  if [[ -n "$DAEMON2_PID" ]] && kill -0 "$DAEMON2_PID" 2>/dev/null; then
    kill -9 "$DAEMON2_PID" 2>/dev/null || true
    wait "$DAEMON2_PID" 2>/dev/null || true
  fi
  if [[ "${KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORK" "$STATE_DIR"
  else
    printf 'workdir kept: %s\nstate kept: %s\n' "$WORK" "$STATE_DIR"
  fi
}
trap cleanup EXIT

# Ephemeral port (bound-then-released; the daemon re-binds it).
PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')

# Runtime-generated scoped tokens (64 hex chars each via xxd). Never stored in source.
# Two distinct tokens because the bounded Kiln daemon enforces EXACT scope match
# (router.ex authorize/2: ^scope -> :ok). session.start requires
# orchestration:operate; session.query requires orchestration:read. Both tokens are
# passed to the daemon via KILN_SCOPED_TOKENS (comma-separated per the
# load_scoped_tokens_from_env parser in lib/mix/tasks/invariant.ex:60-66).
OPERATE_TOKEN=$(head -c 32 /dev/urandom | xxd -p -c 64)
READ_TOKEN=$(head -c 32 /dev/urandom | xxd -p -c 64)

# Fixed timestamp for deterministic request digest across the kill boundary.
# The timestamp is internal to the request; a stable value keeps the
# session.start idempotency replay-equivalent across re-tries.
SEED_TIMESTAMP="2026-08-19T00:00:00Z"
SEED_FINGERPRINT="sha256:0000000000000000000000000000000000000000000000000000000000000001"

# Fixed repository_root pointing at the state dir so the projection is
# fully resolvable across both daemon incarnations.
SEED_REPO_ROOT="$STATE_PATH_DIR"

# -- 1. Start daemon #1 ---------------------------------------------------

printf '==> starting daemon #1 on 127.0.0.1:%s state=%s\n' "$PORT" "$KILN_STATE_PATH"
(
  cd "$KILN"
  KILN_SCOPED_TOKENS="${OPERATE_TOKEN}:orchestration:operate,${READ_TOKEN}:orchestration:read" \
    exec mix invariant serve --port "$PORT" --state-path "$KILN_STATE_PATH"
) >"$WORK/daemon1.log" 2>&1 &
DAEMON1_PID=$!

# Bounded readiness wait: poll /healthz for up to 30 seconds at 100ms interval.
ready=0
for _ in $(seq 1 300); do
  if ! kill -0 "$DAEMON1_PID" 2>/dev/null; then
    cat "$WORK/daemon1.log" >&2 || true
    fail "daemon #1 exited before becoming ready"
  fi
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/healthz" 2>/dev/null || true)
  if [[ "$code" == "200" ]]; then
    ready=1
    break
  fi
  sleep 0.1
done
[[ "$ready" == "1" ]] || { cat "$WORK/daemon1.log" >&2 || true; fail "daemon #1 did not become ready on port $PORT"; }
printf 'healthz (daemon #1): 200 (ready)\n'

# -- 2. POST /api/rpc session.start ---------------------------------------

START_REQUEST=$(cat <<JSON
{
  "method": "session.start",
  "params": {
    "objective": "WP-08 Lane 5 integration: session survives real kill -9",
    "criteria": ["Session identity survives OS-process kill/restart"],
    "actor_id": "user:local",
    "project_observation": {
      "repository_root": "${SEED_REPO_ROOT}",
      "repository_fingerprint": "${SEED_FINGERPRINT}",
      "observed_at": "${SEED_TIMESTAMP}"
    }
  }
}
JSON
)

code=$(curl --fail --silent --show-error -o "$WORK/start.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${OPERATE_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "$START_REQUEST") || { cat "$WORK/daemon1.log" >&2 || true; fail "session.start curl failed (exit non-zero)"; }
[[ "$code" == "200" ]] || { cat "$WORK/daemon1.log" >&2 || true; cat "$WORK/start.json" >&2 || true; fail "session.start returned $code (expected 200)"; }

SESSION_ID=$(jq -r '.session_id' "$WORK/start.json")
PROJECTION_DIGEST=$(jq -r '.projection_digest' "$WORK/start.json")

if [[ -z "$SESSION_ID" || "$SESSION_ID" == "null" ]]; then
  cat "$WORK/daemon1.log" >&2 || true
  cat "$WORK/start.json" >&2 || true
  fail "session.start did not return a session_id"
fi
if [[ -z "$PROJECTION_DIGEST" || "$PROJECTION_DIGEST" == "null" ]]; then
  cat "$WORK/daemon1.log" >&2 || true
  cat "$WORK/start.json" >&2 || true
  fail "session.start did not return a projection_digest"
fi
printf 'session.start: session_id=%s projection_digest=%s\n' "$SESSION_ID" "$PROJECTION_DIGEST"

# -- 3. POST /api/rpc session.query (daemon #1) ---------------------------

QUERY_REQUEST=$(cat <<JSON
{
  "method": "session.query",
  "params": {
    "session_id": "${SESSION_ID}"
  }
}
JSON
)

code=$(curl --fail --silent --show-error -o "$WORK/query1.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${READ_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "$QUERY_REQUEST") || { cat "$WORK/daemon1.log" >&2 || true; fail "session.query (daemon #1) curl failed"; }
[[ "$code" == "200" ]] || { cat "$WORK/daemon1.log" >&2 || true; cat "$WORK/query1.json" >&2 || true; fail "session.query (daemon #1) returned $code (expected 200)"; }

QUERY1_DIGEST=$(jq -r '.projection_digest' "$WORK/query1.json")
if [[ "$QUERY1_DIGEST" != "$PROJECTION_DIGEST" ]]; then
  printf 'mismatch: start_digest=%s query1_digest=%s\n' "$PROJECTION_DIGEST" "$QUERY1_DIGEST" >&2
  cat "$WORK/daemon1.log" >&2 || true
  fail "session.query (daemon #1) projection_digest != session.start projection_digest"
fi
printf 'session.query (daemon #1): projection_digest matches start (%s)\n' "$QUERY1_DIGEST"

# -- 4. KILL -9 the daemon -------------------------------------------------

# Find PID by listening on the port. lsof -ti tcp:PORT lists all PIDs;
# take the first one (the bounded daemon beam.smp).
PID=$(lsof -ti tcp:"$PORT" | head -n 1 || true)
if [[ -z "$PID" ]]; then
  cat "$WORK/daemon1.log" >&2 || true
  fail "could not find PID for port $PORT"
fi
printf '==> killing daemon #1 PID=%s with -9\n' "$PID"
kill -9 "$PID" || true
DAEMON1_PID=""

# Bounded wait: poll until curl cannot connect (connection refused) for up to 10s.
freed=0
for _ in $(seq 1 100); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 "http://127.0.0.1:${PORT}/healthz" 2>/dev/null || echo "000")
  if [[ "$code" == "000" ]]; then
    freed=1
    break
  fi
  sleep 0.1
done
[[ "$freed" == "1" ]] || { cat "$WORK/daemon1.log" >&2 || true; fail "port $PORT never released after kill -9"; }
printf 'port %s: free (daemon #1 killed)\n' "$PORT"

# -- 5. Start daemon #2 with the SAME state-path ---------------------------

printf '==> starting daemon #2 on 127.0.0.1:%s state=%s\n' "$PORT" "$KILN_STATE_PATH"
(
  cd "$KILN"
  KILN_SCOPED_TOKENS="${OPERATE_TOKEN}:orchestration:operate,${READ_TOKEN}:orchestration:read" \
    exec mix invariant serve --port "$PORT" --state-path "$KILN_STATE_PATH"
) >"$WORK/daemon2.log" 2>&1 &
DAEMON2_PID=$!

# Track the actual bound PID for cleanup
BOUND_PID=""

# Bounded readiness wait: poll /healthz for up to 30 seconds at 100ms interval.
ready=0
for _ in $(seq 1 300); do
  if ! kill -0 "$DAEMON2_PID" 2>/dev/null; then
    cat "$WORK/daemon2.log" >&2 || true
    fail "daemon #2 exited before becoming ready"
  fi
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/healthz" 2>/dev/null || true)
  if [[ "$code" == "200" ]]; then
    ready=1
    BOUND_PID=$(lsof -ti tcp:"$PORT" | head -n 1 || true)
    break
  fi
  sleep 0.1
done
[[ "$ready" == "1" ]] || { cat "$WORK/daemon2.log" >&2 || true; fail "daemon #2 did not become ready on port $PORT"; }
printf 'healthz (daemon #2): 200 (ready)\n'

# -- 6. POST /api/rpc session.query (daemon #2) ---------------------------

code=$(curl --fail --silent --show-error -o "$WORK/query2.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${READ_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d "$QUERY_REQUEST") || { cat "$WORK/daemon2.log" >&2 || true; fail "session.query (daemon #2) curl failed"; }
[[ "$code" == "200" ]] || { cat "$WORK/daemon2.log" >&2 || true; cat "$WORK/query2.json" >&2 || true; fail "session.query (daemon #2) returned $code (expected 200)"; }

QUERY2_DIGEST=$(jq -r '.projection_digest' "$WORK/query2.json")
if [[ -z "$QUERY2_DIGEST" || "$QUERY2_DIGEST" == "null" ]]; then
  cat "$WORK/daemon2.log" >&2 || true
  cat "$WORK/query2.json" >&2 || true
  fail "session.query (daemon #2) did not return a projection_digest"
fi

# Assert SAME projection_digest across the kill -9 boundary.
if [[ "$QUERY2_DIGEST" != "$PROJECTION_DIGEST" ]]; then
  printf 'mismatch: start_digest=%s query2_digest=%s\n' "$PROJECTION_DIGEST" "$QUERY2_DIGEST" >&2
  cat "$WORK/daemon2.log" >&2 || true
  fail "session.query (daemon #2) projection_digest != session.start projection_digest"
fi

# Also assert the per-session fields the spec cares about survived.
QUERY2_SESSION_ID=$(jq -r '.session_id' "$WORK/query2.json")
if [[ "$QUERY2_SESSION_ID" != "$SESSION_ID" ]]; then
  cat "$WORK/daemon2.log" >&2 || true
  fail "session.query (daemon #2) returned session_id=$QUERY2_SESSION_ID (expected $SESSION_ID)"
fi

printf 'session.query (daemon #2): session_id=%s projection_digest=%s\n' "$QUERY2_SESSION_ID" "$QUERY2_DIGEST"
printf 'PASS: session.query returns same projection_digest after kill -9\n'
printf '\nwp-08-session-restart bounded kill+restart: PASS\n'
