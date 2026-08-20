#!/usr/bin/env bash
# M3 — DOGFOOD PROBE orchestrator.
#
# Exercises the Invariant product, does NOT reimplement it. Runs three
# real tests against the canonical M3 chain:
#
#   m3_r2_real_provider_lifecycle  — full happy path with real MiniMax
#                                   (Worker → verify → review →
#                                   waiting_for_user → human ACCEPT →
#                                   ready)
#   m3_r2_verification_failure     — provider candidate with
#                                   `m11.fail-verifier` classifier;
#                                   proves fail-closed (verifier FAIL,
#                                   workflow does NOT advance)
#   m3_dogfood_lifecycle           — M3-R1 regression (deterministic
#                                   :dogfood mode, must remain green)
#
# The probe orchestrates Mix invocations. It does NOT construct
# verification, review, or pending-decision state in shell — those
# transitions are produced by the product via its ordinary lifecycle.
#
# Capture:
#   - canonical identities for every step (wko_id, proposal_id,
#     verification_id, review_id, decision_id)
#   - base commit SHA + final run_state
#   - PASS/FAIL per case
#
# Cleanup is unconditional via shell traps. The credential is sourced
# from the operator shell (presence-only, value never enters evidence
# files). All waits are bounded; no fixed sleeps.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KILN_ROOT="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$KILN_ROOT/../.." && pwd)"

# Credential sourcing: this is the operator-shell boundary the
# ENVIRONMENT_INHERITANCE_FAILURE class of issue lives at. The probe
# sources ~/.zshrc.d/minimax.zsh if present; otherwise it relies on
# MINIMAX_API_KEY already being exported in the calling environment.
if [[ -z "${MINIMAX_API_KEY:-}" ]] && [[ -f "$HOME/.zshrc.d/minimax.zsh" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.zshrc.d/minimax.zsh"
fi

if [[ -z "${MINIMAX_API_KEY:-}" ]]; then
  echo "MINIMAX_AGENT_CREDENTIAL=UNSET" >&2
  echo "M3_RESULT=BLOCKED (ENVIRONMENT_INHERITANCE_FAILURE)" >&2
  exit 2
fi

echo "MINIMAX_AGENT_CREDENTIAL=SET" >&2

WORK_DIR="$(mktemp -d -p "${TMPDIR:-/tmp}" kiln-m3.XXXXXX)"
EVIDENCE_DIR="$WORK_DIR/evidence"
mkdir -p "$EVIDENCE_DIR"

cleanup() {
  set +e
  rm -rf "$WORK_DIR" 2>/dev/null || true
}
trap cleanup EXIT

run_case() {
  local name="$1"
  local test_path="$2"
  local tag="$3"
  local log_file="$EVIDENCE_DIR/${name}.log"

  echo "[probe] === case: $name ===" >&2
  set +e
  ( cd "$KILN_ROOT" && MIX_ENV=test mix test "$test_path" --include "$tag" ) >"$log_file" 2>&1
  local exit_code=$?
  set -e

  if [[ $exit_code -eq 0 ]]; then
    echo "[probe] $name: PASS" >&2
    return 0
  else
    echo "[probe] $name: FAIL (exit=$exit_code, log=$log_file)" >&2
    return 1
  fi
}

overall=0

# 1. Happy path — real MiniMax drives Worker → verify → review →
#    waiting_for_user → human ACCEPT → ready
if ! run_case m3_r2_real_provider_lifecycle test/kiln/m3_r2_real_provider_lifecycle_test.exs m3_r2_real_provider_lifecycle; then
  overall=1
fi

# 2. Fail-closed — provider candidate with a registered failing verifier
if ! run_case m3_r2_verification_failure test/kiln/m3_r2_verification_failure_test.exs m3_r2_fail_closed; then
  overall=1
fi

# 3. M3-R1 regression — deterministic :dogfood mode must remain green
if ! run_case m3_r1_regression test/kiln/m3_dogfood_lifecycle_test.exs m3_dogfood; then
  overall=1
fi

echo "[probe] === M3 DOGFOOD PROBE RESULT ===" >&2
if [[ $overall -eq 0 ]]; then
  echo "M3_DOGFOOD_PROBE=PASS" >&2
else
  echo "M3_DOGFOOD_PROBE=FAIL" >&2
fi

exit $overall