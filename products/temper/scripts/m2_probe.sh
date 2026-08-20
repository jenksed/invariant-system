#!/usr/bin/env bash
# M2 — TEMPER DURABLE probe orchestrator.
#
# Reuses the proven M1 real-daemon/runtime machinery and extends it
# with bounded process lifecycle control (kill Temper, restart
# Temper, kill Kiln, restart Kiln against the same KILN_HOME).
#
#   M2-A  active-session reconnect  (start → kill client → restart)
#   M2-B  pending-decision reconnect (drive to waiting_for_user →
#         kill client → restart → envelope survives)
#   M2-C  stale-context rejection   (mutated envelope → reject →
#         resync to canonical)
#   M2-D  Kiln restart + replay     (kill daemon → spawn new against
#         same KILN_HOME → canonical projection hydrates)
#
# Cleanup is unconditional via shell traps. No long-lived secrets.
# All waits are bounded polls; no fixed sleeps.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPER_ROOT="$(cd "$HERE/.." && pwd)"
KILN_ROOT="$(cd "$TEMPER_ROOT/../kiln" && pwd)"
REPO_ROOT="$(cd "$TEMPER_ROOT/../.." && pwd)"

WORK_DIR="$(mktemp -d -p "$(echo "${TMPDIR:-/tmp}" | sed 's:/$::')" kiln-m2.XXXXXX)"
KILN_HOME="$WORK_DIR/kiln-home"
REPO_DIR="$WORK_DIR/target-repo"
mkdir -p "$KILN_HOME/artifacts"
mkdir -p "$REPO_DIR"
git -C "$REPO_DIR" init -q --initial-branch=main >/dev/null
git -C "$REPO_DIR" -c user.name=Temper -c user.email=temper@local \
  commit --allow-empty -qm "M2 fixture initial commit" >/dev/null

find_free_port() {
  python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()'
}
KILN_PORT="$(find_free_port)"

KILN_READ_TOKEN="$(python3 -c 'import secrets;print(secrets.token_hex(32))')"
KILN_OPERATE_TOKEN="$(python3 -c 'import secrets;print(secrets.token_hex(32))')"

export KILN_READ_TOKEN
export KILN_OPERATE_TOKEN
SCOPED_TOKENS_JSON="$(python3 -c "
import json, os
print(json.dumps({
  os.environ['KILN_READ_TOKEN']: 'orchestration:read',
  os.environ['KILN_OPERATE_TOKEN']: 'orchestration:operate',
}))
")"

KILN_PID=""
KILN_PID_2=""
cleanup() {
  set +e
  for pid in "$KILN_PID" "$KILN_PID_2"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
    fi
  done
  echo "M2_PROBE_CLEANUP_WORKDIR=$WORK_DIR" >&2
  if [[ "${M2_KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT INT TERM

# Boot the FIRST daemon (used by M2-A, B, C).
KILN_PID_FILE="$WORK_DIR/kiln.pid"
(
  cd "$KILN_ROOT"
  KILN_HOME="$KILN_HOME" \
  KILN_PORT="$KILN_PORT" \
  SCOPED_TOKENS="$SCOPED_TOKENS_JSON" \
  exec mix run --no-halt "$HERE/m1_kiln_runtime.exs" \
    >"$WORK_DIR/kiln-1.log" 2>&1
) &
KILN_PID=$!
echo "$KILN_PID" > "$KILN_PID_FILE"

KILN_URL="http://127.0.0.1:${KILN_PORT}"
KILN_WS_URL="ws://127.0.0.1:${KILN_PORT}/ws"

# Bounded readiness poll for /healthz.
ready=0
for _ in $(seq 1 50); do
  if curl -fsS "${KILN_URL}/healthz" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$KILN_PID" 2>/dev/null; then
    echo "M2_PROBE_KILN_HEALTH=FAIL" >&2
    echo "--- kiln-1.log ---" >&2
    cat "$WORK_DIR/kiln-1.log" >&2 || true
    exit 2
  fi
  sleep 0.2
done

if [[ "$ready" -ne 1 ]]; then
  echo "M2_PROBE_KILN_HEALTH=FAIL (timeout)" >&2
  echo "--- kiln-1.log ---" >&2
  cat "$WORK_DIR/kiln-1.log" >&2 || true
  exit 2
fi

# Persist runtime info so successive node invocations can coordinate.
cat >"$WORK_DIR/runtime.info" <<EOF
KILN_PID=$KILN_PID
KILN_LOG=$WORK_DIR/kiln-1.log
KILN_HOME=$KILN_HOME
KILN_PORT=$KILN_PORT
KILN_URL=$KILN_URL
KILN_WS_URL=$KILN_WS_URL
KILN_READ_TOKEN=$KILN_READ_TOKEN
KILN_OPERATE_TOKEN=$KILN_OPERATE_TOKEN
KILN_REPO_PATH=$REPO_DIR
KILN_ROOT=$KILN_ROOT
EOF

run_node_probe() {
  local phase_label="$1"
  echo "M2_PROBE_PHASE=$phase_label" >&2
  KILN_URL="$KILN_URL" \
  KILN_WS_URL="$KILN_WS_URL" \
  KILN_READ_TOKEN="$KILN_READ_TOKEN" \
  KILN_OPERATE_TOKEN="$KILN_OPERATE_TOKEN" \
  KILN_REPO_PATH="$REPO_DIR" \
  KILN_ROOT="$KILN_ROOT" \
  KILN_HOME="$KILN_HOME" \
  KILN_PORT="$KILN_PORT" \
  M2_RUNTIME_INFO="$WORK_DIR/runtime.info" \
  M2_PHASE="$phase_label" \
  node "$HERE/m2_probe.mjs"
  return $?
}

# M2-A: kill Temper mid-session, restart, observe same session.
run_node_probe A
a_rc=$?
run_node_probe A-VERIFY
a_verify_rc=$?

# M2-B: drive to waiting_for_user via session.resume (HTTP) + review-propose.
run_node_probe B
b_rc=$?

# M2-C: stale context rejection (between B and B-VERIFY).
run_node_probe C
c_rc=$?

# M2-B-VERIFY: reconnect and accept.
run_node_probe B-VERIFY
b_verify_rc=$?

# M2-D: kill Kiln, spawn new against same KILN_HOME, replay.
kill_first_daemon() {
  local port="$KILN_PORT"
  if command -v lsof >/dev/null 2>&1; then
    local pids
    pids=$(lsof -ti tcp:"$port" 2>/dev/null | tr '\n' ' ')
    if [[ -n "$pids" ]]; then
      echo "M2_D_KILLING_PIDS=$pids" >&2
      kill -9 $pids 2>/dev/null || true
    fi
  fi
  local deadline=$(( $(date +%s) + 10 ))
  while [[ $(date +%s) -lt $deadline ]]; do
    if ! lsof -ti tcp:"$port" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done
  return 1
}

kill_first_daemon || {
  echo "M2_D_KILL=FAIL" >&2
  echo "M2_PROBE=FAIL"; exit 1
}

(
  cd "$KILN_ROOT"
  KILN_HOME="$KILN_HOME" \
  KILN_PORT="$KILN_PORT" \
  SCOPED_TOKENS="$SCOPED_TOKENS_JSON" \
  exec mix run --no-halt "$HERE/m2_kiln_restart.exs" \
    >>"$WORK_DIR/kiln-2.log" 2>&1
) &
KILN_PID_2=$!
echo "M2_D_SECOND_DAEMON_PID=$KILN_PID_2" >&2

deadline=$(( $(date +%s) + 30 ))
ready2=0
while [[ $(date +%s) -lt $deadline ]]; do
  if curl -fsS "${KILN_URL}/healthz" >/dev/null 2>&1; then
    ready2=1
    break
  fi
  if ! kill -0 "$KILN_PID_2" 2>/dev/null; then
    echo "M2_D_SECOND_DAEMON_HEALTH=FAIL" >&2
    tail -n 80 "$WORK_DIR/kiln-2.log" >&2 || true
    echo "M2_PROBE=FAIL"; exit 1
  fi
  sleep 0.2
done
if [[ "$ready2" -ne 1 ]]; then
  echo "M2_D_SECOND_DAEMON_HEALTH=FAIL (timeout)" >&2
  tail -n 80 "$WORK_DIR/kiln-2.log" >&2 || true
  echo "M2_PROBE=FAIL"; exit 1
fi

run_node_probe D
d_rc=$?

final_rc=0
for rc in "$a_rc" "$a_verify_rc" "$b_rc" "$c_rc" "$b_verify_rc" "$d_rc"; do
  if [[ "$rc" -ne 0 ]]; then final_rc="$rc"; fi
done

if [[ "$final_rc" -ne 0 ]]; then
  echo "--- kiln-1.log (tail) ---" >&2
  tail -n 120 "$WORK_DIR/kiln-1.log" >&2 || true
  echo "--- kiln-2.log (tail) ---" >&2
  tail -n 120 "$WORK_DIR/kiln-2.log" >&2 || true
fi

exit "$final_rc"