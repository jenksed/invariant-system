#!/usr/bin/env bash
# M12-D WP-07 scenario: bounded Kiln daemon boot + bounded RPC, runnable
# from the monorepo.
#
#   The bounded daemon boots via `mix invariant serve` on an ephemeral
#   port with a runtime-generated scoped token injected via the
#   KILN_SCOPED_TOKENS environment variable (no credentials in source).
#   The scenario proves:
#     1. GET  /healthz                       -> 200
#     2. POST /api/rpc (valid bearer, authorized method project.list) -> 200
#     3. POST /api/rpc (bad/short bearer)    -> 401 bounded error envelope
#   then the daemon is stopped.
#
# Everything executes from this one checkout. Temporary state lives in a
# mktemp directory and is removed on exit unless KEEP_WORKDIR=1.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
KILN="$ROOT/products/kiln"

fail() {
  printf 'm12-d-daemon scenario: %s\n' "$1" >&2
  exit 1
}

for tool in mix curl openssl python3; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done

# Build product artifacts from this checkout when missing.
if [[ ! -d "$KILN/_build" ]]; then
  printf '==> compiling kiln (mix deps.get && mix compile)\n'
  (cd "$KILN" && mix deps.get >/dev/null && mix compile >/dev/null)
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/invariant-scenario-m12d.XXXXXX")
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

# Ephemeral port (bound-then-released; the daemon re-binds it).
PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')

# Runtime-generated scoped token (64 hex chars). Never stored in source.
READ_TOKEN=$(openssl rand -hex 32)
# Deliberately invalid credential input for the negative case (not a token).
BAD_TOKEN="short"

printf '==> starting bounded kiln daemon on 127.0.0.1:%s\n' "$PORT"
(
  cd "$KILN"
  KILN_SCOPED_TOKENS="${READ_TOKEN}:orchestration:read" \
    exec mix invariant serve --port "$PORT"
) >"$WORK/daemon.log" 2>&1 &
DAEMON_PID=$!

# Bounded readiness wait: poll /healthz for up to 30 seconds.
ready=0
for _ in $(seq 1 60); do
  if ! kill -0 "$DAEMON_PID" 2>/dev/null; then
    cat "$WORK/daemon.log" >&2 || true
    fail "daemon exited before becoming ready"
  fi
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/healthz" 2>/dev/null || true)
  if [[ "$code" == "200" ]]; then
    ready=1
    break
  fi
  sleep 0.5
done
[[ "$ready" == "1" ]] || { cat "$WORK/daemon.log" >&2 || true; fail "daemon did not become ready on port $PORT"; }
printf 'healthz: 200 (daemon ready)\n'

# 2. Bounded RPC with valid bearer + authorized method -> 200.
code=$(curl -s -o "$WORK/rpc-ok.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${READ_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{"method":"project.list","params":{}}')
[[ "$code" == "200" ]] || fail "authorized POST /api/rpc returned $code (expected 200)"
python3 - "$WORK/rpc-ok.json" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert "projects" in body, f"unexpected RPC body: {body}"
print(f"authorized rpc project.list: 200 body={body}")
PY

# 3. Bounded RPC with bad/short bearer -> 401 bounded error envelope.
code=$(curl -s -o "$WORK/rpc-bad.json" -w '%{http_code}' \
  -X POST "http://127.0.0.1:${PORT}/api/rpc" \
  -H "Authorization: Bearer ${BAD_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{"method":"project.list","params":{}}')
[[ "$code" == "401" ]] || fail "bad-token POST /api/rpc returned $code (expected 401)"
python3 - "$WORK/rpc-bad.json" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert body.get("code") == "E_UNAUTHORIZED", f"unexpected error envelope: {body}"
print(f"bad-token rpc: 401 code={body['code']}")
PY

# 4. Stop the daemon and confirm the port is closed.
kill "$DAEMON_PID" 2>/dev/null || true
wait "$DAEMON_PID" 2>/dev/null || true
DAEMON_PID=""

printf '\nm12-d-daemon bounded boot + rpc: PASS\n'
