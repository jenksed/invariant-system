---
title: Branch Policy
description: Branch semantics and the promotion path from work/experiment through dev to main.
status: current
verified_at_commit: 1dcb5466debe6d443d6a0fb648ae8eea73d2b128
source_paths:
  - AGENTS.md
  - docs/development/engineering-process.md
  - invariant.boundaries.json
audience:
  - developer
  - operator
---

# Branch Policy

This document defines the minimum branch semantics needed to integrate accepted work safely. Branch names are labels, not evidence.

## Branches and what they mean

| Branch class | Purpose | Promotion prerequisite |
| --- | --- | --- |
| `main` | Deliberate release / integrated baseline | Integrated-system qualification + explicit release decision |
| `dev` | Persistent qualified integration line | Each accepted work item has candidate identity + persisted evidence |
| `work/*` | Bounded implementation work | Implementation + targeted tests + lane evidence |
| `experiment/*` | Experimental or product-qualification work | Same evidence rules as `work/*`; may additionally require re-execution before promotion |

## Promotion path

```text
work/*  /  experiment/*
        │
        ▼
evidence + human acceptance
        │
        ▼
dev
        │
        ▼
integrated-system qualification
        │
        ▼
main
        │
        ▼
deliberate release baseline
```

## Distinct states

The following are distinct and must not be collapsed:

- `HUMAN_ACCEPTED` — a human decision record exists for the candidate SHA.
- `REPOSITORY_EVIDENCE` — LANE-EVIDENCE artifacts, executable commands, or other repository-visible evidence survive for that decision.
- `MERGED_TO_DEV` — the candidate SHA has been merged into `dev`.
- `RELEASED_TO_MAIN` — `dev` has been promoted into `main` after integrated qualification.

A `HUMAN_ACCEPTED` decision is not invalidated when repository-visible evidence is incomplete; reconciliation is required, but the decision persists until superseded.

## Promotion rules

1. **Work and experiment branches enter `dev` only with:** a candidate identity (exact SHA), an acceptance property, and persisted evidence recorded against that SHA.
2. **`dev` enters `main` only after:** an integrated-system qualification that exercises the public boundary, not only branch-local tests.
3. **`main` is read-only with respect to acceptance evidence.** A passing CI or aggregate test count does not by itself justify promotion to `main`.
4. **Branch labels do not override evidence.** A branch named `accepted-*` carries no acceptance until evidence and a human decision are recorded.

## What this policy does not do

- It does not prescribe a Git-flow release cadence.
- It does not redefine product ownership.
- It does not replace [evidence-driven engineering process](engineering-process.md).
- It does not authorize force-push, history rewrite, or remote-main force-update.

## Reconciliation marker

The `integration/dev-reconciliation` branch is reserved for in-progress reconciliation work between `dev` and active `work/*` / `experiment/*` branches. It must not be the destination for accepted work; reconcile into `dev` and continue.