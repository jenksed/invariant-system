/**
 * Deterministic local recon procedure.
 *
 * This is a SKILL. It can be swapped for another compatible skill without
 * changing the Capability contract. It performs no mutation, executes no
 * effect driver, and emits no claims beyond what the fake Kiln boundary
 * later presents.
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';

export interface ReconSummary {
  repository: string;
  headCommit: string;
  trackedFiles: number;
  hasReadme: boolean;
  hasDocs: boolean;
  notes: string[];
}

export async function runRepositoryRecon(repoRoot: string): Promise<ReconSummary> {
  const headPath = path.join(repoRoot, '.git', 'HEAD');
  let headCommit = '(no HEAD)';
  try {
    const raw = await fs.readFile(headPath, 'utf8');
    const trimmed = raw.trim();
    if (trimmed.startsWith('ref: ')) {
      const ref = trimmed.slice('ref: '.length);
      try {
        headCommit = (await fs.readFile(path.join(repoRoot, '.git', ref), 'utf8')).trim();
      } catch {
        headCommit = `detached:${ref}`;
      }
    } else {
      headCommit = trimmed;
    }
  } catch {
    headCommit = '(no HEAD)';
  }

  let trackedFiles = 0;
  let hasReadme = false;
  let hasDocs = false;

  async function walk(dir: string): Promise<void> {
    let entries;
    try {
      entries = await fs.readdir(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      if (entry.name === '.git' || entry.name === 'node_modules' || entry.name === 'dist') continue;
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name.toLowerCase() === 'docs') hasDocs = true;
        await walk(full);
      } else if (entry.isFile()) {
        trackedFiles++;
        if (/^readme(\.md)?$/i.test(entry.name)) hasReadme = true;
      }
    }
  }
  await walk(repoRoot);

  const notes = [
    `Repository root: ${repoRoot}`,
    `Head commit:     ${headCommit}`,
    `Tracked files:   ${trackedFiles}`,
    `Has README:      ${hasReadme}`,
    `Has docs/:       ${hasDocs}`,
    'This summary is produced by the deterministic local recon procedure; it is INPUT to the fake Kiln boundary, not a Kiln record.'
  ];

  return { repository: repoRoot, headCommit, trackedFiles, hasReadme, hasDocs, notes };
}
