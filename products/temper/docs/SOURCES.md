# Temper source map

Temper is a read-only projection. It does not query SQLite or import product
implementation modules. Every visible product fact comes from a file already
published by Loadout from Kiln's canonical Run Result Envelope (v0) or
Kiln's canonical Run Result Projection (m0-v1).

## v0 sources (Loadout / Kiln)

| Visible value | Semantic owner | File consumed | Command that produces it |
|---|---|---|---|
| Goal and Plan | Loadout | Plan at canonical `sourcePlan.plan_path` in `.loadout/runs/<run-id>.json` | `npx loadout plan --goal "Understand this repository" --repository <repo> --execution kiln` |
| Run id and state | Kiln | canonical `.loadout/runs/<run-id>.json` → `runResult` | `npx loadout run --plan <plan-path> --repository <repo> --execution kiln` |
| Authority | Kiln | Run Result → `authority` | same real-Kiln run command |
| Evidence references | Kiln | Run Result → `evidence[]` | same real-Kiln run command |
| Artifact references | Kiln | Run Result → `effects[].artifact_id` | same real-Kiln run command |
| Unknowns | Kiln | Run Result → `unknowns[]` | same real-Kiln run command |
| Acceptance readiness | Kiln | Run Result → `acceptance_readiness` | same real-Kiln run command |
| Raw Result | Kiln | exact Run Result object stored in the Loadout Run record | same real-Kiln run command |
| Repository currentness | Git + derived Temper projection | repository `HEAD` compared with Run Result `final_state.commit` | `git -C <repo> rev-parse HEAD` |

## M0 sources (Kiln M0 governed loop)

| Visible value | Semantic owner | File consumed | Command that produces it |
|---|---|---|---|
| Run status (loop truth) | Kiln M0 | Run Result Projection → `truth.run_status` | `mix kiln human-decide` (final M0 dispatch that produces the projection) |
| Verification status | Kiln M0 | Run Result Projection → `truth.verification_status` | `mix kiln verify-run` |
| Review status | Kiln M0 | Run Result Projection → `truth.review_status` | `mix kiln review-propose` |
| Human decision status | Kiln M0 | Run Result Projection → `truth.human_status` | `mix kiln human-decide` |
| Unknown effects | Kiln M0 | Run Result Projection → `truth.unknown_effects[]` | `mix kiln human-decide` |
| Plan reference | Kiln M0 | Run Result Projection → `plan_ref.{id,digest}` | derived from projection |
| Implementer assignment ref | Kiln M0 | Run Result Projection → `implementer_assignment_ref.{id,digest}` | `mix kiln worker-propose` (M8) → Manifold selection (M7) |
| Reviewer assignment ref | Kiln M0 | Run Result Projection → `reviewer_assignment_ref.{id,digest}` | `mix kiln review-propose` (M9) → Manifold REVIEWER selection (M7) |
| Patch reference | Kiln M0 | Run Result Projection → `patch_ref.{id,digest}` | `mix kiln patch-decide` (M8) |
| Patch decision reference | Kiln M0 | Run Result Projection → `patch_decision_ref.{id,digest}` | `mix kiln patch-decide` (M8) |
| Verification reference | Kiln M0 | Run Result Projection → `verification_ref.{id,digest}` | `mix kiln verify-run` (M9) |
| Review reference (when present) | Kiln M0 | Run Result Projection → `review_ref.{id,digest}` | `mix kiln review-propose` (M9) |
| Human decision reference (when present) | Kiln M0 | Run Result Projection → `human_decision_ref.{id,digest}` | `mix kiln human-decide` (M9) |
| Run result envelope reference | Kiln M0 | Run Result Projection → `run_result_ref.{id,digest}` | `npx loadout run` (v0 producer) |

## Discovery convention

The M0 RunResultProjection is discovered at:
```
<run_record_directory>/../projections/<projection_id>.json
```

i.e. sibling to the `runs/` directory. The canonical schema is
`engineering-system/run-result-projection/m0-v1`; the filename is
`<projection_id>.json`.

## Rejection policy

Temper rejects at the load layer (never silently promotes to the operator):

1. `simulated: true` on the v0 Run Result record (existing rule).
2. `fixture_only: true` on the M0 RunResultProjection metadata (new M10).
3. `fixture_only: true` on individual artifact files (per M10 contract).

A rejected projection surfaces in the `errors` list; the loop focus renders
`n/a — <reason>` rather than the rejected values.

## Authority boundary

Temper is a projection surface. The M0 actions module
(`products/temper/src/actions.ts`) constructs argv for the owning
Kiln CLI command and invokes it via `execFileSync` (no shell). The
argv is built from artifact refs and the bounded result-state
digest. No free-form shell. No Temper state mutation. After the
owning command exits, the caller re-reads the durable artifacts
and re-renders — the projection is never mutated by the action.

## Canonical producer form (v0)

The canonical producer form is `runResult` plus `sourcePlan.plan_path`.
Temper also reads the already-supported explicit diagnostic summary form
(`result` plus `sourcePlanPath`) for replay; that compatibility form is not
treated as the producer contract.

## Canonical producer form (M0)

The canonical M0 producer form is the M0 RunResultProjection JSON
written by `mix kiln human-decide` (the final M0 dispatch that
records the operator's authoritative decision and emits the
projection that complements — never rewrites — the v0 Run Result
Envelope). Temper does not infer the projection from unrelated
artifacts; it loads the projection directly.
