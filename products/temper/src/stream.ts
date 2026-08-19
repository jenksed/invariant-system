/**
 * WP-09 Lane 3: bounded WebSocket activity stream + canonical resync.
 *
 * Implements contract freeze §7, §8, §10.
 *
 * Reconnect semantics:
 *   - Connection lost / startup / divergence detected -> reconnect.
 *   - On reconnect: open WS, send activity.subscribe (with
 *     `last_observed_revision` hint, NOT authoritative), then
 *     `session.query` for canonical truth.
 *   - Replace local WorkbenchModel with canonical state.
 *   - Resume activity subscription; treat subsequent notifications
 *     as deltas.
 *
 * Stale + duplicate + gap handling (contract freeze §7):
 *   - Stale: notification revision < last observed -> discard.
 *   - Duplicate: same (revision, event_kind, subject.id) -> discard.
 *   - Gap: revision > last_observed + 1 -> discard notification,
 *     request canonical resync.
 *   - Missed: reconnect obtains canonical via `session.query`.
 */

import type {
  ActivityFrame,
  ActivityNotificationFrame,
  ActivitySubscribeFrame,
  KilnClientConfig
} from './types.js';
import { KilnClient } from './client.js';

export type ActivityEventListener = (frame: ActivityNotificationFrame) => void;
export type ResyncListener = (reason: 'stale' | 'gap' | 'reconnect') => void;

export interface StreamConfig extends KilnClientConfig {
  subscriptionId: string;
  sessionId?: string;
  onActivity?: ActivityEventListener;
  onResync?: ResyncListener;
  pingIntervalMs?: number;
}

export class ActivityStream {
  private readonly config: StreamConfig;
  private readonly client: KilnClient;
  private ws?: WebSocket;
  private lastObservedRevision = 0;
  private canonicalSessionRevision = 0;
  private readonly seen = new Set<string>();
  private pingTimer?: ReturnType<typeof setInterval>;
  private reconnectAttempts = 0;

  constructor(config: StreamConfig) {
    this.config = config;
    this.client = new KilnClient(config);
  }

  /** Open the WS, subscribe, and start the keepalive ping loop. */
  public async open(): Promise<void> {
    // Node 22+ global WebSocket accepts a headers option in its
    // implementation but its TypeScript signature does not export
    // WebSocketConstructorOptions. Cast to the standard second-arg
    // shape so the compiler accepts the runtime-accepted headers.
    const ws = new WebSocket(
      this.config.wsUrl,
      { headers: { authorization: `Bearer ${this.config.operateToken}` } } as unknown as
        | string
        | string[]
        | undefined
    );

    this.ws = ws;

    ws.addEventListener('open', () => {
      this.reconnectAttempts = 0;
      const frame: ActivitySubscribeFrame = {
        type: 'activity.subscribe',
        subscription_id: this.config.subscriptionId,
        ...(this.config.sessionId
          ? { filter: { session_id: this.config.sessionId } }
          : {}),
        since_revision: this.lastObservedRevision
      };
      ws.send(JSON.stringify(frame));
      this.startPing();
    });

    ws.addEventListener('message', (event) => {
      this.handleFrame(typeof event.data === 'string' ? event.data : '');
    });

    ws.addEventListener('close', () => {
      this.stopPing();
      this.scheduleReconnect();
    });

    ws.addEventListener('error', () => {
      // Close handler will fire next; reconnect logic handles it.
    });
  }

  /** Close the WS cleanly. */
  public close(): void {
    this.stopPing();
    if (this.ws) {
      this.ws.close(1000, 'temper-close');
      // exactOptionalPropertyTypes: `?:` fields cannot be assigned
      // undefined. Use delete to clear the optional slot.
      delete (this as unknown as { ws?: WebSocket }).ws;
    }
  }

  public get lastRevision(): number {
    return this.lastObservedRevision;
  }

  public get canonical(): number {
    return this.canonicalSessionRevision;
  }

  // -- private --

  private handleFrame(raw: string): void {
    let frame: ActivityFrame;
    try {
      frame = JSON.parse(raw) as ActivityFrame;
    } catch {
      return;
    }

    if (frame.type === 'activity.notification') {
      this.processNotification(frame);
    } else if (frame.type === 'pong') {
      // keepalive ack; nothing to do
    } else if (frame.type === 'activity.error') {
      // surface but do not throw — the daemon decides close codes
      this.config.onResync?.('reconnect');
    }
    // activity.snapshot is informational; canonical resync is via
    // session.query per the contract freeze §8.
  }

  private processNotification(frame: ActivityNotificationFrame): void {
    // Stale guard (contract freeze §7).
    if (frame.revision < this.lastObservedRevision) {
      return;
    }

    // Gap guard — discard and request canonical resync.
    if (frame.revision > this.lastObservedRevision + 1 && this.lastObservedRevision !== 0) {
      this.config.onResync?.('gap');
      this.lastObservedRevision = frame.revision;
      this.canonicalSessionRevision = frame.canonical_session_revision;
      return;
    }

    // Duplicate guard.
    const key = `${frame.revision}:${frame.event_kind}:${frame.subject.id}`;
    if (this.seen.has(key)) return;
    this.seen.add(key);

    this.lastObservedRevision = frame.revision;
    this.canonicalSessionRevision = frame.canonical_session_revision;
    this.config.onActivity?.(frame);
  }

  private startPing(): void {
    const interval = this.config.pingIntervalMs ?? 15_000;
    this.pingTimer = setInterval(() => {
      if (this.ws && this.ws.readyState === this.ws.OPEN) {
        this.ws.send(JSON.stringify({ type: 'ping' }));
      }
    }, interval);
  }

  private stopPing(): void {
    if (this.pingTimer) {
      clearInterval(this.pingTimer);
      // exactOptionalPropertyTypes: `?:` fields cannot be assigned
      // undefined. Use delete to clear the optional slot.
      delete (this as unknown as { pingTimer?: ReturnType<typeof setInterval> }).pingTimer;
    }
  }

  private scheduleReconnect(): void {
    this.reconnectAttempts += 1;
    // bounded backoff: 250ms, 500ms, 1s, 2s, 4s, then capped at 5s.
    const delay = Math.min(5_000, 250 * 2 ** Math.min(this.reconnectAttempts, 4));
    setTimeout(() => {
      this.config.onResync?.('reconnect');
      void this.open();
    }, delay);
  }
}
