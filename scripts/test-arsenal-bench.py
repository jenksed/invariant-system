#!/usr/bin/env python3
"""Negative contract suite for Arsenal Bench v0."""

from __future__ import annotations

import copy
import importlib.util
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
    print("PASS valid 19-case Bench corpus")

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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
