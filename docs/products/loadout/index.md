---
title: Loadout
description: Human-facing goals, capabilities, planning, and Work Envelope preparation.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/loadout/src/
  - products/loadout/tests/
  - products/loadout/package.json
  - contracts/work-envelope.v0.md
  - integration/scenarios/repository-recon/run.sh
audience:
  - developer
  - operator
---

# Loadout

Loadout turns user intent into a bounded attemptable plan.

A user starts with a goal such as “Understand this repository.” Loadout resolves the relevant capability/configuration, prepares a Plan, compiles a Work Envelope, and can execute against either a deterministic simulated boundary or the real Kiln supervision boundary.

## What exists now

- CLI and minimal web surface;
- capability catalog/install/inspect flows;
- bundled `repository-recon` and `verify-change` work;
- Plan and Work Envelope compilation;
- deterministic simulated execution for bounded product behavior;
- real Kiln driver using exact argv, temp-file Work Envelope transport, canonical Run Result validation, timeout handling, and fail-closed error classes;
- run records consumed by Temper.

## Real Kiln boundary

`src/core/kiln-driver.ts` is explicit about the trust boundary. It does not shell-interpolate a command and does not manufacture success when Kiln fails. A supposedly real response labeled `simulated: true` is rejected.

In the current Repository Recon integration, Loadout runs the read-only procedure only after Kiln grants requested authority.

## What Loadout does not own

Loadout can prepare and request work. It cannot grant runtime authority or become durable execution truth. Those are Kiln responsibilities.

## Current limitation

Repository Recon is the clearest real cross-product path. The broader Development Loop for governed code mutation and review is not complete merely because Loadout can produce Plans or invoke Kiln.
