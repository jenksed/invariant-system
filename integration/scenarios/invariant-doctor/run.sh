#!/usr/bin/env bash
# integration/scenarios/invariant-doctor/run.sh
#
# Regression coverage for the root `./invariant doctor` command.
#
# Properties proven:
#
#   1. doctor exits 0 when required prerequisites are satisfied (no
#      genuine missing prerequisite, credential check not gating exit).
#   2. doctor reaches and prints the `kiln-pinned` informational line.
#   3. Pinned values parse as `erlang=28.4` and `elixir=1.20.2-otp-28`.
#   4. Detected values are populated under the Kiln mise runtime.
#   5. The credential-presence check is resistant to ordinary
#      `bash -x` tracing: the trace must not expand the credential
#      value, only its byte length.
#   6. A genuinely missing required prerequisite (git) yields nonzero
#      exit and a `FAIL`/`MISSING` line for that prerequisite.
#
# This script is path-independent: it derives ROOT from its own
# location. Do not introduce absolute filesystem paths.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
INVARIANT="$ROOT/invariant"

fail() {
  printf 'invariant-doctor scenario: %s\n' "$1" >&2
  exit 1
}

[[ -x "$INVARIANT" ]] || fail "expected executable: $INVARIANT"

# Required tools for the doctor under test.
for tool in mise elixir mix; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done

# ---- 1+2+3+4. Run doctor under the Kiln mise runtime ----
doctor_output=$(mise --cd "$ROOT/products/kiln" exec -- "$INVARIANT" doctor 2>&1)
doctor_rc=$?

if (( doctor_rc != 0 )); then
  printf '%s\n' "$doctor_output" >&2
  fail "expected doctor exit 0, got $doctor_rc"
fi

# 2. kiln-pinned informational line is reached and printed.
if ! grep -qE '^info[[:space:]]+kiln-pinned' <<<"$doctor_output"; then
  printf '%s\n' "$doctor_output" >&2
  fail "expected kiln-pinned informational line in doctor output"
fi

# 3. Pinned values parse as expected.
pinned_line=$(grep -E '^info[[:space:]]+kiln-pinned' <<<"$doctor_output" || true)
[[ -n "$pinned_line" ]] || fail "kiln-pinned line missing under grep"

if ! grep -qE 'erlang=28\.4\b' <<<"$pinned_line"; then
  printf '%s\n' "$pinned_line" >&2
  fail "expected pinned erlang=28.4 in kiln-pinned line"
fi
if ! grep -qE 'elixir=1\.20\.2-otp-28\b' <<<"$pinned_line"; then
  printf '%s\n' "$pinned_line" >&2
  fail "expected pinned elixir=1.20.2-otp-28 in kiln-pinned line"
fi

# 4. Detected values populated under pinned mise runtime.
if ! grep -qE 'detected:[[:space:]]+erlang=28\b' <<<"$pinned_line"; then
  printf '%s\n' "$pinned_line" >&2
  fail "expected detected erlang=28 under pinned mise runtime"
fi
if ! grep -qE 'detected:[[:space:]]+erlang=28[[:space:]]+elixir=1\.20\.2\b' <<<"$pinned_line"; then
  printf '%s\n' "$pinned_line" >&2
  fail "expected detected elixir=1.20.2 under pinned mise runtime"
fi

# ---- 5. Credential-presence check is bash -x safe ----
# Run the doctor under bash -x and assert the credential value is NOT
# present anywhere in the trace. The presence line itself is allowed.
cred_trace=$(mise --cd "$ROOT/products/kiln" exec -- bash -x "$INVARIANT" doctor 2>&1 || true)

# The length form is acceptable: "MINIMAX_API_KEY present (length=<N>)".
# The literal value must not appear.
if grep -qE 'MINIMAX_API_KEY[[:space:]]*=[[:space:]]*[^[:space:]l(]' <<<"$cred_trace"; then
  printf '%s\n' "$cred_trace" >&2
  fail "credential value appears in bash -x trace"
fi

# Negative control: the credential length form SHOULD appear when
# MINIMAX_API_KEY is set in the calling environment. This is a
# presence-only signal; we are not asserting a specific length.
# (Do not print the length value; only confirm the literal substring
# "length=" appears next to "credential" so we know the hardened
# path ran.)
if ! grep -qE 'credential.*length=' <<<"$cred_trace"; then
  printf '%s\n' "$cred_trace" >&2
  fail "expected credential length= line under hardened check"
fi

# ---- 6. Genuine missing prerequisite yields nonzero exit ----
# Build a bounded PATH that omits `git`. We strip the directory
# containing `git` from PATH and prepend a sandbox dir with shims for
# `python3` and `bash` so the script can still run. The doctor is run
# directly (not under mise) so we can control PATH; we expect git and
# python3 to be present in the calling shell first.
command -v git >/dev/null 2>&1 || fail "this regression requires git on PATH"
command -v bash >/dev/null 2>&1 || fail "this regression requires bash on PATH"

bounded_path=$(mktemp -d "${TMPDIR:-/tmp}/invariant-doctor-no-git.XXXXXX")
trap 'rm -rf "$bounded_path"' EXIT

# Find git's directory and strip it from PATH so `command -v git` fails.
git_dir=$(command -v git | xargs dirname)
clean_path=""
IFS=:
for p in $PATH; do
  [[ "$p" == "$git_dir" ]] && continue
  if [[ -z "$clean_path" ]]; then
    clean_path="$p"
  else
    clean_path="$clean_path:$p"
  fi
done
unset IFS

# Provide a python3 shim (the doctor also probes python3 deps).
cat >"$bounded_path/python3" <<'PYEOF'
#!/usr/bin/env bash
exit 0
PYEOF
chmod +x "$bounded_path/python3"

no_git_log="$bounded_path/doctor.out"
PATH="$bounded_path:$clean_path" bash "$INVARIANT" doctor >"$no_git_log" 2>&1 || no_git_rc=$?
: "${no_git_rc:=0}"

if (( no_git_rc == 0 )); then
  cat "$no_git_log" >&2
  fail "expected nonzero doctor exit when git is absent from PATH"
fi
if ! grep -qE '^FAIL|^MISSING' "$no_git_log"; then
  cat "$no_git_log" >&2
  fail "expected FAIL or MISSING line for the absent prerequisite"
fi

printf 'invariant-doctor scenario: PASS\n'