/**
 * Temper Workbench Alpha — Motion + Pulse adapter tests.
 *
 * The adapters are pure projection vocabulary. They must not invent
 * Motion from Pulse or fabricate fields. Tests assert that Motion
 * events come only from real canonical-delta comparisons and that
 * Pulse events come only from real activity frames.
 */

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { MotionLog } from '../src/workbench/motion.js';
import { PulseLog } from '../src/workbench/pulse.js';
import type { ActivityNotificationFrame } from '../src/types.js';
import type { SessionQueryResult } from '../src/workbench/projection.js';

function frame(revision: number, subjectKind: 'session' | 'run' | 'operation' = 'session', id = 'ses_abcdef1234567890'): ActivityNotificationFrame {
  return {
    type: 'activity.notification',
    subscription_id: 'sub_test',
    revision,
    emitted_at: '2026-08-19T00:00:00Z',
    subject: { kind: subjectKind, id },
    event_kind: 'state_changed',
    canonical_session_revision: revision
  };
}

function sq(overrides: Partial<SessionQueryResult> = {}): SessionQueryResult {
  return {
    session_id: 'ses_abcdef1234567890',
    run_state: 'active',
    verification_status: 'PENDING',
    review_status: 'PENDING',
    human_status: 'PENDING',
    workflow_step: 'awaiting_operator',
    ...overrides
  };
}

// -- Motion --

test('Motion: first observation emits projection_observed', () => {
  const log = new MotionLog();
  const events = log.observe(sq());
  assert.equal(events.length, 1);
  assert.equal(events[0]?.kind, 'projection_observed');
});

test('Motion: no events when canonical state is unchanged', () => {
  const log = new MotionLog();
  log.observe(sq());
  const events = log.observe(sq());
  assert.equal(events.length, 0);
});

test('Motion: run_state_changed when run_state moves', () => {
  const log = new MotionLog();
  log.observe(sq({ run_state: 'active' }));
  const events = log.observe(sq({ run_state: 'completed' }));
  const found = events.find((e) => e.kind === 'run_state_changed');
  assert.ok(found);
  assert.equal(found?.from, 'active');
  assert.equal(found?.to, 'completed');
});

test('Motion: verification_changed when verification moves', () => {
  const log = new MotionLog();
  log.observe(sq({ verification_status: 'PENDING' }));
  const events = log.observe(sq({ verification_status: 'PASS' }));
  const found = events.find((e) => e.kind === 'verification_changed');
  assert.ok(found);
  assert.equal(found?.from, 'PENDING');
  assert.equal(found?.to, 'PASS');
});

test('Motion: human_status_changed when human moves', () => {
  const log = new MotionLog();
  log.observe(sq({ human_status: 'PENDING' }));
  const events = log.observe(sq({ human_status: 'ACCEPT' }));
  const found = events.find((e) => e.kind === 'human_status_changed');
  assert.ok(found);
  assert.equal(found?.to, 'ACCEPT');
});

test('Motion: pending_decision_changed when pending appears', () => {
  const log = new MotionLog();
  log.observe(sq({ human_status: 'PENDING' }));
  const events = log.observe(sq({ human_status: 'PENDING', pending_decision: { kind: 'human_decision' } }));
  const found = events.find((e) => e.kind === 'pending_decision_changed');
  assert.ok(found);
  assert.equal(found?.from, 'absent');
  assert.equal(found?.to, 'present');
});

test('Motion: bounded log length', () => {
  const log = new MotionLog(3);
  log.observe(sq({ run_state: 'a' }));
  for (let i = 0; i < 10; i += 1) {
    log.observe(sq({ run_state: `state_${i}` }));
  }
  assert.equal(log.list().length, 3);
});

// Regression: when a single observation emits more events than
// maxEvents, the buffer must keep the NEWEST maxEvents entries, not
// the oldest. The previous splice-after-push implementation removed
// the just-pushed events in this case.
test('Motion: trim keeps newest when a single batch exceeds maxEvents', () => {
  const log = new MotionLog(3);
  // Baseline observation (1 event: projection_observed).
  log.observe(sq({ run_state: 'a' }));
  // Second observation: 5 tracked fields change → 5 events emitted.
  const emitted = log.observe(
    sq({
      run_state: 'b',
      verification_status: 'PASS',
      review_status: 'APPROVE',
      human_status: 'ACCEPT',
      workflow_step: 'done'
    })
  );
  assert.equal(emitted.length, 5, 'all five field changes should be detected');
  const list = log.list();
  assert.equal(list.length, 3, 'buffer must be capped at maxEvents=3');
  // Order of TRACKED_FIELDS: run_state, verification_status, review_status,
  // human_status, workflow_step. The newest 3 are the last 3 emitted.
  assert.equal(list[0]?.field, 'review_status');
  assert.equal(list[1]?.field, 'human_status');
  assert.equal(list[2]?.field, 'workflow_step');
});

test('Motion: trim keeps newest when batch alone exceeds maxEvents', () => {
  const log = new MotionLog(2);
  log.observe(sq({ run_state: 'a' }));
  // Emit a batch of 5 events; the buffer can only hold 2.
  log.observe(
    sq({
      run_state: 'b',
      verification_status: 'PASS',
      review_status: 'APPROVE',
      human_status: 'ACCEPT',
      workflow_step: 'done'
    })
  );
  const list = log.list();
  assert.equal(list.length, 2);
  // Newest 2: human_status_changed then workflow_step_changed.
  assert.equal(list[0]?.field, 'human_status');
  assert.equal(list[1]?.field, 'workflow_step');
});

test('Motion: reset clears the log and previous baseline', () => {
  const log = new MotionLog();
  log.observe(sq({ run_state: 'a' }));
  log.reset();
  const events = log.observe(sq({ run_state: 'b' }));
  // After reset, the next observation is treated as first → projection_observed.
  assert.equal(events.length, 1);
  assert.equal(events[0]?.kind, 'projection_observed');
});

// -- Pulse --

test('Pulse: 1:1 reduction of an activity frame', () => {
  const log = new PulseLog();
  const ev = log.observe(frame(7, 'session', 'ses_abcdef1234567890'));
  assert.equal(ev.subjectKind, 'session');
  assert.equal(ev.subjectId, 'ses_abcdef1234567890');
  assert.equal(ev.revision, 7);
  assert.equal(ev.canonicalSessionRevision, 7);
  assert.match(ev.line, /Kiln state changed/);
  assert.match(ev.line, /session/);
});

test('Pulse: log appends in order', () => {
  const log = new PulseLog();
  log.observe(frame(1));
  log.observe(frame(2));
  log.observe(frame(3));
  const events = log.list();
  assert.equal(events.length, 3);
  assert.equal(events[0]?.revision, 1);
  assert.equal(events[1]?.revision, 2);
  assert.equal(events[2]?.revision, 3);
});

test('Pulse: bounded log length', () => {
  const log = new PulseLog(5);
  for (let i = 0; i < 20; i += 1) log.observe(frame(i));
  assert.equal(log.list().length, 5);
  assert.equal(log.list()[0]?.revision, 15);
});

test('Pulse: never invents a frame; the only entry is the observed frame', () => {
  const log = new PulseLog();
  log.observe(frame(11, 'run', 'run_xyz'));
  const list = log.list();
  assert.equal(list.length, 1);
  assert.equal(list[0]?.subjectKind, 'run');
  assert.equal(list[0]?.subjectId, 'run_xyz');
});
