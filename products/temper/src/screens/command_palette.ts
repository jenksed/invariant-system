/** Shared deterministic operator command palette. */

import { createInputState, focusInput, setInputValue, updateInput } from '../tui/input.js';
import { createFrame, putLabeledBox, putString } from '../tui/frame.js';
import type { Frame } from '../tui/frame.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from '../tui/screen.js';

export interface CommandPaletteResult {
  ok: boolean;
  lines: string[];
}

export interface CommandPaletteDeps {
  onCommand: (line: string) => Promise<CommandPaletteResult>;
  onInvalidate?: () => void;
}

export interface CommandPaletteState {
  input: ReturnType<typeof createInputState>;
  state: 'idle' | 'running' | 'success' | 'error';
  output: string[];
}

export function createCommandPaletteScreen(deps: CommandPaletteDeps): ScreenSpec {
  return {
    id: 'command-palette',
    title: 'Command',
    overlay: true,
    init: (): CommandPaletteState => ({
      input: focusInput(createInputState({ prompt: 'cmd> ', initial: '/', maxChars: 4096 }), true),
      state: 'idle',
      output: ['Type /help for the live command registry.']
    }),
    view: (state, ctx) => render(state as CommandPaletteState, ctx),
    update: (state, key) => update(state as CommandPaletteState, key, deps)
  };
}

function update(
  state: CommandPaletteState,
  key: Key,
  deps: CommandPaletteDeps
): { state: CommandPaletteState; msgs: ScreenMsg[] } {
  if (key.kind === 'escape') return { state, msgs: [{ kind: 'pop' }] };
  if (key.kind === 'ctrl' && key.value === 'c') return { state, msgs: [{ kind: 'quit' }] };
  if (key.kind === 'char' && key.value === 'q' && state.input.value.length === 0) {
    return { state, msgs: [{ kind: 'pop' }] };
  }
  if (key.kind === 'enter' && state.state !== 'running') {
    const line = state.input.value.trim();
    if (line.length === 0 || line === '/') return { state, msgs: [] };
    state.state = 'running';
    state.output = [`> ${line}`, 'running…'];
    state.input = setInputValue(state.input, '');
    void execute(state, line, deps);
    return { state, msgs: [] };
  }
  const result = updateInput(state.input, key);
  return { state: { ...state, input: result.state }, msgs: [] };
}

async function execute(state: CommandPaletteState, line: string, deps: CommandPaletteDeps): Promise<void> {
  try {
    const result = await deps.onCommand(line);
    state.state = result.ok ? 'success' : 'error';
    state.output = [`> ${line}`, ...result.lines];
  } catch (error) {
    state.state = 'error';
    state.output = [`> ${line}`, `command failed: ${error instanceof Error ? error.message : String(error)}`];
  }
  deps.onInvalidate?.();
}

function render(state: CommandPaletteState, ctx: ScreenContext): Frame {
  const frame = createFrame(ctx.cols, ctx.rows);
  const width = Math.max(40, Math.min(ctx.cols - 4, 96));
  const height = Math.max(10, Math.min(ctx.rows - 4, 18));
  const top = Math.max(1, Math.floor((ctx.rows - height) / 2));
  const left = Math.max(1, Math.floor((ctx.cols - width) / 2));
  const title = state.state === 'error' ? 'COMMAND · ERROR' : 'COMMAND PALETTE';
  putLabeledBox(frame, { rect: { row: top, col: left, rows: height, cols: width }, title });
  putString(frame, top + 1, left + 2, state.input.prompt, 'accent');
  putString(frame, top + 1, left + 2 + state.input.prompt.length, truncate(state.input.value, width - 8), 'input_focused');
  putString(frame, top + 2, left + 1, '─'.repeat(Math.max(1, width - 2)), 'border');
  const availableRows = Math.max(1, height - 5);
  const visible = state.output.slice(-availableRows);
  for (let i = 0; i < visible.length; i += 1) {
    putString(frame, top + 3 + i, left + 2, truncate(visible[i] ?? '', width - 5), state.state === 'error' ? 'error' : 'dim');
  }
  putString(frame, top + height - 1, left + 2, ' Enter run · esc close · ctrl-c quit ', 'footer');
  return frame;
}

function truncate(text: string, width: number): string {
  if (text.length <= width) return text;
  return width <= 1 ? text.slice(0, width) : `${text.slice(0, width - 1)}…`;
}
