# Arsenal Research Reconciliation

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft
Owner: ARS-00
Scope: Archaeological summary of existing Arsenal research infrastructure and the foundation this branch adds.

## Purpose

This document records what already exists in the Arsenal tree, what can be reused without modification, what is missing, and what this branch adds. Every claim carries a monorepo-relative path so the summary can be verified against the tree rather than trusted as prose.

## WHAT EXISTS

### Epistemic lifecycle (ARS-01)

`products/arsenal/docs/arsenal-lifecycle.md` is the canonical lifecycle document. It maps the epistemic chain `Idea → Hypothesis → Experimental → Replicated/Evaluated → Qualified` onto the closed protocol enums `LIFECYCLE_STATES={draft,testing,stable,deprecated}` and `EVALUATION_STATES={unassessed,planned,candidate,qualified}` owned by `scripts/arsenal_protocol.py`. It explicitly states that Arsenal-distribution content does not extend those enums.

### Method evaluation (ARS-04)

`products/arsenal/docs/arsenal-method-evaluation.md` defines the deterministic, local-only evaluation surface. The executable surface is `scripts/arsenal_evaluate.py`, with subcommands `repository-recon` and `validate`. The v0 artifact schema is `arsenal/method-evaluation/v0`; it carries a `run_digest`, an `epistemic_conclusion` vocabulary restricted to `experimental`, a closed `qualification_gap.label` vocabulary, and auto-promotion flags that are all `false`. The document also describes the adapter surface (`evaluation/adapters/`) and the Wave 3 `loadout-runtime` adapter.

### Bench

`products/arsenal/evaluation/BENCH_CONTRACT.md` defines Arsenal Bench. The executable schemas are:

- `products/arsenal/evaluation/evaluation-case.schema.json`
- `products/arsenal/evaluation/evaluation-receipt.schema.json`
- `products/arsenal/evaluation/case-health-receipt.schema.json`

The seven initial Case Health checks are declared in `scripts/arsenal_protocol.py` as `CASE_HEALTH_CHECKS`: `starting_state_reproducible`, `failure_reachable`, `success_reachable`, `acceptance_observable`, `expected_outcome_explicit`, `solution_not_leaked`, `verifier_independent`, `no_remote_credentials`. The four comparison kinds are `control-treatment`, `ablation`, `multi-arm`, and `contract-counterfactual` (`scripts/arsenal_protocol.py`, `COMPARISONS`).

The Wave 5 campaign lives under `products/arsenal/evaluation/wave5/`:

- `SELECTION-AND-ABLATION.md` — selection set, holdout, ablation, and the `staged-evidence-graph` winner.
- `PRODUCTIZED-ADOPTION.md` — productized Loadout adoption evidence.
- `CONTRACT-ADJUDICATION-REQUIRED.md` — the QMR v0 adapter-binding gap that blocks graduation.
- `miss-taxonomy.v1.json` — the A–F miss taxonomy.
- `winner-lock.v1.json` and `productized-lock.v1.json` — selection and adoption locks.

The v0 method-cases corpus is `products/arsenal/evaluation/method-cases/corpus.manifest.json`, containing three cases: `recon.straightforward.small-clean`, `recon.governed.explicit-architecture`, and `recon.ambiguous.incomplete-state`.

Qualification receipts emitted by `scripts/arsenal_bench.py` live in `products/arsenal/evaluation/qualifications/`, e.g. `agent-skills.plan.v1.json` and `agent-skills.repository-truth.v1.json`.

### Qualified Method Records

The `engineering-system/qualified-method-record/v0` contract is documented in `contracts/qualified-method-record.v0.md`. Arsenal's validation schema is `products/arsenal/evaluation/method-records/qualified-method-record.v0.schema.json`. The canonical experimental record is `products/arsenal/evaluation/method-records/repository-recon.architecture-anchor.v0.yaml`. The schema enforces first-class negative knowledge through `qualified_for.exclusions` and `evaluation.observed_failures`.

### Foundations

`products/arsenal/foundations/rejected_decision_memory.md` defines the rejected-decision memory pattern; it currently contains zero records. `products/arsenal/foundations/reproducible_cloud_fixtures.md` defines fixture properties (minimal, versioned, idempotent/resettable, observable, portable, safe) and the clean-room replay procedure.

### Knowledge Plane

`products/arsenal/arsenal/knowledge/CONTRACT.md` defines the Knowledge Plane. Its typed entity vocabulary includes `Experiment`, `NegativeKnowledge`, and `ReconsiderationTrigger`, among others. The first executable tracer is KFT-0 against Kiln, with a frozen fixture referenced in the contract.

### Cross-product contracts

`contracts/learning-observation.v0.md` names hypothesis and experiment as Arsenal's remit and requires that observations do not silently become doctrine or qualification. `contracts/qualified-method-record.v0.md` is the authoritative QMR contract.

### Integration scenarios

`integration/scenarios/repository-recon/README.md` documents the Wave 3 integration proof harness pattern: a deterministic `proof-repo/` fixture, a `TEST-MATRIX.md`, an `EXPECTED-RESULTS.md`, and verifier-populated `run-logs/`. The proof does not add a fifth cross-product contract and must distinguish simulated from real Kiln.

### Kiln verification registry

`products/kiln/lib/kiln/verification/registry.ex` registers Arsenal verification profiles under IDs such as `arsenal.method-record`, `arsenal.evaluate`, `arsenal.wave5-recon-bench`, `arsenal.wave6-verify-bench`, `arsenal.compiler`, `arsenal.trust`, and `arsenal.repository-recon-adapter`, all mapped to the `project-arsenal` command profile.

## WHAT CAN BE REUSED

The following existing surfaces can be reused without extension:

- State vocabularies as projections of `LIFECYCLE_STATES` and `EVALUATION_STATES` from `scripts/arsenal_protocol.py` (`products/arsenal/docs/arsenal-lifecycle.md`).
- Digest canonicalization: `json.dumps(obj, sort_keys=True, separators=(",", ":"))` followed by SHA-256, with self-referential digest fields replaced by a 64-zero placeholder (`scripts/arsenal_method_record.py`, `scripts/arsenal_evaluate.py`, `scripts/wave5_recon_bench.py`).
- Comparison kinds `control-treatment`, `ablation`, `multi-arm`, `contract-counterfactual` (`scripts/arsenal_protocol.py`, `products/arsenal/evaluation/BENCH_CONTRACT.md`).
- Case Health checks (`scripts/arsenal_protocol.py`, `products/arsenal/evaluation/BENCH_CONTRACT.md`).
- Miss taxonomy classes A–F from `products/arsenal/evaluation/wave5/miss-taxonomy.v1.json`.
- Qualification gap labels from `products/arsenal/docs/arsenal-method-evaluation.md`: `bounded-evaluator-only`, `no-behavioral-efficacy-evidence`, `no-qualification-receipt-bound-to-capability`, `experimental-to-experimental`.
- Receipt/provenance block pattern with `arsenal_commit`, `harness`, `model`, `adapter`, and `remote_credentials_used: false` (`scripts/arsenal_observe.py`, `scripts/arsenal_evaluate.py`, `products/arsenal/evaluation/BENCH_CONTRACT.md`).
- Generated-catalog table pattern used in `products/arsenal/docs/roadmap/capability-system.md` and `products/arsenal/docs/arsenal-method-evaluation.md`.
- The `ARS-NN` / `ARS-NNN` identifier convention established across `products/arsenal/docs/roadmap/capability-system.md`, `products/arsenal/docs/arsenal-lifecycle.md`, and `products/arsenal/docs/arsenal-method-evaluation.md`.

## WHAT IS MISSING

The archaeology surfaced the following gaps:

- No experiment contract or registry. Bench has cases, receipts, and qualification receipts, but there is no artifact class that records a single controlled experiment from hypothesis through result.
- No evidence index. Evidence is scattered across `evaluation/wave5/`, `evaluation/qualifications/`, `evaluation/method-cases/`, `arsenal/knowledge/fixtures/`, and integration `run-logs/`. There is no unified index for locating evidence by capability, method, or research question.
- No instantiated negative-knowledge catalog. Negative knowledge is first-class in QMR `exclusions` and `observed_failures`, in the Wave 5 miss taxonomy, and in the Knowledge Plane `NegativeKnowledge` entity, but no catalog file collects instantiated negative findings across experiments.
- No declared promotion-packet format. The path from a qualified method or supported experiment to a runtime change in Kiln, Loadout, Manifold, or Temper is not encoded as a reviewable packet template.
- No `EXP-` style experiment ID scheme. Existing IDs are `ARS-NN` program IDs, `W5-MNN` miss IDs, and case IDs; there is no stable experiment-record namespace.
- Unresolved QMR v0 adapter-binding gap. As documented in `products/arsenal/evaluation/wave5/CONTRACT-ADJUDICATION-REQUIRED.md`, QMR v0 cannot canonically bind a method to multiple product targets or adapters. This blocks graduation of the Wave 5 winner to `qualified`.

## WHAT THIS BRANCH ADDS

This branch adds the research program foundation without modifying existing contracts, schemas, scripts, or qualification receipts:

- `products/arsenal/docs/arsenal-research-program.md` — program overview and prioritized roadmap DAG.
- `products/arsenal/docs/arsenal-experiment-contract.md` — the foundational operating contract for all Arsenal experiments (ARS-000).
- `products/arsenal/docs/research-provenance-and-reproducibility.md` — provenance and reproducibility rules.
- This document (`products/arsenal/docs/research-reconciliation.md`).
- The `products/arsenal/evaluation/experiments/` tree, which holds the experiment registry (`README.md`), shared templates, the machine-checkable protocol schema, and per-experiment directories `ars-001-execution-state/`, `ars-003-operator-comprehension/`, and `ars-005-evaluator-integrity/`.
- A negative-knowledge catalog under `products/arsenal/evaluation/negative-knowledge/CATALOG.md`, seeded with existing repository negative knowledge (Wave 5 misses, QMR observed failures, the adapter-binding contract gap).
- A promotion packet template at `products/arsenal/evaluation/promotion/PACKET-TEMPLATE.md`.
- ARS-001, ARS-003, and ARS-005 protocol documents and harness descriptions in their respective `evaluation/experiments/ars-00X-*/` directories.

None of these additions extend the closed protocol enums in `scripts/arsenal_protocol.py` or claim runtime authority.
