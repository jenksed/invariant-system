#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$PACK_DIR/docker-compose.floci.yml"
ENV_FILE="${FLOCI_ENV_FILE:-$PACK_DIR/.env.floci}"
ARTIFACT_DIR="${FLOCI_ARTIFACT_DIR:-$PACK_DIR/.floci-artifacts}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${FLOCI_IMAGE:=floci/floci:1.5.34-compat}"
: "${FLOCI_EXPECTED_ENDPOINT:=http://localhost:4566}"
: "${AWS_ENDPOINT_URL:=$FLOCI_EXPECTED_ENDPOINT}"
: "${AWS_DEFAULT_REGION:=us-east-1}"

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

ensure_tools() {
  local missing=0
  for tool in docker curl python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      printf 'missing required tool: %s\n' "$tool" >&2
      missing=1
    fi
  done
  if ! docker compose version >/dev/null 2>&1; then
    printf 'docker compose v2 is required\n' >&2
    missing=1
  fi
  return "$missing"
}

guard_endpoint() {
  if [[ "$AWS_ENDPOINT_URL" != "$FLOCI_EXPECTED_ENDPOINT" ]]; then
    printf 'refusing AWS call: AWS_ENDPOINT_URL=%q expected=%q\n' \
      "$AWS_ENDPOINT_URL" "$FLOCI_EXPECTED_ENDPOINT" >&2
    return 64
  fi

  case "$AWS_ENDPOINT_URL" in
    http://localhost:4566|http://127.0.0.1:4566) ;;
    *)
      printf 'refusing AWS call: endpoint is not approved loopback Floci URL: %s\n' \
        "$AWS_ENDPOINT_URL" >&2
      return 64
      ;;
  esac
}

aws_local() {
  guard_endpoint
  if ! command -v aws >/dev/null 2>&1; then
    printf 'missing required tool: aws\n' >&2
    return 127
  fi

  env \
    -u AWS_PROFILE \
    -u AWS_DEFAULT_PROFILE \
    AWS_CONFIG_FILE=/dev/null \
    AWS_SHARED_CREDENTIALS_FILE=/dev/null \
    AWS_ACCESS_KEY_ID=test \
    AWS_SECRET_ACCESS_KEY=test \
    AWS_SESSION_TOKEN= \
    AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
    AWS_EC2_METADATA_DISABLED=true \
    AWS_ENDPOINT_URL="$AWS_ENDPOINT_URL" \
    aws --endpoint-url "$AWS_ENDPOINT_URL" "$@"
}
