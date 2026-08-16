# Quality Compiler and Development Packs Implementation Plan

**Status:** Proposed for owner review  
**Branch purpose:** Planning and reusable contract scaffold only  
**Runtime implementation authorization:** None

## 1. Strategic decision

Kiln should implement a language-neutral Quality Compiler and use Development Packs to translate native toolchains into agent-operable, evidence-producing quality systems.

The initiative is intentionally cross-slice:

```text
QC0  deterministic Gate execution
QC1  evidence-aware Elixir dogfooding
QC2  independent falsification
QC3  Repository quality memory
QC4  multi-language public Pack platform
```

Kiln should not claim the strongest “earned trust” result until QC2.

## 2. Current sequencing

Do not interrupt the authorized P1-S01 sequence.

```text
merge P1-S01-T04
→ implement P1-S01-T05
→ accept P1-S01 aggregate Evidence
→ authorize P1-S02
→ begin Quality Compiler spine
```

This package should be reviewed and merged as planning material. It does not itself change existing Kiln roadmap authority.

## 3. Stage A — Close the durable foundation

### A1. Merge current CLI work

Exit:

- PR exact-head green;
- main green;
- no excluded capability introduced.

### A2. Complete aggregate slice gate

Exit:

- restart demonstration;
- corruption fixtures;
- P1-S01 verification manifest;
- owner-machine Evidence.

### A3. Capture baseline

Record:

- exact commit;
- test count;
- aggregate commands;
- host profile;
- known limitations.

## 4. Stage B — Authorize the Quality Compiler spine

A later accepted planning change should reconcile existing Kiln authorities and add:

- architecture decision;
- focused Quality Compiler authority;
- threat model;
- Pack protocol contract;
- Quality Compilation contract;
- P1-S02 ticket sequence.

No runtime code should be smuggled through planning.

## 5. Stage C — Artifact substrate

Implement:

```text
Artifact identity
content-addressed store
integrity verification
bounded previews
sensitivity and trust metadata
```

Acceptance:

- temporary write;
- sync;
- digest verification;
- same-directory atomic placement;
- raw bytes outside journal;
- missing/corrupt classification;
- no secret display.

## 6. Stage D — Registered Command substrate

Implement:

```text
Command Registration
Request
Result
Registry
Environment construction
Worker
macOS process-group host
```

Acceptance:

- no shell string;
- fixed executable and interpreter identities;
- validated argv;
- minimal environment;
- explicit working directory;
- output and timeout limits;
- TERM/KILL/probe;
- unknown when cleanup cannot be proved;
- deterministic fake host.

## 7. Stage E — Development Pack kernel

Implement protocol data and host:

```text
Manifest
Frame
Request
Response
Host
Invocation
Registry
Resolver
```

First use deterministic fake Pack.

Required fake behaviors:

- valid match and no match;
- plan;
- parse;
- impact;
- crash;
- timeout;
- malformed frame;
- oversized frame;
- incompatible version;
- forbidden authority attempt.

Exit:

- Pack cannot execute Project Command;
- Pack cannot mutate source;
- crash cannot crash Kiln;
- errors cannot produce empty pass;
- lifecycle and digests inspectable.

## 8. Stage F — Quality Compilation kernel

Implement:

```text
Compilation
Subject
Claim
Verification Obligation
Evidence Plan
Gate
Gate graph
Risk
Assurance
Scheduler
Repair loop
```

Initial scheduler is conservative. Parallel Gates require independent resources, no mutation, and separate cancellation ownership.

Repair loop limits:

- attempts;
- time;
- tool calls;
- repeated identical failure;
- unchanged relevant Patch;
- total budget.

## 9. Stage G — Findings and baselines

Implement:

```text
Diagnostic
Finding
Finding Occurrence
Normalizer
Fingerprint
Baseline
Comparator
Policy Decision
Enforcement
```

Exit:

- audit, ratchet, strict;
- introduced/preexisting/resolved/regressed/worsened;
- structural fingerprint tests;
- version migration report;
- no fuzzy auto-merge;
- no score bypass.

## 10. Stage H — Elixir Development Pack

Keep it separately buildable under a new standalone boundary when implementation is authorized.

Initial capabilities:

- standard Mix and umbrella detection;
- format Gate;
- compile Gate;
- affected and full test Gates;
- compile-connected cycle Gate;
- repository aggregate Gate;
- compiler, ExUnit, and xref adapters;
- risk triggers;
- impact hints.

Framework Packs remain separate later:

```text
kiln-elixir
kiln-phoenix
kiln-ecto
kiln-liveview
```

No automatic dependency installation.

## 11. Stage I — Kiln dogfood profile

Default:

```text
Assurance: Auto
adoption: ratchet
```

Immediately strict:

- current required formatting;
- compiler warnings;
- tests;
- xref cycles;
- contract validation;
- Schema validation;
- agent assets;
- Vale.

Initially audit:

- Credo;
- Dialyzer;
- advanced OTP inspections;
- changed-line coverage;
- mutation testing.

## 12. Stage J — First real dogfood change

One bounded real change must pass:

```text
objective and criteria
→ investigation
→ exact Patch
→ user approval
→ apply
→ fast loop
→ repair
→ completion plan
→ Findings and policy
→ criterion Evidence
→ user acceptance
→ Receipt
→ restart inspection
```

The demonstration must intentionally introduce at least one defect and show the Pack catching it before final acceptance.

This establishes QC1.

## 13. Stage K — Claim and Evidence compiler

Implement:

```text
Claim compiler
Verification Obligation compiler
Evidence Contribution
Guarantee evaluator
Criterion evaluator
Aggregate evaluator
```

Exit:

- every required criterion has visible coverage;
- unsupported Claims stay unsupported;
- stale and contradictory Evidence block;
- model explanation cannot create Evidence;
- acceptance binds exact evaluation.

## 14. Stage L — Independent Verifier Child

After bounded delegation is authorized:

- one depth-one read-only Verifier;
- independent Context;
- no mutation;
- risk-based falsification;
- Counterexample Artifacts;
- pass/fail/blocked/unknown;
- required failure blocks.

This establishes QC2.

## 15. Stage M — Repository quality memory

Retain derived, rebuildable history:

- recurring Findings;
- resolved then regressed Findings;
- flaky test observations;
- broad-impact modules;
- repeatedly violated policies;
- verifier discoveries;
- impact misses;
- repair effectiveness;
- evidence gaps.

Use SQLite projections and immutable Artifacts first. Do not introduce a graph or vector database without measured need.

## 16. Stage N — TypeScript portability proof

Build a thin Pack supporting:

- project and package-manager detection;
- accepted formatter;
- `tsc --noEmit`;
- accepted linter;
- selected tests;
- full tests;
- normalized diagnostics;
- audit and ratchet.

Test:

- monorepos;
- project references;
- package boundaries;
- config inheritance;
- multiple linters;
- multiple test runners;
- missing tools;
- framework ambiguity.

Do not freeze protocol v1 until Elixir and TypeScript both fit.

## 17. Pack conformance suite

Synthetic fixtures:

- detection;
- false-positive resistance;
- missing tool;
- format failure;
- compile failure;
- lint failure;
- failing test;
- flaky test;
- timeout;
- cancel;
- process crash;
- malformed or truncated output;
- public API break;
- cycle;
- security Finding;
- impact blind spot;
- authority request.

A Pack is not certified merely because its commands run. It must catch seeded defects and classify failures correctly.

## 18. Anti-mediocrity gate

Reject the initiative as incomplete if:

1. Pack is mostly a YAML command list.
2. Pack executes arbitrary commands.
3. Pack mutates source.
4. Raw output is discarded.
5. Findings are file-line hashes.
6. Existing debt is hidden by counts.
7. Missing tools are silently skipped.
8. Narrow analysis passes completion without completeness or fallback.
9. Exit zero creates criterion pass.
10. Score overrides a hard failure.
11. Implementer acts as independent verifier.
12. Evidence lacks exact-state binding.
13. Pack/parser/tool versions are absent.
14. Pack crash creates empty pass.
15. Unknown cleanup becomes known success or failure.
16. Baselines survive incompatible changes silently.
17. Plan cannot explain Gate selection and omission.
18. Criteria cannot show missing support.
19. Elixir-specific logic leaks into core contracts.
20. Protocol freezes before second-language proof.
21. First dogfood change bypasses the Pack.
22. Critical change can silently run Rapid.
23. Formal is claimed without method, assumptions, bounds, and Guarantee.

## 19. Verification strategy

### Pure tests

- plan validation;
- Gate cycles;
- Assurance escalation;
- policy;
- baseline comparison;
- criterion aggregation;
- invalidation.

### Property tests

- canonical JSON/data;
- frame round trips;
- fingerprint stability;
- malformed input totality;
- deterministic digests;
- baseline comparator totality.

### Process tests

- partial frame;
- invalid UTF-8;
- wrong length;
- crash;
- timeout;
- cancel;
- output flood;
- late result after cancel.

### End-to-end repositories

Each fixture records:

- initial commit;
- Patch;
- Packs;
- Assurance;
- expected Gates;
- Findings;
- policy Decisions;
- criterion coverage;
- aggregate result.

## 20. Measuring uplift

Compare representative tasks with and without Quality Compiler enforcement.

Measure:

- escaped defects;
- first-pass Gate success;
- repair attempts;
- time to accepted Evidence;
- verifier rejection;
- seeded defects caught;
- post-merge regressions;
- new Finding rate;
- impact false negatives;
- human corrections;
- tokens per accepted change.

Primary quality metric:

```text
baseline escaped-defect rate
minus Quality Compiler escaped-defect rate
divided by baseline escaped-defect rate
```

Do not publish unsupported percentage claims.

## 21. Rough effort ranges

Planning ranges, not commitments:

```text
Artifact and Command substrate       4–7 weeks
Pack protocol and fake               3–5 weeks
Compilation planning and execution   3–5 weeks
Findings and baselines               4–7 weeks
Initial Elixir Pack                  3–5 weeks
Dogfood audit and first change       3–7 weeks
Claim and Evidence compiler          3–6 weeks
Independent Verifier                 4–8 weeks
Quality memory                       3–6 weeks
TypeScript portability               4–8 weeks
```

A differentiated QC1 alpha is a multi-month effort. QC2 is larger but realistic.

## 22. Owner decisions

Before implementation, explicitly accept or reject:

1. Quality Compilation is cross-slice.
2. Public Packs are supervised external processes.
3. Packs never execute or mutate.
4. Elixir is the reference Pack.
5. TypeScript proves portability before protocol freeze.
6. Ratchet is the established-repository default.
7. Findings are not Evidence.
8. Scores do not override hard gates.
9. Assurance is the user-facing verification-depth control.
10. The strongest claim waits for independent falsification.
