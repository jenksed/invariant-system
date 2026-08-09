#!/usr/bin/env python3
"""Inspect, assess, verify, and revoke Project Arsenal trust decisions."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_POLICY = ROOT / "arsenal/trust/policy.json"

AUTHORITY = {
    "filesystem.read", "filesystem.write", "shell.execute", "network.read", "network.write",
    "git.read", "git.write", "tracker.read", "tracker.write", "secrets.read", "cloud.local",
    "cloud.remote", "production.mutate", "human.confirmation",
}
EXIT = {"APPROVED": 0, "QUARANTINED": 3, "REVIEW_REQUIRED": 4,
        "ESCALATION_REQUIRED": 5, "REJECTED": 6, "REVOKED": 7}
READ_ONLY_GIT = ("git status", "git log", "git show", "git diff", "git rev-parse",
                 "git ls-files", "git branch --show-current")
RECONSIDERATION = [
    "candidate-digest-change", "policy-digest-change", "canonical-capability-change",
    "authority-increase", "evaluation-regression", "explicit-revocation",
]


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def sha256_bytes(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def digest_json(value: Any) -> str:
    return sha256_bytes(json.dumps(value, sort_keys=True, separators=(",", ":")).encode())


def package_inventory(package: Path) -> tuple[list[dict[str, Any]], str]:
    if not package.is_dir():
        raise AssertionError(f"package must be a directory: {package}")
    rows: list[dict[str, Any]] = []
    base = package.resolve()
    for path in sorted(package.rglob("*")):
        if path.is_symlink():
            raise AssertionError(f"symlinks are not allowed in imported packages: {path}")
        if path.is_dir():
            continue
        try:
            rel = path.resolve().relative_to(base).as_posix()
        except ValueError as exc:
            raise AssertionError(f"path escapes package root: {path}") from exc
        rows.append({"path": rel, "sha256": sha256_file(path),
                     "executable": bool(path.stat().st_mode & 0o111)})
    if not rows:
        raise AssertionError("package must contain at least one file")
    material = "".join(f"{r['path']}\0{r['sha256']}\n" for r in rows).encode()
    return rows, sha256_bytes(material)


def frontmatter(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    result: dict[str, str] = {}
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        if key.strip() in {"name", "description", "allowed-tools"}:
            result[key.strip()] = value.strip().strip('"').strip("'")
    return result


def allowed_tool_tokens(raw: str) -> list[str]:
    return re.findall(r"Bash\([^)]*\)|[^\s]+", raw) if raw else []


def map_tools(tokens: list[str]) -> tuple[list[str], list[str]]:
    authority: set[str] = set()
    unmapped: set[str] = set()
    for token in tokens:
        if token in {"Read", "Grep", "Glob"}:
            authority.add("filesystem.read")
        elif token in {"Write", "Edit"}:
            authority.add("filesystem.write")
        elif token in {"WebFetch", "WebSearch"}:
            authority.add("network.read")
        elif token.startswith("Bash(") and token.endswith(")"):
            authority.add("shell.execute")
            command = token[5:-1].strip()
            if command.startswith(READ_ONLY_GIT):
                authority.add("git.read")
            elif command.startswith("git"):
                authority.update({"git.read", "git.write"})
            else:
                unmapped.add(token)
        else:
            unmapped.add(token)
    return sorted(authority), sorted(unmapped)


def compiler_manifest_status(package: Path, manifest: dict[str, Any], root: Path) -> tuple[bool, list[str]]:
    reasons: list[str] = []
    try:
        listed = manifest["package"]["files"]
        expected_content = manifest["package"]["content_sha256"]
        source = manifest["source"]
    except (KeyError, TypeError):
        return False, ["invalid Arsenal package manifest shape"]

    digest_rows: list[dict[str, str]] = []
    for entry in listed:
        rel, expected = entry.get("path"), entry.get("sha256")
        if not isinstance(rel, str) or not isinstance(expected, str):
            reasons.append("invalid file entry in Arsenal manifest")
            continue
        file_path = package / rel
        if not file_path.is_file() or file_path.is_symlink():
            reasons.append(f"manifest file missing or unsafe: {rel}")
            continue
        if sha256_file(file_path) != expected:
            reasons.append(f"manifest file digest mismatch: {rel}")
        digest_rows.append({"path": rel, "sha256": expected})

    canonical = (json.dumps(sorted(digest_rows, key=lambda x: x["path"]), sort_keys=True,
                            separators=(",", ":"), ensure_ascii=False) + "\n").encode()
    if sha256_bytes(canonical) != expected_content:
        reasons.append("manifest package content digest mismatch")

    for path_key, digest_key in (("capability_path", "capability_sha256"),
                                 ("primary_asset_path", "primary_asset_sha256")):
        rel, expected = source.get(path_key), source.get(digest_key)
        if not isinstance(rel, str) or not isinstance(expected, str):
            reasons.append(f"manifest missing source field: {path_key}/{digest_key}")
            continue
        source_path = root / rel
        if not source_path.is_file():
            reasons.append(f"manifest source path missing: {rel}")
        elif sha256_file(source_path) != expected:
            reasons.append(f"manifest source digest mismatch: {rel}")
    return not reasons, reasons


def discover_package(package: Path, source_kind: str, locator: str,
                     revision: str | None, root: Path = ROOT) -> dict[str, Any]:
    files, package_digest = package_inventory(package)
    meta = frontmatter(package / "SKILL.md")
    tokens = allowed_tool_tokens(meta.get("allowed-tools", ""))
    authority, unmapped = map_tools(tokens)
    format_name = "agent-skill" if (package / "SKILL.md").is_file() else "unknown"
    assurance = "digest-only"
    manifest_verified = False
    manifest_reasons: list[str] = []

    manifest_path = package / "arsenal-manifest.json"
    if manifest_path.is_file():
        format_name = "arsenal-package"
        manifest = load_json(manifest_path)
        manifest_verified, manifest_reasons = compiler_manifest_status(package, manifest, root)
        if manifest_verified:
            assurance = "compiler-manifest-verified"
            ma = manifest.get("authority", {})
            authority = sorted(set(ma.get("required", [])) | set(ma.get("optional", [])))
            unmapped = []

    revision_pinned = bool(revision and re.fullmatch(r"[0-9a-f]{40}", revision))
    if source_kind == "git":
        assurance = "source-revision-pinned" if revision_pinned else "incomplete"
    elif source_kind == "arsenal-compiled" and assurance != "compiler-manifest-verified" and revision_pinned:
        assurance = "source-revision-pinned"

    executable = sorted(r["path"] for r in files if r["executable"] or r["path"].startswith("scripts/"))
    unknown = (format_name == "agent-skill" and not tokens) or bool(unmapped) or bool(executable)
    return {
        "schema_version": "1.0.0",
        "candidate_id": "candidate-" + package_digest.split(":", 1)[1][:20],
        "state": "QUARANTINED",
        "format": format_name,
        "source": {"kind": source_kind, "locator": locator, "revision": revision,
                   "revision_pinned": revision_pinned},
        "package": {"name": package.name, "sha256": package_digest, "files": files},
        "declaration": {"name": meta.get("name"), "description": meta.get("description"),
                        "allowed_tools": tokens, "authority_signals": authority,
                        "unmapped_tools": unmapped},
        "provenance": {"assurance": assurance, "manifest_verified": manifest_verified,
                       "manifest_reasons": manifest_reasons},
        "risk": {"executable_paths": executable, "unknown_authority": unknown},
    }


def load_capability(capability_id: str, root: Path = ROOT) -> tuple[dict[str, Any], Path, str]:
    for path in sorted((root / "arsenal/capabilities").glob("*.json")):
        doc = load_json(path)
        cap = doc.get("capability", {})
        if cap.get("id") == capability_id:
            return cap, path, sha256_file(path)
    raise AssertionError(f"unknown capability: {capability_id}")


def validate_policy(policy: dict[str, Any]) -> None:
    if policy.get("schema_version") != "1.0.0":
        raise AssertionError("trust policy schema_version must be 1.0.0")
    if policy.get("auto_approval") is not False:
        raise AssertionError("ARS-08 v0 forbids automatic third-party approval")
    partitions = [set(policy.get(k, [])) for k in
                  ("baseline_authority", "escalation_authority", "prohibited_authority")]
    for values in partitions:
        unknown = values - AUTHORITY
        if unknown:
            raise AssertionError(f"unknown authority in trust policy: {sorted(unknown)}")
    if partitions[0] & partitions[1] or partitions[0] & partitions[2] or partitions[1] & partitions[2]:
        raise AssertionError("trust policy authority partitions must be disjoint")
    if not set(policy.get("challenge_authority", [])) <= partitions[1]:
        raise AssertionError("challenge_authority must be an escalation subset")
    if policy.get("digest_change_action") != "REQUARANTINE":
        raise AssertionError("candidate digest drift must re-quarantine")
    if policy.get("policy_change_action") != "REVIEW_REQUIRED" or policy.get("canonical_change_action") != "REVIEW_REQUIRED":
        raise AssertionError("policy/canonical drift must require review")


def validate_review(review: dict[str, Any], candidate: dict[str, Any]) -> None:
    if review.get("schema_version") != "1.0.0":
        raise AssertionError("review schema_version must be 1.0.0")
    if review.get("candidate_sha256") != candidate["package"]["sha256"]:
        raise AssertionError("review is not bound to candidate digest")
    for key in ("requested_authority", "approved_authority"):
        values = review.get(key)
        if not isinstance(values, list) or set(values) - AUTHORITY:
            raise AssertionError(f"invalid {key}")
    if review.get("disposition") not in {"approve", "reject"}:
        raise AssertionError("invalid review disposition")


def assess_candidate(candidate: dict[str, Any], review: dict[str, Any], policy: dict[str, Any],
                     root: Path = ROOT) -> dict[str, Any]:
    validate_policy(policy)
    validate_review(review, candidate)
    cap_id = review["target_capability_id"]
    cap, cap_path, cap_digest = load_capability(cap_id, root)
    required = set(cap["authority"]["required"])
    optional = set(cap["authority"]["optional"])
    forbidden = set(cap["authority"]["forbidden"])
    allowed = required | optional
    declared = set(candidate["declaration"]["authority_signals"])
    requested = set(review["requested_authority"])
    approved = set(review["approved_authority"])
    reasons: list[str] = []
    verdict = "APPROVED"

    if review["disposition"] == "reject":
        verdict, reasons = "REJECTED", ["explicit-review-rejection"]
    if declared - requested:
        verdict = "REJECTED"
        reasons.append("review-omits-declared-authority:" + ",".join(sorted(declared - requested)))
    if approved - requested:
        verdict = "REJECTED"
        reasons.append("approval-exceeds-request:" + ",".join(sorted(approved - requested)))
    conflicts = requested & forbidden
    outside = requested - allowed
    if conflicts:
        verdict = "REJECTED"
        reasons.append("canonical-authority-conflict:" + ",".join(sorted(conflicts)))
    if outside:
        verdict = "REJECTED"
        reasons.append("authority-outside-canonical-contract:" + ",".join(sorted(outside)))
    if required - approved:
        verdict = "REJECTED"
        reasons.append("approval-misses-canonical-required:" + ",".join(sorted(required - approved)))

    prohibited = requested & set(policy["prohibited_authority"])
    if prohibited:
        verdict = "REJECTED"
        reasons.append("policy-prohibited-authority:" + ",".join(sorted(prohibited)))

    if candidate["provenance"]["assurance"] == "incomplete" and verdict == "APPROVED":
        verdict = "REVIEW_REQUIRED"
        reasons.append("incomplete-provenance")
    if candidate["provenance"]["manifest_reasons"] and candidate["format"] == "arsenal-package":
        verdict = "REJECTED"
        reasons.append("compiler-manifest-verification-failed")

    unack = set(candidate["declaration"]["unmapped_tools"]) - set(review["acknowledged_unmapped_tools"])
    unreviewed_exec = set(candidate["risk"]["executable_paths"]) - set(review["reviewed_executable_paths"])
    if (unack or unreviewed_exec) and verdict == "APPROVED":
        verdict = "REVIEW_REQUIRED"
        if unack:
            reasons.append("unacknowledged-tool-surface:" + ",".join(sorted(unack)))
        if unreviewed_exec:
            reasons.append("unreviewed-executable-surface:" + ",".join(sorted(unreviewed_exec)))

    escalation_needed = sorted(requested & set(policy["escalation_authority"]))
    escalation = review.get("escalation", {})
    if escalation_needed and verdict == "APPROVED":
        if not escalation.get("confirmed") or not escalation.get("confirmation_reference"):
            verdict = "ESCALATION_REQUIRED"
            reasons.append("explicit-escalation-confirmation-required")
        else:
            reasons.append("explicit-escalation-confirmed:" + ",".join(escalation_needed))

    effective = sorted(approved) if verdict == "APPROVED" else []
    policy_digest, review_digest = digest_json(policy), digest_json(review)
    material = {"candidate_sha256": candidate["package"]["sha256"], "policy_sha256": policy_digest,
                "review_sha256": review_digest, "capability_sha256": cap_digest,
                "verdict": verdict, "effective_authority": effective}
    decision_id = "trust-" + digest_json(material).split(":", 1)[1][:24]
    challenge_reasons = sorted(set(escalation_needed) & set(policy.get("challenge_authority", [])))
    if not reasons and verdict == "APPROVED":
        reasons = ["reviewed-exact-bytes-within-canonical-and-policy-authority"]

    return {
        "schema_version": "1.0.0", "decision_id": decision_id,
        "supersedes_decision_id": None, "verdict": verdict, "reasons": reasons,
        "candidate": {"id": candidate["candidate_id"], "sha256": candidate["package"]["sha256"],
                      "format": candidate["format"], "source": candidate["source"],
                      "provenance_assurance": candidate["provenance"]["assurance"]},
        "policy": {"id": policy["policy_id"], "sha256": policy_digest},
        "review": {"reference": review["review_reference"], "sha256": review_digest,
                   "disposition": review["disposition"],
                   "escalation_confirmation_reference": escalation.get("confirmation_reference")},
        "target": {"capability_id": cap_id, "version": cap["version"],
                   "capability_path": cap_path.relative_to(root).as_posix(),
                   "capability_sha256": cap_digest},
        "authority": {"declared_signals": sorted(declared), "requested": sorted(requested),
                      "approved": sorted(approved), "effective": effective,
                      "canonical_required": sorted(required), "canonical_optional": sorted(optional),
                      "canonical_forbidden": sorted(forbidden),
                      "escalation_required_for": escalation_needed},
        "route_gate": {"authorized": verdict == "APPROVED", "required_decision_id": decision_id},
        "challenge": {"required": bool(challenge_reasons),
                      "status": "pending" if challenge_reasons else "not-required",
                      "reasons": challenge_reasons},
        "reconsideration_triggers": RECONSIDERATION,
        "content_change_action": "REQUARANTINE",
    }


def revoke_decision(decision: dict[str, Any], reason: str, reference: str) -> dict[str, Any]:
    if decision.get("verdict") != "APPROVED":
        raise AssertionError("only an APPROVED decision can be revoked")
    revoked = json.loads(json.dumps(decision))
    material = {"prior_decision_id": decision["decision_id"], "candidate_sha256": decision["candidate"]["sha256"],
                "reason": reason, "reference": reference}
    revoked["supersedes_decision_id"] = decision["decision_id"]
    revoked["decision_id"] = "trust-" + digest_json(material).split(":", 1)[1][:24]
    revoked["verdict"] = "REVOKED"
    revoked["reasons"] = ["explicit-revocation:" + reason]
    revoked["authority"]["effective"] = []
    revoked["route_gate"] = {"authorized": False, "required_decision_id": revoked["decision_id"]}
    revoked["revocation"] = {"reason": reason, "reference": reference}
    return revoked


def verify_decision(package: Path, decision: dict[str, Any], policy: dict[str, Any],
                    root: Path = ROOT) -> tuple[str, list[str]]:
    if decision.get("verdict") == "REVOKED":
        return "REVOKED", ["decision-explicitly-revoked"]
    if decision.get("verdict") != "APPROVED":
        return "NOT_AUTHORIZED", [f"decision-verdict-{decision.get('verdict')}"]
    reasons: list[str] = []
    _, package_digest = package_inventory(package)
    if package_digest != decision["candidate"]["sha256"]:
        reasons.append("candidate-digest-change")
    if digest_json(policy) != decision["policy"]["sha256"]:
        reasons.append("policy-digest-change")
    cap, cap_path, cap_digest = load_capability(decision["target"]["capability_id"], root)
    if cap_digest != decision["target"]["capability_sha256"]:
        reasons.append("canonical-capability-change")
    if cap_path.relative_to(root).as_posix() != decision["target"]["capability_path"]:
        reasons.append("canonical-capability-path-change")
    allowed = set(cap["authority"]["required"]) | set(cap["authority"]["optional"])
    effective = set(decision["authority"]["effective"])
    if not effective <= allowed:
        reasons.append("effective-authority-no-longer-canonical")
    if effective & set(cap["authority"]["forbidden"]):
        reasons.append("effective-authority-now-forbidden")
    if reasons:
        return ("REQUARANTINE" if "candidate-digest-change" in reasons else "REVIEW_REQUIRED"), reasons
    return "AUTHORIZED", ["exact-candidate-policy-capability-binding-valid"]


def cmd_discover(a: argparse.Namespace) -> int:
    candidate = discover_package(Path(a.package), a.source_kind, a.source, a.revision)
    write_json(Path(a.output), candidate)
    print(f"ARS-08 trust discover: QUARANTINED ({candidate['candidate_id']})")
    print(f"package: {candidate['package']['sha256']}")
    print(f"provenance: {candidate['provenance']['assurance']}")
    return 0


def cmd_assess(a: argparse.Namespace) -> int:
    decision = assess_candidate(load_json(Path(a.candidate)), load_json(Path(a.review)), load_json(Path(a.policy)))
    write_json(Path(a.output), decision)
    print(f"ARS-08 trust assessment: {decision['verdict']} ({decision['decision_id']})")
    for reason in decision["reasons"]:
        print(f"  - {reason}")
    return EXIT[decision["verdict"]]


def cmd_verify(a: argparse.Namespace) -> int:
    decision, policy = load_json(Path(a.decision)), load_json(Path(a.policy))
    status, reasons = verify_decision(Path(a.package), decision, policy)
    print(f"ARS-08 trust verification: {status}")
    for reason in reasons:
        print(f"  - {reason}")
    if status == "AUTHORIZED":
        return 0
    if status == "REVOKED":
        return 7
    if status == "REQUARANTINE":
        return 3
    return 4


def cmd_revoke(a: argparse.Namespace) -> int:
    revoked = revoke_decision(load_json(Path(a.decision)), a.reason, a.reference)
    write_json(Path(a.output), revoked)
    print(f"ARS-08 trust revocation: REVOKED ({revoked['decision_id']})")
    return 0


def cmd_validate(a: argparse.Namespace) -> int:
    policy = load_json(Path(a.policy)); validate_policy(policy)
    print(f"ARS-08 Trust & Authority contract: PASS ({len(AUTHORITY)} authority tokens; policy {policy['policy_id']})")
    return 0


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__); s = p.add_subparsers(dest="command", required=True)
    v = s.add_parser("validate"); v.add_argument("--policy", default=str(DEFAULT_POLICY)); v.set_defaults(func=cmd_validate)
    d = s.add_parser("discover"); d.add_argument("--package", required=True); d.add_argument("--source-kind", choices=["local-directory","git","arsenal-compiled","archive"], required=True); d.add_argument("--source", required=True); d.add_argument("--revision"); d.add_argument("--output", required=True); d.set_defaults(func=cmd_discover)
    a = s.add_parser("assess"); a.add_argument("--candidate", required=True); a.add_argument("--review", required=True); a.add_argument("--policy", default=str(DEFAULT_POLICY)); a.add_argument("--output", required=True); a.set_defaults(func=cmd_assess)
    q = s.add_parser("verify"); q.add_argument("--package", required=True); q.add_argument("--decision", required=True); q.add_argument("--policy", default=str(DEFAULT_POLICY)); q.set_defaults(func=cmd_verify)
    r = s.add_parser("revoke"); r.add_argument("--decision", required=True); r.add_argument("--reason", required=True); r.add_argument("--reference", required=True); r.add_argument("--output", required=True); r.set_defaults(func=cmd_revoke)
    return p


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        print(f"ARS-08 trust error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
