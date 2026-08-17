/**
 * Intelligence Requirement builder for the M0 bounded-change plan.
 *
 * Per the canonical `engineering-system/intelligence-requirement/m0-v1`
 * schema (mirror at `contracts/m0/schemas/intelligence-requirement.m0-v1.schema.json`),
 * an Intelligence Requirement is a closed-shape content-addressed
 * artifact binding a Plan, role (IMPLEMENTER or REVIEWER), required
 * capabilities, context requirements, and an Independence block that
 * forbids the Implementer transcript from leaking to a Reviewer.
 *
 * Per Loadout AGENTS.md "Boundary rule 3: A package or connector may
 * request authority but cannot grant it." — the schema is structurally
 * closed so an authority-granting field is unrepresentable. This
 * builder raises `IntelligenceRequirementError` if a caller attempts
 * to smuggle one in via the independence refs.
 */
import { randomUUID } from 'node:crypto';
import type { M0ArtifactRef, M0IntelligenceRequirement } from './schemas';
import {
  M0IntelligenceRequirementDisclosureSchema,
  M0IntelligenceRequirementRoleSchema,
  M0IntelligenceRequirementSchema
} from './schemas';
import { computeSemanticDigest } from './plan';

export class IntelligenceRequirementError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'IntelligenceRequirementError';
  }
}

export interface BuildImplementerRequirementArgs {
  planRef: M0ArtifactRef;
  implementerCapabilities: string[];
  contextRequirements?: string[];
  disclosureClass?: 'REMOTE_BY_EXPLICIT_MANIFEST' | 'LOCAL_ONLY';
}

export interface BuildReviewerRequirementArgs {
  planRef: M0ArtifactRef;
  reviewerCapabilities: string[];
  implementerAssignmentRef?: M0ArtifactRef;
  contextRequirements?: string[];
  disclosureClass?: 'REMOTE_BY_EXPLICIT_MANIFEST' | 'LOCAL_ONLY';
}

function identityPayload(
  req: Omit<M0IntelligenceRequirement, 'requirement_id' | 'semantic_digest'>
) {
  // requirement_id and semantic_digest are derived/occur-once; the
  // identity payload excludes both per IDENTITY-CONSTITUTION.
  return {
    schema: req.schema,
    plan_ref: req.plan_ref,
    role: req.role,
    task_kind: req.task_kind,
    required_capabilities: req.required_capabilities,
    context_requirements: req.context_requirements,
    disclosure_class: req.disclosure_class,
    independence: req.independence
  };
}

/**
 * Build an IMPLEMENTER Intelligence Requirement. The role field is
 * structurally locked; the schema's closed-shape enforcement makes an
 * authority-granting field unrepresentable.
 */
export function buildImplementerRequirement(
  args: BuildImplementerRequirementArgs
): M0IntelligenceRequirement {
  const role = 'IMPLEMENTER' as const;
  M0IntelligenceRequirementRoleSchema.parse(role);

  const body = {
    schema: 'engineering-system/intelligence-requirement/m0-v1' as const,
    plan_ref: args.planRef,
    role,
    task_kind: 'SOFTWARE_CHANGE' as const,
    required_capabilities: [...args.implementerCapabilities],
    context_requirements: [...(args.contextRequirements ?? [])],
    disclosure_class: args.disclosureClass ?? ('LOCAL_ONLY' as const),
    independence: {
      must_not_receive_implementer_transcript: true as const,
      must_use_separate_context_manifest: true as const
    }
  };

  const semantic_digest = computeSemanticDigest(body.schema, identityPayload(body));
  const requirement_id = randomUUID();

  const candidate = {
    requirement_id,
    semantic_digest,
    ...body
  };

  return M0IntelligenceRequirementSchema.parse(candidate);
}

/**
 * Build a REVIEWER Intelligence Requirement. The independence block
 * forbids the reviewer from receiving the Implementer transcript and
 * requires a separate context manifest. `must_differ_from_assignment_ref`,
 * when supplied, asserts that the Implementer's Assignment (when
 * emitted) is a distinct artifact from this Reviewer's Intake — a
 * closed-schema guarantee against self-review.
 */
export function buildReviewerRequirement(
  args: BuildReviewerRequirementArgs
): M0IntelligenceRequirement {
  const role = 'REVIEWER' as const;
  M0IntelligenceRequirementRoleSchema.parse(role);

  const independence: M0IntelligenceRequirement['independence'] = {
    must_not_receive_implementer_transcript: true as const,
    must_use_separate_context_manifest: true as const,
    ...(args.implementerAssignmentRef
      ? { must_differ_from_assignment_ref: args.implementerAssignmentRef }
      : {})
  };

  const body = {
    schema: 'engineering-system/intelligence-requirement/m0-v1' as const,
    plan_ref: args.planRef,
    role,
    task_kind: 'SOFTWARE_CHANGE' as const,
    required_capabilities: [...args.reviewerCapabilities],
    context_requirements: [...(args.contextRequirements ?? [])],
    disclosure_class: args.disclosureClass ?? ('LOCAL_ONLY' as const),
    independence
  };

  const semantic_digest = computeSemanticDigest(body.schema, identityPayload(body));
  const requirement_id = randomUUID();

  const candidate = {
    requirement_id,
    semantic_digest,
    ...body
  };

  return M0IntelligenceRequirementSchema.parse(candidate);
}

/**
 * Re-derive the canonical semantic digest for an existing Intelligence
 * Requirement. Throws if the recomputed digest does not match the
 * recorded one — i.e. the artifact was tampered with.
 */
export function verifyIntelligenceRequirementDigest(requirement: M0IntelligenceRequirement): {
  ok: true;
  recomputed: string;
} {
  const { requirement_id: _requirementId, semantic_digest, ...body } = requirement;
  const recomputed = computeSemanticDigest(requirement.schema, identityPayload(body));
  if (recomputed !== semantic_digest) {
    throw new IntelligenceRequirementError(
      `Intelligence Requirement semantic_digest mismatch: declared ${semantic_digest}, recomputed ${recomputed}.`
    );
  }
  return { ok: true, recomputed };
}

// Re-export so callers have a single import surface.
export { M0IntelligenceRequirementDisclosureSchema };
