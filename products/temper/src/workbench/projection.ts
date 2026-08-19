/**
 * Temper Workbench Alpha — WorkbenchProjection.
 *
 * The canonical truth that the TUI renders. Built from project.open
 * and (if session_id is present) session.query. The TUI never builds
 * its own workflow boolean; it only consumes what the daemon reports.
 *
 * Every field is optional so the TUI can render a degraded view
 * (e.g. "session present but query failed") without inventing state.
 */

import type { ProjectOpenResult } from '../types.js';

export interface SessionQueryResult {
  session_id?: string;
  task_id?: string;
  root_run_id?: string;
  session_state?: string;
  task_state?: string;
  run_state?: string;
  workflow_step?: string;
  objective?: string;
  criteria?: string[];
  pending_decision?: unknown;
  operation?: unknown;
  verification_status?: 'PASS' | 'FAIL' | 'TIMEOUT' | 'ERROR' | 'PENDING' | 'NOT_RUN';
  review_status?: 'APPROVE' | 'REQUEST_REVISION' | 'REJECT' | 'PENDING' | 'NOT_RUN';
  human_status?: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION' | 'PENDING' | 'NOT_RUN';
  unknowns?: string[];
  objective_revision?: number;
  session_revision?: number;
  journal_head_digest?: string;
  projection_digest?: string;
  [key: string]: unknown;
}

export interface WorkbenchProjection {
  /** Repository path passed to project.open. */
  repository: string;
  /** Repository basename. */
  repositoryName: string;
  /** The bounded Kiln home directory (canonical convention: <repo>/.kiln). */
  kilnHome: string;
  /** Resolved session id, or null if no active session. */
  sessionId: string | null;
  /** Canonical session revision from project.open; monotonic. */
  canonicalSessionRevision: number | null;
  /** True when the journal is orphaned; the TUI surfaces "unknown" status. */
  orphaned: boolean;
  /** Unclassified effects from canonical reconstruction. */
  unknowns: string[];
  /** Full session projection from session.query; undefined if no session or query failed. */
  sessionQuery?: SessionQueryResult;
  /** The last error message from canonical hydration, if any. */
  lastError?: string;
  /** Connection state (not workflow state). */
  connection: 'connected' | 'reconnecting' | 'disconnected';
  /** Built at; the TUI may show it in the header. */
  builtAt: string;
}

export function projectionFromProjectOpen(open: ProjectOpenResult, repositoryName: string): WorkbenchProjection {
  return {
    repository: open.path,
    repositoryName,
    kilnHome: open.kiln_home,
    sessionId: open.session_id ?? null,
    canonicalSessionRevision: open.canonical_session_revision ?? null,
    orphaned: open.orphaned === true,
    unknowns: open.unknowns ?? [],
    connection: 'connected',
    builtAt: new Date().toISOString()
  };
}

export function applySessionQuery(
  projection: WorkbenchProjection,
  query: SessionQueryResult | undefined
): WorkbenchProjection {
  if (!query) return projection;
  return { ...projection, sessionQuery: query, builtAt: new Date().toISOString() };
}

/** Drop a sessionQuery from a projection (used when the session goes away). */
export function clearSessionQuery(projection: WorkbenchProjection): WorkbenchProjection {
  const next: WorkbenchProjection = {
    repository: projection.repository,
    repositoryName: projection.repositoryName,
    kilnHome: projection.kilnHome,
    sessionId: projection.sessionId,
    canonicalSessionRevision: projection.canonicalSessionRevision,
    orphaned: projection.orphaned,
    unknowns: projection.unknowns,
    connection: projection.connection,
    builtAt: projection.builtAt
  };
  if (projection.lastError !== undefined) {
    next.lastError = projection.lastError;
  }
  return next;
}

/** True when the canonical session is "complete" — driven by session.query, never by Temper. */
export function isSessionComplete(projection: WorkbenchProjection): boolean {
  return projection.sessionQuery?.human_status === 'ACCEPT';
}

/** True when the canonical session is "blocked" — pending a human decision. */
export function isSessionBlocked(projection: WorkbenchProjection): boolean {
  return projection.sessionQuery?.pending_decision != null
    || projection.sessionQuery?.human_status === 'PENDING'
    || projection.sessionQuery?.human_status === 'REQUEST_REVISION';
}
