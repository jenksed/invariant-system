/**
 * Temper Workbench Alpha — Home/Resume screen.
 *
 * The first screen after `temper .` opens. Renders project identity,
 * last canonical state, and an intent/command input. Free text starts a real
 * Session; `/...` is routed through the deterministic operator command surface.
 *
 * Authority rule: the screen renders only what the WorkbenchConnection or
 * command executor reports. It never claims work is healthy / complete /
 * authorized on its own.
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

export interface HomeCommandResult {
  ok: boolean;
  lines: string[];
}

export interface HomeDeps {
  /** Called when the operator submits free-text intent. */
  onSubmitIntent: (intent: string) => Promise<{ ok: true } | { ok: false; error: string }>;
  /** Called for deterministic slash commands. */
  onCommand?: (line: string) => Promise<HomeCommandResult>;
  /** Force a redraw after an asynchronous command result mutates screen state. */
  onInvalidate?: () => void;
  /** Optional richer palette hook. Ctrl-k still enters slash mode if absent. */
  onOpenPalette?: () => void;
}

export interface HomeState {
  projection: WorkbenchProjection | null;
  input: ReturnType<typeof createInputState>;
  submitState: 'idle' | 'submitting' | 'error';
  submitError: string;
  hydrated: boolean;
  commandState?: 'idle' | 'running' | 'success' | 'error';
  commandOutput?: string[];
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
      hydrated: false,
      commandState: 'idle',
      commandOutput: []
    }),
    view: (state, ctx) => renderHome(state as HomeState, ctx),
    update: (state, key, ctx) => updateHome(state as HomeState, key, ctx, deps)
  };
}

export function setHomeProjection(state: HomeState, projection: WorkbenchProjection): HomeState {
  return { ...state, projection, hydrated: true };
}

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
  if (key.kind === 'ctrl' && key.value === 'c') {
    return { state, msgs: [{ kind: 'quit' }] };
  }
  if (key.kind === 'char' && key.value === 'q' && state.input.value.length === 0 && state.submitState === 'idle') {
    return { state, msgs: [{ kind: 'quit' }] };
  }
  if (key.kind === 'escape') {
    if (state.input.value.length > 0) {
      return { state: { ...state, input: setInputValue(state.input, '') }, msgs: [] };
    }
    return { state, msgs: [] };
  }
  if (key.kind === 'ctrl' && key.value === 'k') {
    deps.onOpenPalette?.();
    if (state.input.value.length === 0) {
      return {
        state: { ...state, input: setPrompt(setInputValue(state.input, '/'), 'cmd> ') },
        msgs: []
      };
    }
    return { state, msgs: [] };
  }

  if (key.kind === 'enter' && state.input.value.length > 0 && state.submitState === 'idle') {
    const value = state.input.value.trim();
    if (value.length === 0) return { state, msgs: [] };
    if (value.startsWith('/') && deps.onCommand) {
      return beginCommand(state, value, deps);
    }
    void submitIntent(state, value, deps);
    return {
      state: { ...state, submitState: 'submitting', input: setPrompt(state.input, '… submitting') },
      msgs: []
    };
  }

  const result = updateInput(state.input, key);
  if (result.msgs.some((m) => m.kind === 'submit') && state.submitState === 'idle') {
    const value = result.state.value.trim();
    if (value.length > 0) {
      if (value.startsWith('/') && deps.onCommand) {
        return beginCommand({ ...state, input: result.state }, value, deps);
      }
      void submitIntent(state, value, deps);
      return {
        state: { ...state, submitState: 'submitting', input: result.state },
        msgs: []
      };
    }
  }
  return { state: { ...state, input: result.state }, msgs: result.msgs };
}

function beginCommand(
  state: HomeState,
  line: string,
  deps: HomeDeps
): { state: HomeState; msgs: ScreenMsg[] } {
  state.commandState = 'running';
  state.commandOutput = [`> ${line}`, 'running…'];
  state.input = setPrompt(setInputValue(state.input, ''), '> ');
  void submitCommand(state, line, deps);
  return { state, msgs: [] };
}

async function submitCommand(state: HomeState, line: string, deps: HomeDeps): Promise<void> {
  if (!deps.onCommand) return;
  try {
    const result = await deps.onCommand(line);
    state.commandState = result.ok ? 'success' : 'error';
    state.commandOutput = [`> ${line}`, ...result.lines];
  } catch (error) {
    state.commandState = 'error';
    state.commandOutput = [`> ${line}`, `command failed: ${error instanceof Error ? error.message : String(error)}`];
  }
  deps.onInvalidate?.();
}

async function submitIntent(state: HomeState, intent: string, deps: HomeDeps): Promise<void> {
  const result = await deps.onSubmitIntent(intent);
  if (result.ok) return;
  state.submitState = 'error';
  state.submitError = result.error;
  deps.onInvalidate?.();
}

export function setHomeSubmitError(state: HomeState, error: string): HomeState {
  return {
    ...state,
    submitState: 'error',
    submitError: error,
    input: setInputValue(state.input, ''),
    inputFocused: true
  } as HomeState;
}

function renderHome(state: HomeState, ctx: ScreenContext): Frame {
  const frame = createFrame(ctx.cols, ctx.rows);
  const p = state.projection;
  const showSplash = !state.hydrated || !p;
  if (showSplash) return renderSplash(frame, ctx, state);

  putString(frame, 0, 0, ' ◆ TEMPER ', 'wordmark');
  const headerRight = `Session ${formatSession(p.sessionId)}  ·  ${connectionGlyph(p.connection)}`;
  putString(frame, 0, ctx.cols - headerRight.length - 1, headerRight, 'header');
  const leftLine = ` project  ${truncate(p.repository, Math.max(8, ctx.cols - 30))}`;
  putString(frame, 1, 0, leftLine, 'muted');
  const rightLine = `kiln ${truncate(p.kilnHome, Math.max(8, ctx.cols - leftLine.length - 8))} `;
  putString(frame, 1, Math.max(0, ctx.cols - rightLine.length - 1), rightLine, 'muted');
  putString(frame, 2, 0, '─'.repeat(ctx.cols), 'border');

  const bodyTop = 4;
  let row = bodyTop;
  putLabeledBox(frame, { rect: { row, col: 1, rows: 6, cols: ctx.cols - 2 }, title: 'PROJECT' });
  row += 1;
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
  row += 2;

  putLabeledBox(frame, { rect: { row, col: 1, rows: 7, cols: ctx.cols - 2 }, title: 'LAST CANONICAL STATE' });
  row += 1;
  if (p.sessionQuery) {
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
  } else if (p.sessionId) {
    putString(frame, row, 3, 'Session present; canonical query not yet returned', 'muted');
  } else {
    putString(frame, row, 3, 'No active Session. Submit an intent or /new below.', 'muted');
  }
  if (p.orphaned) {
    row += 1;
    putString(frame, row, 3, '⚠ session is ORPHANED — see Kiln for reconciliation', 'warn');
  }
  if (p.lastError) {
    row += 1;
    putString(frame, row, 3, `last error: ${truncate(p.lastError, ctx.cols - 16)}`, 'error');
  }
  if (state.submitState === 'error' && state.submitError) {
    row += 1;
    putString(frame, row, 3, `submit failed: ${truncate(state.submitError, ctx.cols - 16)}`, 'error');
  }

  const commandLines = state.commandOutput ?? [];
  const commandTop = row + 1;
  const inputTop = ctx.rows - 4;
  if (commandLines.length > 0 && commandTop + 3 < inputTop) {
    const rows = Math.min(6, inputTop - commandTop);
    const title = state.commandState === 'error' ? 'COMMAND · ERROR' : 'COMMAND';
    putLabeledBox(frame, { rect: { row: commandTop, col: 1, rows, cols: ctx.cols - 2 }, title });
    const visible = commandLines.slice(-Math.max(1, rows - 2));
    for (let i = 0; i < visible.length; i += 1) {
      putString(
        frame,
        commandTop + 1 + i,
        3,
        truncate(visible[i] ?? '', ctx.cols - 6),
        state.commandState === 'error' ? 'error' : 'dim'
      );
    }
  }

  row = inputTop;
  putLabeledBox(frame, { rect: { row, col: 1, rows: 3, cols: ctx.cols - 2 }, title: 'INTENT / COMMAND' });
  row += 1;
  const promptText = state.input.prompt;
  const inputWidth = Math.max(1, ctx.cols - 6);
  const valueLines = wrapText(state.input.value, inputWidth);
  putString(frame, row, 3, promptText, 'accent');
  const visibleTail = valueLines[valueLines.length - 1] ?? '';
  putString(
    frame,
    row,
    3 + promptText.length,
    visibleTail.slice(Math.max(0, visibleTail.length - (inputWidth - promptText.length))),
    'input_focused'
  );

  const footer = ' Enter submit · / command · ctrl-k command · esc clear · q quit · ctrl-c interrupt ';
  putString(frame, ctx.rows - 1, 0, pad(footer, ctx.cols), 'footer');
  return frame;
}

function renderSplash(frame: Frame, ctx: ScreenContext, state: HomeState): Frame {
  const cols = ctx.cols;
  const rows = ctx.rows;
  const blockW = TEMPER_BLOCK[0]?.length ?? 56;
  const blockStartCol = Math.max(0, Math.floor((cols - blockW) / 2));
  const blockStartRow = 4;

  for (let i = 0; i < TEMPER_BLOCK.length; i += 1) {
    const row = TEMPER_BLOCK[i];
    if (!row) continue;
    putString(frame, blockStartRow + i, blockStartCol, row, 'wordmark');
  }

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

  const statusRow = Math.max(productsRow + 2, rows - 4);
  const status = state.projection?.lastError
    ? `last error: ${truncate(state.projection.lastError, Math.max(8, cols - 14))}`
    : state.hydrated
      ? 'awaiting canonical Session…'
      : 'discovering Kiln…';
  const statusCol = Math.max(0, Math.floor((cols - status.length) / 2));
  putString(frame, statusRow, statusCol, status, state.projection?.lastError ? 'error' : 'muted');

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

export { focusInput, pushInputHistory, setInputValue, setPrompt };
