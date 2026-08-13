#!/usr/bin/env python3
"""Wave 5 real-repository Repository Recon benchmark.

The evaluator is deterministic and output-driven. It validates every emitted
factual claim against the pinned repository before scoring it. Holdout oracle
loading is forbidden until a winner lock binds a method and implementation
digest.
"""

from __future__ import annotations

import argparse
import copy
import glob
import hashlib
import json
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
WAVE5 = ROOT / "evaluation" / "wave5"
DEFAULT_CORPUS = WAVE5 / "benchmark" / "corpus.v1.json"
BASELINE_METHOD = "repository-recon/loadout-runtime-baseline"

sys.path.insert(0, str(ROOT))
from evaluation.adapters.loadout_runtime_adapter import LoadoutRuntimeAdapter  # noqa: E402
from evaluation.wave5.candidates import (  # noqa: E402
    CANDIDATES,
    method_implementation_digest,
)


def canonical(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")


def digest(value: Any) -> str:
    return "sha256:" + hashlib.sha256(canonical(value)).hexdigest()


def read_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {path}")
    return value


def parse_repo_args(values: list[str]) -> dict[str, Path]:
    repos: dict[str, Path] = {}
    for value in values:
        if "=" not in value:
            raise ValueError(f"--repo must be ID=PATH, got {value!r}")
        repo_id, raw_path = value.split("=", 1)
        repos[repo_id] = Path(raw_path).resolve()
    return repos


def git_head(repo: Path) -> str:
    return subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def claim_key(claim_type: str, expected: dict[str, Any]) -> str:
    return json.dumps([claim_type, expected], sort_keys=True, separators=(",", ":"))


def pointer_value(document: Any, pointer: str) -> Any:
    current = document
    if pointer == "":
        return current
    for token in pointer.split("/")[1:]:
        token = token.replace("~1", "/").replace("~0", "~")
        if isinstance(current, list):
            current = current[int(token)]
        elif isinstance(current, dict):
            current = current[token]
        else:
            raise KeyError(pointer)
    return current


def factual_claim_is_true(repo: Path, claim: dict[str, Any]) -> bool:
    claim_type = claim["claim_type"]
    expected = claim["expected"]
    try:
        if claim_type == "path_presence":
            return (repo / expected["path"].rstrip("/")).exists()
        if claim_type == "path_absence":
            return not (repo / expected["path"].rstrip("/")).exists()
        if claim_type == "glob_presence":
            matches = glob.glob(str(repo / expected["pattern"]), recursive=True)
            return len(matches) >= int(expected["minimum"])
        if claim_type == "json_value":
            document = json.loads((repo / expected["path"]).read_text(encoding="utf-8"))
            return pointer_value(document, expected["pointer"]) == expected["value"]
        if claim_type == "text_reference":
            text = (repo / expected["source"]).read_text(encoding="utf-8")
            return expected["target"] in text and (repo / expected["target"]).exists()
        if claim_type == "text_contains":
            text = (repo / expected["path"]).read_text(encoding="utf-8")
            return expected["text"] in text
        if claim_type == "unknown":
            subject = expected["subject"]
            if subject == "primary_runtime":
                manifests = ("package.json", "pyproject.toml", "mix.exs", "Cargo.toml", "go.mod")
                return not any((repo / item).is_file() for item in manifests)
            if subject == "governance_authority":
                return not (repo / "AGENTS.md").is_file() and not (repo / "CLAUDE.md").is_file()
            return False
    except (OSError, UnicodeDecodeError, json.JSONDecodeError, KeyError, ValueError, IndexError):
        return False
    return False


def baseline_claims(repo: Path, loadout_root: Path) -> list[dict[str, Any]]:
    findings = LoadoutRuntimeAdapter(loadout_root).run(repo)
    claims: list[dict[str, Any]] = []
    for finding in findings:
        if finding.get("actual") is True:
            evidence = str(finding["evidence"])
            claims.append(
                {
                    "claim_type": "path_presence",
                    "expected": {"path": evidence},
                    "evidence_sources": [evidence],
                    "certainty": "observed",
                }
            )
    by_key = {
        claim_key(claim["claim_type"], claim["expected"]): claim for claim in claims
    }
    return [by_key[key] for key in sorted(by_key)]


def run_method(method_id: str, repo: Path, loadout_root: Path | None) -> list[dict[str, Any]]:
    if method_id == BASELINE_METHOD:
        if loadout_root is None:
            raise ValueError("baseline method requires --loadout-root")
        return baseline_claims(repo, loadout_root)
    try:
        method = CANDIDATES[method_id]
    except KeyError as exc:
        raise ValueError(f"unknown method {method_id!r}") from exc
    return method(repo)


def implementation_digest(method_id: str, loadout_root: Path | None) -> str:
    if method_id == BASELINE_METHOD:
        if loadout_root is None:
            raise ValueError("baseline method requires --loadout-root")
        source = loadout_root / "src" / "packs" / "repository-recon" / "run.ts"
        return "sha256:" + hashlib.sha256(source.read_bytes()).hexdigest()
    return method_implementation_digest(method_id)


def score_repository(
    repo_meta: dict[str, Any],
    repo: Path,
    oracle: dict[str, Any],
    claims: list[dict[str, Any]],
) -> dict[str, Any]:
    expected_by_key = {
        claim_key(assertion["claim_type"], assertion["expected"]): assertion
        for assertion in oracle["assertions"]
    }
    claims_by_key = {
        claim_key(claim["claim_type"], claim["expected"]): claim for claim in claims
    }
    supported: list[str] = []
    misses: list[str] = []
    correct_unknowns: list[str] = []
    for key, assertion in expected_by_key.items():
        claim = claims_by_key.get(key)
        if claim is not None and factual_claim_is_true(repo, claim):
            supported.append(assertion["id"])
            if assertion["claim_type"] == "unknown":
                correct_unknowns.append(assertion["id"])
        else:
            misses.append(assertion["id"])

    invalid_claims = [
        claim for claim in claims if not factual_claim_is_true(repo, claim)
    ]
    total = len(expected_by_key)
    return {
        "repository_id": repo_meta["id"],
        "role": repo_meta["role"],
        "commit": repo_meta["commit"],
        "assertions_total": total,
        "supported_assertions": supported,
        "supported_count": len(supported),
        "misses": misses,
        "miss_count": len(misses),
        "correct_unknowns": correct_unknowns,
        "unsupported_claims": invalid_claims,
        "unsupported_claim_count": len(invalid_claims),
        "false_certainty": len(invalid_claims),
        "evidence_coverage": len(supported) / total if total else 0.0,
        "claim_count": len(claims),
        "claims_digest": digest(claims),
    }


def selected_repositories(corpus: dict[str, Any], phase: str) -> list[dict[str, Any]]:
    roles = {
        "development": {"development"},
        "validation": {"validation"},
        "holdout": {"holdout"},
        "selection": {"development", "validation"},
        "all": {"development", "validation", "holdout"},
    }[phase]
    return [repo for repo in corpus["repositories"] if repo["role"] in roles]


def verify_holdout_lock(lock_path: Path, method_id: str, method_digest: str) -> None:
    if not lock_path.is_file():
        raise ValueError("holdout is sealed: winner lock does not exist")
    lock = read_json(lock_path)
    if method_id == BASELINE_METHOD:
        return
    if lock.get("method_id") != method_id or lock.get("implementation_digest") != method_digest:
        raise ValueError("holdout is sealed: winner lock does not match method and implementation digest")


def evaluate(args: argparse.Namespace) -> dict[str, Any]:
    corpus_path = Path(args.corpus).resolve()
    corpus = read_json(corpus_path)
    repo_paths = parse_repo_args(args.repo)
    loadout_root = Path(args.loadout_root).resolve() if args.loadout_root else None
    method_digest = implementation_digest(args.method, loadout_root)
    if args.phase in {"holdout", "all"}:
        verify_holdout_lock(Path(args.winner_lock).resolve(), args.method, method_digest)

    results: list[dict[str, Any]] = []
    costs: list[float] = []
    for repo_meta in selected_repositories(corpus, args.phase):
        repo_id = repo_meta["id"]
        if repo_id not in repo_paths:
            raise ValueError(f"missing --repo {repo_id}=PATH")
        repo = repo_paths[repo_id]
        if git_head(repo) != repo_meta["commit"]:
            raise ValueError(
                f"{repo_id} HEAD does not match corpus commit: {git_head(repo)} != {repo_meta['commit']}"
            )
        oracle_path = corpus_path.parent / repo_meta["oracle"]
        oracle = read_json(oracle_path)
        start = time.perf_counter()
        first = run_method(args.method, repo, loadout_root)
        costs.append((time.perf_counter() - start) * 1000)
        second = run_method(args.method, repo, loadout_root)
        if canonical(first) != canonical(second):
            raise ValueError(f"method output is nondeterministic for {repo_id}")
        results.append(score_repository(repo_meta, repo, oracle, first))

    supported = sum(item["supported_count"] for item in results)
    total = sum(item["assertions_total"] for item in results)
    unsupported = sum(item["unsupported_claim_count"] for item in results)
    artifact = {
        "schema": "arsenal/repository-recon-benchmark-result/v1",
        "phase": args.phase,
        "method_id": args.method,
        "implementation_digest": method_digest,
        "corpus_digest": digest(corpus),
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
    digest_payload = copy.deepcopy(artifact)
    digest_payload["metrics"].pop("execution_cost_ms", None)
    artifact["result_digest"] = digest(digest_payload)
    return artifact


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--corpus", default=str(DEFAULT_CORPUS))
    parser.add_argument("--phase", choices=("development", "validation", "selection", "holdout", "all"), required=True)
    parser.add_argument("--method", required=True)
    parser.add_argument("--repo", action="append", default=[])
    parser.add_argument("--loadout-root")
    parser.add_argument("--winner-lock", default=str(WAVE5 / "winner-lock.v1.json"))
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    try:
        artifact = evaluate(args)
        out = Path(args.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(artifact, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        metrics = artifact["metrics"]
        print(
            f"wave5 recon bench: method={args.method} phase={args.phase} "
            f"supported={metrics['supported_assertions']}/{metrics['assertions_total']} "
            f"false_certainty={metrics['false_certainty']} deterministic=true"
        )
        print(f"artifact: {out}")
        return 0
    except Exception as exc:
        print(f"wave5 recon bench: ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
