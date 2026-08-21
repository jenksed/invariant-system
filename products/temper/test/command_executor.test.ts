import assert from 'node:assert/strict';
import { test } from 'node:test';
import { CommandExecutor } from '../src/workbench/command_executor.js';
import type { OperatorResult, SessionGraph } from '../src/workbench/operator.js';
import type { WorkbenchProjection } from '../src/workbench/projection.js';

function projection(): WorkbenchProjection {
  return {
    repository: '/tmp/invariant', repositoryName: 'invariant', kilnHome: '/tmp/invariant/.kiln',
    sessionId: 'ses_1', canonicalSessionRevision: 7, orphaned: false, unknowns: [],
    connection: 'connected', builtAt: '2026-08-20T20:00:00Z',
    sessionQuery: {
      session_id: 'ses_1', task_id: 'tsk_1', root_run_id: 'run_1', run_state: 'waiting_for_user',
      workflow_step: 'human_decision', verification_status: 'PASS', review_status: 'APPROVE',
      human_status: 'PENDING', session_revision: 7, projection_digest: 'sha256:projection',
      journal_head_digest: 'sha256:journal', pending_decision: { id: 'dec_1' },
      references: { project_observation_id: 'obs_1', decision_envelope: {
        plan_ref: { id: 'plan_1', digest: 'sha256:plan' }, patch_ref: { id: 'patch_1', digest: 'sha256:patch' },
        result_state_digest: 'sha256:state', review_ref: { id: 'review_1', digest: 'sha256:review' }
      } }
    }
  };
}
function graph(): SessionGraph { return { schema: 'kiln/session-graph/v1', session_id: 'ses_1', revision: 7, projection_digest: 'sha256:projection', source: 'journal', orphaned: false, nodes: [{ id: 'ses_1', kind: 'Session', canonical_digest: 'sha256:projection', metadata: {} }], edges: [] }; }
function harness(overrides: Partial<WorkbenchProjection> = {}) {
  let p = { ...projection(), ...overrides }; const calls: string[] = [];
  const operator = {
    nextActions: async (): Promise<OperatorResult<string[]>> => ({ ok: true, result: ['human.decide'] }),
    cancel: async (): Promise<OperatorResult<Record<string, unknown>>> => { calls.push('cancel'); return { ok: true, result: {} }; },
    resume: async (): Promise<OperatorResult<Record<string, unknown>>> => { calls.push('resume'); return { ok: true, result: {} }; },
    graph: async (): Promise<OperatorResult<SessionGraph>> => ({ ok: true, result: graph() }),
    doctor: async (): Promise<OperatorResult<string[]>> => ({ ok: true, result: ['transport=connected'] })
  };
  const executor = new CommandExecutor({ getProjection: () => p, operator, actorId: 'user:test',
    startSession: async (o) => { calls.push(`new:${o}`); },
    resync: async () => { calls.push('resync'); p = { ...p, sessionQuery: { ...p.sessionQuery, session_revision: 8 } }; },
    decide: async (d) => { calls.push(`decide:${d}`); return { ok: true }; },
    reconnect: async () => { calls.push('reconnect'); return { ok: true }; },
    openDiff: () => calls.push('diff'), quit: () => calls.push('quit') });
  return { executor, calls };
}

test('/status is read-only', async () => { const { executor, calls } = harness(); const r = await executor.execute('/status'); assert.equal(r.ok, true); assert.match(r.lines.join('\n'), /run_state=waiting_for_user/); assert.deepEqual(calls, []); });
test('/why consumes Kiln next actions and marks inference boundary', async () => { const { executor } = harness(); const t = (await executor.execute('/why')).lines.join('\n'); assert.match(t, /human\.decide/); assert.match(t, /No additional causal claim is inferred by Temper/); });
test('/cancel resyncs after Kiln transition', async () => { const { executor, calls } = harness(); const r = await executor.execute('/cancel'); assert.equal(r.ok, true); assert.deepEqual(calls, ['cancel', 'resync']); assert.match(r.lines.join('\n'), /canonical_revision=8/); });
test('/accept resyncs after governed decision', async () => { const { executor, calls } = harness(); assert.equal((await executor.execute('/accept')).ok, true); assert.deepEqual(calls, ['decide:ACCEPT', 'resync']); });
test('/accept fails closed without pending decision', async () => { const p = projection(); p.sessionQuery = { ...p.sessionQuery, pending_decision: undefined }; const { executor, calls } = harness(p); const r = await executor.execute('/accept'); assert.equal(r.ok, false); assert.match(r.lines.join('\n'), /UNAVAILABLE/); assert.deepEqual(calls, []); });
test('/graph renders only controller payload', async () => { const { executor } = harness(); const t = (await executor.execute('/graph')).lines.join('\n'); assert.match(t, /schema=kiln\/session-graph\/v1/); assert.match(t, /node Session ses_1/); });
test('/providers refuses to imply missing provider control', async () => { const { executor } = harness(); const r = await executor.execute('/providers'); assert.equal(r.ok, true); assert.match(r.lines.join('\n'), /not exposed by the current Workbench contract/); });
