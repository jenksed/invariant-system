# Wave B Entry Gate

**Document type:** Future planning-entry authority  
**Decision status:** Owner-directed  
**Implementation status:** Not started  
**Build authorization:** Not issued

## Purpose

Wave B shapes and authorizes delegation. It does not begin during Wave A.

P0-W26 and P0-W27 must use accepted runtime Evidence from the authorized Single-Run Alpha. Planning them before that Evidence risks designing interruption, recovery, and delegation around imagined behavior.

## Required entry Evidence

Wave B can begin only after the authorized Root workflow has produced accepted Evidence for:

- one real source change;
- durable restart behavior;
- controlled Patch authority;
- registered verification;
- criterion-bound Evidence;
- one valid Receipt;
- known runtime failure or interruption behavior.

## Sequence

```text
accepted Single-Run Alpha Evidence
→ P0-W26 interruption and unknown-effect reconciliation
→ P0-W27 bounded Child Runs
→ Prompt 6-B delegation conformance
→ Prompt 7-B independent adversarial review
→ Prompt 8-B adjudication and bounded authorization
→ only the delegated implementation scope explicitly authorized by Prompt 8-B
```

## P0-W26 boundary

P0-W26 may deepen minimum first-month recovery using observed runtime behavior. It must not invent a replacement Root lifecycle.

It may refine:

- interruption points;
- process cancellation;
- Command cleanup;
- mutation uncertainty;
- restart after external effects;
- orphan classification;
- operator recovery.

Attention belongs to P0-W27 unless an observed Root-only blocker requires a narrower recovery decision.

## P0-W27 boundary

P0-W27 may plan only:

- one read-only Scout Child;
- one independent Verifier Child;
- maximum depth one;
- maximum one active Child;
- no writing Child;
- no peer communication;
- no shared mutable Context;
- no permission expansion;
- bounded result return;
- Root-visible blocking;
- cancellation;
- CLI navigation.

It must consume the proven Root Run model. It must not redefine Root lifecycle, persistence, mutation authority, Command execution, Evidence semantics, or completion.

## Authorization rule

P0-W26, P0-W27, Prompt 6-B, or Prompt 7-B cannot authorize delegated implementation. Prompt 8-B is the only Wave B authorization pass.
