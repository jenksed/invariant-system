/**
 * Temper Workbench Alpha — Pulse adapter.
 *
 * "Pulse" is a Temper-specific projection vocabulary defined in
 * `docs/roadmap/temper.md` and the post-WP09 product direction. It
 * is NOT a T3 Code concept, NOT a Claude Code concept, and NOT a
 * canonical Kiln concept. It reduces activity.notification frames
 * into operator-readable lines. The reduction is intentionally
 * simple: the activity envelope carries only `subject.kind`,
 * `subject.id`, `revision`, and `canonical_session_revision`. We
 * surface those and nothing more. We do not infer "agent is
 * reading file X" or "test passed"; those would be guessing.
 *
 * Authority rule: a Pulse entry maps 1:1 to a single activity frame.
 * No Pulse entry is synthesized from a notification event. Frames
 * that the stream layer discards (stale, duplicate, gap) never
 * become Pulse entries.
 */

import type { ActivityNotificationFrame } from '../types.js';

export interface PulseEvent {
  id: number;
  /** When the frame was received (Temper wall clock). */
  receivedAt: string;
  /** Subject kind from the frame. */
  subjectKind: 'session' | 'run' | 'operation' | string;
  /** Subject id from the frame. */
  subjectId: string;
  /** Activity frame revision. */
  revision: number;
  /** Canonical session revision at the time of the frame. */
  canonicalSessionRevision: number;
  /** Human-readable line. */
  line: string;
}

export class PulseLog {
  private events: PulseEvent[] = [];
  private nextId = 1;
  private readonly maxEvents: number;

  constructor(maxEvents = 200) {
    this.maxEvents = maxEvents;
  }

  /** Reduce an activity frame into a Pulse event. */
  observe(frame: ActivityNotificationFrame): PulseEvent {
    const event: PulseEvent = {
      id: this.nextId++,
      receivedAt: new Date().toISOString(),
      subjectKind: frame.subject.kind,
      subjectId: frame.subject.id,
      revision: frame.revision,
      canonicalSessionRevision: frame.canonical_session_revision,
      line: pulseLine(frame)
    };
    this.events.push(event);
    if (this.events.length > this.maxEvents) {
      this.events.splice(0, this.events.length - this.maxEvents);
    }
    return event;
  }

  list(): PulseEvent[] {
    return this.events.slice();
  }

  reset(): void {
    this.events = [];
    this.nextId = 1;
  }
}

function pulseLine(frame: ActivityNotificationFrame): string {
  const shortId = shorten(frame.subject.id);
  return `Kiln state changed · ${frame.subject.kind}:${shortId} · rev ${frame.revision} → canonical ${frame.canonical_session_revision}`;
}

function shorten(id: string): string {
  if (id.length <= 16) return id;
  return `${id.slice(0, 6)}…${id.slice(-6)}`;
}
