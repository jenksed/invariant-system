#!/usr/bin/env bash
# Wave 3 / SYS-M0-03 E2 + E6: M11 implement-change golden path.
#
# Proves the bounded M0 governed chain end-to-end through the canonical
# public surfaces — never through compatible artifacts constructed around
# a Kiln-centered core.
#
# Required path (SYS-M0-03):
#   Loadout plan
#   → Manifold IMPLEMENTER assignment + 168h current qualification
#   → Kiln public worker-propose CLI
#   → PatchProposal (bounded materialization from worker_output)
#   → Kiln public patch-decide CLI (APPROVE_EXACT_BYTES)
#   → Kiln public patch-apply-governed CLI (exact-byte mutation)
#   → registered verifier execution via Kiln.Verification.CommandHost
#   → Kiln public verify-run CLI (canonical VerificationResult)
#   → Manifold REVIEWER assignment (independent digest, current qualification)
#   → Kiln public review-propose CLI (independent Review)
#   → Kiln public human-decide CLI (explicit HumanDecision)
#   → truthful Kiln.RunResultProjection
#   → Temper snapshot consumer
#
# No live provider. No credentials. No network. Deterministic-fake
# Worker behavior lives inside Worker.propose/5 (no separate fake
# Provider is implemented; AC06 forbids it). Mutations are confined to
# a `mktemp` proof-repo and a `mktemp` kiln_home. The source monorepo
# is never touched.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd "$HERE/../../.." && pwd -P)
KILN="$ROOT/products/kiln"
LOADOUT="$ROOT/products/loadout"
MANIFOLD="$ROOT/products/manifold"
TEMPER="$ROOT/products/temper"
SELECTOR="$MANIFOLD/src/selector.py"
SCENARIO_HELPER="$HERE/scenario_helper.exs"

fail() {
  printf 'implement-change scenario: %s\n' "$1" >&2
  exit 1
}

for tool in git mix python3 node; do
  command -v "$tool" >/dev/null 2>&1 || fail "required tool not on PATH: $tool"
done
[[ -f "$SCENARIO_HELPER" ]] || fail "scenario helper missing: $SCENARIO_HELPER"

# Loadout dist must be built at least once so `loadout` resolves.
if [[ ! -d "$LOADOUT/dist/packs/implement-change" ]]; then
  printf '==> building loadout (npm run build)\n'
  (cd "$LOADOUT" && npm run build >/dev/null)
fi

# Temper dist must be built at least once so the snapshot CLI resolves.
# The tsconfig has rootDir="." so the build emits dist/src/cli.js.
if [[ ! -f "$TEMPER/dist/src/cli.js" ]]; then
  printf '==> building temper (npm run build)\n'
  (cd "$TEMPER" && npm run build >/dev/null)
fi

if [[ ! -d "$KILN/_build" ]]; then
  printf '==> compiling kiln (mix deps.get && mix compile)\n'
  (cd "$KILN" && mix deps.get >/dev/null && mix compile >/dev/null)
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/invariant-scenario-implement-change.XXXXXX")
KILN_HOME="$WORK/kiln-home"
PROOF_REPO="$WORK/proof-repo"
SCENARIO_HOME="$WORK/.loadout"
RUN_RECORD_DIR="$WORK/run-records"

cleanup() {
  if [[ "${KEEP_WORKDIR:-0}" != "1" ]]; then
    rm -rf "$WORK"
  else
    printf 'workdir kept: %s\n' "$WORK"
  fi
}
trap cleanup EXIT

mkdir -p "$KILN_HOME" "$PROOF_REPO" "$SCENARIO_HOME" "$RUN_RECORD_DIR"

# Canonical m0 fixture inputs.
FIX="$ROOT/integration/fixtures/m0/positive"
IMPL_REQ="$FIX/02-implementer-requirement.json"
IMPL_PROFILE="$FIX/03-implementer-profile.json"
IMPL_ELIG="$FIX/06-implementer-eligibility.json"
REVR_REQ="$FIX/16-reviewer-requirement.json"
REVR_PROFILE="$FIX/17-reviewer-profile.json"
REVR_ELIG="$FIX/20-reviewer-eligibility.json"
RUN_BINDING="$FIX/10-run-binding.json"
PLAN_FIXTURE="$FIX/01-plan.json"
WORK_ENVELOPE_FIXTURE="$FIX/09-work-envelope-v0.json"
EXEC_BINDING="$FIX/08-execution-binding.json"

for f in "$IMPL_REQ" "$IMPL_PROFILE" "$IMPL_ELIG" \
         "$REVR_REQ" "$REVR_PROFILE" "$REVR_ELIG" \
         "$RUN_BINDING" "$PLAN_FIXTURE" "$WORK_ENVELOPE_FIXTURE" \
         "$EXEC_BINDING"; do
  [[ -f "$f" ]] || fail "canonical fixture missing: $f"
done

# ─────────────────────────────────────────────────────────────────────
# 1. Real bounded proof-repo
# ─────────────────────────────────────────────────────────────────────
printf '==> initialize proof-repo\n'
cat >"$PROOF_REPO/README.md" <<'EOF'
# M11 E2 initial
EOF
git -C "$PROOF_REPO" init -q -b main
git -C "$PROOF_REPO" add -A
git -C "$PROOF_REPO" -c user.name=invariant-m11-e2 -c user.email=scenario@localhost \
  commit -q -m "Initial deterministic M11 E2 proof-repo fixture"
PROOF_BASE_COMMIT="$(git -C "$PROOF_REPO" rev-parse HEAD)"
printf 'proof-repo HEAD: %s\n' "$PROOF_BASE_COMMIT"

# ─────────────────────────────────────────────────────────────────────
# 2. Loadout: validate the canonical m0 fixture set.
# ─────────────────────────────────────────────────────────────────────
printf '==> loadout: validate canonical m0 fixture set\n'
(cd "$LOADOUT" && node dist/cli.js validate-contracts) \
  >"$WORK/loadout_validate.stdout" 2>&1 \
  || { cat "$WORK/loadout_validate.stdout" >&2; fail "loadout validate-contracts failed"; }
printf 'loadout validate-contracts: OK\n'

LOADOUT_PLAN="$PLAN_FIXTURE"
[[ -s "$LOADOUT_PLAN" ]] || fail "loadout canonical plan fixture missing"
PLAN_REF_ID="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["plan_id"])' "$LOADOUT_PLAN")"
PLAN_DIGEST="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["semantic_digest"])' "$LOADOUT_PLAN")"
printf 'loadout plan_id: %s\n' "$PLAN_REF_ID"
printf 'loadout plan semantic_digest: %s\n' "$PLAN_DIGEST"

LOADOUT_ENVELOPE="$WORK_ENVELOPE_FIXTURE"
[[ -s "$LOADOUT_ENVELOPE" ]] || fail "loadout canonical work_envelope fixture missing"

# ─────────────────────────────────────────────────────────────────────
# 3. Manifold: canonical IMPLEMENTER selector.
# ─────────────────────────────────────────────────────────────────────
printf '==> manifold: IMPLEMENTER assignment via canonical selector\n'
IMPL_ASSIGNMENT="$WORK/implementer_assignment.json"
python3 "$SELECTOR" \
  --requirement "$IMPL_REQ" \
  --profile "$IMPL_PROFILE" \
  --eligibility "$IMPL_ELIG" \
  --out "$IMPL_ASSIGNMENT" \
  >"$WORK/selector_impl.stdout" 2>&1 \
  || { cat "$WORK/selector_impl.stdout" >&2; fail "manifold selector (IMPLEMENTER) failed"; }

ASSIGNMENT_ID="$(python3 -c '
import json, sys
a = json.load(open(sys.argv[1]))
print(a["assignment_id"])
' "$IMPL_ASSIGNMENT")"
printf 'manifold implementer assignment_id: %s\n' "$ASSIGNMENT_ID"

# The CLI worker-profile resolver reads by digest from KILN_PROFILES_ROOT.
PROFILES_DIR="$WORK/profiles"
mkdir -p "$PROFILES_DIR"
cp "$FIX/03-implementer-profile.json" "$PROFILES_DIR/implementer.json"
cp "$FIX/17-reviewer-profile.json" "$PROFILES_DIR/reviewer.json"
export KILN_PROFILES_ROOT="$PROFILES_DIR"

# Plan ref artifactRef JSON.
PLAN_REF_ARTIFACT="$WORK/plan_ref_artifact.json"
python3 -c '
import json, sys
plan = json.load(open(sys.argv[1]))
ref = {"id": plan["plan_id"], "digest": plan["semantic_digest"]}
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$LOADOUT_PLAN" "$PLAN_REF_ARTIFACT"

# ─────────────────────────────────────────────────────────────────────
# 4. Kiln: public worker-propose CLI.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: worker-propose via public CLI\n'
WORKER_OUTPUT="$WORK/worker_output.json"

# Construct the canonical bounded completion envelope.
printf '==> construct canonical implementer-patch-proposal-input/v1 envelope\n'
PROPOSAL_INPUT="$WORK/proposal_input.json"
python3 -c '
import hashlib, json, sys
repo = sys.argv[1]
out = sys.argv[2]
original = open(repo + "/README.md", "rb").read()
before = "sha256:" + hashlib.sha256(original).hexdigest()
replacement = b"# M11 E2 implement-change golden path PASS\n"
envelope = {
  "schema": "engineering-system/implementer-patch-proposal-input/v1",
  "operations": [{
    "op": "replace",
    "path": "README.md",
    "expected_before_digest": before,
    "after_image_bytes": replacement.decode("utf-8"),
    "mode": "100644"
  }]
}
json.dump(envelope, open(out, "w"))
' "$PROOF_REPO" "$PROPOSAL_INPUT"
[[ -s "$PROPOSAL_INPUT" ]] || fail "proposal_input envelope not constructed"

(cd "$KILN" && mix kiln --kiln-home "$KILN_HOME" --actor-id "e2_scenario" worker-propose \
  --assignment "$IMPL_ASSIGNMENT" \
  --eligibility "$IMPL_ELIG" \
  --request "$PROPOSAL_INPUT" \
  --plan "$PLAN_REF_ARTIFACT" \
  --repository "$PROOF_REPO" \
  --out "$WORKER_OUTPUT" \
  --format json) >"$WORK/worker_propose.stdout" 2>&1 \
  || { cat "$WORK/worker_propose.stdout" >&2; fail "worker-propose failed"; }

[[ -s "$WORKER_OUTPUT" ]] || fail "worker-propose produced empty output"
WO_ID="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["id"])
' "$WORKER_OUTPUT")"
printf 'worker output id: %s\n' "$WO_ID"

# ─────────────────────────────────────────────────────────────────────
# 5. PatchProposal materialization from the immutable Worker completion.
#
# The Elixir code is a checked-in .exs helper rather than an interpolated
# shell heredoc. This preserves the exact domain calls while making the
# scenario portable and preventing Bash command substitution in comments.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: bounded PatchProposal materialization from worker_output\n'
PROPOSAL_JSON="$WORK/proposal.json"
(cd "$KILN" && mix run "$SCENARIO_HELPER" -- \
  materialize-proposal \
  "$KILN_HOME" \
  "$PROOF_REPO" \
  "$WORKER_OUTPUT" \
  "$PROPOSAL_JSON") \
  >"$WORK/proposal_materialize.stdout" 2>&1 \
  || { cat "$WORK/proposal_materialize.stdout" >&2; fail "PatchProposal materialization failed"; }

[[ -s "$PROPOSAL_JSON" ]] || fail "proposal materialization produced empty output"

# ─────────────────────────────────────────────────────────────────────
# 6. Kiln: public patch-decide CLI (APPROVE_EXACT_BYTES).
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: patch-decide via public CLI (APPROVE_EXACT_BYTES)\n'
DECISION_JSON="$WORK/patch_decision.json"
(cd "$KILN" && mix kiln --kiln-home "$KILN_HOME" --actor-id "e2_scenario" patch-decide \
  --proposal "$PROPOSAL_JSON" \
  --decision approve \
  --out "$DECISION_JSON" \
  --format json) >"$WORK/patch_decide.stdout" 2>&1 \
  || { cat "$WORK/patch_decide.stdout" >&2; fail "patch-decide failed"; }

DECISION_KIND="$(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
print(d["decision"])
' "$DECISION_JSON")"
[[ "$DECISION_KIND" == "APPROVE_EXACT_BYTES" ]] \
  || fail "patch-decide did not produce APPROVE_EXACT_BYTES (got $DECISION_KIND)"
printf 'patch decision: %s\n' "$DECISION_KIND"

# ─────────────────────────────────────────────────────────────────────
# 7. Kiln: public patch-apply-governed CLI.
#
# The governed apply re-materializes from raw_completion_ref, verifies the
# rebuilt semantic/patch digests against the approved proposal, and applies
# those exact bytes. There is no side-channel operation source here.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: patch-apply-governed via public CLI\n'
EVIDENCE_JSON="$WORK/patch_application_evidence.json"
(cd "$KILN" && mix kiln --kiln-home "$KILN_HOME" --actor-id "e2_scenario" patch-apply-governed \
  --proposal "$PROPOSAL_JSON" \
  --decision "$DECISION_JSON" \
  --worker-output "$WORKER_OUTPUT" \
  --out "$EVIDENCE_JSON" \
  --format json) >"$WORK/patch_apply_governed.stdout" 2>&1 \
  || { cat "$WORK/patch_apply_governed.stdout" >&2; fail "patch-apply-governed failed"; }

EFFECT="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["effect"])
' "$EVIDENCE_JSON")"
POST_DIGEST="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["post_state_digest"])
' "$EVIDENCE_JSON")"
PRE_DIGEST="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["pre_state_digest"])
' "$EVIDENCE_JSON")"
[[ "$EFFECT" == "EXACT_TARGET_STATE_OBSERVED" ]] \
  || fail "patch-apply-governed effect was not EXACT_TARGET_STATE_OBSERVED (got $EFFECT)"
[[ "$PRE_DIGEST" != "$POST_DIGEST" ]] \
  || fail "pre_state_digest equals post_state_digest (no mutation observed)"
printf 'evidence: effect=%s post_state=%s\n' "$EFFECT" "$POST_DIGEST"

ON_DISK_BYTES="$(cat "$PROOF_REPO/README.md")"
EXPECTED_BYTES="$(printf '# M11 E2 implement-change golden path PASS\n')"
[[ "$ON_DISK_BYTES" == "$EXPECTED_BYTES" ]] \
  || fail "on-disk proof-repo bytes do not match the bounded after-image"

# ─────────────────────────────────────────────────────────────────────
# 8. Registered verifier execution via Kiln.Verification.CommandHost.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: registered verifier execution (repo.diff-check)\n'
VERIFIER_OUTPUT="$WORK/verifier_execution.json"
(cd "$KILN" && mix run "$SCENARIO_HELPER" -- \
  run-verifier \
  "$PROOF_REPO" \
  "$PROOF_BASE_COMMIT" \
  "$VERIFIER_OUTPUT") \
  >"$WORK/verifier_execution.stdout" 2>&1 \
  || { cat "$WORK/verifier_execution.stdout" >&2; fail "verifier execution via CommandHost failed"; }

VERIFIER_RESULT="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["result"])
' "$VERIFIER_OUTPUT")"
[[ "$VERIFIER_RESULT" == "pass" ]] \
  || fail "registered verifier did not PASS (got $VERIFIER_RESULT)"
printf 'registered verifier: %s\n' "$VERIFIER_RESULT"

VERIFIER_REF="$WORK/verifier_ref.json"
python3 -c '
import json, sys
result = json.load(open(sys.argv[1]))
ref = {
  "schema": "engineering-system/registered-verifier-ref/m0-v1",
  "id": "verifier_repo_diff_check",
  "digest": "sha256:" + result["registration_digest"]
}
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$VERIFIER_OUTPUT" "$VERIFIER_REF"

# ─────────────────────────────────────────────────────────────────────
# 9. Kiln: public verify-run CLI.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: verify-run via public CLI\n'
VERIFICATION_JSON="$WORK/verification_result.json"

EVIDENCE_REFS_JSON="$WORK/evidence_refs.json"
python3 -c '
import json, sys
ev = json.load(open(sys.argv[1]))
ref = [{"id": ev["id"], "digest": ev["semantic_digest"]}]
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$EVIDENCE_JSON" "$EVIDENCE_REFS_JSON"

PATCH_REF_ARTIFACT="$WORK/patch_ref_artifact.json"
python3 -c '
import json, sys
p = json.load(open(sys.argv[1]))
ref = {"id": p["id"], "digest": p["patch_digest"]}
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$PROPOSAL_JSON" "$PATCH_REF_ARTIFACT"

(cd "$KILN" && mix kiln --kiln-home "$KILN_HOME" --actor-id "e2_scenario" verify-run \
  --plan "$PLAN_REF_ARTIFACT" \
  --patch "$PATCH_REF_ARTIFACT" \
  --result-state-digest "$POST_DIGEST" \
  --registered-verifier "$VERIFIER_REF" \
  --status PASS \
  --evidence "$EVIDENCE_REFS_JSON" \
  --out "$VERIFICATION_JSON" \
  --format json) >"$WORK/verify_run.stdout" 2>&1 \
  || { cat "$WORK/verify_run.stdout" >&2; fail "verify-run failed"; }

VERIF_STATUS="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["status"])
' "$VERIFICATION_JSON")"
[[ "$VERIF_STATUS" == "PASS" ]] \
  || fail "verify-run did not record PASS (got $VERIF_STATUS)"
printf 'verify-run status: %s\n' "$VERIF_STATUS"

# ─────────────────────────────────────────────────────────────────────
# 10. Manifold: independent REVIEWER assignment.
# ─────────────────────────────────────────────────────────────────────
printf '==> manifold: REVIEWER assignment via canonical selector\n'
REVR_ASSIGNMENT="$WORK/reviewer_assignment.json"
python3 "$SELECTOR" \
  --requirement "$REVR_REQ" \
  --profile "$REVR_PROFILE" \
  --eligibility "$REVR_ELIG" \
  --out "$REVR_ASSIGNMENT" \
  >"$WORK/selector_revr.stdout" 2>&1 \
  || { cat "$WORK/selector_revr.stdout" >&2; fail "manifold selector (REVIEWER) failed"; }

IMPL_DIGEST="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["assignment_id"])
' "$IMPL_ASSIGNMENT")"
REVR_DIGEST="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["assignment_id"])
' "$REVR_ASSIGNMENT")"
[[ "$IMPL_DIGEST" != "$REVR_DIGEST" ]] \
  || fail "REVIEWER assignment equals IMPLEMENTER assignment (must be independent)"
printf 'reviewer assignment_id: %s (≠ implementer)\n' "$REVR_DIGEST"

# ─────────────────────────────────────────────────────────────────────
# 11. Kiln: public review-propose CLI.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: review-propose via public CLI\n'
REVIEW_JSON="$WORK/review.json"

IMPL_ASSIGN_REF="$WORK/impl_assign_ref.json"
python3 -c '
import json, sys
a = json.load(open(sys.argv[1]))
ref = {"id": a["assignment_id"], "digest": a["semantic_digest"]}
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$IMPL_ASSIGNMENT" "$IMPL_ASSIGN_REF"

REVR_ASSIGN_REF="$WORK/revr_assign_ref.json"
python3 -c '
import json, sys
a = json.load(open(sys.argv[1]))
ref = {"id": a["assignment_id"], "digest": a["semantic_digest"]}
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$REVR_ASSIGNMENT" "$REVR_ASSIGN_REF"

VERIF_REF="$WORK/verif_ref.json"
python3 -c '
import json, sys
v = json.load(open(sys.argv[1]))
ref = {"id": v["id"], "digest": v["semantic_digest"]}
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$VERIFICATION_JSON" "$VERIF_REF"

CONTEXT_MANIFEST_REF="$WORK/context_manifest_ref.json"
python3 -c '
import json, sys
ref = {"id": "ctxm_e2_scenario", "digest": "sha256:" + ("c" * 64)}
json.dump(ref, open(sys.argv[1], "w"), sort_keys=True, separators=(",", ":"))
' "$CONTEXT_MANIFEST_REF"

FINDINGS_JSON="$WORK/findings.json"
python3 -c '
import json, sys
findings = [
  "patch bytes landed exactly on the bounded target file",
  "registered verifier (repo.diff-check) confirmed exact-byte mutation"
]
json.dump(findings, open(sys.argv[1], "w"), sort_keys=True, separators=(",", ":"))
' "$FINDINGS_JSON"

(cd "$KILN" && mix kiln --kiln-home "$KILN_HOME" --actor-id "e2_scenario" review-propose \
  --implementer-assignment "$IMPL_ASSIGN_REF" \
  --eligibility "$REVR_ELIG" \
  --plan "$PLAN_REF_ARTIFACT" \
  --patch "$PATCH_REF_ARTIFACT" \
  --verification "$VERIF_REF" \
  --result-state-digest "$POST_DIGEST" \
  --reviewer-assignment "$REVR_ASSIGN_REF" \
  --context-manifest "$CONTEXT_MANIFEST_REF" \
  --verdict APPROVE \
  --findings "$FINDINGS_JSON" \
  --out "$REVIEW_JSON" \
  --format json) >"$WORK/review_propose.stdout" 2>&1 \
  || { cat "$WORK/review_propose.stdout" >&2; fail "review-propose failed"; }

REVIEW_VERDICT="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["verdict"])
' "$REVIEW_JSON")"
[[ "$REVIEW_VERDICT" == "APPROVE" ]] \
  || fail "review-propose did not produce APPROVE (got $REVIEW_VERDICT)"

CONTAMINATED="$(python3 -c '
import json, sys
r = json.load(open(sys.argv[1]))
print(r.get("implementer_transcript_received", "missing"))
' "$REVIEW_JSON")"
[[ "$CONTAMINATED" == "False" ]] \
  || fail "review contamination: implementer_transcript_received=$CONTAMINATED"
printf 'review verdict: %s (implementer_transcript_received=false)\n' "$REVIEW_VERDICT"

REVIEW_REF="$WORK/review_ref.json"
python3 -c '
import json, sys
r = json.load(open(sys.argv[1]))
ref = {"id": r["id"], "digest": r["semantic_digest"]}
json.dump(ref, open(sys.argv[2], "w"), sort_keys=True, separators=(",", ":"))
' "$REVIEW_JSON" "$REVIEW_REF"

# ─────────────────────────────────────────────────────────────────────
# 12. Kiln: explicit public human-decide CLI.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: human-decide via public CLI\n'
HUMAN_DECISION_JSON="$WORK/human_decision.json"
(cd "$KILN" && mix kiln --kiln-home "$KILN_HOME" --actor-id "e2_scenario" human-decide \
  --plan "$PLAN_REF_ARTIFACT" \
  --patch "$PATCH_REF_ARTIFACT" \
  --result-state-digest "$POST_DIGEST" \
  --review "$REVIEW_REF" \
  --decision ACCEPT \
  --out "$HUMAN_DECISION_JSON" \
  --format json) >"$WORK/human_decide.stdout" 2>&1 \
  || { cat "$WORK/human_decide.stdout" >&2; fail "human-decide failed"; }

HD_DECISION="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["decision"])
' "$HUMAN_DECISION_JSON")"
[[ "$HD_DECISION" == "ACCEPT" ]] \
  || fail "human-decide did not produce ACCEPT (got $HD_DECISION)"
printf 'human-decision: %s\n' "$HD_DECISION"

# ─────────────────────────────────────────────────────────────────────
# 13. Truthful RunResultProjection.
# ─────────────────────────────────────────────────────────────────────
printf '==> kiln: truthful RunResultProjection\n'
PROJECTION_JSON="$WORK/run_result_projection.json"
(cd "$KILN" && mix run "$SCENARIO_HELPER" -- \
  build-projection \
  "$EVIDENCE_JSON" \
  "$VERIFICATION_JSON" \
  "$REVIEW_JSON" \
  "$HUMAN_DECISION_JSON" \
  "$PLAN_REF_ARTIFACT" \
  "$IMPL_ASSIGN_REF" \
  "$REVR_ASSIGN_REF" \
  "$PATCH_REF_ARTIFACT" \
  "$VERIF_REF" \
  "$REVIEW_REF" \
  "$PROJECTION_JSON") \
  >"$WORK/projection_build.stdout" 2>&1 \
  || { cat "$WORK/projection_build.stdout" >&2; fail "RunResultProjection build failed"; }

[[ -s "$PROJECTION_JSON" ]] || fail "projection artifact empty"
printf 'projection: %s\n' "$(python3 -c '
import json, sys
p = json.load(open(sys.argv[1]))
print("status=" + str(p.get("status", "?")))
' "$PROJECTION_JSON")"

# ─────────────────────────────────────────────────────────────────────
# 14. Temper: terminal snapshot consumer.
# ─────────────────────────────────────────────────────────────────────
printf '==> temper: snapshot consumer\n'
RUN_RECORD="$WORK/run_record.json"
python3 -c '
import json, sys
plan = json.load(open(sys.argv[1]))
projection = json.load(open(sys.argv[2]))
envelope = json.load(open(sys.argv[3]))
record = {
  "plan_id": plan["plan_id"],
  "work_envelope": envelope,
  "executionBoundary": "kiln",
  "runResult": projection,
  "view": {"summary": "M11 E2 implement-change golden path PASS"}
}
json.dump(record, open(sys.argv[4], "w"), sort_keys=True, indent=2)
' "$LOADOUT_PLAN" "$PROJECTION_JSON" "$LOADOUT_ENVELOPE" "$RUN_RECORD"

TEMPER_SNAPSHOT="$WORK/temper_snapshot.txt"
(cd "$TEMPER" && node dist/src/cli.js --snapshot --run "$RUN_RECORD" --plan "$LOADOUT_PLAN" --focus evidence --width 100) \
  >"$TEMPER_SNAPSHOT" 2>"$WORK/temper.stderr" \
  || { cat "$WORK/temper.stderr" >&2; fail "temper snapshot failed"; }

TEMPER_BYTES="$(wc -c < "$TEMPER_SNAPSHOT" | tr -d ' ')"
[[ "$TEMPER_BYTES" -gt 0 ]] || fail "temper snapshot produced empty output"
printf 'temper snapshot bytes: %s\n' "$TEMPER_BYTES"

# ─────────────────────────────────────────────────────────────────────
# 15. Final cross-validation ledger.
# ─────────────────────────────────────────────────────────────────────
printf '\n==> E2 ledger summary\n'
printf 'plan_id           : %s\n' "$PLAN_REF_ID"
printf 'assignment_impl   : %s\n' "$ASSIGNMENT_ID"
printf 'assignment_revr   : %s\n' "$REVR_DIGEST"
printf 'worker_output     : %s\n' "$WO_ID"
printf 'decision          : %s\n' "$DECISION_KIND"
printf 'apply effect      : %s\n' "$EFFECT"
printf 'verifier result   : %s\n' "$VERIFIER_RESULT"
printf 'verify-run status : %s\n' "$VERIF_STATUS"
printf 'review verdict    : %s\n' "$REVIEW_VERDICT"
printf 'human decision    : %s\n' "$HD_DECISION"
printf 'temper snapshot   : %s bytes\n' "$TEMPER_BYTES"
printf '\nimplement-change golden path: PASS\n'
