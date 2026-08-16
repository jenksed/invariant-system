#!/usr/bin/env python3
"""Score a Wave 5 candidate against the frozen original 16 assertions."""

from __future__ import annotations

import argparse
import glob
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from evaluation.wave5.candidates import CANDIDATES, method_implementation_digest  # noqa: E402

DEFAULT_CORPUS = ROOT / "evaluation" / "method-cases" / "corpus.manifest.json"


def canonical(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":")).encode("utf-8")


def claim_key(claim_type: str, expected: dict[str, Any]) -> str:
    return json.dumps([claim_type, expected], sort_keys=True, separators=(",", ":"))


def pointer_value(document: Any, pointer: str) -> Any:
    current = document
    for token in pointer.split("/")[1:]:
        token = token.replace("~1", "/").replace("~0", "~")
        current = current[int(token)] if isinstance(current, list) else current[token]
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
            return len(glob.glob(str(repo / expected["pattern"]), recursive=True)) >= int(expected["minimum"])
        if claim_type == "json_value":
            document = json.loads((repo / expected["path"]).read_text(encoding="utf-8"))
            return pointer_value(document, expected["pointer"]) == expected["value"]
        if claim_type == "text_reference":
            text = (repo / expected["source"]).read_text(encoding="utf-8")
            return expected["target"] in text and (repo / expected["target"]).exists()
        if claim_type == "text_contains":
            return expected["text"] in (repo / expected["path"]).read_text(encoding="utf-8")
        if claim_type == "unknown":
            if expected["subject"] == "primary_runtime":
                manifests = ("package.json", "pyproject.toml", "mix.exs", "Cargo.toml", "go.mod")
                return not any((repo / item).is_file() for item in manifests)
            if expected["subject"] == "governance_authority":
                return not (repo / "AGENTS.md").is_file() and not (repo / "CLAUDE.md").is_file()
    except (OSError, UnicodeDecodeError, json.JSONDecodeError, KeyError, ValueError, IndexError):
        return False
    return False


def candidate_supports(assertion: dict[str, Any], claims: dict[str, dict[str, Any]]) -> bool:
    kind = assertion["kind"]
    evidence = assertion["evidence_path"]
    if kind == "presence":
        return claim_key("path_presence", {"path": evidence}) in claims
    if kind == "absence":
        return claim_key("path_absence", {"path": evidence}) in claims
    if kind == "capability_identity":
        expected = {
            "/capability/id": assertion["expected_id"],
            "/capability/lifecycle": assertion["expected_lifecycle"],
            "/capability/evaluation/status": assertion["expected_evaluation_status"],
        }
        return all(
            claim_key(
                "json_value",
                {"path": evidence, "pointer": pointer, "value": value},
            )
            in claims
            for pointer, value in expected.items()
        )
    return False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--method", required=True, choices=sorted(CANDIDATES))
    parser.add_argument("--corpus", default=str(DEFAULT_CORPUS))
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    corpus_path = Path(args.corpus).resolve()
    manifest = json.loads(corpus_path.read_text(encoding="utf-8"))
    method = CANDIDATES[args.method]
    case_results: list[dict[str, Any]] = []
    all_first_outputs: list[list[dict[str, Any]]] = []
    supported_total = 0
    total = 0
    invalid_claims_total = 0

    for case in manifest["corpus"]["cases"]:
        case_root = ROOT / case["path"]
        repo = case_root / "repo"
        expected = json.loads((case_root / "expected.json").read_text(encoding="utf-8"))
        first = method(repo)
        second = method(repo)
        if canonical(first) != canonical(second):
            raise ValueError(f"candidate is nondeterministic for {case['id']}")
        all_first_outputs.append(first)
        invalid_claims_total += sum(not factual_claim_is_true(repo, claim) for claim in first)
        claims = {
            claim_key(claim["claim_type"], claim["expected"]): claim for claim in first
        }
        supported: list[str] = []
        misses: list[str] = []
        for assertion in expected["expected_assertions"]:
            total += 1
            if candidate_supports(assertion, claims):
                supported.append(assertion["id"])
                supported_total += 1
            else:
                misses.append(assertion["id"])
        case_results.append(
            {
                "case_id": case["id"],
                "supported": supported,
                "misses": misses,
            }
        )

    output_digest = "sha256:" + hashlib.sha256(canonical(all_first_outputs)).hexdigest()
    artifact = {
        "schema": "arsenal/repository-recon-original-16-result/v1",
        "method_id": args.method,
        "implementation_digest": method_implementation_digest(args.method),
        "corpus": manifest["corpus"]["id"],
        "metrics": {
            "supported": supported_total,
            "assertions": total,
            "misses": total - supported_total,
            "unsupported_factual_claims": invalid_claims_total,
            "deterministic": True,
        },
        "case_results": case_results,
        "candidate_output_digest": output_digest,
    }
    artifact["result_digest"] = "sha256:" + hashlib.sha256(canonical(artifact)).hexdigest()
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(artifact, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(
        f"original-16: method={args.method} supported={supported_total}/{total} "
        f"unsupported_factual_claims={invalid_claims_total} deterministic=true"
    )
    print(f"artifact: {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
