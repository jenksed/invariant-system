#!/usr/bin/env python3
"""One-time ARS-07 hardening after first live Flight Recorder run."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path.relative_to(ROOT)}: expected one match, found {count}: {old[:100]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


observe = ROOT / "scripts/arsenal_observe.py"
tests = ROOT / "scripts/test-arsenal-observe.py"
workflow = ROOT / ".github/workflows/ars-07-evidence-observatory.yml"
contract = ROOT / "arsenal/observability/CONTRACT.md"
usage = ROOT / "docs/use/evidence-observatory.md"

replace_once(
    observe,
    '''    provenance = source.get("execution_provenance", {})
    model_value = provenance.get("model")''',
    '''    provenance = source.get("execution_provenance", {})
    source_repository_sha = provenance.get("repository_sha")
    if source_repository_sha not in {None, "unknown"} and source_repository_sha != repository_sha:
        raise ObserveError(
            f"Bench receipt repository_sha {source_repository_sha!r} does not match normalized run {repository_sha!r}"
        )
    model_value = provenance.get("model")''',
)

replace_once(
    observe,
    '''        "authority": {
            "profile": None,
            "required": sorted(set(canonical_cap.get("authority", {}).get("required", []))),
            "granted": [],
            "missing": [],
            "remote_credentials_used": remote,
            "human_confirmation": "not-required",
        },''',
    '''        "authority": {
            "profile": None,
            "required": [],
            "granted": [],
            "missing": [],
            "remote_credentials_used": remote,
            "human_confirmation": "not-required",
        },''',
)

replace_once(
    observe,
    '''    if not isinstance(authority["remote_credentials_used"], bool):
        raise ObserveError("remote_credentials_used must be boolean")

    context = record["context"]''',
    '''    if not isinstance(authority["remote_credentials_used"], bool):
        raise ObserveError("remote_credentials_used must be boolean")
    if authority["profile"] is None:
        if authority["required"] or authority["granted"] or authority["missing"]:
            raise ObserveError("authority-free execution layer must not imply unobserved capability grants or gaps")
    else:
        expected_missing = sorted(set(authority["required"]) - set(authority["granted"]))
        if sorted(authority["missing"]) != expected_missing:
            raise ObserveError("authority missing set must equal required minus granted")

    context = record["context"]''',
)

replace_once(
    tests,
    '''            "repository_sha": "test",''',
    '''            "repository_sha": "repo-sha-1",''',
)

replace_once(
    tests,
    '''        assert d1["run"]["kind"] == "capability-verification"
        assert b1["run"]["kind"] == "evaluation"
        print("PASS normal execution and Bench share one top-level record contract")''',
    '''        assert d1["run"]["kind"] == "capability-verification"
        assert b1["run"]["kind"] == "evaluation"
        assert b1["authority"]["profile"] is None
        assert b1["authority"]["required"] == b1["authority"]["granted"] == b1["authority"]["missing"] == []
        print("PASS normal execution and Bench share one top-level record contract")
        print("PASS Bench records evaluator-layer authority without inventing capability execution grants")''',
)

replace_once(
    tests,
    '''        bad = copy.deepcopy(d1)
        bad["privacy"]["prompt_content_recorded"] = True''',
    '''        stale_bench = bench_source()
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
        bad["privacy"]["prompt_content_recorded"] = True''',
)

replace_once(
    workflow,
    '''          if-no-files-found: error

      - name: Preserve ARS-06 executable-world regression''',
    '''          if-no-files-found: error
          include-hidden-files: true

      - name: Verify evidence bundle file count before upload contract closes
        shell: bash
        run: |
          set -euo pipefail
          test "$(find .arsenal-observatory -maxdepth 1 -type f -name '*.json' | wc -l | tr -d ' ')" = "3"
          test -f .arsenal-evidence/ars-06-tdd-python-container.json
          test -f .arsenal-evidence/ars-06-tdd-python-container.world.json
          test -f .arsenal-bench/local-cloud-receipt.json

      - name: Preserve ARS-06 executable-world regression''',
)

replace_once(
    contract,
    '''The Flight Recorder reports authority; it does not grant authority.

The record should preserve, when available:''',
    '''The Flight Recorder reports authority for the **execution layer being recorded**; it does not grant authority.

A capability-verification run with an observed authority profile records its required, granted, and missing sets. A deterministic evaluation adapter such as Arsenal Bench is not executing the subject capability under that capability's runtime permissions, so its profile and authority sets remain empty rather than pretending those grants were observed.

The record should preserve, when available:''',
)

replace_once(
    usage,
    '''## Evidence remains independently verifiable''',
    '''## Authority is scoped to the recorded execution layer

A Dagger capability-verification record carries the observed authority profile and checks `missing = required - granted`.

A deterministic Bench evaluation is evaluating a capability rather than executing it under that capability's runtime authority. Its authority profile/sets are therefore empty; the recorder does not turn subject capability requirements into invented evaluator grants or gaps.

When Bench records an actual repository SHA, the normalizer also requires it to match the run SHA supplied to the Flight Recorder.

## Evidence remains independently verifiable''',
)

print("ARS-07 hardening materialized")
