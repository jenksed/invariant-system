/**
 * workspace_state_digest = sha256 of (HEAD commit || sorted tracked paths).
 *
 * This is a SIMULATED state digest. It does not use git plumbing; it just
 * hashes the inputs it was given. The point is to bind a request to
 * observable state without claiming canonical authority.
 */
import { createHash } from 'node:crypto';
import { promises as fs } from 'node:fs';
import path from 'node:path';

export interface SnapshotInput {
  headCommit: string;
  trackedPaths: string[];
}

export async function readHeadCommit(repoRoot: string): Promise<string> {
  const headPath = path.join(repoRoot, '.git', 'HEAD');
  const contents = await fs.readFile(headPath, 'utf8');
  const trimmed = contents.trim();
  if (trimmed.startsWith('ref: ')) {
    const ref = trimmed.slice('ref: '.length);
    const refPath = path.join(repoRoot, '.git', ref);
    try {
      const refContents = await fs.readFile(refPath, 'utf8');
      return refContents.trim();
    } catch {
      // Detached HEAD or freshly initialized; fall back to the literal ref string.
      return `detached:${ref}`;
    }
  }
  return trimmed;
}

export async function listTrackedFiles(repoRoot: string): Promise<string[]> {
  // We do not shell out to git to keep this deterministic across hosts and
  // to make it obvious this is a simulated snapshot, not git plumbing.
  //
  // The .loadout/ directory is Loadout's internal workspace (packs, plans,
  // run history, snapshots, catalog). It is NOT part of the user's
  // project state. Excluding it ensures the workspace_state_digest
  // remains stable across Loadout-internal operations (writing a plan
  // file, recording a run, etc.) and is bound only to the user's repo.
  const out: string[] = [];
  async function walk(dir: string): Promise<void> {
    let entries;
    try {
      entries = await fs.readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      if (
        entry.name === '.git' ||
        entry.name === '.loadout' ||
        entry.name === 'node_modules' ||
        entry.name === 'dist'
      ) {
        continue;
      }
      const full = path.join(dir, entry.name);
      const rel = path.relative(repoRoot, full);
      if (entry.isDirectory()) {
        await walk(full);
      } else if (entry.isFile()) {
        out.push(rel.split(path.sep).join('/'));
      }
    }
  }
  await walk(repoRoot);
  out.sort();
  return out;
}

export function computeWorkspaceStateDigest(input: SnapshotInput): string {
  const lines = [input.headCommit, ...input.trackedPaths].join('\n');
  return 'sha256:' + createHash('sha256').update(lines).digest('hex');
}

export async function snapshotRepo(
  repoRoot: string
): Promise<{ digest: string; input: SnapshotInput }> {
  const headCommit = await readHeadCommit(repoRoot);
  const trackedPaths = await listTrackedFiles(repoRoot);
  const input: SnapshotInput = { headCommit, trackedPaths };
  const digest = computeWorkspaceStateDigest(input);
  return { digest, input };
}
