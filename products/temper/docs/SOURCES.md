# Temper v0 source map

Temper is a read-only projection. It does not query SQLite or import product
implementation modules. Every visible product fact comes from a file already
published by Loadout from Kiln's canonical Run Result Envelope.

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

Evidence freshness and contradiction are deliberately rendered as `n/a` in
v0 because `engineering-system/run-result-envelope/v0` does not publish those
projections. Temper does not infer them from unrelated digests.

The canonical producer form is `runResult` plus `sourcePlan.plan_path`.
Temper also reads the already-supported explicit diagnostic summary form
(`result` plus `sourcePlanPath`) for replay; that compatibility form is not
treated as the producer contract.
