# Engineering Doctrine — Constitutional Core

Doctrine-Version: 1.0.0

These principles govern planning, implementation, review, verification, and completion. Project-specific instructions may specialize them, but should not silently weaken them.

1. **Prefer deterministic mechanisms over discretionary reasoning where practical.** Use compilers, types, schemas, constraints, policy engines, tests, static analysis, and deterministic programs to decide what they can decide reliably.
2. **Completion requires evidence, not assertion.** A task is complete only when the requested state exists and the agreed verification supports that claim.
3. **Think architecturally ahead; implement on evidence.** Explore likely future boundaries and failure modes early, but do not make today's system carry speculative machinery without justification.
4. **Centralize invariants, not resemblance.** Similar-looking code is not automatically one abstraction. Important correctness, security, compatibility, and policy invariants should have authoritative homes.
5. **Preserve important optionality cheaply.** Avoid irreversible choices when a low-cost seam can preserve future options, but do not pay indefinitely for hypothetical flexibility.
6. **Scale rigor with impact, irreversibility, uncertainty, and blast radius.** Consequential mutations require stronger controls than bounded, reversible, read-only behavior.
7. **Encode meaningful truths structurally.** Move important mistakes as early as reasonably possible through types, schemas, constraints, permissions, tests, and authoritative boundaries.
8. **Separate concepts before separating processes.** Domain boundaries do not automatically require services, agents, processes, or network hops.
9. **Use opinionated tools aggressively where their opinions are unimportant.** Retain control where behavior defines the product, its reliability, security, economics, or differentiation.
10. **Architecture must answer a real or credible failure mode.** Significant machinery should have a defensible reason for existing.

## Operating Principle

**Think broadly. Implement narrowly. Constrain deliberately. Verify with evidence.**

When these principles conflict, identify the tradeoff explicitly rather than silently choosing one.
