#!/usr/bin/env bash
set -euo pipefail
PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FLOCI_GCP_ENV_FILE:-$PACK_DIR/.env.floci-gcp}"
COMPOSE_FILE="$PACK_DIR/docker-compose.floci-gcp.yml"
ARTIFACT_DIR="${FLOCI_GCP_ARTIFACT_DIR:-$PACK_DIR/.floci-artifacts}"
if [[ -f "$ENV_FILE" ]]; then
  _he="${FLOCI_GCP_ENDPOINT+x}"; _e="${FLOCI_GCP_ENDPOINT-}"
  _hs="${STORAGE_EMULATOR_HOST+x}"; _s="${STORAGE_EMULATOR_HOST-}"
  _hp="${PUBSUB_EMULATOR_HOST+x}"; _p="${PUBSUB_EMULATOR_HOST-}"
  set -a; source "$ENV_FILE"; set +a
  [[ -n "$_he" ]] && FLOCI_GCP_ENDPOINT="$_e"
  [[ -n "$_hs" ]] && STORAGE_EMULATOR_HOST="$_s"
  [[ -n "$_hp" ]] && PUBSUB_EMULATOR_HOST="$_p"
fi
: "${FLOCI_GCP_ENDPOINT:=http://localhost:4588}"
: "${FLOCI_GCP_PROJECT:=floci-local}"
compose() { docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"; }
guard_endpoint() {
  case "$FLOCI_GCP_ENDPOINT" in http://localhost:4588|http://127.0.0.1:4588) ;; *) printf 'UNSAFE GCP endpoint: %s\n' "$FLOCI_GCP_ENDPOINT" >&2; return 64;; esac
  case "${STORAGE_EMULATOR_HOST:-}" in http://localhost:4588|http://127.0.0.1:4588) ;; *) printf 'UNSAFE STORAGE_EMULATOR_HOST: %s\n' "${STORAGE_EMULATOR_HOST:-<missing>}" >&2; return 64;; esac
  case "${PUBSUB_EMULATOR_HOST:-}" in localhost:4588|127.0.0.1:4588) ;; *) printf 'UNSAFE PUBSUB_EMULATOR_HOST: %s\n' "${PUBSUB_EMULATOR_HOST:-<missing>}" >&2; return 64;; esac
}
wait_ready() {
  guard_endpoint
  for _ in $(seq 1 60); do
    if curl -fsS "$FLOCI_GCP_ENDPOINT/" >/dev/null 2>&1 || curl -fsS "$FLOCI_GCP_ENDPOINT/_floci-gcp/health" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  printf 'floci-gcp readiness timeout\n' >&2; compose logs >&2 || true; return 1
}
