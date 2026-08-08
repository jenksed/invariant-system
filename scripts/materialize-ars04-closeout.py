#!/usr/bin/env python3
from pathlib import Path


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


readme = Path("README.md")
roadmap = Path("docs/roadmap/capability-system.md")

replace_once(
    readme,
    "**Next:** ARS-04 turns the capability set into an executable **Capability Graph + Capability Gap Preflight**, so Arsenal can prove required competence is present, compatible, authorized, and sufficiently qualified before execution begins.",
    "**Next:** ARS-05 generalizes execution selection into an **Execution Substrate Contract + Reality Budget**, so Arsenal can spend only as much reality and authority as the evidence requires.",
)

replace_once(
    readme,
    "- deterministic capability compiler + `.arsenal.lock` competence lockfile + proof-carrying Repository Truth Agent Skills package.\n\n### BUILDING TOWARD\n\n- capability graph + Capability Gap Preflight;",
    "- deterministic capability compiler + `.arsenal.lock` competence lockfile + proof-carrying Repository Truth Agent Skills package;\n- Capability Graph + Capability Gap Preflight with canonical/lock inventories, implementation checks, qualification gates, and safe authority profiles.\n\n### BUILDING TOWARD\n\n- generalized execution substrates + Reality Budget;",
)

replace_once(
    roadmap,
    "Current frontier: **ARS-04 — Capability Graph + Capability Gap Preflight**",
    "Current frontier: **ARS-05 — Execution Substrate Contract + Reality Budget**",
)

replace_once(
    roadmap,
    "## ARS-04 — Capability Graph\n\n**Goal:** make dependencies, preconditions, outputs, authority, implementation availability, and composition machine-readable.",
    """## ARS-04 — Capability Graph

**Status:** delivered by PR #16.

**Goal:** make dependencies, preconditions, outputs, authority, implementation availability, and composition machine-readable.

Delivered in v0:

- explicit graph contract and deterministic `arsenal/graph/graph.json`;
- four tracer routes: repository audit, feature delivery, bug repair, and Local Cloud feature delivery;
- Capability Gap Preflight with `READY`, `CAPABILITY_GAP`, `AUTHORITY_GAP`, `QUALIFICATION_GAP`, and `UNKNOWN` verdicts;
- canonical-source and `.arsenal.lock` competence inventories;
- lock version/digest/qualification checks so stale pinned competence fails closed;
- primary implementation resolution through the Asset Registry;
- route minimum semantic-version and lifecycle/evaluation gates;
- read-only, workspace-safe, and local-cloud-safe authority profiles with dangerous remote grants rejected in v0;
- Local Cloud route consuming its ARS-02-earned `testing / candidate` qualification;
- machine-readable JSON preflight output and explicit non-ready exit codes;
- negative graph tests for unknown capabilities, invalid dependencies, bad versions, invalid qualification states, and unsafe profiles.

ARS-04 does not infer routes from vague intent or execute them. It proves the route contract and competence boundary first; ARS-10 later owns intent compilation.""",
)

old_frontier = """```text
DELIVERED SPINE
ARS-00  Public Surface & Distribution
ARS-01  Capability Contract v2
ARS-02  Arsenal Bench v0 + first evidence-backed testing capability
ARS-03  Compiler & Distribution + `.arsenal.lock`

NOW / NEXT AFTER ARS-03 ACCEPTANCE
ARS-04  Capability Graph + Capability Gap Preflight

THEN
ARS-05  Execution Substrate Contract + Reality Budget
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

replace_once(roadmap, old_frontier, new_frontier)
print("ARS-04 closeout materialization complete")
