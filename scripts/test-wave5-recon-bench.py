#!/usr/bin/env python3
"""Characterization tests for the Wave 5 capability-evolution bench."""

from __future__ import annotations

import copy
import importlib.util
import json
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BENCH_PATH = ROOT / "scripts" / "wave5_recon_bench.py"
WAVE5 = ROOT / "evaluation" / "wave5"

spec = importlib.util.spec_from_file_location("wave5_recon_bench", BENCH_PATH)
bench = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(bench)

from evaluation.wave5.candidates import CANDIDATES, method_implementation_digest  # noqa: E402


def test_miss_taxonomy_is_complete() -> None:
    taxonomy = json.loads((WAVE5 / "miss-taxonomy.v1.json").read_text(encoding="utf-8"))
    misses = taxonomy["misses"]
    assert len(misses) == 11
    assert len({item["miss_id"] for item in misses}) == 11
    required = {
        "miss_id", "observed_expectation", "actual_output",
        "why_current_method_missed_it", "expected_evidence_source",
        "expectation_valid", "deterministically_observable", "requires_inference",
        "inference_evaluable", "false_claim_risk", "likely_owner", "classification",
    }
    assert all(required <= set(item) for item in misses)
    assert taxonomy["summary"]["A_detection_miss"] == 9
    assert taxonomy["summary"]["B_relationship_miss"] == 2


def test_real_corpus_has_required_split_and_assertion_shape() -> None:
    corpus = json.loads((WAVE5 / "benchmark" / "corpus.v1.json").read_text(encoding="utf-8"))
    roles = {item["id"]: item["role"] for item in corpus["repositories"]}
    assert roles == {
        "project-arsenal": "development",
        "loadout": "development",
        "kiln": "validation",
        "temper": "holdout",
    }
    required = {
        "id", "expected_claim", "evidence_source", "claim_type",
        "importance", "acceptable_unknown_conditions", "expected",
    }
    for repository in corpus["repositories"]:
        oracle = json.loads(
            (WAVE5 / "benchmark" / repository["oracle"]).read_text(encoding="utf-8")
        )
        assert oracle["repository_id"] == repository["id"]
        assert len(oracle["assertions"]) >= 15
        assert all(required <= set(item) for item in oracle["assertions"])


def test_candidates_are_deterministic_and_factually_valid() -> None:
    with tempfile.TemporaryDirectory(prefix="ars-wave5-candidate-") as td:
        repo = Path(td)
        (repo / "src").mkdir()
        (repo / "src" / "main.ts").write_text("export const value = 1;\n", encoding="utf-8")
        (repo / "AGENTS.md").write_text("Read `docs/RULES.md`.\n", encoding="utf-8")
        (repo / "docs").mkdir()
        (repo / "docs" / "RULES.md").write_text("# Rules\n", encoding="utf-8")
        (repo / "package.json").write_text(
            json.dumps({"name": "fixture", "engines": {"node": ">=20"}}),
            encoding="utf-8",
        )
        for method_id, method in CANDIDATES.items():
            first = method(repo)
            second = method(repo)
            assert bench.canonical(first) == bench.canonical(second), method_id
            assert all(bench.factual_claim_is_true(repo, claim) for claim in first), method_id


def test_winner_lock_binds_current_implementation() -> None:
    lock = json.loads((WAVE5 / "winner-lock.v1.json").read_text(encoding="utf-8"))
    assert lock["method_id"] in CANDIDATES
    assert lock["implementation_digest"] == method_implementation_digest(lock["method_id"])
    try:
        bench.verify_holdout_lock(
            WAVE5 / "does-not-exist.json",
            lock["method_id"],
            lock["implementation_digest"],
        )
    except ValueError as exc:
        assert "sealed" in str(exc)
    else:
        raise AssertionError("missing holdout lock was accepted")


def test_stored_benchmark_result_digests_are_valid() -> None:
    for path in sorted((WAVE5 / "results").glob("**/*.json")):
        artifact = json.loads(path.read_text(encoding="utf-8"))
        expected_digest = artifact.pop("result_digest")
        if artifact["schema"] == "arsenal/repository-recon-benchmark-result/v1":
            artifact = copy.deepcopy(artifact)
            artifact["metrics"].pop("execution_cost_ms", None)
            assert bench.digest(artifact) == expected_digest, path
        elif artifact["schema"] == "arsenal/repository-recon-productized-result/v1":
            artifact = copy.deepcopy(artifact)
            artifact["real_corpus"]["metrics"].pop("execution_cost_ms", None)
            assert bench.digest(artifact) == expected_digest, path
        else:
            import hashlib

            actual = "sha256:" + hashlib.sha256(bench.canonical(artifact)).hexdigest()
            assert actual == expected_digest, path


def test_selection_and_holdout_gates_remain_true() -> None:
    selection = json.loads(
        (WAVE5 / "results" / "selection" / "staged-evidence-graph.json").read_text(encoding="utf-8")
    )
    original = json.loads(
        (WAVE5 / "results" / "original-16" / "staged-evidence-graph.json").read_text(encoding="utf-8")
    )
    holdout_baseline = json.loads(
        (WAVE5 / "results" / "holdout" / "baseline.json").read_text(encoding="utf-8")
    )
    holdout_winner = json.loads(
        (WAVE5 / "results" / "holdout" / "winner.json").read_text(encoding="utf-8")
    )
    assert selection["metrics"]["supported_assertions"] == 45
    assert selection["metrics"]["false_certainty"] == 0
    assert original["metrics"] == {
        "assertions": 16,
        "deterministic": True,
        "misses": 0,
        "supported": 16,
        "unsupported_factual_claims": 0,
    }
    assert holdout_baseline["metrics"]["supported_assertions"] == 4
    assert holdout_winner["metrics"]["supported_assertions"] == 15
    assert holdout_winner["metrics"]["false_certainty"] == 0
    assert holdout_winner["metrics"]["correct_unknowns"] == 1


def test_productized_loadout_matches_the_selected_method() -> None:
    lock = json.loads((WAVE5 / "productized-lock.v1.json").read_text(encoding="utf-8"))
    result = json.loads((WAVE5 / "results" / "productized.json").read_text(encoding="utf-8"))
    assert result["binding"] == lock
    assert lock["capability_id"] == "repository-recon"
    assert lock["status"] == "experimental"
    assert result["original_16"]["supported"] == 16
    assert result["original_16"]["unsupported_factual_claims"] == 0
    assert result["real_corpus"]["metrics"]["supported_assertions"] == 60
    assert result["real_corpus"]["metrics"]["assertions_total"] == 60
    assert result["real_corpus"]["metrics"]["false_certainty"] == 0
    assert result["real_corpus"]["metrics"]["deterministic"] is True


def main() -> None:
    tests = [value for name, value in sorted(globals().items()) if name.startswith("test_")]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS Wave 5 bench: {len(tests)} tests")


if __name__ == "__main__":
    main()
