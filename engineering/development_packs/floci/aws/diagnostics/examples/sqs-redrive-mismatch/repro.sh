#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../../scripts/common.sh"

guard_endpoint
suffix="${REPRO_SUFFIX:-flc03}"
queue_name="arsenal-${suffix}-work"
expected=5
queue_url="$(aws_local sqs get-queue-url --queue-name "$queue_name" --query QueueUrl --output text)"
policy="$(aws_local sqs get-queue-attributes --queue-url "$queue_url" --attribute-names RedrivePolicy --query 'Attributes.RedrivePolicy' --output text)"
actual="$(python3 - "$policy" <<'PY'
import json, sys
value = sys.argv[1]
try:
    data = json.loads(value)
except json.JSONDecodeError:
    print("MISSING")
else:
    print(data.get("maxReceiveCount", "MISSING"))
PY
)"

if [[ "$actual" != "$expected" ]]; then
  printf 'REPRODUCED flc03.sqs-redrive-mismatch expected=%s actual=%s\n' "$expected" "$actual"
  exit 1
fi

printf 'CLEARED flc03.sqs-redrive-mismatch expected=%s actual=%s\n' "$expected" "$actual"
