# Assurance Profiles

**Status:** Proposed  
**User-facing name:** Assurance

## 1. Purpose

Assurance controls how much and what strength of Evidence Kiln requires before acceptance.

It does not control whether Kiln tells the truth.

A lower Assurance may reduce breadth, expensive analysis, and model involvement. It never permits:

- compiler or type errors;
- formatter failure when formatting is required;
- newly failing required tests;
- unknown external effects;
- stale Evidence presented as current;
- hidden skipped required tools;
- explicit critical security Findings;
- repository-required gate bypass;
- false claims of verification.

## 2. Profiles

```text
Auto
1  Rapid
2  Standard
3  Thorough
4  Critical
5  Formal
```

Profiles are named and versioned. The numeric position is presentation, not the canonical identity.

## 3. Rapid

Use for prototypes, scripts, experiments, and disposable work.

Normally includes:

- formatting;
- compiler or type checker;
- directly affected tests;
- critical security rules;
- mandatory Project gates.

Normally excludes unless triggered:

- full test suite;
- expensive static analysis;
- broad architecture checks;
- independent model verification;
- mutation testing;
- formal methods.

Rapid means less breadth, not known-broken acceptance.

## 4. Standard

Default for ordinary feature work.

Includes:

- formatting;
- compilation or type checking;
- changed-code linting;
- affected tests;
- basic impact analysis;
- mandatory Project gates;
- full tests before final acceptance when practical or required by fallback.

## 5. Thorough

Use for important product code and merge-ready work.

Adds:

- complete test suite;
- complete accepted static analysis;
- architecture checks;
- public API compatibility;
- broader integration tests;
- independent verifier inspection when supported;
- stronger Claim-to-Evidence coverage.

## 6. Critical

Use for:

- authorization and permissions;
- secrets;
- persistence and migrations;
- concurrency and message ordering;
- cancellation and process cleanup;
- source mutation;
- external Command execution;
- security boundaries;
- billing or irreversible effects;
- recovery and idempotency.

Adds:

- mandatory independent falsification;
- failure injection;
- cancellation and restart tests;
- concurrency or ordering tests;
- property-based testing where suitable;
- security analysis;
- stronger isolation;
- explicit residual-risk reporting.

## 7. Formal

Use selectively where the Project has formal specifications and suitable tools.

May require:

- model checking;
- solver-backed verification;
- exhaustive finite-state checks;
- refinement types;
- proof-producing tools;
- mutation testing as proof-strength support;
- multiple independent methods.

Formal is not a marketing synonym for “very thorough.” The plan must name the formal method, assumptions, bounds, and resulting Guarantee.

## 8. Auto

Auto computes required Assurance from:

```text
Project default
changed paths
change shape
criteria
risk triggers
public API impact
repository history
Pack requirements
prior regressions
```

The user can request more Assurance freely.

A request below the computed floor triggers an explicit downgrade decision or blocks when the floor is non-waivable.

## 9. Effective Assurance

```text
requested Assurance
+ Project minimum
+ path minimum
+ change risk
+ criterion requirements
+ Pack mandatory conditions
= required Assurance
```

Then:

```text
required Assurance
+ available tools
+ Environment controls
+ resource budget
= executable Evidence Plan
```

Possible outcomes:

```text
satisfied
blocked_missing_tool
blocked_missing_control
blocked_budget
waiver_required
unknown
```

## 10. Automatic escalation examples

| Change | Minimum likely Assurance |
| --- | --- |
| README typo | Rapid |
| Internal pure helper | Standard |
| Public API change | Thorough |
| Dependency upgrade | Thorough |
| Database migration | Critical |
| Authentication or capability logic | Critical |
| OTP supervision or cancellation behavior | Critical |
| Selected proof-oriented component | Formal |

Example:

```text
Requested: Rapid
Detected risk: capability permission boundary
Required: Critical
Reason: permission changes require independent falsification
```

## 11. Resource budget is separate

Assurance is not the same as compute or token budget.

A user may request:

```text
Assurance: Critical
Resource budget: Small
```

Kiln must report when the requirement cannot be established:

```text
Critical Assurance cannot be established under the available budget.

Missing:
- independent verifier attempt
- cancellation fault injection
- full property test budget
```

It may suggest narrower task scope or an explicit waiver. It must not silently downgrade.

## 12. Interaction policy is separate

Possible repair policies:

```text
one_pass
bounded_repair
repair_until_budget
```

A high Assurance does not imply unlimited autonomous repair.

## 13. Gate metadata

A Gate can declare:

```text
minimum Assurance
cost class
mandatory risk triggers
required Guarantee
parallel safety
fallback
```

Example:

```text
Gate: elixir.compile
Minimum: Rapid
Cost: cheap
Mandatory: always
```

```text
Gate: elixir.dialyzer
Minimum: Thorough
Cost: expensive
Mandatory when: public contract or persistence risk
```

## 14. Waivers

A waiver records:

- requested downgrade;
- omitted methods;
- Claims losing support;
- residual risk;
- decision actor;
- expiration or one-use scope;
- exact Subject;
- final effective Assurance.

The final Receipt must report the achieved Assurance, not the originally requested higher level.

Some controls are non-waivable under Project policy, including unknown external effects and integrity failures.

## 15. Project policy example

```toml
[quality]
default_assurance = "standard"
maximum_automatic_assurance = "critical"
allow_user_downgrade = true

[[quality.rules]]
paths = ["lib/kiln/security/**", "lib/kiln/command/**"]
minimum_assurance = "critical"

[[quality.rules]]
paths = ["docs/**"]
minimum_assurance = "rapid"

[[quality.rules]]
paths = ["priv/store/migrations/**"]
minimum_assurance = "critical"
```

Development Packs may recommend minimums. Accepted Project policy remains authoritative.
