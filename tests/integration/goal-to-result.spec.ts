import { describe, it, expect } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import {
  installPack,
  findGoalById,
  resolveCapability,
  compileWorkEnvelope,
  snapshotRepo,
  invokeFakeKiln,
  buildResultView,
  loadAndValidateQmr
} from '../../src/index';

describe('goal-to-result pipeline', () => {
  it('runs end-to-end against a tmp repo and emits a simulated Result view', async () => {
    const repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-e2e-'));
    // create a fake .git/HEAD so snapshotRepo can read it
    await fs.mkdir(path.join(repoRoot, '.git'), { recursive: true });
    await fs.writeFile(path.join(repoRoot, '.git', 'HEAD'), 'ref: refs/heads/main\n');
    await fs
      .writeFile(path.join(repoRoot, '.git', 'refs', '..', '..'), '', { flag: 'w' })
      .catch(() => {});
    await fs.mkdir(path.join(repoRoot, '.git', 'refs', 'heads'), { recursive: true });
    await fs.writeFile(
      path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n'
    );
    await fs.writeFile(path.join(repoRoot, 'README.md'), '# tmp\n');

    await installPack(
      repoRoot,
      path.join(__dirname, '..', '..', 'src', 'packs', 'repository-recon')
    );

    const goal = findGoalById('understand-a-repository')!;
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
    // The QMR fixture is a Loadout-bundled v0 fixture. Resolve it against
    // the Loadout installation, not the target repo.
    const loadoutRoot = path.join(__dirname, '..', '..');
    const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: loadoutRoot });
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

    expect(envelope.capability.id).toBe('repository-recon');
    expect(view.simulated).toBe(true);
    expect(view.evidence.every((e) => e.kind === 'simulated')).toBe(true);
    expect(view.acceptanceReadiness.ready).toBe(false);
  });
});
