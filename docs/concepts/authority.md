---
title: Authority
description: How Invariant separates capability, qualification, selection, execution authority, and human acceptance.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant.boundaries.json
  - products/manifold/README.md
  - products/loadout/src/core/kiln-driver.ts
  - products/kiln/
audience:
  - developer
  - operator
---

# Authority

A recurring failure mode in agent systems is authority laundering: one component knows how to perform an action, so the system gradually treats that capability as permission to perform it.

Invariant forbids that shortcut.

```text
Arsenal method          → useful way to work
Bench qualification     → evidence a configuration can perform a role
Manifold assignment     → future choice among qualified configurations
Loadout plan            → prepared intent and work envelope
Kiln authority decision → permission evaluated at execution time
Human decision          → acceptance/revision where the workflow requires it
```

None of the earlier facts can impersonate the later one.

## Runtime owner

Kiln owns runtime authority. Loadout can request capabilities in a Work Envelope, but its real Kiln driver only invokes the procedure when Kiln returns granted authority. The driver fails closed when Kiln is unavailable, malformed, exits unsuccessfully, or claims a supposedly real result is simulated.

## Non-authorities

- Arsenal does not grant mutation authority.
- Bench does not select runtime assignments as authority.
- Manifold must not grant or expand Kiln authority.
- Loadout does not grant runtime authority.
- Temper does not create authority by rendering it.
- A receipt records evidence/decisions; it does not retroactively create permission.

## Human authority

Invariant does not treat human involvement as decorative approval after autonomous completion. Where acceptance or exact mutation approval is part of the workflow, that decision is a distinct fact with its own state and provenance.
