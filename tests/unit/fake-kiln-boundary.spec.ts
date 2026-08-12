/**
 * Fake Kiln boundary: conservative default (deny-all, unsatisfy-all) with
 * explicit per-request / per-obligation simulated decisions.
 *
 * The Work Envelope contract says requests do not grant authority and
 * proof obligations do not claim satisfaction. The default must make that
 * truth visible.
 */
import { describe, it, expect } from 'vitest';
import { invokeFakeKiln } from '../../src/index';
import type { WorkEnvelopeV0 } from '../../src/index';

function makeEnvelope(overrides: Partial<WorkEnvelopeV0> = {}): WorkEnvelopeV0 {
  return {
    schema: 'engineering-system/work-envelope/v0',
    work_id: 'w-test',
    created_at: '2026-08-12T00:00:00Z',
    producer: { product: 'loadout', version: '0.1.0-fixture' },
    goal: { title: 'Understand this repository', success_conditions: [] },
    capability: {
      id: 'repository-recon',
      contract_version: '0.1.0-fixture',
      method_provenance: ['test@0.0.0']
    },
    project_state: {
      repository: '/tmp/repo',
      base_commit: 'abc',
      workspace_state_digest: 'sha256:digest'
    },
    scope: { included: ['tracked files'], excluded: ['mutation'] },
    constraints: { must: [], must_not: [] },
    context_refs: [],
    proof_obligations: [
      { id: 'repo-state-observed', kind: 'evidence', requirement: 'report commit' },
      { id: 'workspace-digest-reported', kind: 'evidence', requirement: 'report digest' }
    ],
    authority_requests: [
      { capability: 'git.read', scope: '/tmp/repo' },
      { capability: 'fs.read', scope: '/tmp/repo' }
    ],
    ...overrides
  };
}

describe('fake Kiln boundary (L2)', () => {
  it('defaults to deny-all authority when no simulated decisions are provided', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env);
    expect(result.authority.requested).toEqual(['git.read', 'fs.read']);
    expect(result.authority.granted).toEqual([]);
    expect(result.authority.denied).toEqual(['git.read', 'fs.read']);
  });

  it('defaults to unsatisfy-all proof obligations when no simulated decisions are provided', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env);
    expect(result.proof_obligations.satisfied).toEqual([]);
    expect(result.proof_obligations.unsatisfied).toEqual([
      'repo-state-observed',
      'workspace-digest-reported'
    ]);
    expect(result.proof_obligations.invalidated).toEqual([]);
  });

  it('still labels the result simulated after the conservative default', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env);
    expect(result.simulated?.simulated).toBe(true);
    expect(result.acceptance_readiness.ready).toBe(false);
  });

  it('honors explicit simulatedAuthorityDecisions per request', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env, {
      simulatedAuthorityDecisions: [
        { capability: 'git.read', decision: 'granted' },
        { capability: 'fs.read', decision: 'denied' }
      ]
    });
    expect(result.authority.granted).toEqual(['git.read']);
    expect(result.authority.denied).toEqual(['fs.read']);
  });

  it('ignores simulatedAuthorityDecisions for unknown capabilities', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env, {
      simulatedAuthorityDecisions: [
        { capability: 'network.shell', decision: 'granted' } // not requested
      ]
    });
    // No unknown capability leaks into either bucket.
    expect(result.authority.granted).toEqual([]);
    expect(result.authority.denied).toEqual(['git.read', 'fs.read']);
  });

  it('honors explicit simulatedProofDecisions per obligation', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env, {
      simulatedProofDecisions: [
        { obligationId: 'repo-state-observed', decision: 'satisfied' },
        { obligationId: 'workspace-digest-reported', decision: 'invalidated' }
      ]
    });
    expect(result.proof_obligations.satisfied).toEqual(['repo-state-observed']);
    expect(result.proof_obligations.invalidated).toEqual(['workspace-digest-reported']);
    expect(result.proof_obligations.unsatisfied).toEqual([]);
  });

  it('ignores simulatedProofDecisions for unknown obligations', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env, {
      simulatedProofDecisions: [{ obligationId: 'no-such-obligation', decision: 'satisfied' }]
    });
    // Nothing leaks into satisfied.
    expect(result.proof_obligations.satisfied).toEqual([]);
    expect(result.proof_obligations.unsatisfied).toEqual([
      'repo-state-observed',
      'workspace-digest-reported'
    ]);
  });

  it('evidence is still kind=simulated and acceptance_readiness.ready is still false', () => {
    const env = makeEnvelope();
    const result = invokeFakeKiln(env, {
      simulatedAuthorityDecisions: [{ capability: 'git.read', decision: 'granted' }],
      simulatedProofDecisions: [{ obligationId: 'repo-state-observed', decision: 'satisfied' }]
    });
    expect(result.evidence.every((e) => e.kind === 'simulated')).toBe(true);
    expect(result.acceptance_readiness.ready).toBe(false);
  });
});
