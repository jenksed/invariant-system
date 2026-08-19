/**
 * Temper Workbench Alpha — Work screen human.decide operator surface.
 *
 * Slice N2 acceptance: the operator can press A / R / V on the
 * Work screen to submit a governed decision (ACCEPT / REJECT /
 * REQUEST_REVISION) through the real Kiln `human.decide` RPC,
 * and the bounded result (success or exact error code) is
 * rendered on the screen.
 *
 * Tests are unit-level render tests using a fake onHumanDecide
 * callback. The real public-boundary check (live Kiln RPC) is
 * exercised by the integration scenario.
 */

import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  createWorkScreen,
  setWorkProjection,
  setHumanDecideResult,
  type WorkState
} from '../src/screens/work.js';
import { frameToText } from '../src/tui/render.js';
import type { WorkbenchProjection } from '../src/workbench/projection.js';
import type { ScreenContext } from '../src/tui/screen.js';

function ctx(cols: number, rows: number): ScreenContext {
  return { cols, rows, inputFocused: false };
}

function projection(overrides: Partial<WorkbenchProjection> = {}): WorkbenchProjection {
  return {
    repository: '/Users/test/repo',
    repositoryName: 'repo',
    kilnHome: '/Users/test/repo/.kiln',
    sessionId: 'ses_abcdef1234567890',
    canonicalSessionRevision: 47,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: '2026-08-19T12:00:00Z',
    sessionQuery: {
      session_id: 'ses_abcdef1234567890',
      run_state: 'active',
      verification_status: 'PENDING',
      review_status: 'PENDING',
      human_status: 'PENDING'
    },
    ...overrides
  };
}

function freshState(p: WorkbenchProjection = projection()): WorkState {
  return {
    projection: p,
    pulse: [],
    motion: [],
    lastReconnectAt: null,
    disconnectedAt: null,
    humanDecide: { status: 'idle', decision: null, code: null, reason: null, at: null },
    pendingEnvelope: null
  };
}

/** Repair A fixture: a canonical projection that has a real bounded
 *  pending decision recorded by Kiln (decision_envelope +
 *  pending_decision). Used by the key-press dispatch tests so the
 *  precondition `state.pendingEnvelope !== null` is satisfied. */
function envelopeProjection(): WorkbenchProjection {
  return projection({
    sessionQuery: {
      session_id: 'ses_abcdef1234567890',
      run_state: 'waiting_for_user',
      verification_status: 'PASS',
      review_status: 'APPROVE',
      human_status: 'PENDING',
      pending_decision: {
        id: 'dec_aaaaaaaaaaaaaaaa',
        subject_kind: 'run',
        subject_id: 'run_root',
        subject_revision: 3,
        permitted_responses: ['ACCEPT', 'REJECT', 'REQUEST_REVISION']
      },
      references: {
        decision_envelope: {
          plan_ref: {
            id: 'pln_canonical',
            digest: 'sha256:' + 'a'.repeat(64)
          },
          patch_ref: {
            id: 'pp_canonical',
            digest: 'sha256:' + 'b'.repeat(64)
          },
          result_state_digest: 'sha256:' + 'c'.repeat(64),
          review_ref: {
            id: 'rev_canonical',
            digest: 'sha256:' + 'd'.repeat(64)
          }
        }
      }
    }
  });
}

const submitted: Array<'ACCEPT' | 'REJECT' | 'REQUEST_REVISION'> = [];
const work = createWorkScreen({
  intent: 'Fix reconnect projection so stale activity cannot overwrite canonical state.',
  onExit: () => {},
  onHumanDecide: async (decision) => {
    submitted.push(decision);
    return { ok: true };
  }
});

test('N2 pressing A submits ACCEPT', () => {
  submitted.length = 0;
  const seeded = setWorkProjection(freshState(), envelopeProjection());
  const r = work.update(seeded, { kind: 'char', value: 'A' }, ctx(120, 30));
  const next = r.state as WorkState;
  assert.equal(next.humanDecide.status, 'submitting');
  assert.equal(next.humanDecide.decision, 'ACCEPT');
  assert.deepEqual(submitted, ['ACCEPT']);
});

test('N2 pressing R submits REJECT', () => {
  submitted.length = 0;
  const seeded = setWorkProjection(freshState(), envelopeProjection());
  const r = work.update(seeded, { kind: 'char', value: 'R' }, ctx(120, 30));
  const next = r.state as WorkState;
  assert.equal(next.humanDecide.decision, 'REJECT');
  assert.deepEqual(submitted, ['REJECT']);
});

test('N2 pressing V submits REQUEST_REVISION', () => {
  submitted.length = 0;
  const seeded = setWorkProjection(freshState(), envelopeProjection());
  const r = work.update(seeded, { kind: 'char', value: 'V' }, ctx(120, 30));
  const next = r.state as WorkState;
  assert.equal(next.humanDecide.decision, 'REQUEST_REVISION');
  assert.deepEqual(submitted, ['REQUEST_REVISION']);
});

test('N4a pending-decision envelope panel surfaces bounded canonical refs', () => {
  // Push the canonical envelope through setWorkProjection so the
  // screen derives pendingEnvelope from the real Kiln projection
  // shape. Then render and assert the bounded panel surfaces every
  // ref without inventing values.
  const state = setWorkProjection(freshState(), envelopeProjection());
  assert.ok(state.pendingEnvelope, 'pendingEnvelope must be derived from canonical refs');
  assert.equal(state.pendingEnvelope?.decision_id, 'dec_aaaaaaaaaaaaaaaa');
  assert.equal(state.pendingEnvelope?.plan_ref.id, 'pln_canonical');
  assert.equal(state.pendingEnvelope?.patch_ref.id, 'pp_canonical');
  assert.equal(state.pendingEnvelope?.review_ref?.id, 'rev_canonical');
  const text = frameToText(work.view(state, ctx(140, 50)));
  assert.match(text, /PENDING DECISION \(canonical\)/);
  assert.match(text, /pln_canonical/);
  assert.match(text, /pp_canonical/);
  assert.match(text, /rev_canonical/);
  assert.match(text, /ACCEPT, REJECT, REQUEST_REVISION/);
});

test('N4a pending-decision envelope panel is absent when no canonical envelope is recorded', () => {
  const text = frameToText(work.view(freshState(), ctx(140, 36)));
  assert.doesNotMatch(text, /PENDING DECISION \(canonical\)/);
});

test('N2 submitting state shows the submitting banner', () => {
  let state = freshState();
  state = setHumanDecideResult(state, {
    status: 'submitting',
    decision: 'ACCEPT',
    code: null,
    reason: null,
    at: new Date().toISOString()
  });
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /Submitting ACCEPT to Kiln/);
  assert.match(text, /awaiting canonical adjudication/);
});

test('N2 success state shows the accepted banner', () => {
  let state = freshState();
  state = setHumanDecideResult(state, {
    status: 'success',
    decision: 'ACCEPT',
    code: null,
    reason: null,
    at: '2026-08-19T12:00:30Z'
  });
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /ACCEPT accepted by Kiln/);
  assert.match(text, /canonical human status updated/);
});

test('N2 rejected state shows exact bounded error code', () => {
  let state = freshState();
  state = setHumanDecideResult(state, {
    status: 'rejected',
    decision: 'ACCEPT',
    code: 'E_HUMAN_DECISION_INVALID',
    reason: 'plan_ref does not match canonical state',
    at: '2026-08-19T12:00:30Z'
  });
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /NOT applied: E_HUMAN_DECISION_INVALID/);
  assert.match(text, /plan_ref does not match canonical state/);
});

test('N2 E_RUN_TRANSITION_NOT_ALLOWED renders exactly', () => {
  let state = freshState();
  state = setHumanDecideResult(state, {
    status: 'rejected',
    decision: 'ACCEPT',
    code: 'E_RUN_TRANSITION_NOT_ALLOWED',
    reason: 'run is in an active state; cannot transition to accepted',
    at: '2026-08-19T12:00:30Z'
  });
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /E_RUN_TRANSITION_NOT_ALLOWED/);
});

test('N2 error state (transport) shows exact code', () => {
  let state = freshState();
  state = setHumanDecideResult(state, {
    status: 'error',
    decision: 'ACCEPT',
    code: 'E_TRANSPORT',
    reason: 'connection refused',
    at: '2026-08-19T12:00:30Z'
  });
  const text = frameToText(work.view(state, ctx(120, 30)));
  assert.match(text, /ACCEPT failed: E_TRANSPORT/);
  assert.match(text, /connection refused/);
});

test('N2 any key after result clears the result', () => {
  let state = freshState();
  state = setHumanDecideResult(state, {
    status: 'rejected',
    decision: 'ACCEPT',
    code: 'E_HUMAN_DECISION_INVALID',
    reason: 'plan_ref does not match',
    at: '2026-08-19T12:00:30Z'
  });
  const r = work.update(state, { kind: 'char', value: 'x' }, ctx(120, 30));
  const next = r.state as WorkState;
  assert.equal(next.humanDecide.status, 'idle');
});

test('N2 cannot re-submit while submitting', () => {
  let state = freshState();
  state = setHumanDecideResult(state, {
    status: 'submitting',
    decision: 'ACCEPT',
    code: null,
    reason: null,
    at: new Date().toISOString()
  });
  const r = work.update(state, { kind: 'char', value: 'A' }, ctx(120, 30));
  const next = r.state as WorkState;
  // Should still be submitting, not re-submit.
  assert.equal(next.humanDecide.status, 'submitting');
  assert.equal(next.humanDecide.decision, 'ACCEPT');
});

test('N2 no onHumanDecide callback: keys A/R/V are no-ops (back-compat)', () => {
  const workNoCallback = createWorkScreen({
    intent: 'fix',
    onExit: () => {}
  });
  const state = freshState();
  const r = workNoCallback.update(state, { kind: 'char', value: 'A' }, ctx(120, 30));
  const next = r.state as WorkState;
  assert.equal(next.humanDecide.status, 'idle');
});

test('N2 idle state: no banner shown on Work screen', () => {
  const text = frameToText(work.view(freshState(), ctx(120, 30)));
  assert.doesNotMatch(text, /Submitting/);
  assert.doesNotMatch(text, /accepted by Kiln/);
  assert.doesNotMatch(text, /NOT applied/);
});

test('N2 footer shows A / R / V hints when callback is bound', () => {
  const text = frameToText(work.view(freshState(), ctx(120, 30)));
  assert.match(text, /A accept/);
  assert.match(text, /R reject/);
  assert.match(text, /V request-revision/);
});
