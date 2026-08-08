#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path.relative_to(ROOT)}: expected one match, found {count}: {old[:90]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


readme = ROOT / "README.md"
roadmap = ROOT / "docs/roadmap/capability-system.md"
usage = ROOT / "docs/use/reality-budget.md"

replace_once(
    readme,
    "**Next:** ARS-05 generalizes execution selection into an **Execution Substrate Contract + Reality Budget**, so Arsenal can spend only as much reality and authority as the evidence requires.",
    "**Next:** ARS-06 gives the Reality Budget a strong portable execution adapter through the **Dagger / Executable World Pack**, proving that selected worlds can be materialized reproducibly in local and CI environments.",
)

replace_once(
    readme,
    "- Capability Graph + Capability Gap Preflight with canonical/lock inventories, implementation checks, qualification gates, and safe authority profiles.\n\n### BUILDING TOWARD\n\n- generalized execution substrates + Reality Budget;",
    "- Capability Graph + Capability Gap Preflight with canonical/lock inventories, implementation checks, qualification gates, and safe authority profiles;\n- Execution Substrate Contract + Reality Budget with proof-property selection, declared availability, fidelity limitations, and explicit escalation boundaries.\n\n### BUILDING TOWARD\n\n- Dagger / Executable World Pack;",
)

replace_once(
    roadmap,
    "## ARS-05 — Execution Substrate Contract\n\n**Goal:** generalize the Local Cloud execution/fidelity lesson into a portable execution-selection model.",
    """## ARS-05 — Execution Substrate Contract

**Status:** delivered by PR #17.

**Goal:** generalize the Local Cloud execution/fidelity lesson into a portable execution-selection model.

Delivered in v0:

- substrate-neutral `arsenal/substrates/CONTRACT.md`;
- ordered 12-rung Reality Budget catalog from deterministic function through production, with Repository Read as an explicit observation rung;
- runtime-agnostic proof requirements bound to canonical capability verification requirement IDs;
- deterministic selector with `SELECTED`, `AUTHORITY_GAP`, `SUBSTRATE_GAP`, `ESCALATION_REQUIRED`, `EVIDENCE_GAP`, and `UNKNOWN` outcomes;
- declared availability profiles instead of pretending every known substrate exists in the current environment;
- reuse of ARS-04 authority profiles without widening them;
- capability execution-surface compatibility checks;
- per-substrate isolation, reproducibility, proof traits, limitations, reset, teardown, and escalation metadata;
- remote sandbox, shared non-production, staging, and production marked explicit-only;
- TDD proof selecting in-process execution before a higher-cost world;
- Local Cloud proof stopping at the emulator when that evidence is sufficient;
- stronger real-provider semantics producing an explicit remote escalation candidate rather than automatic cloud fallback;
- proof vocabulary corrected to separate provider-behavior observation from emulator-vs-real fidelity;
- final Reality Budget CI read-only.

ARS-05 selects but does not execute. ARS-06 owns the first strong execution adapter implementation.""",
)

old_frontier = """```text
DELIVERED SPINE
ARS-00  Public Surface & Distribution
ARS-01  Capability Contract v2
ARS-02  Arsenal Bench v0 + first evidence-backed testing capability
ARS-03  Compiler & Distribution + `.arsenal.lock`
ARS-04  Capability Graph + Capability Gap Preflight

NOW / NEXT AFTER ARS-04 ACCEPTANCE
ARS-05  Execution Substrate Contract + Reality Budget

THEN
ARS-06  Dagger / Executable World Pack
ARS-07  Evidence Observatory / Agent Flight Recorder
ARS-08  Trust & Authority + third-party competence audit

LATER
ARS-09  Knowledge Plane
ARS-10  Intent Compiler + evidence-based model routing
ARS-11  Adversarial Verification / deeper counterfactual laboratories
ARS-12  Controlled Capability Evolution
```"""
new_frontier = """```text
DELIVERED SPINE
ARS-00  Public Surface & Distribution
ARS-01  Capability Contract v2
ARS-02  Arsenal Bench v0 + first evidence-backed testing capability
ARS-03  Compiler & Distribution + `.arsenal.lock`
ARS-04  Capability Graph + Capability Gap Preflight
ARS-05  Execution Substrate Contract + Reality Budget

NOW / NEXT AFTER ARS-05 ACCEPTANCE
ARS-06  Dagger / Executable World Pack

THEN
ARS-07  Evidence Observatory / Agent Flight Recorder
ARS-08  Trust & Authority + third-party competence audit

LATER
ARS-09  Knowledge Plane
ARS-10  Intent Compiler + evidence-based model routing
ARS-11  Adversarial Verification / deeper counterfactual laboratories
ARS-12  Controlled Capability Evolution
```"""
replace_once(roadmap, old_frontier, new_frontier)

replace_once(
    usage,
    "- `emulated-provider-behavior`\n- `real-provider-semantics`",
    "- `provider-behavior-observation`\n- `real-provider-semantics`",
)

print("ARS-05 public closeout materialized")
