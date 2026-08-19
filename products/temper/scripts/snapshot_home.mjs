#!/usr/bin/env node
/**
 * Snapshot driver — renders the Workbench Alpha Home screen with a
 * fixture WorkbenchProjection and writes the plain-text frame to
 * integration/snapshots/. Used for case-study capture and visual
 * regression in the first vertical slice.
 *
 * Usage:
 *   node scripts/snapshot_home.mjs
 *   node scripts/snapshot_home.mjs --no-session
 *   node scripts/snapshot_home.mjs --orphan
 *   node scripts/snapshot_home.mjs --submit-error
 *
 * Output: integration/snapshots/home-<label>.txt
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = dirname(HERE);
const OUT = join(ROOT, 'integration', 'snapshots');

const { createHomeScreen, setHomeProjection } = await import('../dist/src/screens/home.js');
const { frameToText } = await import('../dist/src/tui/render.js');

const args = new Set(process.argv.slice(2));
const label = args.has('--no-session') ? 'no-session'
  : args.has('--orphan') ? 'orphan'
  : args.has('--submit-error') ? 'submit-error'
  : args.has('--splash') ? 'splash'
  : 'home';

const cols = 100;
const rows = 30;
const ctx = { cols, rows, inputFocused: true };

const baseProjection = {
  repository: '/Users/jenksed/Developer/invariant-system-worktrees/temper-workbench-alpha',
  repositoryName: 'temper-workbench-alpha',
  kilnHome: '/Users/jenksed/Developer/invariant-system-worktrees/temper-workbench-alpha/.kiln',
  sessionId: 'ses_abcdef1234567890',
  canonicalSessionRevision: 47,
  orphaned: false,
  unknowns: [],
  connection: 'connected',
  builtAt: '2026-08-19T12:00:00Z',
  sessionQuery: {
    session_id: 'ses_abcdef1234567890',
    task_id: 'tsk_xyz',
    root_run_id: 'run_root',
    run_state: 'active',
    workflow_step: 'awaiting_operator',
    objective: 'Temper Workbench Alpha — first real TUI screen',
    criteria: ['operator-submitted intent'],
    verification_status: 'PENDING',
    review_status: 'PENDING',
    human_status: 'PENDING',
    unknowns: []
  }
};

let projection;
let submitState = 'idle';
let submitError = '';
let hydrated = true;
if (label === 'splash') {
  projection = null;
  hydrated = false;
} else if (label === 'no-session') {
  projection = {
    repository: baseProjection.repository,
    repositoryName: baseProjection.repositoryName,
    kilnHome: baseProjection.kilnHome,
    sessionId: null,
    canonicalSessionRevision: null,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: baseProjection.builtAt
  };
} else if (label === 'orphan') {
  projection = { ...baseProjection, orphaned: true, unknowns: ['op_unknown_001'] };
} else if (label === 'submit-error') {
  projection = baseProjection;
  submitState = 'error';
  submitError = 'session.start failed: E_SESSION_ALREADY_EXISTS';
} else {
  projection = baseProjection;
}

const home = createHomeScreen({
  onSubmitIntent: async () => ({ ok: true })
});

let state = {
  projection: null,
  input: {
    value: label === 'submit-error' ? '' : 'Fix the reconnect projection so stale activity cannot overwrite canonical state.',
    cursor: 0,
    multiline: true,
    focused: label === 'splash' ? false : true,
    prompt: '> ',
    history: [],
    historyIndex: -1,
    historySaved: '',
    maxChars: 16384
  },
  submitState,
  submitError,
  hydrated
};
if (projection) {
  state = setHomeProjection(state, projection);
}

const text = frameToText(home.view(state, ctx));

mkdirSync(OUT, { recursive: true });
const outPath = join(OUT, `home-${label}.txt`);
writeFileSync(outPath, text + '\n', 'utf8');
process.stdout.write(`snapshot written: ${outPath}\n`);
process.stdout.write('\n--- SNAPSHOT ---\n');
process.stdout.write(text + '\n');
process.stdout.write('--- END ---\n');
