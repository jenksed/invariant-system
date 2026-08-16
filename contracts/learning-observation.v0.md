# Learning Observation v0

**Status:** Experimental semantic contract  
**Producer:** Loadout or Kiln through explicit reviewed projection  
**Consumer:** Arsenal

## Purpose

Return product and runtime observations to Arsenal without silently converting experience into doctrine or qualification.

## Minimum observation

```yaml
schema: engineering-system/learning-observation/v0
observation_id: "..."
source_product: loadout|kiln
source_ref: "..."
capability_id: "..."
method_provenance: []
project_context:
  repository_shape: "..."
outcome:
  status: "..."
  evidence_refs: []
friction: []
failures: []
unknowns: []
cost:
  elapsed_ms: null
  model_usage: null
review:
  reviewed: false
  reviewer: null
```

## Invariants

- An observation is not a Claim, qualification, or policy.
- Customer/source data remains local or controlled unless explicit sharing authority exists.
- Failure and unknown data must not be filtered merely because the user-facing result succeeded.
- Arsenal determines whether observations justify a hypothesis, experiment, or qualification change.
- No automatic path from observation to Kiln enforcement exists.

