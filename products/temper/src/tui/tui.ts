/** Screen-agnostic terminal runtime for Temper. */

import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { createKeypressParser, type KeypressParser } from './keypress.js';
import { ANSI, frameToText, renderFrame } from './render.js';
import type { Frame } from './frame.js';
import { createFrame } from './frame.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from './screen.js';

export interface RuntimeOptions {
  out?: NodeJS.WritableStream;
  input?: NodeJS.ReadableStream;
  altScreen?: boolean;
  cols?: number;
  rows?: number;
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
  private readonly closeListeners = new Set<() => void>();
  private attached = false;
  private onResize?: () => void;
  private commandPaletteFactory?: () => ScreenSpec;

  constructor(options: RuntimeOptions = {}) {
    this.out = options.out ?? process.stdout;
    this.input = options.input ?? process.stdin;
    this.altScreen = options.altScreen ?? true;
    this.cols = options.cols ?? (this.out as { columns?: number }).columns ?? 100;
    this.rows = options.rows ?? (this.out as { rows?: number }).rows ?? 30;
    this.parser = createKeypressParser();
    if (options.snapshotDir) this.snapshotDir = options.snapshotDir;
  }

  /** Register one shared palette factory. Ctrl-k opens it everywhere;
   * `/` opens it only when the current screen has no focused input. */
  setCommandPaletteFactory(factory: () => ScreenSpec): void {
    this.commandPaletteFactory = factory;
  }

  push(screen: ScreenSpec): void {
    this.stack.push({ screen, state: screen.init() });
    this.attachInput();
    this.render();
  }

  pop(): void {
    if (this.stack.length > 1) {
      this.stack.pop();
      this.render();
    }
  }

  replace(screen: ScreenSpec): void {
    const initial = screen.init();
    if (this.stack.length === 0) this.stack.push({ screen, state: initial });
    else this.stack[this.stack.length - 1] = { screen, state: initial };
    this.render();
  }

  setTopState(state: unknown): void {
    const top = this.stack[this.stack.length - 1];
    if (!top) return;
    top.state = state;
    this.render();
  }

  invalidate(): void { this.render(); }

  snapshot(label: string): string | undefined {
    if (!this.snapshotDir) return undefined;
    mkdirSync(this.snapshotDir, { recursive: true });
    const text = frameToText(this.compose());
    const safeLabel = label.replace(/[^a-zA-Z0-9_-]+/g, '-').slice(0, 64) || 'frame';
    const seq = (snapshotCounter += 1).toString().padStart(4, '0');
    const path = join(this.snapshotDir, `${safeLabel}-${seq}.txt`);
    writeFileSync(path, `${text}\n`, 'utf8');
    return path;
  }

  start(): void {
    if (this.altScreen) this.out.write('\x1b[?1049h');
    this.out.write(ANSI.HIDE_CURSOR);
    const stdinAny = this.input as NodeJS.ReadableStream & {
      isTTY?: boolean;
      setRawMode?: (mode: boolean) => void;
    };
    if (stdinAny.isTTY && typeof stdinAny.setRawMode === 'function') stdinAny.setRawMode(true);
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

  stop(): void {
    if (this.closed) return;
    this.closed = true;
    this.out.write(ANSI.SHOW_CURSOR);
    if (this.altScreen) this.out.write('\x1b[?1049l');
    const stdinAny = this.input as NodeJS.ReadableStream & {
      isTTY?: boolean;
      setRawMode?: (mode: boolean) => void;
    };
    if (stdinAny.isTTY && typeof stdinAny.setRawMode === 'function') stdinAny.setRawMode(false);
    this.input.off('data', this.handleData);
    if (this.onResize && typeof this.out.off === 'function') this.out.off('resize', this.onResize);
    for (const listener of this.closeListeners) listener();
    this.closeListeners.clear();
  }

  onClose(listener: () => void): () => void {
    if (this.closed) {
      queueMicrotask(listener);
      return () => {};
    }
    this.closeListeners.add(listener);
    return () => { this.closeListeners.delete(listener); };
  }

  private attachInput(): void {
    if (this.attached) return;
    this.attached = true;
    this.input.on('data', this.handleData);
  }

  inject(key: Key): void { this.handleKey(key); }

  private handleData = (chunk: Buffer | string): void => {
    const data = typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    for (const key of this.parser.feed(data)) this.handleKey(key);
  };

  private handleKey(key: Key): void {
    if (key.kind === 'resize') {
      this.cols = key.cols; this.rows = key.rows; this.render(); return;
    }
    const top = this.stack[this.stack.length - 1];
    if (!top) return;

    // Shared command entry: ctrl-k everywhere; slash when there is no focused
    // text input. This keeps the runtime generic while avoiding duplicate
    // command parsing in Home, Work, Diff, and future screens.
    if (this.commandPaletteFactory && top.screen.id !== 'command-palette') {
      const ctrlK = key.kind === 'ctrl' && key.value === 'k';
      const slashWithoutInput = key.kind === 'char' && key.value === '/' && !isInputFocused(top.state);
      if (ctrlK || slashWithoutInput) {
        this.push(this.commandPaletteFactory());
        return;
      }
    }

    const ctx: ScreenContext = {
      cols: this.cols,
      rows: this.rows,
      inputFocused: isInputFocused(top.state)
    };
    const { state, msgs } = top.screen.update(top.state, key, ctx);
    top.state = state;
    for (const msg of msgs) this.dispatch(msg);
    this.render();
  }

  private dispatch(msg: ScreenMsg): void {
    switch (msg.kind) {
      case 'push': this.push(msg.screen); return;
      case 'pop': this.pop(); return;
      case 'replace': this.replace(msg.screen); return;
      case 'quit': this.stop(); return;
      case 'request_focus': this.render(); return;
      case 'submit': return;
      case 'no_op': return;
    }
  }

  private render(): void {
    if (this.closed) return;
    this.out.write(renderFrame(this.compose()));
  }

  private compose(): Frame {
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
      if (frame === null) frame = next;
      else if (entry.screen.overlay) frame = overlayFrame(frame, next);
      else frame = next;
    }
    return frame ?? createFrame(this.cols, this.rows);
  }

  debugFrame(): Frame { return this.compose(); }
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
      if (!cell || cell.char === ' ') continue;
      const outRow = out.cells[r];
      if (outRow) outRow[c] = cell;
    }
  }
  return out;
}

function isInputFocused(state: unknown): boolean {
  if (state === null || typeof state !== 'object') return false;
  const obj = state as { input?: { focused?: boolean } };
  return obj.input?.focused === true;
}

let snapshotCounter = 0;
