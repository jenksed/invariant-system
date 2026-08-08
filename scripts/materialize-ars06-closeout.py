#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one match, found {count}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


readme = ROOT / "README.md"
roadmap = ROOT / "docs/roadmap/capability-system.md"

replace_once(
    readme,
    "**Next:** ARS-06 gives the Reality Budget a strong portable execution adapter through the **Dagger / Executable World Pack**, proving that selected worlds can be materialized reproducibly in local and CI environments.",
    "**Next:** ARS-07 unifies capability, proof-gate, executable-world, evaluation, and verification receipts through the **Evidence Observatory / Agent Flight Recorder**, so successful and failed runs can be reconstructed without private chain-of-thought capture.",
)

replace_once(
    readme,
    """- Execution Substrate Contract + Reality Budget with proof-property selection, declared availability, fidelity limitations, and explicit escalation boundaries.\n\n### BUILDING TOWARD\n\n- Dagger / Executable World Pack;\n- evidence observability;\n- trust and authority.""",
    """- Execution Substrate Contract + Reality Budget with proof-property selection, declared availability, fidelity limitations, and explicit escalation boundaries;\n- Dagger / Executable World Pack with proof-gated execution, deterministic replay, explicit host-input boundaries, and normal Arsenal evidence.\n\n### BUILDING TOWARD\n\n- Evidence Observatory / Agent Flight Recorder;\n- trust and authority.""",
)

replace_once(
    roadmap,
    """## ARS-06 — Dagger / Executable World Pack\n\n**Goal:** give the generalized execution model a strong portable containerized implementation.\n\nTreat Dagger as an adapter/Development Pack, not as Arsenal's architecture.\n\nUse it to begin constructing purpose-built executable repository worlds that may include application code, dependencies, database, browser, cloud emulator, fixtures, and verifiers.\n\nProof:\n\n- at least one real Arsenal capability runs inside a reproducible disposable world;\n- local and CI execution share the same declared behavior where practical;\n- the substrate emits normal Arsenal evidence and respects authority boundaries.""",
    """## ARS-06 — Dagger / Executable World Pack\n\n**Status:** delivered by PR #18.\n\n**Goal:** give the generalized execution model a strong portable containerized implementation without making Dagger part of Arsenal's architecture.\n\nDelivered in v0:\n\n- a Dagger Development Pack whose responsibility begins only after Reality Budget selects a container world;\n- **proof-gated execution**: the runner refuses to execute unless ARS-05 independently selects the world's exact substrate and reality rank;\n- `world.tdd-python-container`, a real `capability.tdd` verification world exercising canonical `red_observed` and `green_observed` requirements;\n- an explicit caller proof trait, `container-runtime`, that raises this tracer to `substrate.local-container` rank 4 while ordinary TDD still selects rank 2;\n- Dagger CLI `0.21.7` pinned and verified at runtime;\n- explicit host-input scope: only the Dagger Development Pack is imported into `/pack`;\n- no secrets and no runtime network requirement after required images are available;\n- deterministic world-definition and fixture digests;\n- a raw world receipt plus a composed Arsenal receipt carrying the exact Reality Budget selection evidence;\n- byte-identical replay proof across two executions;\n- the same checked-in runner command used locally and in CI;\n- final Dagger CI read-only.\n\nARS-06 sharpened an important boundary: current Core capabilities such as TDD contain model/human judgment that a container does not itself execute. The Dagger world executes the **verification environment that earns evidence for the capability contract**. Capability judgment, execution substrate, and verification evidence remain distinct.\n\nProof achieved:\n\n- a real canonical capability verification contract is exercised inside a reproducible disposable world;\n- Reality Budget, not runtime availability, authorizes that world;\n- ordinary TDD remains on the cheaper in-process substrate when container proof is unnecessary;\n- local and CI use the same declared runner/world contract;\n- two executions produce byte-identical Arsenal receipts;\n- Dagger emits normal Arsenal evidence without acquiring authority, lifecycle, or completion semantics.""",
)

replace_once(
    roadmap,
    """ARS-05  Execution Substrate Contract + Reality Budget\n\nNOW / NEXT AFTER ARS-05 ACCEPTANCE\nARS-06  Dagger / Executable World Pack\n\nTHEN\nARS-07  Evidence Observatory / Agent Flight Recorder\nARS-08  Trust & Authority + third-party competence audit""",
    """ARS-05  Execution Substrate Contract + Reality Budget\nARS-06  Dagger / Executable World Pack + proof-gated execution\n\nNOW / NEXT AFTER ARS-06 ACCEPTANCE\nARS-07  Evidence Observatory / Agent Flight Recorder\n\nTHEN\nARS-08  Trust & Authority + third-party competence audit""",
)
