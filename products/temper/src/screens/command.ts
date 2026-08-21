import {
  createInputState,
  focusInput,
  pushInputHistory,
  setInputValue,
  updateInput,
  type InputState
} from '../tui/input.js';
import { createFrame, putLabeledBox, putString, wrapText, type Frame } from '../tui/frame.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from '../tui/screen.js';
import { commandSuggestions, type CommandResult } from '../workbench/commands.js';

export interface CommandScreenDeps {
  initial?: string;
  executeOnOpen?: boolean;
  execute: (input: string) => Promise<CommandResult>;
  invalidate: () => void;
  onOpenDiff: () => void;
  onQuit: () => void;
}

export interface CommandScreenState {
  input: InputState;
  running: boolean;
  result: CommandResult | null;
}

export function createCommandScreen(deps: CommandScreenDeps): ScreenSpec {
  return {
    id: 'commands',
    title: 'Commands',
    init: () => {
      const initial = deps.initial ?? '/';
      const state: CommandScreenState = {
        input: focusInput(createInputState({ prompt: '> ', initial, history: [] }), true),
        running: false,
        result: null
      };
      if (deps.executeOnOpen && initial.trim().length > 1) {
        state.running = true;
        queueMicrotask(() => void runCommand(state, initial, deps));
      }
      return state;
    },
    view: (state, ctx) => renderCommandScreen(state as CommandScreenState, ctx),
    update: (state, key, ctx) => updateCommandScreen(state as CommandScreenState, key, ctx, deps)
  };
}

function updateCommandScreen(
  state: CommandScreenState,
  key: Key,
  _ctx: ScreenContext,
  deps: CommandScreenDeps
): { state: CommandScreenState; msgs: ScreenMsg[] } {
  // A command may be carrying a real Kiln mutation. Keep the console
  // attached and input-locked until the bounded result returns. Temper has
  // no generic RPC cancellation contract, so Ctrl-C must not pretend it can
  // cancel an already-dispatched operation.
  if (state.running) return { state, msgs: [] };

  if (key.kind === 'ctrl' && key.value === 'c') return { state, msgs: [{ kind: 'quit' }] };
  if (key.kind === 'escape') return { state, msgs: [{ kind: 'pop' }] };

  if (key.kind === 'enter') {
    const value = state.input.value.trim();
    if (value.length === 0) return { state, msgs: [] };
    state.running = true;
    state.result = null;
    void runCommand(state, value, deps);
    return { state, msgs: [] };
  }

  const updated = updateInput(state.input, key);
  return { state: { ...state, input: updated.state }, msgs: updated.msgs.filter((msg) => msg.kind !== 'submit') };
}

async function runCommand(state: CommandScreenState, value: string, deps: CommandScreenDeps): Promise<void> {
  const result = await deps.execute(value);
  state.running = false;
  state.result = result;
  state.input = setInputValue(pushInputHistory(state.input, value), '/');
  deps.invalidate();
  if (result.action === 'open_diff') deps.onOpenDiff();
  if (result.action === 'quit') deps.onQuit();
}

function renderCommandScreen(state: CommandScreenState, ctx: ScreenContext): Frame {
  const frame = createFrame(ctx.cols, ctx.rows);
  putString(frame, 0, 0, ' ◆ TEMPER ', 'wordmark');
  putString(frame, 0, Math.max(0, ctx.cols - 20), 'COMMAND CONSOLE ', 'header');
  putString(frame, 2, 0, '─'.repeat(ctx.cols), 'border');

  putLabeledBox(frame, { rect: { row: 4, col: 1, rows: 3, cols: Math.max(10, ctx.cols - 2) }, title: 'COMMAND' });
  const prompt = state.running ? '… ' : state.input.prompt;
  putString(frame, 5, 3, prompt, state.running ? 'muted' : 'accent');
  putString(frame, 5, 3 + prompt.length, truncate(state.input.value, Math.max(1, ctx.cols - prompt.length - 7)), 'input_focused');

  let row = 8;
  if (state.result) {
    const label = state.result.ok ? state.result.title : `${state.result.title} [${state.result.code ?? 'E_COMMAND_FAILED'}]`;
    const boxRows = Math.max(5, ctx.rows - row - 3);
    putLabeledBox(frame, { rect: { row, col: 1, rows: boxRows, cols: Math.max(10, ctx.cols - 2) }, title: label });
    row += 1;
    const style = state.result.ok ? 'normal' : 'error';
    for (const line of state.result.lines) {
      for (const wrapped of wrapText(line, Math.max(8, ctx.cols - 7))) {
        if (row >= ctx.rows - 3) break;
        putString(frame, row, 3, wrapped, style);
        row += 1;
      }
      if (row >= ctx.rows - 3) break;
    }
  } else {
    const suggestions = commandSuggestions(state.input.value);
    putLabeledBox(frame, { rect: { row, col: 1, rows: Math.max(5, ctx.rows - row - 3), cols: Math.max(10, ctx.cols - 2) }, title: 'AVAILABLE' });
    row += 1;
    for (const suggestion of suggestions) {
      if (row >= ctx.rows - 3) break;
      putString(frame, row, 3, truncate(suggestion, Math.max(8, ctx.cols - 7)), 'muted');
      row += 1;
    }
  }

  const footer = state.running
    ? ' command in flight · input locked until bounded result '
    : ' Enter execute · ↑/↓ history · esc back · ctrl-c quit ';
  putString(frame, ctx.rows - 1, 0, pad(footer, ctx.cols), 'footer');
  return frame;
}

function truncate(value: string, width: number): string {
  if (width <= 0) return '';
  if (value.length <= width) return value;
  if (width <= 1) return '…'.slice(0, width);
  return `${value.slice(0, width - 1)}…`;
}

function pad(value: string, width: number): string {
  if (value.length >= width) return value.slice(0, width);
  return value + ' '.repeat(width - value.length);
}
