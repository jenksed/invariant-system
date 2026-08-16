# Verifier and Counterexamples

**Status:** Proposed  
**Milestone:** Quality Compiler QC2

## 1. Purpose

The Verifier attempts to falsify material Claims.

It does not merely:

- summarize the diff;
- rerun the implementer's command list;
- repeat the implementer's explanation;
- approve style;
- grade its own prior work.

## 2. Independence

The first accepted Verifier should be one depth-one read-only Child Run with:

- independent Context;
- narrower grants;
- no source mutation;
- original objective and criteria;
- final Patch and exact Repository state;
- Evidence Plan and raw Evidence;
- Pack policies;
- known repository risks;
- no implementer hidden reasoning;
- no authority to answer user acceptance.

## 3. Risk-based requirements

### Low risk

Independent inspection may be sufficient when deterministic Evidence is complete.

### Medium risk

Require at least one:

- boundary test;
- negative test;
- counterexample;
- property case;
- public API compatibility check.

### High risk / Critical Assurance

Require execution of an independent falsification attempt, normally including relevant failure, cancellation, restart, concurrency, persistence, or permission paths.

## 4. Counterexample Artifact

A counterexample is a first-class immutable Artifact.

Possible forms:

- concrete input;
- failing generated test;
- event sequence;
- process schedule;
- malformed payload;
- Repository state;
- performance regression;
- permission escalation path;
- crash and restart sequence.

Required metadata:

```text
target Claim
exact Subject
method
inputs or event sequence
reproduction count
command or validator identity
environment
observed failure
limitations
```

## 5. Result

```text
pass
fail
blocked
unknown
```

`pass` means the required independent attempt did not falsify the Claims under the recorded plan.

It does not mean universal correctness.

## 6. Counterexample-first feedback

Preferred:

```text
Claim refuted.

Sequence:
1. child operation starts
2. parent cancellation commits
3. child remains active

Reproduced: 3 of 3
Artifact: counterexample digest
```

Avoid broad prose that does not produce a reproducible failing case.

## 7. Verifier planning

Inputs:

- criteria and Claims;
- risk classes;
- changed components;
- current Evidence and Guarantees;
- known repository history;
- Pack verifier guidance;
- available registered Commands;
- Assurance.

Outputs:

- targeted Claims;
- methods;
- expected counterexample shape;
- limits;
- fallback;
- residual risk.

## 8. Protected tests

- Verifier receives no mutation grant;
- Verifier cannot answer user decision;
- implementer summary omitted by default;
- failing counterexample blocks;
- blocked required verifier blocks;
- timeout remains unknown when cleanup is unproved;
- same command rerun alone does not satisfy adversarial requirement;
- low-risk inspection does not silently satisfy Critical requirement;
- Counterexample Artifact binds exact Subject.
