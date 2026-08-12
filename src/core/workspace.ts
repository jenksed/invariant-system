/**
 * Workspace = .loadout/ directory inside the target repository.
 *
 * Loadout owns Workspace. The workspace persists:
 *  - pack installs (with provenance)
 *  - run history
 *  - install snapshots for rollback
 *
 * A workspace is reversible: removing the .loadout/ directory is the
 * documented uninstall path.
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';

export const WORKSPACE_DIRNAME = '.loadout';

export interface WorkspacePaths {
  root: string;
  packs: string;
  catalog: string;
  runs: string;
  snapshots: string;
}

export function workspacePaths(repoRoot: string): WorkspacePaths {
  const root = path.join(repoRoot, WORKSPACE_DIRNAME);
  return {
    root,
    packs: path.join(root, 'packs'),
    catalog: path.join(root, 'catalog.json'),
    runs: path.join(root, 'runs'),
    snapshots: path.join(root, 'snapshots')
  };
}

export async function ensureWorkspace(repoRoot: string): Promise<WorkspacePaths> {
  const paths = workspacePaths(repoRoot);
  await fs.mkdir(paths.packs, { recursive: true });
  await fs.mkdir(paths.runs, { recursive: true });
  await fs.mkdir(paths.snapshots, { recursive: true });
  return paths;
}

export async function workspaceExists(repoRoot: string): Promise<boolean> {
  try {
    const stat = await fs.stat(path.join(repoRoot, WORKSPACE_DIRNAME));
    return stat.isDirectory();
  } catch {
    return false;
  }
}
