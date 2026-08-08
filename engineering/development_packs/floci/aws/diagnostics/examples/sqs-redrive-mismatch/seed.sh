#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../../../scripts/common.sh"

guard_endpoint

suffix="${REPRO_SUFFIX:-flc03}"
dlq_name="arsenal-${suffix}-dlq"
queue_name="arsenal-${suffix}-work"

dlq_url="$(aws_local sqs create-queue --queue-name "$dlq_name" --query QueueUrl --output text)"
dlq_arn="$(aws_local sqs get-queue-attributes --queue-url "$dlq_url" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)"
queue_url="$(aws_local sqs create-queue --queue-name "$queue_name" --query QueueUrl --output text)"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
python3 - "$queue_url" "$dlq_arn" <<'PY' >"$tmp"
import json, sys
queue_url, dlq_arn = sys.argv[1:]
policy = json.dumps({"deadLetterTargetArn": dlq_arn, "maxReceiveCount": "3"}, separators=(",", ":"))
print(json.dumps({"QueueUrl": queue_url, "Attributes": {"RedrivePolicy": policy}}))
PY

aws_local sqs set-queue-attributes --cli-input-json "file://$tmp"
printf 'seeded %s with maxReceiveCount=3\n' "$queue_name"
