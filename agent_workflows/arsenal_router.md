# Project Arsenal Router

Use this when the user knows the outcome they want but not which Arsenal capability should drive it.

Choose the smallest workflow that fits. Do not invoke heavyweight process when a direct answer or single prompt is enough.

## Planning and project work

- **Unclear plan/design that can fit in one session** → `agent_workflows/grill_decision_tree.md`
- **Large effort with genuine multi-session fog/dependent decisions** → `agent_workflows/wayfind.md`
- **Need repository truth before deciding** → `agent_workflows/repository_truth_audit.md`
- **Need an execution plan with gates** → `agent_workflows/execution_plan_with_acceptance_gates.md`
- **Need to resume from prior work** → `agent_workflows/project_session_kickoff.md` or `resume_from_checkpoint.md`
- **Need portable continuation** → `agent_workflows/session_handoff_and_continuation.md`

## Software engineering

- **Hard bug/performance regression** → `software_engineering/diagnose_bug_feedback_loop.md`
- **Build behavior test-first** → `software_engineering/tdd_vertical_slice.md`
- **Review branch/PR/change** → `software_engineering/code_review_multi_axis.md`
- **Design question needs something concrete** → `software_engineering/prototype_to_answer_question.md`
- **Resolved thinking needs a buildable spec** → `software_engineering/spec_from_resolved_context.md`
- **Spec/plan needs implementation slices** → `software_engineering/work_to_tracer_tickets.md`
- **Merge/rebase conflict** → `software_engineering/resolve_merge_conflicts_by_intent.md`
- **Architecture friction/refactor candidates** → `software_engineering/architecture_deepening_review.md`
- **Human-only setup/cutover steps** → `software_engineering/human_setup_wizard.md`

## Other recurring work

- **Research ending in a decision** → `workflows/research_to_decision.md`
- **Learning toward demonstrable capability** → `workflows/learning_to_portfolio.md`
- **Job application** → `workflows/job_application.md`
- **Recurring activity worth systematizing** → `workflows/recurring_loop_discovery.md`
- **Need information from another domain expert** → `agent_workflows/domain_questionnaire.md`

## Routing rules

1. Prefer an existing narrow asset over inventing a new workflow.
2. Prefer normal grilling over Wayfinding unless multi-session fog is real.
3. Prefer deterministic tools/checks over prose instructions when the repository already exposes them.
4. If two assets overlap, identify which phase each owns rather than stacking both blindly.
5. If no Arsenal asset fits cleanly, say so and use the underlying Engineering Doctrine to proceed directly.