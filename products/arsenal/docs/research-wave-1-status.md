# Arsenal Research Wave 1 — Status and Restart

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**

Status: paused (2026-08-19), work preserved on branch `research/arsenal-program-foundation`
Owner: ARS-00
Scope: What was built in the opening research wave, what is verified, what is unproven, and how to resume.

## Branch and isolation

- Branch: `research/arsenal-program-foundation`, created from `origin/main` at `cae5375` (`docs: record post-publication CI verification results`).
- Worktree used during the wave: `/Users/jenksed/Developer/invariant-system-worktrees/arsenal-research`.
- No active application-development branch or worktree was modified. Nothing was merged to `main`. Nothing in `contracts/`, `integration/`, `program/`, or `products/{kiln,loadout,temper,manifold}` was touched.
- The T3-Challenge / T3-competitive roadmap material is preserved untouched. Note: `docs/Invariant 30-Day T3-Competitive Roadmap and Evidence Audit — Parallel Agent Prompt.md` exists only as an **untracked file in the main checkout** and is not version-controlled; decide deliberately whether to commit it (outside this branch's scope).

## What exists now (all paths under `products/arsenal/`)

| Artifact | Path | State |
|---|---|---|
| Research reconciliation (archaeology) | `docs/research-reconciliation.md` | draft |
| ARS-000 Research Operating Contract | `docs/arsenal-experiment-contract.md` | draft |
| Program overview + roadmap DAG | `docs/arsenal-research-program.md` | draft |
| Provenance + reproducibility rules | `docs/research-provenance-and-reproducibility.md` | draft |
| Brainstorm / candidate registry (BR-001..BR-014) | `research/REGISTRY.md` | draft |
| Experiment registry | `evaluation/experiments/README.md` | draft |
| Protocol template | `evaluation/experiments/PROTOCOL-TEMPLATE.md` | draft |
| Protocol JSON Schema | `evaluation/experiments/experiment-protocol.schema.json` | draft, parses as JSON |
| Evidence manifest template | `evaluation/experiments/EVIDENCE-MANIFEST.md` | draft |
| Negative Knowledge Catalog (NK-001..NK-005) | `evaluation/negative-knowledge/CATALOG.md` | draft, seeded from existing repo evidence |
| Promotion packet template | `evaluation/promotion/PACKET-TEMPLATE.md` | draft |
| ARS-001 protocol + fixture + harness + pilot | `evaluation/experiments/ars-001-execution-state/` | DESIGNED; bounded pilot executed |
| ARS-003 formative protocol + static prototype | `evaluation/experiments/ars-003-operator-comprehension/` | DESIGNED (formative); prototype generated |
| ARS-005 protocol draft + attack catalog | `evaluation/experiments/ars-005-evaluator-integrity/` | DESIGNED; execution gated on ARS-001 |

## Verified evidence (what was actually run)

1. `./invariant test arsenal` — exit 0 (full Arsenal Python gates pass on this branch).
2. `./invariant check boundaries` — all checks ok.
3. `./invariant check` — passes on the main checkout (exit 0). **Environment limitation:** it fails inside a worktree with `FAIL: no .git at monorepo root` (`invariant:108` requires `.git` to be a directory; worktrees have a `.git` file). This is pre-existing harness behavior, not caused by this branch.
4. `git diff --check` — clean.
5. ARS-001 harness determinism: `python3 harness.py determinism-check` — PASS (fixture digest `bacbd707…`, run digest `73d412be…`, identical across two runs).
6. ARS-001 pilot: 36 cells (C0/C1/C2 × P-01..P-12) executed; results artifact at `evaluation/experiments/ars-001-execution-state/evidence/pilot-0/results.v0.json` (schema `arsenal/ars-001-pilot/v0`, run_digest `ef135de9…`).
7. ARS-003 prototype determinism: `graph-fixture.json` sha256 `dd6af903…` identical across two generator runs; all three static renderings emitted with non-authoritative banners.

## What is NOT proven (do not overclaim)

- The ARS-001 pilot used `deterministic-scripted-policy-v0` — **not a model**. Its evidence discriminates fixture/harness mechanics and condition plumbing only. It says nothing about how any real model behaves under C0/C1/C2. `token_consumption` and `time_to_objective_completion` are recorded as not-observed.
- ARS-003 has produced no operator sessions; the task battery is unscored. It is formative research and would not generalize even once run with a single operator.
- ARS-005 is a design draft. No attack has been executed; no defense has been evaluated.
- No experiment has entered READY/RUNNING under the ARS-000 readiness gate with a frozen protocol. The registry states remain DESIGNED/IDEA.
- Nothing here is a promotion candidate. No promotion packet has been authored.

## Restart instructions

1. `git worktree list` — reuse `/Users/jenksed/Developer/invariant-system-worktrees/arsenal-research` if present, else `git worktree add <path> research/arsenal-program-foundation`.
2. Read `docs/arsenal-experiment-contract.md` (ARS-000) first; it governs everything else.
3. Re-verify before new work: `./invariant test arsenal` and `./invariant check boundaries` from the worktree (expect `check` to fail in-worktree per the environment note above; run it from the main checkout if needed).
4. Next highest-value steps, in order:
   - **ARS-001 readiness gate review**: audit `ars-001-execution-state/PROTOCOL.md` against the ARS-000 gate; if it passes honestly, bump state to READY and freeze `protocol_version` with `protocol_frozen_at`. Model-in-loop repetitions require a new protocol version declaring model_identity, seed policy, and repetition counts — do not reuse the scripted-policy pilot as model evidence.
   - **ARS-003 formative session**: run one operator through `prototype/tasks.md` against the three static renderings; record answers/timing per the protocol's counting rules.
   - **ARS-005**: keep gated until ARS-001's harness pattern is judged credible; its infrastructure requirements are enumerated in `PROTOCOL-DRAFT.md`.
5. Evidence rules on resume: preserve raw runs, record not-observed metrics honestly, log negative findings in `evaluation/negative-knowledge/CATALOG.md`, and route any proposed runtime change through `evaluation/promotion/PACKET-TEMPLATE.md` for an external decision.

## Model/harness record for this wave

Foundation docs, registries, templates, protocols, and harnesses were produced by delegated fixer/explorer agents under orchestration (Kimi k3-256k orchestrator). Per the contract, agent output is not itself experimental evidence; the only experimental evidence in this wave is the deterministic ARS-001 pilot and the ARS-003 fixture-determinism check listed above, both reproducible from the committed scripts.
