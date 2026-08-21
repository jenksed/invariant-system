#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
KILN="$ROOT/products/kiln"
TEMPER="$ROOT/products/temper"

fail() {
  printf 'temper-command-control scenario: %s\n' "$1" >&2
  exit 1
}

for tool in git mix node npm curl openssl python3; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done

(cd "$KILN" && mix compile >/dev/null)
(cd "$TEMPER" && npm run build >/dev/null)

WORK=$(mktemp -d "${TMPDIR:-/tmp}/invariant-temper-command-control.XXXXXX")
LOG="$WORK/kiln.log"
REPO="$WORK/repo"
CONFIG_PATH="$WORK/temper.json"
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

mkdir -p "$REPO"
printf '# Temper slash-control integration\n' >"$REPO/README.md"
git -C "$REPO" init -q -b main
git -C "$REPO" add README.md
git -C "$REPO" -c user.name=temper-control -c user.email=temper-control@localhost \
  commit -q -m 'temper slash-control seed'

STATE_PATH="$REPO/.kiln/state.sqlite3"
mkdir -p "$(dirname "$STATE_PATH")"
PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
READ_TOKEN=$(openssl rand -hex 32)
OPERATE_TOKEN=$(openssl rand -hex 32)
SCOPED_TOKENS="${READ_TOKEN}:orchestration:read,${OPERATE_TOKEN}:orchestration:operate"

printf '==> start real Kiln daemon on 127.0.0.1:%s\n' "$PORT"
(
  cd "$KILN"
  KILN_SCOPED_TOKENS="$SCOPED_TOKENS" \
    exec mix invariant serve --port "$PORT" --state-path "$STATE_PATH"
) >"$LOG" 2>&1 &
DAEMON_PID=$!

ready=0
for _ in $(seq 1 60); do
  if ! kill -0 "$DAEMON_PID" 2>/dev/null; then
    cat "$LOG" >&2 || true
    fail 'Kiln daemon exited before readiness'
  fi
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/healthz" 2>/dev/null || true)
  if [[ "$code" == "200" ]]; then
    ready=1
    break
  fi
  sleep 0.5
done
[[ "$ready" == "1" ]] || { cat "$LOG" >&2; fail 'Kiln daemon did not become ready'; }

printf '==> execute compiled Temper slash registry against real Kiln\n'
node "$HERE/run.mjs" \
  "$ROOT" \
  "$REPO" \
  "http://127.0.0.1:${PORT}" \
  "ws://127.0.0.1:${PORT}/ws" \
  "$READ_TOKEN" \
  "$OPERATE_TOKEN" \
  "$CONFIG_PATH" \
  || { cat "$LOG" >&2 || true; fail 'real-daemon slash-command vertical failed'; }

printf '\ntemper-command-control scenario: PASS\n'
