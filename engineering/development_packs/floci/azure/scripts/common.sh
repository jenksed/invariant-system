#!/usr/bin/env bash
set -euo pipefail
PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${FLOCI_AZ_ENV_FILE:-$PACK_DIR/.env.floci-az}"
COMPOSE_FILE="$PACK_DIR/docker-compose.floci-az.yml"
ARTIFACT_DIR="${FLOCI_AZ_ARTIFACT_DIR:-$PACK_DIR/.floci-artifacts}"

if [[ -f "$ENV_FILE" ]]; then
  _had_endpoint="${FLOCI_AZ_ENDPOINT+x}"; _endpoint="${FLOCI_AZ_ENDPOINT-}"
  _had_conn="${AZURE_STORAGE_CONNECTION_STRING+x}"; _conn="${AZURE_STORAGE_CONNECTION_STRING-}"
  set -a; source "$ENV_FILE"; set +a
  [[ -n "$_had_endpoint" ]] && FLOCI_AZ_ENDPOINT="$_endpoint"
  [[ -n "$_had_conn" ]] && AZURE_STORAGE_CONNECTION_STRING="$_conn"
fi
: "${FLOCI_AZ_ENDPOINT:=http://localhost:4577}"
if [[ -z "${AZURE_STORAGE_CONNECTION_STRING:-}" ]]; then
  _local_key="$(python3 - <<'PYKEY'
import base64
print(base64.b64encode(b"project-arsenal-floci-azure-local-only").decode())
PYKEY
)"
  AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=${_local_key};BlobEndpoint=${FLOCI_AZ_ENDPOINT}/devstoreaccount1;QueueEndpoint=${FLOCI_AZ_ENDPOINT}/devstoreaccount1-queue;TableEndpoint=${FLOCI_AZ_ENDPOINT}/devstoreaccount1-table;"
  export AZURE_STORAGE_CONNECTION_STRING
fi

compose() { docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"; }

guard_endpoint() {
  [[ "$FLOCI_AZ_ENDPOINT" == "http://localhost:4577" || "$FLOCI_AZ_ENDPOINT" == "http://127.0.0.1:4577" ]] || {
    printf 'UNSAFE Azure endpoint: %s\n' "$FLOCI_AZ_ENDPOINT" >&2; return 64; }
  [[ -n "${AZURE_STORAGE_CONNECTION_STRING:-}" ]] || { printf 'missing AZURE_STORAGE_CONNECTION_STRING\n' >&2; return 64; }
  python3 - "$AZURE_STORAGE_CONNECTION_STRING" <<'PY'
import sys
parts={}
for item in sys.argv[1].split(';'):
    if '=' in item:
        k,v=item.split('=',1); parts[k]=v
expected={
 'BlobEndpoint': {'http://localhost:4577/devstoreaccount1','http://127.0.0.1:4577/devstoreaccount1'},
 'QueueEndpoint': {'http://localhost:4577/devstoreaccount1-queue','http://127.0.0.1:4577/devstoreaccount1-queue'},
}
for key, allowed in expected.items():
    if parts.get(key) not in allowed:
        raise SystemExit(f'UNSAFE Azure {key}: {parts.get(key)!r}')
if parts.get('AccountName') != 'devstoreaccount1':
    raise SystemExit('unexpected Azure development account')
PY
}

wait_ready() {
  guard_endpoint
  for _ in $(seq 1 60); do
    if curl -fsS "$FLOCI_AZ_ENDPOINT/health" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  printf 'floci-az readiness timeout\n' >&2
  compose logs >&2 || true
  return 1
}
