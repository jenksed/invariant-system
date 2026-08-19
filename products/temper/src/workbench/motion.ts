/**
 * Temper Workbench Alpha — Motion adapter.
 *
 * "Motion" is a Temper-specific projection vocabulary defined in
 * `docs/roadmap/temper.md` and the post-WP09 product direction. It
 * is NOT a T3 Code concept, NOT a Claude Code concept, and NOT a
 * canonical Kiln concept. It is derived by comparing two successive
 * canonical session.query results on a bounded field set. A Motion
 * entry is produced when a tracked field changes value.
 *
 * Authority rule: a Motion entry exists only when a real canonical
 * field value changed between two real session.query responses. No
 * Pulse (activity) is converted to Motion. No UI state is converted
 * to Motion. Only the bounded field set below can produce Motion.
 *
 * The bounded field set is intentionally narrow:
 *   - run_state
 *   - verification_status
 *   - review_status
 *   - human_status
 *   - workflow_step
 *   - journal_head_digest
 *   - projection_digest
 *   - pending_decision (presence + value, tracked as a distinct kind)
 *
 * If the runtime cannot establish that a field changed, this
 * adapter does not invent the change.
 */

import type { SessionQueryResult } from './projection.js';

export type MotionKind =
  | 'run_state_changed'
  | 'verification_changed'
  | 'review_changed'
  | 'human_status_changed'
  | 'workflow_step_changed'
  | 'pending_decision_changed'
  | 'journal_head_changed'
  | 'projection_observed';

export interface MotionEvent {
  /** Monotonic id within the motion log; assigned at detection. */
  id: number;
  kind: MotionKind;
  /** When the delta was detected (Temper wall clock). */
  detectedAt: string;
  /** Field name that changed. */
  field: string;
  /** Previous value (stringified). */
  from: string;
  /** New value (stringified). */
  to: string;
  /** Human-readable label for the Motion. */
  label: string;
}

const TRACKED_FIELDS: ReadonlyArray<string> = [
  'run_state',
  'verification_status',
  'review_status',
  'human_status',
  'workflow_step',
  'journal_head_digest',
  'projection_digest'
];

function stringify(value: unknown): string {
  if (value === null || value === undefined) return '—';
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  return JSON.stringify(value);
}

function labelFor(kind: MotionKind): string {
  switch (kind) {
    case 'run_state_changed':
      return 'run state changed';
    case 'verification_changed':
      return 'verification result recorded';
    case 'review_changed':
      return 'review verdict recorded';
    case 'human_status_changed':
      return 'human decision recorded';
    case 'workflow_step_changed':
      return 'workflow step advanced';
    case 'pending_decision_changed':
      return 'pending decision changed';
    case 'journal_head_changed':
      return 'journal head advanced';
    case 'projection_observed':
      return 'projection observed';
  }
}

export class MotionLog {
  private events: MotionEvent[] = [];
  private nextId = 1;
  private previous: SessionQueryResult | null = null;
  private readonly maxEvents: number;

  constructor(maxEvents = 200) {
    this.maxEvents = maxEvents;
  }

  /** Record a canonical observation. Returns the Motion events
   *  produced by comparing this observation against the previous one. */
  observe(current: SessionQueryResult | undefined): MotionEvent[] {
    if (!current) return [];
    const emitted: MotionEvent[] = [];
    if (this.previous) {
      for (const field of TRACKED_FIELDS) {
        const prev = (this.previous as Record<string, unknown>)[field];
        const now = (current as Record<string, unknown>)[field];
        if (!shallowEqual(prev, now)) {
          emitted.push(this.makeEvent(motionKindFor(field), field, prev, now));
        }
      }
      // pending_decision is tracked as a distinct Motion kind so the
      // operator can see when the canonical Session gained or lost
      // a pending human action.
      const prevPending = this.previous.pending_decision ?? null;
      const nowPending = current.pending_decision ?? null;
      if (prevPending == null && nowPending != null) {
        emitted.push(this.makeEvent('pending_decision_changed', 'pending_decision', 'absent', 'present'));
      } else if (prevPending != null && nowPending == null) {
        emitted.push(this.makeEvent('pending_decision_changed', 'pending_decision', 'present', 'absent'));
      } else if (prevPending != null && nowPending != null && !shallowEqual(prevPending, nowPending)) {
        emitted.push(this.makeEvent('pending_decision_changed', 'pending_decision', prevPending, nowPending));
      }
    } else {
      emitted.push(this.makeEvent('projection_observed', 'projection', '—', 'observed'));
    }
    this.previous = current;
    // Bounded buffer: append the new batch, then keep only the
    // newest maxEvents entries. Computing the combined length and
    // slicing from the end is correct even when the new batch alone
    // exceeds maxEvents.
    if (emitted.length > 0) {
      const combined = this.events.concat(emitted);
      this.events =
        combined.length > this.maxEvents
          ? combined.slice(combined.length - this.maxEvents)
          : combined;
    }
    return emitted;
  }

  /** Snapshot of the bounded motion log (newest last). */
  list(): MotionEvent[] {
    return this.events.slice();
  }

  /** Clear the log; useful when the canonical session changes. */
  reset(): void {
    this.events = [];
    this.previous = null;
  }

  private makeEvent(kind: MotionKind, field: string, from: unknown, to: unknown): MotionEvent {
    return {
      id: this.nextId++,
      kind,
      detectedAt: new Date().toISOString(),
      field,
      from: stringify(from),
      to: stringify(to),
      label: labelFor(kind)
    };
  }
}

function motionKindFor(field: string): MotionKind {
  switch (field) {
    case 'run_state':
      return 'run_state_changed';
    case 'verification_status':
      return 'verification_changed';
    case 'review_status':
      return 'review_changed';
    case 'human_status':
      return 'human_status_changed';
    case 'workflow_step':
      return 'workflow_step_changed';
    case 'journal_head_digest':
    case 'projection_digest':
      return 'journal_head_changed';
    default:
      return 'projection_observed';
  }
}

function shallowEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a == null || b == null) return false;
  if (typeof a !== typeof b) return false;
  if (typeof a === 'string' || typeof a === 'number' || typeof a === 'boolean') {
    return a === b;
  }
  return JSON.stringify(a) === JSON.stringify(b);
}
