---
title: Bench
description: Evaluation and qualification evidence inside Arsenal.
status: experimental
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/arsenal/evaluation/README.md
  - products/arsenal/evaluation/BENCH_CONTRACT.md
  - products/arsenal/evaluation/cases/
  - products/arsenal/scripts/arsenal_bench.py
audience:
  - developer
---

# Bench

Bench exists to make qualification claims expensive enough to mean something.

Its core question is not “Did the output look good?” It is whether controlled evidence supports a capability or configuration claim while preserving the counterfactual and the benchmark's own health.

## Current v0 evidence model

Bench documents and implements concepts for:

- **Case Health** — a broken benchmark should fail before grading the subject;
- **Control / treatment / ablation** — what changed and what stayed constant;
- **Executed vs designed-not-run** — unexecuted arms remain explicitly unexecuted;
- **Capability Evidence Passport** — compact claim scope and evidence location;
- **Lifecycle gates** — maturity is earned from required evidence, not declared by file presence.

## Corpus

The v0 corpus contains **19 cases**:

- 8 Core Arsenal engineering cases;
- 11 Local Cloud cases;
- a mix of active deterministic cases and intentionally designed-not-run deeper/model cases.

This does not prove universal model efficacy. Bench's own README explicitly rejects that inference.

## Commands

From `products/arsenal`:

```bash
python3 scripts/arsenal_bench.py validate
python3 scripts/test-arsenal-bench.py
```

The root gate includes those checks as part of:

```bash
./invariant test arsenal
```

## Boundary

Bench can produce evidence that a configuration is qualified for a role. It does not select the live assignment and does not grant Kiln authority.
