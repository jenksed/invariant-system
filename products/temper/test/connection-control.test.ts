import assert from 'node:assert/strict';
import test from 'node:test';
import { WorkbenchConnection } from '../src/workbench/connection.js';
import type { WorkbenchProjection } from '../src/workbench/projection.js';

const config = {
  baseUrl: 'http://127.0.0.1:4000',
  wsUrl: 'ws://127.0.0.1:4000/ws',
  readToken: 'READ',
  operateToken: 'OPERATE',
  repository: '/tmp/repo'
};

const sessionId = 'ses_0123456789abcdef0123456789abcdef';

function initialProjection(): WorkbenchProjection {
  return {
    repository: '/tmp/repo',
    repositoryName: 'repo',
    kilnHome: '/tmp/repo/.kiln',
    sessionId,
    canonicalSessionRevision: 7,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: '2026-08-20T00:00:00.000Z',
    sessionQuery: {
      session_id: sessionId,
      session_revision: 7,
      run_state: 'ready'
    }
  };
}

test('cancel reports success only after canonical session.query confirms the post-operation Session', async () => {
  const connection = new WorkbenchConnection(config);
  (connection as unknown as { projection: WorkbenchProjection }).projection = initialProjection();

  const methods: string[] = [];
  (connection as unknown as { client: { call: (request: { method: string }) => Promise<unknown> } }).client = {
    call: async (request) => {
      methods.push(request.method);
      if (request.method === 'session.cancel') {
        return { ok: true, result: { accepted: true } };
      }
      if (request.method === 'session.query') {
        return {
          ok: true,
          result: {
            session_id: sessionId,
            projection: {
              session_revision: 8,
              run: { state: 'cancelled' }
            }
          }
        };
      }
      throw new Error(`unexpected method ${request.method}`);
    }
  };

  const result = await connection.cancelSession('operator');

  assert.equal(result.ok, true);
  assert.deepEqual(methods, ['session.cancel', 'session.query']);
  assert.deepEqual(result.result?.canonical_confirmation, {
    session_id: sessionId,
    session_revision: 8,
    session_state: null,
    run_state: 'cancelled',
    workflow_step: null
  });
});

test('accepted mutation becomes unknown-effect error when canonical confirmation cannot be read', async () => {
  const connection = new WorkbenchConnection(config);
  (connection as unknown as { projection: WorkbenchProjection }).projection = initialProjection();

  (connection as unknown as { client: { call: (request: { method: string }) => Promise<unknown> } }).client = {
    call: async (request) => {
      if (request.method === 'session.resume') {
        return { ok: true, result: { accepted: true } };
      }
      if (request.method === 'session.query') {
        return {
          ok: false,
          error: { code: 'E_STORE_UNAVAILABLE', reason: 'cannot read canonical Session' }
        };
      }
      throw new Error(`unexpected method ${request.method}`);
    }
  };

  const result = await connection.resumeSession('operator');

  assert.equal(result.ok, false);
  assert.equal(result.errorCode, 'E_CANONICAL_CONFIRMATION_FAILED');
  assert.match(result.errorReason ?? '', /accepted by Kiln/);
  assert.match(result.errorReason ?? '', /effect is unknown/);
});

test('successful canonical query clears stale hydration error', async () => {
  const connection = new WorkbenchConnection(config);
  (connection as unknown as { projection: WorkbenchProjection }).projection = {
    ...initialProjection(),
    lastError: 'session.query failed: E_TEMPORARY stale failure'
  };

  (connection as unknown as { client: { call: (request: { method: string }) => Promise<unknown> } }).client = {
    call: async (request) => {
      if (request.method !== 'session.query') throw new Error(`unexpected method ${request.method}`);
      return {
        ok: true,
        result: {
          session_id: sessionId,
          projection: { session_revision: 8, run: { state: 'ready' } }
        }
      };
    }
  };

  const projection = await connection.resync('resync');
  assert.equal(projection.lastError, undefined);
  assert.equal(projection.sessionQuery?.session_revision, 8);
});
