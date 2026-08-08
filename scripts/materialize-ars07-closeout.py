#!/usr/bin/env python3
"""One-time deterministic ARS-07 public-surface closeout."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path.relative_to(ROOT)}: expected one match, found {count}: {old[:120]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


readme = ROOT / "README.md"
roadmap = ROOT / "docs/roadmap/capability-system.md"

replace_once(
    readme,
    "**Next:** ARS-07 unifies capability, proof-gate, executable-world, evaluation, and verification receipts through the **Evidence Observatory / Agent Flight Recorder**, so successful and failed runs can be reconstructed without private chain-of-thought capture.",
    "**Next:** ARS-08 builds the **Trust & Authority Plane**, making capability/package provenance, requested authority, escalation, quarantine, and third-party competence review explicit before imported behavior can become trusted execution.",
)

replace_once(
    readme,
    "- Dagger / Executable World Pack with proof-gated execution, deterministic replay, explicit host-input boundaries, and normal Arsenal evidence.\n\n### BUILDING TOWARD\n\n- Evidence Observatory / Agent Flight Recorder;\n- trust and authority.",
    "- Dagger / Executable World Pack with proof-gated execution, deterministic replay, explicit host-input boundaries, and normal Arsenal evidence;\n- Evidence Observatory / Agent Flight Recorder with source-addressed receipts, stable run fingerprints, metadata-first privacy, evidence-bound outcomes, and OpenTelemetry-compatible mapping.\n\n### BUILDING TOWARD\n\n- trust and authority + third-party competence audit.",
)

replace_once(
    roadmap,
    "Current frontier: **ARS-05 — Execution Substrate Contract + Reality Budget**",
    "Current frontier: **ARS-08 — Trust & Authority Plane**",
)

replace_once(
    roadmap,
    "## ARS-07 — Evidence Observatory / Agent Flight Recorder\n\n**Goal:** unify receipts, run provenance, evaluation evidence, model/harness usage, and execution traces into a common run model.",
    """## ARS-07 — Evidence Observatory / Agent Flight Recorder

**Status:** delivered by PR #19.

**Goal:** unify receipts, run provenance, evaluation evidence, model/harness usage, and execution traces into a common run model.

Delivered in v0:

- one strict Flight Record envelope shared by normal capability verification and Arsenal Bench evaluation;
- source-addressed evidence references with SHA-256 verification, claim scope, and preserved limitations;
- separate operational `instance_id` and deterministic stable `fingerprint` identities;
- Dagger and Bench normalization into the same top-level provenance/context/tool/evidence/outcome structure;
- explicit evaluator-layer authority semantics rather than invented capability-runtime grants;
- repository-provenance consistency checks when source receipts observed a repository SHA;
- evidence-bound PASS outcomes that cannot exist without accepted evidence IDs;
- metadata-first, content-off privacy policy rejecting prompt, completion, secret, environment-dump, and chain-of-thought fields;
- OpenTelemetry interoperability mapping using Arsenal's own attribute namespace and current log-based Event direction without making a collector/backend part of correctness;
- live CI evidence bundle containing both normalized Flight Records and their original Dagger/Bench source receipts;
- deterministic fingerprint equivalence across reruns whose instance IDs differ.

The v0 evidence authority is the Flight Record plus independently verifiable source receipts. Dashboards, telemetry backends, retention systems, and raw GenAI content capture remain explicitly outside this slice.""",
)

replace_once(
    roadmap,
    """ARS-06  Dagger / Executable World Pack + proof-gated execution

NOW / NEXT AFTER ARS-06 ACCEPTANCE
ARS-07  Evidence Observatory / Agent Flight Recorder

THEN
ARS-08  Trust & Authority + third-party competence audit""",
    """ARS-06  Dagger / Executable World Pack + proof-gated execution
ARS-07  Evidence Observatory / Agent Flight Recorder

NOW / NEXT AFTER ARS-07 ACCEPTANCE
ARS-08  Trust & Authority + third-party competence audit""",
)

print("ARS-07 public closeout materialized")
