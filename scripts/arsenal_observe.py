#!/usr/bin/env python3
"""ARS-07 Evidence Observatory / Agent Flight Recorder normalizer and validator."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = ROOT / "arsenal/observability/redaction-policy.json"
GRAPH_PATH = ROOT / "arsenal/graph/graph.json"
CAP_DIR = ROOT / "arsenal/capabilities"
SCHEMA_VERSION = "1.0.0"
RECORD_KIND = "arsenal-flight-record"
SHA_RE = re.compile(r"^sha256:[0-9a-f]{64}$")
TOP_LEVEL = {
    "schema_version",
    "record_kind",
    "run",
    "subject",
    "provenance",
    "authority",
    "context",
    "tools",
    "evidence",
    "timeline",
    "outcome",
    "privacy",
    "telemetry_mapping",
}
VALID_RUN_KINDS = {"capability-verification", "evaluation"}
VALID_VERDICTS = {"PASS", "FAIL", "BLOCKED", "UNKNOWN"}
IDENTITY_STATUSES = {"observed", "not-observed", "not-applicable"}


class ObserveError(Exception):
    pass


def read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as fh:
        value = json.load(fh)
    if not isinstance(value, dict):
        raise ObserveError(f"expected JSON object: {path}")
    return value


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode("utf-8")


def sha256_bytes(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def safe_rel(path: Path) -> str:
    resolved = path.resolve()
    try:
        rel = resolved.relative_to(ROOT)
    except ValueError as exc:
        raise ObserveError(f"source must remain inside repository: {path}") from exc
    return rel.as_posix()


def load_capability(capability_id: str) -> tuple[dict[str, Any], Path]:
    for path in sorted(CAP_DIR.glob("*.json")):
        doc = read_json(path)
        cap = doc.get("capability")
        if isinstance(cap, dict) and cap.get("id") == capability_id:
            return cap, path
    raise ObserveError(f"unknown capability: {capability_id}")


def authority_grants(profile_id: str | None) -> list[str]:
    if profile_id is None:
        return []
    graph = read_json(GRAPH_PATH)
    for item in graph.get("authority_profiles", []):
        if item.get("id") == profile_id:
            grants = item.get("grants")
            if isinstance(grants, list) and all(isinstance(x, str) for x in grants):
                return sorted(set(grants))
    raise ObserveError(f"unknown authority profile: {profile_id}")


def identity(status: str, identifier: str | None = None, version: str | None = None) -> dict[str, Any]:
    return {"status": status, "id": identifier, "version": version}


def privacy_block() -> dict[str, Any]:
    return {
        "policy": "metadata-first-content-off",
        "secrets_recorded": False,
        "prompt_content_recorded": False,
        "completion_content_recorded": False,
        "chain_of_thought_recorded": False,
    }


def telemetry_block() -> dict[str, Any]:
    return {
        "status": "mapping-only",
        "trace_name": "arsenal.run",
        "event_transport": "log-based-events",
        "attribute_namespace": "arsenal",
        "backend_required": False,
    }


def context_block(source_id: str, source_path: Path, *, token_status: str = "not-applicable") -> dict[str, Any]:
    return {
        "content_recording": "metadata-only",
        "sources": [
            {
                "kind": "source-receipt",
                "id": source_id,
                "digest": sha256_file(source_path),
                "bytes": source_path.stat().st_size,
            }
        ],
        "token_volume": {
            "status": token_status,
            "input_tokens": None,
            "output_tokens": None,
        },
    }


def evidence_item(evidence_id: str, kind: str, source_path: Path, claim: str, limitations: list[str]) -> dict[str, Any]:
    return {
        "id": evidence_id,
        "kind": kind,
        "source": safe_rel(source_path),
        "sha256": sha256_file(source_path),
        "accepted": True,
        "claim_scope": claim,
        "limitations": limitations,
    }


def stable_payload(record: dict[str, Any]) -> dict[str, Any]:
    value = copy.deepcopy(record)
    run = value["run"]
    run.pop("instance_id", None)
    run.pop("fingerprint", None)
    return value


def apply_fingerprint(record: dict[str, Any]) -> dict[str, Any]:
    record["run"]["fingerprint"] = sha256_bytes(canonical_bytes(stable_payload(record)))
    return record


def dagger_record(source_path: Path, instance_id: str, repository_sha: str) -> dict[str, Any]:
    source = read_json(source_path)
    if source.get("receipt_kind") != "arsenal-executable-world":
        raise ObserveError("Dagger source is not an arsenal-executable-world receipt")
    cap = source.get("capability", {})
    cap_id = cap.get("id")
    cap_version = cap.get("version")
    if not isinstance(cap_id, str) or not isinstance(cap_version, str):
        raise ObserveError("Dagger receipt lacks capability identity")
    canonical_cap, cap_path = load_capability(cap_id)
    if canonical_cap.get("version") != cap_version:
        raise ObserveError("Dagger receipt capability version does not match canonical capability")

    proof_gate = source.get("proof_gate", {})
    reports = proof_gate.get("reports")
    if not isinstance(reports, list) or not reports:
        raise ObserveError("Dagger receipt lacks proof-gate reports")
    if any(report.get("verdict") != "SELECTED" for report in reports):
        raise ObserveError("Dagger flight record requires selected proof-gate reports")
    profiles = {report.get("authority_profile") for report in reports}
    if len(profiles) != 1:
        raise ObserveError("Dagger proof-gate reports disagree on authority profile")
    profile = next(iter(profiles))
    if not isinstance(profile, str):
        raise ObserveError("Dagger proof-gate authority profile missing")
    grants = authority_grants(profile)
    required = sorted(set(canonical_cap.get("authority", {}).get("required", [])))
    missing = sorted(set(required) - set(grants))
    if missing:
        raise ObserveError(f"accepted Dagger receipt unexpectedly lacks authority: {missing}")

    runtime = source.get("adapter_runtime", {})
    runtime_id = runtime.get("id")
    runtime_version = runtime.get("version")
    if not isinstance(runtime_id, str) or not isinstance(runtime_version, str):
        raise ObserveError("Dagger adapter runtime identity missing")
    boundary = source.get("evidence_boundary", {})
    claim = boundary.get("claim")
    limitations = boundary.get("does_not_claim")
    if not isinstance(claim, str) or not isinstance(limitations, list) or not all(isinstance(x, str) for x in limitations):
        raise ObserveError("Dagger evidence boundary is invalid")

    evidence_id = "evidence.executable-world"
    selected = reports[0].get("selected", {})
    selected_id = selected.get("id")
    selected_rank = selected.get("reality_rank")
    record = {
        "schema_version": SCHEMA_VERSION,
        "record_kind": RECORD_KIND,
        "run": {
            "instance_id": instance_id,
            "fingerprint": "sha256:" + "0" * 64,
            "kind": "capability-verification",
            "status": "PASS",
        },
        "subject": {
            "capabilities": [{"id": cap_id, "version": cap_version}],
            "route_id": None,
            "suite_id": None,
        },
        "provenance": {
            "repository_sha": repository_sha,
            "model": identity("not-applicable"),
            "harness": identity("not-applicable"),
            "adapter": identity("observed", runtime_id, runtime_version),
        },
        "authority": {
            "profile": profile,
            "required": required,
            "granted": grants,
            "missing": missing,
            "remote_credentials_used": False,
            "human_confirmation": "not-required",
        },
        "context": {
            "content_recording": "metadata-only",
            "sources": [
                {
                    "kind": "capability-contract",
                    "id": safe_rel(cap_path),
                    "digest": sha256_file(cap_path),
                    "bytes": cap_path.stat().st_size,
                },
                {
                    "kind": "source-receipt",
                    "id": safe_rel(source_path),
                    "digest": sha256_file(source_path),
                    "bytes": source_path.stat().st_size,
                },
            ],
            "token_volume": {"status": "not-applicable", "input_tokens": None, "output_tokens": None},
        },
        "tools": [
            {
                "id": "scripts/arsenal_substrate.py",
                "role": "proof-gate-selector",
                "version": None,
                "result": f"SELECTED:{selected_id}@rank{selected_rank}",
                "evidence_ids": [evidence_id],
            },
            {
                "id": runtime_id,
                "role": "executable-world-adapter",
                "version": runtime_version,
                "result": "PASS",
                "evidence_ids": [evidence_id],
            },
        ],
        "evidence": [evidence_item(evidence_id, "executable-world-receipt", source_path, claim, limitations)],
        "timeline": [
            {"sequence": 1, "event_name": "arsenal.capability.verification.started", "category": "start", "status": "STARTED", "evidence_ids": []},
            {"sequence": 2, "event_name": "arsenal.reality_budget.selected", "category": "decision", "status": f"{selected_id}@rank{selected_rank}", "evidence_ids": [evidence_id]},
            {"sequence": 3, "event_name": "arsenal.executable_world.completed", "category": "execution", "status": "PASS", "evidence_ids": [evidence_id]},
            {"sequence": 4, "event_name": "arsenal.evidence.accepted", "category": "evidence", "status": "ACCEPTED", "evidence_ids": [evidence_id]},
            {"sequence": 5, "event_name": "arsenal.run.outcome", "category": "outcome", "status": "PASS", "evidence_ids": [evidence_id]},
        ],
        "outcome": {
            "verdict": "PASS",
            "claim": claim,
            "accepted_evidence_ids": [evidence_id],
            "limitations": limitations,
        },
        "privacy": privacy_block(),
        "telemetry_mapping": telemetry_block(),
    }
    return apply_fingerprint(record)


def bench_record(source_path: Path, instance_id: str, repository_sha: str) -> dict[str, Any]:
    source = read_json(source_path)
    suite_id = source.get("suite_id")
    cap_id = source.get("capability_id")
    verdict = source.get("verdict")
    if not isinstance(suite_id, str) or not isinstance(cap_id, str) or verdict not in {"PASS", "FAIL"}:
        raise ObserveError("Bench source receipt identity/verdict invalid")
    passport = source.get("capability_passport", {})
    cap_version = passport.get("capability_version")
    if not isinstance(cap_version, str):
        raise ObserveError("Bench receipt lacks capability version")
    canonical_cap, cap_path = load_capability(cap_id)
    if canonical_cap.get("version") != cap_version:
        raise ObserveError("Bench receipt capability version does not match canonical capability")

    provenance = source.get("execution_provenance", {})
    model_value = provenance.get("model")
    harness_value = provenance.get("harness")
    model_identity = identity("not-applicable") if model_value == "not-applicable" else identity("observed", str(model_value), None)
    harness_identity = identity("observed", str(harness_value), None) if harness_value else identity("not-observed")
    claim = source.get("claim_scope")
    limitations = source.get("limitations")
    if not isinstance(claim, str) or not isinstance(limitations, list) or not all(isinstance(x, str) for x in limitations):
        raise ObserveError("Bench receipt claim boundary invalid")
    remote = provenance.get("remote_credentials_used")
    if not isinstance(remote, bool):
        raise ObserveError("Bench receipt must report remote_credentials_used")

    evidence_id = "evidence.bench-receipt"
    record = {
        "schema_version": SCHEMA_VERSION,
        "record_kind": RECORD_KIND,
        "run": {
            "instance_id": instance_id,
            "fingerprint": "sha256:" + "0" * 64,
            "kind": "evaluation",
            "status": verdict,
        },
        "subject": {
            "capabilities": [{"id": cap_id, "version": cap_version}],
            "route_id": None,
            "suite_id": suite_id,
        },
        "provenance": {
            "repository_sha": repository_sha,
            "model": model_identity,
            "harness": harness_identity,
            "adapter": identity("observed", str(provenance.get("runner", "scripts/arsenal_bench.py")), None),
        },
        "authority": {
            "profile": None,
            "required": sorted(set(canonical_cap.get("authority", {}).get("required", []))),
            "granted": [],
            "missing": [],
            "remote_credentials_used": remote,
            "human_confirmation": "not-required",
        },
        "context": {
            "content_recording": "metadata-only",
            "sources": [
                {
                    "kind": "capability-contract",
                    "id": safe_rel(cap_path),
                    "digest": sha256_file(cap_path),
                    "bytes": cap_path.stat().st_size,
                },
                {
                    "kind": "source-receipt",
                    "id": safe_rel(source_path),
                    "digest": sha256_file(source_path),
                    "bytes": source_path.stat().st_size,
                },
            ],
            "token_volume": {"status": "not-applicable" if model_value == "not-applicable" else "not-observed", "input_tokens": None, "output_tokens": None},
        },
        "tools": [
            {
                "id": str(provenance.get("runner", "scripts/arsenal_bench.py")),
                "role": "evaluation-runner",
                "version": None,
                "result": verdict,
                "evidence_ids": [evidence_id],
            }
        ],
        "evidence": [evidence_item(evidence_id, "evaluation-receipt", source_path, claim, limitations)],
        "timeline": [
            {"sequence": 1, "event_name": "arsenal.evaluation.started", "category": "start", "status": "STARTED", "evidence_ids": []},
            {"sequence": 2, "event_name": "arsenal.evaluation.completed", "category": "evaluation", "status": verdict, "evidence_ids": [evidence_id]},
            {"sequence": 3, "event_name": "arsenal.evidence.accepted", "category": "evidence", "status": "ACCEPTED" if verdict == "PASS" else "REJECTED", "evidence_ids": [evidence_id]},
            {"sequence": 4, "event_name": "arsenal.run.outcome", "category": "outcome", "status": verdict, "evidence_ids": [evidence_id]},
        ],
        "outcome": {
            "verdict": verdict,
            "claim": claim,
            "accepted_evidence_ids": [evidence_id],
            "limitations": limitations,
        },
        "privacy": privacy_block(),
        "telemetry_mapping": telemetry_block(),
    }
    return apply_fingerprint(record)


def forbidden_keys() -> set[str]:
    policy = read_json(POLICY_PATH)
    values = policy.get("record", {}).get("forbidden_fields", [])
    if not isinstance(values, list) or not all(isinstance(x, str) for x in values):
        raise ObserveError("invalid observability redaction policy")
    return set(values)


def walk_keys(value: Any, prefix: str = "") -> list[str]:
    found: list[str] = []
    if isinstance(value, dict):
        for key, child in value.items():
            found.append(key)
            found.extend(walk_keys(child, f"{prefix}.{key}" if prefix else key))
    elif isinstance(value, list):
        for child in value:
            found.extend(walk_keys(child, prefix))
    return found


def validate_identity(label: str, value: Any) -> None:
    if not isinstance(value, dict) or set(value) != {"status", "id", "version"}:
        raise ObserveError(f"{label} runtime identity shape invalid")
    status = value["status"]
    if status not in IDENTITY_STATUSES:
        raise ObserveError(f"{label} runtime identity status invalid")
    if status == "observed" and not isinstance(value["id"], str):
        raise ObserveError(f"{label} observed identity requires id")
    if status == "not-applicable" and (value["id"] is not None or value["version"] is not None):
        raise ObserveError(f"{label} not-applicable identity cannot carry id/version")


def validate_record(record: dict[str, Any], *, verify_sources: bool = True) -> None:
    if set(record) != TOP_LEVEL:
        raise ObserveError(f"flight record top-level fields invalid: {sorted(set(record) ^ TOP_LEVEL)}")
    if record["schema_version"] != SCHEMA_VERSION or record["record_kind"] != RECORD_KIND:
        raise ObserveError("flight record schema/kind invalid")

    run = record["run"]
    if not isinstance(run, dict) or set(run) != {"instance_id", "fingerprint", "kind", "status"}:
        raise ObserveError("run block invalid")
    if not isinstance(run["instance_id"], str) or not run["instance_id"]:
        raise ObserveError("run instance_id required")
    if run["kind"] not in VALID_RUN_KINDS or run["status"] not in VALID_VERDICTS:
        raise ObserveError("run kind/status invalid")
    if not isinstance(run["fingerprint"], str) or not SHA_RE.fullmatch(run["fingerprint"]):
        raise ObserveError("run fingerprint invalid")
    expected_fp = sha256_bytes(canonical_bytes(stable_payload(record)))
    if run["fingerprint"] != expected_fp:
        raise ObserveError("run fingerprint does not match stable flight-record content")

    subject = record["subject"]
    if not isinstance(subject, dict) or set(subject) != {"capabilities", "route_id", "suite_id"}:
        raise ObserveError("subject block invalid")
    if not isinstance(subject["capabilities"], list):
        raise ObserveError("subject capabilities invalid")
    for cap in subject["capabilities"]:
        if not isinstance(cap, dict) or set(cap) != {"id", "version"} or not isinstance(cap["id"], str) or not cap["id"].startswith("capability."):
            raise ObserveError("subject capability identity invalid")

    provenance = record["provenance"]
    if not isinstance(provenance, dict) or set(provenance) != {"repository_sha", "model", "harness", "adapter"}:
        raise ObserveError("provenance block invalid")
    if not isinstance(provenance["repository_sha"], str) or not provenance["repository_sha"]:
        raise ObserveError("repository_sha required")
    for label in ("model", "harness", "adapter"):
        validate_identity(label, provenance[label])

    authority = record["authority"]
    expected_authority = {"profile", "required", "granted", "missing", "remote_credentials_used", "human_confirmation"}
    if not isinstance(authority, dict) or set(authority) != expected_authority:
        raise ObserveError("authority block invalid")
    for key in ("required", "granted", "missing"):
        if not isinstance(authority[key], list) or not all(isinstance(x, str) for x in authority[key]) or len(authority[key]) != len(set(authority[key])):
            raise ObserveError(f"authority {key} invalid")
    if not isinstance(authority["remote_credentials_used"], bool):
        raise ObserveError("remote_credentials_used must be boolean")

    context = record["context"]
    if not isinstance(context, dict) or set(context) != {"content_recording", "sources", "token_volume"} or context["content_recording"] != "metadata-only":
        raise ObserveError("context block invalid")
    if not isinstance(context["sources"], list):
        raise ObserveError("context sources invalid")
    for item in context["sources"]:
        if not isinstance(item, dict) or set(item) != {"kind", "id", "digest", "bytes"}:
            raise ObserveError("context source shape invalid")
        if item["digest"] is not None and (not isinstance(item["digest"], str) or not SHA_RE.fullmatch(item["digest"])):
            raise ObserveError("context source digest invalid")
    tokens = context["token_volume"]
    if not isinstance(tokens, dict) or set(tokens) != {"status", "input_tokens", "output_tokens"} or tokens["status"] not in IDENTITY_STATUSES:
        raise ObserveError("token volume block invalid")

    evidence = record["evidence"]
    if not isinstance(evidence, list) or not evidence:
        raise ObserveError("at least one evidence item is required")
    evidence_ids: set[str] = set()
    accepted: set[str] = set()
    for item in evidence:
        required_keys = {"id", "kind", "source", "sha256", "accepted", "claim_scope", "limitations"}
        if not isinstance(item, dict) or set(item) != required_keys:
            raise ObserveError("evidence item shape invalid")
        if item["id"] in evidence_ids:
            raise ObserveError(f"duplicate evidence id: {item['id']}")
        evidence_ids.add(item["id"])
        if not isinstance(item["sha256"], str) or not SHA_RE.fullmatch(item["sha256"]):
            raise ObserveError("evidence sha256 invalid")
        if not isinstance(item["accepted"], bool):
            raise ObserveError("evidence accepted must be boolean")
        if item["accepted"]:
            accepted.add(item["id"])
        if verify_sources:
            source_path = (ROOT / item["source"]).resolve()
            try:
                source_path.relative_to(ROOT)
            except ValueError as exc:
                raise ObserveError("evidence source escapes repository") from exc
            if not source_path.is_file():
                raise ObserveError(f"evidence source missing: {item['source']}")
            if sha256_file(source_path) != item["sha256"]:
                raise ObserveError(f"evidence source digest mismatch: {item['source']}")

    tools = record["tools"]
    if not isinstance(tools, list):
        raise ObserveError("tools must be a list")
    for tool in tools:
        if not isinstance(tool, dict) or set(tool) != {"id", "role", "version", "result", "evidence_ids"}:
            raise ObserveError("tool item shape invalid")
        if any(eid not in evidence_ids for eid in tool["evidence_ids"]):
            raise ObserveError("tool references unknown evidence")

    timeline = record["timeline"]
    if not isinstance(timeline, list) or not timeline:
        raise ObserveError("timeline required")
    for index, event in enumerate(timeline, 1):
        if not isinstance(event, dict) or set(event) != {"sequence", "event_name", "category", "status", "evidence_ids"}:
            raise ObserveError("timeline event shape invalid")
        if event["sequence"] != index:
            raise ObserveError("timeline sequence must be contiguous from 1")
        if not isinstance(event["event_name"], str) or not event["event_name"].startswith("arsenal."):
            raise ObserveError("timeline event name invalid")
        if any(eid not in evidence_ids for eid in event["evidence_ids"]):
            raise ObserveError("timeline references unknown evidence")

    outcome = record["outcome"]
    if not isinstance(outcome, dict) or set(outcome) != {"verdict", "claim", "accepted_evidence_ids", "limitations"}:
        raise ObserveError("outcome block invalid")
    if outcome["verdict"] not in VALID_VERDICTS or outcome["verdict"] != run["status"]:
        raise ObserveError("outcome verdict mismatch")
    if not isinstance(outcome["accepted_evidence_ids"], list) or not outcome["accepted_evidence_ids"]:
        raise ObserveError("outcome must bind to accepted evidence")
    if any(eid not in accepted for eid in outcome["accepted_evidence_ids"]):
        raise ObserveError("outcome references evidence that is absent or not accepted")

    if record["privacy"] != privacy_block():
        raise ObserveError("privacy block must match metadata-first content-off policy")
    if record["telemetry_mapping"] != telemetry_block():
        raise ObserveError("telemetry mapping block invalid")

    forbidden = forbidden_keys()
    keys = walk_keys(record)
    hits = sorted(set(keys) & forbidden)
    if hits:
        raise ObserveError(f"flight record contains forbidden content fields: {hits}")
    if any(key.startswith("otel.") for key in keys):
        raise ObserveError("Arsenal records may not use the reserved otel.* attribute namespace")


def write_record(record: dict[str, Any], output: Path) -> None:
    validate_record(record)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(canonical_bytes(record))


def command_record_dagger(args: argparse.Namespace) -> int:
    source = args.source.resolve()
    record = dagger_record(source, args.instance_id, args.repository_sha)
    write_record(record, args.output.resolve())
    print(f"ARS-07 Flight Recorder: PASS dagger -> {safe_rel(args.output.resolve())}")
    print(f"fingerprint: {record['run']['fingerprint']}")
    return 0


def command_record_bench(args: argparse.Namespace) -> int:
    source = args.source.resolve()
    record = bench_record(source, args.instance_id, args.repository_sha)
    write_record(record, args.output.resolve())
    print(f"ARS-07 Flight Recorder: PASS bench -> {safe_rel(args.output.resolve())}")
    print(f"fingerprint: {record['run']['fingerprint']}")
    return 0


def command_verify(args: argparse.Namespace) -> int:
    record = read_json(args.record.resolve())
    validate_record(record)
    print(f"ARS-07 flight-record verification: PASS ({safe_rel(args.record.resolve())})")
    return 0


def command_compare(args: argparse.Namespace) -> int:
    left = read_json(args.left.resolve())
    right = read_json(args.right.resolve())
    validate_record(left, verify_sources=False)
    validate_record(right, verify_sources=False)
    same = left["run"]["fingerprint"] == right["run"]["fingerprint"]
    print("ARS-07 flight-record comparison")
    print(f"left:  {left['run']['fingerprint']}")
    print(f"right: {right['run']['fingerprint']}")
    print(f"equivalent stable execution/evidence: {'YES' if same else 'NO'}")
    return 0 if same else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    for name in ("record-dagger", "record-bench"):
        item = sub.add_parser(name)
        item.add_argument("--source", type=Path, required=True)
        item.add_argument("--output", type=Path, required=True)
        item.add_argument("--instance-id", required=True)
        item.add_argument("--repository-sha", default=os.environ.get("GITHUB_SHA", "unknown"))

    verify = sub.add_parser("verify")
    verify.add_argument("--record", type=Path, required=True)

    compare = sub.add_parser("compare")
    compare.add_argument("--left", type=Path, required=True)
    compare.add_argument("--right", type=Path, required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(sys.argv[1:] if argv is None else argv)
    try:
        return {
            "record-dagger": command_record_dagger,
            "record-bench": command_record_bench,
            "verify": command_verify,
            "compare": command_compare,
        }[args.command](args)
    except (ObserveError, OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as exc:
        print(f"ARS-07 ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
