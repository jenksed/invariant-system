#!/usr/bin/env bash
# Full local verification surface for LOD-01.
# Runs from a clean checkout; exits non-zero on first failure.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Use a writable npm cache to avoid stale root-owned files in ~/.npm.
export NPM_CONFIG_CACHE="${NPM_CONFIG_CACHE:-/tmp/claude/npm-cache}"

echo "== git diff --check =="
git diff --check

echo "== npm ci =="
npm ci

echo "== format:check =="
npm run format:check

echo "== lint =="
npm run lint

echo "== typecheck =="
npm run typecheck

echo "== test =="
npm test

echo "== validate:contracts =="
node "$ROOT/dist/cli.js" validate-contracts

echo "== build =="
npm run build

echo "== install.sh =="
bash scripts/install.sh

echo "== run.sh =="
bash scripts/run.sh

echo "== remove.sh =="
bash scripts/remove.sh

echo "verify: OK"
