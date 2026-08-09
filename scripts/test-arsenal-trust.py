#!/usr/bin/env python3
"""Contract and negative tests for ARS-08 Trust & Authority."""
from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("arsenal_trust", ROOT / "scripts/arsenal_trust.py")
trust = importlib.util.module_from_spec(spec); assert spec and spec.loader; spec.loader.exec_module(trust)


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def review(candidate, target, requested, *, approved=None, acknowledged=(), executable=(), escalation=False, reference=None):
    return {
        "schema_version": "1.0.0", "candidate_sha256": candidate["package"]["sha256"],
        "target_capability_id": target, "disposition": "approve", "review_reference": "review.test.fixture",
        "requested_authority": sorted(requested), "approved_authority": sorted(approved if approved is not None else requested),
        "acknowledged_unmapped_tools": sorted(acknowledged), "reviewed_executable_paths": sorted(executable),
        "evidence_refs": [], "escalation": {"confirmed": escalation, "confirmation_reference": reference},
        "notes": "Synthetic contract-test review; not a real third-party approval.",
    }


def verdict(decision, expected):
    assert decision["verdict"] == expected, (expected, decision["verdict"], decision["reasons"])


def main() -> int:
    policy = load(ROOT / "arsenal/trust/policy.json")
    trust.validate_policy(policy)
    print("PASS valid conservative trust policy")

    safe_path = ROOT / "arsenal/trust/fixtures/third-party-safe"
    a = trust.discover_package(safe_path, "local-directory", "fixture://third-party-safe", None, ROOT)
    b = trust.discover_package(safe_path, "local-directory", "fixture://third-party-safe", None, ROOT)
    assert a == b and a["state"] == "QUARANTINED"
    assert a["declaration"]["authority_signals"] == ["filesystem.read", "git.read", "shell.execute"]
    assert a["declaration"]["unmapped_tools"] == []
    print("PASS deterministic discovery enters quarantine with mapped Agent Skills authority signals")

    safe_review = review(a, "capability.repository-truth", ["filesystem.read", "git.read", "shell.execute"])
    approved = trust.assess_candidate(a, safe_review, policy, ROOT)
    verdict(approved, "APPROVED")
    assert approved["route_gate"]["authorized"] is True
    assert approved["authority"]["effective"] == ["filesystem.read", "git.read", "shell.execute"]
    print("PASS reviewed exact third-party bytes can earn a bounded Repository Truth approval")

    status, reasons = trust.verify_decision(safe_path, approved, policy, ROOT)
    assert status == "AUTHORIZED", reasons
    print("PASS approved decision verifies against exact package, policy, and canonical capability")

    original = (safe_path / "SKILL.md").read_text(encoding="utf-8")
    try:
        (safe_path / "SKILL.md").write_text(original + "\nDrift.\n", encoding="utf-8")
        status, reasons = trust.verify_decision(safe_path, approved, policy, ROOT)
        assert status == "REQUARANTINE" and "candidate-digest-change" in reasons
    finally:
        (safe_path / "SKILL.md").write_text(original, encoding="utf-8")
    print("PASS post-approval content drift re-quarantines rather than inheriting trust")

    revoked = trust.revoke_decision(approved, "fixture revocation", "review.test.revocation")
    assert revoked["verdict"] == "REVOKED" and revoked["authority"]["effective"] == []
    assert revoked["route_gate"]["authorized"] is False
    assert trust.verify_decision(safe_path, revoked, policy, ROOT)[0] == "REVOKED"
    print("PASS approval is explicitly revocable without rewriting prior evidence")

    over_path = ROOT / "arsenal/trust/fixtures/third-party-overbroad"
    over = trust.discover_package(over_path, "local-directory", "fixture://third-party-overbroad", None, ROOT)
    over_decision = trust.assess_candidate(over, review(over, "capability.repository-truth", over["declaration"]["authority_signals"]), policy, ROOT)
    verdict(over_decision, "REJECTED")
    assert any(x.startswith("canonical-authority-conflict:") for x in over_decision["reasons"])
    print("PASS overbroad third-party import cannot override canonical forbidden authority")

    tdd_path = ROOT / "arsenal/trust/fixtures/tdd-escalation"
    tdd = trust.discover_package(tdd_path, "local-directory", "fixture://tdd-escalation", None, ROOT)
    assert tdd["declaration"]["unmapped_tools"] == ["Bash(pytest:*)"]
    requested = ["filesystem.read", "filesystem.write", "git.read", "shell.execute"]
    pending = trust.assess_candidate(tdd, review(tdd, "capability.tdd", requested, acknowledged=tdd["declaration"]["unmapped_tools"]), policy, ROOT)
    verdict(pending, "ESCALATION_REQUIRED")
    assert pending["route_gate"]["authorized"] is False
    print("PASS mutation authority requires explicit escalation rather than silent widening")

    confirmed = trust.assess_candidate(tdd, review(tdd, "capability.tdd", requested,
        acknowledged=tdd["declaration"]["unmapped_tools"], escalation=True,
        reference="review.test.human-confirmation"), policy, ROOT)
    verdict(confirmed, "APPROVED")
    assert "filesystem.write" in confirmed["authority"]["effective"]
    print("PASS explicit reviewed escalation can authorize only the approved canonical subset")

    unpinned = trust.discover_package(safe_path, "git", "https://example.invalid/repository.git", None, ROOT)
    unpinned_decision = trust.assess_candidate(unpinned, review(unpinned, "capability.repository-truth",
        ["filesystem.read", "git.read", "shell.execute"]), policy, ROOT)
    verdict(unpinned_decision, "REVIEW_REQUIRED")
    assert "incomplete-provenance" in unpinned_decision["reasons"]
    print("PASS git-origin competence without an exact revision cannot earn approval")

    hidden = trust.assess_candidate(over, review(over, "capability.repository-truth",
        ["filesystem.read", "git.read", "shell.execute", "network.read"]), policy, ROOT)
    verdict(hidden, "REJECTED")
    assert any(x.startswith("review-omits-declared-authority:") for x in hidden["reasons"])
    print("PASS review cannot hide authority signaled by the imported package")

    inflated = trust.assess_candidate(a, review(a, "capability.repository-truth",
        ["filesystem.read", "git.read", "shell.execute"],
        approved=["filesystem.read", "git.read", "shell.execute", "network.read"]), policy, ROOT)
    verdict(inflated, "REJECTED")
    assert any(x.startswith("approval-exceeds-request:") for x in inflated["reasons"])
    print("PASS approval cannot grant authority the review did not request")

    bad = json.loads(json.dumps(policy)); bad["auto_approval"] = True
    try:
        trust.validate_policy(bad)
    except AssertionError:
        pass
    else:
        raise AssertionError("auto approval policy should fail")
    print("PASS automatic third-party trust is rejected by v0 policy contract")

    with tempfile.TemporaryDirectory() as tmp:
        package = Path(tmp) / "pkg"; package.mkdir()
        (package / "SKILL.md").write_text("---\nname: x\ndescription: xxxxxxxx\n---\n", encoding="utf-8")
        try:
            (package / "escape").symlink_to(ROOT / "README.md")
            try:
                trust.package_inventory(package)
            except AssertionError:
                pass
            else:
                raise AssertionError("symlink package should fail")
        except (OSError, NotImplementedError):
            pass
    print("PASS imported packages reject symlink indirection")

    assert approved["reconsideration_triggers"] == trust.RECONSIDERATION
    assert approved["content_change_action"] == "REQUARANTINE"
    assert "authorized" in approved["route_gate"] and "required" in approved["challenge"]
    print("PASS ARS-09/10/11/12 seams are data-level only: reconsideration, route gate, challenge, re-quarantine")
    print("ARS-08 Trust & Authority contract suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
