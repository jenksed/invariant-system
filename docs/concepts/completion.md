---
title: Completion
description: Why Invariant separates proposed, applied, executed, verified, accepted, and delivered states.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/README.md
  - products/kiln/lib/
audience:
  - developer
  - operator
---

# Completion

“Done” is overloaded in software work. Invariant keeps the underlying facts separate:

```text
Proposed → Applied → Executed → Verified → Accepted → Delivered
```

A model can produce a proposal without a mutation. A mutation can exist before verification. Verification can pass before the human accepts the result. A receipt can describe those facts without changing them.

Kiln is designed to make completion a projection over durable facts rather than a sentence generated at the end of a conversation.

The exact completion rules continue to evolve with Kiln's implementation slices, so documentation should not claim the entire future state machine exists today. The invariant that survives those slices is simpler: completion cannot be inferred from model confidence, exit zero, or a persuasive summary.
