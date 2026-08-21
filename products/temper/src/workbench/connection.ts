/**
 * WorkbenchConnection owns Temper's canonical projection lifecycle.
 * Transport state is local; workflow state is always re-read from Kiln.
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
      method: 'project.open', params: { path: this.config.repository }
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
    if (!resp.ok) throw new Error(`session.start failed: ${resp.error.code} ${resp.error.reason ?? ''}`);
    const sessionId = resp.result?.session_id;
    if (!sessionId) throw new Error('session.start returned no session_id');
    this.projection = {
      ...this.projection,
      sessionId,
      canonicalSessionRevision: this.projection.canonicalSessionRevision ?? 0
    };
    await this.maybeQuerySession('open');
    this.emitProjection('open');
    return this.projection;
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

  /**
   * Force a real activity-transport reconnect, then replace local workflow
   * projection from canonical session.query. This is deliberately distinct
   * from resume/retry of any Run.
   */
  async reconnect(): Promise<WorkbenchProjection> {
    if (this.stopped) throw new Error('WorkbenchConnection is stopped');
    this.setConnection('reconnecting');
    if (this.stream) {
      this.stream.close();
      delete (this as unknown as { stream?: ActivityStream }).stream;
    }
    await this.startStream();
    if (this.projection.connection !== 'connected') {
      throw new Error('activity transport did not reconnect');
    }
    return this.resync('reconnect');
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
  ): Promise<{ ok: boolean; result?: Record<string, unknown>; errorCode?: string; errorReason?: string }> {
    if (!this.projection.sessionId) {
      return { ok: false, errorCode: 'E_NO_ACTIVE_SESSION', errorReason: 'project.open returned no session_id' };
    }
    const sq = this.projection.sessionQuery;
    const pending = sq?.pending_decision;
    const decisionId =
      pending && typeof pending === 'object' && typeof (pending as { id?: unknown }).id === 'string'
        ? (pending as { id: string }).id
        : null;
    if (!decisionId) {
      return { ok: false, errorCode: 'E_NO_PENDING_DECISION', errorReason: 'no canonical pending_decision on the live projection' };
    }
    const expectedSessionRevision = typeof sq?.session_revision === 'number' ? sq.session_revision : 0;
    const params: Record<string, unknown> = {
      plan_ref: envelope.plan_ref,
      patch_ref: envelope.patch_ref,
      result_state_digest: envelope.result_state_digest,
      decision,
      actor_id: actorId,
      ...(envelope.review_ref ? { review_ref: envelope.review_ref } : {}),
      session_id: this.projection.sessionId,
      decision_id: decisionId,
      expected_session_revision: expectedSessionRevision
    };
    const resp = await this.client.call<typeof params, Record<string, unknown>>({ method: 'human.decide', params });
    if (!resp.ok) return { ok: false, errorCode: resp.error.code, errorReason: resp.error.reason ?? '' };
    return { ok: true, result: resp.result };
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
  current(): WorkbenchProjection { return this.projection; }

  async stop(): Promise<void> {
    this.stopped = true;
    if (this.stream) {
      this.stream.close();
      delete (this as unknown as { stream?: ActivityStream }).stream;
    }
    this.setConnection('disconnected');
  }

  private async maybeQuerySession(source: 'open' | 'resync' | 'activity' | 'reconnect'): Promise<void> {
    if (!this.projection.sessionId) return;
    const query = await sessionQuery(this.client, this.projection.sessionId);
    if (query.ok && query.result) {
      this.projection = applySessionQuery(this.projection, query.result);
    } else if (!query.ok) {
      this.projection = {
        ...this.projection,
        lastError: `session.query failed: ${query.errorCode} ${query.errorReason ?? ''}`.trim()
      };
    }
  }

  private async startStream(): Promise<void> {
    if (this.stream) return;
    const sessionId = this.projection.sessionId ?? undefined;
    this.stream = new ActivityStream({
      ...this.config,
      subscriptionId: this.subscriptionId,
      ...(sessionId ? { sessionId } : {}),
      onActivity: (frame) => {
        if (this.stopped) return;
        for (const listener of this.activityListeners) listener(frame);
        void this.resync('activity');
      },
      onResync: (reason) => {
        if (this.stopped) return;
        if (reason === 'reconnect') {
          this.setConnection('reconnecting');
          void this.resync('reconnect').then(() => this.setConnection('connected'));
        } else {
          void this.resync('activity');
        }
      }
    });
    try {
      await this.stream.open();
      this.setConnection('connected');
    } catch {
      this.setConnection('disconnected');
    }
  }

  private setConnection(state: WorkbenchProjection['connection']): void {
    if (this.projection.connection === state) return;
    this.projection = { ...this.projection, connection: state };
    for (const listener of this.connectionListeners) listener(state);
  }
  private emitProjection(source: 'open' | 'resync' | 'activity' | 'reconnect'): void {
    for (const listener of this.projectionListeners) listener(this.projection, source);
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
