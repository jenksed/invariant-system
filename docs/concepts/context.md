---
title: Context
description: Why Invariant compiles bounded task context instead of accumulating unlimited session history.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant.boundaries.json
  - products/kiln/README.md
  - products/arsenal/
audience:
  - developer
---

# Context

Invariant treats context as an engineering input.

The useful question is not “How much can the model remember?” It is “What does this task need, what is authoritative, what is stale, and what should be excluded?”

Kiln's product definition describes a bounded model package built from accepted objective, criteria, current state, approved instructions, selected source ranges, current failures/evidence, output contract, and limits. Arsenal develops reusable methods for deciding what information matters. Loadout prepares task intent and work envelopes.

The common rule is **compile what the work needs**. Do not silently turn the full transcript, every tool schema, every skill, raw logs, secrets, and stale requirements into ambient authority-bearing context.
