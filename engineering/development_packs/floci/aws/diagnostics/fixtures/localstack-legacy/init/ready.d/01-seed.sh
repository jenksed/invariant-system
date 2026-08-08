#!/bin/sh
set -eu
awslocal s3 mb s3://arsenal-flc03-migration
awslocal sqs create-queue --queue-name arsenal-flc03-migration >/dev/null
