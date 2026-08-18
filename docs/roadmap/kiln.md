---
title: Kiln Roadmap
description: System-facing view of Kiln's accepted bounded implementation sequence.
status: planned
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/docs/ROADMAP.md
  - products/kiln/docs/IMPLEMENTATION-SLICES.md
  - products/kiln/lib/
  - products/kiln/test/
audience:
  - developer
---

# Kiln Roadmap

Kiln has the most detailed product-local implementation/authorization record in the system. This page does not replace it.

## NOW

Current code includes durable single-Run foundations plus integrated authority, evidence/artifact, registered-verification, supervision, result-projection, and recovery work used by the monorepo integration path.

## NEXT

Kiln's accepted roadmap sequences evidence-backed Single-Run change work before delegated child-run work. Its historical plan names exact ticket/authorization gates; those gates remain the authority for Kiln implementation, not this system documentation.

For the system Development Loop, the decisive milestone is:

**Problem:** one authorized exact code proposal must become an observable repository effect with state-bound verification and recoverable evidence.

**Prerequisites:** the currently accepted Kiln slice sequence and any required owner authorization; exact base-state/mutation ownership; artifact/evidence substrate; registered command boundary.

**Acceptance property:** denied/stale/unbound proposals cannot mutate; accepted exact mutation produces durable effect/evidence state; interruption cannot silently become success or unsafe replay.

**Evidence required:** negative authority/state tests, mutation digest/base-state evidence, durable journal/projection, registered verification against resulting state, recovery/reconciliation cases.

## LATER

Kiln's roadmap places independent read-only verifier child work after accepted Single-Run runtime evidence. That dependency is important: independent falsification should not be simulated by self-review inside the implementing Root Run.

## FRONTIER

Broader TUI, managed mutation isolation, richer code intelligence, telemetry, remote execution, and multi-language pack/platform work remain evidence-gated expansion rather than prerequisites for Development Loop v0.
