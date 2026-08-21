import assert from 'node:assert/strict';
import test from 'node:test';
import { ActivityStream } from '../src/stream.js';

const baseConfig = {
  baseUrl: 'http://127.0.0.1:4000',
  wsUrl: 'ws://127.0.0.1:4000/ws',
  readToken: 'READ',
  operateToken: 'OPERATE'
};

test('ActivityStream intentional close permanently suppresses reconnect scheduling', () => {
  let reconnectSignals = 0;
  let closeCalls = 0;
  const stream = new ActivityStream({
    ...baseConfig,
    subscriptionId: 'sub_close_guard',
    onResync: (reason) => {
      if (reason === 'reconnect') reconnectSignals += 1;
    }
  });

  // Install the smallest fake socket necessary to exercise the public
  // close lifecycle. We then invoke the private scheduling seam through
  // a test-only structural cast: if close() did not latch the manual
  // lifecycle guard this would schedule a timer and eventually reopen.
  (stream as unknown as { ws: { close: (code: number, reason: string) => void } }).ws = {
    close: (code, reason) => {
      assert.equal(code, 1000);
      assert.equal(reason, 'temper-close');
      closeCalls += 1;
    }
  };

  stream.close();
  (stream as unknown as { scheduleReconnect: () => void }).scheduleReconnect();

  assert.equal(closeCalls, 1);
  assert.equal(reconnectSignals, 0);
  assert.equal((stream as unknown as { closed: boolean }).closed, true);
});

test('ActivityStream ignores frames after intentional close', () => {
  let delivered = 0;
  const stream = new ActivityStream({
    ...baseConfig,
    subscriptionId: 'sub_closed_frame',
    onActivity: () => {
      delivered += 1;
    }
  });

  stream.close();
  (stream as unknown as { handleFrame: (raw: string) => void }).handleFrame(JSON.stringify({
    type: 'activity.notification',
    subscription_id: 'sub_closed_frame',
    revision: 1,
    emitted_at: '2026-08-20T00:00:00Z',
    subject: { kind: 'session', id: 'ses_closed' },
    event_kind: 'state_changed',
    canonical_session_revision: 1
  }));

  assert.equal(delivered, 0);
});
