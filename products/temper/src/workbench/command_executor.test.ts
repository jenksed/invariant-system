import assert from 'node:assert/strict';
import { test } from 'node:test';
import { CommandExecutor } from './command_executor.js';
import type { OperatorResult, SessionGraph } from './operator.js';
import type { WorkbenchProjection } from './projection.js';

function projection(): WorkbenchProjection {
  return {
    repository: '/tmp/invariant',
    repositoryName: 'invariant',
    kilnHome: '/tmp/invariant/.kiln',
    sessionId: 'ses_1',
    canonicalSessionRevision: 7,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: '2026-08-20T20:00:00Z',
    sessionQuery: {
      session_id: 'ses_1',
      task_id: 'tsk_1',
      root_run_id: 'run_1',
      run_state: 'waiting_for_user',
      workflow_step: 'human_decision',
      verification_status: 'PASS',
      review_status: 'APPROVE',
      human_status: 'PENDING',
      session_revision: 7,
      projection_digest: 'sha256:projection',
      journal_head_digest: 'sha256:journal',
      pending_decision: { id: 'dec_1' },
      references: {
        project_observation_id: 'obs_1',
        decision_envelope: {
          plan_ref: { id: 'plan_1', digest: 'sha256:plan' },
          patch_ref: { id: 'patch_1', digest: 'sha256:patch' },
          result_state_digest: 'sha256:state',
          review_ref: { id: 'review_1', digest: 'sha256:review' }
        }
      }
    }
  };
}

function graph(): SessionGraph {
  return {
    schema: 'kiln/session-graph/v1',
    session_id: 'ses_1',
    revision: 7,
    projection_digest: 'sha256:projection',
    source: 'journal',
    orphaned: false,
    nodes: [
      { id: 'ses_1', kind: 'Session', canonical_digest: 'sha256:projection', metadata: {} }
    ],
    edges: []
  };
}

function harness(overrides: Partial<WorkbenchProjection> = {}) {
  let p = { ...projection(), ...overrides };
  const calls: string[] = [];
  const operator = {
    nextActions: async (): Promise<OperatorResult<string[]>> => ({
      ok: true,
      result: ['human.decide']
    }),
    cancel: async (): Promise<OperatorResult<Record<string, unknown>>> => {
      calls.push('cancel');
      return { ok: true, result: {} };
    },
    resume: async (): Promise<OperatorResult<Record<string, unknown>>> => {
      calls.push('resume');
      return { ok: true, result: {} };
    },
    graph: async (): Promise<OperatorResult<SessionGraph>> => ({ ok: true, result: graph() }),
    doctor: async (): Promise<OperatorResult<string[]>> => ({ ok: true, result: ['transport=connected'] })
  };
  const executor = new CommandExecutor({
    getProjection: () => p,
    operator,
    actorId: 'user:test',
    startSession: async (objective) => {
      calls.push(`new:${objective}`);
    },
    resync: async () => {
      calls.push('resync');
      p = {
        ...p,
        sessionQuery: { ...p.sessionQuery, session_revision: 8 }
      };
    },
    decide: async (decision) => {
      calls.push(`decide:${decision}`);
      return { ok: true };
    },
    reconnect: async () => {
      calls.push('reconnect');
      return { ok: true };
    },
    openDiff: () => calls.push('diff'),
    quit: () => calls.push('quit')
  });
  return { executor, calls };
}

test('/status reports canonical and transport state without mutation', async () => {
  const { executor, calls } = harness();
  const result = await executor.execute('/status');
  assert.equal(result.ok, true);
  assert.match(result.lines.join('\n'), /run_state=waiting_for_user/);
  assert.deepEqual(calls, []);
});

test('/why uses Kiln next_actions and labels inference boundary', async () => {
  const { executor } = harness();
  const result = await executor.execute('/why');
  const text = result.lines.join('\n');
  assert.match(text, /human\.decide/);
  assert.match(text, /No additional causal claim is inferred by Temper/);
});

test('/cancel calls Kiln transition then canonical resync', async () => {
  const { executor, calls } = harness();
  const result = await executor.execute('/cancel');
  assert.equal(result.ok, true);
  assert.deepEqual(calls, ['cancel', 'resync']);
  assert.match(result.lines.join('\n'), /canonical_revision=8/);
});

test('/accept calls governed decision then canonical resync', async () => {
  const { executor, calls } = harness();
  const result = await executor.execute('/accept');
  assert.equal(result.ok, true);
  assert.deepEqual(calls, ['decide:ACCEPT', 'resync']);
});

test('/accept fails closed without canonical pending decision', async () => {
  const p = projection();
  p.sessionQuery = { ...p.sessionQuery, pending_decision: undefined };
  const { executor, calls } = harness(p);
  const result = await executor.execute('/accept');
  assert.equal(result.ok, false);
  assert.match(result.lines.join('\n'), /UNAVAILABLE/);
  assert.deepEqual(calls, []);
});

test('/graph renders only graph payload returned by Kiln controller', async () => {
  const { executor } = harness();
  const result = await executor.execute('/graph');
  const text = result.lines.join('\n');
  assert.match(text, /schema=kiln\/session-graph\/v1/);
  assert.match(text, /node Session ses_1/);
});

test('/providers explicitly refuses to imply provider selection when no provider contract is supplied', async () => {
  const { executor } = harness();
  const result = await executor.execute('/providers');
  assert.equal(result.ok, true);
  assert.match(result.lines.join('\n'), /not exposed by the current Workbench contract/);
});
