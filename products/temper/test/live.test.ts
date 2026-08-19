/**
 * WP-09 Lane 3 tests for the Temper HTTP client + activity stream.
 *
 * Property coverage:
 *   - contract freeze §3: bounded error codes pass through the client
 *     without flattening.
 *   - contract freeze §5: idempotency_key + request_digest are
 *     included verbatim on the wire when provided.
 *   - contract freeze §7: stale notifications are discarded.
 *   - contract freeze §7: gap notifications trigger resync.
 *   - contract freeze §7: duplicate notifications are discarded.
 *   - contract freeze §4: scope-table routing picks the correct token.
 */

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { KilnClient, KilnRpcError } from '../src/client.js';
import { ActivityStream } from '../src/stream.js';
import type {
  ActivityNotificationFrame,
  RpcError,
  RpcResponse
} from '../src/types.js';

// -- fake fetch --
type FetchFn = typeof fetch;

function makeFakeFetch(handler: (url: string, init: RequestInit) => Response | Promise<Response>): FetchFn {
  return (async (url: any, init?: any) => {
    return Promise.resolve(handler(String(url), (init ?? {}) as RequestInit));
  }) as unknown as FetchFn;
}

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' }
  });
}

const baseConfig = {
  baseUrl: 'http://127.0.0.1:4000',
  wsUrl: 'ws://127.0.0.1:4000/ws',
  readToken: 'READ',
  operateToken: 'OPERATE'
};

test('KilnClient.send uses the read token for orchestration:read methods', async () => {
  let capturedAuth: string | null = null;
  const fetch = makeFakeFetch((_url, init) => {
    capturedAuth = (init.headers as Record<string, string>)['authorization'] ?? null;
    return jsonResponse(200, { projects: [] });
  });

  const client = new KilnClient({ ...baseConfig });
  (client as any).fetch = fetch;

  await client.call({ method: 'project.list', params: {} });

  assert.equal(capturedAuth, 'Bearer READ');
});

test('KilnClient.send uses the operate token for orchestration:operate methods', async () => {
  let capturedAuth: string | null = null;
  const fetch = makeFakeFetch((_url, init) => {
    capturedAuth = (init.headers as Record<string, string>)['authorization'] ?? null;
    return jsonResponse(200, { status: 'opened' });
  });

  const client = new KilnClient({ ...baseConfig });
  (client as any).fetch = fetch;

  await client.call({ method: 'project.open', params: { path: '/tmp/x' } });

  assert.equal(capturedAuth, 'Bearer OPERATE');
});

test('KilnClient surfaces bounded error codes without flattening (P5)', async () => {
  // The daemon's wire envelope is FLAT: { code, reason, scope, method, fields, field }
  // (see Kiln.RPC.Error.do_bounded/2 at lib/kiln/rpc/error.ex:50-71). The
  // client must read body.code directly without inventing a wrapper.
  const fetch = makeFakeFetch(() =>
    jsonResponse(400, {
      code: 'E_MUTATION_UNKNOWN_EFFECT',
      reason: 'do not retry'
    })
  );

  const client = new KilnClient({ ...baseConfig });
  (client as any).fetch = fetch;

  const resp: RpcResponse<unknown> = await client.call({ method: 'patch.apply', params: {} });

  assert.equal(resp.ok, false);
  if (!resp.ok) {
    assert.equal(resp.error.code, 'E_MUTATION_UNKNOWN_EFFECT');
    assert.equal(resp.error.reason, 'do not retry');
  }
});

test('KilnClient unwrap throws KilnRpcError preserving code', async () => {
  const fetch = makeFakeFetch(() =>
    jsonResponse(400, { code: 'E_SCOPE_INSUFFICIENT', method: 'worker.propose' })
  );
  const client = new KilnClient({ ...baseConfig });
  (client as any).fetch = fetch;

  // Use a method that IS in the SCOPE_TABLE so the fetch is actually
  // invoked. The mock returns E_SCOPE_INSUFFICIENT and the client
  // surfaces it via KilnRpcError.
  await assert.rejects(
    async () => KilnClient.unwrap<unknown>(await client.call({ method: 'worker.propose', params: {} })),
    (err: KilnRpcError) => err.rpcError.code === 'E_SCOPE_INSUFFICIENT'
  );
});

test('KilnClient forwards idempotency_key + request_digest on the wire', async () => {
  let capturedBody: any = null;
  const fetch = makeFakeFetch((_url, init) => {
    capturedBody = JSON.parse(init.body as string);
    return jsonResponse(200, { ok: true });
  });

  const client = new KilnClient({ ...baseConfig });
  (client as any).fetch = fetch;

  await client.call({
    method: 'patch.apply',
    params: { foo: 'bar' },
    idempotency_key: 'idem_xxx',
    request_digest: 'sha256:0'
  });

  assert.equal(capturedBody.idempotency_key, 'idem_xxx');
  assert.equal(capturedBody.request_digest, 'sha256:0');
  assert.equal(capturedBody.method, 'patch.apply');
});

// -- ActivityStream test (purely synchronous, no real WS) --

test('ActivityStream discards stale notifications (revision < lastObservedRevision)', () => {
  const stream = new ActivityStream({
    ...baseConfig,
    subscriptionId: 'sub_x',
    onActivity: () => {
      throw new Error('stale should not be delivered');
    }
  });

  // simulate: process a notification, then a stale one
  const fresh: ActivityNotificationFrame = {
    type: 'activity.notification',
    subscription_id: 'sub_x',
    revision: 5,
    emitted_at: '2026-08-19T00:00:00Z',
    subject: { kind: 'session', id: 'ses_x' },
    event_kind: 'state_changed',
    canonical_session_revision: 5
  };

  let delivered = 0;
  // swap onActivity for the fresh delivery
  (stream as any).config = { ...(stream as any).config, onActivity: () => { delivered += 1; } };
  (stream as any).handleFrame(JSON.stringify(fresh));
  assert.equal(delivered, 1);

  const stale: ActivityNotificationFrame = { ...fresh, revision: 3 };
  (stream as any).handleFrame(JSON.stringify(stale));
  assert.equal(delivered, 1, 'stale should be discarded');
});

test('ActivityStream discards duplicate notifications', () => {
  const stream = new ActivityStream({
    ...baseConfig,
    subscriptionId: 'sub_x'
  });

  let delivered = 0;
  (stream as any).config = { ...(stream as any).config, onActivity: () => { delivered += 1; } };

  const frame: ActivityNotificationFrame = {
    type: 'activity.notification',
    subscription_id: 'sub_x',
    revision: 1,
    emitted_at: '2026-08-19T00:00:00Z',
    subject: { kind: 'session', id: 'ses_x' },
    event_kind: 'state_changed',
    canonical_session_revision: 1
  };

  (stream as any).handleFrame(JSON.stringify(frame));
  (stream as any).handleFrame(JSON.stringify(frame));
  assert.equal(delivered, 1, 'duplicate should be discarded');
});

test('ActivityStream triggers resync on revision gap', () => {
  let resyncReason: string | null = null;
  const stream = new ActivityStream({
    ...baseConfig,
    subscriptionId: 'sub_x',
    onResync: (r) => {
      resyncReason = r;
    }
  });

  (stream as any).lastObservedRevision = 5;

  const gapFrame: ActivityNotificationFrame = {
    type: 'activity.notification',
    subscription_id: 'sub_x',
    revision: 8,
    emitted_at: '2026-08-19T00:00:00Z',
    subject: { kind: 'session', id: 'ses_x' },
    event_kind: 'state_changed',
    canonical_session_revision: 8
  };

  (stream as any).handleFrame(JSON.stringify(gapFrame));
  assert.equal(resyncReason, 'gap');
});
