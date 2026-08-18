---
title: Manifold Roadmap
description: Trigger conditions and boundaries for introducing intelligence selection runtime.
status: planned
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/manifold/README.md
  - invariant.boundaries.json
  - products/arsenal/evaluation/
audience:
  - developer
---

# Manifold Roadmap

Manifold should remain documentation-only until selection is a real product problem.

## Trigger for implementation

A runtime becomes justified when a workflow has more than one qualified intelligence configuration and needs an evidence-backed decision among them under task/runtime constraints.

If Development Loop v0 can prove the authority/evidence chain with one explicitly chosen qualified configuration, building a generic selector first is unnecessary coupling.

## First bounded milestone

**Problem:** select among multiple already-qualified configurations without re-performing qualification or granting execution authority.

**Prerequisites:** Bench qualification evidence with stable identity/scope; explicit role requirement; task/runtime constraints; accepted assignment output contract; Kiln consumer boundary.

**Acceptance property:** selection only chooses among eligible evidence-backed candidates, records why, cannot fabricate qualification, and cannot expand Kiln authority.

**Evidence required:** deterministic candidate filtering, stale/missing qualification cases, tie/constraint behavior, exact source evidence in assignment decision.

## Non-goals

Do not make the first Manifold runtime a generic workflow engine, agent fleet manager, mutation service, model benchmark, or authority broker.
