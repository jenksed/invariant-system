# Arsenal Bench & Evaluation Lab

Status: ARS-02 v0

Arsenal Bench exists to answer a harder question than whether an output looks good:

> **Does the same agent do better engineering with an Arsenal capability than without it?**

Bench is not a leaderboard generator. It is an evidence system for capability behavior, counterfactual comparison, lifecycle promotion, and retained losses.

## Core rules

1. **Test the benchmark before the benchmark tests the agent.** Every case carries a Case Health contract and executed cases emit a Case Health Receipt.
2. **Preserve the counterfactual.** Control, treatment, and ablation arms are first-class evidence. Unexecuted arms remain explicitly `designed-not-run`; they are never silently inferred.
3. **Hold the world still.** Comparisons must preserve task, starting repository state, model, harness, tools, budget, and verifier unless a declared variable is the thing under test.
4. **Independent verification beats self-report.** The system under test does not get to grade its own success when a held-out deterministic verifier is possible.
5. **Publish losses.** Regressions, neutral results, blocked runs, and negative efficiency tradeoffs remain in the record.
6. **Lifecycle is earned.** A capability cannot reach `testing` merely because an evaluation suite exists. Required cases must be active, actually executed, healthy, and passing under the declared lifecycle gate.
7. **Do not overclaim.** Deterministic contract evidence is not model-efficacy evidence. Local-emulator evidence is not provider evidence. One campaign is never enough for `stable`.

## Signature evidence surfaces

### Case Health Receipt

Before a case may contribute lifecycle evidence, Bench records whether its starting state is reproducible, its expected outcome is observable, its verifier is sufficiently independent, and the case avoids hidden authority or credential requirements. A broken benchmark should fail before it gets to judge the agent.

### Counterfactual / Ablation Receipt

Every case declares what is held constant and what changes between control, treatment, or ablation arms. Bench records which arms actually ran. A treatment-only deterministic run may prove a contract invariant, but it cannot be marketed as model improvement.

### Capability Evidence Passport

Bench receipts contain a compact passport section for the capability under test: capability/version, lifecycle/evaluation state, suite, executed cases, known unexecuted cases, claim scope, and evidence location. Later ARS-07 observability can enrich this with model/harness history, cost, and longitudinal regressions.

## v0 corpus

`evaluation/cases/core-engineering.json`

- 8 high-signal Core Arsenal agent cases;
- control/treatment and ablation designs;
- intentionally `designed-not-run` until an actual model/harness executes them.

`evaluation/cases/local-cloud.json`

- 11 former-FLC-06 / Local Cloud cases;
- 5 deterministic routing/boundary cases active in v0;
- 6 deeper runtime or agent cases preserved as designed-not-run;
- a lifecycle gate capable of earning `capability.local-cloud-feature-delivery` the `testing` state, but only after the active cases execute successfully.

Total v0 corpus: **19 cases**.

## Commands

Validate the corpus and contract:

```bash
python3 scripts/arsenal_bench.py validate
python3 scripts/test-arsenal-bench.py
```

Execute the deterministic Local Cloud candidate suite:

```bash
python3 scripts/arsenal_bench.py run \
  --suite local-cloud \
  --receipt .arsenal-bench/local-cloud-receipt.json
```

Validate a lifecycle claim against that exact receipt:

```bash
python3 scripts/arsenal_bench.py lifecycle \
  --capability capability.local-cloud-feature-delivery \
  --receipt .arsenal-bench/local-cloud-receipt.json
```

## What v0 does not claim

ARS-02 v0 does **not** claim that Arsenal improves Codex, Claude, MiniMax, or any other model merely because the deterministic Local Cloud suite passes. Agent/model efficacy requires actual controlled runs with complete model, harness, tool, budget, and repository-state provenance.

The Core cases are therefore valuable even while unexecuted: they define the experiment without fabricating the result.
