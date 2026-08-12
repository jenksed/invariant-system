import { describe, it, expect, beforeEach } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import { installPack, removePack, readCatalog, rollbackPack, listCatalog } from '../../src/index';

describe('pack lifecycle', () => {
  let repoRoot: string;
  let packsSource: string;

  beforeEach(async () => {
    repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-pack-'));
    packsSource = path.join(__dirname, '..', '..', 'src', 'packs', 'repository-recon');
  });

  it('installs, lists, removes, and rolls back a pack', async () => {
    const res = await installPack(repoRoot, packsSource);
    expect(res.installedPath).toContain('.loadout/packs/repository-recon');
    const catalog = await readCatalog(repoRoot);
    expect(catalog.find((e) => e.id === 'repository-recon')).toBeTruthy();

    // listCatalog on bundled source still works
    const bundled = await listCatalog(path.join(__dirname, '..', '..', 'src', 'packs'));
    expect(bundled.find((m) => m.id === 'repository-recon')).toBeTruthy();

    await removePack(repoRoot, 'repository-recon');
    const removed = await readCatalog(repoRoot);
    expect(removed.find((e) => e.id === 'repository-recon')).toBeUndefined();

    // rollback reinstates from the bundled source
    await rollbackPack(repoRoot, 'repository-recon');
    const restored = await readCatalog(repoRoot);
    expect(restored.find((e) => e.id === 'repository-recon')).toBeTruthy();
  });
});
