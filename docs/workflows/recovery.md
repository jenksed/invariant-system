---
title: Recovery
description: Why durable execution must preserve uncertainty instead of replaying unknown effects.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/README.md
  - products/kiln/lib/
  - products/kiln/test/
audience:
  - developer
---

# Recovery

A process crash is not permission to pretend the last effect never happened.

Kiln's recovery model exists to distinguish durable facts from uncertain effects. If execution was interrupted after a consequential action may have crossed the boundary, the safe state can be “unknown” or “requires reconciliation,” not automatic replay.

The current Kiln codebase contains journal/recovery foundations, but the full future interruption matrix should be documented slice by slice as it becomes executable.

The architectural rule is already stable: **retries require effect semantics and idempotency knowledge, not optimism.**
