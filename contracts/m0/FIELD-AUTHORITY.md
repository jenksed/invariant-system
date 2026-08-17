# Interface Field Authority

| Field family | Owner/meaning | Mutability | Failure |
|---|---|---|---|
| Plan goal/criteria/scope/proof/safety/disclosure | Loadout compiles user intent; request only | immutable per Plan | new Plan required for semantic change |
| Requirement role/task/context | Loadout requirement semantics | immutable | closed-schema rejection |
| Profile provider/model/adapter/config | Profile artifact / program identity contract | immutable | mismatch/substitution rejects |
| Qualification campaign/results | Bench evidence | immutable | not qualified/current => no Assignment |
| Eligibility status/currentness | derived from append-only events | recomputable projection, evidence immutable | ambiguous/stale/invalid => NOT_ELIGIBLE |
| Assignment selection | Manifold | immutable | exact role/profile/eligibility mismatch rejects |
| Work Envelope authority_requests | Loadout request only | immutable request | Kiln may narrow/deny |
| Kiln authority grant | Kiln live policy/preflight | durable decision | cannot be manufactured by Requirement/Assignment |
| Patch operations/after-images | Worker proposal, Kiln content-addresses | immutable proposal | any byte/base mismatch rejects |
| Patch approval | human delegated to Kiln | immutable decision | approval never transfers to revised patch |
| Verification | Kiln registered verifier | immutable evidence | fail/timeout blocks readiness |
| Review | qualified Reviewer via Kiln | immutable for exact state | changed patch/state stales review |
| Human acceptance | human via owning workflow | immutable decision | separate from Run completion |
| Projection | Kiln/program projection | derived only | cannot strengthen canonical facts |
