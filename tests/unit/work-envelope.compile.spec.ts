import { describe, it, expect } from 'vitest';
import path from 'node:path';
import { findGoalById, compileWorkEnvelope, resolveCapability } from '../../src/index';

describe('work envelope compile', () => {
  it('produces a v0 envelope from the Goal catalogue and bundled pack', async () => {
    const goal = findGoalById('understand-a-repository')!;
    const cap = await resolveCapability(
      path.join(__dirname, '..', '..', 'src', 'packs', 'repository-recon')
    );
    const envelope = compileWorkEnvelope({
      goal,
      capability: cap,
      projectState: {
        repository: '.',
        baseCommit: 'abc123',
        workspaceStateDigest: 'sha256:deadbeef'
      },
      createdAt: '2026-08-12T00:00:00Z'
    });
    expect(envelope.schema).toBe('engineering-system/work-envelope/v0');
    expect(envelope.capability.id).toBe('repository-recon');
    expect(envelope.capability.contract_version).toBe('0.1.0-fixture');
    expect(envelope.project_state.base_commit).toBe('abc123');
    expect(envelope.project_state.workspace_state_digest).toBe('sha256:deadbeef');
    expect(envelope.goal.title).toBe('Understand this repository');
  });
});
