/**
 * Temper Workbench Alpha — frame buffer.
 *
 * A Frame is a 2D grid of cells. Each cell carries a single character
 * and an optional style class. Frames are built by screens, blitted to
 * stdout by the runtime.
 *
 * Frames are intentionally simple: rows × cols, no scrollback, no
 * partial repaint. The runtime diffs by full clear-and-rewrite.
 */

/** A semantic style class. Rendered to ANSI by the runtime. */
export type Style =
  | 'normal'
  | 'bold'
  | 'dim'
  | 'header'
  | 'footer'
  | 'success'
  | 'warn'
  | 'error'
  | 'muted'
  | 'accent'
  | 'border'
  | 'input_focused'
  | 'input_unfocused'
  | 'wordmark'
  | 'wordmark_dim';

export interface Cell {
  char: string;
  style: Style;
}

export interface Frame {
  cols: number;
  rows: number;
  cells: Cell[][];
}

export function createFrame(cols: number, rows: number): Frame {
  const cells: Cell[][] = [];
  for (let r = 0; r < rows; r += 1) {
    const row: Cell[] = [];
    for (let c = 0; c < cols; c += 1) {
      row.push({ char: ' ', style: 'normal' });
    }
    cells.push(row);
  }
  return { cols, rows, cells };
}

function clamp(n: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, n));
}

export function putChar(frame: Frame, row: number, col: number, char: string, style: Style = 'normal'): void {
  if (row < 0 || row >= frame.rows) return;
  if (col < 0 || col >= frame.cols) return;
  if (char.length === 0) return;
  const rowCells = frame.cells[row];
  if (!rowCells) return;
  // Only single-cell width supported here; multi-char sequences are
  // split — callers that need them should iterate.
  rowCells[col] = { char: char[0] ?? ' ', style };
}

export function putString(frame: Frame, row: number, col: number, text: string, style: Style = 'normal'): void {
  if (row < 0 || row >= frame.rows) return;
  const rowCells = frame.cells[row];
  if (!rowCells) return;
  let c = col;
  for (let i = 0; i < text.length; i += 1) {
    if (c >= frame.cols) return;
    const ch = text[i];
    if (ch === undefined) continue;
    rowCells[c] = { char: ch, style };
    c += 1;
  }
}

export interface Rect {
  row: number;
  col: number;
  rows: number;
  cols: number;
}

export function putRect(frame: Frame, rect: Rect): void {
  const top = clamp(rect.row, 0, frame.rows);
  const bottom = clamp(rect.row + rect.rows, 0, frame.rows);
  const left = clamp(rect.col, 0, frame.cols);
  const right = clamp(rect.col + rect.cols, 0, frame.cols);
  for (let r = top; r < bottom; r += 1) {
    const rowCells = frame.cells[r];
    if (!rowCells) continue;
    for (let c = left; c < right; c += 1) {
      rowCells[c] = { char: ' ', style: 'border' };
    }
  }
}

export function putBorder(frame: Frame, rect: Rect, style: Style = 'border'): void {
  const top = clamp(rect.row, 0, frame.rows);
  const bottom = clamp(rect.row + rect.rows - 1, 0, frame.rows - 1);
  const left = clamp(rect.col, 0, frame.cols);
  const right = clamp(rect.col + rect.cols - 1, 0, frame.cols - 1);
  if (rect.cols < 2 || rect.rows < 2) return;

  // Corners
  putChar(frame, top, left, '┌', style);
  putChar(frame, top, right, '┐', style);
  putChar(frame, bottom, left, '└', style);
  putChar(frame, bottom, right, '┘', style);
  // Edges
  for (let c = left + 1; c < right; c += 1) {
    putChar(frame, top, c, '─', style);
    putChar(frame, bottom, c, '─', style);
  }
  for (let r = top + 1; r < bottom; r += 1) {
    putChar(frame, r, left, '│', style);
    putChar(frame, r, right, '│', style);
  }
}

export interface LabeledBox {
  rect: Rect;
  title: string;
}

export function putLabeledBox(frame: Frame, box: LabeledBox, style: Style = 'border', titleStyle: Style = 'header'): void {
  putRect(frame, box.rect);
  putBorder(frame, box.rect, style);
  putString(frame, box.rect.row, box.rect.col + 2, ` ${box.title} `, titleStyle);
}

/** Wrap text to a given width, breaking on whitespace when possible. */
export function wrapText(text: string, width: number): string[] {
  if (width <= 0) return [];
  if (text.length === 0) return [''];
  const lines: string[] = [];
  for (const raw of text.split('\n')) {
    if (raw.length === 0) {
      lines.push('');
      continue;
    }
    let current = '';
    for (const word of raw.split(' ')) {
      if (word.length === 0) {
        current += ' ';
        continue;
      }
      if (current.length === 0) {
        current = word;
      } else if (current.length + 1 + word.length <= width) {
        current = `${current} ${word}`;
      } else {
        lines.push(current);
        current = word;
      }
    }
    if (current.length > 0) lines.push(current);
  }
  return lines;
}
