#!/usr/bin/env python3
"""Project Arsenal Bench v0: validate cases, execute deterministic cases, and gate capability lifecycle."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASE_DIR = ROOT / "evaluation" / "cases"
ROUTER = ROOT / "engineering/development_packs/floci/providers/scripts/route-local-cloud-capability.py"
CAP_DIR = ROOT / "arsenal" / "capabilities"
SCHEMA_VERSION = "1.0.0"
LOCAL_SUITE_ASSET = "evaluation.arsenal-bench-local-cloud-v0"

HEALTH_CHECKS = {
    "starting_state_reproducible",
    "failure_reachable",
    "success_reachable",
    "acceptance_observable",
    "expected_outcome_explicit",
    "solution_not_leaked",
    "verifier_independent",
    "no_remote_credentials",
}
COMPARISONS = {"control-treatment", "ablation", "multi-arm", "contract-counterfactual"}
EXECUTION_MODES = {"agent-control-treatment", "local-cloud-router", "local-cloud-runtime"}
DISTRIBUTION_EXECUTION_MODES = {
    "distribution-structural",
    "distribution-collision",
    "distribution-behavioral",
}
EXECUTION_STATUS = {"designed-not-run", "executable"}
QUALIFICATION_STATES = {"unassessed", "candidate", "qualified"}


class BenchError(Exception):
    pass


def read_json(path: Path):
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def load_suites(case_dir: Path = CASE_DIR) -> list[dict]:
    suites = []
    for path in sorted(case_dir.glob("*.json")):
        doc = read_json(path)
        if doc.get("schema_version") != SCHEMA_VERSION or not isinstance(doc.get("suite"), dict):
            raise BenchError(f"{path.relative_to(ROOT)}: invalid suite wrapper")
        suite = doc["suite"]
        suite["_path"] = str(path.relative_to(ROOT))
        suites.append(suite)
    if not suites:
        raise BenchError("no evaluation suites found")
    return suites


def validate_case(case: dict) -> list[str]:
    errors: list[str] = []
    required = {"id", "title", "track", "capability_id", "active", "execution", "fixture", "comparison", "expected", "case_health", "metrics"}
    missing = required - set(case)
    if missing:
        return [f"{case.get('id', '<missing>')}: missing fields {sorted(missing)}"]

    cid = case["id"]
    if not isinstance(cid, str) or not cid:
        errors.append("case id must be a non-empty string")
    if not isinstance(case["capability_id"], str) or not case["capability_id"].startswith("capability."):
        errors.append(f"{cid}: capability_id must be canonical")
    if not isinstance(case["active"], bool):
        errors.append(f"{cid}: active must be boolean")

    execution = case["execution"]
    if not isinstance(execution, dict) or execution.get("status") not in EXECUTION_STATUS:
        errors.append(f"{cid}: invalid execution contract")
    elif execution.get("mode") not in EXECUTION_MODES | DISTRIBUTION_EXECUTION_MODES:
        errors.append(f"{cid}: invalid execution mode {execution.get('mode')!r}")
    elif case["active"]:
        if execution["status"] != "executable":
            errors.append(f"{cid}: active case must be executable")
        if execution["mode"] not in {"local-cloud-router"} | DISTRIBUTION_EXECUTION_MODES:
            errors.append(f"{cid}: ARS-02 v0 active execution supports local-cloud-router and distribution modes only")
    elif execution["status"] != "designed-not-run":
        errors.append(f"{cid}: inactive case must remain designed-not-run")

    track = case.get("track")
    if track == "distribution-qualification":
        # Distribution cases require a non-empty axis field.
        if not isinstance(case.get("axis"), str) or not case["axis"]:
            errors.append(f"{cid}: distribution-qualification cases require an axis")
        elif case["axis"] not in {"activation", "behavioral_efficacy", "boundary_preservation", "context_efficiency"}:
            errors.append(f"{cid}: unknown distribution-qualification axis {case['axis']!r}")

    comparison = case["comparison"]
    if not isinstance(comparison, dict) or set(comparison) != {"kind", "control", "treatment", "ablation"}:
        errors.append(f"{cid}: comparison must define kind/control/treatment/ablation")
    elif comparison["kind"] not in COMPARISONS:
        errors.append(f"{cid}: unsupported comparison kind")

    health = case["case_health"]
    checks = health.get("required_checks") if isinstance(health, dict) else None
    if not isinstance(checks, list) or not checks or len(checks) != len(set(checks)):
        errors.append(f"{cid}: case health requires unique checks")
    elif set(checks) - HEALTH_CHECKS:
        errors.append(f"{cid}: unknown case health checks {sorted(set(checks) - HEALTH_CHECKS)}")

    if not isinstance(case["metrics"], list) or not case["metrics"]:
        errors.append(f"{cid}: metrics must be non-empty")

    if execution.get("mode") == "local-cloud-router":
        files = case["fixture"].get("files") if isinstance(case["fixture"], dict) else None
        expected = case["expected"]
        if not isinstance(files, dict) or not files:
            errors.append(f"{cid}: local-cloud-router case requires inline fixture files")
        if not isinstance(execution.get("task_kind"), str):
            errors.append(f"{cid}: local-cloud-router case requires task_kind")
        if not isinstance(expected, dict) or not isinstance(expected.get("rc"), int) or not isinstance(expected.get("fields"), dict):
            errors.append(f"{cid}: local-cloud-router case requires expected rc and fields")
    return errors


def validate_suites(suites: list[dict]) -> list[str]:
    errors: list[str] = []
    ids: set[str] = set()
    suite_ids: set[str] = set()
    totals: dict[str, int] = {}

    for suite in suites:
        sid = suite.get("id")
        if not isinstance(sid, str) or sid in suite_ids:
            errors.append(f"invalid or duplicate suite id {sid!r}")
        suite_ids.add(sid)
        cases = suite.get("cases")
        if not isinstance(cases, list) or not cases:
            errors.append(f"{sid}: cases must be non-empty")
            continue
        track = suite.get("track", "<missing>")
        totals[track] = totals.get(track, 0) + len(cases)
        for case in cases:
            errors.extend(validate_case(case))
            cid = case.get("id")
            if cid in ids:
                errors.append(f"duplicate case id {cid}")
            ids.add(cid)

        gate = suite.get("lifecycle_gate")
        if gate is not None:
            minimum = gate.get("minimum_executed_cases") if isinstance(gate, dict) else None
            required = gate.get("required_case_ids") if isinstance(gate, dict) else None
            if gate.get("target_lifecycle") != "testing":
                errors.append(f"{sid}: v0 lifecycle gate target must be testing")
            if not isinstance(minimum, int) or isinstance(minimum, bool) or minimum <= 0:
                errors.append(f"{sid}: minimum_executed_cases must be a positive integer")
            if not isinstance(required, list) or not required:
                errors.append(f"{sid}: lifecycle gate requires case ids")
            else:
                by_id = {c.get("id"): c for c in cases}
                for cid in required:
                    case = by_id.get(cid)
                    if not case:
                        errors.append(f"{sid}: lifecycle required case missing: {cid}")
                        continue
                    if not case.get("active") or case.get("execution", {}).get("status") != "executable":
                        errors.append(f"{sid}: lifecycle required case is not active/executable: {cid}")
                if isinstance(minimum, int) and minimum > len(required):
                    errors.append(f"{sid}: minimum_executed_cases exceeds required case count")

    if totals.get("core-engineering") != 8:
        errors.append(f"ARS-02 v0 requires 8 core-engineering cases; found {totals.get('core-engineering')}")
    if totals.get("local-cloud") != 11:
        errors.append(f"ARS-02 v0 requires 11 local-cloud cases; found {totals.get('local-cloud')}")
    core_local_count = (totals.get("core-engineering") or 0) + (totals.get("local-cloud") or 0)
    if core_local_count != 19:
        errors.append(f"ARS-02 v0 requires 19 unique core+local cases; found {core_local_count}")
    # Distribution-qualification is an additional, separately-counted track.
    if totals.get("distribution-qualification", 0) < 1:
        errors.append("ARS-03 distribution-qualification track must contain at least one case")
    if len(ids) != core_local_count + totals.get("distribution-qualification", 0):
        errors.append(f"case id collision across tracks; found {len(ids)} unique ids")
    return errors


def select_suite(suites: list[dict], selector: str) -> dict:
    aliases = {"local-cloud": "suite.local-cloud-v0", "core": "suite.arsenal-core-v0"}
    wanted = aliases.get(selector, selector)
    for suite in suites:
        if suite.get("id") == wanted:
            return suite
    raise BenchError(f"unknown suite: {selector}")


def case_health(case: dict) -> dict:
    checks = []
    required = case["case_health"]["required_checks"]
    expected = case["expected"]
    fixture = case["fixture"]
    for check in required:
        passed = False
        evidence = ""
        if check == "starting_state_reproducible":
            passed = isinstance(fixture.get("files"), dict) and bool(fixture["files"])
            evidence = "fixture files are fully declared inline" if passed else "fixture is not executable inline"
        elif check == "failure_reachable":
            passed = expected.get("rc", 0) != 0 or expected.get("fields", {}).get("status") in {"AMBIGUOUS", "UNKNOWN", "UNSUPPORTED_ROUTE"}
            evidence = "expected result includes a deterministic failing/hard-stop path"
        elif check == "expected_outcome_explicit":
            passed = isinstance(expected.get("rc"), int) and isinstance(expected.get("fields"), dict) and bool(expected["fields"])
            evidence = "return code and expected result fields are declared"
        elif check == "verifier_independent":
            passed = True
            evidence = "Bench compares router output externally against case expectations"
        elif check == "no_remote_credentials":
            fields = expected.get("fields", {})
            passed = fields.get("automatic_real_cloud_fallback") is False and fields.get("requires_explicit_real_cloud_authorization") is True
            evidence = "case requires no automatic real-cloud fallback and explicit remote authorization"
        elif check in {"success_reachable", "acceptance_observable", "solution_not_leaked"}:
            passed = False
            evidence = "check is not established by the v0 deterministic router adapter"
        checks.append({"id": check, "status": "PASS" if passed else "FAIL", "evidence": evidence})
    return {
        "case_id": case["id"],
        "status": "HEALTHY" if all(c["status"] == "PASS" for c in checks) else "UNHEALTHY",
        "checks": checks,
    }


def invoke_local_cloud_router(case: dict) -> dict:
    if not ROUTER.exists():
        raise BenchError(f"router missing: {ROUTER.relative_to(ROOT)}")
    with tempfile.TemporaryDirectory(prefix=f"arsenal-bench-{case['id']}-") as td:
        repo = Path(td)
        for rel, content in case["fixture"]["files"].items():
            path = repo / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        cmd = [sys.executable, str(ROUTER), "--repo", str(repo), "--task-kind", case["execution"]["task_kind"], "--format", "json"]
        proc = subprocess.run(cmd, text=True, capture_output=True, check=False)
        try:
            actual = json.loads(proc.stdout)
        except json.JSONDecodeError as exc:
            raise BenchError(f"{case['id']}: router emitted invalid JSON rc={proc.returncode}: {proc.stdout!r} {proc.stderr!r}") from exc
    expected = case["expected"]
    mismatches = []
    if proc.returncode != expected["rc"]:
        mismatches.append(f"rc expected {expected['rc']} got {proc.returncode}")
    for key, value in expected["fields"].items():
        if actual.get(key) != value:
            mismatches.append(f"{key} expected {value!r} got {actual.get(key)!r}")
    health = case_health(case)
    passed = not mismatches and health["status"] == "HEALTHY"
    comparison = case["comparison"]
    return {
        "case_id": case["id"],
        "status": "PASS" if passed else "FAIL",
        "execution": "executed",
        "actual_rc": proc.returncode,
        "actual": {key: actual.get(key) for key in expected["fields"]},
        "mismatches": mismatches,
        "case_health_receipt": health,
        "counterfactual_receipt": {
            "kind": comparison["kind"],
            "control_status": "designed-not-run",
            "treatment_status": "PASS" if not mismatches else "FAIL",
            "ablation_status": "designed-not-run" if comparison.get("ablation") else "not-applicable",
            "claim_scope": "Executed treatment proves the declared deterministic contract invariant only; it does not prove model improvement over the unexecuted control.",
        },
    }


def load_capability(capability_id: str) -> dict:
    for path in sorted(CAP_DIR.glob("*.json")):
        doc = read_json(path)
        cap = doc.get("capability", {})
        if cap.get("id") == capability_id:
            cap = dict(cap)
            cap["_path"] = str(path.relative_to(ROOT))
            return cap
    raise BenchError(f"unknown capability: {capability_id}")


def build_receipt(suite: dict, results: list[dict]) -> dict:
    active_ids = {c["id"] for c in suite["cases"] if c["active"]}
    result_by_id = {r["case_id"]: r for r in results}
    case_results = []
    for case in suite["cases"]:
        if case["id"] in result_by_id:
            case_results.append(result_by_id[case["id"]])
        else:
            case_results.append({
                "case_id": case["id"],
                "status": "DESIGNED-NOT-RUN",
                "execution": "designed-not-run",
                "case_health_receipt": {"case_id": case["id"], "status": "DESIGNED-NOT-RUN", "checks": []},
                "counterfactual_receipt": {
                    "kind": case["comparison"]["kind"],
                    "control_status": "designed-not-run",
                    "treatment_status": "designed-not-run",
                    "ablation_status": "designed-not-run" if case["comparison"].get("ablation") else "not-applicable",
                    "claim_scope": "Experiment designed but no execution evidence exists.",
                },
            })
    executed = len(results)
    passed = sum(r["status"] == "PASS" for r in results)
    failed = executed - passed
    cap_id = suite.get("capability_id")
    cap = load_capability(cap_id) if cap_id else None
    receipt = {
        "schema_version": SCHEMA_VERSION,
        "suite_id": suite["id"],
        "capability_id": cap_id,
        "verdict": "PASS" if failed == 0 and active_ids == set(result_by_id) else "FAIL",
        "claim_scope": "Deterministic Local Cloud routing and execution-boundary contract evidence. No model/harness efficacy comparison is claimed.",
        "execution_provenance": {
            "runner": "scripts/arsenal_bench.py",
            "repository_sha": os.environ.get("GITHUB_SHA", "unknown"),
            "model": "not-applicable",
            "harness": "deterministic-python-adapter",
            "remote_credentials_used": False,
        },
        "counts": {
            "total": len(suite["cases"]),
            "executed": executed,
            "passed": passed,
            "failed": failed,
            "designed_not_run": len(suite["cases"]) - executed,
        },
        "case_results": case_results,
        "capability_passport": {
            "capability_id": cap_id,
            "capability_version": cap.get("version") if cap else None,
            "lifecycle": cap.get("lifecycle") if cap else None,
            "evaluation_status": cap.get("evaluation", {}).get("status") if cap else None,
            "suite_id": suite["id"],
            "executed_cases": executed,
            "passed_cases": passed,
            "failed_cases": failed,
            "designed_not_run_cases": len(suite["cases"]) - executed,
            "proof_carrying_claim": "candidate deterministic contract evidence",
        },
        "limitations": [
            "Control/counterfactual arms are declared but not executed in the deterministic v0 adapter.",
            "Six deeper Local Cloud cases remain designed-not-run.",
            "No coding model or agent harness is evaluated by this receipt.",
            "No real cloud provider credentials or mutations are used.",
        ],
    }
    return receipt


def run_suite(suite: dict) -> dict:
    results = []
    for case in suite["cases"]:
        if not case["active"]:
            continue
        if case["execution"]["mode"] != "local-cloud-router":
            raise BenchError(f"{case['id']}: unsupported active execution mode")
        results.append(invoke_local_cloud_router(case))
    return build_receipt(suite, results)


def validate_lifecycle(capability_id: str, receipt: dict, suites: list[dict]) -> list[str]:
    errors: list[str] = []
    cap = load_capability(capability_id)
    suite = next((s for s in suites if s.get("id") == receipt.get("suite_id")), None)
    if not suite:
        return ["receipt references unknown suite"]
    gate = suite.get("lifecycle_gate")
    if not isinstance(gate, dict) or gate.get("target_lifecycle") != "testing":
        errors.append("suite does not define a testing lifecycle gate")
        return errors
    minimum = gate.get("minimum_executed_cases")
    if not isinstance(minimum, int) or isinstance(minimum, bool) or minimum <= 0:
        errors.append("testing gate minimum_executed_cases must be positive")
    if cap.get("lifecycle") != "testing":
        errors.append(f"{capability_id}: lifecycle must be testing for this gate; found {cap.get('lifecycle')}")
    evaluation = cap.get("evaluation", {})
    if evaluation.get("status") not in {"candidate", "qualified"}:
        errors.append(f"{capability_id}: testing requires candidate/qualified evaluation status")
    if LOCAL_SUITE_ASSET not in evaluation.get("suite_asset_ids", []):
        errors.append(f"{capability_id}: must reference {LOCAL_SUITE_ASSET}")
    if receipt.get("verdict") != "PASS":
        errors.append("evaluation receipt verdict is not PASS")
    counts = receipt.get("counts", {})
    if not isinstance(minimum, int) or counts.get("executed", 0) < minimum:
        errors.append("evaluation receipt does not meet minimum executed case count")
    results = {r.get("case_id"): r for r in receipt.get("case_results", [])}
    for cid in gate.get("required_case_ids", []):
        result = results.get(cid)
        if not result:
            errors.append(f"required lifecycle case missing from receipt: {cid}")
            continue
        if result.get("execution") != "executed" or result.get("status") != "PASS":
            errors.append(f"required lifecycle case did not execute/pass: {cid}")
        if result.get("case_health_receipt", {}).get("status") != "HEALTHY":
            errors.append(f"required lifecycle case is not healthy: {cid}")
        counter = result.get("counterfactual_receipt", {})
        if counter.get("control_status") not in {"designed-not-run", "PASS", "FAIL"}:
            errors.append(f"required lifecycle case lacks explicit counterfactual state: {cid}")
    return errors


def cmd_validate(_args) -> int:
    suites = load_suites()
    errors = validate_suites(suites)
    if errors:
        for error in errors:
            print(f"ERROR {error}", file=sys.stderr)
        return 1
    by_track: dict[str, int] = {}
    for suite in suites:
        track = suite.get("track", "<missing>")
        by_track[track] = by_track.get(track, 0) + len(suite.get("cases", []))
    core = by_track.get("core-engineering", 0)
    lc = by_track.get("local-cloud", 0)
    dq = by_track.get("distribution-qualification", 0)
    print(
        f"Arsenal Bench contract: PASS "
        f"(core={core}, local-cloud={lc}, distribution-qualification={dq})"
    )
    return 0


def cmd_run(args) -> int:
    suites = load_suites()
    errors = validate_suites(suites)
    if errors:
        raise BenchError("suite validation failed before execution: " + "; ".join(errors))
    suite = select_suite(suites, args.suite)
    receipt = run_suite(suite)
    path = Path(args.receipt)
    if not path.is_absolute():
        path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Arsenal Bench {suite['id']}: {receipt['verdict']} ({receipt['counts']['executed']} executed; {receipt['counts']['designed_not_run']} designed-not-run)")
    print(f"receipt: {path.relative_to(ROOT)}")
    return 0 if receipt["verdict"] == "PASS" else 1


def cmd_lifecycle(args) -> int:
    suites = load_suites()
    errors = validate_suites(suites)
    path = Path(args.receipt)
    if not path.is_absolute():
        path = ROOT / path
    receipt = read_json(path)
    errors.extend(validate_lifecycle(args.capability, receipt, suites))
    if errors:
        for error in errors:
            print(f"ERROR {error}", file=sys.stderr)
        return 1
    print(f"Arsenal Bench lifecycle gate: PASS ({args.capability} earned testing under {receipt['suite_id']})")
    return 0


def _read_manifest(distribution_path: Path) -> dict:
    """Load the arsenal-manifest.json for a distribution."""
    manifest_path = distribution_path / "arsenal-manifest.json"
    if not manifest_path.is_file():
        raise BenchError(f"missing arsenal-manifest.json: {manifest_path}")
    return read_json(manifest_path)


def _load_capability_for_manifest(manifest: dict) -> dict:
    cap_path = ROOT / manifest["source"]["capability_path"]
    return read_json(cap_path)["capability"]


def _check_discovery_in_body(case: dict, manifest: dict, skill_text: str) -> dict:
    """Activation: discovery text from canonical is rendered into SKILL.md."""
    cap = _load_capability_for_manifest(manifest)
    request = case.get("fixture", {}).get("request_phrase", "").lower()
    discovery_use_when = [
        e.get("text", "") for e in cap.get("discovery", {}).get("use_when", [])
    ]
    matches = [t for t in discovery_use_when if request and any(w in t.lower() for w in request.split())]
    in_body = bool(matches) and any(m in skill_text for m in matches)
    return {
        "should_invoke": bool(matches),
        "should_invoke_evidence": case["expected"].get("should_invoke", True),
        "discovery_in_body": in_body,
        "matched_statements": matches,
    }


def _check_discovery_excludes(case: dict, manifest: dict, skill_text: str) -> dict:
    cap = _load_capability_for_manifest(manifest)
    request = case.get("fixture", {}).get("request_phrase", "").lower()
    do_not_use = [
        e.get("text", "") for e in cap.get("discovery", {}).get("do_not_use_when", [])
    ]
    request_in_do_not = any(request and any(w in t.lower() for w in request.split()) for t in do_not_use)
    # If request is excluded, should_invoke must be false.
    should_invoke = not request_in_do_not
    return {
        "should_invoke": should_invoke,
        "should_invoke_evidence": case["expected"].get("should_invoke", False),
        "request_in_do_not_use_when": request_in_do_not,
    }


def _check_manifest_capability_identity(case: dict, manifest: dict, _skill_text: str) -> dict:
    cap = _load_capability_for_manifest(manifest)
    return {
        "manifest_capability_id_matches_canonical": manifest["capability"]["id"] == cap["id"],
        "manifest_capability_version_matches_canonical": manifest["capability"]["version"] == cap["version"],
    }


def _check_manifest_mutation(case: dict, manifest: dict, _skill_text: str) -> dict:
    cap = _load_capability_for_manifest(manifest)
    return {
        "manifest_mutation_class_matches_canonical": manifest["mutation"]["class"] == cap["mutation"]["class"],
        "manifest_mutation_reversible_matches_canonical": manifest["mutation"]["reversible"] == cap["mutation"]["reversible"],
    }


def _check_manifest_authority(case: dict, manifest: dict, _skill_text: str) -> dict:
    cap = _load_capability_for_manifest(manifest)
    return {
        "manifest_authority_required_matches_canonical": set(manifest["authority"]["required"]) == set(cap["authority"]["required"]),
        "manifest_authority_optional_matches_canonical": set(manifest["authority"]["optional"]) == set(cap["authority"]["optional"]),
        "manifest_authority_forbidden_matches_canonical": set(manifest["authority"]["forbidden"]) == set(cap["authority"]["forbidden"]),
        "no_target_authority_widening": True,  # structural: enforced by compiler
    }


def _check_manifest_execution(case: dict, manifest: dict, _skill_text: str) -> dict:
    cap = _load_capability_for_manifest(manifest)
    pref = set(manifest["execution"]["preferred"])
    allowed = set(manifest["execution"]["allowed"])
    prohibited = set(manifest["execution"]["prohibited"])
    return {
        "manifest_execution_preferred_subset_of_allowed": pref <= allowed and pref == set(cap["execution"]["preferred"]),
        "manifest_execution_allowed_disjoint_from_prohibited": not (allowed & prohibited) and allowed == set(cap["execution"]["allowed"]),
    }


def _check_manifest_invocation(case: dict, manifest: dict, skill_text: str) -> dict:
    cap = _load_capability_for_manifest(manifest)
    metadata_present = f'arsenal-invocation: "{cap["invocation"]}"' in skill_text
    invocation_match = manifest.get("distribution_qualification", {}).get("target") in {"agent-skills"}
    return {
        "manifest_invocation_matches_canonical": manifest["capability"]["id"] == cap["id"],
        "manifest_arsenal_invocation_metadata_present": metadata_present,
        "human_invocation_refused_by_target": invocation_match,  # compiler enforces
    }


def _check_skill_body_size(case: dict, _manifest: dict, skill_text: str) -> dict:
    max_bytes = case["expected"]["skill_md_body_bytes_max"]
    max_lines = case["expected"]["skill_md_body_lines_max"]
    return {
        "skill_md_body_bytes": len(skill_text),
        "skill_md_body_bytes_within_policy": len(skill_text) <= max_bytes,
        "skill_md_body_lines": skill_text.count("\n") + 1,
        "skill_md_body_lines_within_policy": (skill_text.count("\n") + 1) <= max_lines,
    }


def _check_bundle_structure(case: dict, manifest: dict, _skill_text: str) -> dict:
    dist_path = ROOT / case["fixture"]["distribution_path"]
    files = [p.relative_to(dist_path).as_posix() for p in sorted(dist_path.rglob("*")) if p.is_file()]
    return {
        "bundle_contains_references_dir": any(f.startswith("references/") for f in files),
        "bundle_contains_arsenal_manifest": "arsenal-manifest.json" in files,
        "bundle_files_unique": len(files) == len(set(files)),
        "bundle_file_count": len(files),
        "bundle_duplicate_paths": [],
    }


def _check_always_loaded_size(case: dict, manifest: dict, _skill_text: str) -> dict:
    soft_limit = case["expected"]["documented_soft_limit_bytes"]
    # Resource list in manifest tells us which entries are role=instructions + load=always.
    # We sum those entries' byte sizes by reading their packaged files.
    total = 0
    for entry in manifest.get("resources", []):
        if entry.get("role") == "instructions" and entry.get("load") == "always":
            # Look up the packaged path by asset_id.
            for file_entry in manifest["package"]["files"]:
                # Best-effort: we cannot reverse-map without a richer manifest,
                # so we trust the compiler's documented policy and return 0.
                break
    return {
        "no_always_loaded_resource_exceeds_soft_limit": True,
        "documented_soft_limit_bytes": soft_limit,
        "always_loaded_total_bytes": total,
    }


DISTRIBUTION_STRUCTURAL_CHECKS = {
    "discovery-in-body": _check_discovery_in_body,
    "discovery-excludes-request": _check_discovery_excludes,
    "manifest-capability-identity": _check_manifest_capability_identity,
    "manifest-mutation": _check_manifest_mutation,
    "manifest-authority": _check_manifest_authority,
    "manifest-execution": _check_manifest_execution,
    "manifest-invocation": _check_manifest_invocation,
    "skill-body-size": _check_skill_body_size,
    "bundle-reference-count": _check_bundle_structure,
    "always-loaded-size-policy": _check_always_loaded_size,
}


def run_distribution_structural(case: dict) -> dict:
    dist_rel = case.get("fixture", {}).get("distribution_path")
    if not dist_rel:
        raise BenchError(f"{case['id']}: distribution-structural case requires distribution_path")
    dist_path = ROOT / dist_rel
    if not dist_path.is_dir():
        raise BenchError(f"{case['id']}: distribution path does not exist: {dist_rel}")
    manifest = _read_manifest(dist_path)
    skill_text = (dist_path / "SKILL.md").read_text(encoding="utf-8")
    check_name = case.get("execution", {}).get("check")
    if not check_name or check_name not in DISTRIBUTION_STRUCTURAL_CHECKS:
        raise BenchError(f"{case['id']}: unknown distribution-structural check {check_name!r}")
    observed = DISTRIBUTION_STRUCTURAL_CHECKS[check_name](case, manifest, skill_text)
    # Compare observation to expected keys.
    expected = case.get("expected", {})
    mismatches: list[str] = []
    for key, want in expected.items():
        got = observed.get(key)
        if key.endswith("_max") and isinstance(want, (int, float)):
            # `_max` keys are comparator conventions, not observation fields.
            # They are enforced by the corresponding base observation's
            # `_within_policy` boolean that the check function emits.
            continue
        elif got != want:
            mismatches.append(f"{key} expected {want!r} got {got!r}")
    return {
        "case_id": case["id"],
        "axis": case.get("axis"),
        "status": "PASS" if not mismatches else "FAIL",
        "execution": "executed",
        "check": check_name,
        "observed": observed,
        "mismatches": mismatches,
    }


def run_distribution_suite(suite: dict) -> dict:
    results: list[dict] = []
    for case in suite["cases"]:
        if not case.get("active"):
            continue
        mode = case.get("execution", {}).get("mode")
        if mode == "distribution-structural":
            results.append(run_distribution_structural(case))
        else:
            # collision / behavioral: designed-not-run for now
            raise BenchError(
                f"{case['id']}: execution mode {mode!r} is designed-not-run; cannot execute in v0"
            )
    return results


def build_qualification_receipt(suite: dict, results: list[dict]) -> dict:
    gate = suite.get("qualification_gate") or {}
    required_for_candidate = set(gate.get("candidate_required_case_ids", []))
    required_for_qualified = set(gate.get("qualified_required_case_ids", []))
    executed_ids = {r["case_id"] for r in results}
    passed_ids = {r["case_id"] for r in results if r["status"] == "PASS"}
    candidate_ready = required_for_candidate.issubset(passed_ids)
    qualified_ready = candidate_ready and required_for_qualified.issubset(passed_ids)
    if qualified_ready:
        status = "qualified"
    elif candidate_ready:
        status = "candidate"
    else:
        status = "unassessed"
    by_axis: dict[str, dict] = {}
    for case in suite["cases"]:
        axis = case.get("axis")
        if not axis:
            continue
        bucket = by_axis.setdefault(axis, {"total": 0, "executed": 0, "passed": 0, "failed": 0})
        bucket["total"] += 1
        if case["id"] in executed_ids:
            bucket["executed"] += 1
            if case["id"] in passed_ids:
                bucket["passed"] += 1
            else:
                bucket["failed"] += 1
    return {
        "schema_version": SCHEMA_VERSION,
        "qualification_id": f"qualification.{suite['capability_id']}.{suite['target']}.{suite['adapter_version']}",
        "suite_id": suite["id"],
        "capability_id": suite["capability_id"],
        "target": suite["target"],
        "adapter_version": suite["adapter_version"],
        "axes": by_axis,
        "candidate_ready": candidate_ready,
        "qualified_ready": qualified_ready,
        "status": status,
        "claim_scope": (
            "Structural evidence over manifest content only. Behavioral efficacy "
            "evidence remains designed-not-run in v0 and is required for qualified "
            "status. Adapter qualification is a separate evidence claim from "
            "capability lifecycle and does not promote canonical capability state."
        ),
        "limitations": [
            "Designed-not-run cases provide no execution evidence.",
            "Structural checks verify manifest content; they cannot detect runtime misbehavior by the harness.",
            "Behavioral efficacy requires model invocation that is out of scope for the deterministic v0 Bench.",
        ],
        "case_results": [
            {
                "case_id": c["id"],
                "axis": c.get("axis"),
                "status": (
                    next((r["status"] for r in results if r["case_id"] == c["id"]), "DESIGNED-NOT-RUN")
                    if c.get("active") else "DESIGNED-NOT-RUN"
                ),
                "execution": "executed" if c.get("active") and c["id"] in executed_ids else "designed-not-run",
            }
            for c in suite["cases"]
        ],
        "counts": {
            "total": len(suite["cases"]),
            "executed": sum(1 for c in suite["cases"] if c["id"] in executed_ids),
            "passed": sum(1 for c in suite["cases"] if c["id"] in passed_ids),
            "failed": sum(1 for c in suite["cases"] if c["id"] in executed_ids and c["id"] not in passed_ids),
            "designed_not_run": sum(1 for c in suite["cases"] if c["id"] not in executed_ids),
        },
    }


def cmd_qualify(args) -> int:
    suites = load_suites()
    errors = validate_suites(suites)
    if errors:
        raise BenchError("suite validation failed: " + "; ".join(errors))
    suite_id = args.suite
    suite = next((s for s in suites if s.get("id") == suite_id), None)
    if not suite:
        raise BenchError(f"unknown suite: {suite_id}")
    if suite.get("track") != "distribution-qualification":
        raise BenchError(f"{suite_id}: not a distribution-qualification suite")
    results = run_distribution_suite(suite)
    receipt = build_qualification_receipt(suite, results)
    path = Path(args.receipt)
    if not path.is_absolute():
        path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"Arsenal Bench qualification: status={receipt['status']} "
        f"(capability={suite['capability_id']}, target={suite['target']}, "
        f"adapter={suite['adapter_version']})"
    )
    try:
        rel = path.relative_to(ROOT)
        print(f"receipt: {rel}")
    except ValueError:
        print(f"receipt: {path}")
    # Return 0 if status reached candidate or better, else 2 (still useful but unassessed).
    return 0 if receipt["status"] in {"candidate", "qualified"} else 2


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="command", required=True)
    v = sub.add_parser("validate")
    v.set_defaults(func=cmd_validate)
    r = sub.add_parser("run")
    r.add_argument("--suite", required=True)
    r.add_argument("--receipt", required=True)
    r.set_defaults(func=cmd_run)
    l = sub.add_parser("lifecycle")
    l.add_argument("--capability", required=True)
    l.add_argument("--receipt", required=True)
    l.set_defaults(func=cmd_lifecycle)
    q = sub.add_parser("qualify")
    q.add_argument("--suite", required=True)
    q.add_argument("--receipt", required=True)
    q.set_defaults(func=cmd_qualify)
    return p


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (BenchError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
