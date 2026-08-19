---
title: Temper
description: Read-only operator workbench over accepted Loadout and Kiln facts.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/temper/README.md
  - products/temper/src/
  - products/temper/test/
  - products/temper/docs/SOURCES.md
audience:
  - developer
  - operator
---

# Temper

Temper is the operator's view into the system, not the system's source of authority.

The current terminal workbench reads a real Loadout Plan and canonical Kiln Run Result and exposes focused views for overview, plan, run, authority, evidence, artifacts, raw result, and help.

## Truthful absence

When a fact is absent from the accepted contract, Temper renders `n/a` with a reason rather than inventing a projection. That is especially important for evidence freshness/contradiction fields not represented by the current Run Result Envelope.

## Repository currentness

Temper can tell the operator whether the repository has moved since the Run. A historical Run can remain valid history while no longer proving the current checkout.

## Boundary

Temper reads and projects. It does not grant authority, execute work, mutate product state, or reach directly into sibling product source trees. The root boundary check enforces the sibling-source-coupling part mechanically.

Future operator actions must preserve this rule: an interaction can request or record a decision through an owning system without making Temper itself canonical execution truth.
