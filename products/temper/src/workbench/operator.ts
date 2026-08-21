/**
 * Bounded operator RPC controller for slash commands.
 *
 * It owns no workflow state. Callers provide the latest canonical projection
 * for every consequential request; Kiln re-validates revision/state and is the
 * only authority that may accept the transition.
 */

import { KilnClient } from '../client.js';
import type { KilnClientConfig } from '../types.js';
import type { WorkbenchProjection } from './projection.js';

export interface OperatorResult<T = unknown> {
  ok: boolean;
  result?: T;
  errorCode?: string;
  errorReason?: string;
}

export interface SessionGraphNode {
  id: string;
  kind: string;
  canonical_digest: string;
  metadata: Record<string, unknown>;
}

export interface SessionGraphEdge {
  id: string;
  kind: string;
  from: string;
  to: string;
  canonical_basis: string;
  proposed: false;
}

export interface SessionGraph {
  schema: 'kiln/session-graph/v1';
  session_id: string;
  revision: number;
  projection_digest: string;
  source: string;
  orphaned: boolean;
  nodes: SessionGraphNode[];
  edges: SessionGraphEdge[];
}

export class OperatorController {
  private readonly client: KilnClient;

  constructor(config: KilnClientConfig) {
    this.client = new KilnClient(config);
  }

  async nextActions(projection: WorkbenchProjection): Promise<OperatorResult<string[]>> {
    const sessionId = projection.sessionId;
    if (!sessionId) return unavailable('E_NO_ACTIVE_SESSION', 'no canonical Session is open');
    const resp = await this.client.call<{ session_id: string }, unknown>({
      method: 'session.next_actions',
      params: { session_id: sessionId }
    });
    if (!resp.ok) return rpcFailure(resp.error.code, resp.error.reason);
    if (!Array.isArray(resp.result)) {
      return unavailable('E_INVALID_NEXT_ACTIONS', 'Kiln returned a non-list next-actions result');
    }
    return { ok: true, result: resp.result.filter((item): item is string => typeof item === 'string') };
  }

  async cancel(projection: WorkbenchProjection, actorId: string): Promise<OperatorResult<Record<string, unknown>>> {
    return this.transition('session.cancel', projection, actorId);
  }

  async resume(projection: WorkbenchProjection, actorId: string): Promise<OperatorResult<Record<string, unknown>>> {
    return this.transition('session.resume', projection, actorId);
  }

  async graph(projection: WorkbenchProjection): Promise<OperatorResult<SessionGraph>> {
    const sessionId = projection.sessionId;
    if (!sessionId) return unavailable('E_NO_ACTIVE_SESSION', 'no canonical Session is open');
    const resp = await this.client.call<{ session_id: string }, SessionGraph>({
      method: 'graph.query',
      params: { session_id: sessionId }
    });
    if (!resp.ok) return rpcFailure(resp.error.code, resp.error.reason);
    return { ok: true, result: resp.result };
  }

  async doctor(projection: WorkbenchProjection): Promise<OperatorResult<string[]>> {
    const checks: string[] = [];
    checks.push(`transport=${projection.connection}`);
    checks.push(`project=${projection.repository}`);
    checks.push(`session=${projection.sessionId ?? 'none'}`);
    if (projection.lastError) checks.push(`last_error=${projection.lastError}`);

    if (projection.sessionId) {
      const next = await this.nextActions(projection);
      checks.push(next.ok ? `session_rpc=ok next_actions=${(next.result ?? []).join(',') || 'none'}` : `session_rpc=failed ${next.errorCode ?? 'E_UNKNOWN'} ${next.errorReason ?? ''}`.trim());
      const graph = await this.graph(projection);
      checks.push(graph.ok ? `graph_rpc=ok nodes=${graph.result?.nodes.length ?? 0} edges=${graph.result?.edges.length ?? 0}` : `graph_rpc=failed ${graph.errorCode ?? 'E_UNKNOWN'} ${graph.errorReason ?? ''}`.trim());
    } else {
      checks.push('session_rpc=not_applicable');
      checks.push('graph_rpc=not_applicable');
    }

    return { ok: true, result: checks };
  }

  private async transition(
    method: 'session.cancel' | 'session.resume',
    projection: WorkbenchProjection,
    actorId: string
  ): Promise<OperatorResult<Record<string, unknown>>> {
    const sessionId = projection.sessionId;
    if (!sessionId) return unavailable('E_NO_ACTIVE_SESSION', 'no canonical Session is open');
    const revision = projection.sessionQuery?.session_revision;
    if (typeof revision !== 'number') {
      return unavailable('E_SESSION_REVISION_UNAVAILABLE', 'canonical session_revision is unavailable');
    }
    const params = {
      session_id: sessionId,
      actor_id: actorId,
      expected_session_revision: revision
    };
    const resp = await this.client.call<typeof params, Record<string, unknown>>({ method, params });
    if (!resp.ok) return rpcFailure(resp.error.code, resp.error.reason);
    return { ok: true, result: resp.result };
  }
}

function unavailable<T>(errorCode: string, errorReason: string): OperatorResult<T> {
  return { ok: false, errorCode, errorReason };
}

function rpcFailure<T>(errorCode: string, errorReason?: string): OperatorResult<T> {
  return { ok: false, errorCode, errorReason: errorReason ?? '' };
}
