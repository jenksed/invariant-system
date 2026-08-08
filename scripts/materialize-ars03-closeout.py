#!/usr/bin/env python3
"""One-time deterministic ARS-03 public-surface and roadmap closeout."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f"{path.relative_to(ROOT)}: expected one match, found {count}: {old[:100]!r}"
        )
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


roadmap = ROOT / "docs/roadmap/capability-system.md"
readme = ROOT / "README.md"
quickstart = ROOT / "docs/use/repository-truth-quickstart.md"

replace_once(
    roadmap,
    "Current frontier: **ARS-03 — Compiler & Distribution**",
    "Current frontier: **ARS-04 — Capability Graph + Capability Gap Preflight**",
)

replace_once(
    roadmap,
    "## ARS-03 — Compiler & Distribution\n\n**Goal:** compile canonical capabilities into downstream harness/distribution formats instead of manually maintaining divergent copies.",
    """## ARS-03 — Compiler & Distribution

**Status:** delivered by PR #15.

**Goal:** compile canonical capabilities into downstream harness/distribution formats instead of manually maintaining divergent copies.

Delivered in v0:

- deterministic `scripts/arsenal_compile.py` with validate/build/verify/explain surfaces;
- a target-specific export plan that contains packaging metadata without duplicating canonical behavior;
- Repository Truth → Agent Skills as the first compiler-backed export;
- generated `SKILL.md` carrying capability identity, lifecycle/evaluation state, authority, execution boundaries, outputs, and canonical source pointer;
- byte-identical canonical workflow snapshot generated from the registered primary implementation asset;
- generated `arsenal-manifest.json` as a proof-carrying package manifest with source and file digests;
- deterministic `.arsenal.lock` pinning capability version/digest, primary-asset digest, evaluation qualification, adapter version, export path, package digest, and export-plan digest;
- negative tests for duplicate exports, unknown capabilities, unsupported targets, path traversal, invalid package names, missing discovery context, and package drift;
- deterministic double-build proof;
- ARS-00B distribution/install regression preserved;
- final compiler CI read-only.

ARS-03 deliberately ships one proven exporter rather than speculative adapters. Agent Skills is the v0 target because ARS-00B already established its real package/install contract. Additional Claude, Codex-specific, MiniMax/generic, Kiln-native, or other adapters must earn their own format contract instead of copying behavior into another source of truth.""",
)

old_frontier = """```text
DELIVERED SPINE
ARS-00  Public Surface & Distribution
ARS-01  Capability Contract v2
ARS-02  Arsenal Bench v0 + first evidence-backed testing capability

NOW / NEXT AFTER ARS-02 ACCEPTANCE
ARS-03  Compiler & Distribution + `.arsenal.lock`

THEN
ARS-04  Capability Graph + Capability Gap Preflight
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
replace_once(roadmap, old_frontier, new_frontier)

replace_once(
    readme,
    "The portable package lives at [`distribution/agent-skills/repository-truth/`](distribution/agent-skills/repository-truth/). Its bundled canonical workflow is deterministically checked against [`agent_workflows/repository_truth_audit.md`](agent_workflows/repository_truth_audit.md).",
    "The portable package lives at [`distribution/agent-skills/repository-truth/`](distribution/agent-skills/repository-truth/). ARS-03 now generates it deterministically from `capability.repository-truth`, the Asset Registry, and the export plan; its bundled canonical workflow remains byte-identical to [`agent_workflows/repository_truth_audit.md`](agent_workflows/repository_truth_audit.md). The generated package manifest and [`.arsenal.lock`](.arsenal.lock) preserve exact provenance and qualification.",
)

replace_once(
    readme,
    "**Next:** ARS-03 will compile canonical capabilities into harness packages and is planned to introduce `.arsenal.lock`, a competence lockfile for reproducible capability versions, digests, provenance, qualification, and generated exports.",
    "**Next:** ARS-04 turns the capability set into an executable **Capability Graph + Capability Gap Preflight**, so Arsenal can prove required competence is present, compatible, authorized, and sufficiently qualified before execution begins.",
)

replace_once(
    readme,
    "- Repository Truth Agent Skills distribution pilot + Codex project-local installer;",
    "- compiler-generated Repository Truth Agent Skills distribution + Codex project-local installer;",
)

replace_once(
    readme,
    "- Arsenal Bench v0 with Case Health Receipts, counterfactual/ablation contracts, Capability Evidence Passports, and the first evidence-backed `testing` capability.\n\n### BUILDING TOWARD\n\n- compiler / harness exports + `.arsenal.lock`;\n- capability graph;",
    "- Arsenal Bench v0 with Case Health Receipts, counterfactual/ablation contracts, Capability Evidence Passports, and the first evidence-backed `testing` capability;\n- deterministic capability compiler + `.arsenal.lock` competence lockfile + proof-carrying Repository Truth Agent Skills package.\n\n### BUILDING TOWARD\n\n- capability graph + Capability Gap Preflight;",
)

replace_once(
    quickstart,
    "Status: ARS-00B distribution pilot",
    "Status: ARS-00B distribution pilot, compiler-backed by ARS-03",
)

replace_once(
    quickstart,
    "ARS-00B is intentionally narrow. It proves one useful distribution path before ARS-03 builds a general compiler.",
    "ARS-00B intentionally proved one useful distribution path before compiler automation. ARS-03 now regenerates that same path deterministically from canonical capability and asset data.",
)

replace_once(
    quickstart,
    """```text
<target-repository>/.agents/skills/repository-truth/
├── SKILL.md
└── references/
    └── repository_truth_audit.md
```""",
    """```text
<target-repository>/.agents/skills/repository-truth/
├── SKILL.md
├── arsenal-manifest.json
└── references/
    └── repository_truth_audit.md
```""",
)

replace_once(
    quickstart,
    "Harness-specific packaging should remain an adapter concern. ARS-03 will use this pilot as a regression fixture when it introduces compiler/export infrastructure.",
    "Harness-specific packaging remains an adapter concern. ARS-03 now uses this pilot as its first compiler regression fixture: `python3 scripts/arsenal_compile.py verify` reconstructs the expected package and fails on manual drift.",
)

replace_once(
    quickstart,
    "The later compiler should generate or refresh that snapshot deterministically rather than maintain it by hand.",
    "The ARS-03 compiler now generates or refreshes that snapshot deterministically rather than maintaining it by hand.",
)

replace_once(
    quickstart,
    "It does not define the permanent Arsenal distribution CLI or plugin system. That belongs to ARS-03 after this pilot establishes what a useful exported package actually needs.",
    "It does not define a universal multi-format distribution CLI or plugin system. ARS-03 v0 proves the compiler contract with Agent Skills only; additional format adapters require their own evidence-backed packaging contracts.",
)

print("ARS-03 closeout materialization complete")
