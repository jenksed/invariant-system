---
title: Temper Roadmap
description: Turn Temper into the project workbench and remote operator surface without moving canonical execution authority out of Kiln.
status: planned
verified_at_commit: fed26fcc8b7598a56ce86e47c99d0154e6b46436
source_paths:
  - products/temper/README.md
  - products/temper/src/
  - invariant.boundaries.json
  - docs/_meta/post-wp09-product-direction.md
audience:
  - developer
  - operator
---

# Temper Roadmap

## Evidence-backed baseline

The branch's current documented evidence supports truthful read-only projection of real Plan/Run Result facts. Newer active engineering work must be reconciled before this page upgrades current capability claims.

The canonical boundary currently assigns Temper `operator experience` and `projection`. Everything below that adds action initiation is planned control-surface behavior until implementation, contract, and boundary evidence establish otherwise.

## NEXT — Workbench Alpha

Primary entry point:

```text
temper .
```

The command should discover/identify the current project and open a project-centric workbench over canonical governed state.

### Required operator surfaces

- current project/repository identity;
- current governed Session and lifecycle state;
- explicit `ATTENTION` when human action is required;
- live/recoverable activity and evidence traversal;
- changes and exact state basis;
- verification results;
- independent review state;
- explicit HumanDecision state/action where the owning contract supports it;
- truthful missing/stale/unknown rendering.

### Governed actions

Planned behavior: Temper may initiate an action request. It must delegate the authoritative operation to Kiln (or another explicitly owning component), then project the resulting canonical state. A UI event is not the durable decision record.

This does not add `governed action initiation` to Temper's current `owns` boundary. If implementing the Workbench genuinely requires that architectural ownership to change, freeze that decision explicitly before dependent implementation.

### Zed handoff

Temper may hand source editing/context to Zed. The adapter should transfer only what the editor needs: project/path/context and navigation/editing intent. It must not create a bypass around Kiln-governed execution/mutation authority.

### UI-loss recovery

Kill Temper completely. Start it again. It should reconstruct the current project/Session/action state from Kiln rather than from Temper-local workflow memory.

## STRETCH — remote Temper → Kiln

Operate Temper on a different machine from the repository/execution host while preserving the same authority and recovery properties.

Required concerns include:

- explicit Kiln/service identity;
- project/repository/Session identity independent of local path coincidence;
- authenticated/authorized action transport;
- freshness/staleness representation;
- disconnect/reconnect and resubscription/requery behavior;
- no transfer of execution authority to the operator host.

## Acceptance evidence

Prefer end-to-end operator evidence over component screenshots:

1. start from a repository directory;
2. open the Workbench through the intended public entry point;
3. observe canonical current state;
4. exercise a real required human action through Kiln;
5. verify the resulting durable state/evidence;
6. terminate/restart Temper and reconstruct the Session;
7. for remote acceptance, repeat across distinct hosts and force disconnect/reconnect.

A polished interface without those properties is not Workbench acceptance.
