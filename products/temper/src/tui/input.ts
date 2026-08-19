/**
 * Temper Workbench Alpha — input widget.
 *
 * Single-line and multiline text editing on top of raw mode stdin.
 * The widget is a pure state machine: (state, Key) → (state, ScreenMsg[]).
 *
 * Editing conventions:
 *   - Enter submits (returns a 'submit' ScreenMsg).
 *   - Backspace deletes the char before the cursor.
 *   - Left/Right move the cursor within the current line.
 *   - Up/Down move through input history (the screen owns history).
 *   - ctrl+a / ctrl+e jump to start / end of the line.
 *   - ctrl+k clears from cursor to end of line.
 *   - ctrl+u clears the line.
 *   - alt+Enter (or paste that contains \n) inserts a newline for
 *     multiline input.
 */

import type { Key, ScreenMsg } from './screen.js';

export interface InputState {
  /** Buffer; may contain newlines for multiline. */
  value: string;
  /** Cursor offset in chars within the value. */
  cursor: number;
  /** Currently in multiline mode. */
  multiline: boolean;
  /** When focused, the input is the active widget. */
  focused: boolean;
  /** Prompt label shown to the left of the cursor. */
  prompt: string;
  /** History (most recent first). The widget does not own it; the
   *  screen pushes/pops entries through `consumeHistory/1` and
   *  `pushHistory/1`. */
  history: string[];
  /** Current history index while navigating. -1 means not navigating. */
  historyIndex: number;
  /** Saved buffer when entering history navigation. */
  historySaved: string;
  /** Max chars accepted (defense in depth). */
  maxChars: number;
}

export function createInputState(options: {
  prompt: string;
  multiline?: boolean;
  initial?: string;
  history?: string[];
  maxChars?: number;
}): InputState {
  return {
    value: options.initial ?? '',
    cursor: (options.initial ?? '').length,
    multiline: options.multiline ?? false,
    focused: false,
    prompt: options.prompt,
    history: options.history ?? [],
    historyIndex: -1,
    historySaved: '',
    maxChars: options.maxChars ?? 16_384
  };
}

export function focusInput(state: InputState, focused: boolean): InputState {
  return { ...state, focused };
}

export function setInputValue(state: InputState, value: string): InputState {
  const clipped = value.length > state.maxChars ? value.slice(0, state.maxChars) : value;
  return { ...state, value: clipped, cursor: clipped.length, historyIndex: -1, historySaved: '' };
}

export function setPrompt(state: InputState, prompt: string): InputState {
  return { ...state, prompt };
}

function clampCursor(state: InputState): number {
  if (state.cursor < 0) return 0;
  if (state.cursor > state.value.length) return state.value.length;
  return state.cursor;
}

function moveToPrevLine(state: InputState, delta: -1 | 1): InputState {
  if (!state.multiline) {
    // delta = -1 for "up" should walk toward older history entries.
    return navigateHistory(state, delta);
  }
  // Find the line containing the cursor.
  const before = state.value.slice(0, state.cursor);
  const lineStart = before.lastIndexOf('\n') + 1;
  const col = state.cursor - lineStart;
  if (delta === -1) {
    if (lineStart === 0) return state;
    const prevBreak = state.value.lastIndexOf('\n', lineStart - 2);
    const prevStart = prevBreak === -1 ? 0 : prevBreak + 1;
    const prevLen = lineStart - 1 - prevStart;
    const newCol = Math.min(col, prevLen);
    return { ...state, cursor: prevStart + newCol };
  }
  // Down
  const lineEnd = state.value.indexOf('\n', lineStart);
  if (lineEnd === -1) return state;
  const nextStart = lineEnd + 1;
  if (nextStart >= state.value.length) return state;
  const nextBreak = state.value.indexOf('\n', nextStart);
  const nextEnd = nextBreak === -1 ? state.value.length : nextBreak;
  const nextLen = nextEnd - nextStart;
  const newCol = Math.min(col, nextLen);
  return { ...state, cursor: nextStart + newCol };
}

function navigateHistory(state: InputState, delta: -1 | 1): InputState {
  if (state.history.length === 0) return state;
  // delta = -1 (up): walk toward older history (higher index in the
  // ring, where history[0] is the most recent entry).
  // delta = +1 (down): walk toward newer entries; when we pass
  // history[0], restore the saved buffer.
  if (state.historyIndex === -1) {
    if (delta === 1) return state; // down with no entry → no-op
    return {
      ...state,
      historySaved: state.value,
      historyIndex: 0,
      value: state.history[0] ?? '',
      cursor: (state.history[0] ?? '').length
    };
  }
  if (delta === -1) {
    const nextIdx = state.historyIndex + 1;
    if (nextIdx >= state.history.length) return state; // already at oldest
    const v = state.history[nextIdx] ?? '';
    return { ...state, historyIndex: nextIdx, value: v, cursor: v.length };
  }
  // delta === +1 (down toward newer)
  const nextIdx = state.historyIndex - 1;
  if (nextIdx < 0) {
    return {
      ...state,
      historyIndex: -1,
      value: state.historySaved,
      cursor: state.historySaved.length
    };
  }
  const v = state.history[nextIdx] ?? '';
  return { ...state, historyIndex: nextIdx, value: v, cursor: v.length };
}

export function updateInput(state: InputState, key: Key): { state: InputState; msgs: ScreenMsg[] } {
  if (!state.focused) {
    return { state, msgs: [] };
  }
  const msgs: ScreenMsg[] = [];

  if (key.kind === 'char') {
    const next = state.value.slice(0, state.cursor) + key.value + state.value.slice(state.cursor);
    if (next.length > state.maxChars) {
      return { state, msgs: [{ kind: 'no_op' }] };
    }
    return { state: { ...state, value: next, cursor: state.cursor + key.value.length, historyIndex: -1, historySaved: '' }, msgs };
  }

  if (key.kind === 'paste') {
    const cleaned = state.multiline ? key.value : key.value.replace(/\n/g, ' ');
    const next = state.value.slice(0, state.cursor) + cleaned + state.value.slice(state.cursor);
    if (next.length > state.maxChars) {
      const clipped = next.slice(0, state.maxChars);
      return { state: { ...state, value: clipped, cursor: clipped.length }, msgs: [{ kind: 'no_op' }] };
    }
    return { state: { ...state, value: next, cursor: state.cursor + cleaned.length, historyIndex: -1, historySaved: '' }, msgs };
  }

  if (key.kind === 'enter') {
    if (state.value.length > 0) {
      msgs.push({ kind: 'submit', value: state.value });
    }
    return { state, msgs };
  }

  if (key.kind === 'backspace') {
    if (state.cursor === 0) return { state, msgs };
    const next = state.value.slice(0, state.cursor - 1) + state.value.slice(state.cursor);
    return { state: { ...state, value: next, cursor: state.cursor - 1, historyIndex: -1, historySaved: '' }, msgs };
  }

  if (key.kind === 'left') {
    return { state: { ...state, cursor: Math.max(0, state.cursor - 1) }, msgs };
  }
  if (key.kind === 'right') {
    return { state: { ...state, cursor: Math.min(state.value.length, state.cursor + 1) }, msgs };
  }
  if (key.kind === 'up' || key.kind === 'down') {
    return { state: moveToPrevLine(state, key.kind === 'up' ? -1 : 1), msgs };
  }
  if (key.kind === 'home') {
    return { state: { ...state, cursor: 0 }, msgs };
  }
  if (key.kind === 'end') {
    return { state: { ...state, cursor: state.value.length }, msgs };
  }
  if (key.kind === 'ctrl') {
    if (key.value === 'a') return { state: { ...state, cursor: 0 }, msgs };
    if (key.value === 'e') return { state: { ...state, cursor: state.value.length }, msgs };
    if (key.value === 'k') {
      const next = state.value.slice(0, state.cursor);
      return { state: { ...state, value: next, cursor: next.length }, msgs };
    }
    if (key.value === 'u') {
      return { state: { ...state, value: '', cursor: 0 }, msgs };
    }
  }
  return { state, msgs };
}

export function pushInputHistory(state: InputState, value: string): InputState {
  if (value.length === 0) return state;
  const next = [value, ...state.history.filter((entry) => entry !== value)].slice(0, 50);
  return { ...state, history: next, historyIndex: -1, historySaved: '' };
}
