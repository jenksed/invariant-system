/**
 * Temper Workbench Alpha — typed session.query wrapper.
 *
 * session.query (Kiln.RPC.Handlers.Session) calls
 * `Kiln.Workflow.query_session/1`. The result map is whatever the
 * Workflow returns. We surface the canonical field names we render
 * and accept the full map unchanged in `raw` for inspection.
 */

import type { KilnClient } from '../client.js';
import type { SessionQueryResult } from './projection.js';

export interface SessionQueryResponse {
  ok: boolean;
  result?: SessionQueryResult;
  raw?: unknown;
  errorCode?: string;
  errorReason?: string;
}

export async function sessionQuery(
  client: KilnClient,
  sessionId: string
): Promise<SessionQueryResponse> {
  const resp = await client.call<{ session_id: string }, unknown>({
    method: 'session.query',
    params: { session_id: sessionId }
  });
  if (!resp.ok) {
    return {
      ok: false,
      errorCode: resp.error.code,
      errorReason: resp.error.reason ?? ''
    };
  }
  const raw = resp.result as Record<string, unknown>;
  return { ok: true, result: raw as SessionQueryResult, raw };
}
