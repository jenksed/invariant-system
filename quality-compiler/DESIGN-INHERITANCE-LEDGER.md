# Design Inheritance Ledger

**Status:** Proposed  
**Purpose:** Gain velocity from mature analysis and verification systems without importing their boundaries blindly.

## Rule

Every major Quality Compiler mechanism should identify:

1. the predecessor;
2. the idea being borrowed;
3. the Kiln adaptation;
4. the part intentionally not copied;
5. the protected test or review question that prevents regression into the rejected design.

## Ledger

| Predecessor | Borrow | Kiln adaptation | Do not copy |
| --- | --- | --- | --- |
| Frama-C | Shared analysis kernel, specialist analyzers, property-status consolidation, provenance | Packs contribute Evidence Contributions to Kiln-native Claims and subjects | A universal multi-language AST or analyzer-owned acceptance |
| Infer | Capture/analyze/compare workflow, incremental summaries, introduced/fixed/preexisting classification | Exact-state capture, dependency-tracked Derived Facts, introduced/resolved/preexisting/regressed Findings | Treating changed-line filtering as complete impact proof |
| Scalafix | Syntactic versus semantic rules, distinct lint and rewrite behavior, published rule extensions | Gate analysis levels, explicit prerequisites, repair suggestions separated from Patch authority | Rewrite execution inside analysis or automatic cascades |
| Stan | Inspection catalog, unique rule IDs, compiler-derived semantic facts, observations | Inspection definitions, logical Finding identity, occurrence identity, Pack metadata | Source-line-only stable IDs |
| HLint | Audit then baseline then enforce; cautious transformation advice | Audit, ratchet, and strict modes with per-Finding debt records | Count-based opaque ignores or unbounded chained fixes |
| Semgrep | Multi-language rule packs, normalized analyzer output, diff-aware policy | Reuse Semgrep as a registered analyzer and ingest SARIF or JSON | Rebuilding a universal pattern engine |
| SARIF | Standard analyzer interchange, rules, results, fingerprints, locations, invocations | Import/export boundary and immutable source Artifact | Canonical Kiln Evidence, authority, or completion domain |
| Rosette | Claims, assumptions, verification queries, first-class counterexamples, explicit boundedness | Verifier attempts produce Counterexample Artifacts and Guarantee classes | Claiming universal proof from bounded or heuristic checks |
| LiquidHaskell / ACL2 | Explicit properties and proof obligations | Criteria compile into Verification Obligations with accepted methods | Requiring formal specifications for ordinary work |
| Eastwood | Analysis may load or execute Project code | Every Gate declares actual execution effects and required isolation | Treating “static analyzer” as a safety class |
| LSP | Request identity, progress, cancellation, terminal response | Small framed Pack protocol with explicit lifecycle | Adopting the whole LSP or JSON-RPC surface |
| in-toto | Immutable subject digest, typed predicate, statement, optional envelope | Exportable Quality Compilation statements and later signatures | Making attestation output create truth or authority |

## 1. Frama-C: collaborative analysis kernel

Frama-C allows multiple analyzers to emit property statuses with explicit emitters and states such as true, false, and unknown. Kiln should borrow the status-contribution architecture.

A Development Pack must not return only:

```json
{"pass": true}
```

It should return a bounded contribution such as:

```text
Claim
Method
Disposition
Guarantee
Completeness
Assumptions
Subject binding
Analyzer identity
Artifact references
```

Kiln's deterministic evaluator decides sufficiency and contradiction.

Reference:

- Frama-C Property Status API: https://frama-c.com/api/frama-c/Frama_c_kernel/Property_status/index.html
- Frama-C project: https://frama-c.com/

## 2. Infer: capture, analyze, compare, evaluate

Kiln should explicitly separate:

```text
Capture
→ Analyze
→ Compare
→ Evaluate
```

**Capture** stores exact native facts.  
**Analyze** executes selected Gates.  
**Compare** classifies Findings against prior state.  
**Evaluate** applies Project policy and criterion obligations.

This keeps parsing, identity matching, baseline policy, and acceptance testable as separate functions.

Reference:

- Infer project: https://fbinfer.com/
- Infer source: https://github.com/facebook/infer

## 3. Scalafix: analysis levels and mutation separation

Scalafix distinguishes syntactic rules from semantic rules that require compiler-produced symbols and types. It also distinguishes linting from rewrites.

Kiln generalizes this into:

```text
textual
syntactic
semantic
build/static analysis
runtime/test observation
adversarial verification
formal or solver-backed verification
```

A Pack may suggest a repair. Every repair still becomes a normal exact Patch proposal.

References:

- Rule overview: https://scalacenter.github.io/scalafix/docs/rules/overview.html
- Linter versus rewrite guidance: https://scalacenter.github.io/scalafix/docs/developers/before-you-begin.html
- API overview: https://scalacenter.github.io/scalafix/docs/developers/api.html

## 4. Stan: inspection catalog

Kiln should define stable Inspection identities separately from Finding and Finding Occurrence identities.

```text
Inspection: what pattern or risk is checked
Finding: the logical problem across source movement
Occurrence: the exact observation on one subject state
```

Reference:

- Stan package: https://hackage.haskell.org/package/stan

## 5. HLint: staged adoption and bounded repair

Established repositories need:

```text
audit
→ review debt
→ explicit baseline
→ ratchet new work
→ migrate selected rules to strict
```

A repair loop should apply one coherent Patch, recapture state, and reevaluate. It should not recursively chain speculative transformations before observing the result.

Reference:

- HLint: https://github.com/ndmitchell/hlint

## 6. Semgrep and SARIF: reuse analyzers and interchange

Kiln should integrate mature analyzers through registered Commands and result adapters. Semgrep is one likely multi-language analyzer. SARIF is a strong import/export format.

Kiln must retain:

```text
SARIF result
≠ Kiln Finding
≠ Kiln Evidence
≠ criterion pass
≠ acceptance
```

References:

- Semgrep: https://semgrep.dev/
- SARIF 2.1.0 plus errata: https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html

## 7. Rosette: counterexample-first verification

The Verifier should prefer concrete falsification:

```text
Claim refuted
Counterexample input or event sequence
Reproduction count
Exact subject state
Artifacts and commands
```

A counterexample is more useful to a repair Agent than broad review prose.

Rosette also demonstrates why bounded methods must state whether they preserve soundness, completeness, both, or neither.

References:

- Verification forms: https://docs.racket-lang.org/rosette-guide/ch_syntactic-forms_rosette.html
- Rosette essentials and counterexamples: https://docs.racket-lang.org/rosette-guide/ch_essentials.html

## 8. Eastwood: analyzers can execute code

Every Gate declares effect metadata:

```text
reads Project source
loads Project code
executes Project code
macroexpands or generates code
writes caches
reads environment
requires network
requires secrets
```

Kiln selects the Environment from actual effects. Names such as “linter” or “static” do not imply safety.

Reference:

- Eastwood: https://github.com/jonase/eastwood

## 9. LSP: lifecycle semantics

Borrow:

```text
request identity
progress
partial result
cancel
terminal response
```

A timed-out, canceled, or crashed Pack invocation cannot disappear. It receives a terminal classification and an invocation Receipt.

Reference:

- LSP 3.17 specification: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/

## 10. in-toto: export layering

Use later export layering:

```text
Subject: immutable Repository or Patch digest
Predicate: Kiln Quality Compilation result
Statement: binds Predicate type to Subject
Envelope: optional authentication
Bundle: optional grouping
```

Internal Kiln Records remain authoritative for Kiln. Exported statements do not create acceptance.

References:

- Statement v1: https://github.com/in-toto/attestation/blob/main/spec/v1/statement.md
- Framework layers: https://github.com/in-toto/attestation/blob/main/spec/README.md

## Questions every implementation ticket must answer

- Which predecessor informed this design?
- Which mature format or tool can be reused?
- What Kiln authority or Evidence requirement is missing from that predecessor?
- Which assumption could make the borrowed design unsound here?
- What protected negative test covers the rejected shortcut?
