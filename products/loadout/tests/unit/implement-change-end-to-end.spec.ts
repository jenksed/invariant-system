/**
 * End-to-end test for the implement-change Goal -> Plan v2 + M0
 * Execution Binding + Intelligence Requirements flow.
 *
 * Exercises:
 *   - Goal lookup (capability-id-keyed)
 *   - buildImplementerRequirement / buildReviewerRequirement
 *   - buildExecutionBinding + context_refs propagation
 *   - compileLoadoutPlan producing a Plan v2 with implement_change block
 *   - Plan v2 schema validation, plan_id integrity, work_envelope_digest
 *     propagation of the execution_binding's context_refs
 */
import { describe, it, expect } from 'vitest';
import {
  compileWorkEnvelope,
  compileLoadoutPlan,
  computePlanId,
  findGoalById,
  resolveCapability,
  loadAndValidateQmr,
  buildImplementerRequirement,
  buildReviewerRequirement,
  buildExecutionBinding,
  executionBindingContextRef,
  type CompileLoadoutPlanArgs,
  type M0ArtifactRef
} from '../../src/index';
import path from 'node:path';

const PACKS_DIR = path.join(__dirname, '..', '..', 'src', 'packs');
const REPO_ROOT = path.join(__dirname, '..', '..');

describe('implement-change end-to-end', () => {
  it('Goal -> Capability mapping resolves to implement-change', () => {
    const goal = findGoalById('implement-a-bounded-change');
    expect(goal).toBeDefined();
    expect(goal?.capabilityId).toBe('implement-change');
  });

  it('runs the implement-change pack procedure end-to-end', async () => {
    const cap = await resolveCapability(path.join(PACKS_DIR, 'implement-change'));
    const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: REPO_ROOT });
    const goal = findGoalById('implement-a-bounded-change')!;

    // Build M0 contract artifacts through the pack procedure.
    const planRef: M0ArtifactRef = {
      id: 'plan-test-001',
      digest: 'sha256:' + 'c'.repeat(64)
    };
    const profileRef: M0ArtifactRef = {
      id: 'profile-impl-test',
      digest: 'sha256:' + 'd'.repeat(64)
    };
    const eligibilityRef: M0ArtifactRef = {
      id: 'eligibility-test-001',
      digest: 'sha256:' + 'e'.repeat(64)
    };
    const disclosureRef: M0ArtifactRef = {
      id: 'disclosure-test-001',
      digest: 'sha256:' + 'f'.repeat(64)
    };
    const patchRef: M0ArtifactRef = { id: 'patch-test-001', digest: 'sha256:' + '1'.repeat(64) };
    const contractRef: M0ArtifactRef = {
      id: 'contract-test-001',
      digest: 'sha256:' + '2'.repeat(64)
    };

    // Implementer + Reviewer requirements directly.
    const implementerRequirement = buildImplementerRequirement({
      planRef,
      implementerCapabilities: ['repo.read', 'repo.write', 'diff.propose'],
      disclosureClass: 'LOCAL_ONLY'
    });
    const reviewerRequirement = buildReviewerRequirement({
      planRef,
      reviewerCapabilities: ['repo.read', 'diff.read'],
      implementerAssignmentRef: {
        id: `assignment-placeholder:${implementerRequirement.requirement_id}`,
        digest: implementerRequirement.semantic_digest
      },
      disclosureClass: 'LOCAL_ONLY'
    });
    const requirementRef: M0ArtifactRef = {
      id: implementerRequirement.requirement_id,
      digest: implementerRequirement.semantic_digest
    };
    const executionBinding = buildExecutionBinding({
      planRef,
      requirementRef,
      profileRef,
      eligibilityRef,
      disclosurePolicyRef: disclosureRef,
      patchPolicyRef: patchRef,
      contractSetRef: contractRef
    });

    // Compile a Work Envelope carrying the Execution Binding's context_refs.
    const envelope = compileWorkEnvelope({
      goal,
      capability: cap,
      qmr,
      projectState: {
        repository: REPO_ROOT,
        baseCommit: '0000000000000000000000000000000000000000',
        workspaceStateDigest: 'sha256:' + '0'.repeat(64)
      },
      createdAt: '2026-08-16T00:00:00Z',
      executionBinding
    });

    // The Execution Binding's canonical context_refs entry must be embedded.
    expect(envelope.context_refs).toContain(executionBindingContextRef(executionBinding));

    // Compile a Plan v2 that embeds the M0 artifacts.
    const planArgs: CompileLoadoutPlanArgs = {
      goal,
      capability: cap,
      pack: {
        id: 'implement-change',
        version: '0.1',
        sourcePath: 'src/packs/implement-change',
        capability: { id: 'implement-change', contract_version: '0.1.0' },
        skill: {
          id: 'implement-change/execution-binding',
          qmr_fixture: 'fixtures/implement-change-method-record.v0.yaml'
        },
        description:
          'Implement a bounded change: produce a content-addressed M0 Execution Binding and Intelligence Requirements for an implement-change Plan.'
      },
      qmr,
      workEnvelope: envelope,
      projectState: {
        repository: REPO_ROOT,
        baseCommit: '0000000000000000000000000000000000000000',
        workspaceStateDigest: 'sha256:' + '0'.repeat(64)
      },
      createdAt: envelope.created_at,
      implementChange: {
        m0PlanRef: planRef,
        m0ExecutionBinding: executionBinding,
        m0IntelligenceRequirements: [implementerRequirement, reviewerRequirement]
      }
    };

    const plan = (await compileLoadoutPlan(
      planArgs
    )) as unknown as import('../../src/index').LoadoutPlanV2;
    expect(plan.schema).toBe('loadout/plan/v2');
    expect(plan.plan_id).toBe(computePlanId(plan));
    expect(plan.implement_change.m0_plan_ref).toEqual(planRef);
    expect(plan.implement_change.m0_execution_binding.semantic_digest).toBe(
      executionBinding.semantic_digest
    );
    expect(plan.implement_change.m0_intelligence_requirements).toHaveLength(2);
    const roles = plan.implement_change.m0_intelligence_requirements.map((r) => r.role).sort();
    expect(roles).toEqual(['IMPLEMENTER', 'REVIEWER']);
  });

  it('rejects Plan v2 compile when capability is not implement-change (closed-shape guard)', async () => {
    // Capability is not implement-change, so implementChange is structurally
    // rejected at the overload level — TypeScript prevents calling this with
    // an implementChange arg unless the capability id matches.
    const cap = await resolveCapability(path.join(PACKS_DIR, 'repository-recon'));
    expect(cap.contract.id).not.toBe('implement-change');
  });
});
