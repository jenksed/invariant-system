---
title: Manifold
description: Planned intelligence selection and allocation boundary.
status: planned
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/manifold/README.md
  - invariant.boundaries.json
audience:
  - developer
---

# Manifold

Manifold has a real architectural boundary and **no runtime implementation**.

Its intended question is:

> Given a role requirement, task characteristics, runtime constraints, and qualification evidence, which qualified intelligence configuration should perform this work now?

## Inputs

- role requirement;
- task characteristics;
- runtime constraints such as cost/latency/availability/tooling;
- qualification evidence from Bench and related records.

## Output

An intelligence assignment/selection decision with the evidence on which it was based.

## Why the boundary exists before the runtime

Selection is a distinct concern. If Loadout, Bench, or Kiln quietly starts choosing live intelligence as an incidental feature, later Manifold implementation would inherit hidden coupling and conflicting authority.

The empty runtime is therefore intentional architectural pressure: do not build it until the Development Loop genuinely needs selection among multiple qualified configurations.

## Non-authority

Manifold must not execute work, mutate repositories, grant/expand Kiln authority, qualify models, fabricate evidence, or become a generic fleet/workflow engine.
