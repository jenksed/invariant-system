# Capability Graph & Gap Preflight Contract

Status: ARS-04 v0

Project Arsenal must be able to determine whether an intended route is actually executable **before** an agent begins improvising around missing competence.

## Public primitive

**Capability Gap Preflight** answers:

> Given an intended route, are all required capabilities present, implemented, compatible, sufficiently qualified, and authorized for the requested execution boundary?

The answer is deterministic and explainable.

## Source-of-truth boundary

The graph does not replace Capability Contract v2.

- Capability Contract owns behavior, inputs, outputs, preconditions, authority, execution surfaces, lifecycle, evaluation, implementation assets, and compatibility metadata.
- The Asset Registry owns canonical implementation paths.
- `.arsenal.lock` owns pinned/distributed competence.
- Capability Graph owns explicit composition routes, ordering/dependency edges, route-level minimum qualification, and authority profiles used for preflight.

Do not infer consequential dependencies from similar-looking free-text names. ARS-04 v0 uses explicit route edges and validates them against canonical capability metadata.

## Graph data

`arsenal/graph/graph.json` defines:

- authority profiles;
- named routes;
- ordered capability steps;
- explicit `after` dependencies;
- minimum capability version;
- minimum lifecycle/evaluation qualification per step.

The route does not duplicate capability authority or implementation paths. Those are read from the canonical capability and registry at preflight time.

## Inventory modes

Preflight supports two inventory views:

### canonical

All capability fragments present in `arsenal/capabilities/*.json` are considered available competence.

Use this to validate Arsenal's source capability system.

### lock

Only capabilities pinned in `.arsenal.lock` are considered available competence.

Use this to answer a stricter distribution question: **what competence has this repository actually pinned for downstream use?**

ARS-03 v0 currently locks Repository Truth only, so multi-step routes should correctly report gaps under lock inventory rather than borrowing unlocked source capabilities.

## Coverage states

Each required capability is classified as one of:

- `covered` — present, implemented, compatible, sufficiently qualified, and authorized;
- `missing` — required competence or registered implementation is absent;
- `unauthorized` — capability requires authority outside the selected profile;
- `insufficient-qualification` — lifecycle/evaluation state is below route policy;
- `unknown` — metadata exists but cannot be safely interpreted.

The route verdict is one of:

- `READY`;
- `CAPABILITY_GAP`;
- `AUTHORITY_GAP`;
- `QUALIFICATION_GAP`;
- `UNKNOWN`.

A non-ready verdict is a hard stop for the declared route. The caller may choose a different route, install/compile missing competence, authorize a broader safe profile, gather qualification evidence, or explicitly escalate. It may not silently borrow an unrelated capability.

## Qualification order

ARS-04 v0 recognizes the existing Capability Contract states:

Lifecycle:

`draft < testing < stable`

Evaluation:

`unassessed < planned < candidate < qualified`

`deprecated` is never considered sufficient for a new route.

Route requirements may be stricter than the capability's current state, but preflight cannot promote state.

## Authority profiles

Profiles are declared in graph data and contain granted authority vocabulary only. A capability is authorized when every item in `authority.required` is granted and none of its `authority.forbidden` entries are being required by the route.

Profiles do not modify capability contracts.

v0 profiles:

- `read-only`;
- `workspace-safe`;
- `local-cloud-safe`.

Real cloud and production mutation are absent deliberately.

## Implementation availability

A capability is implemented only when:

1. its `implementation.primary_asset` resolves in the merged Asset Registry;
2. the registered path is repository-relative and exists as a file.

A capability fragment without a resolvable implementation is not `covered`.

## Compatibility

ARS-04 v0 uses exact capability IDs plus a minimum semantic version declared by the route. Aliases/display names never substitute for canonical IDs.

Future compatibility ranges may expand after real version skew exists. v0 avoids inventing a package-manager-grade solver before there are multiple published capability versions to solve.

## Explainability

Every preflight report must show, per route step:

- capability ID/display name/version;
- inventory presence;
- primary implementation resolution;
- required vs granted authority;
- lifecycle/evaluation actual vs minimum;
- declared preconditions;
- declared outputs;
- dependency predecessors;
- final step status and reasons.

The route verdict must be derivable from those facts.

## Safety

Preflight is read-only.

It must not:

- install missing capabilities automatically;
- expand authority automatically;
- request real cloud credentials because local competence is missing;
- treat an alias as an implementation;
- treat a capability package as qualified beyond its canonical lifecycle/evaluation state;
- route around a missing step without a separately declared route.

## ARS-04 v0 acceptance

ARS-04 is complete when CI proves at least:

1. a valid canonical feature route is READY under workspace-safe authority;
2. omitting TDD produces `CAPABILITY_GAP`;
3. evaluating the same feature route against `.arsenal.lock` produces `CAPABILITY_GAP` because only Repository Truth is pinned;
4. using read-only authority for feature delivery produces `AUTHORITY_GAP`;
5. requiring `testing` qualification for draft Core capabilities produces `QUALIFICATION_GAP`;
6. Local Cloud route is READY only under `local-cloud-safe` and can consume its earned `testing / candidate` state;
7. Local Cloud route under workspace-safe authority fails rather than requesting remote-cloud credentials;
8. malformed graph edges, unknown capabilities, invalid versions, and invalid qualification states fail closed;
9. Capability Contract, Compiler, Bench, and Arsenal Integrity regressions remain green.
