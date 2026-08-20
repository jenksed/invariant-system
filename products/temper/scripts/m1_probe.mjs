#!/usr/bin/env node
/**
 * M1 — TEMPER OPERABLE integration probe.
 *
 * Drives the real Kiln.Daemon + the real Temper WorkbenchConnection
 * through the bounded operator path:
 *
 *   M1-A  session.start via WorkbenchConnection
 *   M1-B  canonical projection observed via connection.resync
 *   M1-C  review-propose (CLI) → bounded canonical pending decision
 *         → human.decide via WorkbenchConnection (real envelope)
 *
 * Every boundary is real. No mocks. No direct journal mutation. No
 * SQLite inspection as a pass condition. Scoped tokens are generated
 * per-run; no long-lived secrets.
 *
 * Emits structured `KEY=VALUE` evidence on stdout and exits non-zero
 * on any failure.
 */

import { spawn } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createRequire } from 'node:module';

// The compiled WorkbenchConnection uses a literal
// `require('node:crypto')` inside buildProjectObservation. Under
// direct ESM dynamic import this throws at runtime; load through
// a CJS require to keep Node happy.
const require = createRequire(import.meta.url);
const { WorkbenchConnection } = require('../dist/src/workbench/connection.js');

const KILN_URL = process.env.KILN_URL;
const KILN_WS_URL = process.env.KILN_WS_URL;
const KILN_READ_TOKEN = process.env.KILN_READ_TOKEN;
const KILN_OPERATE_TOKEN = process.env.KILN_OPERATE_TOKEN;
const KILN_REPO_PATH = process.env.KILN_REPO_PATH;
const KILN_ROOT = process.env.KILN_ROOT;

if (!KILN_URL || !KILN_WS_URL || !KILN_READ_TOKEN || !KILN_OPERATE_TOKEN || !KILN_REPO_PATH || !KILN_ROOT) {
  process.stderr.write('m1_probe: missing required env (KILN_URL, KILN_WS_URL, KILN_READ_TOKEN, KILN_OPERATE_TOKEN, KILN_REPO_PATH, KILN_ROOT)\n');
  process.exit(2);
}

function emit(key, value) {
  process.stdout.write(`${key}=${value}\n`);
}

let exitCode = 0;
function fail(key, reason) {
  emit(`${key}`, 'FAIL');
  emit(`${key}_REASON`, reason.replace(/\n/g, ' '));
  exitCode = 1;
}

let connection;
try {
  // M1-A
  connection = new WorkbenchConnection({
    baseUrl: KILN_URL,
    wsUrl: KILN_WS_URL,
    readToken: KILN_READ_TOKEN,
    operateToken: KILN_OPERATE_TOKEN,
    repository: KILN_REPO_PATH
  });

  let sessionId = null;
  try {
    const proj = await connection.startSession(
      'M1 probe: build a small change in the target repository and report',
      'temper_operator'
    );
    sessionId = proj.sessionId;
    if (!sessionId || !sessionId.startsWith('ses_')) {
      throw new Error(`session.start returned session_id=${sessionId}; expected ses_<32hex>`);
    }
    emit('M1_A_START', 'PASS');
    emit('M1_A_SESSION_ID', sessionId);
    // Trigger a session.query round-trip so sessionQuery fields
    // (run_state, human_status, etc.) populate on the projection.
    await connection.resync('resync');
  } catch (err) {
    fail('M1_A_START', err.message);
  }

  // M1-B
  if (sessionId) {
    try {
      const proj = await connection.resync('resync');
      const sq = proj.sessionQuery;
      if (!sq) throw new Error('sessionQuery missing after resync');
      if (sq.session_id !== sessionId) {
        throw new Error(`sessionQuery.session_id=${sq.session_id} != started session_id=${sessionId}`);
      }
      if (!sq.run_state) throw new Error('sessionQuery.run_state missing');
      emit('M1_B_OBSERVE', 'PASS');
      emit('M1_B_RUN_STATE', sq.run_state);
      emit('M1_B_SESSION_ID', sq.session_id);
      emit('M1_B_HUMAN_STATUS', String(sq.human_status ?? 'NOT_RUN'));
      emit('M1_B_VERIFICATION', String(sq.verification_status ?? 'NOT_RUN'));
      emit('M1_B_REVIEW', String(sq.review_status ?? 'NOT_RUN'));
      emit('M1_B_PROJECTION_DIGEST', String(sq.projection_digest ?? sq.journal_head_digest ?? ''));
    } catch (err) {
      fail('M1_B_OBSERVE', err.message);
    }
  }

  // M1-C
  if (sessionId) {
    try {
      // Step 1: resume the run (ready → running).
      const resumeResult = await runMixKiln(['session-resume', '--actor-id', 'temper_operator'], {
        KILN_URL,
        KILN_OPERATE_TOKEN
      });
      if (resumeResult.code !== 0) {
        throw new Error(`session-resume exited ${resumeResult.code}: ${resumeResult.stderr.slice(0, 400)}`);
      }

      // Step 2: drive review-propose via the bounded CLI. The CLI
      // builds the review and records the canonical pending
      // decision through Workflow.record_pending_decision/2.
      const reviewDir = mkdtempSync(join(tmpdir(), 'kiln-m1-review-'));
      const artifacts = writeReviewArtifacts(reviewDir);
      const proposeArgs = [
        'review-propose',
        '--implementer-assignment', artifacts.implementer,
        '--plan', artifacts.plan,
        '--patch', artifacts.patch,
        '--result-state-digest', artifacts.result_state_digest,
        '--verification', artifacts.verification,
        '--reviewer-assignment', artifacts.reviewer,
        '--verdict', 'APPROVE',
        '--findings', artifacts.findings,
        '--context-manifest', artifacts.context_manifest,
        '--out', artifacts.review,
        '--actor-id', 'temper_operator'
      ];
      const proposeResult = await runMixKiln(proposeArgs, { KILN_URL, KILN_OPERATE_TOKEN });
      if (proposeResult.code !== 0) {
        throw new Error(`review-propose exited ${proposeResult.code}: ${proposeResult.stderr.slice(0, 800)}`);
      }
      rmSync(reviewDir, { recursive: true, force: true });

      // Step 3: re-sync projection to read the canonical envelope.
      const afterPropose = await connection.resync('resync');
      const envelope = afterPropose.sessionQuery?.references?.decision_envelope;
      if (!envelope) {
        throw new Error('projection.references.decision_envelope missing after review-propose');
      }
      const pending = afterPropose.sessionQuery.pending_decision;
      if (!pending || typeof pending !== 'object') {
        throw new Error('projection.pending_decision missing after review-propose');
      }
      const decisionId = pending.id;
      if (!decisionId || !decisionId.startsWith('dec_')) {
        throw new Error(`pending_decision.id=${decisionId} is not canonical dec_<32hex>`);
      }
      const runStateBefore = afterPropose.sessionQuery.run_state;
      if (runStateBefore !== 'waiting_for_user') {
        throw new Error(`run_state after review-propose=${runStateBefore}; expected waiting_for_user`);
      }
      emit('M1_C_PROPOSE_STATE', runStateBefore);
      emit('M1_C_DECISION_ID', decisionId);

      // Step 4: submit the EXACT canonical envelope through the
      // real WorkbenchConnection.submitHumanDecision.
      const decideResult = await connection.submitHumanDecision('ACCEPT', {
        plan_ref: envelope.plan_ref,
        patch_ref: envelope.patch_ref,
        result_state_digest: envelope.result_state_digest,
        review_ref: envelope.review_ref
      }, 'temper_operator');
      if (!decideResult || !decideResult.ok) {
        throw new Error(`human.decide rejected: ${JSON.stringify(decideResult)}`);
      }

      // Step 5: re-query and assert canonical state advanced.
      const afterDecide = await connection.resync('resync');
      const runStateAfter = afterDecide.sessionQuery.run_state;
      const pendingAfter = afterDecide.sessionQuery.pending_decision;
      const envelopeAfter = afterDecide.sessionQuery.references?.decision_envelope;
      if (runStateAfter !== 'ready') {
        throw new Error(`run_state after human.decide=${runStateAfter}; expected ready`);
      }
      if (pendingAfter != null) {
        throw new Error('pending_decision should be null after a successful human.decide');
      }
      if (envelopeAfter != null) {
        throw new Error('decision_envelope should be cleared after a successful human.decide');
      }
      emit('M1_C_DECIDE', 'PASS');
      emit('M1_C_RUN_STATE_BEFORE', runStateBefore);
      emit('M1_C_RUN_STATE_AFTER', runStateAfter);
      emit('M1_C_FINAL_STATE', 'ready');
    } catch (err) {
      fail('M1_C_DECIDE', err.message);
    }
  }

  await connection.stop().catch(() => {});
} catch (err) {
  fail('M1_PROBE', err.message);
}

if (exitCode === 0) emit('M1_PROBE', 'PASS');
else emit('M1_PROBE', 'FAIL');
process.exit(exitCode);

// ---- helpers ----

function writeReviewArtifacts(dir) {
  mkdirSync(dir, { recursive: true });
  const placeholder = (label, char) => ({
    id: `${label}_${'0'.repeat(32)}`,
    digest: 'sha256:' + char.repeat(64)
  });
  const impl = placeholder('impl', 'a');
  const plan = placeholder('pln', 'b');
  const patch = placeholder('pp', 'c');
  const ver = placeholder('ver', 'd');
  const rev = placeholder('rev', 'e');
  const ctx = placeholder('ctx', 'f');
  const result_state_digest = 'sha256:' + '1'.repeat(64);

  const envelopeFor = (kind, refs) => ({
    schema: `engineering-system/${kind}/m0-v1`,
    artifact_id: refs.id,
    semantic_digest: refs.digest
  });
  writeFileSync(join(dir, 'implementer.json'),
    JSON.stringify(envelopeFor('implementer-assignment', impl), null, 2));
  writeFileSync(join(dir, 'plan.json'),
    JSON.stringify(envelopeFor('plan', plan), null, 2));
  writeFileSync(join(dir, 'patch.json'),
    JSON.stringify(envelopeFor('patch', patch), null, 2));
  writeFileSync(join(dir, 'verification.json'),
    JSON.stringify(envelopeFor('verification', ver), null, 2));
  writeFileSync(join(dir, 'reviewer.json'),
    JSON.stringify(envelopeFor('reviewer-assignment', rev), null, 2));
  writeFileSync(join(dir, 'context.json'),
    JSON.stringify(envelopeFor('context-manifest', ctx), null, 2));
  const findings = join(dir, 'findings.txt');
  writeFileSync(findings, 'looks correct\n');
  const review = join(dir, 'review.json');
  return {
    implementer: join(dir, 'implementer.json'),
    plan: join(dir, 'plan.json'),
    patch: join(dir, 'patch.json'),
    verification: join(dir, 'verification.json'),
    reviewer: join(dir, 'reviewer.json'),
    context_manifest: join(dir, 'context.json'),
    result_state_digest,
    findings,
    review
  };
}

function runMixKiln(args, env) {
  return new Promise((resolve) => {
    const child = spawn('mix', ['kiln', ...args], {
      cwd: KILN_ROOT,
      env: {
        ...process.env,
        ...env
      },
      stdio: ['ignore', 'pipe', 'pipe']
    });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (d) => { stdout += d.toString(); });
    child.stderr.on('data', (d) => { stderr += d.toString(); });
    child.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}
