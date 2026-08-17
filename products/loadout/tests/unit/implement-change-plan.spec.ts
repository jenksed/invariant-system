/**
 * Unit tests for Plan v2 + M0 contract builders (LOADOUT-M0-01).
 */
import { describe, it, expect } from 'vitest';
import {
  computeSemanticDigest,
  buildImplementerRequirement,
  buildReviewerRequirement,
  verifyIntelligenceRequirementDigest,
  buildExecutionBinding,
  executionBindingContextRef,
  verifyExecutionBindingDigest,
  IntelligenceRequirementError,
  ExecutionBindingError,
  type M0ArtifactRef
} from '../../src/index';

const samplePlanRef: M0ArtifactRef = {
  id: 'plan-001',
  digest: 'sha256:' + '0'.repeat(64)
};

describe('computeSemanticDigest (E1)', () => {
  it('produces sha256-prefixed digests that are stable across calls', () => {
    const id = 'engineering-system/intelligence-requirement/m0-v1';
    const payload = { role: 'IMPLEMENTER', plan_ref: samplePlanRef };
    const a = computeSemanticDigest(id, payload);
    const b = computeSemanticDigest(id, payload);
    expect(a).toBe(b);
    expect(a).toMatch(/^sha256:[0-9a-f]{64}$/);
  });

  it('two different schema identifiers never produce the same digest for the same payload', () => {
    const payload = { plan_ref: samplePlanRef };
    const a = computeSemanticDigest('engineering-system/intelligence-requirement/m0-v1', payload);
    const b = computeSemanticDigest('engineering-system/execution-binding/m0-v1', payload);
    expect(a).not.toBe(b);
  });

  it('rejects non-integer floats in identity payloads (IDENTITY-CONSTITUTION)', () => {
    expect(() => computeSemanticDigest('test/v0', { confidence: 0.5 })).toThrow(
      /non-integer float/
    );
  });
});

describe('Intelligence Requirement builder (E3)', () => {
  it('builds a structurally-valid IMPLEMENTER requirement with closed independence', () => {
    const req = buildImplementerRequirement({
      planRef: samplePlanRef,
      implementerCapabilities: ['repo.read', 'repo.write'],
      disclosureClass: 'LOCAL_ONLY'
    });

    expect(req.schema).toBe('engineering-system/intelligence-requirement/m0-v1');
    expect(req.role).toBe('IMPLEMENTER');
    expect(req.task_kind).toBe('SOFTWARE_CHANGE');
    expect(req.independence.must_not_receive_implementer_transcript).toBe(true);
    expect(req.independence.must_use_separate_context_manifest).toBe(true);
    expect(req.required_capabilities).toEqual(['repo.read', 'repo.write']);
    expect(req.semantic_digest).toMatch(/^sha256:[0-9a-f]{64}$/);

    // digest is verifiable
    expect(() => verifyIntelligenceRequirementDigest(req)).not.toThrow();
  });

  it('builds a REVIEWER requirement with must_differ_from_assignment_ref', () => {
    const assignmentRef: M0ArtifactRef = {
      id: 'assignment-impl-001',
      digest: 'sha256:' + 'a'.repeat(64)
    };
    const req = buildReviewerRequirement({
      planRef: samplePlanRef,
      reviewerCapabilities: ['repo.read', 'diff.read'],
      implementerAssignmentRef: assignmentRef,
      disclosureClass: 'LOCAL_ONLY'
    });

    expect(req.role).toBe('REVIEWER');
    expect(req.independence.must_differ_from_assignment_ref).toEqual(assignmentRef);
  });

  it('rejects identity-payload tampering on digest recompute', () => {
    const req = buildImplementerRequirement({
      planRef: samplePlanRef,
      implementerCapabilities: ['repo.read']
    });
    const tampered = {
      ...req,
      required_capabilities: ['repo.read', 'shadow.privilege.escalation']
    };
    expect(() => verifyIntelligenceRequirementDigest(tampered as typeof req)).toThrow(
      IntelligenceRequirementError
    );
  });
});

describe('Execution Binding builder (E4)', () => {
  const profileRef: M0ArtifactRef = { id: 'profile-impl-001', digest: 'sha256:' + '1'.repeat(64) };
  const eligibilityRef: M0ArtifactRef = {
    id: 'eligibility-001',
    digest: 'sha256:' + '2'.repeat(64)
  };
  const disclosureRef: M0ArtifactRef = {
    id: 'disclosure-policy-001',
    digest: 'sha256:' + '3'.repeat(64)
  };
  const patchRef: M0ArtifactRef = { id: 'patch-policy-001', digest: 'sha256:' + '4'.repeat(64) };
  const contractRef: M0ArtifactRef = { id: 'contract-set-001', digest: 'sha256:' + '5'.repeat(64) };
  const requirementRef: M0ArtifactRef = {
    id: 'requirement-impl-001',
    digest: 'sha256:' + '6'.repeat(64)
  };

  it('builds a content-addressed binding whose digest propagates into the context_refs entry', () => {
    const binding = buildExecutionBinding({
      planRef: samplePlanRef,
      requirementRef,
      profileRef,
      eligibilityRef,
      disclosurePolicyRef: disclosureRef,
      patchPolicyRef: patchRef,
      contractSetRef: contractRef
    });
    expect(binding.schema).toBe('engineering-system/execution-binding/m0-v1');
    expect(binding.semantic_digest).toMatch(/^sha256:[0-9a-f]{64}$/);

    const contextRef = executionBindingContextRef(binding);
    expect(contextRef).toBe(
      `artifact:engineering-system/execution-binding/m0-v1:${binding.semantic_digest}`
    );
  });

  it('detects identity-payload tampering on digest recompute', () => {
    const binding = buildExecutionBinding({
      planRef: samplePlanRef,
      requirementRef,
      profileRef,
      eligibilityRef,
      disclosurePolicyRef: disclosureRef,
      patchPolicyRef: patchRef,
      contractSetRef: contractRef
    });
    const tampered = {
      ...binding,
      profile_ref: { id: 'profile-impl-other', digest: 'sha256:' + '9'.repeat(64) }
    };
    expect(() => verifyExecutionBindingDigest(tampered as typeof binding)).toThrow(
      ExecutionBindingError
    );
  });
});
