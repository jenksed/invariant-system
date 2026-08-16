#!/usr/bin/env python3
"""ARS-05 Reality Budget contract, selection, and negative tests."""
from __future__ import annotations

import copy
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/arsenal_substrate.py"
SPEC = importlib.util.spec_from_file_location("arsenal_substrate", SCRIPT)
assert SPEC and SPEC.loader
substrate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(substrate)


def expect_catalog_fail(label: str, catalog: dict) -> None:
    try:
        substrate.validate_catalog_data(catalog)
    except (AssertionError, KeyError, TypeError, ValueError):
        print(f"PASS negative catalog case: {label}")
        return
    raise AssertionError(f"negative catalog case unexpectedly passed: {label}")


def expect_proof_fail(label: str, proof: dict, catalog_view: dict, capabilities: dict) -> None:
    try:
        substrate.validate_proof_data(proof, capabilities=capabilities, catalog_view=catalog_view)
    except (AssertionError, KeyError, TypeError, ValueError):
        print(f"PASS negative proof case: {label}")
        return
    raise AssertionError(f"negative proof case unexpectedly passed: {label}")


def assert_verdict(label: str, report: dict, verdict: str, selected: str | None = None) -> None:
    assert report["verdict"] == verdict, (label, report)
    if selected is not None:
        assert report["selected"] and report["selected"]["id"] == selected, (label, report)
    print(f"PASS Reality Budget: {label} -> {verdict}" + (f" / {selected}" if selected else ""))


def main() -> int:
    catalog = substrate.load_json(ROOT / "arsenal/substrates/catalog.json")
    proof = substrate.load_json(ROOT / "arsenal/substrates/proof-requirements.json")
    catalog_view = substrate.validate_catalog_data(catalog)
    capabilities = substrate.load_capabilities(ROOT)
    proof_bindings = substrate.validate_proof_data(proof, capabilities=capabilities, catalog_view=catalog_view)

    assert len(catalog_view["substrates"]) == 12
    assert len(catalog_view["profiles"]) == 5
    assert len(proof_bindings) == 7
    print("PASS valid ARS-05 substrate and proof contracts")

    repo = substrate.select_substrate(
        "capability.repository-truth",
        "claims_grounded",
        authority_profile="read-only",
        availability_profile="minimal-local",
    )
    assert_verdict("Repository Truth uses repository observation", repo, "SELECTED", "substrate.repository-read")

    tdd = substrate.select_substrate(
        "capability.tdd",
        "red_observed",
        authority_profile="workspace-safe",
        availability_profile="minimal-local",
    )
    assert_verdict("TDD red proof uses lowest sufficient world", tdd, "SELECTED", "substrate.in-process-test")
    assert tdd["selected"]["reality_rank"] == 2

    tdd_fallback = substrate.select_substrate(
        "capability.tdd",
        "red_observed",
        authority_profile="workspace-safe",
        availability_profile="minimal-local",
        omitted_substrates={"substrate.in-process-test"},
    )
    assert_verdict("TDD deterministically falls back one rung", tdd_fallback, "SELECTED", "substrate.local-process")
    assert tdd_fallback["selected"]["reality_rank"] == 3

    route = substrate.select_substrate(
        "capability.local-cloud-feature-delivery",
        "provider_route",
        authority_profile="local-cloud-safe",
        availability_profile="floci-local",
    )
    assert_verdict("Local Cloud provider route uses deterministic proof", route, "SELECTED", "substrate.deterministic-function")

    local_cloud = substrate.select_substrate(
        "capability.local-cloud-feature-delivery",
        "local_boundary",
        authority_profile="local-cloud-safe",
        availability_profile="floci-local",
    )
    assert_verdict("Local Cloud boundary stops at emulator", local_cloud, "SELECTED", "substrate.local-emulator")
    assert "real-provider-semantics" not in local_cloud["selected"]["earned_traits"]
    assert any("Does not prove real-provider" in item for item in local_cloud["selected"]["limitations"])

    unavailable = substrate.select_substrate(
        "capability.local-cloud-feature-delivery",
        "local_boundary",
        authority_profile="local-cloud-safe",
        availability_profile="container-local",
    )
    assert_verdict("Emulator not declared available", unavailable, "SUBSTRATE_GAP")
    assert unavailable["candidate"]["id"] == "substrate.local-emulator"

    authority_gap = substrate.select_substrate(
        "capability.local-cloud-feature-delivery",
        "local_boundary",
        authority_profile="workspace-safe",
        availability_profile="floci-local",
    )
    assert_verdict("Cloud-local authority is required", authority_gap, "AUTHORITY_GAP")
    assert "cloud.local" in authority_gap["candidate"]["missing_authority"]

    provider_semantics = substrate.select_substrate(
        "capability.local-cloud-feature-delivery",
        "local_boundary",
        authority_profile="local-cloud-safe",
        availability_profile="floci-local",
        extra_traits=["real-provider-semantics"],
    )
    assert_verdict("Provider semantics require explicit escalation", provider_semantics, "ESCALATION_REQUIRED")
    assert provider_semantics["candidate"]["id"] == "substrate.remote-disposable"
    assert provider_semantics["candidate"]["selection_mode"] == "explicit-only"
    assert provider_semantics["candidate"]["capability_allows_surface"] is False
    assert "cloud.remote" in provider_semantics["candidate"]["missing_authority"]

    impossible = substrate.select_substrate(
        "capability.tdd",
        "red_observed",
        authority_profile="workspace-safe",
        availability_profile="minimal-local",
        extra_traits=["quantum-hardware-proof"],
    )
    assert_verdict("Unknown proof property fails closed", impossible, "EVIDENCE_GAP")

    bad = copy.deepcopy(catalog)
    bad["substrates"][1]["reality_rank"] = bad["substrates"][0]["reality_rank"]
    expect_catalog_fail("duplicate reality rank", bad)

    bad = copy.deepcopy(catalog)
    for item in bad["substrates"]:
        if item["id"] == "substrate.remote-disposable":
            item["selection_mode"] = "automatic"
    expect_catalog_fail("automatic remote sandbox", bad)

    bad = copy.deepcopy(catalog)
    bad["availability_profiles"][0]["substrates"].append("substrate.production")
    expect_catalog_fail("availability profile contains explicit-only production", bad)

    bad = copy.deepcopy(catalog)
    bad["substrates"][0]["escalation_to"] = "substrate.deterministic-function"
    expect_catalog_fail("non-increasing escalation", bad)

    bad_proof = copy.deepcopy(proof)
    bad_proof["requirements"][0]["verification_requirement_id"] = "does_not_exist"
    expect_proof_fail("unknown verification requirement", bad_proof, catalog_view, capabilities)

    bad_proof = copy.deepcopy(proof)
    bad_proof["requirements"][0]["required_traits"] = ["substrate.local-process"]
    expect_proof_fail("substrate identity leaked into proof requirement", bad_proof, catalog_view, capabilities)

    bad_proof = copy.deepcopy(proof)
    bad_proof["requirements"][0]["minimum_isolation"] = "magic"
    expect_proof_fail("invalid isolation requirement", bad_proof, catalog_view, capabilities)

    print("ARS-05 Reality Budget test suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
