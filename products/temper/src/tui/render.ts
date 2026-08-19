/**
 * Temper Workbench Alpha — frame renderer.
 *
 * Converts a Frame to the ANSI byte stream the terminal expects.
 * Optimized: it produces a single string for the entire frame and
 * emits one write per frame.
 *
 * Style classes map to a small palette:
 *   - normal      default fg
 *   - bold        bold
 *   - dim         dim
 *   - header      bold + accent
 *   - footer      dim
 *   - success     green
 *   - warn        yellow
 *   - error       red
 *   - muted       dim
 *   - accent      bold
 *   - border      dim
 *   - input_focused bold
 *   - input_unfocused normal
 */

import type { Cell, Frame, Style } from './frame.js';

const STYLE_TO_ANSI: Record<Style, string> = {
  normal: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  header: '\x1b[1;36m',
  footer: '\x1b[2m',
  success: '\x1b[32m',
  warn: '\x1b[33m',
  error: '\x1b[31m',
  muted: '\x1b[2m',
  accent: '\x1b[1m',
  border: '\x1b[2m',
  input_focused: '\x1b[1m',
  input_unfocused: '\x1b[0m',
  // Wordmark: default foreground (SGR 39) so it adapts to the
  // terminal's color scheme — white on dark, black on light.
  wordmark: '\x1b[1;39m',
  wordmark_dim: '\x1b[2;39m'
};

const MOVE_CURSOR_HOME = '\x1b[H';
const HIDE_CURSOR = '\x1b[?25l';
const SHOW_CURSOR = '\x1b[?25h';
const CLEAR_SCREEN = '\x1b[2J';

export function renderFrame(frame: Frame): string {
  let out = `${MOVE_CURSOR_HOME}${HIDE_CURSOR}`;
  let currentStyle: Style | null = null;
  for (let r = 0; r < frame.rows; r += 1) {
    for (let c = 0; c < frame.cols; c += 1) {
      const cell = frame.cells[r]?.[c];
      if (!cell) continue;
      if (cell.style !== currentStyle) {
        out += STYLE_TO_ANSI[cell.style];
        currentStyle = cell.style;
      }
      out += cell.char;
    }
    if (r < frame.rows - 1) out += '\r\n';
  }
  out += STYLE_TO_ANSI.normal;
  return out;
}

export const ANSI = {
  MOVE_CURSOR_HOME,
  HIDE_CURSOR,
  SHOW_CURSOR,
  CLEAR_SCREEN
} as const;

/** Used by tests to extract visible text. */
export function frameToText(frame: Frame): string {
  const lines: string[] = [];
  for (let r = 0; r < frame.rows; r += 1) {
    let line = '';
    for (let c = 0; c < frame.cols; c += 1) {
      const cell = frame.cells[r]?.[c];
      line += cell?.char ?? ' ';
    }
    lines.push(line.replace(/\s+$/, ''));
  }
  // Trim trailing empty lines.
  while (lines.length > 0 && lines[lines.length - 1] === '') {
    lines.pop();
  }
  return lines.join('\n');
}

/** Used by tests to extract a single cell at (row, col). */
export function cellAt(frame: Frame, row: number, col: number): Cell | undefined {
  if (row < 0 || row >= frame.rows) return undefined;
  if (col < 0 || col >= frame.cols) return undefined;
  return frame.cells[row]?.[col];
}
