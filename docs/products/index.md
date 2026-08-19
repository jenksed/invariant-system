---
title: Products
description: The Invariant product areas and the boundaries between them.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/
  - invariant.boundaries.json
audience:
  - developer
  - operator
---

# Products

Invariant is one system with several deliberately different owners.

| Area | Question it answers |
| --- | --- |
| [Arsenal](arsenal/index.md) | What engineering intelligence is worth reusing and learning from? |
| [Bench](bench/index.md) | What evidence says a method/configuration is qualified for a role? |
| [Loadout](loadout/index.md) | What does the user want, and how should that intent be prepared for execution? |
| [Manifold](manifold/index.md) | Which qualified intelligence should perform this work now? *(boundary only today)* |
| [Kiln](kiln/index.md) | Is this work authorized, what actually executed, and what evidence exists? |
| [Temper](temper/index.md) | What should the operator see about the accepted plan and runtime truth? |

The architecture only works if those answers remain separable. A product can consume another product's facts without inheriting its authority.
