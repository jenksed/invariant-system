/**
 * Bounded WebSocket activity stream + canonical resync trigger.
 *
 * Transport state is not workflow state. Notifications are hints that cause
 * canonical session.query; stale/duplicate/gap frames never become authority.
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
  private reconnectTimer?: ReturnType<typeof setTimeout>;
  private reconnectAttempts = 0;
  /** Deliberate close must never schedule a resurrection. */
  private closedByOperator = false;

  constructor(config: StreamConfig) {
    this.config = config;
    this.client = new KilnClient(config);
  }

  /** Open and resolve only after the socket is actually open. */
  public async open(): Promise<void> {
    this.closedByOperator = false;
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
      const settleOk = (): void => {
        if (settled) return;
        settled = true;
        resolve();
      };
      const settleError = (reason: string): void => {
        if (settled) return;
        settled = true;
        reject(new Error(reason));
      };

      ws.addEventListener('open', () => {
        this.reconnectAttempts = 0;
        const frame: ActivitySubscribeFrame = {
          type: 'activity.subscribe',
          subscription_id: this.config.subscriptionId,
          ...(this.config.sessionId ? { filter: { session_id: this.config.sessionId } } : {}),
          since_revision: this.lastObservedRevision
        };
        ws.send(JSON.stringify(frame));
        this.startPing();
        settleOk();
      });

      ws.addEventListener('message', (event) => {
        this.handleFrame(typeof event.data === 'string' ? event.data : '');
      });

      ws.addEventListener('close', () => {
        this.stopPing();
        if (!this.closedByOperator) this.scheduleReconnect();
        settleError('activity websocket closed before open');
      });

      ws.addEventListener('error', () => {
        settleError('activity websocket connection failed');
      });
    });
  }

  /** Close deliberately. This is terminal for this stream instance. */
  public close(): void {
    this.closedByOperator = true;
    this.stopPing();
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      delete (this as unknown as { reconnectTimer?: ReturnType<typeof setTimeout> }).reconnectTimer;
    }
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

  private handleFrame(raw: string): void {
    let frame: ActivityFrame;
    try {
      frame = JSON.parse(raw) as ActivityFrame;
    } catch {
      return;
    }

    if (frame.type === 'activity.notification') {
      this.processNotification(frame);
    } else if (frame.type === 'activity.error') {
      this.config.onResync?.('reconnect');
    }
  }

  private processNotification(frame: ActivityNotificationFrame): void {
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
      delete (this as unknown as { pingTimer?: ReturnType<typeof setInterval> }).pingTimer;
    }
  }

  private scheduleReconnect(): void {
    if (this.closedByOperator || this.reconnectTimer) return;
    this.reconnectAttempts += 1;
    const delay = Math.min(5_000, 250 * 2 ** Math.min(this.reconnectAttempts, 4));
    this.reconnectTimer = setTimeout(() => {
      delete (this as unknown as { reconnectTimer?: ReturnType<typeof setTimeout> }).reconnectTimer;
      if (this.closedByOperator) return;
      this.config.onResync?.('reconnect');
      void this.open().catch(() => {
        // The close event schedules the next bounded retry when available.
      });
    }, delay);
  }
}
