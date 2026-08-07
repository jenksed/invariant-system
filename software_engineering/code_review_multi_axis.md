# Multi-Axis Code Review

Review a change against independent correctness dimensions so success on one cannot hide failure on another.

## Establish the fixed point

Resolve the base/fixed point once and verify the diff is non-empty. Prefer merge-base semantics for branch/PR review.

Identify:

- diff and commits;
- originating spec/issue/acceptance criteria when available;
- repository standards and Engineering Doctrine;
- required deterministic checks/evidence.

## Review axes

Run independently when context/tools permit.

### 1. Requirement / Spec fidelity

Check:

- requested behavior missing or incomplete;
- behavior implemented incorrectly;
- scope creep not requested;
- acceptance criteria without supporting evidence;
- intentional changes that contradict the source requirement.

Cite the source requirement for each finding.

### 2. Engineering standards / design

Check:

- documented repository standards;
- doctrine violations/tradeoffs;
- inappropriate speculative abstraction;
- duplicated invariant logic;
- shallow/pass-through layers;
- unclear domain naming;
- excessive coupling or shotgun changes;
- missing structural invariants/types/constraints;
- operability/security gaps proportional to blast radius.

Distinguish hard standard violations from judgment calls.

### 3. Verification / evidence

Check whether the claimed completion state is supported by:

- tests/static checks;
- reproduction/verification commands;
- migration/compatibility evidence;
- observable receipts for consequential behavior.

Do not infer that code which looks correct has been executed.

## Isolation rule

When possible, use separate reviewers/contexts for Spec and Standards/Evidence, then aggregate without letting one reviewer's conclusion anchor the others.

## Output

Report findings by axis, severity, and evidence. Keep “requirement wrong” separate from “implementation quality wrong.”

End with:

- blocking findings;
- non-blocking improvements;
- verification gaps;
- whether the change is ready, not ready, or blocked on unavailable evidence.