---
title: M4 Graph Ownership Audit
description: Ownership classification for canonical Graph facts and operator projections.
status: experimental
verified_at_commit: 5e7b0134d5e901603904ca5b1f4f3f16d4a472ec
source_paths:
  - products/kiln/lib/kiln/graph_projection.ex
  - products/temper-elixir/
audience:
  - developer
  - operator
---

# M4 GraphOwnership Audit

## Per-Responsibility Classification

`Kiln.GraphProjection` (current implementation) owns the following:

### A. CANONICAL FACT DERIVATION (legitimate near Kiln contracts)

These are real ref-bearing relationships between M0 envelopes. They
belong in or near the canonical contracts.

| Function            | What it derives                                              |
|---------------------|--------------------------------------------------------------|
| `build/1`           | Reads canonical envelopes, returns canonical id-bound graph. |
| `build_nodes/1`     | Maps each M0 envelope to a node carrying its canonical id + semantic_digest. |
| `maybe_add_*`       | Pattern-match on canonical envelope types.                   |
| `build_edges/2`     | Constructs edges from canonical `*_ref` fields (verifier_ref, patch_ref, decision_ref, review_ref). |
| `node_id_of/1`      | Extracts canonical id from envelope.                          |

The edges that come from canonical refs:
- `VERIFIED` (VerificationResult → PatchProposal): from `patch_ref`
- `REVIEWED` (Review → PatchProposal): from `patch_ref`
- `ASSESSED` (Review → VerificationResult): from `verifier_ref`
- `DECIDED_ON` (HumanDecision → PatchProposal): from `patch_ref`
- `AUTHORIZED` (HumanDecision → Review): from `review_ref`
- `APPLIED_AFTER` (PatchEvidence → HumanDecision): from `decision_ref`
- `APPLIED` (PatchEvidence → PatchProposal): from `patch_ref`

**Boundary verdict**: this material belongs in Kiln because each
edge corresponds to an existing `*_ref` field in an M0 envelope.
The graph representation is a structural reading of existing
canonical state.

### B. OPERATOR PROJECTION (must NOT live in Kiln)

These are display / UX semantics, not Kiln domain facts.

| Function                       | What it owns                                          |
|--------------------------------|-------------------------------------------------------|
| `worker_output_node/1`         | `label: "Worker Output"` (display string)            |
| `proposal_node/1`              | `label: "Patch Proposal"` (display string)            |
| `verification_node/1`          | `label: "Verification: #{status}"` (display)         |
| `review_node/1`                | `label: "Review: #{verdict}"` (display)               |
| `human_decision_node/1`        | `label: "Human: #{decision}"` (display)              |
| `patch_evidence_node/1`        | `label: "Patch Applied"` (display)                    |
| `attention_for_proposal/1`     | always "WORKING" (UI tag)                              |
| `attention_for_verification/1` | PASS→WORKING / FAIL→FAILED / else→BLOCKED             |
| `attention_for_review/1`       | APPROVE→WORKING / REJECT→FAILED / REQUEST_REVISION→BLOCKED |
| `attention_required/1`         | Filter for BLOCKED/FAILED/WAITING_FOR_HUMAN           |
| `@attention_states`            | `WORKING/BLOCKED/FAILED/WAITING_FOR_HUMAN/COMPLETE`   |

**Boundary verdict**: the `label` strings and the
attention-classification logic are Temper/operator projection
concerns. They:
- Use human language ("Worker Output", "Human: ACCEPT").
- Classify state in a UI-tag vocabulary that is not part of
  M0 envelope contracts (e.g., `M0VerificationResult.status` is
  `:PASS | :FAIL | :TIMEOUT | :ERROR`; the "WORKING" / "BLOCKED"
  / "FAILED" triple is a Temper concern).
- Mix canonical facts (envelope id, semantic_digest) with display
  facts (label, attention) in the same struct.

These should move out of Kiln into a Temper-side projection layer.

### C. PROPOSED / PLANNING (deferred per directive)

The `proposed: true|false` field exists on the graph_node and
graph_edge types but no proposed-graph logic exists yet. The
directive says: "DO NOT BUILD ProposedGraph YET". Defer.

**Boundary verdict**: the `proposed` field is preserved as a
data-model property; no actual proposed-graph semantics are
implemented. A separate `Temper.ProposedGraph` (or similar) would
emit `proposed: true` edges, but the canonical graph module does
not need to know about that distinction beyond the boolean.

### Edge-case: WorkerOutput → PatchProposal (`PRODUCED`)

This edge is **not** a canonical ref. There is no
`M0WorkerOutput.proposal_ref` field. The connection is implicit:
the proposal's `completion_bytes` are derived from the worker
output's `completion_bytes`. The `PatchProposal.build/4` takes the
worker_output and the operations and produces a proposal.

**Boundary verdict**: this edge is **derived** at build-time by
`PatchProposal.build/4`, not a stable canonical ref. The graph
projection knows the two envelopes "go together" only because the
caller passed them together in the `facts` map.

This means: the graph projection's claim "this WorkerOutput
PRODUCED this PatchProposal" is true only if the caller's `facts`
map is internally consistent. The graph module should not be the
arbiter of that consistency — that's the caller's responsibility.

## Recommended Module Boundaries

```
KILN (canonical execution truth)
├── M0 envelope structs (unchanged)
└── Kiln.GraphProjection           (canonical fact derivation only)
    ├── build/1
    ├── provenance_for/2           (uses only canonical edges)
    ├── node_id_of/1
    └── ref-derived edge construction (VERIFIED, REVIEWED, ...)

TEMPER (operator projection, M4)
└── Temper.AttentionProjection    (NEW)
    ├── label nodes with human-readable strings
    ├── classify attention (WORKING / BLOCKED / FAILED / WAITING_FOR_HUMAN / COMPLETE)
    └── filter attention_required

PROPOSED_GRAPH (M5+)
└── Temper.ProposedGraph          (DEFERRED)
    ├── planner-generated nodes
    ├── proposed: true edges
    └── cannot intersect canonical nodes (digest collision check)
```

Concretely, in this slice:

- Move label construction, attention classification, and
  `attention_required/1` out of `Kiln.GraphProjection` into a new
  `Temper.AttentionProjection` module. The Temper module consumes
  a `Kiln.GraphProjection` and produces a derived view.
- The `graph_node` type splits into a canonical `graph_node` (id,
  kind, canonical_digest, metadata) and a Temper `attention_node`
  wrapping it.
- The `proposed` boolean is preserved as a field on the canonical
  graph_node (so Temper layers can tag proposed edges) but no
  proposed-graph logic exists yet.

## Attention Canonical vs Derived

Current attention states, classified:

| State                | Canonical? | Reason                                                       |
|----------------------|-----------|--------------------------------------------------------------|
| `WORKING`            | DERIVED   | Derived from a verdict/status, not a domain fact.            |
| `BLOCKED`            | DERIVED   | Derived from REQUEST_REVISION verdict. Not a domain fact.     |
| `FAILED`             | DERIVED   | Derived from FAIL status or REJECT verdict. Not a domain fact. |
| `WAITING_FOR_HUMAN`  | DERIVED   | Derived from run_state == :waiting_for_user. Not in the M0 envelope. |
| `COMPLETE`           | DERIVED   | Derived from human_decision present / patch_evidence recorded. |

**None of the attention states are canonical M0 domain facts.** All
five are Temper-side classifications. The current placement in
`Kiln.GraphProjection` is a domain boundary violation.

In this slice, attention moves entirely to `Temper.AttentionProjection`.

## Invariants Preserved

- The canonical graph's edges are still constructed only from
  canonical `*_ref` fields (and the build-time PRODUCED edge which
  is caller's responsibility).
- `proposed: false` is the only value produced by the canonical
  graph. No `proposed: true` edges emerge from Kiln.
- `provenance_for/2` continues to walk the canonical edges and
  preserve identity.
