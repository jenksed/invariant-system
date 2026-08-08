#!/usr/bin/env bash
set -euo pipefail
PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FLOCI_OCI_ENV_FILE:-$PACK_DIR/.env.floci-oci}"
COMPOSE_FILE="$PACK_DIR/docker-compose.floci-oci.yml"
ARTIFACT_DIR="${FLOCI_OCI_ARTIFACT_DIR:-$PACK_DIR/.floci-artifacts}"
if [[ -f "$ENV_FILE" ]]; then
  _he="${FLOCI_OCI_ENDPOINT+x}"; _e="${FLOCI_OCI_ENDPOINT-}"
  set -a; source "$ENV_FILE"; set +a
  [[ -n "$_he" ]] && FLOCI_OCI_ENDPOINT="$_e"
fi
: "${FLOCI_OCI_ENDPOINT:=http://localhost:4599}"
: "${FLOCI_OCI_NAMESPACE:=floci-local}"
: "${FLOCI_OCI_TENANCY:=ocid1.tenancy.oc1..flocilocaltenancy0000000000000000000000000000000000000000}"
compose() { docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"; }
guard_endpoint() {
  case "$FLOCI_OCI_ENDPOINT" in http://localhost:4599|http://127.0.0.1:4599) ;; *) printf 'UNSAFE OCI endpoint: %s\n' "$FLOCI_OCI_ENDPOINT" >&2; return 64;; esac
}
wait_ready() {
  guard_endpoint
  for _ in $(seq 1 60); do
    if curl -fsS "$FLOCI_OCI_ENDPOINT/_floci-oci/health" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  printf 'floci-oci readiness timeout\n' >&2; compose logs >&2 || true; return 1
}
