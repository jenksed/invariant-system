/**
 * Temper Workbench Alpha — keypress parser.
 *
 * Reads bytes from a Readable stream and yields Key events. Handles
 * bracketed paste, escape sequences for arrows / pgup / pgdn / home /
 * end, and ctrl+letter chords.
 *
 * The parser is decoupled from raw mode: the runtime enables raw mode
 * and forwards data events to feed(buf). feed() returns the parsed
 * Key events (if any) and any unused trailing bytes to keep in the
 * buffer for the next feed.
 */

import type { Key } from './screen.js';

export interface KeypressParser {
  feed(data: string): Key[];
  end(): void;
}

const ESC = '\x1b';
const CSI = '\x1b[';

export function createKeypressParser(): KeypressParser {
  let buffer = '';
  let pasting = false;

  function flushEscSequence(): Key | null {
    if (!buffer.startsWith(ESC)) return null;
    // Single ESC: wait for more; the runtime will time it out as a
    // lone escape key when the stream goes idle.
    if (buffer.length === 1) {
      return null;
    }
    if (buffer.length === 2 && buffer[1] === ESC) {
      // ESC ESC → second ESC; drop and wait for more.
      return null;
    }
    // CSI sequence: ESC [
    if (buffer.startsWith(CSI)) {
      // Find the terminator (0x40-0x7E).
      let endIdx = -1;
      for (let i = 2; i < buffer.length; i += 1) {
        const code = buffer.charCodeAt(i);
        if (code >= 0x40 && code <= 0x7e) {
          endIdx = i;
          break;
        }
      }
      if (endIdx === -1) {
        // Incomplete sequence; keep waiting.
        return null;
      }
      const params = buffer.slice(2, endIdx);
      const final = buffer[endIdx] ?? '';
      buffer = buffer.slice(endIdx + 1);
      return csiToKey(params, final);
    }
    // ESC + non-CSI byte: the ESC was a standalone escape key. Strip
    // it from the buffer and return escape; the main loop will then
    // process the remaining byte as a normal keypress.
    buffer = buffer.slice(1);
    return { kind: 'escape' };
  }

  function csiToKey(params: string, final: string): Key | null {
    if (final === 'A') return { kind: 'up' };
    if (final === 'B') return { kind: 'down' };
    if (final === 'C') return { kind: 'right' };
    if (final === 'D') return { kind: 'left' };
    if (final === 'H') return { kind: 'home' };
    if (final === 'F') return { kind: 'end' };
    if (final === '~') {
      if (params === '1' || params === '7') return { kind: 'home' };
      if (params === '4' || params === '8') return { kind: 'end' };
      if (params === '5') return { kind: 'page_up' };
      if (params === '6') return { kind: 'page_down' };
      if (params === '3') return { kind: 'char', value: '\x7f' };
    }
    return null;
  }

  return {
    feed(data: string): Key[] {
      const events: Key[] = [];
      buffer += data;

      while (buffer.length > 0) {
        const head = buffer[0] ?? '';
        if (pasting) {
          const end = buffer.indexOf('\x1b[201~');
          if (end === -1) {
            events.push({ kind: 'paste', value: buffer });
            buffer = '';
            return events;
          }
          const pasteValue = buffer.slice(0, end);
          buffer = buffer.slice(end + '\x1b[201~'.length);
          pasting = false;
          if (pasteValue.length > 0) {
            events.push({ kind: 'paste', value: pasteValue });
          }
          continue;
        }

        // Bracketed paste start?
        if (buffer.startsWith('\x1b[200~')) {
          pasting = true;
          buffer = buffer.slice('\x1b[200~'.length);
          continue;
        }

        // CR or LF → enter
        if (head === '\r' || head === '\n') {
          buffer = buffer.slice(1);
          events.push({ kind: 'enter' });
          continue;
        }

        // ESC begins an escape sequence; never ctrl.
        if (head === ESC) {
          const key = flushEscSequence();
          if (key === null) {
            // Incomplete; keep waiting.
            return events;
          }
          events.push(key);
          continue;
        }

        // Backspace / DEL.
        if (head === '\x7f' || head === '\b') {
          buffer = buffer.slice(1);
          events.push({ kind: 'backspace' });
          continue;
        }

        // ctrl+c / ctrl+d / ctrl+h / ctrl+? etc. (skip tab; skip the
        // control bytes we've already handled above).
        if (head.charCodeAt(0) < 0x20 && head !== '\t') {
          const code = head.charCodeAt(0);
          const letter = String.fromCharCode(code + 0x60); // 0x01 → 'a'
          buffer = buffer.slice(1);
          events.push({ kind: 'ctrl', value: letter });
          continue;
        }

        // Tab
        if (head === '\t') {
          buffer = buffer.slice(1);
          events.push({ kind: 'tab' });
          continue;
        }

        // Regular printable char.
        buffer = buffer.slice(1);
        events.push({ kind: 'char', value: head });
      }

      return events;
    },
    end(): void {
      buffer = '';
      pasting = false;
    }
  };
}
