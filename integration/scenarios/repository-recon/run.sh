#!/usr/bin/env bash
# Wave 3 golden path (TEST-MATRIX section A), runnable from the monorepo.
#
#   Loadout compiles a Work Envelope for the proof-repo fixture,
#   the real Kiln supervises the run (mix kiln supervise),
#   Temper renders the recorded Run Result.
#
# This runner covers the golden path only. The full Wave 3 matrix
# (restart durability, 8 negative cases, dogfood) is specified in
# TEST-MATRIX.md and remains the job of a dedicated integration verifier.
#
# Everything executes from this one checkout; no sibling repositories are
# cloned. Temporary state lives in a mktemp directory and is removed on
# exit unless KEEP_WORKDIR=1.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
LOADOUT="$ROOT/products/loadout"
KILN="$ROOT/products/kiln"
TEMPER="$ROOT/products/temper"

fail() {
  printf 'repository-recon scenario: %s\n' "$1" >&2
  exit 1
}

for tool in git node npm mix python3; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done

# Build product artifacts from this checkout when missing.
if [[ ! -f "$LOADOUT/dist/cli.js" ]]; then
  printf '==> building loadout\n'
  (cd "$LOADOUT" && npm ci --silent && npm run build >/dev/null)
fi
if [[ ! -f "$TEMPER/dist/src/cli.js" ]]; then
  printf '==> building temper\n'
  (cd "$TEMPER" && npm ci --silent && npm run build >/dev/null)
fi
if [[ ! -d "$KILN/_build" ]]; then
  printf '==> compiling kiln (mix deps.get && mix compile)\n'
  (cd "$KILN" && mix deps.get >/dev/null && mix compile >/dev/null)
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/invariant-scenario-recon.XXXXXX")
cleanup() {
  if [[ "${KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORK"
  else
    printf 'workdir kept: %s\n' "$WORK"
  fi
}
trap cleanup EXIT

# The Loadout kiln driver spawns `mix` with the caller's working directory;
# this wrapper pins the mix project to the monorepo Kiln tree. It is passed
# explicitly via --kiln-binary; no product code is modified.
KILN_WRAPPER="$WORK/kiln-mix"
cat >"$KILN_WRAPPER" <<EOF
#!/usr/bin/env bash
cd "$KILN" && exec mix "\$@"
EOF
chmod +x "$KILN_WRAPPER"

# 1. Initialize the proof repository (fixture .git is runner-local by design).
REPO="$WORK/proof-repo"
cp -R "$HERE/proof-repo" "$REPO"
git -C "$REPO" init -q -b main
git -C "$REPO" add -A
git -C "$REPO" -c user.name=invariant-scenario -c user.email=scenario@localhost \
  commit -q -m "Initial deterministic proof-repo fixture"
printf 'proof-repo HEAD: %s\n' "$(git -C "$REPO" rev-parse HEAD)"

LOADOUT_CLI=(node "$LOADOUT/dist/cli.js")

# 2. Install the repository-recon capability into the proof repo.
printf '==> loadout install repository-recon\n'
"${LOADOUT_CLI[@]}" install repository-recon --repository "$REPO" >/dev/null

# 3. Compile the Plan against the real Kiln execution boundary.
printf '==> loadout plan --execution kiln\n'
"${LOADOUT_CLI[@]}" plan \
  --goal "Understand this repository" \
  --repository "$REPO" \
  --execution kiln >/dev/null
PLAN=$(ls -t "$REPO"/.loadout/plans/*.json 2>/dev/null | head -1)
[[ -n "$PLAN" ]] || fail "no plan produced under $REPO/.loadout/plans"
printf 'plan: %s\n' "${PLAN#"$WORK"/}"

# 4. Execute through the real Kiln (authority, run record, evidence).
printf '==> loadout run --execution kiln (real Kiln supervision)\n'
"${LOADOUT_CLI[@]}" run \
  --plan "$PLAN" \
  --repository "$REPO" \
  --execution kiln \
  --kiln-binary "$KILN_WRAPPER" \
  --kiln-home "$WORK/kiln-home" >/dev/null

RUN_RECORD=$(ls -t "$REPO"/.loadout/runs/*.json 2>/dev/null | head -1)
[[ -n "$RUN_RECORD" ]] || fail "no run record produced under $REPO/.loadout/runs"

# 5. Verify the canonical Run Result Envelope, honestly not simulated.
python3 - "$RUN_RECORD" <<'PY'
import json, sys
rec = json.load(open(sys.argv[1]))
envelope = rec.get("runResult", rec)
schema = envelope.get("schema")
assert schema == "engineering-system/run-result-envelope/v0", f"unexpected schema: {schema}"
simulated = envelope.get("simulated", rec.get("simulated"))
assert not simulated, "run record is marked simulated; expected a real Kiln run"
print(f"run record schema: {schema}")
print(f"simulated: {bool(simulated)}")
PY

# 6. Temper renders the recorded run (operator experience consumes truth).
printf '==> temper --snapshot\n'
node "$TEMPER/dist/src/cli.js" "$REPO" --snapshot | head -30

printf '\nrepository-recon golden path: PASS\n'
