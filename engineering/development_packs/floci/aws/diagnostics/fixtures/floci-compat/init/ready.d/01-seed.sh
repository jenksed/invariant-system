#!/bin/sh
set -eu
aws s3 mb s3://arsenal-flc03-migration
aws sqs create-queue --queue-name arsenal-flc03-migration >/dev/null
