/**
 * Pack lifecycle.
 *
 * install/inspect/run/remove/rollback for one narrow software-engineering
 * pack. The pack owns its capability.json + skill.json + run.ts; Loadout
 * owns the lifecycle and the workspace snapshots for rollback.
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { ensureWorkspace, workspacePaths } from './workspace';

export interface PackManifest {
  id: string;
  version: string;
  sourcePath: string;
  capability: { id: string; contract_version: string };
  skill: { id: string; qmr_fixture: string };
  description: string;
}

export async function readPackManifest(packRoot: string): Promise<PackManifest> {
  const raw = await fs.readFile(path.join(packRoot, 'pack.json'), 'utf8');
  const obj = JSON.parse(raw) as PackManifest;
  if (!obj.id || !obj.version || !obj.capability || !obj.skill) {
    throw new Error(`Invalid pack manifest at ${packRoot}`);
  }
  return obj;
}

export async function listCatalog(sourceDir: string): Promise<PackManifest[]> {
  const entries = await fs.readdir(sourceDir, { withFileTypes: true });
  const manifests: PackManifest[] = [];
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const packRoot = path.join(sourceDir, entry.name);
    try {
      manifests.push(await readPackManifest(packRoot));
    } catch {
      // skip malformed packs
    }
  }
  return manifests;
}

export interface InstallResult {
  installedPath: string;
  snapshotPath: string;
}

export async function installPack(
  repoRoot: string,
  packSourcePath: string
): Promise<InstallResult> {
  const manifest = await readPackManifest(packSourcePath);
  const ws = await ensureWorkspace(repoRoot);
  const target = path.join(ws.packs, manifest.id);
  await fs.cp(packSourcePath, target, { recursive: true });

  // Take a pre-install snapshot (the previous contents of .loadout, if any).
  const snapshotPath = path.join(ws.snapshots, `${manifest.id}.pre.json`);
  await fs.writeFile(
    snapshotPath,
    JSON.stringify({ id: manifest.id, removed: false, ts: new Date().toISOString() }, null, 2)
  );

  await writeCatalog(repoRoot, await readCatalog(repoRoot).then((c) => upsertCatalog(c, manifest)));
  return { installedPath: target, snapshotPath };
}

export interface CatalogEntry {
  id: string;
  version: string;
  installed_path: string;
  capability: { id: string; contract_version: string };
}

export async function readCatalog(repoRoot: string): Promise<CatalogEntry[]> {
  const ws = workspacePaths(repoRoot);
  try {
    const raw = await fs.readFile(ws.catalog, 'utf8');
    return JSON.parse(raw) as CatalogEntry[];
  } catch {
    return [];
  }
}

export async function writeCatalog(repoRoot: string, entries: CatalogEntry[]): Promise<void> {
  const ws = workspacePaths(repoRoot);
  await ensureWorkspace(repoRoot);
  await fs.writeFile(ws.catalog, JSON.stringify(entries, null, 2));
}

export function upsertCatalog(entries: CatalogEntry[], manifest: PackManifest): CatalogEntry[] {
  const next = entries.filter((e) => e.id !== manifest.id);
  next.push({
    id: manifest.id,
    version: manifest.version,
    installed_path: path.join('.loadout', 'packs', manifest.id),
    capability: manifest.capability
  });
  return next;
}

export async function removePack(repoRoot: string, packId: string): Promise<void> {
  const ws = workspacePaths(repoRoot);
  await fs.rm(path.join(ws.packs, packId), { recursive: true, force: true });
  const catalog = await readCatalog(repoRoot);
  await writeCatalog(
    repoRoot,
    catalog.filter((e) => e.id !== packId)
  );
}

export async function rollbackPack(repoRoot: string, packId: string): Promise<void> {
  // Trivial rollback: if the snapshot file exists, the pack was previously
  // installed and we can re-copy from the source under src/packs/<id>.
  const ws = workspacePaths(repoRoot);
  const snapshotPath = path.join(ws.snapshots, `${packId}.pre.json`);
  try {
    await fs.stat(snapshotPath);
  } catch {
    throw new Error(`No rollback snapshot for pack ${packId}`);
  }
  // Reinstall from the bundled source under src/packs/.
  const sourceRoot = path.resolve(__dirname, '..', 'packs', packId);
  await installPack(repoRoot, sourceRoot);
}
