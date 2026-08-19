/**
 * Temper Workbench Alpha — Home/Resume screen tests.
 *
 * Snapshot tests for the Home screen render. The screen is driven
 * with a fixture WorkbenchProjection; the resulting frame is
 * converted to plain text and asserted against expected content.
 */

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHomeScreen, setHomeProjection, type HomeState } from '../src/screens/home.js';
import { frameToText } from '../src/tui/render.js';
import type { WorkbenchProjection } from '../src/workbench/projection.js';
import type { ScreenContext, ScreenSpec } from '../src/tui/screen.js';
import { focusInput, setInputValue } from '../src/tui/input.js';
import { createInputState } from '../src/tui/input.js';

function ctx(cols: number, rows: number): ScreenContext {
  return { cols, rows, inputFocused: true };
}

function fixtureProjection(overrides: Partial<WorkbenchProjection> = {}): WorkbenchProjection {
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
      task_id: 'tsk_xyz',
      root_run_id: 'run_root',
      run_state: 'active',
      workflow_step: 'awaiting_operator',
      objective: 'Temper Workbench Alpha',
      criteria: ['operator-submitted intent'],
      verification_status: 'PENDING',
      review_status: 'PENDING',
      human_status: 'PENDING',
      unknowns: []
    },
    ...overrides
  };
}

test('Home screen renders project identity + last canonical state + intent input', () => {
  let state: HomeState = {
    projection: null,
    input: focusInput(createInputState({ prompt: '> ', multiline: true }), true),
    submitState: 'idle',
    submitError: '',
    hydrated: false
  };
  state = setHomeProjection(state, fixtureProjection());
  const home = createHomeScreen({
    onSubmitIntent: async () => ({ ok: true })
  });
  const frame = home.view(state, ctx(100, 30));
  const text = frameToText(frame);

  assert.match(text, /Temper/);
  assert.match(text, /repo/);
  assert.match(text, /Session/);
  assert.match(text, /PROJECT/);
  assert.match(text, /LAST CANONICAL STATE/);
  assert.match(text, /INTENT/);
  assert.match(text, /Run state/);
  assert.match(text, /active/);
  assert.match(text, /Verification/);
  assert.match(text, /PENDING/);
  assert.match(text, /Enter submit/);
});

test('Home screen shows "no active session" when sessionId is null', () => {
  let state: HomeState = {
    projection: null,
    input: focusInput(createInputState({ prompt: '> ', multiline: true }), true),
    submitState: 'idle',
    submitError: '',
    hydrated: false
  };
  const noSession: WorkbenchProjection = {
    repository: '/Users/test/repo',
    repositoryName: 'repo',
    kilnHome: '/Users/test/repo/.kiln',
    sessionId: null,
    canonicalSessionRevision: null,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: '2026-08-19T12:00:00Z'
  };
  state = setHomeProjection(state, noSession);
  const home = createHomeScreen({ onSubmitIntent: async () => ({ ok: true }) });
  const text = frameToText(home.view(state, ctx(100, 30)));
  assert.match(text, /No active Session/);
  assert.match(text, /—/);
});

test('Home screen surfaces orphaned state with a warn marker', () => {
  let state: HomeState = {
    projection: null,
    input: focusInput(createInputState({ prompt: '> ', multiline: true }), true),
    submitState: 'idle',
    submitError: '',
    hydrated: false
  };
  state = setHomeProjection(state, fixtureProjection({ orphaned: true, unknowns: ['unknown_op_1'] }));
  const home = createHomeScreen({ onSubmitIntent: async () => ({ ok: true }) });
  const text = frameToText(home.view(state, ctx(100, 30)));
  assert.match(text, /ORPHANED/);
});

test('Home screen surfaces submit error', () => {
  let state: HomeState = {
    projection: null,
    input: focusInput(createInputState({ prompt: '> ', multiline: true }), true),
    submitState: 'error',
    submitError: 'session.start failed: E_SESSION_ALREADY_EXISTS',
    hydrated: true
  };
  state = setHomeProjection(state, fixtureProjection());
  const home = createHomeScreen({ onSubmitIntent: async () => ({ ok: true }) });
  const text = frameToText(home.view(state, ctx(100, 30)));
  assert.match(text, /submit failed/);
  assert.match(text, /E_SESSION_ALREADY_EXISTS/);
});

test('Home screen quit key emits quit message when input is empty', () => {
  const home = createHomeScreen({ onSubmitIntent: async () => ({ ok: true }) });
  const state: HomeState = {
    projection: fixtureProjection(),
    input: focusInput(createInputState({ prompt: '> ' }), true),
    submitState: 'idle',
    submitError: '',
    hydrated: true
  };
  const r = home.update(state, { kind: 'char', value: 'q' }, ctx(100, 30));
  assert.equal(r.msgs.some((m) => m.kind === 'quit'), true);
});

test('Home screen "q" inside an input is treated as text', () => {
  const home = createHomeScreen({ onSubmitIntent: async () => ({ ok: true }) });
  const input = focusInput(createInputState({ prompt: '> ', initial: 'fix ' }), true);
  const state: HomeState = {
    projection: fixtureProjection(),
    input,
    submitState: 'idle',
    submitError: '',
    hydrated: true
  };
  const r = home.update(state, { kind: 'char', value: 'q' }, ctx(100, 30));
  const next = r.state as HomeState;
  // No quit message; the q was typed into the input.
  assert.equal(r.msgs.some((m) => m.kind === 'quit'), false);
  assert.equal(next.input.value, 'fix q');
});

test('Home screen ctrl-c always quits', () => {
  const home = createHomeScreen({ onSubmitIntent: async () => ({ ok: true }) });
  const state: HomeState = {
    projection: fixtureProjection(),
    input: focusInput(createInputState({ prompt: '> ', initial: 'fix' }), true),
    submitState: 'idle',
    submitError: '',
    hydrated: true
  };
  const r = home.update(state, { kind: 'ctrl', value: 'c' }, ctx(100, 30));
  assert.equal(r.msgs.some((m) => m.kind === 'quit'), true);
});

test('Home screen enter on non-empty input flips submitState to submitting', () => {
  const home = createHomeScreen({
    onSubmitIntent: async () => ({ ok: true })
  });
  const state: HomeState = {
    projection: fixtureProjection(),
    input: focusInput(createInputState({ prompt: '> ', initial: 'fix reconnect' }), true),
    submitState: 'idle',
    submitError: '',
    hydrated: true
  };
  const r = home.update(state, { kind: 'enter' }, ctx(100, 30));
  const next = r.state as HomeState;
  assert.equal(next.submitState, 'submitting');
});

test('Home screen escape clears the input when non-empty', () => {
  const home = createHomeScreen({ onSubmitIntent: async () => ({ ok: true }) });
  const state: HomeState = {
    projection: fixtureProjection(),
    input: focusInput(createInputState({ prompt: '> ', initial: 'fix' }), true),
    submitState: 'idle',
    submitError: '',
    hydrated: true
  };
  const r = home.update(state, { kind: 'escape' }, ctx(100, 30));
  const next = r.state as HomeState;
  assert.equal(next.input.value, '');
});

// -- workbench connection smoke (with fake fetch) --

test('WorkbenchConnection: project.open failure surfaces lastError', async () => {
  const { WorkbenchConnection } = await import('../src/workbench/connection.js');
  const conn = new WorkbenchConnection({
    baseUrl: 'http://127.0.0.1:1',
    wsUrl: 'ws://127.0.0.1:1/ws',
    readToken: 'R',
    operateToken: 'O',
    repository: '/tmp/nonexistent'
  });
  // Inject a fake fetch that returns E_PROJECT_NOT_FOUND.
  const fakeFetch: typeof fetch = (async () =>
    new Response(JSON.stringify({ code: 'E_PROJECT_NOT_FOUND', reason: 'path does not exist' }), {
      status: 400,
      headers: { 'content-type': 'application/json' }
    })) as unknown as typeof fetch;
  (conn as unknown as { client: { fetch: typeof fetch } }).client.fetch = fakeFetch;
  let caught = false;
  try {
    await conn.open();
  } catch {
    caught = true;
  }
  assert.equal(caught, true);
  // Last error is recorded.
  const proj = conn.current();
  assert.match(proj.lastError ?? '', /E_PROJECT_NOT_FOUND/);
});
