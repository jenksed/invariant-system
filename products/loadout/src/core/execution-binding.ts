/**
 * Execution Binding builder for the M0 bounded-change plan.
 *
 * Per the canonical `engineering-system/execution-binding/m0-v1` schema
 * (mirror at `contracts/m0/schemas/execution-binding.m0-v1.schema.json`),
 * the binding is a content-addressed artifact that ties together the
 * Loadout Plan, the M0 Intelligence Requirements, the assigned Profile,
 * the eligibility snapshot, and the disclosure/patch/contract-set
 * policy refs. Kiln reads it as one digest; the binding's
 * `semantic_digest` is part of the Work Envelope's `context_refs`
 * (compiled by `compileWorkEnvelope` for the `implement-change`
 * capability), so any post-creation change to the binding identity
 * propagates into the Work Envelope digest (P02-D015).
 */
import { randomUUID } from 'node:crypto';
import type { M0ArtifactRef, M0ExecutionBinding } from './schemas';
import { M0ExecutionBindingSchema } from './schemas';
import { computeSemanticDigest } from './plan';

export class ExecutionBindingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ExecutionBindingError';
  }
}

export interface BuildExecutionBindingArgs {
  planRef: M0ArtifactRef;
  requirementRef: M0ArtifactRef;
  /** Implementer's current Assignment, if available. Optional. */
  assignmentRef?: M0ArtifactRef;
  profileRef: M0ArtifactRef;
  eligibilityRef: M0ArtifactRef;
  disclosurePolicyRef: M0ArtifactRef;
  patchPolicyRef: M0ArtifactRef;
  contractSetRef: M0ArtifactRef;
}

function identityPayload(args: Omit<M0ExecutionBinding, 'binding_id' | 'semantic_digest'>) {
  return {
    schema: args.schema,
    plan_ref: args.plan_ref,
    requirement_ref: args.requirement_ref,
    assignment_ref: args.assignment_ref,
    profile_ref: args.profile_ref,
    eligibility_ref: args.eligibility_ref,
    disclosure_policy_ref: args.disclosure_policy_ref,
    patch_policy_ref: args.patch_policy_ref,
    contract_set_ref: args.contract_set_ref
  };
}

/**
 * Build a content-addressed Execution Binding. The `binding_id` is a
 * fresh UUID (occur-once); the `semantic_digest` is computed over the
 * canonicalized identity payload. The closed-shape schema rejects
 * any field that would smuggle authority through the binding.
 */
export function buildExecutionBinding(args: BuildExecutionBindingArgs): M0ExecutionBinding {
  const body = {
    schema: 'engineering-system/execution-binding/m0-v1' as const,
    plan_ref: args.planRef,
    requirement_ref: args.requirementRef,
    ...(args.assignmentRef ? { assignment_ref: args.assignmentRef } : {}),
    profile_ref: args.profileRef,
    eligibility_ref: args.eligibilityRef,
    disclosure_policy_ref: args.disclosurePolicyRef,
    patch_policy_ref: args.patchPolicyRef,
    contract_set_ref: args.contractSetRef
  };

  const semantic_digest = computeSemanticDigest(body.schema, identityPayload(body));
  const binding_id = randomUUID();

  return M0ExecutionBindingSchema.parse({
    binding_id,
    semantic_digest,
    ...body
  });
}

/**
 * Build the canonical M0 `context_refs` entry that Loadout embeds in
 * the Work Envelope for `implement-change`. Mirrors the
 * `verify-change` precedent at `src/core/compile.ts:92-94`:
 *   `loadout/verification-change/v0:<digest>`
 * which becomes here:
 *   `artifact:engineering-system/execution-binding/m0-v1:sha256:<digest>`
 */
export function executionBindingContextRef(binding: M0ExecutionBinding): string {
  return `artifact:engineering-system/execution-binding/m0-v1:${binding.semantic_digest}`;
}

/**
 * Re-derive the canonical semantic digest for an existing Execution
 * Binding. Throws if the recomputed digest does not match the recorded
 * one — i.e. the artifact was tampered with.
 */
export function verifyExecutionBindingDigest(binding: M0ExecutionBinding): {
  ok: true;
  recomputed: string;
} {
  const { binding_id: _bindingId, semantic_digest, ...body } = binding;
  const recomputed = computeSemanticDigest(binding.schema, identityPayload(body));
  if (recomputed !== semantic_digest) {
    throw new ExecutionBindingError(
      `Execution Binding semantic_digest mismatch: declared ${semantic_digest}, recomputed ${recomputed}.`
    );
  }
  return { ok: true, recomputed };
}
