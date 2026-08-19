/**
 * Temper Workbench Alpha — Active Work screen.
 *
 * Three real-Kiln panels:
 *   - Pulse  (left): the bounded activity stream. Every entry maps
 *     1:1 to an activity.notification frame. No "agent is reading"
 *     guesses; only what the frame carries.
 *   - Motion (right top): the bounded canonical-delta stream. Every
 *     entry is the diff between two successive session.query
 *     responses on a fixed field set. Activity never becomes Motion.
 *   - Frontier + Attention (right bottom): the canonical session
 *     fields. Frontier is the bounded set the operator can act on;
 *     Attention is the subset that requires human judgment.
 *
 * Authority rule: this screen never owns a workflow boolean. It
 * renders only what the WorkbenchConnection reports. Motion and
 * Pulse are derived strictly from authoritative sources.
 */

import { putLabeledBox, putString, wrapText } from '../tui/frame.js';
import type { Frame } from '../tui/frame.js';
import { createFrame } from '../tui/frame.js';
import type { Key, ScreenContext, ScreenMsg, ScreenSpec } from '../tui/screen.js';
import type { WorkbenchProjection, SessionQueryResult } from '../workbench/projection.js';
import type { PulseEvent } from '../workbench/pulse.js';
import type { MotionEvent } from '../workbench/motion.js';

export interface WorkDeps {
  /** The operator's submitted intent. */
  intent: string;
  /** Called when the operator presses esc / q to leave Work. */
  onExit: () => void;
}

export interface WorkState {
  projection: WorkbenchProjection | null;
  /** Most recent activity stream events (newest last). */
  pulse: PulseEvent[];
  /** Most recent canonical-delta events (newest last). */
  motion: MotionEvent[];
}

export function createWorkScreen(deps: WorkDeps): ScreenSpec {
  return {
    id: 'work',
    title: 'Active Work',
    init: () => ({
      projection: null,
      pulse: [],
      motion: []
    }),
    view: (state, ctx) => renderWork(state as WorkState, ctx, deps),
    update: (state, key, ctx) => updateWork(state as WorkState, key, ctx, deps)
  };
}

/** External hooks to push canonical data into the screen state. */
export function setWorkProjection(state: WorkState, projection: WorkbenchProjection): WorkState {
  return { ...state, projection };
}

export function appendWorkPulse(state: WorkState, event: PulseEvent, maxEvents = 100): WorkState {
  const next = state.pulse.concat(event);
  if (next.length > maxEvents) next.splice(0, next.length - maxEvents);
  return { ...state, pulse: next };
}

export function appendWorkMotion(state: WorkState, event: MotionEvent, maxEvents = 100): WorkState {
  const next = state.motion.concat(event);
  if (next.length > maxEvents) next.splice(0, next.length - maxEvents);
  return { ...state, motion: next };
}

function updateWork(
  state: WorkState,
  key: Key,
  _ctx: ScreenContext,
  deps: WorkDeps
): { state: WorkState; msgs: ScreenMsg[] } {
  if (key.kind === 'ctrl' && key.value === 'c') {
    return { state, msgs: [{ kind: 'quit' }] };
  }
  if (key.kind === 'escape') {
    deps.onExit();
    return { state, msgs: [{ kind: 'pop' }] };
  }
  if (key.kind === 'char' && key.value === 'q') {
    deps.onExit();
    return { state, msgs: [{ kind: 'quit' }] };
  }
  // Future: d → diff, e → evidence, g → graph (later), ? → help.
  return { state, msgs: [] };
}

// -- view --

function renderWork(state: WorkState, ctx: ScreenContext, deps: WorkDeps): Frame {
  const frame = createFrame(ctx.cols, ctx.rows);
  const p = state.projection;

  // Header
  putString(frame, 0, 0, ' ◆ TEMPER ', 'wordmark');
  const headerRight = p
    ? `Session ${formatSession(p.sessionId)}  ·  ${connectionGlyph(p.connection)}`
    : '(no projection)';
  putString(frame, 0, ctx.cols - headerRight.length - 1, headerRight, 'header');
  if (p) {
    const leftLine = ` project  ${truncate(p.repository, Math.max(8, ctx.cols - 30))}`;
    putString(frame, 1, 0, leftLine, 'muted');
  }
  putString(frame, 2, 0, '─'.repeat(ctx.cols), 'border');

  // Two-pane layout: left = work stream (pulse + intent), right = motion + frontier.
  const bodyTop = 4;
  const footerRow = ctx.rows - 1;
  const bodyHeight = footerRow - bodyTop - 1;
  const leftW = Math.max(40, Math.floor(ctx.cols * 0.6));
  const rightW = ctx.cols - leftW - 3;
  const leftCol = 1;
  const rightCol = leftCol + leftW + 1;

  // Left pane: WORK
  putLabeledBox(frame, {
    rect: { row: bodyTop, col: leftCol, rows: bodyHeight, cols: leftW },
    title: 'WORK'
  });
  let lr = bodyTop + 1;
  const leftInnerW = leftW - 4;
  // Operator's intent at the top
  if (deps.intent.length > 0) {
    putString(frame, lr, leftCol + 2, 'You', 'accent');
    lr += 1;
    for (const line of wrapText(truncate(deps.intent, leftInnerW * 4), leftInnerW).slice(0, 4)) {
      putString(frame, lr, leftCol + 2, line);
      lr += 1;
    }
    lr += 1;
  }
  // Pulse
  if (state.pulse.length > 0) {
    putString(frame, lr, leftCol + 2, 'Pulse (live activity)', 'muted');
    lr += 1;
    const pulseShown = state.pulse.slice(-Math.max(1, bodyHeight - (lr - bodyTop) - 2));
    for (const ev of pulseShown) {
      if (lr >= footerRow - 1) break;
      const ts = ev.receivedAt.slice(11, 19);
      const line = truncate(`${ts}  ${ev.line}`, leftInnerW);
      putString(frame, lr, leftCol + 2, line, 'dim');
      lr += 1;
    }
  } else {
    lr += 1;
    putString(frame, lr, leftCol + 2, 'No Pulse yet — awaiting activity.', 'muted');
    lr += 1;
    putString(frame, lr, leftCol + 2, 'Pulse is read-only; it is not proof of progress.', 'muted');
  }

  // Right pane top: MOTION
  const motionH = Math.max(5, Math.floor(bodyHeight * 0.5));
  putLabeledBox(frame, {
    rect: { row: bodyTop, col: rightCol, rows: motionH, cols: rightW },
    title: 'MOTION (canonical deltas)'
  });
  let rr = bodyTop + 1;
  const rightInnerW = rightW - 4;
  if (state.motion.length > 0) {
    const shown = state.motion.slice(-Math.max(1, motionH - 2));
    for (const ev of shown) {
      if (rr >= bodyTop + motionH - 1) break;
      const ts = ev.detectedAt.slice(11, 19);
      const text = `${ts}  ${ev.label}: ${truncate(ev.from, 10)} → ${truncate(ev.to, 10)}`;
      putString(frame, rr, rightCol + 2, truncate(text, rightInnerW), 'success');
      rr += 1;
    }
  } else {
    putString(frame, rr, rightCol + 2, 'No Motion yet — canonical state unchanged.', 'muted');
    rr += 1;
  }

  // Right pane bottom: FRONTIER + ATTENTION
  const frontierRow = bodyTop + motionH + 1;
  const frontierH = bodyHeight - motionH - 2;
  if (frontierH >= 4) {
    putLabeledBox(frame, {
      rect: { row: frontierRow, col: rightCol, rows: frontierH, cols: rightW },
      title: 'FRONTIER · ATTENTION'
    });
    let fr = frontierRow + 1;
    const innerW = rightW - 4;
    const sq = p?.sessionQuery;
    if (sq) {
      // Frontier: read-only canonical fields
      const frontier: Array<[string, string]> = [
        ['Objective', sq.objective ?? '—'],
        ['Run', sq.run_state ?? '—'],
        ['Verify', sq.verification_status ?? '—'],
        ['Review', sq.review_status ?? '—'],
        ['Human', sq.human_status ?? '—'],
        ['Unknowns', sq.unknowns && sq.unknowns.length > 0 ? String(sq.unknowns.length) : 'none']
      ];
      for (const [label, value] of frontier) {
        if (fr >= frontierRow + frontierH - 1) break;
        putString(frame, fr, rightCol + 2, label, 'muted');
        putString(frame, fr, rightCol + 12, truncate(value, innerW - 10));
        fr += 1;
      }
      // Attention: only when canonical state establishes a real ask.
      const attentionLine = attentionFor(sq);
      if (attentionLine && fr < frontierRow + frontierH - 1) {
        fr += 1;
        putString(frame, fr, rightCol + 2, '⚠ YOU', 'warn');
        fr += 1;
        for (const line of wrapText(truncate(attentionLine, innerW - 2), innerW - 2).slice(0, 3)) {
          if (fr >= frontierRow + frontierH - 1) break;
          putString(frame, fr, rightCol + 2, line, 'warn');
          fr += 1;
        }
      }
    } else {
      putString(frame, fr, rightCol + 2, 'No canonical Session yet.', 'muted');
    }
  }

  // Footer
  const footer = ' esc back · q quit · ctrl-c interrupt · (d diff · e evidence · g graph) — coming ';
  putString(frame, footerRow, 0, pad(footer, ctx.cols), 'footer');
  return frame;
}

function attentionFor(sq: SessionQueryResult): string | null {
  if (sq.human_status === 'REQUEST_REVISION') {
    return 'Human revision requested. Review the prior review and re-propose.';
  }
  if (sq.human_status === 'PENDING' && sq.pending_decision) {
    return 'A pending decision requires your judgment.';
  }
  if (sq.pending_decision) {
    return 'A pending decision is recorded in the canonical Session.';
  }
  return null;
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
