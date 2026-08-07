# AGENTS.md

Doctrine-Version: 1.0.0

## Authority

This repository is developed under the Engineering Doctrine maintained in `project-arsenal`.

The doctrine is not aspirational guidance. It is the default decision framework for planning, implementation, review, verification, and declaring work complete. Project-specific requirements may specialize these principles. When a requirement creates a meaningful tradeoff against the doctrine, identify that tradeoff explicitly rather than silently ignoring the doctrine.

## Paramount Engineering Principles

1. Prefer deterministic mechanisms over discretionary reasoning where practical.
2. Completion requires evidence, not assertion.
3. Think architecturally ahead; implement speculative machinery only when justified by evidence or credible failure modes.
4. Centralize real invariants; do not abstract code merely because it looks similar.
5. Preserve important optionality cheaply; do not pay indefinitely for hypothetical flexibility.
6. Scale rigor with impact, irreversibility, uncertainty, and blast radius.
7. Encode meaningful invariants structurally through types, schemas, constraints, permissions, policies, tests, and authoritative boundaries.
8. Separate concepts before separating processes; distribution requires justification.
9. Use opinionated tools aggressively where their opinions are unimportant; retain control where behavior defines the product.
10. Significant architecture must answer a real or credible failure mode.

**Operating principle:** Think broadly. Implement narrowly. Constrain deliberately. Verify with evidence.

## Project-Specific Engineering Constraints

<!--
Document repository-specific invariants, architectural boundaries, language/tooling
requirements, compatibility commitments, security constraints, and deliberate
exceptions to the doctrine here.
-->

## Required Work Loop

### Before implementation

1. Understand the requested outcome and the existing system before changing it.
2. Identify relevant invariants, contracts, boundaries, and credible failure modes.
3. Separate present requirements from speculative future architecture.
4. For substantial refactors, characterize behavior that must be preserved before changing structure.
5. Define how completion will be verified.

### During implementation

1. Prefer the smallest coherent, verifiable change that advances the requested outcome.
2. Use deterministic feedback as early as practical.
3. Preserve existing behavior and compatibility unless change is intentional and justified.
4. Keep consequential operations bounded and observable enough to diagnose failure.
5. Do not introduce abstractions, services, agents, frameworks, or dependencies without identifying the leverage or failure mode they address.
6. Encode important invariants in authoritative mechanisms rather than relying only on comments or prompts.

### Before declaring completion

1. Run the repository's applicable deterministic verification.
2. Inspect the resulting diff and final state, not only command exit codes.
3. Confirm the requested acceptance criteria or outcome.
4. Report the evidence that supports completion.
5. State unresolved uncertainty, skipped checks, or known limitations explicitly.

## Engineering Doctrine Check for Substantial Work

For architecture, persistence, public contracts, permissions, consequential mutation, or substantial refactoring, answer these questions in the plan, task, PR, or completion record as appropriate:

### Invariants
What truths must remain true?

### Failure modes
What credible failure modes influence this design?

### Future architecture
What likely future needs were considered but intentionally not implemented?

### Blast radius
What can this change mutate, break, expose, or make difficult to reverse?

### Verification
What deterministic evidence will prove the change correct?

## Verification

<!--
Replace this section with the repository's authoritative commands, for example:

    ./scripts/verify

or language-specific checks. A task must not be reported complete when required
verification is failing or has not been run, unless the limitation is explicitly
reported and completion is not claimed.
-->

## Full Doctrine

Maintain a project-local reference or link to the adopted Engineering Doctrine when useful. The canonical source lives in `project-arsenal/engineering/doctrine/ENGINEERING_DOCTRINE.md`.
