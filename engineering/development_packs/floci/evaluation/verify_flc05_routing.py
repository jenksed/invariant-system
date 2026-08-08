#!/usr/bin/env python3
"""Deterministic FLC-05 routing and composition acceptance checks."""
from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
CASES = Path(__file__).with_name("flc05_cases.json")
ROUTER = ROOT / "engineering/development_packs/floci/providers/scripts/route-local-cloud-capability.py"
RECEIPT = ROOT / ".floci-artifacts/flc05-routing-receipt.json"

COMPOSED_REQUIRED = [
    "agent_workflows/repository_truth_audit.md",
    "agent_workflows/local_cloud_router.md",
    "agent_workflows/route_local_cloud_provider.md",
    "software_engineering/work_to_tracer_tickets.md",
    "software_engineering/tdd_vertical_slice.md",
    "software_engineering/diagnose_bug_feedback_loop.md",
    "software_engineering/code_review_multi_axis.md",
    "agent_workflows/independent_verification_and_receipts.md",
    "agent_workflows/session_handoff_and_continuation.md",
    "foundations/cloud_execution_boundary.md",
]


def invoke(case: dict, repo: Path) -> tuple[int, dict]:
    cmd = ["python3", str(ROUTER), "--repo", str(repo), "--task-kind", case["task_kind"], "--format", "json"]
    if case.get("provider"):
        cmd.extend(["--provider", case["provider"]])
    proc = subprocess.run(cmd, text=True, capture_output=True, check=False)
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise AssertionError(
            f"{case['id']}: invalid router JSON rc={proc.returncode}: {proc.stdout!r} {proc.stderr!r}"
        ) from exc
    return proc.returncode, data


def assert_route_assets(result: dict) -> None:
    for rel in [result.get("primary"), *result.get("support", [])]:
        if rel is None:
            continue
        assert (ROOT / rel).exists(), f"route references missing asset: {rel}"


def main() -> int:
    spec = json.loads(CASES.read_text(encoding="utf-8"))
    results = []

    for case in spec["cases"]:
        with tempfile.TemporaryDirectory(prefix=f"flc05-{case['id']}-") as td:
            repo = Path(td)
            for rel, content in case["files"].items():
                path = repo / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding="utf-8")

            rc, actual = invoke(case, repo)
            expected = case["expect"]
            assert rc == expected["rc"], (case["id"], rc, expected)
            for key, value in expected.items():
                if key == "rc":
                    continue
                assert actual.get(key) == value, (case["id"], key, actual.get(key), value)

            assert actual["automatic_real_cloud_fallback"] is False
            assert actual["requires_explicit_real_cloud_authorization"] is True
            assert_route_assets(actual)
            results.append({
                "id": case["id"],
                "rc": rc,
                "status": actual["status"],
                "provider": actual["provider"],
                "primary": actual["primary"],
                "candidate_primary": actual.get("candidate_primary"),
                "pass": True,
            })

    composed = (ROOT / "workflows/floci_first_cloud_feature_delivery.md").read_text(encoding="utf-8")
    for rel in COMPOSED_REQUIRED:
        assert rel in composed, f"composed workflow missing delegation pointer: {rel}"

    local_router = (ROOT / "agent_workflows/local_cloud_router.md").read_text(encoding="utf-8")
    assert "route-local-cloud-capability.py" in local_router
    assert "Never default to AWS" in local_router
    assert "No automatic real-cloud fallback" in local_router
    assert "UNSUPPORTED_ROUTE" in local_router
    assert "IaC validation" in local_router and "AWS" in local_router

    unsupported = sum(r["status"] == "UNSUPPORTED_ROUTE" for r in results)
    assert unsupported >= 4

    RECEIPT.parent.mkdir(parents=True, exist_ok=True)
    receipt = {
        "slice": "FLC-05",
        "case_count": len(results),
        "unsupported_route_count": unsupported,
        "cases": results,
        "automatic_real_cloud_fallback": False,
        "requires_explicit_real_cloud_authorization": True,
        "composition_pointers_verified": COMPOSED_REQUIRED,
        "verdict": "PASS",
    }
    RECEIPT.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"FLC-05 capability routing: PASS ({len(results)} cases; {unsupported} unsupported routes stopped)")
    print(f"receipt: {RECEIPT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
