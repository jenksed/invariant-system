/**
 * Temper Workbench Alpha — Home/Resume screen.
 *
 * The first screen after `temper .` opens. Renders project identity,
 * last canonical state, and an intent input. When the operator
 * presses Enter, the screen dispatches an intent message to the
 * runtime, which routes to the Work screen after a session.start
 * RPC round-trip.
 *
 * Authority rule: the screen renders only what the WorkbenchConnection
 * reports. It never claims the work is healthy / complete / authorized.
 */

import {
  createInputState,
  focusInput,
  pushInputHistory,
  setInputValue,
  setPrompt,
  updateInput
} from '../tui/input.js';
import { putLabeledBox, putString, wrapText } from '../tui/frame.js';
import type { Frame } from '../tui/frame.js';
import { createFrame } from '../tui/frame.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from '../tui/screen.js';
import type { WorkbenchProjection } from '../workbench/projection.js';

export interface HomeDeps {
  /** Called when the operator submits an intent; must return the
   *  resulting projection (after session.start). */
  onSubmitIntent: (intent: string) => Promise<{ ok: true } | { ok: false; error: string }>;
  /** Called when the operator opens the command palette. */
  onOpenPalette?: () => void;
}

export interface HomeState {
  projection: WorkbenchProjection | null;
  input: ReturnType<typeof createInputState>;
  /** Submission status: 'idle' | 'submitting' | 'error'. */
  submitState: 'idle' | 'submitting' | 'error';
  /** Last error message from onSubmitIntent. */
  submitError: string;
  /** Has the projection been hydrated at least once? */
  hydrated: boolean;
}

export function createHomeScreen(deps: HomeDeps): ScreenSpec {
  return {
    id: 'home',
    title: 'Home',
    init: () => ({
      projection: null,
      input: focusInput(createInputState({ prompt: '> ', multiline: true, maxChars: 4096 }), true),
      submitState: 'idle',
      submitError: '',
      hydrated: false
    }),
    view: (state, ctx) => renderHome(state as HomeState, ctx),
    update: (state, key, ctx) => updateHome(state as HomeState, key, ctx, deps)
  };
}

/** Allow external code to push the hydrated projection into the screen state. */
export function setHomeProjection(state: HomeState, projection: WorkbenchProjection): HomeState {
  return { ...state, projection, hydrated: true };
}

// TEMPER block art (primary recommendation). Each entry is one row.
// Renders in wordmark style (default fg, bold) so it adapts to the
// terminal's color scheme: white on dark, black on light.
const TEMPER_BLOCK: string[] = [
  '████████╗███████╗███╗   ███╗██████╗ ███████╗██████╗',
  '╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██╔════╝██╔══██╗',
  '   ██║   █████╗  ██╔████╔██║██████╔╝█████╗  ██████╔╝',
  '   ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██╔══╝  ██╔══██╗',
  '   ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗██║  ██║',
  '   ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝'
];

const SPLASH_POWERED_BY = 'Powered by Invariant';
const SPLASH_PRODUCTS = 'KILN · LOADOUT · ARSENAL · MANIFOLD';

function updateHome(
  state: HomeState,
  key: Key,
  ctx: ScreenContext,
  deps: HomeDeps
): { state: HomeState; msgs: ScreenMsg[] } {
  // ctrl-c → quit; q → quit only when input is empty and idle
  if (key.kind === 'ctrl' && key.value === 'c') {
    return { state, msgs: [{ kind: 'quit' }] };
  }
  if (key.kind === 'char' && key.value === 'q' && state.input.value.length === 0 && state.submitState === 'idle') {
    return { state, msgs: [{ kind: 'quit' }] };
  }
  if (key.kind === 'escape') {
    if (state.input.value.length > 0) {
      const next = setInputValue(state.input, '');
      return { state: { ...state, input: next }, msgs: [] };
    }
    return { state, msgs: [] };
  }
  if (key.kind === 'ctrl' && key.value === 'k') {
    deps.onOpenPalette?.();
    return { state, msgs: [] };
  }

  // Submit flow
  if (key.kind === 'enter' && state.input.value.length > 0 && state.submitState === 'idle') {
    const intent = state.input.value.trim();
    if (intent.length === 0) {
      return { state, msgs: [] };
    }
    // Synchronously fire the intent submission; the screen will be
    // transitioned by the runtime after onSubmitIntent resolves.
    void submitIntent(state, intent, deps);
    return {
      state: { ...state, submitState: 'submitting', input: setPrompt(state.input, '… submitting') },
      msgs: []
    };
  }

  // Delegate remaining key events to the input widget.
  const result = updateInput(state.input, key);
  if (result.msgs.some((m) => m.kind === 'submit') && state.submitState === 'idle') {
    const value = result.state.value.trim();
    if (value.length > 0) {
      void submitIntent(state, value, deps);
      return {
        state: { ...state, submitState: 'submitting', input: result.state },
        msgs: []
      };
    }
  }
  return { state: { ...state, input: result.state }, msgs: result.msgs };
}

async function submitIntent(state: HomeState, intent: string, deps: HomeDeps): Promise<void> {
  const result = await deps.onSubmitIntent(intent);
  if (result.ok) {
    // Runtime will replace the screen; nothing to do here.
    return;
  }
  // Surface the error inline. The next render will show it.
  // We do not have a setter here; the screen state is updated via
  // the runtime's setTopState. Instead, emit a ScreenMsg that the
  // runtime can interpret. For now, we use a no-op and rely on the
  // next external state push.
  state.submitState = 'error';
  state.submitError = result.error;
}

/** External hook for the runtime to recover from an inline error. */
export function setHomeSubmitError(state: HomeState, error: string): HomeState {
  return {
    ...state,
    submitState: 'error',
    submitError: error,
    input: setInputValue(state.input, ''),
    inputFocused: true
  } as HomeState;
}

// -- view --

function renderHome(state: HomeState, ctx: ScreenContext): Frame {
  const frame = createFrame(ctx.cols, ctx.rows);
  const p = state.projection;

  // Splash mode: while the projection is not yet hydrated, render the
  // full block-letter TEMPER splash with the powered-by hierarchy. As
  // soon as the projection lands, transition to the work-focused
  // home view that shows the canonical Session state.
  const showSplash = !state.hydrated || !p;
  if (showSplash) {
    return renderSplash(frame, ctx, state);
  }

  // ---- Post-hydration: work-focused home view ----
  // Header row 0: small wordmark (left) + session indicator (right).
  putString(frame, 0, 0, ' ◆ TEMPER ', 'wordmark');
  const headerRight = `Session ${formatSession(p.sessionId)}  ·  ${connectionGlyph(p.connection)}`;
  putString(frame, 0, ctx.cols - headerRight.length - 1, headerRight, 'header');
  // Row 1: project path (left) + Kiln home (right).
  const leftLine = ` project  ${truncate(p.repository, Math.max(8, ctx.cols - 30))}`;
  putString(frame, 1, 0, leftLine, 'muted');
  const rightLine = `kiln ${truncate(p.kilnHome, Math.max(8, ctx.cols - leftLine.length - 8))} `;
  putString(frame, 1, Math.max(0, ctx.cols - rightLine.length - 1), rightLine, 'muted');
  // Row 2: subtle divider.
  putString(frame, 2, 0, '─'.repeat(ctx.cols), 'border');

  // Body
  const bodyTop = 4;
  const bodyHeight = ctx.rows - bodyTop - 4;

  // Project identity
  let row = bodyTop;
  putLabeledBox(frame, { rect: { row, col: 1, rows: 6, cols: ctx.cols - 2 }, title: 'PROJECT' });
  row += 1;
  if (p) {
    putString(frame, row, 3, 'Path', 'muted');
    putString(frame, row, 12, truncate(p.repository, ctx.cols - 14));
    row += 1;
    putString(frame, row, 3, 'Kiln home', 'muted');
    putString(frame, row, 12, truncate(p.kilnHome, ctx.cols - 14));
    row += 1;
    putString(frame, row, 3, 'Session', 'muted');
    putString(frame, row, 12, formatSession(p.sessionId));
    row += 1;
    putString(frame, row, 3, 'Revision', 'muted');
    putString(frame, row, 12, p.canonicalSessionRevision == null ? '—' : String(p.canonicalSessionRevision));
  } else {
    putString(frame, row, 3, state.hydrated ? 'Project hydration failed' : 'Hydrating from Kiln…', 'muted');
  }
  row += 1;

  // Last canonical state
  row += 1;
  putLabeledBox(frame, { rect: { row, col: 1, rows: 7, cols: ctx.cols - 2 }, title: 'LAST CANONICAL STATE' });
  row += 1;
  if (p?.sessionQuery) {
    const sq = p.sessionQuery;
    const lines: Array<[string, string]> = [
      ['Objective', sq.objective ?? '—'],
      ['Run state', sq.run_state ?? '—'],
      ['Verification', sq.verification_status ?? '—'],
      ['Review', sq.review_status ?? '—'],
      ['Human', sq.human_status ?? '—']
    ];
    for (const [label, value] of lines) {
      putString(frame, row, 3, label, 'muted');
      putString(frame, row, 18, truncate(value, ctx.cols - 20));
      row += 1;
    }
  } else if (p?.sessionId) {
    putString(frame, row, 3, 'Session present; canonical query not yet returned', 'muted');
  } else {
    putString(frame, row, 3, 'No active Session. Submit an intent below to start one.', 'muted');
  }
  if (p?.orphaned) {
    row += 1;
    putString(frame, row, 3, '⚠ session is ORPHANED — see Kiln for reconciliation', 'warn');
  }
  if (p?.lastError) {
    row += 1;
    putString(frame, row, 3, `last error: ${truncate(p.lastError, ctx.cols - 16)}`, 'error');
  }
  if (state.submitState === 'error' && state.submitError) {
    row += 1;
    putString(frame, row, 3, `submit failed: ${truncate(state.submitError, ctx.cols - 16)}`, 'error');
  }
  row += 1;

  // Intent input box
  row = ctx.rows - 4;
  putLabeledBox(frame, { rect: { row, col: 1, rows: 3, cols: ctx.cols - 2 }, title: 'INTENT' });
  row += 1;
  const promptText = state.input.prompt;
  const valueLines = wrapText(state.input.value, ctx.cols - 6);
  putString(frame, row, 3, promptText, 'accent');
  if (valueLines.length > 0 && valueLines[0]) {
    const first = valueLines[0] ?? '';
    putString(frame, row, 3 + promptText.length, first.slice(Math.max(0, valueLines[0].length - (ctx.cols - 6 - promptText.length))), 'input_focused');
  }
  if (valueLines.length > 1) {
    for (let i = 1; i < valueLines.length && i < 1; i += 1) {
      const line = valueLines[i] ?? '';
      putString(frame, row, 3, line.slice(0, ctx.cols - 6), 'input_focused');
    }
  }

  // Footer
  const footer = ' Enter submit · esc clear · ctrl-k palette · q quit · ctrl-c interrupt ';
  putString(frame, ctx.rows - 1, 0, pad(footer, ctx.cols), 'footer');
  void bodyHeight;
  return frame;
}

/** Splash view — the big block-letter TEMPER + powered-by hierarchy.
 *  Shown until the WorkbenchConnection has produced a hydrated
 *  canonical projection. Uses default-fg colors so it adapts to
 *  both light and dark terminals. */
function renderSplash(frame: Frame, ctx: ScreenContext, state: HomeState): Frame {
  const cols = ctx.cols;
  const rows = ctx.rows;

  // Center the TEMPER block horizontally. The block is 56 cols wide.
  const blockW = TEMPER_BLOCK[0]?.length ?? 56;
  const blockStartCol = Math.max(0, Math.floor((cols - blockW) / 2));

  // Vertical placement: 4 rows from the top.
  const blockStartRow = 4;

  for (let i = 0; i < TEMPER_BLOCK.length; i += 1) {
    const row = TEMPER_BLOCK[i];
    if (!row) continue;
    putString(frame, blockStartRow + i, blockStartCol, row, 'wordmark');
  }

  // Powered-by hierarchy, centered below the block.
  const afterBlockRow = blockStartRow + TEMPER_BLOCK.length + 1;
  if (afterBlockRow < rows - 1) {
    const poweredCol = Math.max(0, Math.floor((cols - SPLASH_POWERED_BY.length) / 2));
    putString(frame, afterBlockRow, poweredCol, SPLASH_POWERED_BY, 'wordmark_dim');
  }
  const productsRow = afterBlockRow + 1;
  if (productsRow < rows - 1) {
    const productsCol = Math.max(0, Math.floor((cols - SPLASH_PRODUCTS.length) / 2));
    putString(frame, productsRow, productsCol, SPLASH_PRODUCTS, 'muted');
  }

  // Status line near the bottom: hydrating or error.
  const statusRow = Math.max(productsRow + 2, rows - 4);
  const status = state.projection?.lastError
    ? `last error: ${truncate(state.projection.lastError, Math.max(8, cols - 14))}`
    : state.hydrated
      ? 'awaiting canonical Session…'
      : 'discovering Kiln…';
  const statusCol = Math.max(0, Math.floor((cols - status.length) / 2));
  putString(frame, statusRow, statusCol, status, state.projection?.lastError ? 'error' : 'muted');

  // Footer with the same keyboard hints.
  const footer = ' any key to continue · ctrl-c to quit ';
  putString(frame, rows - 1, 0, pad(footer, cols), 'footer');
  return frame;
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

function formatSession(id: string | null): string {
  if (!id) return '—';
  if (id.length <= 12) return id;
  return `${id.slice(0, 3)}…${id.slice(-6)}`;
}

function connectionGlyph(state: WorkbenchProjection['connection']): string {
  if (state === 'connected') return '●';
  if (state === 'reconnecting') return '◌';
  return '○';
}

// expose input helpers for the screen caller
export { focusInput, pushInputHistory, setInputValue, setPrompt };
