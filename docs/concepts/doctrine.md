---
title: Doctrine
description: The engineering rules encoded in Invariant's root boundary policy.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant.boundaries.json
  - AGENTS.md
audience:
  - developer
---

# Doctrine

Invariant's root boundary policy records six rules:

1. **Determinism over discretion.** Prefer mechanisms whose behavior can be inspected and reproduced when discretion is not required.
2. **Capability is not authority.** Being able to do something is different from being permitted to do it now.
3. **Intelligence can propose. Infrastructure should enforce.** Model reasoning may shape a proposal; system boundaries own enforcement.
4. **Context should be compiled, not accumulated.** A working set should contain what the task needs, not every artifact a session has ever seen.
5. **Completion requires evidence.** “Done” is a claim about observed state, not confidence or narrative.
6. **Test the property, not the proxy.** A convenient green signal matters only if it proves the property under review.

These are not page-copy slogans. They explain otherwise inconvenient architecture. For example, the monorepo deliberately refuses source-level product coupling even though the code now lives together, and Temper remains read-only even though giving the UI mutation power would look convenient.

The constraint is the point: colocating products must not silently collapse their authority boundaries.
