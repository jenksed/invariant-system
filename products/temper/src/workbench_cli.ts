/**
 * Temper Workbench Alpha — workbench entry point.
 *
 * Wires the WorkbenchConnection to the Home + Work screens, the
 * runtime, and the CLI. Invoked by `temper .` (no flags) and
 * `temper . --workbench`.
 *
 * Authority rule: this module never holds a workflow boolean. It
 * only forwards Kiln responses to the screen and screen submit
 * events to Kiln.
 */

import { TuiRuntime } from './tui/tui.js';
import {
  createHomeScreen,
  setHomeProjection,
  type HomeState
} from './screens/home.js';
import { execFileSync } from 'node:child_process';
import {
  appendWorkMotion,
  appendWorkPulse,
  createWorkScreen,
  markWorkDisconnect,
  markWorkReconnect,
  setHumanDecideResult,
  setWorkProjection,
  type WorkState
} from './screens/work.js';
import { createDiffScreen } from './screens/diff.js';
import { WorkbenchConnection } from './workbench/connection.js';
import { MotionLog } from './workbench/motion.js';
import { PulseLog } from './workbench/pulse.js';
import type { WorkbenchProjection } from './workbench/projection.js';

export interface WorkbenchCliOptions {
  repository: string;
  /** Base URL for the bounded Kiln daemon (env KILN_URL). */
  baseUrl: string;
  /** WebSocket URL for the activity stream (env KILN_WS_URL). */
  wsUrl: string;
  /** Read-scoped token (env KILN_READ_TOKEN). */
  readToken: string;
  /** Operate-scoped token (env KILN_OPERATE_TOKEN). */
  operateToken: string;
  /** Actor id used for session.start; defaults to "temper_operator". */
  actorId?: string;
  /** Directory for milestone snapshots (env TEMPER_SNAPSHOT_DIR). */
  snapshotDir?: string;
  /** When true, run a single hydration + render, then exit. Used for
   *  --once and for case-study capture. */
  once?: boolean;
}

export async function runWorkbench(options: WorkbenchCliOptions): Promise<number> {
  const connection = new WorkbenchConnection({
    baseUrl: options.baseUrl,
    wsUrl: options.wsUrl,
    readToken: options.readToken,
    operateToken: options.operateToken,
    repository: options.repository
  });

  const runtime = new TuiRuntime(
    options.snapshotDir ? { snapshotDir: options.snapshotDir } : {}
  );

  // Bounded projection vocabulary derived from authoritative sources.
  const motionLog = new MotionLog();
  const pulseLog = new PulseLog();

  // Mutable screen state mirrors; the orchestrator mutates them and
  // pushes the result to the runtime.
  let homeState: HomeState | null = null;
  let workState: WorkState | null = null;
  let active: 'home' | 'work' = 'home';

  const homeScreen = createHomeScreen({
    onSubmitIntent: async (intent) => {
      try {
        await connection.startSession(intent, options.actorId ?? 'temper_operator');
        // Transition: replace Home with Work.
        const nextScreen = workScreen(intent);
        workState = setWorkProjection(nextScreen.init() as WorkState, connection.current());
        runtime.replace(nextScreen);
        active = 'work';
        runtime.setTopState(workState);
        return { ok: true };
      } catch (err) {
        return { ok: false, error: (err as Error).message };
      }
    }
  });

  function workScreen(intent: string) {
    return createWorkScreen({
      intent,
      onExit: () => {
        runtime.replace(homeScreen);
        active = 'home';
        if (homeState) runtime.setTopState(homeState);
      },
      onHumanDecide: async (decision) => {
        // N2 (Repair A): invoke the real bounded `human.decide` Kiln RPC.
        // The bounded envelope is constructed ONLY from canonical
        // state — the four bounded refs the operator must submit
        // are read from session.query.projection.references.decision_envelope,
        // recorded by Kiln at the decision-creation lifecycle point
        // (review-propose). Temper does NOT invent placeholders.
        //
        // If canonical context is unavailable, the operator sees
        // "decision action unavailable" rather than fabricated refs.
        if (!workState) {
          return { ok: false, errorCode: 'E_NO_ACTIVE_SESSION', errorReason: 'no work state' };
        }
        const envelope = workState.pendingEnvelope;
        if (!envelope) {
          return {
            ok: false,
            errorCode: 'E_DECISION_CONTEXT_UNAVAILABLE',
            errorReason: 'no canonical pending decision envelope is currently recorded'
          };
        }
        const setResult = (result: { ok: boolean; errorCode?: string; errorReason?: string }) => {
          workState = setHumanDecideResult(workState!, {
            status: result.ok ? 'success' : 'rejected',
            decision,
            code: result.ok ? null : (result.errorCode ?? 'E_UNKNOWN'),
            reason: result.ok ? null : (result.errorReason ?? ''),
            at: new Date().toISOString()
          });
          if (active === 'work') runtime.setTopState(workState);
        };
        try {
          const result = await connection.submitHumanDecision(
            decision,
            {
              plan_ref: envelope.plan_ref,
              patch_ref: envelope.patch_ref,
              result_state_digest: envelope.result_state_digest,
              review_ref: envelope.review_ref
            },
            options.actorId ?? 'temper_operator'
          );
          setResult(result);
          // After a successful human.decide, the canonical
          // Session has advanced; resync so the next render
          // shows the new state and a freshly derived envelope
          // (or null when no longer waiting_for_user).
          if (result.ok) {
            await connection.resync('resync');
          }
          return result;
        } catch (err) {
          const errResult = { ok: false, errorCode: 'E_TRANSPORT', errorReason: (err as Error).message };
          setResult(errResult);
          return errResult;
        }
      },
      onOpenDiff: () => {
        // N3: open the bounded diff surface. The diff screen
        // reads `git diff` from the current worktree via a
        // bounded execFileSync. No new contracts.
        const repoRoot = options.repository;
        const diffSource = (root: string): Promise<{ ok: boolean; text: string; error?: string }> => {
          try {
            const text = execFileSync('git', ['-C', root, 'diff'], {
              encoding: 'utf8',
              maxBuffer: 2 * 1024 * 1024,
              stdio: ['ignore', 'pipe', 'pipe']
            });
            return Promise.resolve({ ok: true, text: text ?? '' });
          } catch (err) {
            const e = err as { stdout?: Buffer | string; stderr?: Buffer | string; message?: string };
            const stdout = typeof e.stdout === 'string' ? e.stdout : e.stdout?.toString('utf8') ?? '';
            const stderr = typeof e.stderr === 'string' ? e.stderr : e.stderr?.toString('utf8') ?? '';
            if (stdout.length > 0) {
              return Promise.resolve({ ok: true, text: stdout });
            }
            return Promise.resolve({
              ok: false,
              text: '',
              error: stderr || e.message || 'git diff failed'
            });
          }
        };
        runtime.push(
          createDiffScreen({
            repositoryRoot: repoRoot,
            diffSource,
            onExit: () => {
              runtime.pop();
            },
            onResult: (result) => {
              // The Diff screen is push-only and self-contained;
              // it does not project into the workbench state.
              // This is a deliberate boundary: a diff is a
              // snapshot of current worktree bytes, not a
              // canonical projection.
              void result;
            }
          })
        );
      }
    });
  }

  // Keep the orchestration mirror initialized alongside the runtime's copy.
  // Projection callbacks arrive asynchronously after `connection.open()`;
  // leaving this mirror null strands the UI on the splash forever because
  // there is no state object to hydrate and hand back to the runtime.
  homeState = homeScreen.init() as HomeState;
  runtime.push(homeScreen);
  runtime.setTopState(homeState);

  // Wire projection updates into the active screen state. Both
  // screens always receive the latest projection so the Work screen
  // is ready to render as soon as the operator transitions.
  const unsubProjection = connection.onProjection((projection: WorkbenchProjection) => {
    if (homeState) homeState = setHomeProjection(homeState, projection);
    if (workState) workState = setWorkProjection(workState, projection);
    // Run the canonical query through the Motion log; emit any new
    // Motion events into the Work screen.
    if (projection.sessionQuery) {
      const emitted = motionLog.observe(projection.sessionQuery);
      for (const ev of emitted) {
        if (workState) workState = appendWorkMotion(workState, ev);
      }
    }
    if (active === 'home' && homeState) runtime.setTopState(homeState);
    if (active === 'work' && workState) runtime.setTopState(workState);
  });

  // Wire raw activity frames into the Pulse log. Pulse is appended
  // to the Work screen state; the Home screen does not show Pulse.
  const unsubActivity = connection.onActivity((frame) => {
    const event = pulseLog.observe(frame);
    if (workState) {
      workState = appendWorkPulse(workState, event);
      if (active === 'work') runtime.setTopState(workState);
    }
  });

  // Wire connection state transitions into the Work screen so it
  // can show a prominent disconnect banner and the "since you
  // left" feed on reconnect. We track the previous state to
  // detect the transition that triggers the reconnect banner.
  let previousConnection: WorkbenchProjection['connection'] | null = null;
  const unsubConnection = connection.onConnection((state) => {
    if (!workState) return;
    if (state === 'disconnected' || state === 'reconnecting') {
      workState = markWorkDisconnect(workState);
    } else if (state === 'connected' && previousConnection !== 'connected') {
      workState = markWorkReconnect(workState);
    }
    previousConnection = state;
    if (active === 'work') runtime.setTopState(workState);
  });

  runtime.start();

  try {
    await connection.open();
  } catch (err) {
    if (options.once) {
      runtime.stop();
      await connection.stop();
      unsubProjection();
      unsubActivity();
      unsubConnection();
      process.stderr.write(`temper: ${(err as Error).message}\n`);
      return 1;
    }
  }

  if (options.once) {
    await new Promise((resolve) => setTimeout(resolve, 50));
    const snapshotPath = runtime.snapshot('workbench-open');
    if (snapshotPath) {
      process.stderr.write(`temper: snapshot written: ${snapshotPath}\n`);
    }
    runtime.stop();
    await connection.stop();
    unsubProjection();
    unsubActivity();
    unsubConnection();
    return 0;
  }

  await new Promise<void>((resolve) => {
    let settled = false;
    const finish = (): void => {
      if (settled) return;
      settled = true;
      offClose();
      process.stdin.off('end', finish);
      process.off('SIGINT', finish);
      process.off('SIGTERM', finish);
      resolve();
    };
    const offClose = runtime.onClose(finish);
    process.stdin.once('end', finish);
    process.once('SIGINT', finish);
    process.once('SIGTERM', finish);
  });

  runtime.stop();
  await connection.stop();
  unsubProjection();
  unsubActivity();
  unsubConnection();
  return 0;
}

/** Resolve WorkbenchCliOptions from CLI flags + env vars. */
export function resolveWorkbenchOptions(
  flags: {
    repository: string;
    baseUrl?: string;
    wsUrl?: string;
    readToken?: string;
    operateToken?: string;
    snapshotDir?: string;
    actorId?: string;
  },
  env: NodeJS.ProcessEnv = process.env
): WorkbenchCliOptions | { error: string } {
  const baseUrl = flags.baseUrl ?? env.KILN_URL;
  const wsUrl = flags.wsUrl ?? env.KILN_WS_URL;
  const readToken = flags.readToken ?? env.KILN_READ_TOKEN;
  const operateToken = flags.operateToken ?? env.KILN_OPERATE_TOKEN;
  if (!baseUrl) return { error: 'KILN_URL (or --kiln-url) is required' };
  if (!wsUrl) return { error: 'KILN_WS_URL (or --kiln-ws-url) is required' };
  if (!readToken) return { error: 'KILN_READ_TOKEN (or --kiln-read-token) is required' };
  if (!operateToken) return { error: 'KILN_OPERATE_TOKEN (or --kiln-operate-token) is required' };
  return {
    repository: flags.repository,
    baseUrl,
    wsUrl,
    readToken,
    operateToken,
    ...(flags.snapshotDir ? { snapshotDir: flags.snapshotDir } : {}),
    ...(flags.actorId ? { actorId: flags.actorId } : {})
  };
}
