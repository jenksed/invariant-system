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
| `diagnosing-bugs` | `software_engineering/diagnose_bug_feedback_loop.md` — feedback-loop-first diagnosis with a red-capable reproduction gate. |
| `tdd` | `software_engineering/tdd_vertical_slice.md` — seam-aware red/green vertical slices with behavior-focused tests. |
| `code-review` | `software_engineering/code_review_multi_axis.md` — independent review axes so spec correctness cannot hide standards/evidence failures. |
| `prototype` | `software_engineering/prototype_to_answer_question.md` — disposable artifact tied to one design question and retained only as useful evidence. |
| `to-spec` | `software_engineering/spec_from_resolved_context.md` — synthesize already-resolved conversation/map decisions rather than re-interview settled questions. |
| `to-tickets` | `software_engineering/work_to_tracer_tickets.md` — tracer-bullet implementation slices with dependency edges and expand/migrate/contract for wide refactors. |
| `implement` | Existing feature-delivery workflows remain thin and delegate discipline to implementation, TDD, review, and verification primitives. |
| `improve-codebase-architecture` + `codebase-design` | `software_engineering/architecture_deepening_review.md` — explicit seams, interface leverage/locality, and multiple design alternatives. |
| `research` | Strong overlap with Arsenal research assets; retain primary-source preference and durable cited findings. |
| `resolving-merge-conflicts` | `software_engineering/resolve_merge_conflicts_by_intent.md` — resolve by original intent/evidence, not by mechanically choosing lines. |
| `wizard` | `software_engineering/human_setup_wizard.md` — convert unavoidable human-only procedures into explicit, gated, verifiable walkthroughs. |
| `triage` | `agent_workflows/triage_to_agent_ready.md` — state-machine triage, claim verification, agent-ready briefs, and rejected-decision memory. |
| `to-questionnaire` | `agent_workflows/domain_questionnaire.md` — externalize knowledge gaps to the person who owns them; interview the send, not the unknown subject. |
| `wait-what` | `agent_workflows/rephrase_with_context.md` — intentionally tiny context-restoring re-explanation capability. |
| `handoff` | Strong overlap with Arsenal session handoff; preserve pointer-not-duplication and portability principles. |
| `ask-matt` | `agent_workflows/arsenal_router.md` maps goals to workflows without becoming the implementation of those workflows. |
| repo setup | `agent_workflows/setup_project_arsenal.md` discovers project conventions before adding pointers/configuration. |

## Learning and writing patterns that fit

| Source capability | Arsenal treatment |
|---|---|
| `teach` | `learning/stateful_learning_workspace.md` — mission, trusted resources, learning records, reference artifacts, retrieval practice, and feedback loops. |
| `loop-me` | `workflows/recurring_loop_discovery.md` feeds Arsenal's workflow-package architecture: repeated activity, trigger, checkpoints, permissions, failure behavior, and evidence. |
| `writing-fragments` | `writing/fragment_mining.md` preserves a distinct raw-material collection phase. |
| `writing-beats` | `writing/beat_map.md` preserves reader-journey/beat planning as a distinct structure phase. |
| `writing-shape` | `writing/shape_from_fragments.md` preserves progressive paragraph/section shaping as a separate synthesis phase. |
| `scaffold-exercises` | Overlaps Arsenal portfolio/lab and learning-session assets; borrow exercise-scaffolding principles rather than create a second canonical prompt initially. |

## Infrastructure patterns adopted through Development Packs

`engineering/development_packs/CONTRACT.md` is the common home for the transferable ideas behind source infrastructure skills.

- **Git guardrails** → safe mutation guardrails should be structural hooks/permissions where the harness supports them.
- **Pre-commit setup** → fast, deterministic local feedback belongs in an inner-loop tier; slow/flaky checks move to later verification/CI.
- **Typecheck/test/format orchestration** → every pack should expose obvious inner-loop, slice-gate, and completion-gate verification.
- **TypeScript deep-module setup** → architecture/package-boundary enforcement is valuable when native tooling can enforce a real invariant, but the concrete rule belongs in the relevant language pack.
- **Repo-local setup** → installers inspect existing tooling and preserve conventions rather than installing duplicates.
- **Agent guidance** → pack docs should point at deterministic machinery rather than restate what config/scripts already reveal.

## Other repository-architecture ideas retained

- Thin orchestrators over reusable primitives.
- Explicit lifecycle buckets; Arsenal models this through registry status rather than directory placement.
- Deterministic install/integrity checks and a future selective installer/synchronizer.
- User-invoked vs model-invoked behavior represented as harness-neutral invocation metadata.
- Shared reference is single-sourced and reached by pointers.
- Source/provenance audits are explicit so adaptation boundaries remain inspectable.

## Do not import as canonical Arsenal assets

- Repository-specific migration utilities such as `migrate-to-shoehorn`.
- Claude-specific background-handoff mechanics as a universal contract; preserve the portable handoff concept instead.
- Exact GitHub label names, plugin manifests, docs publishing conventions, or Matt's setup file layout.
- A mandatory Wayfinding process for ordinary scoped work. Wayfinding is explicitly for genuine multi-session fog.
- A language-specific deep-module rule in universal Arsenal core; that belongs in a Development Pack with ecosystem-native enforcement.

## Architectural takeaway

The strongest idea in the source repository is not any individual prompt. It is the separation of:

1. reusable disciplines;
2. thin user-facing orchestrators;
3. shared vocabulary/reference;
4. durable project state;
5. deterministic tooling around the prompts.

Project Arsenal pushes that separation one layer further: the reusable method is independent of its eventual skill, CLI, plugin, or Kiln runtime packaging.