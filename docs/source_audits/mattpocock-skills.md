# Source Audit — mattpocock/skills

Audit date: 2026-08-07

Source repository: `mattpocock/skills`

Source commit reviewed: `84fdeffd12f2ee307994d1eb6feb48173b6e0502`

License observed in source repository: MIT.

This audit records concepts and operating patterns adapted into Project Arsenal. Arsenal implementations should preserve the useful engineering idea without depending on Matt Pocock's repository layout, product names, issue-label vocabulary, Claude plugin packaging, or exact prompt text.

A user-provided transcript explaining Wayfinder was also treated as primary design evidence for the conceptual model.

## Adopt as foundations

| Source capability/pattern | Arsenal treatment | Why |
|---|---|---|
| `grilling` / `grill-me` | `foundations/grilling.md` + thin prompt wrapper | Dependency-aware decision frontier is a reusable primitive, not a one-off prompt. |
| `wayfinder` | `foundations/wayfinding.md` + orchestration workflow | Multi-session decision mapping, fog, frontier, blocking, and primary-source decisions are foundational. |
| `domain-modeling` | `foundations/domain_language.md` | Shared domain language and selective ADR capture reduce interpretation cost across every workflow. |
| phase-boundary decision tree | `foundations/context_boundaries.md` | Continue/clear/handoff/delegate/compact is a context-engineering method independent of a specific harness. |
| writing-for-agents | `prompt_design/writing_for_agents.md` | Context pointers, progressive disclosure, completion criteria, pruning, and single sourcing belong in Arsenal authoring standards. |
| `.out-of-scope` knowledge base | `foundations/rejected_decision_memory.md` | Durable rejection memory prevents repeated re-litigation and improves triage. |
| user-vs-model invocation split | `arsenal/INVOCATION_MODEL.md` | Arsenal needs invocation semantics without making Claude/Codex packaging the canonical representation. |

## Adopt as software/agent workflows

| Source capability | Arsenal direction |
|---|---|
| `diagnosing-bugs` | Feedback-loop-first bug diagnosis with a red-capable reproduction gate. |
| `tdd` | Seam-aware red/green vertical slices with behavior-focused tests. |
| `code-review` | Independent review axes so spec correctness cannot hide standards failures or vice versa. |
| `prototype` | Throwaway artifact explicitly tied to one design question, retained only as evidence. |
| `to-spec` | Synthesize already-resolved conversation/map decisions; do not re-interview settled questions. |
| `to-tickets` | Tracer-bullet implementation slices with dependency edges; use expand/migrate/contract for wide refactors. |
| `implement` | Keep orchestration thin and delegate discipline to reusable implementation, TDD, review, and verification primitives. |
| `improve-codebase-architecture` + `codebase-design` | Architecture deepening review using explicit seams, interface leverage, locality, and multiple design alternatives. |
| `research` | Strong overlap with Arsenal research assets; retain primary-source preference and durable cited findings. |
| `resolving-merge-conflicts` | Resolve by original intent/evidence, not by mechanically choosing lines. |
| `wizard` | Convert unavoidable human-only procedures into explicit, gated, verifiable walkthroughs. |
| `triage` | State-machine triage, claim verification, agent-ready briefs, and rejected-decision memory. |
| `to-questionnaire` | Externalize knowledge gaps to the person who owns the missing domain facts; interview the send, not the unknown subject. |
| `wait-what` | Lightweight re-explanation capability using project vocabulary; useful but intentionally tiny. |
| `handoff` | Strong overlap with Arsenal session handoff; preserve pointer-not-duplication and portability principles. |
| `ask-matt` | Arsenal router should map goals to workflows without becoming the implementation of those workflows. |

## Learning and writing patterns that fit

| Source capability | Arsenal treatment |
|---|---|
| `teach` | Stateful learning workspace: mission, trusted resources, learning records, lessons, reference artifacts, retrieval practice, and feedback loops. |
| `loop-me` | Recurring-loop discovery should feed Arsenal's workflow-package architecture: identify repeated activity, trigger, checkpoints, and late HITL review. |
| `writing-fragments` | Preserve as a distinct raw-material collection phase for long-form writing. |
| `writing-beats` | Preserve journey/beat planning as a distinct structure phase. |
| `writing-shape` | Preserve paragraph-level shaping as a separate synthesis phase. |
| `scaffold-exercises` | Overlaps Arsenal portfolio/lab and learning-session assets; borrow exercise scaffolding principles rather than a duplicate canonical prompt initially. |

## Infrastructure ideas to carry forward

- A repo-local setup workflow that discovers tracker, domain-doc, verification, and policy conventions rather than hardcoding them.
- Thin orchestrators over reusable primitives.
- Explicit lifecycle buckets; Arsenal already models this through registry status rather than directory placement.
- Deterministic install/integrity checks and a future selective installer/synchronizer.
- Git guardrails implemented structurally (hooks/permissions) where the harness supports them.
- Pre-commit/typecheck/test feedback loops as Development Pack machinery rather than prose-only rules.
- Language-specific deep-module enforcement belongs in Development Packs, not Arsenal's universal core.

## Do not import as canonical Arsenal assets

- Repository-specific migration utilities such as `migrate-to-shoehorn`.
- Claude-specific background-handoff mechanics as a universal contract; preserve the portable handoff concept instead.
- Exact GitHub label names, plugin manifests, docs publishing conventions, or Matt's setup file layout.
- A mandatory Wayfinding process for ordinary scoped work. Wayfinding is explicitly for genuine multi-session fog.

## Architectural takeaway

The strongest idea in the source repository is not any individual prompt. It is the separation of:

1. reusable disciplines;
2. thin user-facing orchestrators;
3. shared vocabulary/reference;
4. durable project state;
5. deterministic tooling around the prompts.

Project Arsenal should push that separation further by making the reusable method independent of the eventual skill/runtime packaging.