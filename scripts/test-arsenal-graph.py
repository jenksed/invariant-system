#!/usr/bin/env python3
"""ARS-04 Capability Graph contract, preflight, and negative tests."""
from __future__ import annotations

import copy
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/arsenal_graph.py"
SPEC = importlib.util.spec_from_file_location("arsenal_graph", SCRIPT)
assert SPEC and SPEC.loader
graphmod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(graphmod)


def expect_graph_fail(label: str, graph: dict) -> None:
    try:
        graphmod.validate_graph_data(graph, ROOT)
    except (AssertionError, KeyError, TypeError, ValueError):
        print(f"PASS negative graph case: {label}")
        return
    raise AssertionError(f"negative graph case unexpectedly passed: {label}")


def assert_verdict(label: str, expected: str, **kwargs) -> dict:
    report = graphmod.preflight(**kwargs)
    assert report["verdict"] == expected, (label, report)
    print(f"PASS preflight: {label} -> {expected}")
    return report


def main() -> int:
    graph = graphmod.load_json(ROOT / "arsenal/graph/graph.json")
    validated = graphmod.validate_graph_data(graph, ROOT)
    assert len(validated["routes"]) == 4
    assert len(validated["profiles"]) == 3
    print("PASS valid ARS-04 graph")

    assert_verdict(
        "canonical feature route",
        "READY",
        route_id="route.feature-delivery",
        inventory="canonical",
        authority_profile="workspace-safe",
    )

    missing_tdd = assert_verdict(
        "feature route with TDD omitted",
        "CAPABILITY_GAP",
        route_id="route.feature-delivery",
        inventory="canonical",
        authority_profile="workspace-safe",
        omitted={"capability.tdd"},
    )
    tdd = next(step for step in missing_tdd["steps"] if step["capability_id"] == "capability.tdd")
    assert tdd["status"] == "missing"

    lock_gap = assert_verdict(
        "feature route against competence lockfile",
        "CAPABILITY_GAP",
        route_id="route.feature-delivery",
        inventory="lock",
        authority_profile="workspace-safe",
    )
    covered = [step["capability_id"] for step in lock_gap["steps"] if step["status"] == "covered"]
    assert covered == ["capability.repository-truth"], covered

    locked = graphmod.load_locked_capabilities(ROOT)
    repo_record = graphmod.load_capabilities(ROOT)["capability.repository-truth"]
    stale = copy.deepcopy(locked["capability.repository-truth"])
    stale["version"] = "9.9.9"
    lock_ok, lock_reasons = graphmod.locked_entry_state(repo_record, stale)
    assert not lock_ok
    assert any("locked version" in reason for reason in lock_reasons)
    print("PASS stale competence lock detection")

    authority_gap = assert_verdict(
        "feature route under read-only authority",
        "AUTHORITY_GAP",
        route_id="route.feature-delivery",
        inventory="canonical",
        authority_profile="read-only",
    )
    assert any(step["status"] == "unauthorized" for step in authority_gap["steps"])

    qualification_gap = assert_verdict(
        "Core feature route requiring testing/candidate",
        "QUALIFICATION_GAP",
        route_id="route.feature-delivery",
        inventory="canonical",
        authority_profile="workspace-safe",
        minimum_lifecycle="testing",
        minimum_evaluation="candidate",
    )
    assert any(step["status"] == "insufficient-qualification" for step in qualification_gap["steps"])

    local_ready = assert_verdict(
        "Local Cloud route with earned qualification and local-cloud authority",
        "READY",
        route_id="route.local-cloud-feature-delivery",
        inventory="canonical",
        authority_profile="local-cloud-safe",
    )
    local_step = next(
        step
        for step in local_ready["steps"]
        if step["capability_id"] == "capability.local-cloud-feature-delivery"
    )
    assert local_step["qualification"]["lifecycle"] == "testing"
    assert local_step["qualification"]["evaluation"] == "candidate"
    assert local_step["qualification"]["minimum_lifecycle"] == "testing"
    assert local_step["qualification"]["minimum_evaluation"] == "candidate"

    local_authority_gap = assert_verdict(
        "Local Cloud route without cloud.local authority",
        "AUTHORITY_GAP",
        route_id="route.local-cloud-feature-delivery",
        inventory="canonical",
        authority_profile="workspace-safe",
    )
    local_step = next(
        step
        for step in local_authority_gap["steps"]
        if step["capability_id"] == "capability.local-cloud-feature-delivery"
    )
    assert local_step["status"] == "unauthorized"
    assert local_step["authority"]["missing"] == ["cloud.local"]

    bad = copy.deepcopy(graph)
    bad["routes"][0]["steps"][0]["capability_id"] = "capability.not-real"
    expect_graph_fail("unknown capability", bad)

    bad = copy.deepcopy(graph)
    bad["routes"][1]["steps"][1]["after"] = ["capability.verify"]
    expect_graph_fail("dependency not yet available", bad)

    bad = copy.deepcopy(graph)
    bad["routes"][1]["steps"][1]["minimum_version"] = "latest"
    expect_graph_fail("invalid semantic version", bad)

    bad = copy.deepcopy(graph)
    bad["routes"][1]["steps"][1]["minimum_lifecycle"] = "probably-good"
    expect_graph_fail("invalid lifecycle minimum", bad)

    bad = copy.deepcopy(graph)
    bad["routes"][1]["steps"][1]["minimum_evaluation"] = "vibes"
    expect_graph_fail("invalid evaluation minimum", bad)

    bad = copy.deepcopy(graph)
    bad["authority_profiles"][0]["grants"].append("cloud.remote")
    expect_graph_fail("unsafe remote-cloud authority profile", bad)

    print("ARS-04 Capability Graph test suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
