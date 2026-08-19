/**
 * Temper Workbench Alpha — bounded diff screen.
 *
 * Press `d` in the Work screen to surface this screen. It
 * fetches `git diff` against the current worktree through the
 * provided `diffSource` function (execFileSync in the
 * orchestrator) and renders the unified diff output bounded to
 * the available viewport.
 *
 * Authority rule: this screen is projection-only. It reads
 * the current worktree bytes; it does not own a workflow
 * boolean and does not propose any governed change.
 */

import { putString, wrapText } from '../tui/frame.js';
import type { Frame } from '../tui/frame.js';
import { createFrame } from '../tui/frame.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from '../tui/screen.js';

export interface DiffDeps {
  /** The repository root to diff against. */
  repositoryRoot: string;
  /** Function that returns the bounded diff text. The default
   *  implementation in the orchestrator uses execFileSync to
   *  spawn `git diff`. */
  diffSource: (root: string) => Promise<{ ok: boolean; text: string; error?: string }>;
  /** Called when the operator presses esc / q to leave the
   *  diff screen. */
  onExit: () => void;
  /** Called by the screen when the async diff result arrives.
   *  The orchestrator uses this to set the runtime state. */
  onResult: (
    result:
      | { status: 'ready'; text: string }
      | { status: 'empty' }
      | { status: 'error'; error: string }
  ) => void;
}

export interface DiffState {
  repositoryRoot: string;
  status: 'loading' | 'ready' | 'empty' | 'error';
  text: string;
  error: string;
  scrollOffset: number;
}

export function createDiffScreen(deps: DiffDeps): ScreenSpec {
  return {
    id: 'diff',
    title: 'Diff',
    init: (): DiffState => {
      // Trigger an async load. The result lands via
      // deps.onResult, which the orchestrator wires to the
      // runtime state.
      void loadDiff(deps);
      return {
        repositoryRoot: deps.repositoryRoot,
        status: 'loading',
        text: '',
        error: '',
        scrollOffset: 0
      };
    },
    view: (state, ctx) => renderDiff(state as DiffState, ctx, deps),
    update: (state, key, ctx) => updateDiff(state as DiffState, key, ctx, deps)
  };
}

async function loadDiff(deps: DiffDeps): Promise<void> {
  try {
    const result = await deps.diffSource(deps.repositoryRoot);
    if (!result.ok) {
      deps.onResult({ status: 'error', error: result.error ?? 'diff failed' });
      return;
    }
    if (result.text.length === 0) {
      deps.onResult({ status: 'empty' });
      return;
    }
    deps.onResult({ status: 'ready', text: result.text });
  } catch (err) {
    deps.onResult({ status: 'error', error: (err as Error).message });
  }
}

function updateDiff(
  state: DiffState,
  key: Key,
  _ctx: ScreenContext,
  deps: DiffDeps
): { state: DiffState; msgs: ScreenMsg[] } {
  if (key.kind === 'ctrl' && key.value === 'c') {
    return { state, msgs: [{ kind: 'quit' }] };
  }
  if (key.kind === 'escape') {
    deps.onExit();
    return { state, msgs: [{ kind: 'pop' }] };
  }
  if (key.kind === 'char' && key.value === 'q') {
    deps.onExit();
    return { state, msgs: [{ kind: 'quit' }] };
  }
  if (key.kind === 'down' || (key.kind === 'char' && key.value === 'j')) {
    return { state: { ...state, scrollOffset: state.scrollOffset + 1 }, msgs: [] };
  }
  if (key.kind === 'up' || (key.kind === 'char' && key.value === 'k')) {
    return { state: { ...state, scrollOffset: Math.max(0, state.scrollOffset - 1) }, msgs: [] };
  }
  if (key.kind === 'page_down') {
    return { state: { ...state, scrollOffset: state.scrollOffset + 10 }, msgs: [] };
  }
  if (key.kind === 'page_up') {
    return { state: { ...state, scrollOffset: Math.max(0, state.scrollOffset - 10) }, msgs: [] };
  }
  if (key.kind === 'home') {
    return { state: { ...state, scrollOffset: 0 }, msgs: [] };
  }
  if (key.kind === 'end') {
    return { state: { ...state, scrollOffset: 9999 }, msgs: [] };
  }
  return { state, msgs: [] };
}

function renderDiff(state: DiffState, ctx: ScreenContext, _deps: DiffDeps): Frame {
  const frame = createFrame(ctx.cols, ctx.rows);
  // Header
  putString(frame, 0, 0, ' ◆ TEMPER ', 'wordmark');
  const headerRight = `Diff · ${truncate(state.repositoryRoot, Math.max(8, ctx.cols - 12))}`;
  putString(frame, 0, ctx.cols - headerRight.length - 1, headerRight, 'header');
  putString(frame, 1, 0, ` read-only · git diff against worktree`, 'muted');
  putString(frame, 2, 0, '─'.repeat(ctx.cols), 'border');

  // Body
  const bodyTop = 4;
  const footerRow = ctx.rows - 1;
  const bodyHeight = footerRow - bodyTop - 1;
  const innerW = ctx.cols - 2;

  if (state.status === 'loading') {
    putString(frame, bodyTop + 1, 1, ' ⏳ Loading diff…', 'muted');
  } else if (state.status === 'error') {
    putString(frame, bodyTop + 1, 1, ' ✕ diff failed', 'error');
    putString(frame, bodyTop + 2, 1, truncate(state.error, innerW - 4), 'muted');
  } else if (state.status === 'empty') {
    putString(frame, bodyTop + 1, 1, ' (no changes — worktree clean against HEAD)', 'muted');
  } else {
    // Render the diff text line-by-line, bounded to the viewport.
    const lines = state.text.split('\n');
    const maxLines = bodyHeight;
    const start = Math.min(state.scrollOffset, Math.max(0, lines.length - maxLines));
    const end = Math.min(lines.length, start + maxLines);
    for (let i = 0; i < end - start; i += 1) {
      const r = bodyTop + i;
      if (r >= footerRow) break;
      const line = lines[start + i] ?? '';
      const style = diffLineStyle(line);
      putString(frame, r, 1, truncate(line, innerW - 2), style);
    }
  }

  // Footer
  const footer = ' ↑/↓ scroll · page up/down · home/end · esc back · q quit ';
  putString(frame, footerRow, 0, pad(footer, ctx.cols), 'footer');
  return frame;
}

function diffLineStyle(line: string): 'normal' | 'success' | 'error' | 'muted' {
  if (line.startsWith('+') && !line.startsWith('+++')) return 'success';
  if (line.startsWith('-') && !line.startsWith('---')) return 'error';
  if (line.startsWith('@@') || line.startsWith('diff ') || line.startsWith('index ')) return 'muted';
  return 'normal';
}

function pad(text: string, width: number): string {
  if (text.length >= width) return text.slice(0, width);
  return text + ' '.repeat(width - text.length);
}

function truncate(text: string, width: number): string {
  if (text.length <= width) return text;
  if (width <= 1) return text.slice(0, width);
  return text.slice(0, width - 1) + '…';
}
