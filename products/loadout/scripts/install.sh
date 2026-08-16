#!/usr/bin/env bash
# Basic-user install path.
# Installs npm dependencies and the bundled repository-recon pack into
# the target repository's .loadout/ workspace.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -d node_modules ]; then
  npm ci --cache "${NPM_CONFIG_CACHE:-/tmp/claude/npm-cache}"
fi

if [ ! -f dist/cli.js ]; then
  npm run build
fi

REPO="${LOADOUT_TARGET_REPO:-$ROOT}"
node "$ROOT/dist/cli.js" install repository-recon --repository "$REPO"
echo "install: OK (target=$REPO)"
