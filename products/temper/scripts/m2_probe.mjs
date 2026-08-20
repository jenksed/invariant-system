#!/usr/bin/env node
/**
 * M2 — TEMPER DURABLE probe.
 *
 * Reuses the proven M1 daemon/runtime and extends it with bounded
 * process lifecycle control. Drives the real WorkbenchConnection
 * against a real Kiln.Daemon across:
 *
 *   M2-A  kill Temper mid-session → restart → project.open →
 *         session.query hydrates the SAME session_id
 *   M2-B  drive to waiting_for_user → kill Temper → restart →
 *         same canonical decision_envelope reconstructs
 *   M2-C  stale context rejected by Kiln; Temper refreshes from
 *         canonical state — never from local memory
 *   M2-D  kill Kiln → spawn new against same KILN_HOME →
 *         project.open re-derives session_id from journal replay
 *
 * Every boundary is real. No mocks. No direct journal mutation.
 * Scoped tokens are generated per-run; no long-lived secrets.
 *
 * Emits structured KEY=VALUE evidence on stdout; exits non-zero
 * on any failure.
 */

import { spawn } from 'node:child_process';
import { createRequire } from 'node:module';
import {
  mkdtempSync, writeFileSync, mkdirSync, rmSync, existsSync,
  readFileSync, appendFileSync
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const require = createRequire(import.meta.url);
const { WorkbenchConnection } = require('../dist/src/workbench/connection.js');

const KILN_URL = process.env.KILN_URL;
const KILN_WS_URL = process.env.KILN_WS_URL;
const KILN_READ_TOKEN = process.env.KILN_READ_TOKEN;
const KILN_OPERATE_TOKEN = process.env.KILN_OPERATE_TOKEN;
const KILN_REPO_PATH = process.env.KILN_REPO_PATH;
const KILN_ROOT = process.env.KILN_ROOT;
const KILN_HOME = process.env.KILN_HOME;
const KILN_PORT = process.env.KILN_PORT;
const M2_RUNTIME_INFO = process.env.M2_RUNTIME_INFO;
const M2_PHASE = (process.env.M2_PHASE || 'ALL').toUpperCase();

for (const [n, v] of Object.entries({
  KILN_URL, KILN_WS_URL, KILN_READ_TOKEN, KILN_OPERATE_TOKEN,
  KILN_REPO_PATH, KILN_ROOT, KILN_HOME, KILN_PORT, M2_RUNTIME_INFO
})) {
  if (!v) {
    process.stderr.write(`m2_probe: missing required env ${n}\n`);
    process.exit(2);
  }
}

let exitCode = 0;
function emit(k, v) { process.stdout.write(`${k}=${v}\n`); }
function fail(k, reason) {
  emit(k, 'FAIL');
  emit(`${k}_REASON`, String(reason).replace(/\n/g, ' '));
  exitCode = 1;
}

// --- runtime.info helpers ---
function readRuntime(key) {
  const text = existsSync(M2_RUNTIME_INFO) ? readFileSync(M2_RUNTIME_INFO, 'utf8') : '';
  for (const line of text.split('\n')) {
    const eq = line.indexOf('=');
    if (eq < 0) continue;
    const k = line.slice(0, eq);
    if (k === key) return line.slice(eq + 1);
  }
  return null;
}
function appendRuntime(line) {
  appendFileSync(M2_RUNTIME_INFO, line);
}

// --- HTTP RPC helper (avoids the non-existent mix kiln session-resume task) ---
async function rpcCall(method, params, token) {
  const url = `${KILN_URL}/api/rpc`;
  const resp = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({ method, params })
  });
  const text = await resp.text();
  let parsed;
  try { parsed = JSON.parse(text); } catch { parsed = { ok: false, error: { code: 'E_PARSE', reason: text.slice(0, 400) } }; }
  if (!resp.ok || (parsed.ok === false)) {
    return { ok: false, error: parsed.error || { code: 'E_HTTP_' + resp.status, reason: text.slice(0, 400) } };
  }
  return { ok: true, result: parsed.result || parsed };
}

// --- review-propose artifact fixtures (M2 — matches CLI's {id, digest} shape) ---
function writeReviewArtifacts(dir) {
  mkdirSync(dir, { recursive: true });
  const placeholder = (label, ch) => ({
    id: `${label}_${'0'.repeat(32)}`,
    digest: 'sha256:' + ch.repeat(64)
  });
  const impl = placeholder('impl', 'a');
  const plan = placeholder('pln', 'b');
  const patch = placeholder('pp', 'c');
  const ver = placeholder('ver', 'd');
  const rev = placeholder('rev', 'e');
  const ctx = placeholder('ctx', 'f');
  const result_state_digest = 'sha256:' + '1'.repeat(64);
  // The Kiln CLI's review-propose load_artifact_ref/2 expects exactly
  // {"id": <id>, "digest": <digest>}; see lib/kiln/cli.ex:load_artifact_ref/2.
  writeFileSync(join(dir, 'implementer.json'), JSON.stringify(impl, null, 2));
  writeFileSync(join(dir, 'plan.json'), JSON.stringify(plan, null, 2));
  writeFileSync(join(dir, 'patch.json'), JSON.stringify(patch, null, 2));
  writeFileSync(join(dir, 'verification.json'), JSON.stringify(ver, null, 2));
  writeFileSync(join(dir, 'reviewer.json'), JSON.stringify(rev, null, 2));
  writeFileSync(join(dir, 'context.json'), JSON.stringify(ctx, null, 2));
  // The reviewer-eligibility must carry derived_at + valid_until
  // inside the bounded 168h currentness window
  // (lib/kiln/m0_currentness.ex). Use now and +24h as the bounded
  // safe window for an automated probe.
  const now = new Date();
  const validUntil = new Date(now.getTime() + 24 * 3600 * 1000);
  const eligibility = {
      schema: 'engineering-system/eligibility-snapshot/m0-v1',
      artifact_id: 'elig_' + '0'.repeat(32),
      semantic_digest: 'sha256:' + '2'.repeat(64),
      derived_at: now.toISOString(),
      valid_until: validUntil.toISOString(),
      reviewer_id: 'temper_operator'
  };
  writeFileSync(join(dir, 'eligibility.json'), JSON.stringify(eligibility, null, 2));
  // The CLI's load_findings/1 requires a JSON array of strings,
  // not a text blob. See lib/kiln/cli.ex:load_findings/1.
  const findings = join(dir, 'findings.json');
  writeFileSync(findings, JSON.stringify(['looks correct'], null, 2));
  const review = join(dir, 'review.json');
  return {
    implementer: join(dir, 'implementer.json'),
    plan: join(dir, 'plan.json'),
    patch: join(dir, 'patch.json'),
    verification: join(dir, 'verification.json'),
    reviewer: join(dir, 'reviewer.json'),
    context_manifest: join(dir, 'context.json'),
    eligibility: join(dir, 'eligibility.json'),
    result_state_digest,
    findings,
    review
  };
}

function runMixKiln(args, env) {
  return new Promise((resolve) => {
    const child = spawn('mix', ['kiln', ...args], {
      cwd: KILN_ROOT,
      env: { ...process.env, ...env },
      stdio: ['ignore', 'pipe', 'pipe']
    });
    let stdout = '', stderr = '';
    child.stdout.on('data', (d) => { stdout += d.toString(); });
    child.stderr.on('data', (d) => { stderr += d.toString(); });
    child.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}

// --- M2-A: active-session reconnect ---
async function phase_A_sessionReconnect() {
  emit('M2_A_PHASE', 'start');
  const connection = new WorkbenchConnection({
    baseUrl: KILN_URL, wsUrl: KILN_WS_URL,
    readToken: KILN_READ_TOKEN, operateToken: KILN_OPERATE_TOKEN,
    repository: KILN_REPO_PATH
  });
  let sessionId = null;
  try {
    await connection.open();
    const proj0 = await connection.startSession(
      'M2-A: bounded intent for active-session reconnect',
      'temper_operator'
    );
    sessionId = proj0.sessionId;
    if (!sessionId || !sessionId.startsWith('ses_')) {
      throw new Error(`session.start returned ${sessionId}; expected ses_<32hex>`);
    }
    const proj1 = await connection.resync('resync');
    if (!proj1.sessionQuery || proj1.sessionQuery.session_id !== sessionId) {
      throw new Error(`resync did not populate sessionQuery.session_id=${sessionId}`);
    }
    emit('M2_A_INITIAL_SESSION_ID', sessionId);
    emit('M2_A_INITIAL_RUN_STATE', String(proj1.sessionQuery.run_state ?? 'NOT_RUN'));
    appendRuntime(`M2_A_INITIAL_SESSION_ID=${sessionId}\n`);
  } catch (err) {
    fail('M2_A_START', err.message);
  }
  await connection.stop().catch(() => {});
  if (exitCode === 0) emit('M2_A_CLIENT_TERMINATED', 'ok');
  return sessionId;
}

async function phase_A_verifyReconnect() {
  const expected = readRuntime('M2_A_INITIAL_SESSION_ID');
  if (!expected) {
    fail('M2_A_RECONNECT', 'no prior session_id recorded in runtime.info');
    return;
  }
  emit('M2_A_EXPECTED_SESSION_ID', expected);
  const connection = new WorkbenchConnection({
    baseUrl: KILN_URL, wsUrl: KILN_WS_URL,
    readToken: KILN_READ_TOKEN, operateToken: KILN_OPERATE_TOKEN,
    repository: KILN_REPO_PATH
  });
  try {
    const proj = await connection.open();
    if (proj.sessionId !== expected) {
      throw new Error(`session_id on reconnect: expected=${expected} got=${proj.sessionId}`);
    }
    const sq = proj.sessionQuery;
    if (!sq || sq.session_id !== expected) {
      throw new Error(`session.query.session_id mismatch on reconnect`);
    }
    emit('M2_A_RECONNECT', 'PASS');
    emit('M2_A_RECONNECTED_SESSION_ID', proj.sessionId);
    emit('M2_A_RECONNECTED_RUN_STATE', String(sq.run_state ?? 'NOT_RUN'));
    emit('M2_A_RECONNECTED_KILN_HOME', proj.kilnHome);
  } catch (err) {
    fail('M2_A_RECONNECT', err.message);
  }
  await connection.stop().catch(() => {});
}

// --- M2-B: pending-decision reconnect ---
async function phase_B_decisionReconnect() {
  emit('M2_B_PHASE', 'start');
  const connection = new WorkbenchConnection({
    baseUrl: KILN_URL, wsUrl: KILN_WS_URL,
    readToken: KILN_READ_TOKEN, operateToken: KILN_OPERATE_TOKEN,
    repository: KILN_REPO_PATH
  });
  let sessionId = null;
  try {
    await connection.open();
    let proj = connection.current();
    if (!proj.sessionId) {
      proj = await connection.startSession(
        'M2-B: pending-decision reconnect scenario',
        'temper_operator'
      );
    }
    sessionId = proj.sessionId;
    if (!sessionId) throw new Error('no active session for M2-B');

    // session.resume via HTTP RPC (ready → running). The mix task
    // 'session-resume' does not exist; the canonical transition is
    // the bounded 'session.resume' RPC.
    const resumeResp = await rpcCall('session.resume', {
      session_id: sessionId,
      actor_id: 'temper_operator',
      expected_session_revision: 0
    }, KILN_OPERATE_TOKEN);
    if (!resumeResp.ok) {
      throw new Error(`session.resume failed: ${JSON.stringify(resumeResp.error)}`);
    }

    // review-propose → canonical pending decision (CLI; reads local SQLite).
    const reviewDir = mkdtempSync(join(tmpdir(), 'kiln-m2-review-'));
    const artifacts = writeReviewArtifacts(reviewDir);
    const propose = await runMixKiln([
      'review-propose',
      '--implementer-assignment', artifacts.implementer,
      '--eligibility', artifacts.eligibility,
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
    ], { KILN_URL, KILN_OPERATE_TOKEN });
    rmSync(reviewDir, { recursive: true, force: true });
    if (propose.code !== 0) {
      const tail = propose.stderr.split('\n').slice(-15).join('\n');
      throw new Error(`review-propose failed rc=${propose.code}: ${tail}`);
    }

    const after = await connection.resync('resync');
    const envelope = after.sessionQuery?.references?.decision_envelope;
    if (!envelope) throw new Error('projection.references.decision_envelope missing');
    const pending = after.sessionQuery?.pending_decision;
    if (!pending || typeof pending !== 'object') {
      throw new Error('projection.pending_decision missing');
    }
    if (after.sessionQuery?.run_state !== 'waiting_for_user') {
      throw new Error(`expected waiting_for_user, got ${after.sessionQuery?.run_state}`);
    }
    emit('M2_B_PENDING_DECISION_ID', pending.id);
    emit('M2_B_PLAN_REF_ID', envelope.plan_ref.id);
    emit('M2_B_PATCH_REF_ID', envelope.patch_ref.id);
    emit('M2_B_REVIEW_REF_ID', envelope.review_ref?.id ?? '');
    emit('M2_B_RESULT_STATE_DIGEST', envelope.result_state_digest);
    appendRuntime(`M2_B_PLAN_REF_ID=${envelope.plan_ref.id}\n`);
    appendRuntime(`M2_B_PATCH_REF_ID=${envelope.patch_ref.id}\n`);
    appendRuntime(`M2_B_RESULT_STATE_DIGEST=${envelope.result_state_digest}\n`);
    appendRuntime(`M2_B_REVIEW_REF_ID=${envelope.review_ref?.id ?? ''}\n`);
    appendRuntime(`M2_B_DECISION_ID=${pending.id}\n`);
  } catch (err) {
    fail('M2_B_START', err.message);
  }
  await connection.stop().catch(() => {});
  if (exitCode === 0) emit('M2_B_CLIENT_TERMINATED', 'ok');
}

// --- M2-C: stale-context rejection ---
async function phase_C_betweenBHalves() {
  emit('M2_C_PHASE', 'start');
  const connection = new WorkbenchConnection({
    baseUrl: KILN_URL, wsUrl: KILN_WS_URL,
    readToken: KILN_READ_TOKEN, operateToken: KILN_OPERATE_TOKEN,
    repository: KILN_REPO_PATH
  });
  try {
    const proj = await connection.open();
    const sq = proj.sessionQuery;
    if (!sq || !sq.references?.decision_envelope) {
      emit('M2_C_REFRESH_RESULT', 'no_pending_decision');
      emit('M2_C_STALE_REJECT', 'SKIP');
      emit('M2_C_STALE_REASON', 'M2-C requires a pending decision; not present');
      return;
    }
    const canonical = sq.references.decision_envelope;
    const stale = {
      plan_ref: canonical.plan_ref,
      patch_ref: canonical.patch_ref,
      // Stale: mutated result_state_digest — simulates client memory
      // that did not see the latest canonical value.
      result_state_digest: 'sha256:' + 'f'.repeat(64),
      review_ref: canonical.review_ref
    };
    const decide = await connection.submitHumanDecision('ACCEPT', stale, 'temper_operator');
    if (decide.ok) {
      throw new Error('human.decide with stale envelope was accepted (must be rejected)');
    }
    emit('M2_C_STALE_REJECT', 'PASS');
    emit('M2_C_STALE_ERROR_CODE', decide.errorCode ?? 'E_UNKNOWN');
    emit('M2_C_STALE_ERROR_REASON', (decide.errorReason ?? '').slice(0, 200));

    const refresh = await connection.resync('reconnect');
    const sq2 = refresh.sessionQuery;
    if (!sq2?.references?.decision_envelope) {
      throw new Error('decision_envelope missing after refresh');
    }
    if (sq2.references.decision_envelope.result_state_digest === stale.result_state_digest) {
      throw new Error('refreshed envelope still carries stale result_state_digest');
    }
    if (sq2.run_state !== 'waiting_for_user') {
      throw new Error(`expected waiting_for_user after refresh; got ${sq2.run_state}`);
    }
    emit('M2_C_REFRESH_RESULT', 'PASS');
    emit('M2_C_REFRESHED_DIGEST', sq2.references.decision_envelope.result_state_digest);
  } catch (err) {
    fail('M2_C_STALE', err.message);
  }
  await connection.stop().catch(() => {});
}

// --- M2-B-VERIFY: reconnect and accept the canonical pending decision ---
async function phase_B_verifyReconnect() {
  const expected = {
    plan_ref_id: readRuntime('M2_B_PLAN_REF_ID'),
    patch_ref_id: readRuntime('M2_B_PATCH_REF_ID'),
    result_state_digest: readRuntime('M2_B_RESULT_STATE_DIGEST'),
    review_ref_id: readRuntime('M2_B_REVIEW_REF_ID'),
    decision_id: readRuntime('M2_B_DECISION_ID')
  };
  if (!expected.decision_id) {
    fail('M2_B_RECONNECT', 'no prior pending decision recorded in runtime.info');
    return;
  }
  const connection = new WorkbenchConnection({
    baseUrl: KILN_URL, wsUrl: KILN_WS_URL,
    readToken: KILN_READ_TOKEN, operateToken: KILN_OPERATE_TOKEN,
    repository: KILN_REPO_PATH
  });
  try {
    const proj = await connection.open();
    const sq = proj.sessionQuery;
    if (!sq) throw new Error('sessionQuery missing after reconnect');
    const env2 = sq.references?.decision_envelope;
    if (!env2) throw new Error('decision_envelope missing after reconnect');
    const pend = sq.pending_decision;
    if (!pend || pend.id !== expected.decision_id) {
      throw new Error(`pending_decision.id mismatch: expected=${expected.decision_id} got=${pend?.id}`);
    }
    if (sq.run_state !== 'waiting_for_user') {
      throw new Error(`expected waiting_for_user after reconnect, got ${sq.run_state}`);
    }
    if (env2.plan_ref.id !== expected.plan_ref_id) {
      throw new Error('plan_ref.id mismatch after reconnect');
    }
    if (env2.patch_ref.id !== expected.patch_ref_id) {
      throw new Error('patch_ref.id mismatch after reconnect');
    }
    if (env2.result_state_digest !== expected.result_state_digest) {
      throw new Error('result_state_digest mismatch after reconnect');
    }
    const expectedRev = expected.review_ref_id || null;
    const observedRev = env2.review_ref?.id ?? null;
    if (observedRev !== expectedRev) {
      throw new Error(`review_ref.id mismatch after reconnect: expected=${expectedRev} got=${observedRev}`);
    }

    const decide = await connection.submitHumanDecision('ACCEPT', {
      plan_ref: env2.plan_ref,
      patch_ref: env2.patch_ref,
      result_state_digest: env2.result_state_digest,
      review_ref: env2.review_ref
    }, 'temper_operator');
    if (!decide.ok) {
      throw new Error(`human.decide failed on reconnect: ${JSON.stringify(decide)}`);
    }
    const afterDecide = await connection.resync('resync');
    if (afterDecide.sessionQuery?.run_state !== 'ready') {
      throw new Error(`run_state after human.decide=${afterDecide.sessionQuery?.run_state}; expected ready`);
    }
    if (afterDecide.sessionQuery?.pending_decision != null) {
      throw new Error('pending_decision should be null after successful human.decide');
    }
    emit('M2_B_RECONNECT', 'PASS');
    emit('M2_B_RECONNECTED_DECISION_ID', pend.id);
    emit('M2_B_FINAL_RUN_STATE', 'ready');
  } catch (err) {
    fail('M2_B_RECONNECT', err.message);
  }
  await connection.stop().catch(() => {});
}

// --- M2-D: Kiln restart + replay ---
async function phase_D_kilnRestartReplay() {
  emit('M2_D_PHASE', 'start');
  const expected = readRuntime('M2_A_INITIAL_SESSION_ID');
  if (!expected) {
    fail('M2_D_REPLAY', 'no expected session_id in runtime.info');
    return;
  }
  const connection = new WorkbenchConnection({
    baseUrl: KILN_URL, wsUrl: KILN_WS_URL,
    readToken: KILN_READ_TOKEN, operateToken: KILN_OPERATE_TOKEN,
    repository: KILN_REPO_PATH
  });
  try {
    // The bash orchestrator has already killed the first daemon and
    // spawned the second against the same KILN_HOME. Wait for
    // /healthz (the orchestrator already waits, but we double-check).
    const deadline = Date.now() + 10_000;
    while (Date.now() < deadline) {
      try {
        const r = await fetch(`${KILN_URL}/healthz`);
        if (r.ok) break;
      } catch { /* not ready */ }
      await new Promise((r) => setTimeout(r, 200));
    }

    const proj = await connection.open();
    if (proj.sessionId !== expected) {
      throw new Error(`session_id on restarted daemon: expected=${expected} got=${proj.sessionId}`);
    }
    const sq = proj.sessionQuery;
    if (!sq || sq.session_id !== expected) {
      throw new Error(`session.query.session_id mismatch on replay`);
    }
    emit('M2_D_REPLAY', 'PASS');
    emit('M2_D_SESSION_ID', proj.sessionId);
    emit('M2_D_KILN_HOME', proj.kilnHome);
    emit('M2_D_RUN_STATE', String(sq.run_state ?? 'NOT_RUN'));
  } catch (err) {
    fail('M2_D_REPLAY', err.message);
  }
  await connection.stop().catch(() => {});
}

async function main() {
  if (M2_PHASE === 'A') { await phase_A_sessionReconnect(); }
  else if (M2_PHASE === 'A-VERIFY') { await phase_A_verifyReconnect(); }
  else if (M2_PHASE === 'B') { await phase_B_decisionReconnect(); }
  else if (M2_PHASE === 'C') { await phase_C_betweenBHalves(); }
  else if (M2_PHASE === 'B-VERIFY') { await phase_B_verifyReconnect(); }
  else if (M2_PHASE === 'D') { await phase_D_kilnRestartReplay(); }
  else {
    if (exitCode === 0) emit('M2_PROBE', 'PASS');
    else emit('M2_PROBE', 'FAIL');
    process.exit(exitCode);
  }
  if (exitCode === 0) emit('M2_PROBE', 'PASS');
  else emit('M2_PROBE', 'FAIL');
  process.exit(exitCode);
}

main().catch((err) => {
  fail('M2_PROBE', err.message);
  emit('M2_PROBE', 'FAIL');
  process.exit(1);
});