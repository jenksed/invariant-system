import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import {
  CommandExecutor,
  parseCommandLine,
  type CommandConnection,
  type CommandRpcResult
} from '../src/workbench/commands.js';
import type { WorkbenchProjection } from '../src/workbench/projection.js';

function projection(overrides: Partial<WorkbenchProjection> = {}): WorkbenchProjection {
  return {
    repository: '/tmp/repo',
    repositoryName: 'repo',
    kilnHome: '/tmp/repo/.kiln',
    sessionId: 'ses_0123456789abcdef0123456789abcdef',
    canonicalSessionRevision: 7,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: '2026-08-20T00:00:00.000Z',
    sessionQuery: {
      session_id: 'ses_0123456789abcdef0123456789abcdef',
      session_revision: 7,
      session_state: 'active',
      run_state: 'ready'
    },
    ...overrides
  };
}

class FakeConnection implements CommandConnection {
  public currentProjection = projection();
  public cancelActor: string | null = null;
  public resumeActor: string | null = null;
  public decision: string | null = null;
  public reconnectCount = 0;
  public resyncCount = 0;

  current(): WorkbenchProjection {
    return this.currentProjection;
  }

  async resync(): Promise<WorkbenchProjection> {
    this.resyncCount += 1;
    return this.currentProjection;
  }

  async reconnect(): Promise<WorkbenchProjection> {
    this.reconnectCount += 1;
    return this.currentProjection;
  }

  async startSession(intent: string, _actorId: string): Promise<WorkbenchProjection> {
    this.currentProjection = projection({
      sessionQuery: { ...this.currentProjection.sessionQuery, objective: intent }
    });
    return this.currentProjection;
  }

  async cancelSession(actorId: string): Promise<CommandRpcResult> {
    this.cancelActor = actorId;
    return { ok: true, result: { status: 'cancelled' } };
  }

  async resumeSession(actorId: string): Promise<CommandRpcResult> {
    this.resumeActor = actorId;
    return { ok: true, result: { status: 'resumed' } };
  }

  async nextActions(): Promise<CommandRpcResult> {
    return { ok: true, result: { actions: ['resume', 'cancel'] } };
  }

  async submitHumanDecision(
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION',
    _envelope: {
      plan_ref: { id: string; digest: string };
      patch_ref: { id: string; digest: string };
      result_state_digest: string;
      review_ref?: { id: string; digest: string } | null;
    },
    _actorId: string
  ): Promise<CommandRpcResult> {
    this.decision = decision;
    return { ok: true, result: { decision } };
  }
}

function executor(connection = new FakeConnection(), configPath?: string) {
  let actor = 'operator-one';
  const instance = new CommandExecutor(connection, {
    repository: '/tmp/repo',
    baseUrl: 'http://127.0.0.1:4000',
    wsUrl: 'ws://127.0.0.1:4000/ws',
    getActorId: () => actor,
    setActorId: (value) => {
      actor = value;
    },
    ...(configPath ? { configPath } : {})
  });
  return { instance, connection, getActor: () => actor };
}

test('slash parser preserves quoted objective arguments', () => {
  assert.deepEqual(parseCommandLine('/new "inspect safely" --bounded'), {
    ok: true,
    name: 'new',
    args: ['inspect safely', '--bounded']
  });
});

test('/next delegates to the real connection boundary and renders returned actions', async () => {
  const { instance } = executor();
  const result = await instance.execute('/next');
  assert.equal(result.ok, true);
  assert.ok(result.lines.some((line) => line.includes('resume')));
  assert.ok(result.lines.some((line) => line.includes('cancel')));
});

test('/cancel uses the configured actor and resyncs after Kiln accepts', async () => {
  const { instance, connection } = executor();
  const result = await instance.execute('/cancel');
  assert.equal(result.ok, true);
  assert.equal(connection.cancelActor, 'operator-one');
  assert.equal(connection.resyncCount, 1);
});

test('/decide refuses to invent canonical decision refs', async () => {
  const connection = new FakeConnection();
  const { instance } = executor(connection);
  const result = await instance.execute('/accept');
  assert.equal(result.ok, false);
  assert.equal(result.code, 'E_DECISION_CONTEXT_UNAVAILABLE');
  assert.equal(connection.decision, null);
});

test('/decide consumes the canonical pending envelope when it exists', async () => {
  const connection = new FakeConnection();
  connection.currentProjection = projection({
    sessionQuery: {
      session_revision: 9,
      pending_decision: { id: 'decision-1' },
      references: {
        decision_envelope: {
          plan_ref: { id: 'plan-1', digest: `sha256:${'a'.repeat(64)}` },
          patch_ref: { id: 'patch-1', digest: `sha256:${'b'.repeat(64)}` },
          result_state_digest: `sha256:${'c'.repeat(64)}`,
          review_ref: { id: 'review-1', digest: `sha256:${'d'.repeat(64)}` }
        }
      }
    }
  });
  const { instance } = executor(connection);
  const result = await instance.execute('/revise');
  assert.equal(result.ok, true);
  assert.equal(connection.decision, 'REQUEST_REVISION');
});

test('provider/model selection fails closed until Kiln exposes a control RPC', async () => {
  const { instance } = executor();
  const provider = await instance.execute('/provider claude');
  const model = await instance.execute('/model opus');
  assert.equal(provider.ok, false);
  assert.equal(provider.code, 'E_PROVIDER_CONTROL_UNAVAILABLE');
  assert.equal(model.ok, false);
  assert.equal(model.code, 'E_PROVIDER_CONTROL_UNAVAILABLE');
});

test('/config set actor_id persists non-secret config and changes the live actor', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'temper-command-test-'));
  const configPath = join(dir, 'temper.json');
  try {
    const { instance, getActor } = executor(new FakeConnection(), configPath);
    const result = await instance.execute('/config set actor_id operator-two');
    assert.equal(result.ok, true);
    assert.equal(getActor(), 'operator-two');
    const persisted = JSON.parse(readFileSync(configPath, 'utf8')) as { actor_id?: string };
    assert.equal(persisted.actor_id, 'operator-two');
    assert.equal('KILN_READ_TOKEN' in persisted, false);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
