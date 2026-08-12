import { describe, it, expect, beforeEach } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import {
  findGoalById,
  resolveCapability,
  compileWorkEnvelope,
  snapshotRepo,
  invokeFakeKiln,
  buildResultView,
  loadAndValidateQmr
} from '../../src/index';

describe('fixture substitution', () => {
  let repoRoot: string;
  const fixtureDir = path.join(__dirname, '..', '..', 'fixtures');
  const packsDir = path.join(__dirname, '..', '..', 'src', 'packs');

  beforeEach(async () => {
    repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-sub-'));
    await fs.mkdir(path.join(repoRoot, '.git', 'refs', 'heads'), { recursive: true });
    await fs.writeFile(path.join(repoRoot, '.git', 'HEAD'), 'ref: refs/heads/main\n');
    await fs.writeFile(
      path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
      '2222222222222222222222222222222222222222\n'
    );
  });

  it('keeps capability contract and Result view shape stable across compatible QMR fixtures', async () => {
    const goal = findGoalById('understand-a-repository')!;

    async function runOnce(qmrPath: string) {
      const cap = await resolveCapability(path.join(packsDir, 'repository-recon'));
      cap.skill.qmrFixturePath = qmrPath;
      const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: fixtureDir });
      expect(qmr.qualified_for.outcome).toBe('understand-a-repository');
      const snap = await snapshotRepo(repoRoot);
      const envelope = compileWorkEnvelope({
        goal,
        capability: cap,
        qmr,
        projectState: {
          repository: repoRoot,
          baseCommit: snap.input.headCommit,
          workspaceStateDigest: snap.digest
        },
        createdAt: '2026-08-12T00:00:00Z'
      });
      const result = invokeFakeKiln(envelope);
      const view = buildResultView(result);
      return {
        contractVersion: cap.contract.contract_version,
        envelopeContractVersion: envelope.capability.contract_version,
        envelopeProvenance: envelope.capability.method_provenance,
        view
      };
    }

    const a = await runOnce(path.join(fixtureDir, 'qualified-method-record.v0.yaml'));
    const b = await runOnce(path.join(fixtureDir, 'qualified-method-record.v0.alt.yaml'));

    // Capability contract is identical across A/B.
    expect(a.contractVersion).toBe(b.contractVersion);
    expect(a.envelopeContractVersion).toBe(b.envelopeContractVersion);
    expect(a.view.simulated).toBe(true);
    expect(b.view.simulated).toBe(true);
    // Work Envelope method provenance differs across A/B because the QMR
    // method_id and digest differ.
    expect(a.envelopeProvenance).not.toEqual(b.envelopeProvenance);
  });
});
