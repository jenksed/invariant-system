---
title: Loadout Roadmap
description: Advance from current planning and real Kiln supervision toward a bounded code-change request path.
status: planned
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/loadout/src/
  - products/loadout/tests/
  - contracts/work-envelope.v0.md
  - integration/scenarios/repository-recon/
audience:
  - developer
---

# Loadout Roadmap

## NOW

Loadout has a real user-facing planning surface, simulated boundary, real fail-closed Kiln driver, Repository Recon, and verify-change work in the current source tree.

## NEXT

**Milestone:** prepare one real Development Loop code-change request through existing capability/Plan/Work Envelope concepts.

**Problem:** current Repository Recon proves a read-oriented golden path; code mutation needs exact intent/criteria/state requirements without Loadout becoming execution policy.

**Prerequisites:** reconcile existing verify-change schema/path with the exact Kiln change slice and canonical contracts.

**Acceptance property:** Loadout can express the requested bounded change and required verification while remaining unable to grant authority or claim completion.

**Evidence required:** schema/fixture tests, negative capability/authority cases, real consumer compatibility tests.

**Blocker:** any new semantic field that affects runtime authority is a cross-product contract decision, not a Loadout-only implementation detail.

## LATER

Richer capability discovery/configuration and operator-facing planning UX are safe only if they continue to produce explicit requests rather than hidden execution decisions.
