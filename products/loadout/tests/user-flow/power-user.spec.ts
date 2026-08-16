import { describe, it, expect, beforeEach } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import {
  installPack,
  listCatalog,
  readCatalog,
  resolveCapability,
  loadQmrFixture,
  findGoalById,
  compileWorkEnvelope,
  snapshotRepo,
  invokeFakeKiln,
  buildResultView,
  removePack,
  rollbackPack,
  loadAndValidateQmr
} from '../../src/index';

describe('power-user flow', () => {
  let repoRoot: string;
  const fixtureDir = path.join(__dirname, '..', '..', 'fixtures');
  const packsDir = path.join(__dirname, '..', '..', 'src', 'packs');

  beforeEach(async () => {
    repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-power-'));
    await fs.mkdir(path.join(repoRoot, '.git', 'refs', 'heads'), { recursive: true });
    await fs.writeFile(path.join(repoRoot, '.git', 'HEAD'), 'ref: refs/heads/main\n');
    await fs.writeFile(
      path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
      'feed0000000000000000000000000000000000\n'
    );
  });

  it('catalog -> install -> inspect -> swap -> run -> remove -> rollback', async () => {
    // catalog
    const bundled = await listCatalog(packsDir);
    expect(bundled.map((m) => m.id)).toContain('repository-recon');

    // install
    await installPack(repoRoot, path.join(packsDir, 'repository-recon'));
    const catalogAfter = await readCatalog(repoRoot);
    expect(catalogAfter.find((e) => e.id === 'repository-recon')).toBeTruthy();

    // inspect
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
    const originalFixture = path.join(fixtureDir, 'qualified-method-record.v0.yaml');
    const originalQmr = await loadQmrFixture(originalFixture, fixtureDir);
    expect(originalQmr.qualified_for.outcome).toBe('understand-a-repository');

    // swap (in-memory; persistent swap is done via the loadout CLI skill.json writer)
    const altFixturePath = path.join(fixtureDir, 'qualified-method-record.v0.alt.yaml');
    cap.skill.qmrFixturePath = altFixturePath;
    const swappedQmr = await loadQmrFixture(cap.skill.qmrFixturePath, fixtureDir);
    expect(swappedQmr.method_id).toBe('repository-recon/alternate-fixture-method');
    expect(cap.contract.contract_version).toBe('0.1.0-fixture');

    // run
    const goal = findGoalById('understand-a-repository')!;
    const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: fixtureDir });
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
    const view = buildResultView(invokeFakeKiln(envelope));
    expect(view.simulated).toBe(true);

    // remove
    await removePack(repoRoot, 'repository-recon');
    expect((await readCatalog(repoRoot)).find((e) => e.id === 'repository-recon')).toBeUndefined();

    // rollback
    await rollbackPack(repoRoot, 'repository-recon');
    expect((await readCatalog(repoRoot)).find((e) => e.id === 'repository-recon')).toBeTruthy();
  });
});
