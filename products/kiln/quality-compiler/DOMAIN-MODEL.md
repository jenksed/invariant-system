# Quality Compiler Domain Model

**Status:** Proposed  
**Boundary:** Language-neutral and protocol-neutral Kiln concepts

## 1. Primary relationship

```text
Run
└── Quality Compilation
    ├── Subject
    ├── Claim
    ├── Verification Obligation
    ├── Evidence Plan
    ├── Gate
    ├── Observation
    ├── Finding
    ├── Evidence Contribution
    ├── Policy Decision
    ├── Criterion Evaluation
    ├── Verifier Attempt
    └── Aggregate Evaluation
```

A Quality Compilation is owned by a Run. It is not a Run, Agent, model invocation, Command, process, branch, worktree, or transcript.

## 2. Seven foundational primitives

### Subject

The immutable thing being evaluated.

Examples:

- exact Patch;
- resulting Repository state;
- generated Artifact;
- registered Command result;
- release candidate.

Required fields:

```text
subject_id
kind
digest algorithm and value
Repository binding
Patch binding when applicable
created or observed time
```

### Claim

A statement about one Subject.

Examples:

- the Patch preserves cancellation semantics;
- the Repository compiles without warnings;
- no child operation outlives cancellation;
- the public callback contract remains compatible.

Claims may originate from accepted criteria, Pack decomposition, deterministic rules, or the Verifier. Origin and authority remain explicit.

### Verification Obligation

The work required to evaluate a Claim.

It records:

```text
accepted methods
required Guarantee class
Assumptions
required completeness
freshness rule
risk class
minimum Assurance
```

### Observation

One direct result from an analyzer, deterministic validator, registered Command, user observation, or Verifier attempt.

An Observation is not automatically sufficient Evidence.

### Guarantee

What the Observation legitimately establishes.

Guarantees are defined in [Evidence and Guarantee Model](EVIDENCE-AND-GUARANTEE-MODEL.md).

### Derived Fact

A normalized result with explicit dependencies and validity conditions.

Examples:

- Finding batch;
- affected-test map;
- dependency summary;
- criterion evaluation;
- flake classification.

### Decision

Kiln's deterministic policy conclusion:

```text
pass
fail
blocked
unknown
stale
contradicted
waived
```

A Pack or model may propose facts. Only Kiln policy creates a Kiln Decision.

## 3. Development Pack

A Development Pack contributes language, framework, toolchain, or repository-specific knowledge.

It may provide:

- deterministic project detection;
- Gate templates;
- parser definitions;
- Inspection metadata;
- impact hints;
- risk triggers;
- policy metadata;
- verifier guidance;
- repair suggestions.

It may not:

- execute a Project Command;
- mutate source;
- install dependencies;
- grant authority;
- choose secrets or network;
- accept a Claim;
- create a passing criterion Decision;
- answer user acceptance.

## 4. Pack Manifest

A Pack Manifest includes:

```text
Pack identity and version
protocol version
executable identity
supported project kinds
supported operations
request and response limits
declared effects
trust class
compatibility requirements
```

Manifest availability is separate from Project acceptance and Run authority.

## 5. Quality Compilation

Required identity:

```text
quality_compilation_id
Session ID
Run ID
Subject set
Repository state digest
Patch digest
Pack set digest
Assurance profile and version
Project policy digest
Evidence Plan digest
status
timestamps
```

Status:

```text
planned
running
repair_required
ready_for_verifier
ready_for_evaluation
ready_for_user_acceptance
rejected
blocked
unknown
canceled
```

These are Quality Compilation states. They do not add Run states.

## 6. Gate

A Gate is one registered analysis or verification step selected for an Evidence Plan.

It records:

```text
Gate ID
Pack ID
Command template or deterministic implementation
analysis level
dependencies
applicability
required status
minimum Assurance
risk triggers
declared effects
expected result adapter
criterion eligibility
```

A Gate never contains an unvalidated shell string.

## 7. Evidence Plan

The Evidence Plan is a deterministic, digest-bound plan explaining:

- selected Gates;
- dependencies and ordering;
- selected scope;
- required Artifacts;
- criterion and Claim coverage;
- Assurance reasons;
- risk escalations;
- fallback conditions;
- omitted Gates and rationale;
- budget constraints;
- Verifier requirements.

The plan must be inspectable before expensive or risky execution.

## 8. Inspection, Finding, and Occurrence

### Inspection Definition

A stable rule or analysis identity.

### Finding

The logical issue that may survive movement or rewording.

### Finding Occurrence

The exact observation of that Finding on one Subject state.

Required separation:

```text
Inspection ID remains stable across occurrences.
Finding ID may survive line movement.
Occurrence ID is unique to one observed state.
```

## 9. Evidence Contribution

An Evidence Contribution states how one Observation relates to one Claim.

```text
supports
refutes
inconclusive
not_applicable
```

It also records Guarantee, completeness, assumptions, and source Artifacts.

Kiln's evaluator consolidates Contributions. A Pack does not.

## 10. Policy Decision

Policy evaluates Findings, Evidence, baselines, and waivers under one accepted Project policy version.

Examples:

- new compiler Finding fails;
- preexisting audit Finding records debt;
- expired waiver blocks;
- missing required tool blocks;
- contradicted current Evidence blocks;
- lower requested Assurance escalates.

## 11. Verifier Attempt

A Verifier Attempt is an independent attempt to falsify one or more material Claims.

It records:

```text
Claims targeted
independent plan
methods
commands or deterministic actions
counterexamples
limitations
result
```

The Verifier is not permitted to mutate source in the first accepted design.

## 12. Aggregate Evaluation

The aggregate result is one of:

```text
ready_for_user_acceptance
not_ready
unknown
```

Ready requires:

- exact current Subject;
- every required criterion passed;
- required Guarantees satisfied;
- no stale or contradicted Evidence;
- no open or unknown operation;
- all required Artifacts intact;
- required Assurance established or explicit permitted waiver;
- Verifier requirement satisfied;
- no critical unwaived Finding.

## 13. Derived Fact invalidation

Every Derived Fact records:

```text
producer digest
parameters digest
Subject digest
dependency digests
Pack and parser versions
validity conditions
```

A change to any required dependency invalidates or stales the Derived Fact.

Time alone does not refresh a stale fact.

## 14. Persistence guidance

Journal material accepted facts:

- Pack set accepted;
- compilation started;
- Evidence Plan accepted;
- Gate intent and terminal observation;
- Artifact references;
- baseline and waiver decisions;
- criterion evaluation;
- Verifier result;
- aggregate evaluation.

Store large payloads outside the journal:

- stdout and stderr;
- SARIF;
- JUnit;
- compiler reports;
- normalized Finding batches;
- impact graphs;
- counterexamples;
- verifier reports.

Current views are rebuildable projections, never more authoritative than journal facts and immutable Artifacts.
