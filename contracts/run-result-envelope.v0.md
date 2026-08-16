# Run Result Envelope v0

**Status:** Experimental semantic contract  
**Producer:** Kiln  
**Consumer:** Loadout; reviewed projection may feed Arsenal

## Purpose

Return canonical runtime facts for one attempted Work Envelope without claiming more success than the evidence supports.

## Minimum envelope

```yaml
schema: engineering-system/run-result-envelope/v0
work_id: "..."
run_id: "..."
status: completed|blocked|cancelled|failed|unknown
input_state:
  base_commit: "..."
  workspace_state_digest: "..."
final_state:
  commit: "..."
  workspace_state_digest: "..."
authority:
  requested: []
  granted: []
  denied: []
effects: []
evidence: []
proof_obligations:
  satisfied: []
  unsatisfied: []
  invalidated: []
unknowns: []
recovery: null
acceptance_readiness:
  ready: false
  reasons: []
```

## Invariants

- `completed` describes Run lifecycle, not human acceptance.
- Evidence is bound to the state against which it was obtained.
- A later relevant state mutation can invalidate earlier evidence.
- Unknown effects remain explicit and prevent false certainty.
- Loadout may transform presentation but must not strengthen the semantic claim.
- Arsenal may receive reviewed observations; it must not treat one Run as a qualified method conclusion.
- Human or authorized workflow acceptance remains external to the envelope.

## v0 exclusions

- universal software correctness;
- semantic proof that a model understood inspected material;
- cross-organization audit export;
- nested Run aggregation;
- automatic policy creation.

