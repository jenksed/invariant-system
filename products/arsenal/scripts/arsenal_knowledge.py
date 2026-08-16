#!/usr/bin/env python3
"""Validate and query Project Arsenal Knowledge Plane snapshots.

The v0 implementation deliberately consumes typed observations. It does not
pretend that a generic Markdown parser can infer repository authority safely.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import sys
from typing import Any

# Shared I/O primitives.
from arsenal_io import load_json

def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


ROOT = Path(__file__).resolve().parents[1]

KINDS = {
    "Decision", "Requirement", "Invariant", "Assumption", "Unknown",
    "NegativeKnowledge", "Evidence", "Experiment", "Observation", "Incident",
    "Capability", "Artifact", "ReconsiderationTrigger", "Exception",
    "FrictionEvent", "CompetenceExpectation", "Authorization",
}
KNOWLEDGE_STATUSES = {"candidate", "accepted", "rejected", "superseded", "unknown"}
PREDICATES = {
    "planning_status", "permission_status", "implementation_authorization",
    "implementation_status", "verification_status", "acceptance_status",
}
PREDICATE_VALUES = {
    "planning_status": {"unplanned", "proposed", "accepted"},
    "permission_status": {"unspecified", "permitted", "forbidden"},
    "implementation_authorization": {"not-authorized", "authorized", "revoked"},
    "implementation_status": {"not-started", "in-progress", "implemented"},
    "verification_status": {"unverified", "verified", "failed"},
    "acceptance_status": {"unaccepted", "accepted", "rejected"},
}
AUTHORITY_VERDICTS = {"AUTHORIZED", "NOT_AUTHORIZED", "BLOCKED", "STALE", "UNKNOWN"}
HEX64 = set("0123456789abcdef")


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def digest_json(value: Any) -> str:
    return "sha256:" + hashlib.sha256(canonical_json(value)).hexdigest()


def is_digest(value: Any) -> bool:
    return (
        isinstance(value, str)
        and value.startswith("sha256:")
        and len(value) == 71
        and set(value[7:]) <= HEX64
    )


def _require_id(value: Any, label: str, errors: list[str]) -> None:
    if not isinstance(value, str) or not value or any(ch.isspace() for ch in value):
        errors.append(f"{label} must be a non-empty whitespace-free string")


def validate_snapshot(snapshot: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if snapshot.get("schema_version") != "1.0.0":
        errors.append("schema_version must be 1.0.0")
    if snapshot.get("record_kind") != "arsenal-knowledge-snapshot":
        errors.append("record_kind must be arsenal-knowledge-snapshot")
    _require_id(snapshot.get("snapshot_id"), "snapshot_id", errors)

    subject = snapshot.get("subject")
    if not isinstance(subject, dict):
        errors.append("subject must be an object")
        subject = {}
    if not isinstance(subject.get("repository"), str) or "/" not in subject.get("repository", ""):
        errors.append("subject.repository must be owner/name")
    sha = subject.get("repository_sha")
    if not isinstance(sha, str) or len(sha) != 40 or set(sha) - HEX64:
        errors.append("subject.repository_sha must be a lowercase 40-character Git SHA")
    if subject.get("mode") not in {"read-only", "assisted", "routed"}:
        errors.append("subject.mode must be read-only, assisted, or routed")

    ids: dict[str, str] = {}

    def register(value: Any, label: str) -> None:
        _require_id(value, label, errors)
        if not isinstance(value, str) or not value:
            return
        if value in ids:
            errors.append(f"duplicate id {value}: {ids[value]} and {label}")
        ids[value] = label

    sources = snapshot.get("sources")
    if not isinstance(sources, list) or not sources:
        errors.append("sources must be a non-empty array")
        sources = []
    for i, source in enumerate(sources):
        if not isinstance(source, dict):
            errors.append(f"sources[{i}] must be an object")
            continue
        register(source.get("id"), f"sources[{i}].id")
        if source.get("kind") not in {
            "repository-instruction", "governing-plan", "accepted-plan", "proposed-plan",
            "pull-request", "git", "evidence", "owner-authorization", "field-observation",
        }:
            errors.append(f"sources[{i}].kind is invalid")
        rank = source.get("authority_rank")
        if not isinstance(rank, int) or isinstance(rank, bool) or rank < 0:
            errors.append(f"sources[{i}].authority_rank must be a non-negative integer")
        binding = source.get("state_binding")
        if not isinstance(binding, dict) or not isinstance(binding.get("repository_sha"), str):
            errors.append(f"sources[{i}].state_binding.repository_sha is required")
        elif binding.get("artifact_sha") is not None:
            artifact_sha = binding.get("artifact_sha")
            if not isinstance(artifact_sha, str) or len(artifact_sha) != 40 or set(artifact_sha) - HEX64:
                errors.append(f"sources[{i}].state_binding.artifact_sha must be a lowercase 40-character Git SHA")
        digest = source.get("content_sha256")
        if digest is not None and not is_digest(digest):
            errors.append(f"sources[{i}].content_sha256 must be null or sha256:<64 hex>")
        retrieval = source.get("retrieval")
        if not isinstance(retrieval, dict) or retrieval.get("status") not in {
            "retrieved", "not-retrieved", "unavailable"
        }:
            errors.append(f"sources[{i}].retrieval.status is invalid")

    knowledge = snapshot.get("knowledge")
    if not isinstance(knowledge, list):
        errors.append("knowledge must be an array")
        knowledge = []
    for i, entry in enumerate(knowledge):
        if not isinstance(entry, dict):
            errors.append(f"knowledge[{i}] must be an object")
            continue
        register(entry.get("id"), f"knowledge[{i}].id")
        if entry.get("kind") not in KINDS:
            errors.append(f"knowledge[{i}].kind is invalid")
        if entry.get("status") not in KNOWLEDGE_STATUSES:
            errors.append(f"knowledge[{i}].status is invalid")
        if not isinstance(entry.get("statement"), str) or not entry.get("statement"):
            errors.append(f"knowledge[{i}].statement is required")
        if not isinstance(entry.get("source_refs"), list) or not entry.get("source_refs"):
            errors.append(f"knowledge[{i}].source_refs must be non-empty")

    claims = snapshot.get("claims")
    if not isinstance(claims, list):
        errors.append("claims must be an array")
        claims = []
    for i, claim in enumerate(claims):
        if not isinstance(claim, dict):
            errors.append(f"claims[{i}] must be an object")
            continue
        register(claim.get("id"), f"claims[{i}].id")
        _require_id(claim.get("subject_id"), f"claims[{i}].subject_id", errors)
        predicate = claim.get("predicate")
        if predicate not in PREDICATES:
            errors.append(f"claims[{i}].predicate is invalid")
        elif claim.get("value") not in PREDICATE_VALUES[predicate]:
            errors.append(f"claims[{i}].value is invalid for {predicate}")
        if not isinstance(claim.get("source_ref"), str):
            errors.append(f"claims[{i}].source_ref is required")

    relationships = snapshot.get("relationships")
    if not isinstance(relationships, list):
        errors.append("relationships must be an array")
        relationships = []
    for i, edge in enumerate(relationships):
        if not isinstance(edge, dict):
            errors.append(f"relationships[{i}] must be an object")
            continue
        register(edge.get("id"), f"relationships[{i}].id")
        for field in ("from", "to", "kind"):
            _require_id(edge.get(field), f"relationships[{i}].{field}", errors)
        if edge.get("kind") not in {
            "supported-by", "challenged-by", "governed-by", "blocks", "requires",
            "reconsiders", "observed-as",
        }:
            errors.append(f"relationships[{i}].kind is invalid")

    records = snapshot.get("authorization_records")
    if not isinstance(records, list):
        errors.append("authorization_records must be an array")
        records = []
    for i, record in enumerate(records):
        if not isinstance(record, dict):
            errors.append(f"authorization_records[{i}] must be an object")
            continue
        register(record.get("id"), f"authorization_records[{i}].id")
        for field in ("subject_id", "owner", "source_ref"):
            _require_id(record.get(field), f"authorization_records[{i}].{field}", errors)
        if not isinstance(record.get("scope"), str) or not record.get("scope"):
            errors.append(f"authorization_records[{i}].scope is required")
        base_sha = record.get("base_repository_sha")
        if not isinstance(base_sha, str) or len(base_sha) != 40 or set(base_sha) - HEX64:
            errors.append(f"authorization_records[{i}].base_repository_sha must be a lowercase 40-character Git SHA")
        if not isinstance(record.get("plan_path"), str) or not record.get("plan_path"):
            errors.append(f"authorization_records[{i}].plan_path is required")
        if not is_digest(record.get("plan_sha256")):
            errors.append(f"authorization_records[{i}].plan_sha256 must be sha256:<64 hex>")
        if record.get("status") not in {"active", "revoked", "expired", "consumed"}:
            errors.append(f"authorization_records[{i}].status is invalid")

    observations = snapshot.get("field_observations")
    if not isinstance(observations, list):
        errors.append("field_observations must be an array")
        observations = []
    for i, observation in enumerate(observations):
        if not isinstance(observation, dict):
            errors.append(f"field_observations[{i}] must be an object")
            continue
        register(observation.get("id"), f"field_observations[{i}].id")
        if observation.get("classification") not in {"got-right", "got-wrong", "friction", "gap", "loss", "unknown"}:
            errors.append(f"field_observations[{i}].classification is invalid")
        if not isinstance(observation.get("statement"), str) or not observation.get("statement"):
            errors.append(f"field_observations[{i}].statement is required")
        if not isinstance(observation.get("source_refs"), list):
            errors.append(f"field_observations[{i}].source_refs must be an array")

    queries = snapshot.get("queries")
    if not isinstance(queries, list) or not queries:
        errors.append("queries must be a non-empty array")
        queries = []
    for i, query in enumerate(queries):
        if not isinstance(query, dict):
            errors.append(f"queries[{i}] must be an object")
            continue
        register(query.get("id"), f"queries[{i}].id")
        if query.get("kind") not in {"implementation-authority", "task-context"}:
            errors.append(f"queries[{i}].kind is invalid")
        _require_id(query.get("subject_id"), f"queries[{i}].subject_id", errors)
        target = query.get("target")
        if not isinstance(target, dict):
            errors.append(f"queries[{i}].target must be an object")
        else:
            if target.get("repository_sha") != sha:
                errors.append(f"queries[{i}].target.repository_sha must equal subject.repository_sha")
            if query.get("kind") == "implementation-authority":
                _require_id(target.get("owner"), f"queries[{i}].target.owner", errors)
                if not isinstance(target.get("scope"), str) or not target.get("scope"):
                    errors.append(f"queries[{i}].target.scope is required")
                if not isinstance(target.get("plan_path"), str) or not target.get("plan_path"):
                    errors.append(f"queries[{i}].target.plan_path is required")
                if not is_digest(target.get("plan_sha256")):
                    errors.append(f"queries[{i}].target.plan_sha256 must be sha256:<64 hex>")
        seeds = query.get("context_entity_ids")
        if not isinstance(seeds, list) or not seeds:
            errors.append(f"queries[{i}].context_entity_ids must be non-empty")

    source_ids = {s.get("id") for s in sources if isinstance(s, dict)}
    knowledge_ids = {k.get("id") for k in knowledge if isinstance(k, dict)}
    for entry in knowledge:
        if not isinstance(entry, dict):
            continue
        for ref in entry.get("source_refs", []):
            if ref not in source_ids:
                errors.append(f"{entry.get('id')}: unresolved source_ref {ref}")
        for field in ("supports", "challenges", "reconsideration_triggers"):
            for ref in entry.get(field, []):
                if ref not in knowledge_ids:
                    errors.append(f"{entry.get('id')}: unresolved {field} reference {ref}")
    for claim in claims:
        if isinstance(claim, dict) and claim.get("source_ref") not in source_ids:
            errors.append(f"{claim.get('id')}: unresolved source_ref {claim.get('source_ref')}")
    for record in records:
        if not isinstance(record, dict):
            continue
        if record.get("source_ref") not in source_ids:
            errors.append(f"{record.get('id')}: unresolved source_ref {record.get('source_ref')}")
            continue
        source = next(s for s in sources if s.get("id") == record.get("source_ref"))
        if source.get("kind") != "owner-authorization":
            errors.append(f"{record.get('id')}: authorization source must be owner-authorization")
        if source.get("content_sha256") is None:
            errors.append(f"{record.get('id')}: authorization source must have an exact content digest")
    for edge in relationships:
        if not isinstance(edge, dict):
            continue
        for field in ("from", "to"):
            if edge.get(field) not in knowledge_ids:
                errors.append(f"{edge.get('id')}: unresolved {field} {edge.get(field)}")
    for query in queries:
        if not isinstance(query, dict):
            continue
        for ref in query.get("context_entity_ids", []):
            if ref not in knowledge_ids:
                errors.append(f"{query.get('id')}: unresolved context entity {ref}")
    for observation in observations:
        if not isinstance(observation, dict):
            continue
        for ref in observation.get("source_refs", []):
            if ref not in source_ids:
                errors.append(f"{observation.get('id')}: unresolved source_ref {ref}")
    return errors


def _indexes(snapshot: dict[str, Any]) -> tuple[dict[str, Any], dict[str, Any], dict[str, Any]]:
    return (
        {s["id"]: s for s in snapshot["sources"]},
        {k["id"]: k for k in snapshot["knowledge"]},
        {q["id"]: q for q in snapshot["queries"]},
    )


def _current_claims(
    snapshot: dict[str, Any], subject_id: str, predicate: str
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    sources, _, _ = _indexes(snapshot)
    repository_sha = snapshot["subject"]["repository_sha"]
    current: list[dict[str, Any]] = []
    stale: list[dict[str, Any]] = []
    for claim in snapshot["claims"]:
        if claim["subject_id"] != subject_id or claim["predicate"] != predicate:
            continue
        source = sources[claim["source_ref"]]
        retrieval = source["retrieval"]["status"]
        bound = source["state_binding"]["repository_sha"] == repository_sha
        row = {**claim, "authority_rank": source["authority_rank"], "source_kind": source["kind"]}
        if retrieval == "retrieved" and bound:
            current.append(row)
        else:
            stale.append(row)
    return current, stale


def resolve_claim(snapshot: dict[str, Any], subject_id: str, predicate: str) -> dict[str, Any]:
    current, stale = _current_claims(snapshot, subject_id, predicate)
    if not current:
        return {"status": "STALE" if stale else "UNKNOWN", "value": None,
                "claim_ids": [], "stale_claim_ids": sorted(c["id"] for c in stale)}
    rank = min(c["authority_rank"] for c in current)
    top = [c for c in current if c["authority_rank"] == rank]
    values = {json.dumps(c["value"], sort_keys=True) for c in top}
    if len(values) > 1:
        return {"status": "CONTRADICTORY", "value": None,
                "authority_rank": rank, "claim_ids": sorted(c["id"] for c in top),
                "stale_claim_ids": sorted(c["id"] for c in stale)}
    return {"status": "RESOLVED", "value": top[0]["value"], "authority_rank": rank,
            "claim_ids": sorted(c["id"] for c in top),
            "challenged_by": sorted(c["id"] for c in current if c["value"] != top[0]["value"]),
            "stale_claim_ids": sorted(c["id"] for c in stale)}


def contradictions(snapshot: dict[str, Any]) -> list[dict[str, Any]]:
    groups: dict[tuple[str, str], list[dict[str, Any]]] = {}
    sources, _, _ = _indexes(snapshot)
    repository_sha = snapshot["subject"]["repository_sha"]
    for claim in snapshot["claims"]:
        source = sources[claim["source_ref"]]
        if source["retrieval"]["status"] != "retrieved":
            continue
        if source["state_binding"]["repository_sha"] != repository_sha:
            continue
        groups.setdefault((claim["subject_id"], claim["predicate"]), []).append(claim)
    result = []
    for (subject_id, predicate), claims in sorted(groups.items()):
        values = {json.dumps(c["value"], sort_keys=True) for c in claims}
        if len(values) > 1:
            result.append({"subject_id": subject_id, "predicate": predicate,
                           "claim_ids": sorted(c["id"] for c in claims),
                           "values": sorted(json.loads(v) for v in values)})
    return result


def lifecycle_findings(snapshot: dict[str, Any], subject_id: str) -> list[dict[str, Any]]:
    resolved = {p: resolve_claim(snapshot, subject_id, p) for p in PREDICATES}
    value = lambda p: resolved[p]["value"] if resolved[p]["status"] == "RESOLVED" else None
    findings: list[dict[str, Any]] = []
    planning = value("planning_status")
    authorization = value("implementation_authorization")
    implementation = value("implementation_status")
    verification = value("verification_status")
    acceptance = value("acceptance_status")

    def add(code: str, message: str, predicates: list[str]) -> None:
        findings.append({"code": code, "message": message, "predicates": predicates})

    if planning == "proposed" and implementation in {"in-progress", "implemented"}:
        add("PROPOSED_PLAN_HAS_IMPLEMENTATION", "A proposed plan is associated with implementation activity.",
            ["planning_status", "implementation_status"])
    if implementation in {"in-progress", "implemented"} and authorization != "authorized":
        add("IMPLEMENTATION_WITHOUT_AUTHORIZATION", "Implementation activity lacks resolved authorization.",
            ["implementation_status", "implementation_authorization"])
    if verification == "verified" and implementation != "implemented":
        add("VERIFIED_WITHOUT_IMPLEMENTATION", "Verification cannot outrun implementation.",
            ["verification_status", "implementation_status"])
    if acceptance == "accepted" and verification != "verified":
        add("ACCEPTED_WITHOUT_VERIFICATION", "Acceptance cannot outrun verification.",
            ["acceptance_status", "verification_status"])
    return findings


def evaluate_authority(snapshot: dict[str, Any], query_id: str) -> dict[str, Any]:
    errors = validate_snapshot(snapshot)
    if errors:
        raise AssertionError("invalid snapshot: " + "; ".join(errors))
    sources, _, queries = _indexes(snapshot)
    if query_id not in queries:
        raise AssertionError(f"unknown query: {query_id}")
    query = queries[query_id]
    if query["kind"] != "implementation-authority":
        raise AssertionError(f"query is not implementation-authority: {query_id}")
    subject_id = query["subject_id"]
    resolution = resolve_claim(snapshot, subject_id, "implementation_authorization")
    reasons: list[str] = []
    record_ids: list[str] = []
    verdict = "UNKNOWN"

    if resolution["status"] == "CONTRADICTORY":
        verdict, reasons = "BLOCKED", ["CONTRADICTORY_TOP_AUTHORITY"]
    elif resolution["status"] == "STALE":
        verdict, reasons = "STALE", ["ONLY_STALE_AUTHORITY_CLAIMS"]
    elif resolution["status"] == "UNKNOWN":
        verdict, reasons = "UNKNOWN", ["NO_AUTHORITY_CLAIM"]
    elif resolution["value"] in {"not-authorized", "revoked"}:
        verdict = "NOT_AUTHORIZED"
        reasons = ["EXPLICIT_NOT_AUTHORIZED" if resolution["value"] == "not-authorized" else "AUTHORIZATION_REVOKED"]
    else:
        target = query["target"]
        candidates = [r for r in snapshot["authorization_records"] if r["subject_id"] == subject_id]
        active = [r for r in candidates if r["status"] == "active"]
        exact = [r for r in active if (
            r["owner"] == target["owner"]
            and r["scope"] == target["scope"]
            and r["base_repository_sha"] == target["repository_sha"]
            and r["plan_path"] == target["plan_path"]
            and r["plan_sha256"] == target["plan_sha256"]
            and sources[r["source_ref"]]["retrieval"]["status"] == "retrieved"
            and sources[r["source_ref"]]["state_binding"]["repository_sha"] == target["repository_sha"]
        )]
        if exact:
            verdict, record_ids = "AUTHORIZED", sorted(r["id"] for r in exact)
        elif active:
            verdict, reasons = "STALE", ["AUTHORIZATION_BINDING_MISMATCH"]
        else:
            verdict, reasons = "BLOCKED", ["MISSING_ACTIVE_AUTHORIZATION_RECORD"]

    assert verdict in AUTHORITY_VERDICTS
    return {
        "schema_version": "1.0.0",
        "record_kind": "arsenal-authority-result",
        "snapshot_id": snapshot["snapshot_id"],
        "snapshot_digest": digest_json(snapshot),
        "query_id": query_id,
        "subject_id": subject_id,
        "verdict": verdict,
        "reason_codes": reasons,
        "resolution": resolution,
        "authorization_record_ids": record_ids,
        "contradictions": contradictions(snapshot),
        "lifecycle_findings": lifecycle_findings(snapshot, subject_id),
        "may_implement": verdict == "AUTHORIZED",
    }


def compile_context(snapshot: dict[str, Any], query_id: str) -> dict[str, Any]:
    errors = validate_snapshot(snapshot)
    if errors:
        raise AssertionError("invalid snapshot: " + "; ".join(errors))
    sources, knowledge, queries = _indexes(snapshot)
    if query_id not in queries:
        raise AssertionError(f"unknown query: {query_id}")
    query = queries[query_id]
    selected = set(query["context_entity_ids"])
    changed = True
    while changed:
        changed = False
        for edge in snapshot["relationships"]:
            if edge["from"] in selected and edge["to"] not in selected:
                selected.add(edge["to"]); changed = True
            elif (
                edge["to"] in selected
                and edge["from"] not in selected
                and edge["kind"] in {"supported-by", "challenged-by", "governed-by"}
            ):
                selected.add(edge["from"]); changed = True
    entries = [knowledge[k] for k in sorted(selected)]
    source_refs = sorted({ref for entry in entries for ref in entry["source_refs"]})
    result = {
        "schema_version": "1.0.0",
        "record_kind": "arsenal-compiled-context",
        "snapshot_id": snapshot["snapshot_id"],
        "snapshot_digest": digest_json(snapshot),
        "query_id": query_id,
        "subject": snapshot["subject"],
        "knowledge": entries,
        "relationships": [e for e in snapshot["relationships"] if e["from"] in selected and e["to"] in selected],
        "sources": [sources[s] for s in source_refs],
        "selection": {"seed_ids": query["context_entity_ids"], "selected_ids": sorted(selected),
                      "excluded_count": len(snapshot["knowledge"]) - len(selected)},
    }
    if query["kind"] == "implementation-authority":
        result["authority"] = evaluate_authority(snapshot, query_id)
    return result


def _print_json(value: Any) -> None:
    print(json.dumps(value, indent=2, sort_keys=True))


def main() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("validate", "adjudicate", "compile", "fingerprint"):
        p = sub.add_parser(name)
        p.add_argument("--snapshot", type=Path, required=True)
        if name in {"adjudicate", "compile"}:
            p.add_argument("--query", required=True)
        if name == "validate":
            p.add_argument("--strict-findings", action="store_true")
    args = parser.parse_args()
    try:
        snapshot = load_json(args.snapshot)
        errors = validate_snapshot(snapshot)
        if errors:
            for error in errors:
                print(f"ERROR: {error}", file=sys.stderr)
            return 2
        if args.command == "fingerprint":
            print(digest_json(snapshot)); return 0
        if args.command == "adjudicate":
            result = evaluate_authority(snapshot, args.query); _print_json(result)
            return 0 if result["verdict"] == "AUTHORIZED" else 3
        if args.command == "compile":
            _print_json(compile_context(snapshot, args.query)); return 0
        subject_ids = sorted({c["subject_id"] for c in snapshot["claims"]})
        findings = [f for sid in subject_ids for f in lifecycle_findings(snapshot, sid)]
        report = {"snapshot_id": snapshot["snapshot_id"], "snapshot_digest": digest_json(snapshot),
                  "structural_errors": [], "contradictions": contradictions(snapshot),
                  "lifecycle_findings": findings}
        _print_json(report)
        return 1 if args.strict_findings and (report["contradictions"] or findings) else 0
    except (OSError, json.JSONDecodeError, AssertionError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
