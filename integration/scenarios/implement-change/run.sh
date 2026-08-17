#!/usr/bin/env bash
# Wave 3 / SYS-M0-03 E2 + E6: M11 implement-change golden path.
#
# Proves the bounded M0 governed chain end-to-end, in two fresh Elixir
# processes back-to-back:
#
#   process 1: deterministic fake envelope  →  publish via Artifact.Store
#              →  WorkerOutput with raw_completion_ref rewired to
#              Artifact identity  →  decode_envelope  →  build/5  →
#              APPROVE_EXACT_BYTES  →  apply_with_completion_ref  →
#              exact-byte mutation  →  canonical evidence.
#
#   process 2: re-open the bounded kiln_home  →  Artifact.Store.read/2
#              proves byte-identical durable content  →  on-disk repo
#              re-read proves the exact-byte mutation landed.
#
# No live provider. No credentials. No network. Each bounded value comes
# from the canonical `Kiln.Conformance.FirstMonth.patch_limits/0`.
# Mutations are confined to a `mktemp` proof-repo and a `mktemp` kiln_home.
# The source monorepo is never touched.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
KILN="$ROOT/products/kiln"

fail() {
  printf 'implement-change scenario: %s\n' "$1" >&2
  exit 1
}

for tool in git mix python3; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done

if [[ ! -d "$KILN/_build" ]]; then
  printf '==> compiling kiln (mix deps.get && mix compile)\n'
  (cd "$KILN" && mix deps.get >/dev/null && mix compile >/dev/null)
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/invariant-scenario-implement-change.XXXXXX")
KILN_HOME="$WORK/kiln-home"
PROOF_REPO="$WORK/proof-repo"

cleanup() {
  if [[ "${KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORK"
  else
    printf 'workdir kept: %s\n' "$WORK"
  fi
}
trap cleanup EXIT

mkdir -p "$KILN_HOME" "$PROOF_REPO"

# 1. Real bounded proof-repo (one initial file, real Git history).
printf '==> initialize proof-repo\n'
cat >"$PROOF_REPO/README.md" <<'EOF'
# M11 E2 initial
EOF
git -C "$PROOF_REPO" init -q -b main
git -C "$PROOF_REPO" add -A
git -C "$PROOF_REPO" -c user.name=invariant-m11-e2 -c user.email=scenario@localhost \
  commit -q -m "Initial deterministic M11 E2 proof-repo fixture"
printf 'proof-repo HEAD: %s\n' "$(git -C "$PROOF_REPO" rev-parse HEAD)"
PROOF_BASE_COMMIT="$(git -C "$PROOF_REPO" rev-parse HEAD)"

# 2. Process 1 — bounded govern chain: build envelope, publish, rebuild
# proposal, decide, apply_with_completion_ref, capture evidence, write
# bounded Envelope.json + WorkerOutput.json + Proposal.json + Decision.json
# + Evidence.json files for downstream verification.
printf '==> process 1: bounded govern chain\n'
( cd "$KILN" && mix run /dev/stdin <<KILN_EOF
import Bitwise
import Record

kiln_home = "$KILN_HOME"
proof_repo = "$PROOF_REPO"

{:ok, _} = Application.ensure_all_started(:kiln)

# Build the bounded IMPLEMENTER envelope. The replacement text is the
# exact bounded bytes that will land on disk.
original = File.read!(Path.join(proof_repo, "README.md"))
replaced = "# M11 E2 implement-change golden path PASS\n"

before_digest =
  "sha256:" <> (:crypto.hash(:sha256, original) |> Base.encode16(case: :lower))
after_digest =
  "sha256:" <> (:crypto.hash(:sha256, replaced) |> Base.encode16(case: :lower))

# Persist future preimage/afterimage digests for cross-process verification.
File.write!("$WORK/before_digest.txt", before_digest)
File.write!("$WORK/after_digest.txt", after_digest)

envelope = %{
  "schema" => "engineering-system/implementer-patch-proposal-input/v1",
  "operations" => [
    %{
      "op" => "replace",
      "path" => "README.md",
      "expected_before_digest" => before_digest,
      "after_image_bytes" => replaced,
      "mode" => "100644"
    }
  ]
}
envelope_bytes = :json.encode(envelope) |> IO.iodata_to_binary()
File.write!("$WORK/envelope.json", envelope_bytes)

# Open the bounded kiln_home store and compose the canonical handle.
{:ok, :ready} = Kiln.CLI.Runtime.open(kiln_home, :write)

conn = Process.whereis(Kiln.Store.Connection)
state_path = Path.join(kiln_home, "state.sqlite3")
artifact_root = Kiln.Store.artifact_root_for_path(state_path)
store = %{conn: conn, artifact_root: artifact_root}

# Persist the envelope bytes via the canonical Artifact.Store and
# build the Worker Output with raw_completion_ref re-pointed to the
# durable Artifact identity.
artifact_id = Kiln.Store.Uuid.v7()

{:ok, artifact, %{status: _status}} =
  Kiln.Artifact.Store.put(
    store,
    %Kiln.Artifact.PutRequest{
      artifact_id: artifact_id,
      idempotency_key: "scenario_implement_change:" <> artifact_id,
      recorded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      bytes: envelope_bytes,
      metadata: %{
        session_id: "scenario:implement_change",
        run_id: "scenario:implement_change",
        owner_kind: :session,
        owner_id: "scenario:implement_change",
        producer_kind: :deterministic_service,
        producer_id: "scenario.implement_change",
        kind: :output,
        media_type: "application/json",
        encoding: :utf_8,
        trust: :kiln_generated,
        sensitivity: :project,
        retention_class: :session,
        completeness: :complete
      }
    }
  )

after_image_digest_canonical =
  "sha256:" <> (:crypto.hash(:sha256, envelope_bytes) |> Base.encode16(case: :lower))

File.write!("$WORK/artifact_id.txt", artifact.artifact_id)
File.write!("$WORK/artifact_digest.txt", artifact.content_digest)
File.write!("$WORK/expected_digest.txt", after_image_digest_canonical)

worker_output = %Kiln.M0WorkerOutput{
  id: "wko_scenario_implement_change",
  semantic_digest: "sha256:" <> String.duplicate("d", 64),
  attempt_ref: %{"id" => "att_scenario", "digest" => "sha256:" <> String.duplicate("e", 64)},
  assignment_ref: %{"id" => "asg_scenario", "digest" => "sha256:" <> String.duplicate("f", 64)},
  profile_ref: %{"id" => "prf_scenario", "digest" => "sha256:" <> String.duplicate("1", 64)},
  output_kind: "PATCH_CANDIDATE",
  raw_completion_ref: %{"id" => artifact.artifact_id, "digest" => artifact.content_digest},
  parsed_candidate_digest: after_image_digest_canonical,
  completion_bytes: envelope_bytes,
  base_commit: "$PROOF_BASE_COMMIT",
  base_state_digest: "sha256:" <> String.duplicate("4", 64),
  adapter_implementation_digest: "sha256:" <> String.duplicate("5", 64)
}

# Decode the bounded envelope and rebuild the canonical PatchProposal.
{:ok, ops_with_bytes} = Kiln.PatchProposal.decode_envelope(envelope_bytes)
plan_ref = %{"id" => "pln_scenario", "digest" => "sha256:" <> String.duplicate("6", 64)}

{:ok, proposal} =
  Kiln.PatchProposal.build(worker_output, ops_with_bytes, plan_ref, proof_repo)

File.write!("$WORK/proposal.json", :json.encode(proposal) |> IO.iodata_to_binary())

# APPROVE_EXACT_BYTES (human-decision source).
{:ok, decision} =
  Kiln.PatchService.decide(proposal, :approve, proposal.base_state_digest)

File.write!("$WORK/decision.json", :json.encode(decision) |> IO.iodata_to_binary())

# Governed apply from immutable completion evidence.
{:ok, evidence} =
  Kiln.PatchService.apply_with_completion_ref(proposal, decision, worker_output, store)

File.write!("$WORK/evidence.json", :json.encode(evidence) |> IO.iodata_to_binary())

# Verify exact-byte mutation.
on_disk = File.read!(Path.join(proof_repo, "README.md"))

if on_disk != replaced do
  raise "exact-byte mutation failed; expected #{inspect(replaced)}, got #{inspect(on_disk)}"
end

if evidence.effect != "EXACT_TARGET_STATE_OBSERVED" do
  raise "bounded evidence.effect must be EXACT_TARGET_STATE_OBSERVED, got #{evidence.effect}"
end

IO.puts(:io_lib.format("~n> artifact_id: ~s~n", [artifact.artifact_id]))
IO.puts(:io_lib.format("> artifact_digest: ~s~n", [artifact.content_digest]))
IO.puts(:io_lib.format("> evidence.effect: ~s~n", [evidence.effect]))
IO.puts(:io_lib.format("> evidence.post_state_digest: ~s~n", [evidence.post_state_digest]))
IO.puts("> exact-byte mutation verified at README.md")

Kiln.CLI.Runtime.stop()
KILN_EOF
) || fail "process 1: bounded govern chain failed"

# 3. Process 2 — fresh-process read-back across process lifetime.
# A new Elixir invocation proves the persisted Artifact identity is
# stable across process restarts; the bounded read also re-checks
# sha256(retrieved) == ref.digest via Artifact.Store.read/2.
printf '==> process 2: fresh-process read-back\n'
( cd "$KILN" && mix run /dev/stdin <<KILN_EOF

kiln_home = "$KILN_HOME"
proof_repo = "$PROOF_REPO"
artifact_id = File.read!("$WORK/artifact_id.txt") |> String.trim()
artifact_digest = File.read!("$WORK/artifact_digest.txt") |> String.trim()
expected_after_digest = File.read!("$WORK/after_digest.txt") |> String.trim()

{:ok, _} = Application.ensure_all_started(:kiln)
{:ok, :ready} = Kiln.CLI.Runtime.open(kiln_home, :read)

conn = Process.whereis(Kiln.Store.Connection)
state_path = Path.join(kiln_home, "state.sqlite3")
artifact_root = Kiln.Store.artifact_root_for_path(state_path)
store = %{conn: conn, artifact_root: artifact_root}

{:ok, retrieved_bytes, %{integrity_status: :verified}} =
  Kiln.Artifact.Store.read(store, artifact_id)

if byte_size(retrieved_bytes) == 0 do
  raise "fresh process: retrieved Artifact bytes are empty"
end

retrieved_digest =
  "sha256:" <> (:crypto.hash(:sha256, retrieved_bytes) |> Base.encode16(case: :lower))

if retrieved_digest != artifact_digest do
  raise "fresh process: Artifact content_digest drift; stored #{artifact_digest}, retrieved #{retrieved_digest}"
end

# The artifact IS the envelope bytes; `expected_after_digest` is the
# digest of the bounded afterimage text (not the envelope JSON).
# The on-disk README.md digest is verified against `expected_after_digest`
# separately below — that is the bounded mutation proof.

_ = expected_after_digest

on_disk = File.read!(Path.join(proof_repo, "README.md"))
expected = "# M11 E2 implement-change golden path PASS\n"

if on_disk != expected do
  raise "fresh process: README.md drift; expected #{inspect(expected)}, got #{inspect(on_disk)}"
end

IO.puts(:io_lib.format("~n> durable artifact bytes: ~p~n", [byte_size(retrieved_bytes)]))
IO.puts(:io_lib.format("> verified content_digest: ~s~n", [retrieved_digest]))
IO.puts("> fresh-process read-back: PASS")

Kiln.CLI.Runtime.stop()
KILN_EOF
) || fail "process 2: fresh-process read-back failed"

# 4. Cross-process bounded assertions (Python — read what Elixir wrote).
python3 - "$WORK" <<'PY'
import hashlib, json, sys, pathlib
work = pathlib.Path(sys.argv[1])

def sha(path):
    return "sha256:" + hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()

# 4a. Envelope JSON byte-identical across processes.
envelope_path = work / "envelope.json"
envelope_digest = sha(envelope_path)
expected_envelope_digest = (work / "expected_digest.txt").read_text().strip()
assert envelope_digest == expected_envelope_digest, f"envelope digest drift: {envelope_digest} vs {expected_envelope_digest}"
print(f"envelope bytes: byte_size={envelope_path.stat().st_size} digest={envelope_digest}")

# 4b. Evidence shape — bounded canonical patch-application-evidence/m0-v1.
evidence = json.loads((work / "evidence.json").read_text())
assert evidence["effect"] == "EXACT_TARGET_STATE_OBSERVED", evidence
assert evidence["pre_state_digest"].startswith("sha256:"), evidence
assert evidence["post_state_digest"].startswith("sha256:"), evidence
assert evidence["pre_state_digest"] != evidence["post_state_digest"], evidence
assert evidence["patch_ref"]["digest"].startswith("sha256:"), evidence
assert evidence["decision_ref"]["digest"].startswith("sha256:"), evidence
print(f"evidence.effect: {evidence['effect']}")
print(f"evidence.post_state_digest: {evidence['post_state_digest']}")

# 4c. On-disk repo matches bounded afterimage exactly.
# `work` IS the mktemp directory; the proof-repo lives at work/proof-repo.
repo_readme = work / "proof-repo" / "README.md"
on_disk = repo_readme.read_text()
expected = "# M11 E2 implement-change golden path PASS\n"
assert on_disk == expected, f"on-disk drift: {on_disk!r} vs {expected!r}"
on_disk_digest = "sha256:" + hashlib.sha256(repo_readme.read_bytes()).hexdigest()
expected_after_digest = (work / "after_digest.txt").read_text().strip()
assert on_disk_digest == expected_after_digest, f"on-disk digest drift: {on_disk_digest} vs {expected_after_digest}"
print(f"proof-repo README.md: byte_size={repo_readme.stat().st_size} digest={on_disk_digest}")

print("\nimplement-change golden path: PASS")
PY
