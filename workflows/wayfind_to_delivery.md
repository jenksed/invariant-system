# Wayfind to Software Delivery

Use for a software effort whose route is too foggy for one planning session.

## Phase 1 — Wayfind

Use `agent_workflows/wayfind.md` until:

- the destination is a buildable software outcome/spec;
- consequential in-scope fog is gone;
- every load-bearing decision has evidence/primary-source pointers.

Do not create implementation tickets from unresolved decision nodes.

## Phase 2 — Collapse the map

Use `software_engineering/spec_from_resolved_context.md` to synthesize the map into a coherent buildable spec.

The spec should compress decisions without severing provenance: link back to the relevant decision source when implementation may need to inspect the original reasoning.

## Phase 3 — Decompose implementation

Use `software_engineering/work_to_tracer_tickets.md` to create dependency-aware vertical implementation slices.

Decision graph and implementation graph are distinct. The former answers what/why; the latter delivers behavior.

## Phase 4 — Implement

For each implementation frontier ticket:

- start with fresh enough context;
- recover its spec/decision pointers;
- use TDD/feedback-loop primitives where appropriate;
- run repository verification continuously;
- keep changes bounded to the ticket contract.

Parallelize only independent tickets whose blockers and mutation surfaces make that safe.

## Phase 5 — Review and evidence

Use multi-axis code review and independent verification/receipts before claiming completion.

## Phase 6 — Retire transition artifacts appropriately

Once behavior is verified in the system:

- durable architectural/product decisions remain durable;
- tests/schemas/code become executable truth;
- the spec/map remain historical evidence or may be closed/archived according to project policy;
- unresolved future ideas should not stay disguised as completed scope.