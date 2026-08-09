#!/usr/bin/env python3
"""Contract and negative tests for ARS-09 Knowledge Plane v0."""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("arsenal_knowledge", ROOT / "scripts/arsenal_knowledge.py")
knowledge = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(knowledge)

FIXTURE = ROOT / "arsenal/knowledge/fixtures/kft-0-kiln.json"


def load_fixture():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def main() -> int:
    snapshot = load_fixture()
    assert knowledge.validate_snapshot(snapshot) == []
    print("PASS KFT-0 fixture is a structurally valid exact-state Knowledge Snapshot")

    first = knowledge.digest_json(snapshot)
    second = knowledge.digest_json(json.loads(json.dumps(snapshot)))
    assert first == second and knowledge.is_digest(first)
    print("PASS snapshot fingerprint is deterministic and content-addressed")

    result = knowledge.evaluate_authority(snapshot, "query.kft-0.p1-s02-t01-authority")
    assert result["verdict"] == "NOT_AUTHORIZED", result
    assert result["may_implement"] is False
    assert result["reason_codes"] == ["EXPLICIT_NOT_AUTHORIZED"]
    assert result["resolution"]["authority_rank"] == 0
    assert "claim.kiln.pr48.authorized" in result["resolution"]["challenged_by"]
    print("PASS stronger repository authority defeats a conflicting PR authorization claim")

    contradiction = next(x for x in result["contradictions"] if x["predicate"] == "implementation_authorization")
    assert contradiction["values"] == ["authorized", "not-authorized"]
    codes = {x["code"] for x in result["lifecycle_findings"]}
    assert {"PROPOSED_PLAN_HAS_IMPLEMENTATION", "IMPLEMENTATION_WITHOUT_AUTHORIZATION"} <= codes
    print("PASS cross-source contradiction and impossible lifecycle combinations remain visible")

    compiled = knowledge.compile_context(snapshot, "query.kft-0.p1-s02-t01-authority")
    assert compiled["authority"]["verdict"] == "NOT_AUTHORIZED"
    assert compiled["selection"]["excluded_count"] > 0
    selected = set(compiled["selection"]["selected_ids"])
    assert "knowledge.kiln.authority-invariant" in selected
    assert len(selected) < len(snapshot["knowledge"])
    print("PASS task context follows relevant relationships without dumping the full snapshot")

    duplicate = copy.deepcopy(snapshot)
    duplicate["knowledge"][1]["id"] = duplicate["knowledge"][0]["id"]
    assert any("duplicate id" in error for error in knowledge.validate_snapshot(duplicate))
    print("PASS duplicate cross-document identifiers fail structural validation")

    unresolved = copy.deepcopy(snapshot)
    unresolved["knowledge"][0]["source_refs"].append("source.missing")
    assert any("unresolved source_ref" in error for error in knowledge.validate_snapshot(unresolved))
    print("PASS unresolved provenance references fail structural validation")

    top_conflict = copy.deepcopy(snapshot)
    next(s for s in top_conflict["sources"] if s["id"] == "source.kiln.pr48")["authority_rank"] = 0
    blocked = knowledge.evaluate_authority(top_conflict, "query.kft-0.p1-s02-t01-authority")
    assert blocked["verdict"] == "BLOCKED"
    assert blocked["reason_codes"] == ["CONTRADICTORY_TOP_AUTHORITY"]
    print("PASS equally authoritative contradictory claims fail closed")

    missing_record = copy.deepcopy(snapshot)
    missing_record["claims"] = [
        c for c in missing_record["claims"]
        if c["predicate"] != "implementation_authorization" or c["value"] == "authorized"
    ]
    missing = knowledge.evaluate_authority(missing_record, "query.kft-0.p1-s02-t01-authority")
    assert missing["verdict"] == "BLOCKED"
    assert missing["reason_codes"] == ["MISSING_ACTIVE_AUTHORIZATION_RECORD"]
    print("PASS an authorized prose claim cannot replace a bound authorization record")

    exact = copy.deepcopy(missing_record)
    target = exact["queries"][0]["target"]
    exact["sources"].append({
        "id": "source.kiln.owner-authorization-test",
        "kind": "owner-authorization",
        "locator": "fixture://owner-authorization-test",
        "authority_rank": 0,
        "state_binding": {"repository_sha": target["repository_sha"]},
        "content_sha256": "sha256:" + "1" * 64,
        "retrieval": {"status": "retrieved", "durability": "repository", "limitation": "Synthetic test record."}
    })
    exact["authorization_records"] = [{
        "id": "authorization.test.exact",
        "subject_id": "work.kiln.p1-s02-t01",
        "owner": "owner.joshua-jenks",
        "scope": "P1-S02-T01 only",
        "base_repository_sha": target["repository_sha"],
        "plan_path": target["plan_path"],
        "plan_sha256": target["plan_sha256"],
        "issued_at": "2026-08-09T01:30:00Z",
        "status": "active",
        "source_ref": "source.kiln.owner-authorization-test"
    }]
    authorized = knowledge.evaluate_authority(exact, "query.kft-0.p1-s02-t01-authority")
    assert authorized["verdict"] == "AUTHORIZED"
    assert authorized["may_implement"] is True
    assert authorized["authorization_record_ids"] == ["authorization.test.exact"]
    print("PASS exact owner, scope, base SHA, plan path, and digest can authorize")

    drifted = copy.deepcopy(exact)
    drifted["authorization_records"][0]["plan_sha256"] = "sha256:" + "0" * 64
    stale = knowledge.evaluate_authority(drifted, "query.kft-0.p1-s02-t01-authority")
    assert stale["verdict"] == "STALE"
    assert stale["reason_codes"] == ["AUTHORIZATION_BINDING_MISMATCH"]
    print("PASS plan or exact-state drift invalidates authorization applicability")

    no_claim = copy.deepcopy(snapshot)
    no_claim["claims"] = [c for c in no_claim["claims"] if c["predicate"] != "implementation_authorization"]
    unknown = knowledge.evaluate_authority(no_claim, "query.kft-0.p1-s02-t01-authority")
    assert unknown["verdict"] == "UNKNOWN" and unknown["may_implement"] is False
    print("PASS absent authority evidence remains UNKNOWN and cannot authorize")

    stale_only = copy.deepcopy(snapshot)
    stale_only["claims"] = [c for c in stale_only["claims"] if c["predicate"] == "implementation_authorization"]
    for source in stale_only["sources"]:
        if any(c["source_ref"] == source["id"] for c in stale_only["claims"]):
            source["state_binding"]["repository_sha"] = "0" * 40
    stale_result = knowledge.evaluate_authority(stale_only, "query.kft-0.p1-s02-t01-authority")
    assert stale_result["verdict"] == "STALE"
    assert stale_result["reason_codes"] == ["ONLY_STALE_AUTHORITY_CLAIMS"]
    print("PASS evidence bound only to an older repository state cannot authorize the target")

    assert knowledge.compile_context(snapshot, "query.kft-0.p1-s02-t01-authority") == compiled
    print("PASS compiled context and authority result are deterministic")
    print("ARS-09 Knowledge Plane contract suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
