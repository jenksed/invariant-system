/**
 * Temper Workbench Alpha — TUI runtime.
 *
 * Owns:
 *   - alt-screen enter/exit
 *   - raw mode + signal handling
 *   - keypress parsing
 *   - screen state stack (push / pop / replace)
 *   - render loop
 *
 * Does NOT own:
 *   - workflow authority (every screen is a projection of Kiln state)
 *   - terminal capability detection beyond the stdlib
 *
 * The runtime is screen-agnostic. A screen is a {id, title, view,
 * update, init, overlay?} value; the runtime maintains a stack of
 * {screen, state} pairs. On each keypress, the top screen's update is
 * called. The top screen's view is blitted. Overlay screens are
 * rendered on top of the previous screen.
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { createKeypressParser, type KeypressParser } from './keypress.js';
import { ANSI, frameToText, renderFrame } from './render.js';
import type { Cell, Frame } from './frame.js';
import { createFrame } from './frame.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from './screen.js';

export interface RuntimeOptions {
  /** Output stream; defaults to process.stdout. */
  out?: NodeJS.WritableStream;
  /** Input stream; defaults to process.stdin. */
  input?: NodeJS.ReadableStream;
  /** Whether to use the alt-screen buffer. Defaults to true. */
  altScreen?: boolean;
  /** Initial cols. */
  cols?: number;
  /** Initial rows. */
  rows?: number;
  /** Directory to write milestone snapshots to (plain-text frames).
   *  Defaults to undefined (no snapshots). When set, every render()
   *  that is preceded by a snapshot("label") call writes a file. */
  snapshotDir?: string;
}

interface StackEntry {
  screen: ScreenSpec;
  state: unknown;
}

export class TuiRuntime {
  private readonly out: NodeJS.WritableStream;
  private readonly input: NodeJS.ReadableStream;
  private readonly altScreen: boolean;
  private readonly parser: KeypressParser;
  private readonly stack: StackEntry[] = [];
  private readonly snapshotDir?: string;
  private cols: number;
  private rows: number;
  private closed = false;
  private attached = false;
  private onStdoutData?: (chunk: string) => void;
  private onStdinData?: (chunk: Buffer | string) => void;
  private onResize?: () => void;

  constructor(options: RuntimeOptions = {}) {
    this.out = options.out ?? process.stdout;
    this.input = options.input ?? process.stdin;
    this.altScreen = options.altScreen ?? true;
    this.cols = options.cols ?? (this.out as { columns?: number }).columns ?? 100;
    this.rows = options.rows ?? (this.out as { rows?: number }).rows ?? 30;
    this.parser = createKeypressParser();
    if (options.snapshotDir) {
      this.snapshotDir = options.snapshotDir;
    }
  }

  /** Push a new screen onto the stack and render. */
  push(screen: ScreenSpec): void {
    const initial = screen.init();
    this.stack.push({ screen, state: initial });
    this.attachInput();
    this.render();
  }

  /** Pop the top screen. */
  pop(): void {
    if (this.stack.length > 1) {
      this.stack.pop();
      this.render();
    }
  }

  /** Replace the top screen. */
  replace(screen: ScreenSpec): void {
    const initial = screen.init();
    if (this.stack.length === 0) {
      this.stack.push({ screen, state: initial });
    } else {
      this.stack[this.stack.length - 1] = { screen, state: initial };
    }
    this.render();
  }

  /** Update the top screen's state directly (used by external reducers). */
  setTopState(state: unknown): void {
    if (this.stack.length === 0) return;
    const top = this.stack[this.stack.length - 1];
    if (top) {
      top.state = state;
      this.render();
    }
  }

  /** Force a redraw. */
  invalidate(): void {
    this.render();
  }

  /** Snapshot the current frame as plain text to <snapshotDir>/<label>-<seq>.txt
   *  for case-study capture. Returns the file path written (or undefined
   *  if no snapshotDir was configured). The file is human-readable
   *  (no ANSI) and a faithful representation of the TUI at the moment
   *  of capture. */
  snapshot(label: string): string | undefined {
    if (!this.snapshotDir) return undefined;
    mkdirSync(this.snapshotDir, { recursive: true });
    const frame = this.compose();
    const text = frameToText(frame);
    const safeLabel = label.replace(/[^a-zA-Z0-9_-]+/g, '-').slice(0, 64) || 'frame';
    const seq = (snapshotCounter += 1).toString().padStart(4, '0');
    const path = join(this.snapshotDir, `${safeLabel}-${seq}.txt`);
    writeFileSync(path, `${text}\n`, 'utf8');
    return path;
  }

  /** Start the runtime: enable raw mode, install listeners. */
  start(): void {
    if (this.altScreen) {
      this.out.write('\x1b[?1049h');
    }
    this.out.write(ANSI.HIDE_CURSOR);

    const stdinAny = this.input as NodeJS.ReadableStream & {
      isTTY?: boolean;
      setRawMode?: (mode: boolean) => void;
    };
    if (stdinAny.isTTY && typeof stdinAny.setRawMode === 'function') {
      stdinAny.setRawMode(true);
    }
    this.attachInput();
    if (typeof this.out.on === 'function') {
      this.onResize = (): void => {
        const outAny = this.out as { columns?: number; rows?: number };
        if (typeof outAny.columns === 'number') this.cols = outAny.columns;
        if (typeof outAny.rows === 'number') this.rows = outAny.rows;
        this.render();
      };
      this.out.on('resize', this.onResize);
    }
  }

  /** Stop the runtime: restore terminal, close stream, remove listeners. */
  stop(): void {
    if (this.closed) return;
    this.closed = true;
    this.out.write(ANSI.SHOW_CURSOR);
    if (this.altScreen) {
      this.out.write('\x1b[?1049l');
    }
    const stdinAny = this.input as NodeJS.ReadableStream & {
      isTTY?: boolean;
      setRawMode?: (mode: boolean) => void;
    };
    if (stdinAny.isTTY && typeof stdinAny.setRawMode === 'function') {
      stdinAny.setRawMode(false);
    }
    this.input.off('data', this.handleData);
    if (this.onResize && typeof this.out.off === 'function') {
      this.out.off('resize', this.onResize);
    }
  }

  /** Install the input listener if not already installed. */
  private attachInput(): void {
    if (this.attached) return;
    this.attached = true;
    this.input.on('data', this.handleData);
  }

  /** Test seam: directly inject a key event without raw mode. */
  inject(key: Key): void {
    this.handleKey(key);
  }

  private handleData = (chunk: Buffer | string): void => {
    const data = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    for (const key of this.parser.feed(data)) {
      this.handleKey(key);
    }
  };

  private handleKey(key: Key): void {
    if (key.kind === 'resize') {
      this.cols = key.cols;
      this.rows = key.rows;
      this.render();
      return;
    }
    const top = this.stack[this.stack.length - 1];
    if (!top) return;
    const ctx: ScreenContext = {
      cols: this.cols,
      rows: this.rows,
      inputFocused: isInputFocused(top.state)
    };
    const { state, msgs } = top.screen.update(top.state, key, ctx);
    top.state = state;
    for (const msg of msgs) {
      this.dispatch(msg);
    }
    this.render();
  }

  private dispatch(msg: ScreenMsg): void {
    switch (msg.kind) {
      case 'push':
        this.push(msg.screen);
        return;
      case 'pop':
        this.pop();
        return;
      case 'replace':
        this.replace(msg.screen);
        return;
      case 'quit':
        this.stop();
        return;
      case 'request_focus':
        // Focus requests are hints; screens decide what to do.
        this.render();
        return;
      case 'submit':
        // Submit is handled by the screen's own update via its state.
        return;
      case 'no_op':
        return;
    }
  }

  private render(): void {
    if (this.closed) return;
    const frame = this.compose();
    const bytes = renderFrame(frame);
    this.out.write(bytes);
  }

  private compose(): Frame {
    // Build a frame from the bottom of the stack, then overlay each
    // overlay screen on top.
    let frame: Frame | null = null;
    for (let i = 0; i < this.stack.length; i += 1) {
      const entry = this.stack[i];
      if (!entry) continue;
      const ctx: ScreenContext = {
        cols: this.cols,
        rows: this.rows,
        inputFocused: isInputFocused(entry.state)
      };
      const next = entry.screen.view(entry.state, ctx);
      if (frame === null) {
        frame = next;
      } else if (entry.screen.overlay) {
        frame = overlayFrame(frame, next);
      } else {
        frame = next;
      }
    }
    return frame ?? createFrame(this.cols, this.rows);
  }

  /** Test seam: capture the most recent composed frame. */
  debugFrame(): Frame {
    return this.compose();
  }
}

function overlayFrame(bottom: Frame, top: Frame): Frame {
  const out = createFrame(bottom.cols, bottom.rows);
  for (let r = 0; r < bottom.rows; r += 1) {
    for (let c = 0; c < bottom.cols; c += 1) {
      const cell = bottom.cells[r]?.[c];
      if (cell) {
        const outRow = out.cells[r];
        if (outRow) outRow[c] = cell;
      }
    }
  }
  for (let r = 0; r < top.rows; r += 1) {
    for (let c = 0; c < top.cols; c += 1) {
      const cell = top.cells[r]?.[c];
      if (!cell) continue;
      // Only overwrite when top cell is non-space; otherwise the
      // bottom cell shows through (transparency).
      if (cell.char !== ' ') {
        const outRow = out.cells[r];
        if (outRow) outRow[c] = cell;
      }
    }
  }
  return out;
}

function isInputFocused(state: unknown): boolean {
  if (state === null || typeof state !== 'object') return false;
  const obj = state as { input?: { focused?: boolean } };
  if (!obj.input) return false;
  return obj.input.focused === true;
}

let snapshotCounter = 0;
