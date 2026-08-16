#!/usr/bin/env python3
"""Negative, privacy, and normalization tests for ARS-07 Flight Records."""
from __future__ import annotations

import copy
import importlib.util
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/arsenal_observe.py"
SPEC = importlib.util.spec_from_file_location("arsenal_observe", SCRIPT)
assert SPEC and SPEC.loader
observe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(observe)
TEST_DIR = ROOT / ".arsenal-observatory-test"


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")


def dagger_source() -> dict:
    return {
        "schema_version": "1.0.0",
        "receipt_kind": "arsenal-executable-world",
        "world": {"id": "world.tdd-python-container", "version": "0.1.0"},
        "capability": {
            "id": "capability.tdd",
            "version": "0.1.0",
            "verification_requirements": ["red_observed", "green_observed"],
        },
        "proof_gate": {
            "selector": "arsenal/substrates",
            "additional_required_traits": ["container-runtime"],
            "reports": [
                {
                    "verdict": "SELECTED",
                    "authority_profile": "workspace-safe",
                    "selected": {"id": "substrate.local-container", "reality_rank": 4},
                },
                {
                    "verdict": "SELECTED",
                    "authority_profile": "workspace-safe",
                    "selected": {"id": "substrate.local-container", "reality_rank": 4},
                },
            ],
        },
        "adapter_runtime": {"id": "dagger", "version": "0.21.7"},
        "world_evidence": {"results": {"red_observed": True, "green_observed": True}},
        "evidence_boundary": {
            "claim": "Containerized execution observed the declared TDD red/green verification behavior inside the selected local-container world.",
            "does_not_claim": ["Does not prove production or provider semantics."],
        },
    }


def bench_source() -> dict:
    return {
        "schema_version": "1.0.0",
        "suite_id": "suite.local-cloud-v0",
        "capability_id": "capability.local-cloud-feature-delivery",
        "verdict": "PASS",
        "claim_scope": "Deterministic Local Cloud routing and execution-boundary contract evidence. No model/harness efficacy comparison is claimed.",
        "execution_provenance": {
            "runner": "scripts/arsenal_bench.py",
            "repository_sha": "repo-sha-1",
            "model": "not-applicable",
            "harness": "deterministic-python-adapter",
            "remote_credentials_used": False,
        },
        "capability_passport": {
            "capability_id": "capability.local-cloud-feature-delivery",
            "capability_version": "0.1.0",
            "lifecycle": "testing",
            "evaluation_status": "candidate",
            "suite_id": "suite.local-cloud-v0",
        },
        "limitations": [
            "Control/counterfactual arms are declared but not executed in the deterministic v0 adapter.",
            "No coding model or agent harness is evaluated by this receipt.",
        ],
    }


def expect_fail(label: str, fn) -> None:
    try:
        fn()
    except (observe.ObserveError, AssertionError, KeyError, TypeError, ValueError):
        print(f"PASS negative case: {label}")
        return
    raise AssertionError(f"negative case unexpectedly passed: {label}")


def main() -> int:
    shutil.rmtree(TEST_DIR, ignore_errors=True)
    TEST_DIR.mkdir(parents=True)
    try:
        dagger_path = TEST_DIR / "dagger.json"
        bench_path = TEST_DIR / "bench.json"
        write_json(dagger_path, dagger_source())
        write_json(bench_path, bench_source())

        d1 = observe.dagger_record(dagger_path, "instance-a", "repo-sha-1")
        d2 = observe.dagger_record(dagger_path, "instance-b", "repo-sha-1")
        b1 = observe.bench_record(bench_path, "bench-a", "repo-sha-1")
        observe.validate_record(d1)
        observe.validate_record(d2)
        observe.validate_record(b1)
        print("PASS Dagger and Bench normalize into valid Flight Records")

        assert set(d1) == set(b1) == observe.TOP_LEVEL
        assert d1["run"]["kind"] == "capability-verification"
        assert b1["run"]["kind"] == "evaluation"
        assert b1["authority"]["profile"] is None
        assert b1["authority"]["required"] == b1["authority"]["granted"] == b1["authority"]["missing"] == []
        print("PASS normal execution and Bench share one top-level record contract")
        print("PASS Bench records evaluator-layer authority without inventing capability execution grants")

        assert d1["run"]["fingerprint"] == d2["run"]["fingerprint"]
        assert d1["run"]["instance_id"] != d2["run"]["instance_id"]
        print("PASS instance identity is separate from deterministic run fingerprint")

        d3 = observe.dagger_record(dagger_path, "instance-c", "repo-sha-2")
        assert d3["run"]["fingerprint"] != d1["run"]["fingerprint"]
        print("PASS repository state participates in behavioral fingerprint")

        stale_bench = bench_source()
        stale_bench["execution_provenance"]["repository_sha"] = "repo-sha-stale"
        stale_bench_path = TEST_DIR / "bench-stale.json"
        write_json(stale_bench_path, stale_bench)
        expect_fail(
            "Bench source repository provenance mismatch",
            lambda: observe.bench_record(stale_bench_path, "bench-stale", "repo-sha-1"),
        )

        bad = copy.deepcopy(d1)
        bad["authority"]["granted"] = []
        bad["authority"]["missing"] = []
        bad = observe.apply_fingerprint(bad)
        expect_fail("execution authority arithmetic drift", lambda: observe.validate_record(bad))

        bad = copy.deepcopy(d1)
        bad["privacy"]["prompt_content_recorded"] = True
        bad = observe.apply_fingerprint(bad)
        expect_fail("prompt-content privacy opt-in is unavailable in v0", lambda: observe.validate_record(bad))

        bad = copy.deepcopy(d1)
        bad["context"]["sources"][0]["prompt"] = "secret prompt content"
        bad = observe.apply_fingerprint(bad)
        expect_fail("forbidden prompt field", lambda: observe.validate_record(bad))

        bad = copy.deepcopy(d1)
        bad["outcome"]["accepted_evidence_ids"] = ["evidence.missing"]
        bad = observe.apply_fingerprint(bad)
        expect_fail("outcome without accepted evidence", lambda: observe.validate_record(bad))

        bad = copy.deepcopy(d1)
        bad["timeline"][1]["sequence"] = 9
        bad = observe.apply_fingerprint(bad)
        expect_fail("non-contiguous timeline", lambda: observe.validate_record(bad))

        bad = copy.deepcopy(d1)
        bad["provenance"]["model"] = observe.identity("not-applicable", "invented-model", "1")
        bad = observe.apply_fingerprint(bad)
        expect_fail("fabricated not-applicable model identity", lambda: observe.validate_record(bad))

        bad = copy.deepcopy(d1)
        bad["run"]["fingerprint"] = "sha256:" + "f" * 64
        expect_fail("fingerprint drift", lambda: observe.validate_record(bad))

        source_before = dagger_path.read_bytes()
        d_source = observe.dagger_record(dagger_path, "instance-d", "repo-sha-1")
        dagger_path.write_bytes(source_before + b" \n")
        expect_fail("source receipt digest drift", lambda: observe.validate_record(d_source))
        dagger_path.write_bytes(source_before)

        assert "prompt" in observe.forbidden_keys()
        assert "chain_of_thought" in observe.forbidden_keys()
        assert observe.telemetry_block()["event_transport"] == "log-based-events"
        assert observe.telemetry_block()["attribute_namespace"] == "arsenal"
        print("PASS metadata-first privacy and OTel mapping policy")

        print("ARS-07 Flight Recorder contract suite: PASS")
        return 0
    finally:
        shutil.rmtree(TEST_DIR, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
