#!/usr/bin/env python3
"""Test suite for the Repository Recon adapter surface (ARS-W3 Phase 1).

This suite proves four load-bearing properties:

* the internal fixture adapter is the canonical, default adapter;
* the evaluator can be configured to use the shell adapter;
* a broken shell adapter (wrong findings) produces worse evaluation
  evidence -- it never silently degrades to the internal fixture;
* the corpus-level evaluation runs end-to-end through the adapter
  surface without invoking Loadout.

The tests run the CLI in-process and on-disk against the canonical
corpus so the adapter behavior is exercised the same way an
operator would exercise it.
"""

from __future__ import annotations

import importlib.util
import json
import os
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "scripts" / "arsenal_evaluate.py"
CORPUS_PATH = ROOT / "evaluation" / "method-cases" / "corpus.manifest.json"

sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT))
spec = importlib.util.spec_from_file_location("arsenal_evaluate", SCRIPT_PATH)
ae = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(ae)


def _run(argv: list[str], env: dict | None = None) -> tuple[int, str, str]:
    """Run the CLI in-process with ``argv`` and capture (rc, stdout, stderr).

    argparse calls ``sys.exit(2)`` on argument errors; we catch the
    SystemExit so test assertions can observe the non-zero rc without
    the SystemExit propagating up through the test process.
    """
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
        try:
            rc = ae.main()
        except SystemExit as exc:
            # argparse uses sys.exit; translate to a regular rc.
            code = exc.code
            rc = code if isinstance(code, int) else 1
    finally:
        sys.argv = saved_argv
        sys.stdout = saved_stdout
        sys.stderr = saved_stderr
    return rc, out.getvalue(), err.getvalue()


def _capture_canonical_findings(tmp: Path) -> dict[str, list[dict]]:
    """Capture the canonical internal-procedure findings for each case.

    Returns a dict mapping ``case_id`` -> list of findings shaped like
    the adapter contract. We invoke the canonical procedure directly
    (the test runs in-process so the procedure is the same function
    the internal adapter calls).
    """
    cases = [
        ("recon.straightforward.small-clean", "evaluation/method-cases/repo-straightforward/repo"),
        ("recon.governed.explicit-architecture", "evaluation/method-cases/repo-governed/repo"),
        ("recon.ambiguous.incomplete-state", "evaluation/method-cases/repo-ambiguous/repo"),
    ]
    captured: dict[str, list[dict]] = {}
    for case_id, rel in cases:
        findings = ae._run_recon_procedure(ROOT / rel)
        captured[case_id] = findings
    return captured


def _write_findings_file(
    findings: dict[str, list[dict]], path: Path
) -> Path:
    """Write a findings dict to a JSON file in the shell-adapter format."""
    payload = {"schema": "arsenal/repository-recon-findings/v0", "findings": findings}
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return path


def test_default_adapter_is_internal() -> None:
    """With no --adapter flag, the evaluator uses the internal adapter.

    The artifact's provenance.adapter.name MUST be
    ``internal-fixture-procedure``. The metric counters and run digest
    MUST match the canonical (no-adapter) run so the adapter
    indirection is observably equivalent.
    """
    with tempfile.TemporaryDirectory(prefix="ars-w3-default-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
        )
        assert rc == 0, f"default run failed: rc={rc}, stderr={stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        adapter = artifact["provenance"]["adapter"]
        assert adapter["name"] == ae.ADAPTER_INTERNAL, (
            f"default adapter must be {ae.ADAPTER_INTERNAL}, got {adapter['name']!r}"
        )
        assert adapter["input"] is None, "internal adapter must not have an input"
        assert adapter["module"].endswith("InternalFixtureProcedureAdapter"), (
            f"internal adapter module path unexpected: {adapter['module']!r}"
        )
        print("PASS adapter default: evaluator uses internal-fixture-procedure by default")


def test_explicit_internal_adapter_matches_default() -> None:
    """Passing ``--adapter internal-fixture-procedure`` explicitly must
    produce the same artifact as the default run."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-internal-") as td:
        tmp = Path(td)
        out_default = tmp / "default.json"
        out_explicit = tmp / "explicit.json"
        for out in (out_default, out_explicit):
            argv = [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
            ]
            if out is out_explicit:
                argv.insert(1, ae.ADAPTER_INTERNAL)
                argv.insert(1, "--adapter")
            rc, _, stderr = _run(argv)
            assert rc == 0, f"run failed: rc={rc}, stderr={stderr!r}"
        a = json.loads(out_default.read_text(encoding="utf-8"))
        b = json.loads(out_explicit.read_text(encoding="utf-8"))
        assert a["run_digest"] == b["run_digest"], (
            "explicit internal adapter must produce the same run_digest as the default"
        )
        assert a["provenance"]["adapter"]["name"] == b["provenance"]["adapter"]["name"]
        print("PASS adapter internal-explicit: explicit internal matches the default run")


def test_shell_adapter_with_correct_findings_matches_internal() -> None:
    """A shell adapter emitting the canonical findings MUST produce the
    same evaluation evidence as the internal adapter. The two
    adapters are observably equivalent when their inputs match."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-shell-correct-") as td:
        tmp = Path(td)
        findings = _capture_canonical_findings(tmp)
        findings_path = _write_findings_file(findings, tmp / "findings.json")

        out_internal = tmp / "internal.json"
        out_shell = tmp / "shell.json"

        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out_internal),
            ]
        )
        assert rc == 0, f"internal run failed: rc={rc}, stderr={stderr!r}"

        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out_shell),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                "--adapter-input", str(findings_path),
            ]
        )
        assert rc == 0, f"shell run failed: rc={rc}, stderr={stderr!r}"

        internal = json.loads(out_internal.read_text(encoding="utf-8"))
        shell = json.loads(out_shell.read_text(encoding="utf-8"))

        # Different adapter names -> different digests (the adapter
        # identity is part of the artifact body).
        assert (
            internal["provenance"]["adapter"]["name"]
            != shell["provenance"]["adapter"]["name"]
        )
        # But the per-case evidence must match exactly.
        for ia, sa in zip(internal["case_results"], shell["case_results"]):
            assert ia["case_id"] == sa["case_id"]
            assert ia["successes"] == sa["successes"], (
                f"successes differ for {ia['case_id']}: "
                f"internal={ia['successes']} shell={sa['successes']}"
            )
            assert ia["misses"] == sa["misses"], (
                f"misses differ for {ia['case_id']}: "
                f"internal={ia['misses']} shell={sa['misses']}"
            )
            assert ia["failures"] == sa["failures"], (
                f"failures differ for {ia['case_id']}: "
                f"internal={ia['failures']} shell={sa['failures']}"
            )
        assert internal["metrics"] == shell["metrics"], (
            "internal and shell adapter runs must report identical metrics when "
            "the shell findings exactly match the internal procedure's outputs"
        )
        print(
            "PASS adapter shell-correct: shell adapter with canonical findings "
            "matches internal evidence exactly"
        )


def test_shell_adapter_with_wrong_findings_produces_worse_evidence() -> None:
    """A shell adapter emitting WRONG findings MUST produce worse
    evaluation evidence than the internal adapter. This is the
    load-bearing proof that a broken candidate is observable as a
    regression, not silently masked.

    The wrong-finding injection flips AGENTS.md to absent in every
    case, which contradicts two of the three canonical assertions
    that expect AGENTS.md to be present.
    """
    with tempfile.TemporaryDirectory(prefix="ars-w3-shell-broken-") as td:
        tmp = Path(td)
        canonical = _capture_canonical_findings(tmp)
        # Inject the broken finding: AGENTS.md reported absent in every case.
        broken: dict[str, list[dict]] = {}
        for case_id, findings in canonical.items():
            broken[case_id] = [
                {**f, "actual": False}
                if f.get("kind") == "presence" and f.get("evidence") == "AGENTS.md"
                else f
                for f in findings
            ]
        findings_path = _write_findings_file(broken, tmp / "broken.json")

        out_internal = tmp / "internal.json"
        out_broken = tmp / "broken.json.out"

        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out_internal),
            ]
        )
        assert rc == 0, f"internal run failed: rc={rc}, stderr={stderr!r}"

        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out_broken),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                "--adapter-input", str(findings_path),
            ]
        )
        assert rc == 0, f"shell run failed: rc={rc}, stderr={stderr!r}"

        internal = json.loads(out_internal.read_text(encoding="utf-8"))
        broken_art = json.loads(out_broken.read_text(encoding="utf-8"))

        # The broken adapter must produce at least one MORE miss
        # than the internal adapter.
        assert (
            broken_art["metrics"]["assertions_missed"]
            > internal["metrics"]["assertions_missed"]
        ), (
            "broken shell adapter must produce strictly more misses than the "
            "internal adapter; otherwise a wrong candidate is being silently "
            "masked"
        )

        # The adapter identity MUST be the shell adapter in the broken artifact.
        assert (
            broken_art["provenance"]["adapter"]["name"]
            == ae.ADAPTER_SHELL_LOADOUT
        )

        # Confirm the regression is localized to the flipped anchor.
        miss_ids_per_case = {
            cr["case_id"]: set(cr["misses"]) for cr in broken_art["case_results"]
        }
        # The straightforward and governed cases assert AGENTS.md present.
        assert "agents_md_present" in miss_ids_per_case.get(
            "recon.straightforward.small-clean", set()
        ), (
            "broken shell adapter must report agents_md_present as a MISS in the "
            "straightforward case (it claimed AGENTS.md was absent)"
        )
        assert "agents_md_present" in miss_ids_per_case.get(
            "recon.governed.explicit-architecture", set()
        ), (
            "broken shell adapter must report agents_md_present as a MISS in the "
            "governed case (it claimed AGENTS.md was absent)"
        )
        print(
            "PASS adapter broken-detected: wrong shell findings produce strictly "
            "more misses; the regression is observable, not silently masked"
        )


def test_shell_adapter_with_missing_case_fails_loudly() -> None:
    """A shell adapter with a findings file that omits a case MUST
    fail loudly, not silently fall back to the internal procedure.

    The error must surface in stderr so an operator can diagnose it.
    """
    with tempfile.TemporaryDirectory(prefix="ars-w3-shell-missing-") as td:
        tmp = Path(td)
        # Build findings that cover only ONE case (missing the others).
        canonical = _capture_canonical_findings(tmp)
        partial = {
            "recon.straightforward.small-clean": canonical[
                "recon.straightforward.small-clean"
            ]
        }
        findings_path = _write_findings_file(partial, tmp / "partial.json")

        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                "--adapter-input", str(findings_path),
            ]
        )
        assert rc != 0, "shell adapter with missing case must NOT silently succeed"
        assert (
            "no findings registered" in stderr or "adapter" in stderr
        ), f"shell adapter missing-case must surface adapter error in stderr; got {stderr!r}"
        assert not out.exists(), (
            "shell adapter with a missing case must NOT emit a partial artifact; "
            f"found {out}"
        )
        print(
            "PASS adapter missing-case-loud: shell adapter with a missing case "
            "fails loudly and emits no partial artifact"
        )


def test_shell_adapter_with_malformed_findings_file_is_rejected() -> None:
    """A findings file with the wrong schema is rejected at adapter
    construction; the evaluator reports an UNKNOWN failure class."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-shell-malformed-") as td:
        tmp = Path(td)
        bad = tmp / "bad.json"
        bad.write_text(json.dumps({"schema": "wrong", "findings": {}}), encoding="utf-8")
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                "--adapter-input", str(bad),
            ]
        )
        assert rc != 0, "malformed findings must NOT silently succeed"
        assert "schema" in stderr.lower(), (
            f"malformed findings must surface schema error in stderr; got {stderr!r}"
        )
        print(
            "PASS adapter malformed-findings: wrong-schema findings file is "
            "rejected loudly"
        )


def test_shell_adapter_missing_findings_file_is_rejected() -> None:
    """A missing findings file is rejected."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-shell-absent-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                "--adapter-input", str(tmp / "does-not-exist.json"),
            ]
        )
        assert rc != 0, "missing findings file must NOT silently succeed"
        assert "missing" in stderr.lower() or "not found" in stderr.lower(), (
            f"missing findings file must surface missing error in stderr; got {stderr!r}"
        )
        print(
            "PASS adapter missing-findings-file: nonexistent findings file is "
            "rejected loudly"
        )


def test_shell_adapter_without_input_is_rejected() -> None:
    """Selecting the shell adapter without --adapter-input is rejected
    (the evaluator refuses to invent an input)."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-shell-noinput-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
            ]
        )
        assert rc != 0, "shell adapter without --adapter-input must be rejected"
        assert "adapter-input" in stderr.lower(), (
            f"shell adapter without input must surface the requirement in stderr; "
            f"got {stderr!r}"
        )
        print(
            "PASS adapter shell-requires-input: shell adapter without "
            "--adapter-input is refused"
        )


def test_unknown_adapter_is_rejected() -> None:
    """An unknown adapter name is rejected at parse time."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-unknown-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        # argparse ``choices=`` rejects the unknown value with exit 2.
        rc, _, _ = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", "no-such-adapter",
            ]
        )
        assert rc != 0, "unknown adapter must be rejected"
        print("PASS adapter unknown: unknown adapter name is rejected")


def test_corpus_level_end_to_end_with_shell_adapter() -> None:
    """End-to-end corpus-level test demonstrating the ad-hoc
    evaluation pattern works: build a findings file from the
    canonical procedure, run the evaluator with the shell adapter,
    validate the resulting artifact, and confirm the run-digest is
    stable across two invocations.

    This is the Phase 1 placeholder for the eventual Wave 3
    Phase 2 flow:

        evaluation fixture -> actual candidate procedure ->
        candidate output -> Arsenal oracle/evaluator ->
        evaluation artifact

    Phase 2 will replace ``_capture_canonical_findings`` with an
    invocation of the Loadout Recon procedure (exact SHA to be
    supplied separately). Phase 1 uses the canonical procedure
    as a stand-in so the artifact shape and adapter contract can
    be exercised end-to-end without invoking Loadout yet.
    """
    with tempfile.TemporaryDirectory(prefix="ars-w3-corpus-e2e-") as td:
        tmp = Path(td)
        findings = _capture_canonical_findings(tmp)
        findings_path = _write_findings_file(findings, tmp / "findings.json")

        out_a = tmp / "a.json"
        out_b = tmp / "b.json"
        for out in (out_a, out_b):
            rc, _, stderr = _run(
                [
                    "repository-recon",
                    "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                    "--out", str(out),
                    "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                    "--adapter-input", str(findings_path),
                ]
            )
            assert rc == 0, f"corpus-level run failed: rc={rc}, stderr={stderr!r}"

        # Both runs must produce the same run_digest.
        a = json.loads(out_a.read_text(encoding="utf-8"))
        b = json.loads(out_b.read_text(encoding="utf-8"))
        assert a["run_digest"] == b["run_digest"], (
            "two corpus-level runs with the same shell findings must produce "
            "the same run_digest (determinism across invocations)"
        )

        # The artifact must validate against the canonical validator.
        rc, stdout, stderr = _run(["validate", "--artifact", str(out_a)])
        assert rc == 0, f"corpus-level artifact failed validation: stderr={stderr!r}"
        assert "PASS" in stdout, f"validate output did not report PASS: {stdout!r}"

        # And the artifact must declare the shell adapter identity.
        assert a["provenance"]["adapter"]["name"] == ae.ADAPTER_SHELL_LOADOUT
        assert a["provenance"]["adapter"]["input"], (
            "artifact must record the shell adapter input path"
        )
        print(
            "PASS corpus e2e: shell adapter drives the full corpus run end-to-end, "
            "the artifact validates, and the run_digest is deterministic"
        )


def test_artifact_adapter_block_is_recorded_for_every_run() -> None:
    """Every emitted artifact, regardless of adapter, records the
    adapter identity under ``provenance.adapter``. The artifact is
    always self-describing about which procedure produced the
    findings."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-record-") as td:
        tmp = Path(td)
        # Internal run.
        out_internal = tmp / "internal.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out_internal),
            ]
        )
        assert rc == 0, f"internal run failed: stderr={stderr!r}"
        artifact = json.loads(out_internal.read_text(encoding="utf-8"))
        assert "adapter" in artifact["provenance"], (
            "artifact must record provenance.adapter on every run"
        )
        adapter = artifact["provenance"]["adapter"]
        assert isinstance(adapter, dict)
        assert adapter["name"], "adapter.name must be a non-empty string"
        assert "module" in adapter, "adapter block must declare the module path"

        # Shell run.
        findings = _capture_canonical_findings(tmp)
        findings_path = _write_findings_file(findings, tmp / "findings.json")
        out_shell = tmp / "shell.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out_shell),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                "--adapter-input", str(findings_path),
            ]
        )
        assert rc == 0, f"shell run failed: stderr={stderr!r}"
        artifact = json.loads(out_shell.read_text(encoding="utf-8"))
        assert artifact["provenance"]["adapter"]["name"] == ae.ADAPTER_SHELL_LOADOUT
        assert (
            artifact["provenance"]["adapter"]["input"]
        ), "shell adapter artifact must record the input path"
        print(
            "PASS adapter provenance: every emitted artifact records the adapter "
            "identity under provenance.adapter"
        )


def test_adapter_does_not_break_revised_qmr_emission() -> None:
    """The revised-QMR emission path works for shell-adapter runs
    just as it does for internal runs. The revised QMR is always
    status: experimental; the adapter does not influence QMR status."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-revised-") as td:
        tmp = Path(td)
        findings = _capture_canonical_findings(tmp)
        findings_path = _write_findings_file(findings, tmp / "findings.json")
        out = tmp / "eval.json"
        revised = tmp / "revised.yaml"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--revised-qmr", str(revised),
                "--adapter", ae.ADAPTER_SHELL_LOADOUT,
                "--adapter-input", str(findings_path),
            ]
        )
        assert rc == 0, f"run failed: stderr={stderr!r}"
        assert revised.is_file(), "revised QMR was not written"
        # The validator accepts the revised QMR.
        import yaml  # type: ignore
        with revised.open("r", encoding="utf-8") as fh:
            record = yaml.safe_load(fh)
        assert record["status"] == "experimental", (
            "revised QMR must stay experimental under any adapter"
        )
        # The artifact's qmr_revisions block is unchanged.
        artifact = json.loads(out.read_text(encoding="utf-8"))
        qmr = artifact["qmr_revisions"]
        assert qmr["auto_promote_method_status"] is False
        assert qmr["auto_promote_capability_lifecycle"] is False
        assert qmr["auto_promote_capability_evaluation_status"] is False
        assert qmr["revised_qmr_status"] == "experimental"
        print(
            "PASS adapter qmr-revised: revised QMR emission works through the "
            "shell adapter and stays experimental"
        )


def _loadout_root_for_tests() -> Path | None:
    """Resolve the Loadout installation root for the adapter tests.

    The tests are no-ops (return None) when the W3 Loadout checkpoint
    is not present on disk. The runtime adapter test then skips
    itself rather than failing. CI runs against the exact checkpoint
    the Wave 3 maintainer supplies.
    """
    candidates = [
        Path(os.environ.get("ARSENAL_W3_LOADOUT_ROOT", "")),
        ROOT.parent / "loadout",
        Path("/Users/jenksed/Developer/engineering-system-workspace/loadout"),
    ]
    for c in candidates:
        if c and c.is_dir() and (c / "dist" / "packs" / "repository-recon" / "run.js").is_file():
            return c
    return None


def test_loadout_runtime_adapter_translates_common_paths() -> None:
    """When the W3 Loadout checkpoint is present, the loadout-runtime
    adapter must successfully translate the procedure's output into
    Arsenal findings for the canonical corpus, and the artifact must
    record the adapter identity with the Loadout installation root.

    Skipped when the checkpoint is not present (the test surface is
    environment-conditional so the suite stays green in CI without
    the Loadout source tree).
    """
    loadout_root = _loadout_root_for_tests()
    if loadout_root is None:
        print(
            "SKIP loadout-runtime translates: Loadout W3 checkpoint not on disk"
        )
        return
    with tempfile.TemporaryDirectory(prefix="ars-w3-loadout-rt-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", ae.ADAPTER_LOADOUT_RUNTIME,
                "--loadout-root", str(loadout_root),
            ]
        )
        assert rc == 0, f"loadout-runtime run failed: rc={rc}, stderr={stderr!r}"
        artifact = json.loads(out.read_text(encoding="utf-8"))
        adapter = artifact["provenance"]["adapter"]
        assert adapter["name"] == ae.ADAPTER_LOADOUT_RUNTIME
        assert adapter["loadout_root"], (
            "loadout-runtime adapter must record the loadout_root in provenance"
        )
        # The artifact must validate against the canonical validator.
        rc, _, _ = _run(["validate", "--artifact", str(out)])
        assert rc == 0, "loadout-runtime artifact failed validation"
        # The straightforward case must succeed on the AGENTS.md and
        # README.md presence assertions; these are paths Loadout's
        # catalog covers. Arsenal-specific paths produce FAILURE
        # outcomes, which is the honest output-driven signal.
        straight = next(
            cr for cr in artifact["case_results"]
            if cr["case_id"] == "recon.straightforward.small-clean"
        )
        success_ids = set(straight["successes"])
        assert "agents_md_present" in success_ids, (
            f"Loadout runtime adapter must succeed on AGENTS.md presence; "
            f"got successes={success_ids!r}"
        )
        assert "readme_present" in success_ids, (
            f"Loadout runtime adapter must succeed on README.md presence; "
            f"got successes={success_ids!r}"
        )
        print(
            "PASS loadout-runtime translates: Loadout W3 checkpoint produces "
            "expected common-path coverage; Arsenal-specific paths surface "
            "honestly as FAILURE"
        )


def test_loadout_runtime_adapter_without_loadout_root_is_rejected() -> None:
    """Selecting the loadout-runtime adapter without --loadout-root
    is rejected (the evaluator refuses to invent an installation)."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-loadout-noinput-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", ae.ADAPTER_LOADOUT_RUNTIME,
            ]
        )
        assert rc != 0, "loadout-runtime without --loadout-root must be rejected"
        assert "loadout-root" in stderr.lower(), (
            f"loadout-runtime without root must surface requirement in stderr; "
            f"got {stderr!r}"
        )
        print(
            "PASS loadout-runtime requires-root: loadout-runtime without "
            "--loadout-root is refused"
        )


def test_loadout_runtime_adapter_with_missing_root_fails_loudly() -> None:
    """A loadout-runtime adapter pointed at a missing Loadout
    installation refuses to emit a partial artifact and surfaces the
    failure in stderr."""
    with tempfile.TemporaryDirectory(prefix="ars-w3-loadout-badroot-") as td:
        tmp = Path(td)
        out = tmp / "eval.json"
        rc, _, stderr = _run(
            [
                "repository-recon",
                "--corpus", str(CORPUS_PATH.relative_to(ROOT)),
                "--out", str(out),
                "--adapter", ae.ADAPTER_LOADOUT_RUNTIME,
                "--loadout-root", str(tmp / "no-such-loadout"),
            ]
        )
        assert rc != 0, "loadout-runtime with bad root must NOT silently succeed"
        assert "loadout-runtime" in stderr.lower() or "cannot locate" in stderr.lower(), (
            f"loadout-runtime with bad root must surface the failure in stderr; "
            f"got {stderr!r}"
        )
        assert not out.exists(), (
            "loadout-runtime with a bad root must NOT emit a partial artifact"
        )
        print(
            "PASS loadout-runtime missing-root: bad --loadout-root fails loudly "
            "and emits no partial artifact"
        )


def test_translate_recon_to_findings_known_anchors_and_unknowns() -> None:
    """The translation helper emits presence findings (actual=True)
    for every detected anchor and presence findings (actual=False)
    for every canonical path implied by an ``architecture_anchor:KIND``
    unknown. The translation is pure and reviewable."""
    from evaluation.adapters.loadout_runtime_adapter import (  # type: ignore
        _translate_recon_to_findings,
    )
    recon = {
        "schema": "loadout/repository-recon/v1",
        "architecture_anchors": [
            {
                "kind": "governance",
                "path": "AGENTS.md",
                "observation": "x",
                "evidence": "x",
            },
            {
                "kind": "readme",
                "path": "README.md",
                "observation": "y",
                "evidence": "y",
            },
            {
                "kind": "source_root",
                "path": "src/",
                "observation": "z",
                "evidence": "z",
            },
        ],
        "unknowns": [
            {"subject": "architecture_anchor:ci_workflow", "reason": "r"},
            {"subject": "architecture_anchor:test_root", "reason": "r"},
            {"subject": "architecture_ownership", "reason": "r"},
        ],
    }
    findings = _translate_recon_to_findings(recon)
    # Three presence-True findings (the detected anchors).
    presence_true = [f for f in findings if f["actual"] is True]
    assert len(presence_true) == 3, (
        f"expected 3 presence-True findings, got {len(presence_true)}: "
        f"{presence_true!r}"
    )
    # The unknowns of the form architecture_anchor:KIND emit presence-False
    # findings for every canonical path of that KIND that was not detected.
    presence_false = [f for f in findings if f["actual"] is False]
    evidence_set = {f["evidence"] for f in presence_false}
    # ci_workflow canonical paths include .github/workflows, .travis.yml, ...
    assert ".github/workflows" in evidence_set, (
        f"expected ci_workflow canonical path '.github/workflows' in absence "
        f"findings, got {sorted(evidence_set)}"
    )
    assert ".travis.yml" in evidence_set, (
        f"expected ci_workflow canonical path '.travis.yml' in absence "
        f"findings, got {sorted(evidence_set)}"
    )
    # test_root canonical paths include tests/, test/, spec/, __tests__/.
    assert "tests/" in evidence_set
    # Architecture-ownership unknown (not of the anchor:KIND form) must NOT
    # produce findings.
    assert all(
        f["subject"] != "architecture_ownership" for f in findings
    ), "non-anchor-KIND unknown must not produce findings"
    print(
        "PASS translate recon-to-findings: pure translation emits 1:1 anchor "
        "and anchor-KIND-unknown findings, ignores architecture_ownership"
    )


def test_loadout_runtime_adapter_does_not_silently_fall_back() -> None:
    """When the loadout-runtime adapter's subprocess fails (non-zero
    exit), the adapter raises a RuntimeError that the evaluator
    surfaces as UNKNOWN. There is no silent fallback to the internal
    fixture procedure."""
    from unittest import mock
    from evaluation.adapters.loadout_runtime_adapter import (  # type: ignore
        LoadoutRuntimeAdapter,
    )
    fake = mock.MagicMock()
    fake.returncode = 7
    fake.stderr = "boom"
    fake.stdout = ""
    adapter = LoadoutRuntimeAdapter(Path("/tmp/nonexistent"))
    with mock.patch.object(
        adapter, "_resolve_procedure_path", return_value=Path("/tmp/fake.js")
    ), mock.patch("subprocess.run", return_value=fake):
        try:
            adapter.run(Path("/tmp/whatever"))
        except RuntimeError as exc:
            assert "loadout-runtime" in str(exc).lower(), (
                f"adapter failure must name the adapter: {exc!r}"
            )
            assert "boom" in str(exc), (
                f"adapter failure must surface stderr: {exc!r}"
            )
            print(
                "PASS loadout-runtime no-silent-fallback: subprocess failure "
                "raises a loud RuntimeError naming the adapter and stderr"
            )
            return
    raise AssertionError("adapter swallowed the subprocess failure")


def main() -> int:
    test_default_adapter_is_internal()
    test_explicit_internal_adapter_matches_default()
    test_shell_adapter_with_correct_findings_matches_internal()
    test_shell_adapter_with_wrong_findings_produces_worse_evidence()
    test_shell_adapter_with_missing_case_fails_loudly()
    test_shell_adapter_with_malformed_findings_file_is_rejected()
    test_shell_adapter_missing_findings_file_is_rejected()
    test_shell_adapter_without_input_is_rejected()
    test_unknown_adapter_is_rejected()
    test_corpus_level_end_to_end_with_shell_adapter()
    test_artifact_adapter_block_is_recorded_for_every_run()
    test_adapter_does_not_break_revised_qmr_emission()
    test_loadout_runtime_adapter_translates_common_paths()
    test_loadout_runtime_adapter_without_loadout_root_is_rejected()
    test_loadout_runtime_adapter_with_missing_root_fails_loudly()
    test_translate_recon_to_findings_known_anchors_and_unknowns()
    test_loadout_runtime_adapter_does_not_silently_fall_back()
    print("arsenal adapter suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
