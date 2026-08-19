/**
 * Temper Workbench Alpha — Work screen disconnect / reconnect tests.
 *
 * Slice N1 acceptance: when the bounded Kiln WebSocket connection
 * is lost, the Work screen shows a prominent DISCONNECTED / RECONNECTING
 * banner with the last known canonical session reference. On
 * reconnect, a "SINCE YOU LEFT" feed surfaces the canonical Motion
 * deltas that arrived during the disconnect window.
 *
 * All tests are unit-level render tests using a fixture
 * WorkbenchProjection. The real public-boundary check (live daemon
 * kill+restart) is exercised by the integration scenario.
 */

import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  createWorkScreen,
  setWorkProjection,
  markWorkDisconnect,
  markWorkReconnect,
  clearWorkReconnectBanner,
  appendWorkMotion,
  type WorkState
} from '../src/screens/work.js';
import { frameToText } from '../src/tui/render.js';
import type { WorkbenchProjection } from '../src/workbench/projection.js';
import type { ScreenContext } from '../src/tui/screen.js';
import type { MotionEvent } from '../src/workbench/motion.js';

function ctx(cols: number, rows: number): ScreenContext {
  return { cols, rows, inputFocused: false };
}

function projection(overrides: Partial<WorkbenchProjection> = {}): WorkbenchProjection {
  return {
    repository: '/Users/test/repo',
    repositoryName: 'repo',
    kilnHome: '/Users/test/repo/.kiln',
    sessionId: 'ses_abcdef1234567890',
    canonicalSessionRevision: 47,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: '2026-08-19T12:00:00Z',
    sessionQuery: {
      session_id: 'ses_abcdef1234567890',
      run_state: 'active',
      verification_status: 'PENDING',
      review_status: 'PENDING',
      human_status: 'PENDING'
    },
    ...overrides
  };
}

function motionEvent(overrides: Partial<MotionEvent> = {}): MotionEvent {
  return {
    id: 1,
    kind: 'run_state_changed',
    detectedAt: '2026-08-19T12:00:30Z',
    field: 'run_state',
    from: 'active',
    to: 'completed',
    label: 'run state changed',
    ...overrides
  };
}

function freshState(p: WorkbenchProjection | null = projection()): WorkState {
  return {
    projection: p,
    pulse: [],
    motion: [],
    lastReconnectAt: null,
    disconnectedAt: null,
    humanDecide: { status: 'idle', decision: null, code: null, reason: null, at: null },
    pendingEnvelope: null
  };
}

const work = createWorkScreen({
  intent: 'Fix the reconnect projection so stale activity cannot overwrite canonical state.',
  onExit: () => {}
});

test('N1 connected: no banner shown when connection is healthy', () => {
  const state = freshState(projection({ connection: 'connected' }));
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.doesNotMatch(text, /DISCONNECTED/);
  assert.doesNotMatch(text, /RECONNECTING/);
  assert.doesNotMatch(text, /SINCE YOU LEFT/);
});

test('N1 disconnected: shows prominent DISCONNECTED banner with last canonical session', () => {
  let state = freshState(projection({ connection: 'disconnected' }));
  state = markWorkDisconnect(state, '2026-08-19T12:00:00Z');
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /DISCONNECTED from Kiln/);
  assert.match(text, /last canonical: Session ses…567890 · revision 47/);
  assert.match(text, /do not assume work stopped/);
  assert.doesNotMatch(text, /SINCE YOU LEFT/);
});

test('N1 reconnecting: shows RECONNECTING banner', () => {
  let state = freshState(projection({ connection: 'reconnecting' }));
  state = markWorkDisconnect(state, '2026-08-19T12:00:00Z');
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /RECONNECTING to Kiln/);
  assert.match(text, /last canonical: Session ses…567890/);
});

test('N1 reconnect: shows SINCE YOU LEFT feed with motion deltas count', () => {
  // Simulate the operator experience:
  //   1. disconnect → reconnecting → connected
  //   2. motion events arrive during the reconnect (canonical deltas)
  //   3. Work screen surfaces the since-you-left feed
  const now = Date.now();
  const lastReconnectIso = new Date(now - 5_000).toISOString();
  const after1 = new Date(now - 4_500).toISOString();
  const after2 = new Date(now - 4_000).toISOString();
  const before = new Date(now - 9_000).toISOString();
  let state = freshState(projection({ connection: 'connected', canonicalSessionRevision: 51 }));
  state = markWorkDisconnect(state, new Date(now - 10_000).toISOString());
  state = markWorkReconnect(state, lastReconnectIso);
  // Motion events AFTER the reconnect timestamp (should be counted).
  state = appendWorkMotion(
    state,
    motionEvent({ id: 1, detectedAt: after1, field: 'run_state' })
  );
  state = appendWorkMotion(
    state,
    motionEvent({ id: 2, detectedAt: after2, field: 'verification_status' })
  );
  // Motion event BEFORE the reconnect (should NOT be counted).
  state = appendWorkMotion(
    state,
    motionEvent({ id: 3, detectedAt: before, field: 'human_status' })
  );
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /Resynchronized to Kiln — SINCE YOU LEFT/);
  assert.match(text, /2 canonical delta\(s\) recorded during the disconnect window/);
  assert.match(text, /press any key to dismiss/);
});

test('N1 reconnect with no motion: shows banner with 0 deltas', () => {
  let state = freshState(projection({ connection: 'connected' }));
  state = markWorkDisconnect(state);
  state = markWorkReconnect(state);
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /Resynchronized to Kiln — SINCE YOU LEFT/);
  assert.match(text, /0 canonical delta\(s\) recorded/);
});

test('N1 dismissal: any key clears the reconnect banner', () => {
  let state = freshState(projection({ connection: 'connected' }));
  state = markWorkDisconnect(state);
  state = markWorkReconnect(state);
  // Sanity: banner is present before dismissal.
  const beforeText = frameToText(work.view(state, ctx(120, 30)));
  assert.match(beforeText, /SINCE YOU LEFT/);

  const r = work.update(state, { kind: 'char', value: 'a' }, ctx(120, 30));
  const afterState = r.state as WorkState;
  assert.equal(afterState.lastReconnectAt, null);
  const afterText = frameToText(work.view(afterState, ctx(120, 30)));
  assert.doesNotMatch(afterText, /SINCE YOU LEFT/);
});

test('N1 clearWorkReconnectBanner: explicit clear works', () => {
  let state = freshState(projection({ connection: 'connected' }));
  state = markWorkReconnect(state);
  assert.ok(state.lastReconnectAt);
  const cleared = clearWorkReconnectBanner(state);
  assert.equal(cleared.lastReconnectAt, null);
});

test('N1 markWorkDisconnect: idempotent — second call does not overwrite first timestamp', () => {
  let state = freshState(projection({ connection: 'disconnected' }));
  state = markWorkDisconnect(state, '2026-08-19T12:00:00Z');
  const first = state.disconnectedAt;
  state = markWorkDisconnect(state, '2026-08-19T12:01:00Z');
  assert.equal(state.disconnectedAt, first, 'disconnectedAt must not be overwritten');
});

test('N1 markWorkReconnect: clears disconnectedAt', () => {
  let state = freshState(projection({ connection: 'connected' }));
  state = markWorkDisconnect(state, '2026-08-19T12:00:00Z');
  assert.ok(state.disconnectedAt);
  state = markWorkReconnect(state, '2026-08-19T12:00:30Z');
  assert.equal(state.disconnectedAt, null);
  assert.ok(state.lastReconnectAt);
});

test('N1 disconnected session: banner still renders with "—" when no session known', () => {
  const state: WorkState = {
    projection: {
      repository: '/Users/test/repo',
      repositoryName: 'repo',
      kilnHome: '/Users/test/repo/.kiln',
      sessionId: null,
      canonicalSessionRevision: null,
      orphaned: false,
      unknowns: [],
      connection: 'disconnected',
      builtAt: '2026-08-19T12:00:00Z'
    },
    pulse: [],
    motion: [],
    lastReconnectAt: null,
    disconnectedAt: '2026-08-19T12:00:00Z',
    humanDecide: { status: 'idle', decision: null, code: null, reason: null, at: null },
    pendingEnvelope: null
  };
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /DISCONNECTED from Kiln/);
  assert.match(text, /no canonical session known/);
});
