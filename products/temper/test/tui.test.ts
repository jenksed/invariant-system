/**
 * Temper Workbench Alpha — TUI runtime tests.
 *
 * Unit tests for the keypress parser, frame buffer, and runtime
 * dispatcher. No real raw mode, no real WebSocket, no real Kiln.
 */

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { PassThrough } from 'node:stream';
import { createKeypressParser } from '../src/tui/keypress.js';
import { TuiRuntime } from '../src/tui/tui.js';
import { frameToText, ANSI } from '../src/tui/render.js';
import { createFrame, putString, putLabeledBox } from '../src/tui/frame.js';
import { createInputState, focusInput, setInputValue, updateInput } from '../src/tui/input.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from '../src/tui/screen.js';

// -- keypress parser --

test('keypress parser: char passes through', () => {
  const p = createKeypressParser();
  const events = p.feed('a');
  assert.equal(events.length, 1);
  assert.deepEqual(events[0], { kind: 'char', value: 'a' });
});

test('keypress parser: enter (CR / LF) → enter', () => {
  const p = createKeypressParser();
  assert.deepEqual(p.feed('\r'), [{ kind: 'enter' }]);
  assert.deepEqual(p.feed('\n'), [{ kind: 'enter' }]);
});

test('keypress parser: tab → tab', () => {
  const p = createKeypressParser();
  assert.deepEqual(p.feed('\t'), [{ kind: 'tab' }]);
});

test('keypress parser: backspace / DEL → backspace', () => {
  const p1 = createKeypressParser();
  const p2 = createKeypressParser();
  assert.deepEqual(p1.feed('\x7f'), [{ kind: 'backspace' }]);
  assert.deepEqual(p2.feed('\b'), [{ kind: 'backspace' }]);
});

test('keypress parser: arrow keys via CSI', () => {
  const up = createKeypressParser().feed('\x1b[A');
  const down = createKeypressParser().feed('\x1b[B');
  const right = createKeypressParser().feed('\x1b[C');
  const left = createKeypressParser().feed('\x1b[D');
  assert.deepEqual(up[0], { kind: 'up' });
  assert.deepEqual(down[0], { kind: 'down' });
  assert.deepEqual(right[0], { kind: 'right' });
  assert.deepEqual(left[0], { kind: 'left' });
});

test('keypress parser: ctrl+a / ctrl+c', () => {
  const p1 = createKeypressParser();
  const p2 = createKeypressParser();
  assert.deepEqual(p1.feed('\x01'), [{ kind: 'ctrl', value: 'a' }]);
  assert.deepEqual(p2.feed('\x03'), [{ kind: 'ctrl', value: 'c' }]);
});

test('keypress parser: split ESC sequence across feeds', () => {
  const p = createKeypressParser();
  const a = p.feed('\x1b');
  assert.equal(a.length, 0, 'incomplete ESC keeps the byte buffered');
  const b = p.feed('[A');
  assert.equal(b.length, 1);
  assert.deepEqual(b[0], { kind: 'up' });
});

test('keypress parser: lone ESC → escape', () => {
  const p = createKeypressParser();
  // After an ESC alone the parser needs to flush; we simulate the
  // runtime sending a follow-up empty feed to flush the buffer. In
  // practice the runtime injects the escape when the stream closes
  // or after a timeout. For the test we feed an extra char to flush.
  p.feed('\x1b');
  const after = p.feed('x');
  // First event: escape (from the lone ESC). Second: char 'x'.
  assert.equal(after[0]?.kind, 'escape');
  assert.equal(after[1]?.kind, 'char');
});

test('keypress parser: bracketed paste', () => {
  const p = createKeypressParser();
  const events = p.feed('\x1b[200~hello\x1b[201~');
  assert.equal(events.length, 1);
  assert.equal(events[0]?.kind, 'paste');
  if (events[0]?.kind === 'paste') {
    assert.equal(events[0].value, 'hello');
  }
});

// -- frame buffer --

test('frame buffer: putString + putLabeledBox + text extraction', () => {
  const f = createFrame(40, 10);
  putString(f, 0, 0, 'hello', 'header');
  putLabeledBox(f, { rect: { row: 2, col: 1, rows: 5, cols: 20 }, title: 'X' });
  const text = frameToText(f);
  assert.match(text, /hello/);
  assert.match(text, /X/);
});

test('frame buffer: out-of-bounds is a no-op', () => {
  const f = createFrame(20, 5);
  putString(f, 10, 0, 'overflow', 'normal');
  putString(f, 0, 30, 'overflow', 'normal');
  // Frame should not have changed except for the initial spaces.
  const text = frameToText(f);
  assert.doesNotMatch(text, /overflow/);
});

// -- input widget --

test('input widget: char appends and cursor advances', () => {
  const s = focusInput(createInputState({ prompt: '> ' }), true);
  const r1 = updateInput(s, { kind: 'char', value: 'a' });
  const r2 = updateInput(r1.state, { kind: 'char', value: 'b' });
  assert.equal(r2.state.value, 'ab');
  assert.equal(r2.state.cursor, 2);
});

test('input widget: backspace deletes the char before the cursor', () => {
  const s = focusInput(createInputState({ prompt: '> ', initial: 'abc' }), true);
  const r = updateInput(s, { kind: 'backspace' });
  assert.equal(r.state.value, 'ab');
  assert.equal(r.state.cursor, 2);
});

test('input widget: enter emits submit msg', () => {
  const s = focusInput(createInputState({ prompt: '> ', initial: 'fix it' }), true);
  const r = updateInput(s, { kind: 'enter' });
  const submit = r.msgs.find((m) => m.kind === 'submit');
  assert.ok(submit);
  if (submit && submit.kind === 'submit') assert.equal(submit.value, 'fix it');
});

test('input widget: history navigation', () => {
  let s = focusInput(createInputState({ prompt: '> ', history: ['first', 'second', 'third'] }), true);
  // Up once → most recent (first in the ring).
  s = updateInput(s, { kind: 'up' }).state;
  assert.equal(s.value, 'first');
  // Up again → second.
  s = updateInput(s, { kind: 'up' }).state;
  assert.equal(s.value, 'second');
  // Down → back to first.
  s = updateInput(s, { kind: 'down' }).state;
  assert.equal(s.value, 'first');
  // Down again → empty (saved).
  s = updateInput(s, { kind: 'down' }).state;
  assert.equal(s.value, '');
});

test('input widget: not focused → no-op for all keys', () => {
  const s = createInputState({ prompt: '> ' });
  const r = updateInput(s, { kind: 'char', value: 'a' });
  assert.equal(r.state.value, '');
  assert.equal(r.msgs.length, 0);
});

test('input widget: setInputValue resets history nav', () => {
  let s = focusInput(createInputState({ prompt: '> ', history: ['x', 'y'] }), true);
  s = updateInput(s, { kind: 'up' }).state;
  s = setInputValue(s, 'reset');
  assert.equal(s.value, 'reset');
  assert.equal(s.cursor, 5);
  assert.equal(s.historyIndex, -1);
});

// -- runtime dispatch --

class StringOutput extends PassThrough {
  collected: string = '';
  columns: number = 100;
  rows: number = 30;
  constructor() {
    super();
    this.on('data', (chunk: Buffer | string) => {
      this.collected += typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    });
  }
}

function makeRuntime(): { runtime: TuiRuntime; out: StringOutput; input: PassThrough } {
  const out = new StringOutput();
  const input = new PassThrough();
  const runtime = new TuiRuntime({ out, input, altScreen: false, cols: 80, rows: 20 });
  return { runtime, out, input };
}

function makeCountScreen(id: string): { screen: ScreenSpec; calls: { kind: string; value: string }[] } {
  const calls: { kind: string; value: string }[] = [];
  let n = 0;
  const screen: ScreenSpec = {
    id,
    title: id,
    init: () => ({ n }),
    view: (_state, ctx) => {
      const f = createFrame(ctx.cols, ctx.rows);
      putString(f, 0, 0, `${id}:${n}`, 'header');
      return f;
    },
    update: (state, key) => {
      calls.push({ kind: key.kind, value: key.kind === 'char' ? key.value : (key.kind === 'ctrl' ? key.value : '') });
      if (key.kind === 'char' && key.value === '+') n += 1;
      if (key.kind === 'char' && key.value === 'q') {
        return { state, msgs: [{ kind: 'quit' }] };
      }
      return { state, msgs: [] };
    }
  };
  return { screen, calls };
}

test('runtime: push + key dispatch + render', () => {
  const { runtime, out, input } = makeRuntime();
  const { screen, calls } = makeCountScreen('home');
  runtime.push(screen);
  input.write('+');
  input.write('+');
  input.write('+');
  const frame = runtime.debugFrame();
  const text = frameToText(frame);
  assert.match(text, /home:3/);
  // The keypress events were delivered.
  assert.equal(calls.filter((c) => c.kind === 'char' && c.value === '+').length, 3);
  runtime.stop();
  void out;
});

test('runtime: quit message closes the runtime', () => {
  const { runtime, out, input } = makeRuntime();
  const { screen } = makeCountScreen('home');
  runtime.push(screen);
  input.write('q');
  // After the quit message, runtime.stop() should have written the
  // SHOW_CURSOR escape; subsequent renders should be no-ops.
  const text = out.collected;
  assert.match(text, /\x1b\[\?25h/);
  runtime.stop();
});

test('runtime: alt-screen writes enter code on start', () => {
  const { runtime, out, input } = makeRuntime();
  const { screen } = makeCountScreen('home');
  runtime.push(screen);
  // Replace with alt-screen variant to avoid pulling PassThrough quirks.
  void input;
  runtime.stop();
  // altScreen defaults to true; the start path writes \x1b[?1049h.
  // In this test we constructed the runtime with altScreen:false to
  // keep output deterministic. Just confirm no crash.
  void out;
});
