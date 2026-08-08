#!/usr/bin/env python3
"""Negative-contract tests for Arsenal Capability Contract v2."""

from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT_PATH = ROOT / "scripts" / "capability_audit.py"
spec = importlib.util.spec_from_file_location("capability_audit", AUDIT_PATH)
audit = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(audit)


def load_fragments(directory: Path):
    return {p.name: json.loads(p.read_text()) for p in directory.glob("*.json")}


def write_fragments(directory: Path, docs):
    for name, doc in docs.items():
        (directory / name).write_text(json.dumps(doc, indent=2) + "\n")


def expect_failure(name: str, mutate, needle: str) -> None:
    source = ROOT / "arsenal" / "capabilities"
    with tempfile.TemporaryDirectory() as tmp:
        directory = Path(tmp) / "capabilities"
        directory.mkdir()
        docs = load_fragments(source)
        mutate(docs)
        write_fragments(directory, docs)
        _, errors = audit.validate_repository(ROOT, directory)
        joined = "\n".join(errors)
        if not errors:
            raise AssertionError(f"{name}: invalid fixture unexpectedly passed")
        if needle not in joined:
            raise AssertionError(f"{name}: expected {needle!r} in errors, got:\n{joined}")
        print(f"PASS negative case: {name}")


def main() -> int:
    capabilities, errors = audit.validate_repository(ROOT)
    if errors:
        raise AssertionError("valid capability set failed:\n" + "\n".join(errors))
    if len(capabilities) < 9:
        raise AssertionError("expected at least nine ARS-01 capabilities")
    print("PASS valid capability set")

    expect_failure(
        "duplicate public alias",
        lambda d: d["pressure-test.json"]["capability"]["aliases"].append("Recon"),
        "public name/alias collision",
    )

    expect_failure(
        "missing implementation asset",
        lambda d: d["repository-truth.json"]["capability"]["implementation"]["asset_ids"].append("missing.asset"),
        "unknown registered asset missing.asset in implementation",
    )

    def overlap_authority(docs):
        cap = docs["tdd.json"]["capability"]
        cap["authority"]["optional"].append("filesystem.read")

    expect_failure("overlapping authority", overlap_authority, "authority sets overlap")

    def readonly_write(docs):
        cap = docs["review.json"]["capability"]
        cap["authority"]["forbidden"].remove("filesystem.write")
        cap["authority"]["required"].append("filesystem.write")

    expect_failure("read-only write authority", readonly_write, "read-only capability requires write authority")

    def invalid_substrate(docs):
        docs["tdd.json"]["capability"]["execution"]["preferred"].append("production")

    expect_failure("preferred substrate not allowed", invalid_substrate, "preferred execution substrate must be allowed")

    def harness_leak(docs):
        docs["repository-truth.json"]["capability"]["compatibility"]["notes"] += " Codex adapter detail."

    expect_failure("harness leakage", harness_leak, "harness-specific marker leaked")

    def stable_without_evidence(docs):
        docs["tdd.json"]["capability"]["lifecycle"] = "stable"

    expect_failure("stable without evaluation", stable_without_evidence, "stable capability requires qualified evaluation evidence")

    print("Capability Contract negative suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
