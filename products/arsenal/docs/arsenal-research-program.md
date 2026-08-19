# Arsenal Research Program

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft
Owner: ARS-00
Scope: Prioritized research roadmap for Project Arsenal.

## Purpose

This document is the program-level overview for Arsenal's research work. It references `products/arsenal/docs/arsenal-experiment-contract.md` for the operating thesis and `products/arsenal/docs/research-provenance-and-reproducibility.md` for provenance rules. It does not duplicate the thesis in full and it does not modify the closed protocol enums in `scripts/arsenal_protocol.py`.

## Thesis

See `products/arsenal/docs/arsenal-experiment-contract.md`, section "The Arsenal thesis".

## Prioritized research roadmap

The roadmap is a DAG. Dependencies are explicit; programs that are genuinely independent may progress in parallel.

```text
ARS-000 Research Operating Contract (foundation, mandatory)
  ├── ARS-001 Execution-State Validity Challenge
  │     └── (enables) ARS-005 Evaluator Integrity Challenge
  ├── ARS-003 Graph Operator Comprehension Study
  │     └── (may inform) ARS-005 Evaluator Integrity Challenge
  ├── ARS-002 Semantic Concurrency (deferred until experiment machinery credible)
  ├── ARS-006 Steering Semantics (future program, retained but deferred)
  └── ARS-004 Long-Horizon Repository Health (future program, retained but deferred)
```

ARS-001 and ARS-003 may progress in parallel only where genuinely independent. ARS-005 begins design after ARS-001 infrastructure is credible. ARS-002 is not prioritized until the experiment machinery is credible. ARS-006 and ARS-004 are explicitly retained as future programs but deferred from current work.

## ARS-000 — Research Operating Contract

**Research question:** What is the minimal contract that lets Arsenal run controlled experiments, record negative knowledge, and route promotion candidates to external decisions without creating parallel authority?

**Current state:** Foundation draft. This contract (`products/arsenal/docs/arsenal-experiment-contract.md`) defines the mandatory experiment record fields, the experiment state vocabulary, the readiness gate, evidence discipline, model/harness discipline, and the relationship to Bench, QMR, and promotion packets.

**Protocol location:** `products/arsenal/docs/arsenal-experiment-contract.md`.

## ARS-001 — Execution-State Validity Challenge

**Research question:** What deterministic state must exist outside the model so an agent does not have to infer current operational truth from conversational history?

**Current state:** Designed, with a deterministic pilot executed against a scripted policy. The protocol, fixture generator, harness, scorer, and bounded pilot evidence live under `products/arsenal/evaluation/experiments/ars-001-execution-state/`. The pilot discriminates fixture/harness mechanics only; it is not model evidence.

**Protocol location:** `products/arsenal/evaluation/experiments/ars-001-execution-state/PROTOCOL.md`.

## ARS-003 — Graph Operator Comprehension Study

**Research question:** What representation allows a graph engineer to understand and operate durable agentic work with the least cognitive reconstruction?

**Current state:** Designed (formative). Static, non-authoritative prototypes of three representation concepts (conversation tabs, graph-first, hybrid) over one synthetic graph fixture live under `products/arsenal/evaluation/experiments/ars-003-operator-comprehension/`. Formative classification: single-operator results would not generalize.

**Protocol location:** `products/arsenal/evaluation/experiments/ars-003-operator-comprehension/PROTOCOL.md`.

## ARS-005 — Evaluator Integrity Challenge

**Research question:** Can an implementation appear successful by modifying or weakening the mechanism used to determine success?

**Current state:** Designed (draft protocol; execution gated). Design initiated at `products/arsenal/evaluation/experiments/ars-005-evaluator-integrity/PROTOCOL-DRAFT.md` with a seeded attack catalog (`ATTACK-CASES.md`, ATK-01..ATK-09) and the infrastructure requirements it imposes on the shared harness. Execution begins only after ARS-001 infrastructure is credible.

**Protocol location:** `products/arsenal/evaluation/experiments/ars-005-evaluator-integrity/`.

## ARS-002 — Semantic Concurrency

**Research question:** What happens when multiple capabilities, methods, or agent instructions operate on overlapping repository semantics, and how should Arsenal specify isolation boundaries?

**Current state:** Deferred. This program is not prioritized until the experiment machinery is credible and ARS-001 has produced reproducible execution-state evidence.

**Protocol location:** `products/arsenal/evaluation/experiments/ars-002-semantic-concurrency/` (reserved, empty).

## ARS-006 — Steering Semantics

**Research question:** How should human steering signals (preferences, constraints, overrides) compose with capability contracts and evidence without becoming hidden authority?

**Current state:** Future program, retained but deferred. No active protocol directory is populated.

**Protocol location:** `products/arsenal/evaluation/experiments/ars-006-steering-semantics/` (reserved, empty).

## ARS-004 — Long-Horizon Repository Health

**Research question:** How do repository health signals (architecture drift, capability fragment lifecycle, evaluation status, doctrine alignment) evolve over long-running agent work, and what leading indicators are detectable?

**Current state:** Future program, retained but deferred. It builds on the Repository Recon and Knowledge Plane work but requires longer-running evidence than the current machinery can collect.

**Protocol location:** `products/arsenal/evaluation/experiments/ars-004-long-horizon-repository-health/` (reserved, empty).

## Explicitly deferred distractions

The following topics are out of scope for the current program. They are recorded in the brainstorm registry at `products/arsenal/research/REGISTRY.md` for reconsideration when conditions change:

- Tournament / swarm architectures.
- Self-modifying authoritative workflows.
- Full mobile engineering.
- Giant model-routing benchmark suites.
- Cryptographic provenance infrastructure.
- Workflow marketplaces.
- Drag-and-drop graph authoring.

## Relationship to active Invariant development

- The research branch is parallel to active development. It does not mutate Kiln, Loadout, Manifold, Temper, or Bench contracts.
- Every experiment binds exact `repository_identity` and `runtime_identity`. Stale experiments record currentness boundaries; old evidence is never silently reinterpreted as evidence for a new runtime.
- Cross-product changes that result from research are `PROMOTION_CANDIDATE` until explicitly accepted by the owning product. Arsenal records the external decision as `PROMOTED` for traceability only.
- Existing T3-Challenge / T3-competitive roadmap material is preserved. Arsenal may inform that material but never overwrites it.
