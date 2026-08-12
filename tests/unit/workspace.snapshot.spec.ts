import { describe, it, expect, beforeEach } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import { snapshotRepo, computeWorkspaceStateDigest } from '../../src/index';

describe('workspace snapshot', () => {
  let repoRoot: string;

  beforeEach(async () => {
    repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-snap-'));
    await fs.mkdir(path.join(repoRoot, '.git', 'refs', 'heads'), { recursive: true });
    await fs.writeFile(path.join(repoRoot, '.git', 'HEAD'), 'ref: refs/heads/main\n');
    await fs.writeFile(
      path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
      '1111111111111111111111111111111111111111\n'
    );
    await fs.writeFile(path.join(repoRoot, 'README.md'), '# tmp\n');
  });

  it('produces a deterministic sha256 digest', async () => {
    const a = await snapshotRepo(repoRoot);
    const b = await snapshotRepo(repoRoot);
    expect(a.digest).toBe(b.digest);
    expect(a.digest.startsWith('sha256:')).toBe(true);
  });

  it('digest changes when the input changes', () => {
    const d1 = computeWorkspaceStateDigest({ headCommit: 'aaa', trackedPaths: ['a', 'b'] });
    const d2 = computeWorkspaceStateDigest({ headCommit: 'bbb', trackedPaths: ['a', 'b'] });
    expect(d1).not.toBe(d2);
  });
});
