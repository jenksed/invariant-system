# Arsenal Research Registry

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft

This is the brainstorm / candidate research registry for the Arsenal research program. It records ideas, their possible dispositions, and any evidence or source observations that connect them to active experiments.

## Rules

- An idea may carry **multiple dispositions simultaneously** from the set below. Cross-listing requires a concrete reason noted per listing.
- This registry is **not a ranked backlog**. Order does not imply priority.
- Entries link to evidence or source observations where they exist. Ideas without links remain speculative.
- Rejected entries stay visible with the rejection reason and reconsideration triggers, consistent with `foundations/rejected_decision_memory.md`.
- Dispositions:
  - `PRODUCT_TARGET` — likely to become a product requirement if evidence supports it.
  - `EXPERIMENT_CANDIDATE` — needs a falsifiable experiment under `evaluation/experiments/`.
  - `ARCHITECTURE_CANDIDATE` — may affect cross-product contracts or repository structure.
  - `ENABLING_CAPABILITY` — supports other experiments or methods without being the research claim itself.
  - `UX_RESEARCH` — informs operator experience in Temper; never an authority surface.
  - `RESEARCH_WATCH` — preserve the idea, monitor external or internal progress, no active foundation effort.
  - `REJECT_OR_TRANSFORM` — conflicts with a durable decision; remains visible with triggers for reconsideration.

## Entries

| ID | Idea | Dispositions | Source observation | Linked experiment(s) | Notes |
|----|------|--------------|--------------------|----------------------|-------|
| BR-001 | Tournament / swarm agent architectures | RESEARCH_WATCH | Historical recurring proposal to coordinate multiple agents competitively or as a swarm. | — | Deferred distraction. Preserve the idea; do not allocate foundation effort until execution-state semantics (ARS-001) and evaluator integrity (ARS-005) are credible. |
| BR-002 | Self-modifying authoritative workflows | REJECT_OR_TRANSFORM | Proposal to let an agent rewrite its own execution or governance paths. | — | Conflicts with determinism-over-discretion doctrine and capability-is-not-authority boundary. Reconsideration trigger: qualified steering semantics from ARS-006 that can be enforced by Kiln rather than delegated to model discretion. |
| BR-003 | Full mobile engineering | RESEARCH_WATCH | Recurring market / capability observation about engineering on mobile devices. | — | No Arsenal foundation effort. Monitor only. |
| BR-004 | Giant model-routing benchmark suites | RESEARCH_WATCH | External trend toward large routing benchmarks. | — | No foundation effort until Manifold selection surface (`products/manifold/src/selector.py`) has a bounded, stdlib-only integration path. |
| BR-005 | Cryptographic provenance infrastructure | RESEARCH_WATCH | Recurring interest in signed evidence, attestations, and digest-bound receipts. | — | Monitor. Any adoption must preserve the anti-authority rule: evidence is not execution authority. |
| BR-006 | Workflow marketplaces | RESEARCH_WATCH | Recurring proposal to distribute or exchange agent workflows. | — | No foundation effort. Authority and mutation surfaces remain product-owned. |
| BR-007 | Drag-and-drop graph authoring | UX_RESEARCH + RESEARCH_WATCH | Operator-experience signal that graph manipulation could aid comprehension. | ARS-003 | Informs operator comprehension studies; does not imply an authoring runtime or mutation surface in Temper. |
| BR-008 | Explicit execution-state surface | EXPERIMENT_CANDIDATE + ARCHITECTURE_CANDIDATE | Need for deterministic, observable execution state shared between Loadout planning and Kiln execution. | ARS-001 | See `evaluation/experiments/ars-001-execution-state/PROTOCOL.md`. |
| BR-009 | Evaluator-integrity defenses | EXPERIMENT_CANDIDATE | Risk that evaluators can be gamed or become the weakest link in evidence chains. | ARS-005 | Gated on ARS-001 infrastructure. Design initiated at `evaluation/experiments/ars-005-evaluator-integrity/PROTOCOL-DRAFT.md`. |
| BR-010 | Graph-first operator representation | UX_RESEARCH + PRODUCT_TARGET(Temper, future) | Operator comprehension may improve with graph representations of plans, state, or provenance. | ARS-003 | Future Temper direction only; no runtime authority. Formative study at `evaluation/experiments/ars-003-operator-comprehension/PROTOCOL.md`. |
| BR-011 | Dependency-aware scheduling over naive parallelism | EXPERIMENT_CANDIDATE | Observation that parallel execution often ignores plan dependencies. | ARS-002 (deferred) | Deferred until experiment machinery is credible. See `evaluation/experiments/README.md`. |
| BR-012 | Long-horizon repository health metrics | EXPERIMENT_CANDIDATE | Need for durable, repeatable repository-health measurements beyond single-pass linting. | ARS-004 (deferred) | Explicit future program. See `evaluation/experiments/README.md`. |
| BR-013 | Steering semantics classification | EXPERIMENT_CANDIDATE | Need to classify which steering signals reliably influence model behavior in bounded contexts. | ARS-006 (deferred) | Explicit future program. Reconsideration trigger for BR-002. |
| BR-014 | Rejected-decision memory instantiation | ENABLING_CAPABILITY | `foundations/rejected_decision_memory.md` defines the pattern but currently holds zero records. | — | This program instantiates the pattern via `evaluation/negative-knowledge/CATALOG.md`. |
