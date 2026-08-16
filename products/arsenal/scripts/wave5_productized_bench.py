#!/usr/bin/env python3
"""Evaluate the exact adopted Loadout method against Wave 5 evidence.

This adapter-level proof shells out to the operator-supplied Loadout build. It
does not import Loadout implementation and never writes to target repositories.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
import time
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from evaluation.adapters.loadout_runtime_adapter import LoadoutRuntimeAdapter  # noqa: E402
from scripts.wave5_original_16 import (  # noqa: E402
    candidate_supports,
    claim_key,
    factual_claim_is_true,
)
from scripts.wave5_recon_bench import (  # noqa: E402
    DEFAULT_CORPUS,
    canonical,
    digest,
    git_head,
    parse_repo_args,
    read_json,
    score_repository,
    selected_repositories,
)

DEFAULT_LOCK = ROOT / "evaluation" / "wave5" / "productized-lock.v1.json"
DEFAULT_ORIGINAL = ROOT / "evaluation" / "method-cases" / "corpus.manifest.json"


def file_digest(path: Path) -> str:
    return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()


def productized_procedure_ref(loadout_root: Path) -> str:
    hasher = hashlib.sha256()
    for relative in (
        "src/packs/repository-recon/run.ts",
        "src/packs/repository-recon/staged-evidence-graph.ts",
    ):
        hasher.update(relative.encode("utf-8"))
        hasher.update(b"\0")
        hasher.update((loadout_root / relative).read_bytes())
        hasher.update(b"\0")
    return "sha256:" + hasher.hexdigest()


def assert_product_binding(loadout_root: Path, lock: dict[str, Any]) -> None:
    actual_commit = git_head(loadout_root)
    if actual_commit != lock["loadout_commit"]:
        raise ValueError(
            f"Loadout HEAD {actual_commit} does not match productized lock "
            f"{lock['loadout_commit']}"
        )
    actual_ref = productized_procedure_ref(loadout_root)
    if actual_ref != lock["loadout_procedure_ref"]:
        raise ValueError(
            f"Loadout procedure {actual_ref} does not match productized lock "
            f"{lock['loadout_procedure_ref']}"
        )
    capability = loadout_root / "src/packs/repository-recon/capability.json"
    if file_digest(capability) != lock["capability_contract_digest"]:
        raise ValueError("stable repository-recon Capability contract changed")


def evaluate_original_16(adapter: LoadoutRuntimeAdapter) -> dict[str, Any]:
    manifest = read_json(DEFAULT_ORIGINAL)
    supported_total = 0
    assertion_total = 0
    invalid_total = 0
    cases: list[dict[str, Any]] = []
    outputs: list[list[dict[str, Any]]] = []
    for case in manifest["corpus"]["cases"]:
        repo = ROOT / case["path"] / "repo"
        expected = read_json(ROOT / case["path"] / "expected.json")
        first = adapter.run_claims(repo)
        second = adapter.run_claims(repo)
        if canonical(first) != canonical(second):
            raise ValueError(f"productized method is nondeterministic for {case['id']}")
        outputs.append(first)
        invalid_total += sum(not factual_claim_is_true(repo, item) for item in first)
        claims = {claim_key(item["claim_type"], item["expected"]): item for item in first}
        supported: list[str] = []
        misses: list[str] = []
        for assertion in expected["expected_assertions"]:
            assertion_total += 1
            if candidate_supports(assertion, claims):
                supported_total += 1
                supported.append(assertion["id"])
            else:
                misses.append(assertion["id"])
        cases.append({"case_id": case["id"], "supported": supported, "misses": misses})
    return {
        "supported": supported_total,
        "assertions": assertion_total,
        "misses": assertion_total - supported_total,
        "unsupported_factual_claims": invalid_total,
        "deterministic": True,
        "candidate_output_digest": digest(outputs),
        "case_results": cases,
    }


def evaluate_real_corpus(
    adapter: LoadoutRuntimeAdapter,
    corpus_path: Path,
    repos: dict[str, Path],
) -> dict[str, Any]:
    corpus = read_json(corpus_path)
    results: list[dict[str, Any]] = []
    costs: list[float] = []
    for repo_meta in selected_repositories(corpus, "all"):
        repo = repos[repo_meta["id"]]
        if git_head(repo) != repo_meta["commit"]:
            raise ValueError(f"{repo_meta['id']} does not match pinned corpus commit")
        oracle = read_json(corpus_path.parent / repo_meta["oracle"])
        started = time.perf_counter()
        first = adapter.run_claims(repo)
        costs.append((time.perf_counter() - started) * 1000)
        second = adapter.run_claims(repo)
        if canonical(first) != canonical(second):
            raise ValueError(f"productized method is nondeterministic for {repo_meta['id']}")
        results.append(score_repository(repo_meta, repo, oracle, first))
    supported = sum(item["supported_count"] for item in results)
    total = sum(item["assertions_total"] for item in results)
    unsupported = sum(item["unsupported_claim_count"] for item in results)
    return {
        "results": results,
        "metrics": {
            "supported_assertions": supported,
            "assertions_total": total,
            "misses": total - supported,
            "unsupported_claims": unsupported,
            "correct_unknowns": sum(len(item["correct_unknowns"]) for item in results),
            "false_certainty": unsupported,
            "evidence_coverage": supported / total if total else 0.0,
            "deterministic": True,
            "execution_cost_ms": round(sum(costs), 3),
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--loadout-root", required=True)
    parser.add_argument("--repo", action="append", default=[])
    parser.add_argument("--corpus", default=str(DEFAULT_CORPUS))
    parser.add_argument("--lock", default=str(DEFAULT_LOCK))
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    try:
        loadout_root = Path(args.loadout_root).resolve()
        lock = read_json(Path(args.lock).resolve())
        assert_product_binding(loadout_root, lock)
        adapter = LoadoutRuntimeAdapter(loadout_root)
        real = evaluate_real_corpus(
            adapter,
            Path(args.corpus).resolve(),
            parse_repo_args(args.repo),
        )
        artifact = {
            "schema": "arsenal/repository-recon-productized-result/v1",
            "binding": lock,
            "adapter": {
                "id": adapter.name,
                "digest": file_digest(ROOT / "evaluation/adapters/loadout_runtime_adapter.py"),
            },
            "suite_digest": digest(read_json(Path(args.corpus).resolve())),
            "original_16": evaluate_original_16(adapter),
            "real_corpus": real,
        }
        stable = copy.deepcopy(artifact)
        stable["real_corpus"]["metrics"].pop("execution_cost_ms", None)
        artifact["result_digest"] = digest(stable)
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(artifact, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        metrics = real["metrics"]
        print(
            f"productized: original={artifact['original_16']['supported']}/"
            f"{artifact['original_16']['assertions']} real={metrics['supported_assertions']}/"
            f"{metrics['assertions_total']} false_certainty={metrics['false_certainty']}"
        )
        print(f"artifact: {out}")
        return 0
    except Exception as exc:
        print(f"productized bench: ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
