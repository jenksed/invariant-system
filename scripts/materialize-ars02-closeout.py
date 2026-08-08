#!/usr/bin/env python3
"""One-time deterministic ARS-02 public-surface and roadmap materializer."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path.relative_to(ROOT)}: expected one match, found {count}: {old[:80]!r}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


roadmap = ROOT / "docs/roadmap/capability-system.md"
readme = ROOT / "README.md"
floci = ROOT / "engineering/development_packs/floci/ROADMAP.md"

replace_once(
    roadmap,
    "Current frontier: **ARS-02 — Arsenal Bench & Evaluation Lab v0**",
    "Current frontier: **ARS-03 — Compiler & Distribution**",
)

replace_once(
    roadmap,
    "10. **Build the spine; grow packs in parallel.** Ecosystem-specific Development Packs should prove the shared contracts rather than fork the architecture.\n\n---",
    """10. **Build the spine; grow packs in parallel.** Ecosystem-specific Development Packs should prove the shared contracts rather than fork the architecture.

## Signature primitives

The roadmap deliberately owns a small set of concepts that should make Arsenal feel obvious in hindsight rather than merely comprehensive. They are not all shipped yet; each has an explicit program owner.

| Primitive | Product idea | Program owner |
|---|---|---|
| **Proof-Carrying Capability** | A capability travels with identity, authority, evaluation state, known limitations, and inspectable evidence instead of being trusted because its instructions look good. | ARS-02 seeds the Capability Evidence Passport; ARS-07/08 harden provenance and trust. |
| **Case Health Receipt** | A benchmark case must prove it is fit to judge the agent before its result can count. | ARS-02 — AVAILABLE v0. |
| **Counterfactual / Ablation Receipt** | Record what changed, what stayed fixed, which arms actually ran, and what Arsenal prevented rather than reporting a score without causal context. | ARS-02 — AVAILABLE v0; ARS-11 expands adversarial experiments. |
| **Competence Lockfile — `.arsenal.lock`** | Version the engineering judgment a repository expects its agents to use, including capability versions, digests, provenance, evaluation qualification, and compiled exports. | ARS-03. |
| **Capability Gap Preflight** | Compute required competence versus available/qualified competence before execution, so missing capabilities surface before the agent improvises around them. | ARS-04. |
| **Reality Budget / Proof Ladder** | Spend only as much reality and authority as the evidence requires. | ARS-05. |
| **Agent Flight Recorder** | Preserve capability/model/context/tool/evidence traces so a run can be replayed and successful/failed behavior can be diffed — eventually, git-bisect-like debugging for agent behavior. | ARS-07. |
| **Third-Party Competence Audit** | Treat imported skills as untrusted packages: inspect provenance/authority/conflicts, quarantine, sandbox, evaluate, then approve. | ARS-08. |
| **Evidence-Based Model Routing** | Route a capability to models/harnesses because Bench evidence shows competence for that capability, not because of brand reputation. | ARS-10 after ARS-02/04/07 evidence exists. |

These primitives are architectural commitments only at the slices named above. Public surfaces must continue to distinguish `AVAILABLE`, `BUILDING`, and `FRONTIER` rather than presenting roadmap concepts as shipped features.

---""",
)

replace_once(
    roadmap,
    "## ARS-02 — Arsenal Bench & Evaluation Lab v0\n\n**Status:** next slice.\n\n**Goal:** measure whether Arsenal actually improves engineering work and make lifecycle promotion executable.",
    """## ARS-02 — Arsenal Bench & Evaluation Lab v0

**Status:** delivered by PR #14; model-efficacy campaigns remain ongoing evaluation work.

**Goal:** measure whether Arsenal actually improves engineering work and make lifecycle promotion executable.

Delivered in v0:

- `evaluation/BENCH_CONTRACT.md` plus case, Case Health Receipt, and evaluation receipt schemas;
- a 19-case corpus: 8 Core engineering-judgment cases and 11 Local Cloud / former-FLC-06 cases;
- explicit control/treatment, ablation, and contract-counterfactual definitions;
- **Case Health Receipts** so broken or under-specified cases cannot contribute lifecycle evidence;
- **Counterfactual / Ablation Receipts** that preserve unexecuted arms instead of inferring causal wins;
- a **Capability Evidence Passport** inside executable receipts as the first proof-carrying-capability surface;
- deterministic runner + negative contract suite;
- five active Local Cloud routing/boundary cases executed in CI while fourteen deeper/model cases remain explicitly `designed-not-run`;
- retained claim scope and limitations stating that deterministic contract evidence is not model/harness efficacy evidence;
- the first evidence-backed capability lifecycle promotion: `capability.local-cloud-feature-delivery` to `testing` / `candidate`, guarded by the registered Local Cloud suite and exact generated receipt;
- read-only final CI and generated catalog integration.

First candidate campaign evidence: 5/5 active Local Cloud cases executed, healthy, and passing; 6 deeper Local Cloud cases remain designed-not-run, as do all 8 Core model-behavior cases. No capability is promoted to `stable` by this campaign.""",
)

replace_once(
    roadmap,
    "Candidate export targets:\n\n- Agent Skills;\n- Claude-compatible package;\n- Codex-compatible package;\n- MiniMax/generic agent package;\n- Kiln-native capability package.\n\nPotential CLI surface may include concepts such as lint/build/explain/install, but command names are not public contract until implementation reconnaissance proves the right interface.",
    """Candidate export targets:

- Agent Skills;
- Claude-compatible package;
- Codex-compatible package;
- MiniMax/generic agent package;
- Kiln-native capability package.

ARS-03 also owns the **Competence Lockfile** concept: `.arsenal.lock` should pin the capability IDs/versions, content digests, provenance, evaluation qualification, and compiled export expectations a repository depends on. The goal is to make agent competence reproducible infrastructure in the same spirit that dependency lockfiles make software dependencies reproducible.

The lockfile must not freeze model choice or pretend evaluation evidence never expires. It records the accepted competence contract and provenance; later evidence can invalidate or upgrade qualification deliberately.

Potential CLI surface may include concepts such as lint/build/explain/install, but command names are not public contract until implementation reconnaissance proves the right interface.""",
)

replace_once(
    roadmap,
    "FLC-05 is the tracer precedent: it proved that **provider resolved** and **requested capability available for that provider** are separate facts. ARS-04 generalizes that lesson beyond cloud work.\n\nStart deterministic.",
    """FLC-05 is the tracer precedent: it proved that **provider resolved** and **requested capability available for that provider** are separate facts. ARS-04 generalizes that lesson beyond cloud work.

ARS-04 should expose this as **Capability Gap Preflight**: before execution, derive the competence required by the intended route and compare it with capabilities that are actually present, compatible, authorized, and sufficiently qualified. The result should be explainable as covered / missing / unknown rather than allowing an agent to improvise around a consequential gap.

Start deterministic.""",
)

replace_once(
    roadmap,
    "**Goal:** generalize the Local Cloud execution/fidelity lesson into a portable execution-selection model.\n\nExecution ladder:",
    """**Goal:** generalize the Local Cloud execution/fidelity lesson into a portable execution-selection model.

Public concept: **Reality Budget / Proof Ladder**.

> **Spend only as much reality and authority as the evidence requires.**

The selector should be able to explain why a lower-blast-radius substrate is sufficient, what claim it cannot establish, and what additional evidence would justify escalation.

Execution ladder:""",
)

replace_once(
    roadmap,
    "## ARS-07 — Evidence Observatory\n\n**Goal:** unify receipts, run provenance, evaluation evidence, model/harness usage, and execution traces into a common run model.\n\nStart with data contracts, not a dashboard.",
    """## ARS-07 — Evidence Observatory / Agent Flight Recorder

**Goal:** unify receipts, run provenance, evaluation evidence, model/harness usage, and execution traces into a common run model.

The recognizable product surface is the **Agent Flight Recorder**: preserve enough of intent, capability versions, context, tools, authority escalation, verification, cost, and accepted evidence to explain *why* one run succeeded and another failed. Long term, this should enable time-travel inspection and git-bisect-like debugging for agent behavior without requiring private chain-of-thought capture.

Start with data contracts, not a dashboard.""",
)

replace_once(
    roadmap,
    "External capability ingestion should evolve toward:\n\n```text\ndiscover\n→ inspect\n→ classify\n→ sandbox\n→ extract/adapt\n→ evaluate\n→ register\n```",
    """External capability ingestion should evolve toward an **`arsenal audit` for third-party competence**:

```text
discover
→ quarantine
→ inspect provenance + requested authority + conflicts
→ sandbox
→ evaluate
→ adapt
→ approve/register
```

Unverified imported instructions should default to quarantine rather than becoming trusted behavior because they use a familiar package format.""",
)

replace_once(
    roadmap,
    "- evaluation history may inform choices only after ARS-02/07 provide sufficient evidence.",
    """- evaluation history may inform choices only after ARS-02/07 provide sufficient evidence;
- **evidence-based model routing** may select different models/harnesses for different capabilities only when comparable Bench/Flight-Recorder evidence supports that decision — never from brand reputation alone.""",
)

old_frontier = """```text
PROVEN FOUNDATION
Asset registry · invocation model · doctrine · methods · workflows
Development Pack contract · evidence/receipts · Floci FLC-00→05

NOW
ARS-00A  Public Surface & Unified Roadmap

NEXT
ARS-00B  Flagship quickstart / distribution pilot
ARS-01   Capability Contract v2
ARS-02   Arsenal Bench & Evaluation Lab v0
ARS-03   Compiler & Distribution

THEN
ARS-04   Capability Graph
ARS-05   Execution Substrate Contract
ARS-06   Dagger / Executable World Pack
ARS-07   Evidence Observatory
ARS-08   Trust & Authority Plane

LATER
ARS-09   Knowledge Plane
ARS-10   Intent Compiler
ARS-11   Adversarial Verification
ARS-12   Controlled Capability Evolution
```"""
new_frontier = """```text
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
replace_once(roadmap, old_frontier, new_frontier)

replace_once(
    readme,
    "**Next:** ARS-01 introduces Capability Contract v2. ARS-03 will later be required to reproduce this manually proven distribution shape rather than inventing packaging from theory.",
    "**Next:** ARS-03 will compile canonical capabilities into harness packages and is planned to introduce `.arsenal.lock`, a competence lockfile for reproducible capability versions, digests, provenance, qualification, and generated exports.",
)

replace_once(
    readme,
    "**ARSENAL BENCH — Status: BUILDING TOWARD (ARS-02).**",
    "**ARSENAL BENCH — Status: AVAILABLE v0 (ARS-02).**",
)

replace_once(
    readme,
    "Losses matter. Ablations matter. Model/harness differences matter.\n\nThe former Floci **FLC-06 evaluation/stabilization** program is being absorbed into Arsenal Bench as the first substantial execution-backed evaluation track rather than receiving a separate one-off benchmark framework.",
    """Losses matter. Ablations matter. Model/harness differences matter.

Bench v0 now ships a **19-case evaluation corpus** with Case Health Receipts, explicit control/treatment or ablation contracts, a deterministic runner, lifecycle gates, and Capability Evidence Passports. The first executable Local Cloud campaign runs 5 routing/boundary cases and keeps 6 deeper Local Cloud cases plus all 8 Core agent-behavior cases explicitly `designed-not-run`.

That distinction is deliberate: the 5/5 deterministic campaign is enough to earn `capability.local-cloud-feature-delivery` the `testing` / `candidate` lifecycle under its registered suite, but it is **not evidence that Arsenal improves a coding model**. Model/harness efficacy requires actual controlled agent runs with complete provenance.

The former Floci **FLC-06 evaluation/stabilization** program is now the Local Cloud track inside Arsenal Bench rather than a separate one-off benchmark framework.""",
)

replace_once(
    readme,
    "The Local Cloud contract requires local-cloud authority while forbidding remote-cloud and production mutation by default. All nine capability lifecycle states remain `draft` / `unassessed`; ARS-02 Arsenal Bench must earn stronger lifecycle claims through evaluation evidence.",
    "The Local Cloud contract requires local-cloud authority while forbidding remote-cloud and production mutation by default. Eight initial capabilities remain `draft` / `unassessed`; Local Cloud Feature Delivery has earned `testing` / `candidate` through the registered Arsenal Bench Local Cloud suite. No capability is `stable` yet.",
)

replace_once(
    readme,
    "- deterministic Arsenal Integrity audit.\n\n### BUILDING TOWARD\n\n- Arsenal Bench and executable evaluation infrastructure;",
    """- deterministic Arsenal Integrity audit;
- Arsenal Bench v0 with Case Health Receipts, counterfactual/ablation contracts, Capability Evidence Passports, and the first evidence-backed `testing` capability.

### BUILDING TOWARD

- compiler / harness exports + `.arsenal.lock`;""",
)

# The replacement above intentionally consumes the existing compiler line too if present twice.
text = readme.read_text(encoding="utf-8")
text = text.replace("- compiler / harness exports + `.arsenal.lock`;\n- compiler / harness exports;", "- compiler / harness exports + `.arsenal.lock`;", 1)
readme.write_text(text, encoding="utf-8")

replace_once(
    floci,
    "Evaluation should compare representative control/treatment runs and retain model, harness, tool, budget, repository-state, verifier, cost, and failure evidence under the general ARS-02 contract.\n\nFloci assets may earn `testing` or later `stable` only through the same lifecycle evidence rules as the rest of Arsenal.",
    """Evaluation should compare representative control/treatment runs and retain model, harness, tool, budget, repository-state, verifier, cost, and failure evidence under the general ARS-02 contract.

ARS-02 v0 has now executed the first five deterministic Local Cloud routing/boundary cases under Case Health and counterfactual receipts. Six deeper Local Cloud runtime/agent cases remain explicitly `designed-not-run`. That candidate evidence is sufficient for `capability.local-cloud-feature-delivery` to enter `testing`, but it does not establish model efficacy, real-provider semantics, or `stable` maturity.

Floci assets may earn `testing` or later `stable` only through the same lifecycle evidence rules as the rest of Arsenal.""",
)

print("ARS-02 closeout materialization complete")
