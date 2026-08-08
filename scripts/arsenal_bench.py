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
EXECUTION_STATUS = {"designed-not-run", "executable"}


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
    if not isinstance(execution, dict) or execution.get("mode") not in EXECUTION_MODES or execution.get("status") not in EXECUTION_STATUS:
        errors.append(f"{cid}: invalid execution contract")
    elif case["active"]:
        if execution["status"] != "executable":
            errors.append(f"{cid}: active case must be executable")
        if execution["mode"] != "local-cloud-router":
            errors.append(f"{cid}: ARS-02 v0 active execution supports local-cloud-router only")
    elif execution["status"] != "designed-not-run":
        errors.append(f"{cid}: inactive case must remain designed-not-run")

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
        totals[suite.get("track", "<missing>")] = len(cases)
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
    if len(ids) != 19:
        errors.append(f"ARS-02 v0 requires 19 unique cases; found {len(ids)}")
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
    print("Arsenal Bench contract: PASS (19 cases: 8 core; 11 local-cloud; 5 executable)")
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
