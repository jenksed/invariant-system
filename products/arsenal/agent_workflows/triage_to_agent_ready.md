# Triage a Request to an Agent-Ready State

Move an incoming bug, feature request, or external change from raw report to a defensible next state.

## States

Use the repository's existing labels/states when present. Conceptually distinguish:

- **needs triage** — not yet evaluated;
- **needs information** — blocked on reporter/domain evidence;
- **ready for agent** — behavior and acceptance are sufficiently specified for autonomous work;
- **ready for human** — implementation/decision requires human access or judgment;
- **rejected** — intentionally not pursued.

Keep category (bug/enhancement/etc.) separate from workflow state.

## Workflow

1. Read the full request, discussion, labels, attachments, and any attached code.
2. Inspect project vocabulary and durable decisions.
3. Search the codebase for already-existing behavior by concept, not only exact wording.
4. Check rejected-decision memory for prior decisions on the same concept.
5. Recommend category/state with a short evidence-based reason.
6. Verify the core claim before expanding the request:
   - bugs: reproduce or establish a feedback loop;
   - external code: inspect the diff and run relevant checks;
   - enhancements: confirm the stated current behavior.
7. If decisions remain, use Decision-Tree Grilling. Do not re-ask resolved discussion points.
8. Apply the resulting state.

## Agent-ready brief

When ready for autonomous work, produce a durable behavioral brief:

- **Summary**
- **Current behavior/state**
- **Desired behavior**
- **Important interfaces/invariants**
- **Acceptance criteria** — independently verifiable
- **Out of scope**
- **Evidence/primary-source pointers**

Avoid line numbers and brittle file-path instructions unless the path itself is part of the contract.

## Rejected work

For a durable rejected enhancement, update the project's rejected-decision memory with the concept, reason, prior request pointer, and reconsideration trigger.

Do not record already-implemented behavior as a rejection.

## Completion

Triage is complete when the request has exactly one actionable state and enough evidence/context that the next actor understands why it is there.