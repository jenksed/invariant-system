#!/usr/bin/env bash
# Basic-user run path.
# Runs the simulated Repository Recon pipeline against the target repo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f dist/cli.js ]; then
  npm run build
fi

REPO="${LOADOUT_TARGET_REPO:-$ROOT}"
node "$ROOT/dist/cli.js" run \
  --goal "Understand this repository" \
  --repository "$REPO" \
  --pack repository-recon
echo "run: OK (target=$REPO)"
