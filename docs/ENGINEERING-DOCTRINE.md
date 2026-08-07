# Engineering Doctrine

Doctrine-Version: 1.0.0

**Project status:** Accepted default engineering decision framework  
**Scope:** Planning, design, implementation, review, and verification decisions  
**Authority boundary:** This doctrine does not authorize product scope, override accepted ADRs or invariants, or supersede an accepted work plan. It resolves choices that remain open inside those authorities.

## Provenance and adoption

**Upstream source:** `engineering/doctrine/ENGINEERING_DOCTRINE.md` in `project-arsenal` (`git@github.com:jenksed/project-arsenal.git`)  
**Adopted at upstream commit:** `2e704fe1ef2dfd5142625c6987c04b9c4de6cea0`  
**Tracked version:** the `Doctrine-Version` declared at the top of this file, which matches the upstream version at that commit

Kiln adopts this doctrine from Project Arsenal instead of authoring it locally. The numbered principles, the decision heuristics, and the meta-principle below are adopted without local modification. The status, scope, authority boundary, and Kiln application guidance in this file are Kiln-local.

Project Arsenal is reusable engineering material for building Kiln. It is not a Kiln runtime component, not a Kiln dependency, and it holds no authority over Kiln scope, ADRs, invariants, or the accepted work plan. Arsenal vocabulary is not Kiln domain vocabulary; Kiln domain terms come only from Kiln documents. An agent working in Kiln does not need to read Project Arsenal to apply this doctrine.

Record intentional divergence from the upstream text in this section with its reason, and change the Doctrine-Version when upstream text is deliberately re-adopted. Undocumented drift is a defect.

## Applying this doctrine in Kiln

Use the doctrine when a material engineering choice is still open after current scope, architecture, ADRs, invariants, and the accepted work plan are applied.

For material design or review decisions, prefer a short explanation that answers the relevant questions rather than mechanically citing every principle:

- What can be decided or enforced deterministically?
- What remains model judgment, and what must infrastructure enforce?
- What exact Evidence will make the result trustworthy?
- What Capability and blast-radius boundary is appropriate?
- What credible failure mode justifies the mechanism?
- What future option should remain cheap to preserve?
- What must be observable, interruptible, recoverable, or idempotent?
- Which behavior is strategically Kiln-owned, and which behavior is commodity?

Do not turn the doctrine into ceremony. Apply the principles that materially change the decision, record important tradeoffs where the project already records design rationale, and preserve simpler choices when extra machinery would not buy meaningful control.

This doctrine is the default decision framework for technical work. It is not a substitute for judgment; it is a set of strong defaults that make tradeoffs explicit.

## 1. Determinism over discretion

If a compiler, type system, schema, policy, test, static analyzer, constraint, or deterministic program can reliably make a decision, prefer that over asking a human or model to reason through it repeatedly.

**Limit:** Do not create disproportionate machinery to deterministically decide low-value things.

## 2. Models belong inside engineered systems

LLMs may reason, plan, interpret, and generate. They should not implicitly become persistence models, permission systems, workflow engines, schedulers, verifiers, or security boundaries.

**Rule of thumb:** Intelligence may propose; infrastructure should enforce.

## 3. Compile context

Context is a working set, not a history dump. Construct it deliberately from relevant intent, requirements, code, state, evidence, permissions, hypotheses, constraints, and token budget. Remove stale and redundant material.

## 4. Completion requires evidence

A task is not complete because an engineer or agent says it is. The requested state must exist and the agreed verification must support that claim.

## 5. Feedback loops determine achievable quality

Generation capability matters, but evaluation determines which mistakes survive. Invest heavily in compilers, static analysis, tests, domain validators, independent verification, reproducible environments, and deterministic tooling.

## 6. Autonomy should be capability-scoped

Read, write, execute, deploy, communicate externally, access secrets, and destroy state are different privileges. Grant them independently and proportionally.

## 7. Separate agents for engineering reasons

Create separate agents or runs when there is a useful boundary in context, permissions, verification, concurrency, ownership, or failure isolation. Do not create agent hierarchies merely because organizational metaphors are familiar.

## 8. Think farther ahead than you implement

Architectural exploration is cheap when it remains analysis. Speculative machinery is not.

**Default:** Architect ahead; implement on evidence.

Consider likely future plugins, backends, domain boundaries, scaling limits, and public contracts early. Implement those mechanisms when present requirements or credible failure modes justify them.

## 9. Centralize invariants, not resemblance

Similar-looking code does not automatically deserve one abstraction. Centralize behavior that represents a real invariant, especially around correctness, security, compatibility, or policy. Allow uncertain similarities to remain duplicated until their true shape is understood.

## 10. Separate concepts before separating processes

Strong domain boundaries are valuable. Microservices, processes, agents, and network boundaries are implementation choices. Prefer a structured monolith until independent deployment, scaling, isolation, ownership, or another real constraint justifies distribution.

## 11. Own what makes the product strategically yours

Buy commodity capability. Encapsulate dependencies when substitution or policy control matters. Build aggressively when outsourcing would surrender something central to differentiation, reliability, economics, security, roadmap control, or product capability.

## 12. Frameworks may own boring things

Use productive abstractions enthusiastically where their opinions do not matter. Prefer primitives where behavior itself defines the product.

**Principle:** Convenience should not become architectural governance.

## 13. Compatibility is an obligation, not a prison

Once others depend on a contract, that dependency has real value. Preserve compatibility when reasonably possible. When a contract materially damages the future system, compare the cost of migration with the cost of permanence and migrate deliberately when breaking change is justified.

## 14. Characterize before major refactoring

Before substantial architectural change, understand actual behavior and capture the behavior that must survive. Preserve high-level contracts, then rebuild implementation-oriented tests around the new design rather than preserving accidental structure.

## 15. Encode meaningful truths structurally

Use strong types, schemas, database constraints, runtime validation, permissions, and policy boundaries to encode important invariants.

**Goal:** Move important mistakes as early as reasonably possible.

## 16. Redundant safeguards can be good engineering

DRY is not absolute. Duplicated knowledge is dangerous; layered defense is not necessarily duplication. Important invariants may warrant complementary enforcement in types, application boundaries, persistence boundaries, permissions, and verification.

## 17. Rigor should track blast radius

Required rigor should increase with impact, irreversibility, uncertainty, and blast radius. A bounded read-only experiment and an autonomous production mutation should not face identical controls merely because both are called software features.

## 18. Observability belongs in the architecture

Design enough observability to reconstruct consequential behavior, especially around destructive, privileged, external, asynchronous, nondeterministic, security-sensitive, or difficult-to-reproduce operations. Avoid telemetry that adds complexity without useful signal.

## 19. Optimize future options before future performance

If a plausible future scaling problem could be expensive, avoid choices that make solving it prohibitively difficult. Preserve the migration path without prematurely implementing the optimization.

## 20. Operability is part of correctness

For infrastructure and operational software, success-path correctness is incomplete without considering failure, interruption, diagnosis, recovery, retries, idempotency, evidence, and operator understanding.

## 21. Developer experience is operational engineering

If the safe path is difficult and the dangerous path is convenient, users will eventually choose the dangerous path. Good developer experience shapes real system behavior and therefore belongs in engineering design.

## 22. Architecture should answer a failure mode

Every significant mechanism should have a defensible reason for existing. Prefer explanations of the form: "Without this mechanism, credible condition X produces failure Y; this design changes that outcome to Z."

## 23. AI should raise the engineering bar

Cheaper generation should enable stronger verification, more alternatives explored, better documentation, smaller safer changes, and more rigorous review. Cheap code generation is not permission to accumulate cheap software.

## 24. Understanding can be distributed; responsibility cannot disappear

No individual must memorize every implementation detail of a sufficiently large system, but important behavior must remain explainable, owned, and recoverable. "The AI wrote it" is not an architectural explanation.

# Decision Heuristics

When principles conflict, use these defaults:

- **Architecture vs. emergence:** design likely seams early; implement them when evidence appears.
- **Duplication vs. abstraction:** centralize known invariants; tolerate uncertain duplication.
- **Velocity vs. rigor:** scale rigor with blast radius, irreversibility, and uncertainty.
- **Types vs. simplicity:** maximize useful guarantees, not type cleverness.
- **Monolith vs. services:** separate concepts first; distribute when operational evidence justifies it.
- **Build vs. buy:** buy commodities, encapsulate strategic dependencies, own differentiation.
- **Frameworks vs. primitives:** use frameworks for commodity behavior; retain control over product-defining behavior.
- **Compatibility vs. cleanup:** compare cost of migration with cost of permanence.
- **Tests vs. redesign:** characterize behavior first, preserve contracts, then refactor.
- **Performance vs. simplicity:** preserve the path to scale before paying the cost of scaling.

# Meta-Principle

**Spend complexity where it buys control over meaningful risk; preserve optionality where it is cheap; delay commitment where evidence is weak.**

Good engineering creates systems that can evolve without surrendering understanding, control, or evidence.
