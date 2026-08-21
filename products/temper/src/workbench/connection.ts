/**
 * Temper Workbench Alpha — WorkbenchConnection.
 *
 * Owns the canonical projection lifecycle:
 *   1. project.open  → bounds the projection to a repository
 *   2. session.query → if session_id is present, hydrate the full Session
 *   3. activity.subscribe → stream canonical state changes
 *   4. on every activity frame → re-run session.query (canonical resync)
 *
 * The connection never invents state. It only forwards what Kiln
 * reports. The TUI is a pure consumer of `onProjection` callbacks.
 *
 * Authority rule: WorkbenchConnection never holds a workflow boolean.
 * `connection` is transport state, not workflow state.
 */

import path from 'node:path';
import { createHash, randomUUID } from 'node:crypto';
import { KilnClient } from '../client.js';
import { ActivityStream } from '../stream.js';
import type { ActivityNotificationFrame, KilnClientConfig, ProjectOpenResult } from '../types.js';
import type { WorkbenchProjection } from './projection.js';
import { applySessionQuery, projectionFromProjectOpen } from './projection.js';
import { sessionQuery } from './session_query.js';

export interface WorkbenchConnectionConfig extends KilnClientConfig {
  repository: string;
  autoStartOnEmpty?: boolean;
}

export type ProjectionListener = (projection: WorkbenchProjection, source: 'open' | 'resync' | 'activity' | 'reconnect') => void;
export type ConnectionListener = (state: WorkbenchProjection['connection']) => void;
export type ActivityListener = (frame: ActivityNotificationFrame) => void;

export interface BoundedCommandResult {
  ok: boolean;
  result?: Record<string, unknown>;
  errorCode?: string;
  errorReason?: string;
}

interface CanonicalConfirmation {
  session_id: string;
  session_revision: number | null;
  session_state: string | null;
  run_state: string | null;
  workflow_step: string | null;
}

export class WorkbenchConnection {
  private readonly config: WorkbenchConnectionConfig;
  private readonly client: KilnClient;
  private stream?: ActivityStream;
  private projection: WorkbenchProjection;
  private readonly projectionListeners = new Set<ProjectionListener>();
  private readonly connectionListeners = new Set<ConnectionListener>();
  private readonly activityListeners = new Set<ActivityListener>();
  private readonly subscriptionId: string;
  private resyncInFlight = false;
  private stopped = false;

  constructor(config: WorkbenchConnectionConfig) {
    this.config = config;
    this.client = new KilnClient(config);
    this.projection = this.emptyProjection();
    this.subscriptionId = `sub_${randomUUID().replace(/-/g, '').slice(0, 32)}`;
  }

  async open(): Promise<WorkbenchProjection> {
    const openResp = await this.client.call<{ path: string }, ProjectOpenResult>({
      method: 'project.open',
      params: { path: this.config.repository }
    });
    if (!openResp.ok) {
      const err: WorkbenchProjection['lastError'] = `${openResp.error.code} ${openResp.error.reason ?? ''}`.trim();
      this.projection = { ...this.emptyProjection(), lastError: err };
      this.emitProjection('open');
      throw new Error(`project.open failed: ${err}`);
    }

    this.projection = projectionFromProjectOpen(openResp.result, path.basename(this.config.repository));
    await this.maybeQuerySession('open');
    this.emitProjection('open');
    await this.startStream();
    return this.projection;
  }

  /**
   * Begin a new Session and canonically confirm it. The activity subscription
   * is then rebound to that exact Session ID. Failure to rebind the stream
   * does not undo or falsely reject a Session that Kiln already created and
   * canonically confirmed; the projection instead remains disconnected and
   * the stream's bounded retry machinery continues from the new instance.
   */
  async startSession(intent: string, actorId: string): Promise<WorkbenchProjection> {
    const projectObservation = buildProjectObservation(this.config.repository);
    const resp = await this.client.call<Record<string, unknown>, { session_id?: string }>({
      method: 'session.start',
      params: {
        objective: intent,
        criteria: ['operator-submitted intent'],
        actor_id: actorId,
        project_observation: projectObservation
      }
    });
    if (!resp.ok) {
      throw new Error(`session.start failed: ${resp.error.code} ${resp.error.reason ?? ''}`);
    }
    const sessionId = resp.result?.session_id;
    if (!sessionId) throw new Error('session.start returned no session_id');

    this.projection = {
      ...this.projection,
      sessionId,
      canonicalSessionRevision: this.projection.canonicalSessionRevision ?? 0
    };
    await this.maybeQuerySession('open');
    this.emitProjection('open');

    const confirmation = this.confirmCanonicalSession(sessionId);
    if (!confirmation.ok) {
      throw new Error(
        `session.start accepted by Kiln but canonical confirmation failed: ${confirmation.reason}`
      );
    }

    await this.rebindActivityStream();
    return this.projection;
  }

  async cancelSession(actorId: string): Promise<BoundedCommandResult> {
    return this.sessionLifecycle('session.cancel', actorId);
  }

  async resumeSession(actorId: string): Promise<BoundedCommandResult> {
    return this.sessionLifecycle('session.resume', actorId);
  }

  async nextActions(): Promise<BoundedCommandResult> {
    if (!this.projection.sessionId) {
      return { ok: false, errorCode: 'E_NO_ACTIVE_SESSION', errorReason: 'project.open returned no session_id' };
    }
    const resp = await this.client.call<{ session_id: string }, Record<string, unknown>>({
      method: 'session.next_actions',
      params: { session_id: this.projection.sessionId }
    });
    if (!resp.ok) {
      return { ok: false, errorCode: resp.error.code, errorReason: resp.error.reason ?? '' };
    }
    return { ok: true, result: resp.result };
  }

  /** Manual reconnect succeeds only when the replacement WS really opens. */
  async reconnect(): Promise<WorkbenchProjection> {
    this.retireActivityStream();
    this.stopped = false;
    this.setConnection('reconnecting');
    try {
      const projection = await this.open();
      if (projection.connection !== 'connected') {
        throw new Error(`activity transport did not reconnect; state=${projection.connection}`);
      }
      if (projection.sessionId) {
        const confirmation = this.confirmCanonicalSession(projection.sessionId);
        if (!confirmation.ok) {
          this.retireActivityStream();
          this.setConnection('disconnected');
          throw new Error(`canonical confirmation failed after reconnect: ${confirmation.reason}`);
        }
      }
      return projection;
    } catch (err) {
      this.setConnection('disconnected');
      throw err;
    }
  }

  async resync(reason: 'activity' | 'reconnect' | 'resync' = 'resync'): Promise<WorkbenchProjection> {
    if (this.resyncInFlight) return this.projection;
    this.resyncInFlight = true;
    try {
      await this.maybeQuerySession(reason);
      this.emitProjection(reason);
    } finally {
      this.resyncInFlight = false;
    }
    return this.projection;
  }

  async submitHumanDecision(
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION',
    envelope: {
      plan_ref: { id: string; digest: string };
      patch_ref: { id: string; digest: string };
      result_state_digest: string;
      review_ref?: { id: string; digest: string } | null;
    },
    actorId: string
  ): Promise<BoundedCommandResult> {
    if (!this.projection.sessionId) {
      return { ok: false, errorCode: 'E_NO_ACTIVE_SESSION', errorReason: 'project.open returned no session_id' };
    }
    const sessionId = this.projection.sessionId;
    const sq = this.projection.sessionQuery;
    const pending = sq?.pending_decision;
    const decisionId =
      pending && typeof pending === 'object' && typeof (pending as { id?: unknown }).id === 'string'
        ? ((pending as { id: string }).id)
        : null;
    if (!decisionId) {
      return {
        ok: false,
        errorCode: 'E_NO_PENDING_DECISION',
        errorReason: 'no canonical pending_decision on the live projection'
      };
    }
    const expectedSessionRevision =
      typeof sq?.session_revision === 'number' ? (sq.session_revision as number) : 0;
    const params: Record<string, unknown> = {
      plan_ref: envelope.plan_ref,
      patch_ref: envelope.patch_ref,
      result_state_digest: envelope.result_state_digest,
      decision,
      actor_id: actorId,
      ...(envelope.review_ref ? { review_ref: envelope.review_ref } : {}),
      session_id: sessionId,
      decision_id: decisionId,
      expected_session_revision: expectedSessionRevision
    };
    const resp = await this.client.call<typeof params, Record<string, unknown>>({
      method: 'human.decide',
      params
    });
    if (!resp.ok) {
      return {
        ok: false,
        errorCode: resp.error.code,
        errorReason: resp.error.reason ?? ''
      };
    }

    await this.maybeQuerySession('resync');
    this.emitProjection('resync');
    const confirmation = this.confirmCanonicalSession(sessionId);
    if (!confirmation.ok) {
      return {
        ok: false,
        errorCode: 'E_CANONICAL_CONFIRMATION_FAILED',
        errorReason:
          `human.decide was accepted by Kiln but post-operation canonical confirmation failed; effect is unknown: ${confirmation.reason}`
      };
    }

    return {
      ok: true,
      result: {
        ...(resp.result ?? {}),
        canonical_confirmation: confirmation.value
      }
    };
  }

  onProjection(listener: ProjectionListener): () => void {
    this.projectionListeners.add(listener);
    return () => this.projectionListeners.delete(listener);
  }

  onConnection(listener: ConnectionListener): () => void {
    this.connectionListeners.add(listener);
    return () => this.connectionListeners.delete(listener);
  }

  onActivity(listener: ActivityListener): () => void {
    this.activityListeners.add(listener);
    return () => this.activityListeners.delete(listener);
  }

  current(): WorkbenchProjection {
    return this.projection;
  }

  async stop(): Promise<void> {
    this.stopped = true;
    this.retireActivityStream();
  }

  // -- private --

  private async sessionLifecycle(
    method: 'session.cancel' | 'session.resume',
    actorId: string
  ): Promise<BoundedCommandResult> {
    const sessionId = this.projection.sessionId;
    if (!sessionId) {
      return { ok: false, errorCode: 'E_NO_ACTIVE_SESSION', errorReason: 'project.open returned no session_id' };
    }
    const revision = this.projection.sessionQuery?.session_revision ?? this.projection.canonicalSessionRevision;
    if (typeof revision !== 'number' || revision < 0) {
      return {
        ok: false,
        errorCode: 'E_SESSION_REVISION_UNAVAILABLE',
        errorReason: 'no canonical session revision is available for a mutating lifecycle operation'
      };
    }
    const params = {
      session_id: sessionId,
      actor_id: actorId,
      expected_session_revision: revision
    };
    const resp = await this.client.call<typeof params, Record<string, unknown>>({ method, params });
    if (!resp.ok) {
      return { ok: false, errorCode: resp.error.code, errorReason: resp.error.reason ?? '' };
    }

    await this.maybeQuerySession('resync');
    this.emitProjection('resync');
    const confirmation = this.confirmCanonicalSession(sessionId);
    if (!confirmation.ok) {
      return {
        ok: false,
        errorCode: 'E_CANONICAL_CONFIRMATION_FAILED',
        errorReason:
          `${method} was accepted by Kiln but post-operation canonical confirmation failed; effect is unknown: ${confirmation.reason}`
      };
    }

    return {
      ok: true,
      result: {
        ...(resp.result ?? {}),
        canonical_confirmation: confirmation.value
      }
    };
  }

  private confirmCanonicalSession(
    expectedSessionId: string
  ): { ok: true; value: CanonicalConfirmation } | { ok: false; reason: string } {
    if (this.projection.lastError) return { ok: false, reason: this.projection.lastError };
    const query = this.projection.sessionQuery;
    if (!query) return { ok: false, reason: 'session.query returned no canonical projection' };
    if (query.session_id && query.session_id !== expectedSessionId) {
      return {
        ok: false,
        reason: `session.query returned ${query.session_id}, expected ${expectedSessionId}`
      };
    }
    return {
      ok: true,
      value: {
        session_id: expectedSessionId,
        session_revision:
          typeof query.session_revision === 'number' ? query.session_revision : this.projection.canonicalSessionRevision,
        session_state: typeof query.session_state === 'string' ? query.session_state : null,
        run_state: typeof query.run_state === 'string' ? query.run_state : null,
        workflow_step: typeof query.workflow_step === 'string' ? query.workflow_step : null
      }
    };
  }

  private async maybeQuerySession(source: 'open' | 'resync' | 'activity' | 'reconnect'): Promise<void> {
    if (!this.projection.sessionId) return;
    const query = await sessionQuery(this.client, this.projection.sessionId);
    if (query.ok && query.result) {
      const next = applySessionQuery(this.projection, query.result);
      const { lastError: _staleError, ...confirmed } = next;
      this.projection = confirmed;
    } else if (!query.ok) {
      this.projection = {
        ...this.projection,
        lastError: `session.query failed: ${query.errorCode} ${query.errorReason ?? ''}`.trim()
      };
    }
  }

  private async rebindActivityStream(): Promise<void> {
    this.retireActivityStream();
    try {
      await this.startStream();
    } catch {
      // The Session is already canonically confirmed. Preserve that fact and
      // surface disconnected transport state; ActivityStream owns bounded
      // reconnect retries for its failed replacement socket.
    }
  }

  private retireActivityStream(): void {
    if (!this.stream) return;
    this.stream.close();
    delete (this as unknown as { stream?: ActivityStream }).stream;
  }

  private async startStream(): Promise<void> {
    if (this.stream) return;
    const sessionId = this.projection.sessionId ?? undefined;
    this.stream = new ActivityStream({
      ...this.config,
      subscriptionId: this.subscriptionId,
      ...(sessionId ? { sessionId } : {}),
      onConnectionState: (state) => {
        if (!this.stopped) this.setConnection(state);
      },
      onActivity: (frame) => {
        if (this.stopped) return;
        for (const l of this.activityListeners) l(frame);
        void this.resync('activity');
      },
      onResync: (reason) => {
        if (this.stopped) return;
        if (reason === 'reconnect') void this.resync('reconnect');
        else void this.resync('activity');
      }
    });
    try {
      await this.stream.open();
      this.setConnection('connected');
    } catch (err) {
      this.setConnection('disconnected');
      throw err;
    }
  }

  private setConnection(state: WorkbenchProjection['connection']): void {
    if (this.projection.connection === state) return;
    this.projection = { ...this.projection, connection: state };
    for (const l of this.connectionListeners) l(state);
    // Home consumes projection callbacks rather than the Work-only connection
    // listener. Push transport changes through the same projection channel so
    // no screen can retain a stale connection claim.
    this.emitProjection('reconnect');
  }

  private emitProjection(source: 'open' | 'resync' | 'activity' | 'reconnect'): void {
    for (const l of this.projectionListeners) l(this.projection, source);
  }

  private emptyProjection(): WorkbenchProjection {
    return {
      repository: this.config.repository,
      repositoryName: path.basename(this.config.repository),
      kilnHome: path.join(this.config.repository, '.kiln'),
      sessionId: null,
      canonicalSessionRevision: null,
      orphaned: false,
      unknowns: [],
      connection: 'disconnected',
      builtAt: new Date().toISOString()
    };
  }
}

function buildProjectObservation(repositoryRoot: string): {
  repository_root: string;
  repository_fingerprint: string;
  observed_at: string;
} {
  const hash = createHash('sha256').update(repositoryRoot).digest('hex');
  return {
    repository_root: repositoryRoot,
    repository_fingerprint: `sha256:${hash}`,
    observed_at: new Date().toISOString()
  };
}
