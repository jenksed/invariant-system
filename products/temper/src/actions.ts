/**
 * Temper M10 — Delegated action surface.
 *
 * Operator actions (approve patch / reject / accept / revise) are thin
 * delegations to the owning Kiln CLI command. Temper never holds
 * decision authority; the action surface constructs the exact argv,
 * invokes the owning command via execFileSync, then RE-READS durable
 * artifacts and re-renders. A failed owning command leaves the
 * projection unchanged and surfaces the failure.
 *
 * Boundary doctrine (P02-D017):
 *   - No sibling-source imports. The actions module knows the
 *     canonical Kiln command contract, not Kiln internals.
 *   - No free-form shell. All invocations use execFileSync with an
 *     explicit argv constructed from artifact refs.
 *   - No Temper state mutation. The action returns a typed result;
 *     the caller re-loads the projection.
 */

import { execFileSync } from 'node:child_process';
import path from 'node:path';
import type { ArtifactRef } from './types.js';

export type DelegatedActionKind =
  | 'patch-decide-approve'
  | 'patch-decide-reject'
  | 'patch-decide-revise'
  | 'human-decide-accept'
  | 'human-decide-reject'
  | 'human-decide-revise';

export interface DelegatedActionRequest {
  kind: DelegatedActionKind;
  planRef: ArtifactRef;
  patchRef: ArtifactRef;
  resultStateDigest: string;
  reviewRef?: ArtifactRef;
}

export interface DelegatedActionResult {
  kind: DelegatedActionKind;
  command: string;
  argv: string[];
  exitCode: number;
  stdout: string;
  stderr: string;
  /** Path to the canonical artifact the owning command wrote. */
  outputPath?: string;
}

export interface DelegatedActionError {
  kind: DelegatedActionKind;
  command: string;
  argv: string[];
  message: string;
}

const KILN_BIN = 'mix';

/**
 * Construct the exact argv for a delegated Kiln action. The argv is
 * built from artifact refs and the bounded result-state digest; no
 * free-form shell.
 */
export function buildArgv(
  req: DelegatedActionRequest,
  outPath: string
): { command: string; argv: string[] } {
  if (req.kind === 'patch-decide-approve') {
    return {
      command: 'kiln patch-decide',
      argv: [
        'patch-decide',
        '--proposal',
        req.patchRef.id,
        '--base-state-digest',
        req.resultStateDigest,
        '--decision',
        'approve',
        '--out',
        outPath
      ]
    };
  }
  if (req.kind === 'patch-decide-reject') {
    return {
      command: 'kiln patch-decide',
      argv: [
        'patch-decide',
        '--proposal',
        req.patchRef.id,
        '--base-state-digest',
        req.resultStateDigest,
        '--decision',
        'reject',
        '--out',
        outPath
      ]
    };
  }
  if (req.kind === 'patch-decide-revise') {
    return {
      command: 'kiln patch-decide',
      argv: [
        'patch-decide',
        '--proposal',
        req.patchRef.id,
        '--base-state-digest',
        req.resultStateDigest,
        '--decision',
        'revise',
        '--out',
        outPath
      ]
    };
  }
  if (req.kind === 'human-decide-accept') {
    return {
      command: 'kiln human-decide',
      argv: [
        'human-decide',
        '--plan',
        req.planRef.id,
        '--patch',
        req.patchRef.id,
        '--result-state-digest',
        req.resultStateDigest,
        '--review',
        req.reviewRef?.id ?? '',
        '--decision',
        'accept',
        '--out',
        outPath
      ]
    };
  }
  if (req.kind === 'human-decide-reject') {
    return {
      command: 'kiln human-decide',
      argv: [
        'human-decide',
        '--plan',
        req.planRef.id,
        '--patch',
        req.patchRef.id,
        '--result-state-digest',
        req.resultStateDigest,
        '--review',
        req.reviewRef?.id ?? '',
        '--decision',
        'reject',
        '--out',
        outPath
      ]
    };
  }
  // human-decide-revise
  return {
    command: 'kiln human-decide',
    argv: [
      'human-decide',
      '--plan',
      req.planRef.id,
      '--patch',
      req.patchRef.id,
      '--result-state-digest',
      req.resultStateDigest,
      '--review',
      req.reviewRef?.id ?? '',
      '--decision',
      'request-revision',
      '--out',
      outPath
    ]
  };
}

/**
 * Execute a delegated action. The owning Kiln command runs as a child
 * process; its stdout/stderr/exit code are surfaced. After exit, the
 * caller re-loads the projection from disk; the projection is never
 * mutated by this function.
 */
export function runAction(
  request: DelegatedActionRequest,
  options: { cwd: string; outPath: string }
): DelegatedActionResult | DelegatedActionError {
  const { command, argv } = buildArgv(request, options.outPath);

  // Validate argv: every element must be a non-empty string with no
  // shell metacharacters. This is a paranoid defense-in-depth check
  // on top of execFileSync (which already does NOT use a shell).
  for (const arg of argv) {
    if (typeof arg !== 'string' || arg.length === 0) {
      return {
        kind: request.kind,
        command,
        argv,
        message: `refused to invoke: argv element is empty or non-string`
      };
    }
    if (/[;&|`$<>\n\r]/.test(arg)) {
      return {
        kind: request.kind,
        command,
        argv,
        message: `refused to invoke: argv element contains shell metacharacter: ${JSON.stringify(arg)}`
      };
    }
  }

  try {
    const stdout = execFileSync(KILN_BIN, argv, {
      cwd: options.cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe']
    });
    return {
      kind: request.kind,
      command,
      argv,
      exitCode: 0,
      stdout,
      stderr: '',
      outputPath: options.outPath
    };
  } catch (error) {
    const e = error as {
      status?: number;
      stdout?: Buffer | string;
      stderr?: Buffer | string;
      message: string;
    };
    return {
      kind: request.kind,
      command,
      argv,
      message: e.message
    };
  }
}

/**
 * Build a deterministic output path under the repository's `.loadout/`
 * scratch dir. Temper writes nothing; the owning Kiln command writes
 * here on success.
 */
export function defaultOutputPath(
  repository: string,
  kind: DelegatedActionKind
): string {
  return path.join(
    repository,
    '.loadout',
    'actions',
    `${kind}-${Date.now()}.json`
  );
}
