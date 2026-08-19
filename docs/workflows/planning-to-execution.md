---
title: Planning to Execution
description: How Loadout preparation crosses into Kiln runtime authority without collapsing the boundary.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - contracts/work-envelope.v0.md
  - products/loadout/src/core/kiln-driver.ts
  - products/kiln/
audience:
  - developer
---

# Planning to Execution

Loadout can decide what should be attempted and encode that request. It cannot decide that the attempt is authorized.

The Work Envelope is the boundary object between those concerns.

Current Repository Recon path:

```text
Goal
→ Capability resolution
→ Plan
→ Work Envelope
→ Kiln authority evaluation
→ supervised execution / observation
→ Run Result Envelope
```

The important property is not the serialization format. It is that the boundary preserves ownership: a Work Envelope is a request, not a grant.
