/**
 * Temper Workbench alpha — typed session.query wrapper.
 *
 * session.query (Kiln.RPC.Handlers.Session) calls
 * `Kiln.Workflow.query_session/1`. The wire response is the bounded
 * query envelope:
 *
 *   { session_id, projection, source, projection_digest,
 *     journal_head_digest, orphaned }
 *
 * where `projection` is the canonical Session projection map:
 *
 *   { schema, session_revision, run.state, run.human.status,
 *     run.verification.status, run.review.status, pending_decision,
 *     references.decision_envelope, criteria, objective, ... }
 *
 * The WorkbenchProjection.sessionQuery field represents the canonical
 * Temper projection (per M1 boundary contract), NOT the complete
 * transport envelope. We therefore normalize the wire shape into the
 * canonical flat field set the Workbench renders — run_state,
 * human_status, verification_status, review_status, pending_decision,
 * references, projection_digest at top level — by lifting them out
 * of `projection`. Transport-only fields (source, journal_head_digest,
 * orphaned, schema, reducer_version) are kept under `transport` for
 * diagnostics, never on the canonical path.
 *
 * `raw` retains the full transport envelope for inspection.
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
  const result = normalizeSessionQuery(raw);
  return { ok: true, result, raw };
}

/**
 * Normalize the bounded query envelope into the canonical Workbench
 * projection shape. Pure function; no IO, no side effects.
 */
export function normalizeSessionQuery(
  wire: Record<string, unknown>
): SessionQueryResult {
  const projection =
    (wire['projection'] && typeof wire['projection'] === 'object'
      ? (wire['projection'] as Record<string, unknown>)
      : {}) as Record<string, unknown>;
  const run =
    (projection['run'] && typeof projection['run'] === 'object'
      ? (projection['run'] as Record<string, unknown>)
      : {}) as Record<string, unknown>;
  const human =
    (run['human'] && typeof run['human'] === 'object'
      ? (run['human'] as Record<string, unknown>)
      : {}) as Record<string, unknown>;
  const verification =
    (run['verification'] && typeof run['verification'] === 'object'
      ? (run['verification'] as Record<string, unknown>)
      : {}) as Record<string, unknown>;
  const review =
    (run['review'] && typeof run['review'] === 'object'
      ? (run['review'] as Record<string, unknown>)
      : {}) as Record<string, unknown>;
  const references =
    (projection['references'] && typeof projection['references'] === 'object'
      ? (projection['references'] as Record<string, unknown>)
      : {}) as Record<string, unknown>;

  const result: Record<string, unknown> = {};

  // Top-level transport → canonical scalars
  if (typeof wire['session_id'] === 'string') result['session_id'] = wire['session_id'];
  if (typeof wire['projection_digest'] === 'string') {
    result['projection_digest'] = wire['projection_digest'];
  }
  if (typeof wire['orphaned'] === 'boolean') result['orphaned'] = wire['orphaned'];

  // Flattened from projection.*
  if (typeof run['state'] === 'string') result['run_state'] = run['state'];
  if (typeof human['status'] === 'string') result['human_status'] = human['status'];
  if (typeof verification['status'] === 'string') {
    result['verification_status'] = verification['status'];
  }
  if (typeof review['status'] === 'string') result['review_status'] = review['status'];
  if (typeof projection['session_revision'] === 'number') {
    result['session_revision'] = projection['session_revision'];
  }
  if (projection['pending_decision'] !== undefined) {
    result['pending_decision'] = projection['pending_decision'];
  }
  if (Object.keys(references).length > 0) {
    result['references'] = references;
  }

  // Diagnostic-only transport envelope (NEVER on the canonical path).
  const transport: Record<string, unknown> = {};
  if (typeof wire['source'] === 'string') transport['source'] = wire['source'];
  if (typeof wire['journal_head_digest'] === 'string') {
    transport['journal_head_digest'] = wire['journal_head_digest'];
  }
  if (Object.keys(transport).length > 0) {
    result['transport'] = transport;
  }

  return result as SessionQueryResult;
}