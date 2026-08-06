# Impact Analysis

**Status:** Proposed  
**Goal:** Reduce unnecessary work without confusing scoped analysis with complete proof.

## 1. Rule

Impact analysis may optimize the repair loop.

It may narrow final acceptance only when completeness is established under accepted Project policy.

When completeness is uncertain, the final workflow falls back to the full required Gates.

## 2. Output contract

Every Impact Result includes:

```text
changed subjects
direct dependents
transitive dependents considered
selected tests
selected analyzers
risk classifications
confidence
known blind spots
fallback requirement
producer and parameters
dependency digests
```

## 3. Capture and summaries

Borrow Infer's summary idea.

A retained summary records:

```text
result
depends on
producer
parameters
Subject
validity conditions
```

Examples:

- module dependency summary;
- test-to-source map;
- public export summary;
- behavior implementation map;
- migration impact summary.

A changed dependency stales the summary automatically.

## 4. Fast versus completion plan

### Fast

Use:

- changed files;
- semantic dependencies;
- affected tests;
- cheap compiler checks;
- changed-code inspections.

### Completion

Use:

- full required compiler or type check;
- full required tests;
- accepted static analysis;
- architecture and security checks;
- any risk-triggered methods;
- independent verification when required.

## 5. Elixir provider

Potential inputs:

- changed files;
- changed modules;
- compile references;
- runtime references where available;
- behaviours and implementations;
- test references;
- umbrella application boundaries;
- public API changes;
- configuration changes;
- migrations.

Risk triggers:

- supervision trees;
- GenServer behavior;
- message ordering;
- cancellation;
- persistence;
- migrations;
- permissions;
- external Commands;
- serialization;
- security boundaries.

If complete impact cannot be established, the completion plan runs the full accepted test and analysis Gates.

## 6. TypeScript portability provider

Potential inputs:

- import graph;
- project references;
- package boundaries;
- public exports;
- test-to-source relationships;
- generated declarations;
- browser/server boundaries;
- configuration inheritance;
- workspace layout.

TypeScript is deliberately used to expose assumptions hidden by Elixir's cohesive toolchain.

## 7. False-negative metric

Primary safety metric:

```text
scoped plan passed
but full required plan found failure
```

Track:

- missed failure count;
- missed risk class;
- Impact Provider and version;
- repository area;
- reason;
- corrective rule.

Impact speed is secondary to false-negative control.

## 8. Conformance cases

- changed module breaks indirect caller;
- dynamic dispatch hides dependency;
- compile and runtime dependencies differ;
- configuration change affects distant tests;
- generated file affects public API;
- umbrella boundary changes impact;
- test references code indirectly;
- deleted file invalidates import graph;
- lockfile change widens scope;
- migration requires Critical Assurance;
- incomplete metadata forces full fallback.
