/**
 * Producer-side planning procedure for the `implement-change` capability.
 *
 * Produces a content-addressed M0 Execution Binding and the two
 * M0 Intelligence Requirements (IMPLEMENTER, REVIEWER). Kiln does NOT
 * import or invoke this module; it consumes the frozen artifacts
 * over the Work Envelope's context_refs.
 */
import type { M0ArtifactRef } from '../../core/schemas';
import { buildExecutionBinding } from '../../core/execution-binding';
import {
  buildImplementerRequirement,
  buildReviewerRequirement
} from '../../core/intelligence-requirement';

export interface ImplementChangeArgs {
  planRef: M0ArtifactRef;
  profileRef: M0ArtifactRef;
  eligibilityRef: M0ArtifactRef;
  disclosurePolicyRef: M0ArtifactRef;
  patchPolicyRef: M0ArtifactRef;
  contractSetRef: M0ArtifactRef;
  implementerCapabilities: string[];
  reviewerCapabilities: string[];
}

export interface ImplementChangeArtifacts {
  executionBinding: ReturnType<typeof buildExecutionBinding>;
  intelligenceRequirements: ReturnType<
    typeof buildImplementerRequirement | typeof buildReviewerRequirement
  >[];
}

/**
 * Build the closed artifacts that the implement-change Plan embeds:
 *   - one Execution Binding (engineering-system/execution-binding/m0-v1)
 *   - one Implementer Intelligence Requirement (IMPLEMENTER role)
 *   - one Reviewer Intelligence Requirement (REVIEWER role, with
 *     must_differ_from_assignment_ref asserting self-review is closed)
 *
 * The Implementer's Assignment (when later produced by Manifold) is
 * necessarily a different artifact from the Reviewer's requirement;
 * the closed-schema enforcement makes the self-review path
 * unrepresentable.
 */
export function runImplementChange(args: ImplementChangeArgs): ImplementChangeArtifacts {
  const implementerRequirement = buildImplementerRequirement({
    planRef: args.planRef,
    implementerCapabilities: args.implementerCapabilities,
    disclosureClass: 'LOCAL_ONLY'
  });

  // Placeholder assignment ref. Manifold (M7) produces the real
  // Assignment; until then we use a placeholder ArtifactRef keyed
  // off the implementer requirement id with a synthetic digest.
  // The closed schema enforces that the Reviewer's
  // must_differ_from_assignment_ref is a distinct artifact_ref —
  // a self-reference is structurally rejected.
  const placeholderAssignmentRef: M0ArtifactRef = {
    id: `assignment-placeholder:${implementerRequirement.requirement_id}`,
    digest: implementerRequirement.semantic_digest
  };

  const reviewerRequirement = buildReviewerRequirement({
    planRef: args.planRef,
    reviewerCapabilities: args.reviewerCapabilities,
    implementerAssignmentRef: placeholderAssignmentRef,
    disclosureClass: 'LOCAL_ONLY'
  });

  // The Execution Binding's requirement_ref is a content reference
  // (id + digest) to the Implementer's requirement artifact, not the
  // full requirement struct.
  const requirementRef: M0ArtifactRef = {
    id: implementerRequirement.requirement_id,
    digest: implementerRequirement.semantic_digest
  };

  const executionBinding = buildExecutionBinding({
    planRef: args.planRef,
    requirementRef,
    profileRef: args.profileRef,
    eligibilityRef: args.eligibilityRef,
    disclosurePolicyRef: args.disclosurePolicyRef,
    patchPolicyRef: args.patchPolicyRef,
    contractSetRef: args.contractSetRef
  });

  return {
    executionBinding,
    intelligenceRequirements: [implementerRequirement, reviewerRequirement]
  };
}
