#!/usr/bin/env bash
set -euo pipefail

IAC_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_DIR="$(cd "$IAC_SCRIPT_DIR/.." && pwd)"
AWS_PACK_DIR="$(cd "$IAC_DIR/.." && pwd)"

# Reuse the proven FLC-01 runtime, endpoint guard, Compose wrapper, and AWS CLI boundary.
# shellcheck source=../../scripts/common.sh
source "$AWS_PACK_DIR/scripts/common.sh"

IAC_ARTIFACT_DIR="${FLOCI_IAC_ARTIFACT_DIR:-$ARTIFACT_DIR/iac}"
IAC_WORK_ROOT="${FLOCI_IAC_WORK_ROOT:-${TMPDIR:-/tmp}/arsenal-floci-iac}"
TERRAFORM_IMAGE="${FLOCI_TERRAFORM_IMAGE:-hashicorp/terraform:1.14.7}"
OPENTOFU_IMAGE="${FLOCI_OPENTOFU_IMAGE:-ghcr.io/opentofu/opentofu:1.8}"
AWS_PROVIDER_VERSION="${FLOCI_AWS_PROVIDER_VERSION:-6.44.0}"
FLOCI_CONTAINER_ENDPOINT="${FLOCI_CONTAINER_ENDPOINT:-http://floci:4566}"

mkdir -p "$IAC_ARTIFACT_DIR" "$IAC_WORK_ROOT"

ensure_iac_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    cp "$AWS_PACK_DIR/env.floci.example" "$ENV_FILE"
  fi

  local had_endpoint="${AWS_ENDPOINT_URL+x}"
  local explicit_endpoint="${AWS_ENDPOINT_URL-}"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
  [[ -n "$had_endpoint" ]] && AWS_ENDPOINT_URL="$explicit_endpoint"
  export AWS_ENDPOINT_URL
  guard_endpoint
}

capture_floci_evidence() {
  local label="${1:-run}"
  mkdir -p "$IAC_ARTIFACT_DIR"
  compose logs --no-color >"$IAC_ARTIFACT_DIR/floci-${label}.log" 2>&1 || true
  docker ps -a --no-trunc >"$IAC_ARTIFACT_DIR/docker-${label}.txt" 2>&1 || true
}

raw_reset_floci() {
  guard_endpoint
  local response
  response="$(curl -fsS -X POST "$AWS_ENDPOINT_URL/_floci/state/reset")"
  python3 - "$response" <<'PY'
import json, sys
doc = json.loads(sys.argv[1])
if doc.get("status") != "OK":
    raise SystemExit(f"unexpected reset response: {doc!r}")
PY
}

sha256_paths() {
  python3 - "$@" <<'PY'
import hashlib
from pathlib import Path
import sys

h = hashlib.sha256()
for index, raw in enumerate(sys.argv[1:]):
    root = Path(raw)
    files = sorted(x for x in (root.rglob('*') if root.is_dir() else [root]) if x.is_file())
    for f in files:
        label = f.relative_to(root) if root.is_dir() else Path(f.name)
        h.update(str(index).encode())
        h.update(b':')
        h.update(str(label).encode())
        h.update(b'\0')
        h.update(f.read_bytes())
        h.update(b'\0')
print(h.hexdigest())
PY
}

iac_image() {
  case "$1" in
    terraform) printf '%s\n' "$TERRAFORM_IMAGE" ;;
    opentofu) printf '%s\n' "$OPENTOFU_IMAGE" ;;
    *) printf 'unsupported IaC engine: %s\n' "$1" >&2; return 64 ;;
  esac
}

iac_binary() {
  case "$1" in
    terraform) printf 'terraform\n' ;;
    opentofu) printf 'tofu\n' ;;
    *) printf 'unsupported IaC engine: %s\n' "$1" >&2; return 64 ;;
  esac
}

prepare_iac_workdir() {
  local tool="$1" namespace="$2"
  local work="$IAC_WORK_ROOT/${tool}-${namespace}"
  rm -rf "$work"
  mkdir -p "$work"
  cp "$IAC_DIR/terraform/provider.tf" "$IAC_DIR/terraform/main.tf" "$work/"
  printf '%s\n' "$work"
}

floci_network() {
  local cid
  cid="$(compose ps -q floci)"
  [[ -n "$cid" ]] || { printf 'Floci container is not running\n' >&2; return 1; }
  docker inspect -f '{{range $name, $_ := .NetworkSettings.Networks}}{{$name}}{{"\n"}}{{end}}' "$cid" | head -n1
}

iac_exec() {
  local tool="$1" work="$2"
  shift 2
  local image binary network
  image="$(iac_image "$tool")"
  binary="$(iac_binary "$tool")"
  network="$(floci_network)"

  docker run --rm \
    --network "$network" \
    -v "$work:/workspace" \
    -w /workspace \
    -e TF_IN_AUTOMATION=1 \
    -e CHECKPOINT_DISABLE=1 \
    -e AWS_ACCESS_KEY_ID=test \
    -e AWS_SECRET_ACCESS_KEY=test \
    -e AWS_DEFAULT_REGION=us-east-1 \
    -e AWS_EC2_METADATA_DISABLED=true \
    --entrypoint "$binary" \
    "$image" "$@"
}

assert_iac_present() {
  "$IAC_SCRIPT_DIR/assert-iac" present "$1"
}

assert_iac_absent() {
  "$IAC_SCRIPT_DIR/assert-iac" absent "$1"
}
