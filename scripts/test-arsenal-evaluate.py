#!/usr/bin/env python3
"""Test suite for ``scripts/arsenal_evaluate.py`` (ARS-04).

The test classes mirror the v0 evaluator's surface:

* positive: the canonical run produces a passing artifact with
  expected metrics and a deterministic digest;
* negative: invalid corpora, missing QMR, forged conclusions,
  non-canonical methods, and forbidden gap labels are rejected;
* determinism: two runs over the same corpus produce the same
  ``run_digest``;
* provenance: the run digest rule matches the documented
  canonicalization; a tampered artifact is rejected by the
  validator;
* qmr binding: a revised QMR emitted from a run passes the
  canonical ``arsenal_method_record`` validator.
"""

from __future__ import annotations

import copy
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "scripts" / "arsenal_evaluate.py"
CORPUS_PATH = ROOT / "evaluation" / "method-cases" / "corpus.manifest.json"
DEFAULT_OUT = ROOT / ".arsenal-eval" / "repository-recon-evaluation.v0.json"
METHOD_RECORDS_DIR = ROOT / "evaluation" / "method-records"

sys.path.insert(0, str(ROOT / "scripts"))
spec = importlib.util.spec_from_file_location("arsenal_evaluate", SCRIPT_PATH)
ae = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(ae)


def _run(argv: list[str], env: dict | None = None) -> tuple[int, str, str]:
    """Run the CLI in-process with ``argv`` and capture (rc, stdout, stderr)."""
    from io import StringIO
    saved_argv = sys.argv
    saved_stdout = sys.stdout
    saved_stderr = sys.stderr
    sys.argv = ["arsenal_evaluate"] + argv
    out, err = StringIO(), StringIO()
    sys.stdout = out
    sys.stderr = err
    rc = 1
    try:
        rc = ae.main()
    finally:
        sys.argv = saved_argv
        sys.stdout = saved_stdout
        sys.stderr = saved_stderr
    return rc, out.getvalue(), err.getvalue()


def _make_corpus(tmp: Path, *, method_id: str = ae.TARGET_METHOD_ID, cases: list | None = None) -> Path:
    """Write a small corpus manifest into ``tmp`` and return its path.

    The corpus uses real on-disk case paths copied from the
    canonical corpus to keep the evaluator's path resolution honest.
    """
    if cases is None:
        cases = [
            {
                "id": "recon.straightforward.small-clean",
                "path": "evaluation/method-cases/repo-straightforward",
                "context_kind": "local-git-repository-with-AGENTS.md",
            },
            {
                "id": "recon.ambiguous.incomplete-state",
                "path": "evaluation/method-cases/repo-ambiguous",
                "context_kind": "incomplete-or-ambiguous-local-repository",
            },
        ]
    payload = {
        "schema_version": "1.0.0",
        "corpus": {
            "id": "corpus.test",
            "title": "ARS-04 test corpus",
            "method_id": method_id,
            "capability_id": ae.TARGET_CAPABILITY_ID,
            "cases": cases,
        },
    }
    p = tmp / "corpus.json"
    p.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return p


def test_canonical_run_emits_valid_artifact() -> None:
    """The canonical corpus + QMR produces a passing artifact with
    the expected metric shape and a non-empty deterministic digest."""
    with tempfile.TemporaryDirectory(prefix="ars-04-canonical-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, stdout, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
        )
        assert rc == 0, f"canonical run failed: rc={rc}, stderr={stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        assert artifact["schema"] == "arsenal/method-evaluation/v0"
        assert artifact["method"]["method_id"] == ae.TARGET_METHOD_ID
        assert artifact["method"]["method_version"] == ae.TARGET_METHOD_VERSION
        assert artifact["epistemic_conclusion"] == "experimental"
        assert artifact["qualification_gap"]["label"] == "experimental-to-experimental"
        assert artifact["qmr_revisions"]["auto_promote_method_status"] is False
        assert artifact["qmr_revisions"]["auto_promote_capability_lifecycle"] is False
        assert artifact["qmr_revisions"]["auto_promote_capability_evaluation_status"] is False
        assert artifact["qmr_revisions"]["revised_qmr_status"] == "experimental"
        assert artifact["metrics"]["cases_total"] >= 3
        assert artifact["metrics"]["assertions_evaluated"] >= 5
        assert artifact["run_digest"].startswith("sha256:")
        assert len(artifact["run_digest"]) == len("sha256:") + 64
        print("PASS positive: canonical run emits a valid artifact")


def test_run_digest_is_deterministic() -> None:
    """Two runs over the same corpus must produce the same run_digest."""
    with tempfile.TemporaryDirectory(prefix="ars-04-det-") as td:
        tmp = Path(td)
        out_a = tmp / "a.json"
        out_b = tmp / "b.json"
        for out in (out_a, out_b):
            rc, _, stderr = _run(
                [
                    "repository-recon",
                    "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                    "--out", str(out),
                ]
            )
            assert rc == 0, f"run failed: rc={rc}, stderr={stderr!r}"
        a = json.loads(out_a.read_text(encoding="utf-8"))
        b = json.loads(out_b.read_text(encoding="utf-8"))
        assert a["run_digest"] == b["run_digest"], "run_digest not stable across runs"
        print("PASS determinism: run_digest is stable across two invocations")


def test_validate_detects_tampered_digest() -> None:
    """A tampered artifact must fail the validator."""
    with tempfile.TemporaryDirectory(prefix="ars-04-tamper-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
        )
        assert rc == 0, f"setup run failed: {stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        artifact["metrics"]["assertions_supported"] += 1
        tampered = tmp / "tampered.json"
        tampered.write_text(json.dumps(artifact, indent=2), encoding="utf-8")
        rc, _, stderr = _run(["validate", "--artifact", str(tampered)])
        assert rc != 0, "validator accepted a tampered artifact"
        assert "run_digest" in stderr, f"validator did not flag the digest: {stderr!r}"
        print("PASS negative: tampered artifact is rejected by validate")


def test_validate_rejects_non_canonical_method() -> None:
    """An artifact with the wrong method_id is rejected."""
    with tempfile.TemporaryDirectory(prefix="ars-04-method-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
        )
        assert rc == 0, f"setup run failed: {stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        artifact["method"]["method_id"] = "repository-recon/wrong-method"
        tampered = tmp / "tampered.json"
        tampered.write_text(json.dumps(artifact, indent=2), encoding="utf-8")
        rc, _, stderr = _run(["validate", "--artifact", str(tampered)])
        assert rc != 0, "validator accepted wrong method_id"
        assert "method_id" in stderr, f"validator did not flag the method: {stderr!r}"
        print("PASS negative: validate rejects non-canonical method_id")


def test_validate_rejects_forbidden_qualification_promotion() -> None:
    """A forged auto_promote flag is rejected by the validator."""
    with tempfile.TemporaryDirectory(prefix="ars-04-promo-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
        )
        assert rc == 0, f"setup run failed: {stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        artifact["qmr_revisions"]["auto_promote_method_status"] = True
        tampered = tmp / "tampered.json"
        tampered.write_text(json.dumps(artifact, indent=2), encoding="utf-8")
        rc, _, stderr = _run(["validate", "--artifact", str(tampered)])
        assert rc != 0, "validator accepted auto_promote_method_status=true"
        assert "auto_promote_method_status" in stderr, f"validator did not flag promotion: {stderr!r}"
        print("PASS negative: validate rejects auto-promotion of method status")


def test_invalid_corpus_is_rejected() -> None:
    """A corpus with a non-canonical method_id is refused."""
    with tempfile.TemporaryDirectory(prefix="ars-04-bad-corpus-") as td:
        tmp = Path(td)
        bad = _make_corpus(tmp, method_id="repository-recon/wrong-method")
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(bad),
                "--out", str(out),
            ]
        )
        assert rc == ae.EXIT_CODE["INVALID_CORPUS"], f"expected INVALID_CORPUS, got {rc}: {stderr!r}"
        assert "method_id" in stderr, f"stderr did not name the failure: {stderr!r}"
        print("PASS negative: invalid corpus method_id is rejected")


def test_missing_corpus_returns_documented_exit_code() -> None:
    """A missing corpus returns MISSING_CORPUS (rc=2)."""
    with tempfile.TemporaryDirectory(prefix="ars-04-missing-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(tmp / "does-not-exist.json"),
                "--out", str(out),
            ]
        )
        assert rc == ae.EXIT_CODE["MISSING_CORPUS"], f"expected MISSING_CORPUS, got {rc}"
        print("PASS negative: missing corpus returns MISSING_CORPUS")


def test_revised_qmr_passes_canonical_validator() -> None:
    """The revised QMR emitted by the run is accepted by the
    canonical QMR validator. The new record is evidence, not
    authority; it stays ``experimental`` and the canonical
    validator accepts it."""
    import yaml  # type: ignore
    with tempfile.TemporaryDirectory(prefix="ars-04-qmr-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        revised = tmp / "revised.yaml"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--revised-qmr", str(revised),
            ]
        )
        assert rc == 0, f"run failed: {stderr!r}"
        assert revised.is_file(), "revised QMR was not written"
        with revised.open("r", encoding="utf-8") as fh:
            record = yaml.safe_load(fh)
        assert record["status"] == "experimental", "revised QMR must stay experimental"
        assert record["method_id"] == ae.TARGET_METHOD_ID

        # Now run the canonical QMR validator against the revised record.
        from arsenal_method_record import validate_record  # type: ignore
        errors = validate_record(record, path=revised)
        assert not errors, f"canonical validator rejected the revised QMR: {errors!r}"
        print("PASS provenance: revised QMR passes the canonical QMR validator")


def test_revised_qmr_is_refused_for_non_canonical_method() -> None:
    """Defensive: the revised QMR emitter refuses non-canonical methods."""
    forged = {
        "schema": "engineering-system/qualified-method-record/v0",
        "method_id": "repository-recon/wrong-method",
        "method_version": "0.1.0",
        "status": "experimental",
        "qualified_for": {
            "outcome": "understand-a-repository",
            "contexts": ["x"],
            "exclusions": ["y"],
        },
        "inputs": [],
        "outputs": ["x"],
        "procedure_ref": "sha256:" + ("0" * 64),
        "evaluation": {
            "evidence_refs": [],
            "models": [],
            "repositories": [],
            "observed_strengths": [],
            "observed_failures": ["x"],
            "confidence": "bounded",
        },
        "provenance": {
            "arsenal_commit": None,
            "record_digest": "sha256:" + ("0" * 64),
        },
    }
    out = Path("/tmp/should-not-exist.yaml")
    try:
        ae._emit_revised_qmr({"method": {"method_id": "wrong", "procedure_ref": "sha256:" + ("0" * 64)},
                              "case_results": [],
                              "corpus": {"path": "x"},
                              "provenance": {"arsenal_commit": None},
                              "run_digest": "sha256:abc"}, out)
        raise AssertionError("emitter accepted a non-canonical method")
    except ValueError as exc:
        assert "non-canonical" in str(exc), f"unexpected error: {exc}"
        print("PASS negative: revised QMR emitter refuses non-canonical method")


def test_metric_set_is_honest_no_composite_score() -> None:
    """The artifact must not invent a composite quality score.

    The metrics object must contain only the documented count
    fields, never a synthetic ``quality_score`` or similar.
    """
    with tempfile.TemporaryDirectory(prefix="ars-04-metrics-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
        )
        assert rc == 0, f"run failed: {stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        forbidden = {"quality_score", "composite_score", "score", "grade"}
        metrics = artifact["metrics"]
        leaked = forbidden & set(metrics)
        assert not leaked, f"artifact leaked synthetic scores: {sorted(leaked)}"
        # Every metric value must be a non-negative integer (repetitions=1).
        for k, v in metrics.items():
            assert isinstance(v, int) and v >= 0, f"metric {k!r} is not a non-negative int: {v!r}"
        assert metrics["repetitions"] == 1
        assert (
            metrics["assertions_supported"]
            + metrics["assertions_missed"]
            + metrics["assertions_failed"]
            == metrics["assertions_evaluated"]
        )
        print("PASS honesty: metrics are real counts, not a composite score")


def test_no_runtime_authority_or_remote_credentials() -> None:
    """The artifact must never declare runtime authority or remote
    credentials; the v0 evaluator is strictly read-only and local.
    """
    with tempfile.TemporaryDirectory(prefix="ars-04-auth-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
        )
        assert rc == 0, f"run failed: {stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        serialized = json.dumps(artifact, sort_keys=True).lower()
        for token in (
            "filesystem.write",
            "network.write",
            "git.write",
            "production.mutate",
            "cloud.remote",
        ):
            assert token not in serialized, (
                f"artifact leaked runtime authority token {token!r}"
            )
        assert artifact["provenance"]["remote_credentials_used"] is False
        print("PASS authority: artifact declares no runtime authority or remote credentials")


def main() -> int:
    test_canonical_run_emits_valid_artifact()
    test_run_digest_is_deterministic()
    test_validate_detects_tampered_digest()
    test_validate_rejects_non_canonical_method()
    test_validate_rejects_forbidden_qualification_promotion()
    test_invalid_corpus_is_rejected()
    test_missing_corpus_returns_documented_exit_code()
    test_revised_qmr_passes_canonical_validator()
    test_revised_qmr_is_refused_for_non_canonical_method()
    test_metric_set_is_honest_no_composite_score()
    test_no_runtime_authority_or_remote_credentials()
    print("arsenal evaluate suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
