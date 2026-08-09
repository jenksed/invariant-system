# KFT-0 — Kiln read-only authority field trial

**Result:** PASS with material findings
**Mode:** Read-only; Kiln was not modified
**Kiln main:** `ad319d7c748a6b723b9cff4187fa06c60bc3cf06`
**Observed PR:** [jenksed/kiln#48](https://github.com/jenksed/kiln/pull/48) at `60367874bfc3c0e6d8cbd736f58e1ae17938943b`
**Arsenal response:** ARS-09 Knowledge Plane v0 on PR #21

## Authority result

```text
OBJECTIVE UNDERSTOOD
IMPLEMENTATION EXISTS
VERIFICATION REPORTED GREEN
IMPLEMENTATION AUTHORITY ABSENT
RESULT: NOT_AUTHORIZED / OWNER ADJUDICATION REQUIRED
```

PR #48 may be technically correct. KFT-0 did not perform a code-acceptance review and makes no claim that the implementation is defective. It found that the implementation was not authorized by Kiln's governing repository state.

## Observed facts

- Kiln main was `ad319d7` and clean in the read-only field-trial checkout.
- P1-S01 was integrated and owner-accepted.
- `AGENTS.md`, `docs/PLANNING.md`, `docs/ROADMAP.md`, and `docs/P1-S02-PLANNING-BASELINE.md` said P1-S02 was planned but not authorized.
- Prompt 8-A remained the sole current build-authorization authority and did not authorize P1-S02.
- The T01 plan on PR #48 was explicitly `Proposed (awaits owner authorization; P1-S02 implementation package is not yet authorized)`.
- PR #48 nevertheless said it implemented T01 under explicit owner authorization at `ad319d7` and reported a fully green validation matrix at head `60367874`.
- No owner-issued authorization record bound to exact owner, scope, base SHA, plan path, and plan digest was found.
- Kiln preflight and CI could validate plan shape and implementation evidence without settling whether repository authority permitted the work.
- Some ignored/local owner-machine Evidence was discoverable by reference but lacked one durable retrieval index available to the trial.

## Accepted decisions

- Kiln's declared authority order outranks a PR-body assertion about Kiln authority.
- A plan, branch, PR, implementation, schema, or green CI result is not implementation authorization.
- Missing or contradictory authority fails closed.
- The legitimate next Kiln action is owner adjudication bound to exact state, not additional implementation.
- Arsenal may record and explain this result but may not alter Kiln or issue authorization on the owner's behalf.

## Assumptions

- The observed Kiln authority documents were current for main `ad319d7`.
- PR #48's reported verification was treated as a claim and was not independently rerun during this authority-focused trial.
- The T01 plan digest `sha256:780f9257cccbb38d279784f8dcec4851923f6238686d228a51d1d37c2d791cb3` identifies the observed plan bytes.

## Unknowns

- Whether the owner intended a message outside the repository to authorize T01.
- Whether an authoritative owner record exists somewhere the trial could not retrieve.
- Whether the owner will reject, ratify, revise, or supersede PR #48.
- Whether PR #48's implementation and validation claims remain correct under an independent technical review.
- Exact field-trial token volume, wall time, and model/tool cost; these were not instrumented and are recorded as not observed rather than estimated.

## Invariants

- Ability to edit or push a branch is not authorization to implement a work package.
- Planned, permitted, authorized, implemented, verified, accepted, and merged are distinct states.
- Completion and acceptance require applicable Evidence bound to the state being claimed.
- Proposed work cannot silently become authorized because implementation already exists.
- Arsenal cannot grant itself or the target repository new authority.

## Negative knowledge

- Do not merge PR #48 based only on green checks.
- Do not solve missing authorization by proposing or beginning more P1-S02 work.
- Do not rewrite Kiln authority documents merely to make Arsenal's route pass.
- Do not treat the PR body as a stronger authority source than Kiln's repository instructions and governing plans.
- Do not erase the contradiction after selecting the stronger source; it is field-trial evidence.
- Do not claim a causal productivity improvement from this single shadow episode.

## Evidence references

| Evidence | Exact binding | Role |
|---|---|---|
| `AGENTS.md` | main `ad319d7`; SHA-256 `c5f06e…cf4` | Highest repository authorization boundary |
| `docs/PLANNING.md` | main `ad319d7`; SHA-256 `6274b8…3d1` | Governing planning and final authorization state |
| `docs/ROADMAP.md` | main `ad319d7`; SHA-256 `39a241…b00` | Accepted roadmap authority and P1-S02 state |
| `docs/P1-S02-PLANNING-BASELINE.md` | main `ad319d7`; SHA-256 `2194ef…523` | Proposed planning-only boundary |
| T01 implementation plan | PR head `60367874`; SHA-256 `780f92…cb3` | Proposed plan and exact target digest |
| PR #48 body | PR head `60367874`; body digest not captured | Conflicting authorization claim and reported verification |
| ARS-09 KFT fixture | Arsenal PR #21 | Reconstructable typed snapshot and regression fixture |

The complete source identities and digests are preserved in `arsenal/knowledge/fixtures/kft-0-kiln.json`.

## Friction observations

- Authority facts were distributed across repository instructions, roadmap, planning index, proposed plan, PR body, Git state, and external/ignored Evidence references.
- Several surfaces reused words such as planned, complete, implemented, verified, and accepted without one machine-readable state vector.
- Green plan validation and CI created a strong correctness signal that could be mistaken for authorization.
- The authorization contradiction required manual cross-document reconciliation.
- Exact Evidence references existed without a uniform durable retrieval path.
- The planned KFT-0 baseline expected a simple “P1-S02 unauthorized” test; the real episode was harder and more valuable because implemented work already existed.

## Likely capability route

```text
Repository Truth
→ typed Knowledge Snapshot
→ source authority resolution
→ lifecycle contradiction detection
→ exact authorization applicability check
→ relevant-subgraph context compilation
→ owner frontier
```

Pressure Test, technical Review, and Verify become legitimate only after the owner establishes what should happen to PR #48. They cannot repair missing authority.

## Capability gaps exposed

| Gap | Arsenal owner | Response |
|---|---|---|
| First-class repository authority resolution | ARS-09/10 boundary | ARS-09 v0 resolves typed claims and fails closed; automatic extraction remains deferred. |
| SHA- and plan-digest-bound authorization records | ARS-09 + Trust consumption | Implemented as an exact record contract and evaluator requirement. |
| Proposed/implemented/verified/accepted lifecycle separation | ARS-09 | Implemented as independent predicates with deterministic findings. |
| Cross-source contradiction and duplicate-ID detection | ARS-09 | Implemented for typed snapshots. Arbitrary prose scanning remains deferred. |
| Durable ignored/local Evidence retrieval | ARS-07/storage follow-on | Made explicit as unavailable Evidence; backend/synchronization remains unimplemented. |
| Exact-state Evidence applicability | ARS-09/11 | Repository SHA and plan digest binding implemented for authority; broader Proof Graph remains ARS-11. |
| Capability discovery and branch-age filtering | ARS-10/demand-driven | Preserved as gaps; not pulled into the first Knowledge Plane slice. |

## What Project Arsenal got right

- The field-trial contract made a blocked result successful rather than pressuring the agent to invent work.
- The read-only boundary prevented the experiment from changing Kiln to satisfy Arsenal.
- The handoff categories forced facts, decisions, assumptions, unknowns, invariants, negative knowledge, evidence, friction, routes, and gaps to remain distinct.
- Naming Kiln early produced a real authority-sensitive design tracer before ARS-09 hardened into generic memory machinery.
- The trial discovered a consequential issue that green CI and preflight did not detect.

## What Project Arsenal got wrong or lacked

- Repository Truth alone did not settle authority applicability.
- Arsenal had no typed Knowledge Snapshot, authority resolver, lifecycle vector, or exact authorization record before the trial.
- The original plan underweighted the possibility that unauthorized implementation would already exist.
- Field Trial metrics were specified but not instrumented for this episode, so time/token/cost overhead remains unknown.
- Evidence retrieval assumptions were too optimistic for ignored/local owner-machine artifacts.

## ARS-09 design response

KFT-0 directly produced:

- `arsenal/knowledge/CONTRACT.md`;
- `arsenal/knowledge/snapshot.schema.json`;
- `arsenal/knowledge/fixtures/kft-0-kiln.json`;
- `scripts/arsenal_knowledge.py`;
- `scripts/test-arsenal-knowledge.py`;
- `docs/use/knowledge-plane.md`.

The fixture is a permanent regression case. Arsenal fails this tracer if it authorizes T01, hides the conflicting PR claim, collapses lifecycle states, treats stale evidence as current, or requires Kiln mutation to reach a result.

## Exit gate

KFT-0 passes:

1. the shadow task is reconstructable;
2. Arsenal preserved Kiln's authorization boundary;
3. Kiln was not modified;
4. concrete Knowledge Plane contracts and tests came from the episode;
5. losses, friction, unavailable Evidence, and unobserved metrics are recorded.

Passing KFT-0 does not authorize KFT-1 implementation assistance. KFT-1 still requires ARS-09 acceptance and a Kiln task that Kiln itself explicitly authorizes.
