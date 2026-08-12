#!/usr/bin/env bash
# Basic-user remove path.
# Removes the bundled pack from the target repo workspace and verifies
# the workspace is empty.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f dist/cli.js ]; then
  npm run build
fi

REPO="${LOADOUT_TARGET_REPO:-$ROOT}"
node "$ROOT/dist/cli.js" remove repository-recon --repository "$REPO"
if [ -d "$REPO/.loadout/packs/repository-recon" ]; then
  echo "remove: FAILED (pack directory still present)" >&2
  exit 1
fi
echo "remove: OK (target=$REPO)"
