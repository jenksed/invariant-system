#!/usr/bin/env bash
# M1 — TEMPER OPERABLE probe orchestrator.
#
# Boots a real Kiln.Daemon with bounded scoped tokens, waits for
# /healthz, then invokes the Node.js probe (scripts/m1_probe.mjs)
# which exercises the real WorkbenchConnection through:
#
#   session.start  (M1-A)
#   session.query  (M1-B)
#   review-propose (CLI) + human.decide  (M1-C, harness-defect)
#
# Cleanup is unconditional via shell traps. No long-lived secrets,
# no external network, no fixed sleeps.
#
# --------------------------------------------------------------------------
# STATUS: FROZEN HISTORICAL ARTIFACT — not current regression authority.
#
# The M1-C slice below invokes `mix kiln session-resume`, which is not a
# Mix task in the canonical CLI surface (the canonical transition is the
# bounded `session.resume` HTTP RPC). This harness defect was present in
# the original M1 acceptance at 5d152e7 and is left untouched here so that
# the historical evidence is reproducible verbatim.
#
# Current regression authority for the M1-C property (real daemon, real
# RPC boundary, real human.decide, canonical waiting_for_user → ready
# transition) lives in:
#
#   products/temper/scripts/m2_probe.sh
#     → M2-B (drives :running → :waiting_for_user)
#     → M2-B-VERIFY (reconnect, submitHumanDecision, run_state=ready)
#
# A green end-to-end m2_probe.sh run + a green
# products/kiln/test/kiln/decision_lifecycle_test.exs (10/10) together
# prove the M1-C property holds today. Do not interpret a non-zero
# m1_probe.sh exit as a regression of M1-C — interpret it as the known
# harness defect documented above.
# --------------------------------------------------------------------------

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPER_ROOT="$(cd "$HERE/.." && pwd)"
KILN_ROOT="$(cd "$TEMPER_ROOT/../kiln" && pwd)"
REPO_ROOT="$(cd "$TEMPER_ROOT/../.." && pwd)"

WORK_DIR="$(mktemp -d -p "$(echo "${TMPDIR:-/tmp}" | sed 's:/$::')" kiln-m1.XXXXXX)"
KILN_HOME="$WORK_DIR/kiln-home"
REPO_DIR="$WORK_DIR/target-repo"
mkdir -p "$KILN_HOME/artifacts"
mkdir -p "$REPO_DIR"
git -C "$REPO_DIR" init -q --initial-branch=main >/dev/null
git -C "$REPO_DIR" -c user.name=Temper -c user.email=temper@local \
  commit --allow-empty -qm "M1 fixture initial commit" >/dev/null

# Pick a likely-free port; bounded retry if the daemon can't bind.
find_free_port() {
  python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()'
}
KILN_PORT="$(find_free_port)"

# Generate bounded scoped tokens; never reuse across runs.
KILN_READ_TOKEN="$(python3 -c 'import secrets;print(secrets.token_hex(32))')"
KILN_OPERATE_TOKEN="$(python3 -c 'import secrets;print(secrets.token_hex(32))')"

# JSON-encoded tokens map for the runtime. Export first so the
# python invocation sees them in os.environ.
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
cleanup() {
  set +e
  if [[ -n "$KILN_PID" ]] && kill -0 "$KILN_PID" 2>/dev/null; then
    kill "$KILN_PID" 2>/dev/null || true
    wait "$KILN_PID" 2>/dev/null || true
  fi
  echo "M1_PROBE_CLEANUP_WORKDIR=$WORK_DIR" >&2
  echo "M1_PROBE_CLEANUP_KILN_PID=$KILN_PID" >&2
  if [[ "${M1_KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT INT TERM

# Boot the daemon as a background process. Mix run --no-halt keeps
# the application alive; the runtime.exs adds Kiln.Daemon to the
# supervision tree and blocks on receive.
KILN_PID_FILE="$WORK_DIR/kiln.pid"
(
  cd "$KILN_ROOT"
  KILN_HOME="$KILN_HOME" \
  KILN_PORT="$KILN_PORT" \
  SCOPED_TOKENS="$SCOPED_TOKENS_JSON" \
  exec mix run --no-halt "$HERE/m1_kiln_runtime.exs" \
    >"$WORK_DIR/kiln.log" 2>&1
) &
KILN_PID=$!
echo "$KILN_PID" > "$KILN_PID_FILE"

KILN_URL="http://127.0.0.1:${KILN_PORT}"
KILN_WS_URL="ws://127.0.0.1:${KILN_PORT}/ws"

# Bounded readiness poll for /healthz; never sleep fixed durations.
ready=0
for _ in $(seq 1 50); do
  if curl -fsS "${KILN_URL}/healthz" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! kill -0 "$KILN_PID" 2>/dev/null; then
    echo "M1_PROBE_KILN_HEALTH=FAIL" >&2
    echo "M1_PROBE_KILN_HEALTH_REASON=daemon process exited before becoming ready" >&2
    echo "--- kiln.log ---" >&2
    cat "$WORK_DIR/kiln.log" >&2 || true
    exit 2
  fi
  sleep 0.2
done

if [[ "$ready" -ne 1 ]]; then
  echo "M1_PROBE_KILN_HEALTH=FAIL" >&2
  echo "M1_PROBE_KILN_HEALTH_REASON=daemon did not become ready within bounded window" >&2
  echo "--- kiln.log ---" >&2
  cat "$WORK_DIR/kiln.log" >&2 || true
  exit 2
fi

# Run the Node.js probe with the bounded env wired in.
KILN_URL="$KILN_URL" \
KILN_WS_URL="$KILN_WS_URL" \
KILN_READ_TOKEN="$KILN_READ_TOKEN" \
KILN_OPERATE_TOKEN="$KILN_OPERATE_TOKEN" \
KILN_REPO_PATH="$REPO_DIR" \
KILN_ROOT="$KILN_ROOT" \
node "$HERE/m1_probe.mjs"
probe_rc=$?

# Emit the daemon log on non-zero exit so the failure is
# investigable without rerunning.
if [[ $probe_rc -ne 0 ]]; then
  echo "--- kiln.log (tail) ---" >&2
  tail -n 80 "$WORK_DIR/kiln.log" >&2 || true
fi

exit $probe_rc
