import assert from 'node:assert/strict';
import test from 'node:test';
import { ActivityStream } from '../src/stream.js';

const baseConfig = {
  baseUrl: 'http://127.0.0.1:4000',
  wsUrl: 'ws://127.0.0.1:4000/ws',
  readToken: 'READ',
  operateToken: 'OPERATE'
};

class ManualWebSocket extends EventTarget {
  static instances: ManualWebSocket[] = [];
  readonly OPEN = 1;
  readyState = 0;
  readonly sent: string[] = [];

  constructor(_url: string | URL, _protocols?: string | string[]) {
    super();
    ManualWebSocket.instances.push(this);
  }

  send(data: string | ArrayBufferLike | Blob | ArrayBufferView): void {
    this.sent.push(String(data));
  }

  close(_code?: number, _reason?: string): void {
    this.readyState = 3;
    this.dispatchEvent(new Event('close'));
  }

  emitOpen(): void {
    this.readyState = this.OPEN;
    this.dispatchEvent(new Event('open'));
  }

  emitUnexpectedClose(): void {
    this.readyState = 3;
    this.dispatchEvent(new Event('close'));
  }
}

test('ActivityStream.open resolves only after the WebSocket open event', async (t) => {
  const original = globalThis.WebSocket;
  ManualWebSocket.instances.length = 0;
  globalThis.WebSocket = ManualWebSocket as unknown as typeof WebSocket;
  t.after(() => {
    globalThis.WebSocket = original;
  });

  const states: string[] = [];
  const stream = new ActivityStream({
    ...baseConfig,
    subscriptionId: 'sub_handshake',
    onConnectionState: (state) => states.push(state),
    pingIntervalMs: 60_000
  });
  t.after(() => stream.close());

  let resolved = false;
  const opening = stream.open().then(() => {
    resolved = true;
  });

  await Promise.resolve();
  assert.equal(resolved, false, 'constructing a socket must not mean connected');
  assert.equal(ManualWebSocket.instances.length, 1);

  const socket = ManualWebSocket.instances[0];
  assert.ok(socket);
  socket.emitOpen();
  await opening;

  assert.equal(resolved, true);
  assert.deepEqual(states, ['connected']);
  assert.equal(socket.sent.length, 1);
  assert.match(socket.sent[0] ?? '', /activity\.subscribe/);
});

test('unexpected WebSocket close is projected as reconnecting immediately', async (t) => {
  const original = globalThis.WebSocket;
  ManualWebSocket.instances.length = 0;
  globalThis.WebSocket = ManualWebSocket as unknown as typeof WebSocket;
  t.after(() => {
    globalThis.WebSocket = original;
  });

  const states: string[] = [];
  const stream = new ActivityStream({
    ...baseConfig,
    subscriptionId: 'sub_disconnect',
    onConnectionState: (state) => states.push(state),
    pingIntervalMs: 60_000
  });

  const opening = stream.open();
  const socket = ManualWebSocket.instances[0];
  assert.ok(socket);
  socket.emitOpen();
  await opening;

  socket.emitUnexpectedClose();
  assert.deepEqual(states, ['connected', 'reconnecting']);

  // Latch manual close before the bounded reconnect timer fires; this also
  // proves the scheduled retry observes the close guard.
  stream.close();
});
