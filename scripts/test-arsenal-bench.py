#!/usr/bin/env python3
"""Negative contract suite for Arsenal Bench v0."""

from __future__ import annotations

import copy
import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "arsenal_bench.py"
spec = importlib.util.spec_from_file_location("arsenal_bench", MODULE_PATH)
bench = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(bench)


def require_error(label: str, suites: list[dict], needle: str) -> None:
    errors = bench.validate_suites(suites)
    if not any(needle in error for error in errors):
        raise AssertionError(f"{label}: expected error containing {needle!r}; got {errors}")
    print(f"PASS negative case: {label}")


def main() -> int:
    suites = bench.load_suites()
    errors = bench.validate_suites(suites)
    assert not errors, errors
    print("PASS valid Bench corpus (core-engineering + local-cloud + distribution-qualification)")

    broken = copy.deepcopy(suites)
    broken[1]["cases"][0]["id"] = broken[0]["cases"][0]["id"]
    require_error("duplicate case id", broken, "duplicate case id")

    broken = copy.deepcopy(suites)
    local = next(s for s in broken if s["id"] == "suite.local-cloud-v0")
    local["lifecycle_gate"]["minimum_executed_cases"] = 0
    require_error("zero lifecycle minimum", broken, "positive integer")

    broken = copy.deepcopy(suites)
    local = next(s for s in broken if s["id"] == "suite.local-cloud-v0")
    required = local["lifecycle_gate"]["required_case_ids"][0]
    next(c for c in local["cases"] if c["id"] == required)["active"] = False
    next(c for c in local["cases"] if c["id"] == required)["execution"]["status"] = "designed-not-run"
    require_error("lifecycle cannot count designed-not-run case", broken, "not active/executable")

    broken = copy.deepcopy(suites)
    broken[0]["cases"][0].pop("comparison")
    require_error("missing counterfactual contract", broken, "missing fields")

    # Negative cases for distribution-qualification track.
    broken = copy.deepcopy(suites)
    dq = next(s for s in broken if s["id"] == "suite.distribution-qualification-v0")
    dq["cases"][0].pop("axis")
    require_error("distribution case missing axis", broken, "distribution-qualification cases require an axis")

    broken = copy.deepcopy(suites)
    dq = next(s for s in broken if s["id"] == "suite.distribution-qualification-v0")
    dq["cases"][0]["axis"] = "unknown-axis"
    require_error("distribution case unknown axis", broken, "unknown distribution-qualification axis")

    broken = copy.deepcopy(suites)
    dq = next(s for s in broken if s["id"] == "suite.distribution-qualification-v0")
    dq["cases"][0]["execution"]["mode"] = "bogus-mode"
    require_error("distribution case invalid mode", broken, "invalid execution mode")

    broken = copy.deepcopy(suites)
    local = next(s for s in broken if s["id"] == "suite.local-cloud-v0")
    local["cases"][0]["execution"]["status"] = "designed-not-run"
    require_error("active case must be executable", broken, "active case must be executable")

    broken = copy.deepcopy(suites)
    broken[0]["cases"][0]["case_health"]["required_checks"].append("looks_good_to_me")
    require_error("unknown health check", broken, "unknown case health checks")

    broken = copy.deepcopy(suites)
    local = next(s for s in broken if s["id"] == "suite.local-cloud-v0")
    local["lifecycle_gate"]["minimum_executed_cases"] = 99
    require_error("lifecycle minimum exceeds required cases", broken, "exceeds required case count")

    core = next(s for s in suites if s["id"] == "suite.arsenal-core-v0")
    assert all(not c["active"] and c["execution"]["status"] == "designed-not-run" for c in core["cases"])
    assert all("comparison" in c for c in core["cases"])
    print("PASS Core agent cases remain explicitly designed-not-run")
    print("Arsenal Bench negative suite: PASS")

    # Distribution qualification tracer: run the qualify command against the
    # compiled Repository Truth distribution and assert it reaches candidate
    # status when all candidate-required cases pass.
    import tempfile, json
    from io import StringIO
    with tempfile.TemporaryDirectory(prefix="arsenal-bench-qualify-test-") as tmp:
        receipt_path = Path(tmp) / "qualification.json"
        argv = [
            "qualify",
            "--suite", "suite.distribution-qualification-v0",
            "--receipt", str(receipt_path),
        ]
        original_argv = sys.argv
        original_stderr = sys.stderr
        sys.argv = ["arsenal_bench"] + argv
        sys.stderr = StringIO()
        try:
            rc = bench.main()
            err_output = sys.stderr.getvalue()
        finally:
            sys.argv = original_argv
            sys.stderr = original_stderr
        assert rc == 0, f"qualify command exited with {rc}, expected 0 (candidate); stderr: {err_output}"
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
        assert receipt["status"] == "candidate", f"expected status=candidate, got {receipt['status']!r}"
        assert receipt["target"] == "agent-skills"
        assert receipt["adapter_version"] == "1.0.0"
        assert receipt["capability_id"] == "capability.repository-truth"
        # Behavioral efficacy cases must remain designed-not-run.
        behavioral = [c for c in receipt["case_results"] if c["axis"] == "behavioral_efficacy"]
        assert behavioral, "behavioral_efficacy cases missing"
        assert all(c["status"] == "DESIGNED-NOT-RUN" for c in behavioral), \
            "behavioral_efficacy cases should remain designed-not-run in v0"
        assert receipt["qualified_ready"] is False
        print("PASS distribution-qualification tracer reaches candidate status")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
