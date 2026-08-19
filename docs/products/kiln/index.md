---
title: Kiln
description: Durable runtime authority, execution truth, effects, evidence, verification, and acceptance state.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/lib/
  - products/kiln/test/
  - products/kiln/README.md
  - products/kiln/docs/
  - integration/scenarios/repository-recon/run.sh
audience:
  - developer
  - operator
---

# Kiln

Kiln exists for the moment when a useful proposal might become a real effect.

It owns the runtime questions that should not be left to the proposing model: whether work is authorized, what repository state is relevant, what executed, what effects occurred, what evidence exists, what verification ran, what state can be recovered after interruption, and what acceptance facts are durable.

## Current implemented foundation

The current monorepo contains real Kiln implementation and tests for a durable single-Run foundation and later integrated work, including:

- Elixir/OTP runtime structure;
- SQLite-backed journal/projection foundations;
- authority evaluation and Work Envelope supervision;
- artifact/evidence substrate;
- registered per-product verification commands;
- Run Result Envelope projection;
- restart/recovery foundations;
- CLI surfaces used by the real Repository Recon integration path.

The published migration record reports 689/689 Kiln tests green in post-migration CI.

## Repository truth vs Kiln truth

Git and the filesystem remain repository source truth. Kiln records work facts, authority decisions, effects, evidence, and recovery state. It should not replace Git with a private alternate model of the repository.

## Failure semantics

Kiln's architecture explicitly cares about blocked, stale, orphaned, and unknown-effect states. A durable system must be able to say “we do not know whether that effect happened” rather than replaying a consequential action because a process died.

## What is not proven complete

The Kiln README and roadmap contain substantial future architecture: child runs, broader provider/runtime slices, deeper execution and recovery semantics. Those are not all current capability. Treat implementation/tests as the boundary for “works today” claims.

## Boundary

Kiln must not absorb Arsenal's R&D intelligence or Bench's model qualification role. It consumes prepared requests and evidence; it remains the runtime authority owner.
