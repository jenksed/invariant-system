/**
 * WP-09 Lane 3: live-mode orchestrator for Temper.
 *
 * Coordinates:
 *   - HTTP RPC client (client.ts)
 *   - WebSocket activity stream (stream.ts)
 *   - Canonical resync (contract freeze §8)
 *
 * On every activity notification:
 *   - Re-query canonical state via session.query (or project.open).
 *   - Replace local WorkbenchModel with canonical response.
 *   - Caller re-renders.
 *
 * The orchestrator NEVER:
 *   - infers an authoritative transition from a notification
 *   - blindly replays a consequential RPC
 *   - mutates Kiln state from local events
 */

import { randomUUID } from 'node:crypto';
import type {
  ActivityNotificationFrame,
  KilnClientConfig,
  ProjectOpenResult,
  RpcResponse,
  WorkbenchModel
} from './types.js';
import { KilnClient } from './client.js';
import { ActivityStream } from './stream.js';

export interface LiveModeConfig extends KilnClientConfig {
  repository: string;
  /** Initial focus (default 'overview'). */
  initialFocus?: 'overview' | 'plan' | 'run' | 'authority' | 'evidence' | 'artifacts' | 'raw' | 'help' | 'loop';
  /** Called on every canonical resync; the caller re-renders. */
  onProjection: (model: WorkbenchModel) => void;
  /** Called when a non-resync notification arrives (status hint). */
  onActivity?: (frame: ActivityNotificationFrame) => void;
}

export class LiveMode {
  private readonly config: LiveModeConfig;
  private readonly client: KilnClient;
  private stream?: ActivityStream;
  private model?: WorkbenchModel;
  private readonly subscriptionId: string;

  constructor(config: LiveModeConfig) {
    this.config = config;
    this.client = new KilnClient(config);
    this.subscriptionId = `sub_${randomUUID().replace(/-/g, '').slice(0, 32)}`;
  }

  /** Open the daemon and obtain the canonical projection. */
  public async start(): Promise<WorkbenchModel> {
    // Step 1: project.open — canonical state for the repository.
    const open = await this.client.call<{ path: string }, ProjectOpenResult>({
      method: 'project.open',
      params: { path: this.config.repository }
    });

    if (!open.ok) {
      throw new Error(`project.open failed: ${open.error.code} ${open.error.reason ?? ''}`);
    }

    const sessionId = open.result.session_id ?? undefined;

    // Step 2: subscribe to live activity.
    this.stream = new ActivityStream({
      ...this.config,
      subscriptionId: this.subscriptionId,
      ...(sessionId ? { sessionId } : {}),
      onActivity: (frame) => this.handleActivity(frame),
      onResync: (reason) => {
        void this.resync(reason);
      }
    });
    await this.stream.open();

    // Step 3: build the initial WorkbenchModel from the canonical
    // response. The render layer does not know whether the model came
    // from the filesystem or the daemon — that is the entire point of
    // preserving the WorkbenchSource seam.
    this.model = this.canonicalToModel(open.result);

    return this.model;
  }

  /** Stop the activity stream. */
  public async stop(): Promise<void> {
    if (this.stream) {
      this.stream.close();
      // exactOptionalPropertyTypes: `?:` fields cannot be assigned
      // undefined. Use delete to clear the optional slot.
      delete (this as unknown as { stream?: ActivityStream }).stream;
    }
  }

  public get currentModel(): WorkbenchModel | undefined {
    return this.model;
  }

  // -- private --

  private async resync(reason: 'stale' | 'gap' | 'reconnect'): Promise<void> {
    // Contract freeze §8: re-obtain canonical state from Kiln. We
    // do NOT trust local caches; we do NOT replay notifications
    // we happened to miss.
    const resp: RpcResponse<ProjectOpenResult> = await this.client.call<
      { path: string },
      ProjectOpenResult
    >({ method: 'project.open', params: { path: this.config.repository } });

    if (resp.ok) {
      this.model = this.canonicalToModel(resp.result);
      this.config.onProjection(this.model);
    } else {
      // Surface the error but do not silently succeed.
      throw new Error(`resync failed (${reason}): ${resp.error.code}`);
    }
  }

  private handleActivity(frame: ActivityNotificationFrame): void {
    this.config.onActivity?.(frame);
    // Trigger a resync on every notification — the contract freeze
    // §7 makes the event stream NOT authoritative.
    void this.resync('reconnect');
  }

  private canonicalToModel(c: ProjectOpenResult): WorkbenchModel {
    // Map the canonical RPC response into the existing WorkbenchModel
    // shape so the existing render.ts continues to work unmodified.
    const errors: string[] = [];
    if (c.orphaned) {
      errors.push(`session is orphaned: ${(c.unknowns ?? []).join(', ')}`);
    }
    return {
      repository: c.path,
      repositoryName: c.path.split('/').pop() ?? c.path,
      currentness: c.canonical_session_revision && c.canonical_session_revision > 0 ? 'current' : 'n/a',
      currentnessReason: `canonical_session_revision=${c.canonical_session_revision ?? 0}`,
      errors,
      sources: {
        kiln_home: { value: c.kiln_home, sourcePath: '(rpc)', command: 'project.open' },
        session_id: { value: c.session_id ?? '', sourcePath: '(rpc)', command: 'project.open' }
      }
    };
  }
}
