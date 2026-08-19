#!/usr/bin/env node
/**
 * Snapshot driver — renders the Workbench Alpha Active Work screen
 * with three real-Kiln panels: Pulse (left), Motion (right top),
 * Frontier + Attention (right bottom).
 *
 * Usage:
 *   node scripts/snapshot_work.mjs                       # empty
 *   node scripts/snapshot_work.mjs --with-motion         # motion deltas
 *   node scripts/snapshot_work.mjs --with-pulse          # activity stream
 *   node scripts/snapshot_work.mjs --full                # both + attention
 *   node scripts/snapshot_work.mjs --disconnected        # N1: DISCONNECTED banner
 *   node scripts/snapshot_work.mjs --reconnecting         # N1: RECONNECTING banner
 *   node scripts/snapshot_work.mjs --since-you-left       # N1: SINCE YOU LEFT feed
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = dirname(HERE);
const OUT = join(ROOT, 'integration', 'snapshots');

const {
  createWorkScreen,
  appendWorkMotion,
  appendWorkPulse,
  setWorkProjection,
  markWorkDisconnect,
  markWorkReconnect
} = await import('../dist/src/screens/work.js');
const { frameToText } = await import('../dist/src/tui/render.js');

const args = new Set(process.argv.slice(2));
const label = args.has('--with-motion') ? 'work-with-motion'
  : args.has('--with-pulse') ? 'work-with-pulse'
  : args.has('--full') ? 'work-full'
  : args.has('--disconnected') ? 'work-disconnected'
  : args.has('--reconnecting') ? 'work-reconnecting'
  : args.has('--since-you-left') ? 'work-since-you-left'
  : 'work-empty';

const cols = 120;
const rows = 32;
const ctx = { cols, rows, inputFocused: false };

let connectionState = 'connected';
let canonicalSessionRevision = 51;
let verificationStatus = label === 'work-full' || label === 'work-since-you-left' ? 'PASS' : 'PENDING';
let humanStatus = 'PENDING';
let showPendingDecision = label === 'work-full' || label === 'work-since-you-left';

if (label === 'work-disconnected' || label === 'work-reconnecting') {
  connectionState = label === 'work-disconnected' ? 'disconnected' : 'reconnecting';
  canonicalSessionRevision = 47;
  verificationStatus = 'PENDING';
  showPendingDecision = false;
}

const projection = {
  repository: '/Users/jenksed/Developer/invariant-system-worktrees/temper-workbench-alpha',
  repositoryName: 'temper-workbench-alpha',
  kilnHome: '/Users/jenksed/Developer/invariant-system-worktrees/temper-workbench-alpha/.kiln',
  sessionId: 'ses_abcdef1234567890',
  canonicalSessionRevision,
  orphaned: false,
  unknowns: [],
  connection: connectionState,
  builtAt: '2026-08-19T12:05:00Z',
  sessionQuery: {
    session_id: 'ses_abcdef1234567890',
    task_id: 'tsk_xyz',
    root_run_id: 'run_root',
    run_state: 'active',
    workflow_step: 'awaiting_operator',
    objective: 'Fix reconnect projection so stale activity cannot overwrite canonical state.',
    criteria: ['operator-submitted intent'],
    verification_status: verificationStatus,
    review_status: 'PENDING',
    human_status: humanStatus,
    unknowns: [],
    pending_decision: showPendingDecision
      ? { kind: 'human_decision_required', message: 'A canonical human decision is required.' }
      : undefined
  }
};

const intent = 'Fix the reconnect projection so stale activity cannot overwrite canonical state.';

const work = createWorkScreen({
  intent,
  onExit: () => {}
});

let state = {
  projection: null,
  pulse: [],
  motion: [],
  lastReconnectAt: null,
  disconnectedAt: null
};
state = setWorkProjection(state, projection);

if (label === 'work-with-motion' || label === 'work-full') {
  // Build a small canonical-delta timeline against the same projection.
  const baseTime = new Date('2026-08-19T12:00:00Z').getTime();
  const deltas = [
    { offset: 0, kind: 'run_state_changed', field: 'run_state', from: 'pending', to: 'active', label: 'run state changed' },
    { offset: 30, kind: 'verification_changed', field: 'verification_status', from: 'PENDING', to: 'PASS', label: 'verification result recorded' },
    { offset: 60, kind: 'review_changed', field: 'review_status', from: '—', to: 'APPROVE', label: 'review verdict recorded' }
  ];
  for (const d of deltas) {
    state = appendWorkMotion(state, {
      id: deltas.indexOf(d) + 1,
      kind: d.kind,
      detectedAt: new Date(baseTime + d.offset * 1000).toISOString(),
      field: d.field,
      from: d.from,
      to: d.to,
      label: d.label
    });
  }
}

if (label === 'work-with-pulse' || label === 'work-full') {
  const baseTime = new Date('2026-08-19T12:00:00Z').getTime();
  const pulses = [
    { offset: 5, kind: 'session', id: 'ses_abcdef1234567890', rev: 47 },
    { offset: 25, kind: 'run', id: 'run_root_001', rev: 49 },
    { offset: 55, kind: 'operation', id: 'opn_test_run', rev: 50 }
  ];
  for (let i = 0; i < pulses.length; i += 1) {
    const p = pulses[i];
    state = appendWorkPulse(state, {
      id: i + 1,
      receivedAt: new Date(baseTime + p.offset * 1000).toISOString(),
      subjectKind: p.kind,
      subjectId: p.id,
      revision: p.rev,
      canonicalSessionRevision: p.rev,
      line: `Kiln state changed · ${p.kind}:${p.id.slice(0, 6)}…${p.id.slice(-4)} · rev ${p.rev} → canonical ${p.rev}`
    });
  }
}

// N1: disconnect/reconnect snapshots
if (label === 'work-disconnected' || label === 'work-reconnecting') {
  // Disconnect happened 15s ago.
  state = markWorkDisconnect(state, new Date(Date.now() - 15_000).toISOString());
}

if (label === 'work-since-you-left') {
  // Disconnect then reconnect 3s ago; motion events arrived during
  // the disconnect window.
  const now = Date.now();
  state = markWorkDisconnect(state, new Date(now - 15_000).toISOString());
  state = markWorkReconnect(state, new Date(now - 3_000).toISOString());
  state = appendWorkMotion(state, {
    id: 100,
    kind: 'verification_changed',
    detectedAt: new Date(now - 2_500).toISOString(),
    field: 'verification_status',
    from: 'PENDING',
    to: 'PASS',
    label: 'verification result recorded'
  });
  state = appendWorkMotion(state, {
    id: 101,
    kind: 'human_status_changed',
    detectedAt: new Date(now - 2_000).toISOString(),
    field: 'human_status',
    from: 'PENDING',
    to: 'PENDING',
    label: 'human decision recorded'
  });
  state = appendWorkMotion(state, {
    id: 102,
    kind: 'pending_decision_changed',
    detectedAt: new Date(now - 1_500).toISOString(),
    field: 'pending_decision',
    from: 'absent',
    to: 'present',
    label: 'pending decision changed'
  });
}

const text = frameToText(work.view(state, ctx));
mkdirSync(OUT, { recursive: true });
const outPath = join(OUT, `${label}.txt`);
writeFileSync(outPath, text + '\n', 'utf8');
process.stdout.write(`snapshot written: ${outPath}\n`);
process.stdout.write('\n--- SNAPSHOT ---\n');
process.stdout.write(text + '\n');
process.stdout.write('--- END ---\n');
