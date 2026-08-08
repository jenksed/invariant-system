#!/usr/bin/env bash
set -euo pipefail

PACK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$PACK_DIR/docker-compose.floci.yml"
ENV_FILE="${FLOCI_ENV_FILE:-$PACK_DIR/.env.floci}"
ARTIFACT_DIR="${FLOCI_ARTIFACT_DIR:-$PACK_DIR/.floci-artifacts}"

# Preserve explicitly supplied process environment so it wins over the env file,
# matching normal CLI/Compose precedence. The env file supplies repository-local
# defaults but may never mask an unsafe caller override during endpoint validation.
_had_floci_image="${FLOCI_IMAGE+x}"
_had_expected_endpoint="${FLOCI_EXPECTED_ENDPOINT+x}"
_had_aws_endpoint="${AWS_ENDPOINT_URL+x}"
_had_region="${AWS_DEFAULT_REGION+x}"
_external_floci_image="${FLOCI_IMAGE-}"
_external_expected_endpoint="${FLOCI_EXPECTED_ENDPOINT-}"
_external_aws_endpoint="${AWS_ENDPOINT_URL-}"
_external_region="${AWS_DEFAULT_REGION-}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

[[ -n "$_had_floci_image" ]] && FLOCI_IMAGE="$_external_floci_image"
[[ -n "$_had_expected_endpoint" ]] && FLOCI_EXPECTED_ENDPOINT="$_external_expected_endpoint"
[[ -n "$_had_aws_endpoint" ]] && AWS_ENDPOINT_URL="$_external_aws_endpoint"
[[ -n "$_had_region" ]] && AWS_DEFAULT_REGION="$_external_region"

: "${FLOCI_IMAGE:=floci/floci:1.5.34-compat}"
: "${FLOCI_EXPECTED_ENDPOINT:=http://localhost:4566}"
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
  if [[ -z "${AWS_ENDPOINT_URL:-}" ]]; then
    printf 'refusing AWS call: AWS_ENDPOINT_URL is not set\n' >&2
    return 64
  fi

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
