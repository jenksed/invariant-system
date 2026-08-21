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
export type StreamConnectionListener = (state: 'connected' | 'reconnecting' | 'disconnected') => void;

export interface StreamConfig extends KilnClientConfig {
  subscriptionId: string;
  sessionId?: string;
  onActivity?: ActivityEventListener;
  onResync?: ResyncListener;
  onConnectionState?: StreamConnectionListener;
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
  /**
   * Manual lifecycle guard. `close()` means the owner intentionally
   * retired this stream; a WebSocket close event must not resurrect it.
   * Unexpected network closes leave this false and retain bounded retry.
   */
  private closed = false;

  constructor(config: StreamConfig) {
    this.config = config;
    this.client = new KilnClient(config);
  }

  /**
   * Open the WebSocket and resolve only after the actual `open` event.
   * The old implementation returned immediately after construction, which
   * allowed callers to report `connected` before the transport handshake.
   */
  public async open(): Promise<void> {
    if (this.closed) throw new Error('activity stream is permanently closed');

    const ws = new WebSocket(
      this.config.wsUrl,
      { headers: { authorization: `Bearer ${this.config.operateToken}` } } as unknown as
        | string
        | string[]
        | undefined
    );

    this.ws = ws;

    await new Promise<void>((resolve, reject) => {
      let settled = false;

      ws.addEventListener('open', () => {
        if (this.closed) {
          ws.close(1000, 'temper-close');
          if (!settled) {
            settled = true;
            reject(new Error('activity stream closed during connection'));
          }
          return;
        }
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
        this.config.onConnectionState?.('connected');
        if (!settled) {
          settled = true;
          resolve();
        }
      });

      ws.addEventListener('message', (event) => {
        if (this.closed) return;
        this.handleFrame(typeof event.data === 'string' ? event.data : '');
      });

      ws.addEventListener('close', () => {
        this.stopPing();
        if (this.closed) return;
        this.config.onConnectionState?.('reconnecting');
        if (!settled) {
          settled = true;
          reject(new Error('activity websocket closed before connection completed'));
        }
        this.scheduleReconnect();
      });

      ws.addEventListener('error', () => {
        if (this.closed) return;
        this.config.onConnectionState?.('disconnected');
        if (!settled) {
          settled = true;
          reject(new Error('activity websocket connection failed'));
        }
        // The close event normally follows and owns bounded retry.
      });
    });
  }

  /** Close the WS cleanly and permanently retire this stream instance. */
  public close(): void {
    this.closed = true;
    this.stopPing();
    if (this.ws) {
      this.ws.close(1000, 'temper-close');
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
    if (this.closed) return;
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
      // The daemon reported stream divergence/error while the socket still
      // exists. Force canonical resync; do not invent a notification.
      this.config.onResync?.('reconnect');
    }
    // activity.snapshot is informational; canonical resync is via
    // session.query per the contract freeze §8.
  }

  private processNotification(frame: ActivityNotificationFrame): void {
    if (this.closed) return;
    if (frame.revision < this.lastObservedRevision) return;

    if (frame.revision > this.lastObservedRevision + 1 && this.lastObservedRevision !== 0) {
      this.config.onResync?.('gap');
      this.lastObservedRevision = frame.revision;
      this.canonicalSessionRevision = frame.canonical_session_revision;
      return;
    }

    const key = `${frame.revision}:${frame.event_kind}:${frame.subject.id}`;
    if (this.seen.has(key)) return;
    this.seen.add(key);

    this.lastObservedRevision = frame.revision;
    this.canonicalSessionRevision = frame.canonical_session_revision;
    this.config.onActivity?.(frame);
  }

  private startPing(): void {
    if (this.closed) return;
    const interval = this.config.pingIntervalMs ?? 15_000;
    this.pingTimer = setInterval(() => {
      if (!this.closed && this.ws && this.ws.readyState === this.ws.OPEN) {
        this.ws.send(JSON.stringify({ type: 'ping' }));
      }
    }, interval);
  }

  private stopPing(): void {
    if (this.pingTimer) {
      clearInterval(this.pingTimer);
      delete (this as unknown as { pingTimer?: ReturnType<typeof setInterval> }).pingTimer;
    }
  }

  private scheduleReconnect(): void {
    if (this.closed) return;
    this.reconnectAttempts += 1;
    const delay = Math.min(5_000, 250 * 2 ** Math.min(this.reconnectAttempts, 4));
    setTimeout(() => {
      if (this.closed) return;
      void this.open()
        .then(() => {
          if (!this.closed) this.config.onResync?.('reconnect');
        })
        .catch(() => {
          // `open()` reports the failed attempt through connection state.
          // The socket close event owns scheduling the next bounded retry.
        });
    }, delay);
  }
}