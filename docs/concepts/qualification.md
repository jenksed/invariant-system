---
title: Qualification
description: How Bench qualification evidence differs from selection and runtime authority.
status: experimental
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/arsenal/evaluation/README.md
  - products/arsenal/evaluation/BENCH_CONTRACT.md
  - products/manifold/README.md
audience:
  - developer
---

# Qualification

Qualification asks whether a method or intelligence configuration has enough evidence to be considered for a role.

Bench, inside Arsenal, owns that evidence plane. Its v0 design includes case-health receipts, controlled/counterfactual structure, explicit executed vs designed-not-run arms, evidence passports, and lifecycle gates.

The current 19-case corpus is deliberately mixed: some deterministic cases can execute now; many model/harness comparison arms are still designed-not-run. That is a feature of the evidence model, not missing prose. Bench explicitly refuses to infer model improvement from unexecuted comparisons.

## Qualification is not selection

Bench asks: **Can this configuration perform this role, according to the evidence we actually have?**

Manifold is intended to ask: **Which qualified configuration should perform this work now, given task and runtime constraints?**

Manifold has no runtime today.

## Qualification is not execution authority

Even a fully qualified configuration cannot grant itself repository authority. Kiln evaluates runtime authority for the actual work instance.
