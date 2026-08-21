import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHomeScreen, type HomeState } from '../src/screens/home.js';
import { createInputState, focusInput } from '../src/tui/input.js';
import type { ScreenContext } from '../src/tui/screen.js';

const ctx: ScreenContext = { cols: 100, rows: 30, inputFocused: true };
function state(initial: string): HomeState {
  return {
    projection: null,
    input: focusInput(createInputState({ prompt: '> ', initial }), true),
    submitState: 'idle', submitError: '', hydrated: true,
    commandState: 'idle', commandOutput: []
  };
}

test('slash input routes to command callback and never to session intent', async () => {
  const calls: string[] = [];
  let invalidate = 0;
  const home = createHomeScreen({
    onSubmitIntent: async (intent) => { calls.push(`intent:${intent}`); return { ok: true }; },
    onCommand: async (line) => { calls.push(`command:${line}`); return { ok: true, lines: ['transport=connected'] }; },
    onInvalidate: () => { invalidate += 1; }
  });
  const s = state('/status');
  const r = home.update(s, { kind: 'enter' }, ctx);
  assert.equal((r.state as HomeState).commandState, 'running');
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls, ['command:/status']);
  assert.equal(s.commandState, 'success');
  assert.match((s.commandOutput ?? []).join('\n'), /transport=connected/);
  assert.equal(invalidate, 1);
});

test('free text still routes only to session intent', async () => {
  const calls: string[] = [];
  const home = createHomeScreen({
    onSubmitIntent: async (intent) => { calls.push(`intent:${intent}`); return { ok: true }; },
    onCommand: async (line) => { calls.push(`command:${line}`); return { ok: true, lines: [] }; }
  });
  home.update(state('fix reconnect'), { kind: 'enter' }, ctx);
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls, ['intent:fix reconnect']);
});

test('ctrl-k enters slash command mode without invoking authority', () => {
  const calls: string[] = [];
  const home = createHomeScreen({
    onSubmitIntent: async () => ({ ok: true }),
    onCommand: async (line) => { calls.push(line); return { ok: true, lines: [] }; }
  });
  const r = home.update(state(''), { kind: 'ctrl', value: 'k' }, ctx);
  const next = r.state as HomeState;
  assert.equal(next.input.value, '/');
  assert.equal(next.input.prompt, 'cmd> ');
  assert.deepEqual(calls, []);
});
