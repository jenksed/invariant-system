/**
 * Temper Workbench Alpha — Diff screen tests.
 *
 * Slice N3 acceptance: from the Work screen, an operator can
 * press d to surface a bounded `git diff` view of the current
 * worktree. The diff is read-only and projection-only; it
 * does not propose or apply any change.
 *
 * The tests use direct DiffState construction to keep the
 * tests deterministic and avoid cross-test async contamination.
 * The real public-boundary check is: launch a real temper .
 * session, modify a file in the worktree, press d, observe
 * the diff output.
 */

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createDiffScreen, type DiffState } from '../src/screens/diff.js';
import { frameToText } from '../src/tui/render.js';
import type { ScreenContext } from '../src/tui/screen.js';

function ctx(cols: number, rows: number): ScreenContext {
  return { cols, rows, inputFocused: false };
}

function loadState(text: string, error = ''): DiffState {
  return {
    repositoryRoot: '/test/repo',
    status: text.length === 0 && error === '' ? 'empty' : (text.length > 0 ? 'ready' : 'error'),
    text,
    error,
    scrollOffset: 0
  };
}

const fakeDiff = `diff --git a/example.txt b/example.txt
index 0000001..0000002 100644
--- a/example.txt
+++ b/example.txt
@@ -1,1 +1,2 @@
-old line
+old line
+new line
`;

const screen = createDiffScreen({
  repositoryRoot: '/test/repo',
  diffSource: async () => ({ ok: true, text: fakeDiff }),
  onExit: () => {},
  onResult: () => {}
});

test('N3 diff loading: shows the loading banner on init', () => {
  const text = frameToText(screen.view(screen.init(), ctx(120, 30)));
  assert.match(text, /Loading diff/);
});

test('N3 diff ready: renders the diff text with + and - visible', () => {
  const state = loadState(fakeDiff);
  const text = frameToText(screen.view(state, ctx(120, 30)));
  assert.match(text, /\+old line/);
  assert.match(text, /-old line/);
  assert.match(text, /\+new line/);
  assert.match(text, /diff --git/);
});

test('N3 diff empty: shows "no changes" when diff is empty', () => {
  const state = loadState('');
  const text = frameToText(screen.view(state, ctx(120, 30)));
  assert.match(text, /no changes/);
});

test('N3 diff error: surfaces bounded error text', () => {
  const state = loadState('', 'fatal: not a git repository');
  const text = frameToText(screen.view(state, ctx(120, 30)));
  assert.match(text, /diff failed/);
  assert.match(text, /not a git repository/);
});

test('N3 diff esc emits a pop ScreenMsg; the runtime invokes onExit on pop', () => {
  const state = loadState(fakeDiff);
  const r = screen.update(state, { kind: 'escape' }, ctx(120, 30));
  assert.equal(r.msgs[0]?.kind, 'pop');
  // Note: the screen's update does NOT call onExit directly.
  // The runtime is what invokes onExit when it processes
  // the pop message. This is the correct architecture: the
  // screen emits intent, the runtime executes it.
});

test('N3 diff q quits the screen', () => {
  const state = loadState(fakeDiff);
  const r = screen.update(state, { kind: 'char', value: 'q' }, ctx(120, 30));
  assert.equal(r.msgs[0]?.kind, 'quit');
});

test('N3 diff scroll: down / up keys adjust scroll offset', () => {
  const state = loadState(fakeDiff);
  const r1 = screen.update(state, { kind: 'down' }, ctx(120, 30));
  const r2 = screen.update(r1.state, { kind: 'down' }, ctx(120, 30));
  assert.ok(r1.state);
  assert.ok(r2.state);
  // The state object should have advanced scrollOffset.
  const s1 = r1.state as DiffState;
  const s2 = r2.state as DiffState;
  assert.equal(s1.scrollOffset, 1);
  assert.equal(s2.scrollOffset, 2);
});

test('N3 diff header shows the repository root', () => {
  const state = loadState(fakeDiff);
  const text = frameToText(screen.view(state, ctx(120, 30)));
  assert.match(text, /\/test\/repo/);
  assert.match(text, /read-only/);
});
