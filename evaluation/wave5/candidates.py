"""Genuinely distinct deterministic Repository Recon candidate strategies.

These are Arsenal research implementations. Normal Loadout operation never
imports or executes this module. Each strategy emits a small, evidence-bound
claim vocabulary consumed by the Wave 5 evaluator.
"""

from __future__ import annotations

import glob
import json
import re
import subprocess
from pathlib import Path
from typing import Any, Callable


TOPOLOGY_METHOD = "repository-recon/topology-inventory"
MANIFEST_METHOD = "repository-recon/structured-manifest"
GOVERNANCE_METHOD = "repository-recon/governance-graph"
STAGED_METHOD = "repository-recon/staged-evidence-graph"

STANDARD_PATHS = (
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "package.json",
    "pyproject.toml",
    "mix.exs",
    "Cargo.toml",
    "go.mod",
    "src/",
    "lib/",
    "test/",
    "tests/",
    ".github/workflows/",
    "engineering/",
    "arsenal/capabilities/",
    "evaluation/method-records/",
)

COMMON_GLOBS = (
    "scripts/*.py",
    ".github/workflows/*.yml",
    ".github/workflows/*.yaml",
    "tests/**/*.ts",
    "test/**/*.exs",
)

ROOT_MANIFESTS = (
    "package.json",
    "arsenal.project.json",
    "pyproject.toml",
    "mix.exs",
    "Cargo.toml",
    "go.mod",
)

RUNTIME_MANIFESTS = (
    "package.json",
    "pyproject.toml",
    "mix.exs",
    "Cargo.toml",
    "go.mod",
)

GOVERNANCE_SOURCES = (
    "AGENTS.md",
    "CLAUDE.md",
    "README.md",
    "CONTRIBUTING.md",
)


def _claim(claim_type: str, expected: dict[str, Any], *evidence: str) -> dict[str, Any]:
    return {
        "claim_type": claim_type,
        "expected": expected,
        "evidence_sources": list(evidence),
        "certainty": "observed" if claim_type != "unknown" else "unknown",
    }


def _claim_key(claim: dict[str, Any]) -> str:
    return json.dumps(
        [claim["claim_type"], claim["expected"]],
        sort_keys=True,
        separators=(",", ":"),
    )


def _dedupe(claims: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_key = {_claim_key(claim): claim for claim in claims}
    return [by_key[key] for key in sorted(by_key)]


def _tracked_files(repo: Path) -> list[str]:
    completed = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "-z"],
        capture_output=True,
        check=False,
    )
    if completed.returncode == 0:
        return sorted(
            item.decode("utf-8")
            for item in completed.stdout.split(b"\0")
            if item
        )
    return sorted(
        str(path.relative_to(repo))
        for path in repo.rglob("*")
        if path.is_file() and ".git" not in path.parts
    )


def topology_inventory(repo: Path) -> list[dict[str, Any]]:
    claims: list[dict[str, Any]] = []
    files = _tracked_files(repo)
    directories: set[str] = set()
    for relative in files:
        if not (repo / relative).exists():
            # A gitlink can be tracked without being materialized in the
            # checkout. Do not strengthen repository metadata into filesystem
            # presence.
            continue
        claims.append(_claim("path_presence", {"path": relative}, relative))
        parent = Path(relative).parent
        while str(parent) != ".":
            directories.add(f"{parent.as_posix()}/")
            parent = parent.parent
    for directory in sorted(directories):
        claims.append(_claim("path_presence", {"path": directory}, directory))

    for relative in STANDARD_PATHS:
        target = repo / relative.rstrip("/")
        claim_type = "path_presence" if target.exists() else "path_absence"
        claims.append(_claim(claim_type, {"path": relative}, relative))

    for pattern in COMMON_GLOBS:
        matches = sorted(glob.glob(str(repo / pattern), recursive=True))
        if matches:
            evidence = [str(Path(item).relative_to(repo)) for item in matches]
            claims.append(
                _claim(
                    "glob_presence",
                    {"pattern": pattern, "minimum": 1},
                    *evidence,
                )
            )

    if not any((repo / manifest).is_file() for manifest in RUNTIME_MANIFESTS):
        claims.append(
            _claim(
                "unknown",
                {"subject": "primary_runtime"},
                *RUNTIME_MANIFESTS,
            )
        )
    if not (repo / "AGENTS.md").is_file() and not (repo / "CLAUDE.md").is_file():
        claims.append(
            _claim(
                "unknown",
                {"subject": "governance_authority"},
                "AGENTS.md",
                "CLAUDE.md",
            )
        )
    return _dedupe(claims)


def _json_pointer_tokens(pointer: str) -> list[str]:
    return [token.replace("~1", "/").replace("~0", "~") for token in pointer.split("/")[1:]]


def _walk_json(value: Any, pointer: str = "") -> list[tuple[str, Any]]:
    if isinstance(value, dict):
        out: list[tuple[str, Any]] = []
        for key in sorted(value):
            escaped = key.replace("~", "~0").replace("/", "~1")
            out.extend(_walk_json(value[key], f"{pointer}/{escaped}"))
        return out
    if isinstance(value, list):
        out = []
        for index, item in enumerate(value):
            out.extend(_walk_json(item, f"{pointer}/{index}"))
        return out
    return [(pointer, value)]


def structured_manifest(repo: Path) -> list[dict[str, Any]]:
    claims: list[dict[str, Any]] = []
    files = _tracked_files(repo)
    json_paths = [relative for relative in files if relative.endswith(".json")]
    for relative in json_paths:
        path = repo / relative
        try:
            if path.stat().st_size > 2_000_000:
                continue
            parsed = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError):
            continue
        claims.append(_claim("path_presence", {"path": relative}, relative))
        for pointer, value in _walk_json(parsed):
            if isinstance(value, (str, int, float, bool)) or value is None:
                claims.append(
                    _claim(
                        "json_value",
                        {"path": relative, "pointer": pointer, "value": value},
                        f"{relative}#{pointer}",
                    )
                )

    for relative in ("mix.exs", "Cargo.toml", "pyproject.toml", "go.mod"):
        path = repo / relative
        if not path.is_file():
            continue
        claims.append(_claim("path_presence", {"path": relative}, relative))
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeDecodeError):
            continue
        for line in lines:
            text = line.strip()
            if not text or text.startswith(("#", "//")) or len(text) > 200:
                continue
            claims.append(
                _claim(
                    "text_contains",
                    {"path": relative, "text": text},
                    relative,
                )
            )
            for pattern in (r"\bapp:\s*:[a-zA-Z0-9_]+", r'\belixir:\s*"[^"]+"'):
                match = re.search(pattern, text)
                if match:
                    normalized = match.group(0)
                    claims.append(
                        _claim(
                            "text_contains",
                            {"path": relative, "text": normalized},
                            relative,
                        )
                    )
    return _dedupe(claims)


def _reference_tokens(text: str) -> set[str]:
    tokens: set[str] = set()
    tokens.update(re.findall(r"`([^`\n]+)`", text))
    tokens.update(re.findall(r"\]\(([^)\s]+)\)", text))
    tokens.update(re.findall(r"(?m)^@([A-Za-z0-9_.\-/]+)\s*$", text))
    return {
        token.strip().lstrip("./")
        for token in tokens
        if "/" in token or token.endswith((".md", ".json", ".yaml", ".yml"))
    }


def governance_graph(repo: Path) -> list[dict[str, Any]]:
    claims: list[dict[str, Any]] = []
    for relative in GOVERNANCE_SOURCES:
        path = repo / relative
        if not path.is_file():
            continue
        claims.append(_claim("path_presence", {"path": relative}, relative))
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        for target in sorted(_reference_tokens(text)):
            if (repo / target).exists() and target in text:
                claims.append(
                    _claim(
                        "text_reference",
                        {"source": relative, "target": target},
                        relative,
                        target,
                    )
                )
    if not (repo / "AGENTS.md").is_file() and not (repo / "CLAUDE.md").is_file():
        claims.append(
            _claim(
                "unknown",
                {"subject": "governance_authority"},
                "AGENTS.md",
                "CLAUDE.md",
            )
        )
    return _dedupe(claims)


def staged_evidence_graph(repo: Path) -> list[dict[str, Any]]:
    return _dedupe(
        topology_inventory(repo) + structured_manifest(repo) + governance_graph(repo)
    )


CANDIDATES: dict[str, Callable[[Path], list[dict[str, Any]]]] = {
    TOPOLOGY_METHOD: topology_inventory,
    MANIFEST_METHOD: structured_manifest,
    GOVERNANCE_METHOD: governance_graph,
    STAGED_METHOD: staged_evidence_graph,
}


def method_implementation_digest(method_id: str) -> str:
    import hashlib

    source = Path(__file__).read_bytes()
    return "sha256:" + hashlib.sha256(method_id.encode("utf-8") + b"\0" + source).hexdigest()
