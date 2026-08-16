# Synthesize a Buildable Spec From Resolved Context

Use when the important design decisions are already present in the conversation, Wayfinding map, research, prototypes, ADRs, and repository evidence.

**Do not restart discovery by interviewing the user about settled decisions.** Synthesize first; ask only when a genuinely unresolved contradiction blocks a buildable contract.

## Inputs

- current repository truth;
- resolved product/domain decisions;
- Wayfinding decision pointers when applicable;
- prototype/research evidence;
- durable ADRs/policy;
- Engineering Doctrine and project constraints.

## Spec structure

### Problem / outcome
What problem is being solved and what observable outcome should exist?

### Behavioral requirements
Numbered, testable behaviors from the user's perspective, including meaningful error/edge cases.

### Domain and interface decisions
The settled concepts, public interfaces, invariants, data/schema/API contracts, and compatibility decisions that implementation must preserve.

Avoid brittle line numbers and unnecessary file-path prescriptions.

### Testing / verification decisions
State the behavior seams and evidence required to demonstrate completion. Prefer existing seams; new seams need architectural justification.

### Operational / security constraints
Only the controls proportionate to blast radius, irreversibility, external effects, and uncertainty.

### Out of scope
Explicitly bound adjacent work.

### Decision provenance
For non-obvious/load-bearing decisions, link to the primary source: Wayfinding resolution, ADR, research, prototype, issue discussion, or evidence artifact.

## Quality gate

A spec is buildable when an implementation planner can decompose it without inventing product behavior or re-litigating settled architecture.

A spec should not pretend to be eternal truth. Once verified behavior is embodied in code/tests/schemas and durable decisions, treat the spec according to the repository's lifecycle policy.