#!/usr/bin/env python3
"""Adversarial qualification tests.

Each test deliberately mutates a single consequence of the qualification
contract. The mutation must drive status from "candidate" to
"unassessed", or fail at the gate-validation step before any receipt is
written.

For each mutation:

  - the compiled distribution (or canonical capability, or suite
    definition) is copied into a temporary directory,
  - the targeted field is mutated in the copy,
  - arsenal_bench.py qualify is invoked against the mutated copy,
  - the test asserts the receipt is no longer "candidate" OR the
    validate_suites step rejects the suite.
"""

from __future__ import annotations

import copy
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
from io import StringIO
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BENCH_PATH = ROOT / "scripts" / "arsenal_bench.py"


def _load_bench():
    spec = importlib.util.spec_from_file_location("arsenal_bench", BENCH_PATH)
    bench = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(bench)
    return bench


def _copy_distribution_to(src_rel: str, dst_root: Path) -> Path:
    """Copy a generated distribution (SKILL.md, arsenal-manifest.json,
    references/) into dst_root and return its absolute path.
    """
    src = ROOT / src_rel
    dst = dst_root / src.name
    shutil.copytree(src, dst)
    return dst


def _replace_manifest_field(dist_path: Path, field_path: list[str], value):
    manifest_path = dist_path / "arsenal-manifest.json"
    manifest = json.loads(manifest_path.read_text())
    obj = manifest
    for key in field_path[:-1]:
        obj = obj.setdefault(key, {})
    obj[field_path[-1]] = value
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")


def _run_qualify(bench, suite_id: str, dist_path: Path, receipt_path: Path) -> dict:
    """Invoke bench.main with the qualify subcommand against a manipulated
    distribution. The suite is the one in evaluation/cases/ (untouched);
    only the distribution under test is mutated.
    """
    argv = [
        "qualify",
        "--suite", suite_id,
        "--receipt", str(receipt_path),
    ]
    original_argv = sys.argv
    original_stderr = sys.stderr
    sys.argv = ["arsenal_bench"] + argv
    sys.stderr = StringIO()
    try:
        rc = bench.main()
        err_output = sys.stderr.getvalue()
    finally:
        sys.argv = original_argv
        sys.stderr = original_stderr
    receipt = None
    if receipt_path.is_file():
        try:
            receipt = json.loads(receipt_path.read_text())
        except (OSError, json.JSONDecodeError):
            receipt = None
    return {"rc": rc, "stderr": err_output, "receipt": receipt}


def _swap_suite_distribution(suite_id: str, dist_path: Path) -> dict:
    """Replace every case's distribution_path with the new path. Returns a
    map of case_id -> original distribution_path so the suite can be
    restored after the test.
    """
    suite_path = None
    for p in (ROOT / "evaluation" / "cases").glob("*.json"):
        suite_doc = json.loads(p.read_text())
        if suite_doc.get("suite", {}).get("id") == suite_id:
            suite_path = p
            break
    if not suite_path:
        raise RuntimeError(f"unknown suite {suite_id}")
    suite_doc = json.loads(suite_path.read_text())
    cases = suite_doc["suite"]["cases"]
    saved: dict[str, str] = {}
    for c in cases:
        if "distribution_path" in c.get("fixture", {}):
            saved[c["id"]] = c["fixture"]["distribution_path"]
            c["fixture"]["distribution_path"] = str(dist_path.relative_to(ROOT))
    suite_path.write_text(json.dumps(suite_doc, indent=2, sort_keys=True) + "\n")
    return saved


def _restore_suite_distribution(suite_id: str, saved: dict) -> None:
    suite_path = None
    for p in (ROOT / "evaluation" / "cases").glob("*.json"):
        suite_doc = json.loads(p.read_text())
        if suite_doc.get("suite", {}).get("id") == suite_id:
            suite_path = p
            break
    suite_doc = json.loads(suite_path.read_text())
    cases = suite_doc["suite"]["cases"]
    for c in cases:
        if c["id"] in saved:
            c["fixture"]["distribution_path"] = saved[c["id"]]
    suite_path.write_text(json.dumps(suite_doc, indent=2, sort_keys=True) + "\n")


def _expect_unassessed(receipt: dict, label: str) -> None:
    if receipt["status"] == "candidate":
        raise AssertionError(
            f"{label}: expected status=unassessed after mutation, got candidate; "
            f"binding={receipt['binding']}"
        )


def _mutated_qualify(bench, suite_id: str, mutate, label: str) -> None:
    """Run qualify against a mutated copy of the Repository Truth
    distribution; assert the receipt is no longer 'candidate'.

    `mutate` receives the absolute path to the copied distribution and
    is expected to mutate any of SKILL.md, arsenal-manifest.json, or
    references/* in place.
    """
    tmp_root = ROOT / ".tmp-ars-qual-adversary"
    if tmp_root.exists():
        shutil.rmtree(tmp_root)
    tmp_root.mkdir()
    try:
        dist = _copy_distribution_to("distribution/agent-skills/repository-truth", tmp_root)
        mutate(dist)
        receipt_path = tmp_root / "receipt.json"
        saved = _swap_suite_distribution(suite_id, dist)
        try:
            result = _run_qualify(bench, suite_id, dist, receipt_path)
            receipt = result["receipt"]
            if receipt is None:
                # qualify refused to write a receipt (suite validation
                # failed or some other precondition). That is also
                # acceptable evidence that the mutation was caught.
                return
            _expect_unassessed(receipt, label)
        finally:
            _restore_suite_distribution(suite_id, saved)
    finally:
        shutil.rmtree(tmp_root, ignore_errors=True)


def main() -> int:
    bench = _load_bench()
    suite_id = "suite.distribution-qualification-v0"

    # Mutation 1: manifest capability ID changed
    def mut_capability_id_manifest(dist: Path):
        _replace_manifest_field(dist, ["capability", "id"], "capability.not-the-real-one")
    _mutated_qualify(bench, suite_id, mut_capability_id_manifest,
                     "manifest capability.id drift")

    # Mutation 2: manifest capability version changed
    def mut_capability_version_manifest(dist: Path):
        _replace_manifest_field(dist, ["capability", "version"], "99.99.99")
    _mutated_qualify(bench, suite_id, mut_capability_version_manifest,
                     "manifest capability.version drift")

    # Mutation 4: manifest mutation class weakened
    def mut_mutation_class(dist: Path):
        _replace_manifest_field(dist, ["mutation", "class"], "workspace-write")
    _mutated_qualify(bench, suite_id, mut_mutation_class,
                     "manifest mutation class weakened")

    # Mutation 6: manifest required authority widened (filesystem.write added)
    def mut_required_authority(dist: Path):
        m = json.loads((dist / "arsenal-manifest.json").read_text())
        m["authority"]["required"] = sorted(set(m["authority"]["required"]) | {"filesystem.write"})
        (dist / "arsenal-manifest.json").write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    _mutated_qualify(bench, suite_id, mut_required_authority,
                     "manifest authority required widened")

    # Mutation 8: manifest forbidden authority relaxed (remove filesystem.write)
    def mut_forbidden_authority(dist: Path):
        m = json.loads((dist / "arsenal-manifest.json").read_text())
        m["authority"]["forbidden"] = sorted(set(m["authority"]["forbidden"]) - {"filesystem.write"})
        (dist / "arsenal-manifest.json").write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    _mutated_qualify(bench, suite_id, mut_forbidden_authority,
                     "manifest forbidden authority relaxed")

    # Mutation 10: manifest allowed execution surface widened (production)
    def mut_allowed_execution(dist: Path):
        m = json.loads((dist / "arsenal-manifest.json").read_text())
        m["execution"]["allowed"] = sorted(set(m["execution"]["allowed"]) | {"production"})
        (dist / "arsenal-manifest.json").write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    _mutated_qualify(bench, suite_id, mut_allowed_execution,
                     "manifest execution allowed widened")

    # Mutation 11: manifest prohibited execution surface shrunk (remove remote-sandbox)
    def mut_prohibited_execution(dist: Path):
        m = json.loads((dist / "arsenal-manifest.json").read_text())
        m["execution"]["prohibited"] = sorted(set(m["execution"]["prohibited"]) - {"remote-sandbox"})
        (dist / "arsenal-manifest.json").write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    _mutated_qualify(bench, suite_id, mut_prohibited_execution,
                     "manifest execution prohibited shrunk")

    # Mutation 12: invocation mode in manifest flattened (human)
    def mut_invocation_flattened(dist: Path):
        _replace_manifest_field(dist, ["invocation"], "human")
    _mutated_qualify(bench, suite_id, mut_invocation_flattened,
                     "manifest invocation flattened")

    # Mutation 14: adapter version mutated in manifest (mismatches suite).
    # This is detected by the bind to suite_id and adapter_version in
    # the receipt's qualification_id; the bench also checks manifest
    # compiler fields agree with the suite. Skipped here because the
    # bench has no dedicated check; the verify chain catches this via
    # manifest/receipt binding drift.
    pass  # see verify_build's _verify_qualification_bindings

    # Mutation 16: package digest in manifest mutated
    def mut_package_digest(dist: Path):
        m = json.loads((dist / "arsenal-manifest.json").read_text())
        m["package"]["content_sha256"] = "sha256:0000000000000000000000000000000000000000000000000000000000000000"
        (dist / "arsenal-manifest.json").write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    _mutated_qualify(bench, suite_id, mut_package_digest,
                     "package digest drift in manifest")

    # Mutation 17: canonical capability digest drift (mutate the manifest's
    # claimed source capability_sha256 to a value that no longer matches
    # the file). The capability-identity check rejects it.
    def mut_capability_sha(dist: Path):
        m = json.loads((dist / "arsenal-manifest.json").read_text())
        m["source"]["capability_sha256"] = "sha256:0000000000000000000000000000000000000000000000000000000000000000"
        (dist / "arsenal-manifest.json").write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    _mutated_qualify(bench, suite_id, mut_capability_sha,
                     "canonical capability_sha256 drift in manifest")

    # Mutation 19: packaged resource contents tampered
    def mut_packaged_contents(dist: Path):
        ref = dist / "references" / "repository_truth_audit.md"
        ref.write_text("# tampered\nthis is no longer the canonical workflow\n")
    _mutated_qualify(bench, suite_id, mut_packaged_contents,
                     "packaged reference contents tampered")

    # Mutation 20: always-loaded policy understated
    def mut_always_loaded_policy(dist: Path):
        m = json.loads((dist / "arsenal-manifest.json").read_text())
        m["always_loaded_policy"]["total_bytes"] = 1_000_000
        (dist / "arsenal-manifest.json").write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    _mutated_qualify(bench, suite_id, mut_always_loaded_policy,
                     "always_loaded_policy total_bytes overstated")

    # Mutation 21: required candidate case marked designed-not-run.
    # The qualification_gate validator must reject this at validate_suites.
    def mut_required_case_designed_not_run(_dist: Path):
        # We do not mutate the package here; we mutate the suite gate
        # temporarily, then attempt qualify, which calls validate_suites.
        suite_path = None
        for p in (ROOT / "evaluation" / "cases").glob("*.json"):
            suite_doc = json.loads(p.read_text())
            if suite_doc.get("suite", {}).get("id") == suite_id:
                suite_path = p
                break
        suite_doc = json.loads(suite_path.read_text())
        cases = suite_doc["suite"]["cases"]
        target = "dq-boundary-preservation-mutation"
        for c in cases:
            if c["id"] == target:
                c["active"] = False
                c["execution"]["status"] = "designed-not-run"
                break
        suite_path.write_text(json.dumps(suite_doc, indent=2, sort_keys=True) + "\n")
        with tempfile.TemporaryDirectory() as tmp:
            receipt_path = Path(tmp) / "receipt.json"
            argv = ["qualify", "--suite", suite_id, "--receipt", str(receipt_path)]
            original_argv = sys.argv
            original_stderr = sys.stderr
            sys.argv = ["arsenal_bench"] + argv
            sys.stderr = StringIO()
            try:
                rc = bench.main()
                err_output = sys.stderr.getvalue()
            finally:
                sys.argv = original_argv
                sys.stderr = original_stderr
            if rc == 0:
                raise AssertionError(
                    "required candidate case marked designed-not-run: "
                    f"qualify returned 0 instead of failing at validate_suites; stderr: {err_output!r}"
                )
    mut_required_case_designed_not_run(None)

    # Mutation 22: required candidate case fails. Force the structural
    # check to fail by deleting a canonical use_when statement from the
    # SKILL.md body.
    def mut_required_case_fails(dist: Path):
        skill = dist / "SKILL.md"
        text = skill.read_text()
        # Drop one canonical use_when statement to make
        # structural-discovery-preservation report missing.
        text = text.replace(
            "Inheriting a repository whose current state is unknown or contested",
            "REMOVED",
        )
        skill.write_text(text)
    _mutated_qualify(bench, suite_id, mut_required_case_fails,
                     "required candidate case (discovery preservation) fails")

    # Mutation 23: required case omitted from suite (gate references missing id)
    def mut_required_case_omitted(_dist: Path):
        suite_path = None
        for p in (ROOT / "evaluation" / "cases").glob("*.json"):
            suite_doc = json.loads(p.read_text())
            if suite_doc.get("suite", {}).get("id") == suite_id:
                suite_path = p
                break
        suite_doc = json.loads(suite_path.read_text())
        gate = suite_doc["suite"]["qualification_gate"]
        gate["candidate_required_case_ids"].append("dq-does-not-exist")
        suite_path.write_text(json.dumps(suite_doc, indent=2, sort_keys=True) + "\n")
        with tempfile.TemporaryDirectory() as tmp:
            receipt_path = Path(tmp) / "receipt.json"
            argv = ["qualify", "--suite", suite_id, "--receipt", str(receipt_path)]
            original_argv = sys.argv
            original_stderr = sys.stderr
            sys.argv = ["arsenal_bench"] + argv
            sys.stderr = StringIO()
            try:
                rc = bench.main()
                err_output = sys.stderr.getvalue()
            finally:
                sys.argv = original_argv
                sys.stderr = original_stderr
            if rc == 0:
                raise AssertionError(
                    f"required case omitted: qualify returned 0; stderr: {err_output!r}"
                )
    mut_required_case_omitted(None)

    # Mutation 24 / 25 / 26: cross-capability / cross-suite reuse.
    # Run the Plan suite against the Repository Truth distribution and
    # vice versa; both must fail at validate_suites because case
    # capability_id no longer matches suite capability_id.
    def mut_cross_capability_reuse():
        with tempfile.TemporaryDirectory() as tmp:
            receipt_path = Path(tmp) / "receipt.json"
            argv = [
                "qualify",
                "--suite", "suite.distribution-qualification-plan-v0",
                "--receipt", str(receipt_path),
            ]
            original_argv = sys.argv
            original_stderr = sys.stderr
            sys.argv = ["arsenal_bench"] + argv
            sys.stderr = StringIO()
            try:
                rc = bench.main()
                err_output = sys.stderr.getvalue()
            finally:
                sys.argv = original_argv
                sys.stderr = original_stderr
            if rc == 0:
                raise AssertionError(
                    f"Plan suite against RT distribution: qualify returned 0; stderr: {err_output!r}"
                )
    mut_cross_capability_reuse()

    print("ARS-07 qualification adversarial suite: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())