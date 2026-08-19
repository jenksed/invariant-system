---
title: Evidence
description: What Invariant means by evidence-backed completion and state-bound proof.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/README.md
  - products/arsenal/evaluation/README.md
  - contracts/run-result-envelope.v0.md
audience:
  - developer
  - operator
---

# Evidence

Invariant uses “evidence” narrowly: an observable result must be tied to a subject, method, state, and scope strongly enough to support the claim being made.

That is why these are deliberately different:

```text
command exited 0
verification evidence says the required property passed
human accepted the result
```

A green command can be useful evidence without being the whole acceptance argument.

## Two evidence planes

**Bench** produces evaluation and qualification evidence about methods/configurations. It preserves case health, counterfactual design, executed vs designed-not-run arms, and lifecycle claim scope.

**Kiln** owns runtime evidence about actual work: authority decisions, effects, artifacts, verification, repository state, and acceptance readiness.

They answer different questions. Bench evidence should not be laundered into runtime permission, and Kiln runtime evidence should not be misrepresented as broad model efficacy.

## Freshness matters

Evidence is only meaningful against the state it observed. If the repository has moved, a prior result may still be historically true but no longer prove the current tree. Temper exposes repository currentness precisely because presentation should not hide that distinction.
