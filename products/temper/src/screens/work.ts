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
  /**
   * N2: invoked when the operator presses A / R / V to submit
   * a governed human decision. The implementation performs the
   * real Kiln `human.decide` RPC and returns the bounded result.
   * The screen renders the result faithfully.
   */
  onHumanDecide?: (
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION'
  ) => Promise<{
    ok: boolean;
    errorCode?: string;
    errorReason?: string;
  }>;
  /**
   * N3: invoked when the operator presses d to open the
   * bounded diff surface. The orchestrator pushes the Diff
   * screen onto the runtime stack; the Diff screen reads
   * the bounded repository root from the projection.
   */
  onOpenDiff?: () => void;
}

export interface WorkState {
  projection: WorkbenchProjection | null;
  /** Most recent activity stream events (newest last). */
  pulse: PulseEvent[];
  /** Most recent canonical-delta events (newest last). */
  motion: MotionEvent[];
  /**
   * Wall-clock ISO timestamp of the most recent reconnect
   * transition. When non-null and recent (within ~30s), the
   * Work screen surfaces a "SINCE YOU LEFT" feed so the
   * operator can see what materially changed during the
   * disconnect window. Auto-clears when the operator presses
   * any key on the screen, or after the window expires.
   */
  lastReconnectAt: string | null;
  /**
   * Wall-clock ISO timestamp captured at the moment the
   * connection entered a non-connected state. Used to show
   * how long the disconnect has been active. Cleared when
   * the connection re-establishes.
   */
  disconnectedAt: string | null;
  /**
   * N2: status of the most recent human-decide submission.
   * idle: no submission yet (or last result dismissed)
   * submitting: the RPC is in flight
   * success: the bounded result was ok
   * rejected: the bounded result was ok:false with a real code
   * (e.g. E_HUMAN_DECISION_INVALID, E_RUN_TRANSITION_NOT_ALLOWED)
   * error: transport or other non-bounded failure
   * Cleared when the operator presses any key.
   */
  humanDecide: {
    status: 'idle' | 'submitting' | 'success' | 'rejected' | 'error';
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION' | null;
    code: string | null;
    reason: string | null;
    at: string | null;
  };
}

export function createWorkScreen(deps: WorkDeps): ScreenSpec {
  return {
    id: 'work',
    title: 'Active Work',
    init: () => ({
      projection: null,
      pulse: [],
      motion: [],
      lastReconnectAt: null,
      disconnectedAt: null,
      humanDecide: { status: 'idle', decision: null, code: null, reason: null, at: null }
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

/** Mark a reconnect transition. Called by the orchestrator when
 *  the WorkbenchConnection's state listener observes a transition
 *  from non-connected to connected. */
export function markWorkReconnect(state: WorkState, at: string = new Date().toISOString()): WorkState {
  return { ...state, lastReconnectAt: at, disconnectedAt: null };
}

/** Mark a disconnect transition. Called when the connection
 *  state becomes 'reconnecting' or 'disconnected'. */
export function markWorkDisconnect(state: WorkState, at: string = new Date().toISOString()): WorkState {
  // Don't overwrite an earlier disconnect timestamp if already set.
  if (state.disconnectedAt) return state;
  return { ...state, disconnectedAt: at };
}

/** Dismiss the "since you left" banner (operator dismissed it
 *  or the window expired). */
export function clearWorkReconnectBanner(state: WorkState): WorkState {
  return { ...state, lastReconnectAt: null };
}

/** Set the human-decide submission result. Called by the
 *  orchestrator after the real Kiln RPC returns. */
export function setHumanDecideResult(
  state: WorkState,
  result: {
    status: 'idle' | 'submitting' | 'success' | 'rejected' | 'error';
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION' | null;
    code: string | null;
    reason: string | null;
    at: string | null;
  }
): WorkState {
  return { ...state, humanDecide: result };
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

  // N2: human-decide key handlers (A / R / V). The screen
  // dispatches via the orchestrator's onHumanDecide callback and
  // transitions to 'submitting' immediately. The orchestrator
  // owns the result lifecycle and calls setHumanDecideResult on
  // the state when the real Kiln RPC returns.
  if (
    key.kind === 'char' &&
    deps.onHumanDecide &&
    state.humanDecide.status === 'idle' &&
    (key.value === 'A' || key.value === 'R' || key.value === 'V')
  ) {
    const decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION' =
      key.value === 'A' ? 'ACCEPT' : key.value === 'R' ? 'REJECT' : 'REQUEST_REVISION';
    void deps.onHumanDecide(decision);
    return {
      state: {
        ...state,
        humanDecide: { status: 'submitting', decision, code: null, reason: null, at: new Date().toISOString() }
      },
      msgs: []
    };
  }

  // N3: d opens the bounded diff surface. The orchestrator
  // pushes the Diff screen onto the runtime stack.
  if (key.kind === 'char' && key.value === 'd' && deps.onOpenDiff) {
    deps.onOpenDiff();
    return { state, msgs: [] };
  }

  // Pressing any other key (or a key after a result) dismisses
  // the since-you-left banner and a terminal human-decide result.
  // 'submitting' is intentionally not a terminal state — any key
  // during submit is a no-op so the operator cannot double-submit
  // or accidentally dismiss a result that has not arrived yet.
  if (
    state.humanDecide.status === 'submitting' &&
    (key.kind === 'char' || key.kind === 'enter')
  ) {
    return { state, msgs: [] };
  }
  if (state.lastReconnectAt || state.humanDecide.status !== 'idle') {
    return {
      state: {
        ...clearWorkReconnectBanner(state),
        humanDecide: { status: 'idle', decision: null, code: null, reason: null, at: null }
      },
      msgs: []
    };
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
  // Disconnect / reconnect banner — occupies the rows right below
  // the header. Always visible when the connection is non-connected;
  // visible briefly on reconnect (until dismissed by any key press
  // or the window expires).
  const bannerRow = 3;
  const isDisconnected = p?.connection === 'disconnected' || p?.connection === 'reconnecting';
  if (isDisconnected) {
    const since = state.disconnectedAt ? durationSince(state.disconnectedAt) : '';
    const headline = p?.connection === 'reconnecting'
      ? ' ⚠ RECONNECTING to Kiln…'
      : ' ✕ DISCONNECTED from Kiln';
    const subline = p?.sessionId
      ? `   last canonical: Session ${formatSession(p.sessionId)} · revision ${p.canonicalSessionRevision ?? '—'}${since ? '  (' + since + ')' : ''}`
      : '   no canonical session known';
    const caution = '   do not assume work stopped; awaiting Kiln to re-authorize';
    putString(frame, bannerRow, 0, pad(headline, ctx.cols), 'warn');
    putString(frame, bannerRow + 1, 0, pad(subline, ctx.cols), 'muted');
    putString(frame, bannerRow + 2, 0, pad(caution, ctx.cols), 'muted');
  } else if (state.lastReconnectAt && isRecent(state.lastReconnectAt, 30_000)) {
    const motionSinceReconnect = state.motion.filter(
      (e) => e.detectedAt > (state.lastReconnectAt as string)
    );
    const headline = ' ✓ Resynchronized to Kiln — SINCE YOU LEFT';
    const subline = `   ${motionSinceReconnect.length} canonical delta(s) recorded during the disconnect window`;
    const dismiss = '   press any key to dismiss';
    putString(frame, bannerRow, 0, pad(headline, ctx.cols), 'success');
    putString(frame, bannerRow + 1, 0, pad(subline, ctx.cols), 'muted');
    putString(frame, bannerRow + 2, 0, pad(dismiss, ctx.cols), 'muted');
  } else if (state.humanDecide.status !== 'idle') {
    // N2: human-decide submission status banner.
    const hd = state.humanDecide;
    const ts = hd.at ? hd.at.slice(11, 19) : '';
    let headline = '';
    let subline = '';
    let style: 'success' | 'warn' | 'error' = 'warn';
    if (hd.status === 'submitting') {
      headline = ` ⏳ Submitting ${hd.decision ?? 'decision'} to Kiln…`;
      subline = '   awaiting canonical adjudication';
      style = 'warn';
    } else if (hd.status === 'success') {
      headline = ` ✓ ${hd.decision ?? 'decision'} accepted by Kiln`;
      subline = `   canonical human status updated (${ts})`;
      style = 'success';
    } else if (hd.status === 'rejected') {
      headline = ` ✕ ${hd.decision ?? 'decision'} NOT applied: ${hd.code ?? 'E_UNKNOWN'}`;
      subline = hd.reason ? `   ${truncate(hd.reason, ctx.cols - 6)}` : '   bounded rejection from Kiln';
      style = 'error';
    } else if (hd.status === 'error') {
      headline = ` ✕ ${hd.decision ?? 'decision'} failed: ${hd.code ?? 'E_TRANSPORT'}`;
      subline = hd.reason ? `   ${truncate(hd.reason, ctx.cols - 6)}` : '   transport or unknown failure';
      style = 'error';
    }
    putString(frame, bannerRow, 0, pad(headline, ctx.cols), style);
    putString(frame, bannerRow + 1, 0, pad(subline, ctx.cols), 'muted');
    putString(frame, bannerRow + 2, 0, pad('   press any key to dismiss', ctx.cols), 'muted');
  }

  const showReconnectBanner = !isDisconnected && state.lastReconnectAt && isRecent(state.lastReconnectAt, 30_000);
  const showHumanDecideBanner = !isDisconnected && !showReconnectBanner && state.humanDecide.status !== 'idle';
  const bodyTop = isDisconnected
    ? bannerRow + 4
    : showReconnectBanner || showHumanDecideBanner
      ? bannerRow + 4
      : 4;
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
  const footer = (deps.onHumanDecide || deps.onOpenDiff)
    ? ' d diff · A accept · R reject · V request-revision · esc back · q quit '
    : ' esc back · q quit · ctrl-c interrupt · (d diff · e evidence · g graph) — coming ';
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

/** Render a short human duration since an ISO timestamp, e.g.
 *  "12s ago", "3m ago", "1h ago". Returns "" for malformed input. */
function durationSince(iso: string): string {
  const then = Date.parse(iso);
  if (Number.isNaN(then)) return '';
  const ms = Date.now() - then;
  if (ms < 0) return 'just now';
  if (ms < 1000) return 'just now';
  const s = Math.floor(ms / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  return `${h}h ago`;
}

/** True when `iso` is within `windowMs` milliseconds of now. */
function isRecent(iso: string, windowMs: number): boolean {
  const then = Date.parse(iso);
  if (Number.isNaN(then)) return false;
  return Date.now() - then < windowMs;
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
