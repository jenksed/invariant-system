---
title: Kiln Roadmap
description: System-facing view of Kiln's durable Session, authority, recovery, evidence, and operator-service responsibilities.
status: planned
verified_at_commit: 325b1b5fe2e65c35bde9a1cd75e099a540b283aa
source_paths:
  - products/kiln/docs/ROADMAP.md
  - products/kiln/docs/IMPLEMENTATION-SLICES.md
  - products/kiln/lib/
  - products/kiln/test/
  - docs/_meta/post-wp09-product-direction.md
audience:
  - developer
---

# Kiln Roadmap

Kiln has the most detailed product-local implementation/authorization record in the system. This page does not replace it and does not authorize Kiln work independently of its accepted lane/process state.

## Evidence-backed baseline

The documentation branch's verified source basis includes durable Run foundations, authority evaluation, artifacts/evidence, registered verification, supervision, result projection, and recovery foundations. The active WP-08/WP-09 implementation state is not present on this remote documentation branch, so its reported progress is not promoted here as demonstrated fact.

## Gate — accepted durable Session/service foundation

Before Workbench Alpha consumes WP-09 capabilities, accepted evidence should establish the exact Session/service/recovery contract and update [Current system status](../status.md).

The important property is not “daemon exists.” It is that canonical governed Session state survives client/UI loss, exposes the facts/actions an operator needs, and does not weaken authority or recovery semantics.

## NEXT — serve the operator product without surrendering authority

Kiln should expose the smallest stable query/action surface Temper needs for:

- current Session/project identity;
- lifecycle and explicit human-attention state;
- activity/evidence/change traversal;
- verification/review/decision state;
- governed human actions;
- recovery/reconciliation state;
- freshness/version identity sufficient for a projection to detect staleness.

Temper should not need direct access to Kiln internals or a duplicate durable workflow database.

## Distributed operation

Remote Temper → Kiln is a near-term system target once local Session/query/action semantics are frozen.

The transport must preserve, rather than emulate loosely:

- Kiln identity and execution-host identity;
- project/repository/Session identity;
- authenticated/authorized actor identity;
- state/version binding for actions;
- explicit stale/conflict responses;
- reconnect/requery behavior;
- interruption and unknown-effect semantics.

Remote operation is not accepted merely because an HTTP request crosses the network.

## Evidence required

- restart/reconstruction tests from authoritative state;
- denial/stale-state/action-binding negative cases;
- recovery cases for interrupted consequential effects;
- public query/action contract tests;
- local Workbench end-to-end proof;
- remote topology proof with forced disconnect/reconnect before remote acceptance.

## Later expansion

Delegated child work, richer isolation, broader provider/runtime support, telemetry, and multi-language/platform work remain evidence-gated. They should be pulled forward only when they protect a property required by the operator product, dogfood, or a separately authorized strategic program.
