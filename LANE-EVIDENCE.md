# LANE-EVIDENCE — LOADOUT-M0-01 (M4)

## Lane metadata

- Lane: `LOADOUT-M0-01`
- Branch: `m0/loadout-01-implement-change-plan`
- Worktree: `/Users/jenksed/Developer/invariant-system`
- Started at: 2026-08-16T21:42Z
- Author: orchestrator (Pass-05 execution, M4)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/LOADOUT-M0-01.md`
- Authorization model: Loadout has NO `docs/authorizations/` infrastructure (unlike Kiln). Per `products/loadout/AGENTS.md` the boundary rules + first-wave constraints are the governance. The M0 work was authorized by the M2 merge-train state (SYS-M0-01 ratified the M0 packet and `contracts/m0/schemas/...` are now consumable).

## Merge-gate precondition

- Merge gate: **M4** (after M3).
- Predecessor: `m0/kiln-01-candidate-invocation` (M3) merged at `8a23886`. ✓

## Path corrections applied

- The refined package's I1 INVESTIGATION SUBTASK asks whether `CapabilityContractV0Schema.compatibility` requires a QMR fixture for `implement-change`. The capability contract does not *require* a QMR; the QMR is supplied by the Skill (per existing capability registry pattern). A placeholder QMR fixture (`fixtures/implement-change-method-record.v0.yaml`) is created to satisfy the Skill contract's `qmrFixturePath`. Authoritative qualification runs at M6 BENCH-M0-01.

## RISK D protocol

Loadout's flake RISK D protocol (per the refined package) requires running `npm test` end-to-end THREE times on the final branch and observing the fake-Kiln subprocess flake. The fake-Kiln boundary is internal to Loadout's tests (no real subprocess); the existing tests cover the fake boundary deterministically. Three end-to-end `npm test` runs recorded below show stable, deterministic results.

## Files touched

```text
M  products/loadout/src/core/compile.ts              # E4: context_refs for execution binding
M  products/loadout/src/core/contract-validation.ts # E5: catalogue lookup for implement-change
M  products/loadout/src/core/goal.ts                 # E5: implement-a-bounded-change Goal
M  products/loadout/src/core/plan.ts                 # E1: computeSemanticDigest; E2: v2 path in compileLoadoutPlan
M  products/loadout/src/core/schemas.ts              # E2: LoadoutPlanV2Schema + M0 contract mirrors
M  products/loadout/src/index.ts                     # E3+E4+E6: builder re-exports
A  products/loadout/src/core/execution-binding.ts    # E4: Execution Binding builder
A  products/loadout/src/core/intelligence-requirement.ts # E3: Intelligence Requirement builder
A  products/loadout/src/packs/implement-change/pack.json
A  products/loadout/src/packs/implement-change/capability.json
A  products/loadout/src/packs/implement-change/skill.json
A  products/loadout/src/packs/implement-change/run.ts
A  products/loadout/fixtures/implement-change-method-record.v0.yaml # I1
A  products/loadout/tests/unit/implement-change-plan.spec.ts            # E3+E4+E1 unit
A  products/loadout/tests/unit/implement-change-end-to-end.spec.ts     # E5+E4+e2e
A  LANE-EVIDENCE.md
```

Primary paths only? **YES** — every touched path is in the refined package's PRIMARY PATHS or ALLOWED SUPPORTING PATHS list.

## Self-test transcript

### Tests (M4 unit + end-to-end)

```text
$ cd products/loadout && npm test
 Test Files  26 passed (26)
      Tests  140 passed (140)
   Duration  4.26s
```

- Pre-M4 baseline: 129 tests in 24 files
- M4 added: 11 tests in 2 new files (`implement-change-plan.spec.ts`: 8 unit tests; `implement-change-end-to-end.spec.ts`: 3 e2e)
- 0 regressions: every existing test passes unchanged.

### RISK D protocol — three end-to-end `npm run ci` cycles

```text
$ npm run ci   (cycle 1)
... format:check OK; lint OK; typecheck OK; test 140/140 OK;
validate:contracts OK; build OK. exit 0.

$ npm run ci   (cycle 2)
... (same output) exit 0.

$ npm run ci   (cycle 3)
... (same output) exit 0.
```

No fake-Kiln flake observed (RISK D — clean). The fake Kiln boundary is in-process (no real subprocess); existing `tests/integration/cli-plan-run.spec.ts` covers the deterministic fake path with the built `dist/cli.js` (production invocation path).

### `./invariant check` / boundaries

```text
$ ./invariant check       # exit 0
$ ./invariant check boundaries
ok:   single Git root
ok:   no submodules
ok:   manifold is documentation-only
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/learning-observation.v0.md
```

## Architectural changes — what new capability actually exists

**Cross-product seam `loadout → kiln` (M0 bounded change):**

1. **Schema-prefixed semantic digest primitive** (`computeSemanticDigest`) shared across LoadoutPlan v2 + Intelligence Requirement + Execution Binding. The `schemaId` is folded into the digest so payloads that encode identically under different schemas still receive distinct digests.
3. **M0 Execution Binding builder** (`buildExecutionBinding`) produces a content-addressed `engineering-system/execution-binding/m0-v1` artifact binding Plan + Implementer/Reviewer Requirements + Profile/Eligibility/Disclosure/Patch/Contract refs. The binding's `semantic_digest` is embedded in the Work Envelope's `context_refs` so Kiln can validate the binding identity at execution time (P02-D015 propagation).
4. **M0 Intelligence Requirement builders** (`buildImplementerRequirement` / `buildReviewerRequirement`) produce closed-schema `engineering-system/intelligence-requirement/m0-v1` artifacts for IMPLEMENTER and REVIEWER roles. The Reviewer's `must_differ_from_assignment_ref` enforces the self-review prohibition structurally.
5. **Loadout Plan v2** (`LoadoutPlanV2Schema`) carries an `implement_change` block with the M0 plan ref + Execution Binding + Intelligence Requirements. The Plan v2 participates in the same integrity / freshness / procedure-binding checks as v0 / v1.
6. **`implement-change` Capability + Pack + Goal** — a new bounded-change capability with a placeholder QMR (M6 BENCH-M0-01 will run authoritative qualification).

**Architectural discipline preserved:**

- Loadout remains capability/work-intent. No authority, no mutation, no provider selection.
- The M0 Execution Binding is a **request**, not a grant. Authority remains in Kiln.
- The closed schemas make authority smuggling unrepresentable: the schema enforces the absence of any authority-granting field at the type level.
- Loadout still does not import Arsenal or Kiln source. The M0 contract schemas are mirrored in Loadout (closed-shape zod), not imported.
- No runtime agent, no background processing, no provider selection, no plugin system.

## Questions resolved from repository evidence

1. **Does Loadout have an authorization model?** No. `products/loadout/docs/authorizations/` does not exist, and `products/loadout/AGENTS.md` has no authorization requirement. The Loadout governance is the AGENTS.md boundary rules + first-wave constraints. Resolved by reading `products/loadout/AGENTS.md`, `products/loadout/docs/PRODUCT-BOUNDARY.md`, and confirming absence of `docs/authorizations/` and `docs/work/` directories.
2. **What artifact crosses the Loadout → Kiln boundary for bounded change?** A content-addressed `engineering-system/execution-binding/m0-v1` artifact, embedded in the Work Envelope's `context_refs`. Resolved by inspecting `contracts/m0/schemas/execution-binding.m0-v1.schema.json` + the verify-change precedent at `products/loadout/src/core/compile.ts:92-94`.
3. **Is I1 (QMR fixture required for implement-change)?** No for the capability contract; yes for the Skill's `qmrFixturePath`. Created a placeholder QMR (`fixtures/implement-change-method-record.v0.yaml`) so the Skill contract is satisfied until M6 BENCH-M0-01 runs the authoritative qualification.
4. **Does Plan v2 with `implement_change` block require removing `repository_recon` and `verification_change` from V0?** Yes. Implemented via `LoadoutPlanV0Schema.omit({schema: true, repository_recon: true}).extend({schema: 'loadout/plan/v2', implement_change: ...})`. Also fixed a subtle bug where the local var's body and the zod-parsed body's divergence on `repository_recon` would cause `plan.plan_id !== computePlanId(plan)`. Fix: strip `repository_recon` and `verification_change` from the local var before setting `plan_id`.

## STATUS

`ready-to-merge`

## Notes for the integration authority

Per the merge train, this lane merges at **M4**. The lane branch must be deleted post-merge per `BRANCH-STRATEGY.md`. The merge title must be `LOADOUT-M0-01: <one-line summary>`; the recommended summary is "add implement-change Plan v2 + M0 Execution Binding + Intelligence Requirements".

After this lane merges, **M5 (SYS-M0-02) — Manifold boundary transition** becomes eligible to open per decision D4-06. M5 owns the boundary-policy transition (BT-01) that lets Manifold (M7) implement its bounded selector.