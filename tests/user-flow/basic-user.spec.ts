import { describe, it, expect, beforeEach } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import {
  installPack,
  findGoalByTitle,
  resolveCapability,
  compileWorkEnvelope,
  snapshotRepo,
  invokeFakeKiln,
  buildResultView,
  formatResultViewText,
  loadAndValidateQmr
} from '../../src/index';

/**
 * The basic-user flow is: open the page, click Run, see a Result view.
 * We exercise the same core pipeline that the page's POST /run calls
 * without binding a port (sandboxed CI may not allow listening).
 */
describe('basic-user flow', () => {
  let repoRoot: string;

  beforeEach(async () => {
    repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-basic-'));
    await fs.mkdir(path.join(repoRoot, '.git', 'refs', 'heads'), { recursive: true });
    await fs.writeFile(path.join(repoRoot, '.git', 'HEAD'), 'ref: refs/heads/main\n');
    await fs.writeFile(
      path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
      'cafe0000000000000000000000000000000000\n'
    );
    await installPack(
      repoRoot,
      path.join(__dirname, '..', '..', 'src', 'packs', 'repository-recon')
    );
  });

  it('returns a SIMULATED Result view via the basic-user pipeline', async () => {
    const goal = findGoalByTitle('Understand this repository')!;
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
    const text = formatResultViewText(view);

    expect(view.simulated).toBe(true);
    expect(view.evidence.every((e) => e.kind === 'simulated')).toBe(true);
    expect(text).toContain('SIMULATED');
    expect(text).toContain('simulated run cannot establish real acceptance readiness');
  });
});
