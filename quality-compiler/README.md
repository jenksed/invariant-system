# Kiln Quality Compiler

**Status:** Proposed for owner review  
**Scope:** Standalone design and contract scaffold  
**Build authorization:** None  
**Baseline:** `jenksed/kiln` `main` at `d5960492b74abe254db77c7892dcf039d00b30c5`  
**Prepared:** 2026-08-05

## Purpose

The Quality Compiler is Kiln's proposed system for deciding whether a repository change has earned trust.

It receives:

```text
accepted objective and criteria
+ exact base Repository state
+ proposed Patch
+ resulting Repository state
+ Project policy
+ active Development Packs
+ execution and resource limits
```

It produces either:

```text
accepted change
+ current Evidence
+ explicit policy decisions
+ independent verification
+ durable acceptance record
```

or:

```text
rejected, blocked, stale, contradicted, or unknown change
+ localized Findings
+ missing Evidence
+ reproducible repair guidance
```

Models can generate and repair code. Kiln remains responsible for authority, deterministic effects, Evidence sufficiency, and truthful completion.

## This package

This directory is intentionally isolated from current Kiln runtime source. It provides reviewable design artifacts and reusable contract scaffolding without changing existing Kiln files or authorizing implementation.

| Document | Purpose |
| --- | --- |
| [Design inheritance ledger](DESIGN-INHERITANCE-LEDGER.md) | Records what Kiln borrows, adapts, and rejects from prior systems |
| [Domain model](DOMAIN-MODEL.md) | Defines the language-neutral Quality Compiler nouns and invariants |
| [Evidence and guarantee model](EVIDENCE-AND-GUARANTEE-MODEL.md) | Prevents all green checks from being treated as equivalent proof |
| [Assurance profiles](ASSURANCE-PROFILES.md) | Defines Rapid through Formal verification depth and automatic escalation |
| [Development Pack protocol](DEVELOPMENT-PACK-PROTOCOL.md) | Defines the proposed supervised external-process boundary |
| [Finding identity and baselines](FINDING-IDENTITY-AND-BASELINES.md) | Defines durable Findings, matching, audit, ratchet, and strict modes |
| [Impact analysis](IMPACT-ANALYSIS.md) | Defines safe change-scoped planning and full-gate fallback |
| [Verifier and counterexamples](VERIFIER-AND-COUNTEREXAMPLES.md) | Defines independent falsification rather than self-review |
| [Threat model](THREAT-MODEL.md) | Defines authority, execution, plugin, parser, and evidence threats |
| [Implementation plan](IMPLEMENTATION-PLAN.md) | Defines the staged delivery path and anti-mediocrity gates |
| [Schemas](schemas/) | Draft machine-readable contracts |
| [Conformance fixtures](conformance/) | Seed corpus for protocol and domain validation |

## Governing architecture

```text
Kiln Run
└── Quality Compilation
    ├── exact-state capture
    ├── Development Pack resolution
    ├── criteria and Claim compilation
    ├── risk and Assurance evaluation
    ├── Evidence Plan
    ├── registered Gate execution
    ├── normalized Findings
    ├── audit, ratchet, or strict policy
    ├── criterion Evidence evaluation
    ├── independent falsification when required
    └── aggregate acceptance decision
```

A Quality Compilation is not a new Run, Agent, process, branch, or CI job. It is an evidence-producing workflow owned by one Run.

## Foundational rules

1. **Packs describe; Kiln authorizes and executes.**
2. **A Finding is an observation, not criterion Evidence by itself.**
3. **Raw results remain immutable Artifacts after normalization.**
4. **Every material result binds exact Repository, Patch, tool, parser, Pack, and Environment state.**
5. **Unknown never becomes success.**
6. **Hard failures cannot be averaged away by a quality score.**
7. **Baselines are explicit debt records, not invisible ignores.**
8. **The public Pack boundary is an external supervised process.**
9. **Repairs occur as bounded Patch proposals followed by recapture and reevaluation.**
10. **The strongest trust claim requires an independent attempt to falsify material Claims.**

## Assurance

The user-facing verification-depth control remains **Assurance**:

```text
Auto
1  Rapid
2  Standard
3  Thorough
4  Critical
5  Formal
```

Assurance controls the breadth and strength of required Evidence. It does not permit compiler errors, stale Evidence, unknown effects, hidden skipped tools, new required-test failures, or critical security violations.

The effective Assurance is computed from:

```text
requested Assurance
+ Project minimum
+ changed-path policy
+ detected risk
+ criterion requirements
+ Development Pack requirements
= required Assurance
```

Resource budget and repair autonomy remain separate controls. Kiln must block honestly when the selected Assurance cannot be established within available tooling or budget.

## Intended delivery sequence

```text
finish P1-S01
→ approve this design package
→ authorize a Quality Compiler spine inside P1-S02
→ build Artifact and registered Command substrate
→ prove Pack protocol with a deterministic fake
→ implement Quality Compilation and Findings
→ dogfood kiln-elixir
→ compile criteria into Evidence
→ add independent Verifier Child
→ prove portability with a TypeScript Pack
```

The public protocol must not freeze before both the Elixir and TypeScript Packs fit without language-specific fields in the core contract.
