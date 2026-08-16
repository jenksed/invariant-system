#!/usr/bin/env bash
# Basic-user run path.
# Runs the simulated Repository Recon pipeline against the target repo.
# Set LOADOUT_EXECUTION=kiln to run through the real Kiln supervision
# boundary; the default is simulate (the fake Kiln boundary).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f dist/cli.js ]; then
  npm run build
fi

REPO="${LOADOUT_TARGET_REPO:-$ROOT}"
EXECUTION_FLAG="--execution simulate"
if [ "${LOADOUT_EXECUTION:-}" = "kiln" ]; then
  EXECUTION_FLAG="--execution kiln"
fi

node "$ROOT/dist/cli.js" run \
  --goal "Understand this repository" \
  --repository "$REPO" \
  --pack repository-recon \
  $EXECUTION_FLAG
echo "run: OK (target=$REPO, execution=${LOADOUT_EXECUTION:-simulate})"
