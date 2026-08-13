/**
 * Loadout core schemas.
 *
 * These are Loadout's INTERNAL schemas. They mirror the v0 contract fixtures
 * loaded from /fixtures and used by tests, but they are NOT a copy of the
 * engineering-system source. Loadout owns the schema because Loadout owns
 * the Work Envelope producer role per Decision 0001.
 *
 * All fixtures and runtime values include an explicit `simulated` flag so
 * that nothing can be mistaken for real Kiln enforcement.
 */
import { z } from 'zod';

export const SimulatedFlagSchema = z.object({
  simulated: z.literal(true),
  reason: z.string().min(1)
});
export type SimulatedFlag = z.infer<typeof SimulatedFlagSchema>;

/* ----------------------------- QMR fixture ----------------------------- */

export const QualifiedMethodRecordV0Schema = z.object({
  schema: z.literal('engineering-system/qualified-method-record/v0'),
  fixture: z.boolean().optional(),
  method_id: z.string(),
  method_version: z.string(),
  status: z.enum(['experimental', 'qualified']),
  qualified_for: z.object({
    outcome: z.string(),
    contexts: z.array(z.string()),
    exclusions: z.array(z.string())
  }),
  inputs: z.array(z.string()),
  outputs: z.array(z.string()),
  procedure_ref: z.string(),
  evaluation: z.object({
    evidence_refs: z.array(z.string()),
    models: z.array(z.string()),
    repositories: z.array(z.string()),
    observed_strengths: z.array(z.string()),
    observed_failures: z.array(z.string()),
    confidence: z.string()
  }),
  provenance: z.object({
    arsenal_commit: z.string().nullable(),
    record_digest: z.string()
  })
});
export type QualifiedMethodRecordV0 = z.infer<typeof QualifiedMethodRecordV0Schema>;

/* --------------------------- Work Envelope v0 -------------------------- */

export const WorkEnvelopeV0Schema = z.object({
  schema: z.literal('engineering-system/work-envelope/v0'),
  fixture: z.boolean().optional(),
  work_id: z.string(),
  created_at: z.string(),
  producer: z.object({
    product: z.literal('loadout'),
    version: z.string()
  }),
  goal: z.object({
    title: z.string(),
    success_conditions: z.array(z.string())
  }),
  capability: z.object({
    id: z.string(),
    contract_version: z.string(),
    method_provenance: z.array(z.string())
  }),
  project_state: z.object({
    repository: z.string(),
    base_commit: z.string(),
    workspace_state_digest: z.string()
  }),
  scope: z.object({
    included: z.array(z.string()),
    excluded: z.array(z.string())
  }),
  constraints: z.object({
    must: z.array(z.string()),
    must_not: z.array(z.string())
  }),
  context_refs: z.array(z.string()),
  proof_obligations: z.array(
    z.object({
      id: z.string(),
      kind: z.string(),
      requirement: z.string()
    })
  ),
  authority_requests: z.array(
    z.object({
      capability: z.string(),
      scope: z.string()
    })
  )
});
export type WorkEnvelopeV0 = z.infer<typeof WorkEnvelopeV0Schema>;

/* -------------------------- Run Result Envelope v0 --------------------- */

export const RunResultEnvelopeV0Schema = z.object({
  schema: z.literal('engineering-system/run-result-envelope/v0'),
  fixture: z.boolean().optional(),
  work_id: z.string(),
  run_id: z.string(),
  status: z.enum(['completed', 'blocked', 'cancelled', 'failed', 'unknown']),
  input_state: z.object({
    base_commit: z.string(),
    workspace_state_digest: z.string()
  }),
  final_state: z.object({
    commit: z.string(),
    workspace_state_digest: z.string()
  }),
  authority: z.object({
    requested: z.array(z.string()),
    granted: z.array(z.string()),
    denied: z.array(z.string())
  }),
  effects: z.array(z.unknown()),
  evidence: z.array(
    z.object({
      id: z.string(),
      kind: z.string(),
      state_digest: z.string(),
      description: z.string().optional()
    })
  ),
  proof_obligations: z.object({
    satisfied: z.array(z.string()),
    unsatisfied: z.array(z.string()),
    invalidated: z.array(z.string())
  }),
  unknowns: z.array(z.string()),
  recovery: z.unknown().nullable(),
  acceptance_readiness: z.object({
    ready: z.boolean(),
    reasons: z.array(z.string())
  }),
  simulated: SimulatedFlagSchema.optional()
});
export type RunResultEnvelopeV0 = z.infer<typeof RunResultEnvelopeV0Schema>;

/* ------------------------- Capability contract ------------------------- */

export const CapabilityContractV0Schema = z.object({
  schema: z.literal('loadout/capability-contract/v0'),
  id: z.string(),
  contract_version: z.string(),
  goal_outcome: z.string(),
  inputs: z.array(z.string()),
  outputs: z.array(z.string()),
  effects: z.array(z.string()),
  evidence_expectations: z.array(z.string()),
  failure_shape: z.array(z.string()),
  compatibility: z.object({
    min_method_status: z.string(),
    accepted_contexts: z.array(z.string())
  })
});
export type CapabilityContractV0 = z.infer<typeof CapabilityContractV0Schema>;

/* ------------------------- Loadout Plan v0 --------------------------- */
/**
 * A Loadout Plan v0 is the user-facing, content-addressable description of
 * what Loadout intends to ask Kiln to do, BEFORE any execution.
 *
 * It is produced by `loadout plan` and consumed by `loadout run --plan`.
 * A Plan is a real artifact: it carries a deterministic plan_id (sha256
 * of the canonicalized body) and a work_envelope_digest, both of which
 * are reproduced identically on a fresh `loadout plan` call against the
 * same inputs.
 *
 * The Plan includes the fully-compiled Work Envelope v0 so that `run
 * --plan` does not need to recompute, and the same Work Envelope
 * submitted at plan time is the exact one submitted to the boundary at
 * run time.
 */

export const PlanCompatibilityV0Schema = z.object({
  min_method_status: z.string(),
  accepted_contexts: z.array(z.string()),
  outcome: z.string(),
  qmr_outcome: z.string(),
  qmr_status: z.string(),
  status_sufficient: z.boolean(),
  context_intersections: z.array(z.string())
});
export type PlanCompatibilityV0 = z.infer<typeof PlanCompatibilityV0Schema>;

export const PlanMethodProvenanceV0Schema = z.object({
  method_id: z.string(),
  method_version: z.string(),
  status: z.string(),
  confidence: z.string(),
  record_digest: z.string(),
  arsenal_commit: z.string().nullable()
});
export type PlanMethodProvenanceV0 = z.infer<typeof PlanMethodProvenanceV0Schema>;

export const LoadoutPlanV0Schema = z.object({
  schema: z.literal('loadout/plan/v0'),
  plan_id: z.string(),
  created_at: z.string(),
  goal: z.object({
    id: z.string(),
    title: z.string(),
    success_conditions: z.array(z.string())
  }),
  capability: z.object({
    id: z.string(),
    contract_version: z.string(),
    contract_schema: z.literal('loadout/capability-contract/v0'),
    goal_outcome: z.string(),
    evidence_expectations: z.array(z.string()),
    failure_shape: z.array(z.string())
  }),
  pack: z.object({
    id: z.string(),
    version: z.string()
  }),
  skill: z.object({
    id: z.string(),
    qmr_fixture_path: z.string()
  }),
  method: PlanMethodProvenanceV0Schema,
  compatibility: PlanCompatibilityV0Schema,
  requested_authority: z.array(
    z.object({
      capability: z.string(),
      scope: z.string()
    })
  ),
  proof_obligations: z.array(
    z.object({
      id: z.string(),
      kind: z.string(),
      requirement: z.string()
    })
  ),
  work_envelope: WorkEnvelopeV0Schema,
  work_envelope_digest: z.string(),
  project_state: z.object({
    repository: z.string(),
    base_commit: z.string(),
    workspace_state_digest: z.string()
  }),
  execution_boundary: z.object({
    boundary: z.literal('simulated'),
    reason: z.string(),
    details: z.string()
  }),
  notes: z.array(z.string())
});
export type LoadoutPlanV0 = z.infer<typeof LoadoutPlanV0Schema>;
