# Evidence and Guarantee Model

**Status:** Proposed  
**Purpose:** Prevent heterogeneous checks from collapsing into identical green checkmarks.

## 1. Core distinction

```text
Command result
≠ Observation sufficiency
≠ Evidence contribution
≠ criterion pass
≠ aggregate acceptance
```

A successful test command and a formal proof are not the same kind of assurance. A compiler error and a heuristic warning do not carry the same failure guarantee.

## 2. Guarantee classes

### `proof`

The method produces an accepted proof under explicit assumptions and semantics.

### `sound_for_pass`

A passing result is sound for the declared scope and assumptions.

### `sound_for_failure`

A reported failure or counterexample is sound for the declared scope.

### `bounded_sound_for_pass`

A passing result is sound only within explicit bounds.

### `bounded_sound_for_failure`

A reported failure is sound within explicit bounds.

### `empirical`

The result records observed executions or examples. It can refute behavior for concrete cases but does not prove universal behavior.

### `heuristic`

The method identifies likely risk but does not claim sound pass or failure.

### `human_observation`

An accepted person observed a condition permitted by the criterion. It cannot override conflicting machine Evidence, stale state, or unknown effects.

### `unknown`

The method's guarantee is not understood sufficiently for acceptance.

## 3. Scope

Every Guarantee declares scope:

```text
all inputs
selected inputs
changed paths
selected symbols
bounded depth
bounded time
one environment
one tool configuration
one concurrency schedule
```

A result without explicit scope cannot satisfy a required obligation.

## 4. Examples

### Compiler type error

```text
Disposition: refutes
Guarantee: sound_for_failure within compiler semantics
Completeness: complete
```

### Unit test pass

```text
Disposition: supports
Guarantee: empirical
Scope: executed examples
Universal proof: no
```

### Property test counterexample

```text
Disposition: refutes
Guarantee: sound_for_failure
Counterexample: concrete generated input
```

### Bounded model check pass

```text
Disposition: supports
Guarantee: bounded_sound_for_pass
Scope: state depth 16
```

### Linter recommendation

```text
Disposition: supports concern
Guarantee: heuristic
```

## 5. Evidence Contribution contract

Each contribution includes:

```text
contribution ID
Claim ID
Observation ID
method
disposition
Guarantee class
scope
assumptions
completeness
freshness
contradiction state
Subject digest
producer and parser identity
Artifact references
limitations
```

## 6. Consolidation

Kiln consolidates multiple Contributions for one Claim.

Possible Claim states:

```text
directly_supported
indirectly_supported
partially_supported
unsupported
refuted
contradicted
stale
unknown
waived
```

Rules:

- one current sound refutation cannot be hidden by favorable heuristic or empirical Evidence;
- incomplete or truncated required output cannot satisfy complete Evidence;
- incompatible current results create contradiction;
- stale Contributions remain visible but cannot satisfy current state;
- a waiver records omitted Evidence; it does not transform it into support.

## 7. Verification Obligations

Every required Claim should have one or more obligations:

```text
statement
assumptions
accepted methods
required Guarantee
minimum completeness
freshness rule
minimum Assurance
fallback
```

Example:

```text
Claim:
A canceled parent leaves no active child operation.

Accepted methods:
- deterministic state-machine validator
- cancellation integration test
- independent counterexample search

Required Guarantee:
empirical plus independent falsification

Minimum Assurance:
Critical
```

## 8. Contradiction

Contradiction examples:

- one required test report passes and another fails on the same exact state;
- Repository observation disagrees with an analyzer;
- a summary claims output exists but the required Artifact is missing;
- output truncation prevents confirming the claimed pass;
- two Pack parsers classify the same native diagnostic incompatibly.

Contradiction blocks acceptance until resolved or explicitly re-observed. Kiln never chooses the favorable result automatically.

## 9. Freshness

Freshness rules may include:

```text
same Repository state
same Patch and Repository state
same Command registration and Repository state
same Pack, parser, and tool versions
same environment profile
manual same Repository state
```

Any changed required binding stales Evidence.

## 10. Assurance relationship

Assurance specifies the required breadth and Guarantee strength.

Rapid may rely primarily on deterministic compiler and empirical focused tests.

Critical may require multiple methods, failure injection, and independent falsification.

Formal may require proof or solver-backed methods for selected obligations.

The selected Assurance cannot upgrade the Guarantee of the methods actually executed.
