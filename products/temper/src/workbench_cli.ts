/** Temper Workbench entry point: real Kiln projection + operator controls. */

import { execFileSync } from 'node:child_process';
import { TuiRuntime } from './tui/tui.js';
import { createHomeScreen, setHomeProjection, type HomeState } from './screens/home.js';
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
import { CommandExecutor } from './workbench/command_executor.js';
import { OperatorController } from './workbench/operator.js';
import { MotionLog } from './workbench/motion.js';
import { PulseLog } from './workbench/pulse.js';
import type { WorkbenchProjection } from './workbench/projection.js';

export interface WorkbenchCliOptions {
  repository: string;
  baseUrl: string;
  wsUrl: string;
  readToken: string;
  operateToken: string;
  actorId?: string;
  snapshotDir?: string;
  once?: boolean;
}

export async function runWorkbench(options: WorkbenchCliOptions): Promise<number> {
  const actorId = options.actorId ?? 'temper_operator';
  const transportConfig = {
    baseUrl: options.baseUrl,
    wsUrl: options.wsUrl,
    readToken: options.readToken,
    operateToken: options.operateToken
  };
  const connection = new WorkbenchConnection({ ...transportConfig, repository: options.repository });
  const operator = new OperatorController(transportConfig);
  const runtime = new TuiRuntime(options.snapshotDir ? { snapshotDir: options.snapshotDir } : {});
  const motionLog = new MotionLog();
  const pulseLog = new PulseLog();

  let homeState: HomeState | null = null;
  let workState: WorkState | null = null;
  let active: 'home' | 'work' = 'home';
  let homeScreen: ReturnType<typeof createHomeScreen>;

  const openDiff = (): void => {
    const repoRoot = options.repository;
    const diffSource = (root: string): Promise<{ ok: boolean; text: string; error?: string }> => {
      try {
        const text = execFileSync('git', ['-C', root, 'diff'], {
          encoding: 'utf8', maxBuffer: 2 * 1024 * 1024, stdio: ['ignore', 'pipe', 'pipe']
        });
        return Promise.resolve({ ok: true, text: text ?? '' });
      } catch (err) {
        const e = err as { stdout?: Buffer | string; stderr?: Buffer | string; message?: string };
        const stdout = typeof e.stdout === 'string' ? e.stdout : e.stdout?.toString('utf8') ?? '';
        const stderr = typeof e.stderr === 'string' ? e.stderr : e.stderr?.toString('utf8') ?? '';
        if (stdout.length > 0) return Promise.resolve({ ok: true, text: stdout });
        return Promise.resolve({ ok: false, text: '', error: stderr || e.message || 'git diff failed' });
      }
    };
    runtime.push(createDiffScreen({
      repositoryRoot: repoRoot,
      diffSource,
      onExit: () => runtime.pop(),
      onResult: (result) => { void result; }
    }));
  };

  const submitDecision = async (
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION'
  ): Promise<{ ok: boolean; errorCode?: string; errorReason?: string }> => {
    const envelope = connection.current().sessionQuery?.references?.decision_envelope;
    if (!envelope) {
      return {
        ok: false,
        errorCode: 'E_DECISION_CONTEXT_UNAVAILABLE',
        errorReason: 'no canonical pending decision envelope is currently recorded'
      };
    }
    try {
      const result = await connection.submitHumanDecision(
        decision,
        {
          plan_ref: envelope.plan_ref,
          patch_ref: envelope.patch_ref,
          result_state_digest: envelope.result_state_digest,
          review_ref: envelope.review_ref
        },
        actorId
      );
      if (workState) {
        workState = setHumanDecideResult(workState, {
          status: result.ok ? 'success' : 'rejected',
          decision,
          code: result.ok ? null : (result.errorCode ?? 'E_UNKNOWN'),
          reason: result.ok ? null : (result.errorReason ?? ''),
          at: new Date().toISOString()
        });
        if (active === 'work') runtime.setTopState(workState);
      }
      return result;
    } catch (err) {
      const result = { ok: false, errorCode: 'E_TRANSPORT', errorReason: (err as Error).message };
      if (workState) {
        workState = setHumanDecideResult(workState, {
          status: 'error', decision, code: result.errorCode, reason: result.errorReason,
          at: new Date().toISOString()
        });
        if (active === 'work') runtime.setTopState(workState);
      }
      return result;
    }
  };

  const workScreen = (intent: string) => createWorkScreen({
    intent,
    onExit: () => {
      runtime.replace(homeScreen);
      active = 'home';
      homeState = setHomeProjection(homeScreen.init() as HomeState, connection.current());
      runtime.setTopState(homeState);
    },
    onHumanDecide: async (decision) => {
      const result = await submitDecision(decision);
      if (result.ok) await connection.resync('resync');
      return result;
    },
    onOpenDiff: openDiff
  });

  const startAndOpenWork = async (intent: string): Promise<{ ok: true } | { ok: false; error: string }> => {
    try {
      await connection.startSession(intent, actorId);
      const nextScreen = workScreen(intent);
      workState = setWorkProjection(nextScreen.init() as WorkState, connection.current());
      runtime.replace(nextScreen);
      active = 'work';
      runtime.setTopState(workState);
      return { ok: true };
    } catch (err) {
      return { ok: false, error: (err as Error).message };
    }
  };

  const executor = new CommandExecutor({
    getProjection: () => connection.current(),
    operator,
    actorId,
    startSession: async (objective) => {
      const result = await startAndOpenWork(objective);
      if (!result.ok) throw new Error(result.error);
    },
    resync: async () => { await connection.resync('resync'); },
    decide: submitDecision,
    reconnect: async () => {
      try {
        await connection.reconnect();
        return { ok: true };
      } catch (err) {
        return { ok: false, error: (err as Error).message };
      }
    },
    openDiff,
    quit: () => runtime.stop()
  });

  homeScreen = createHomeScreen({
    onSubmitIntent: startAndOpenWork,
    onCommand: async (line) => {
      const result = await executor.execute(line);
      return { ok: result.ok, lines: result.lines };
    },
    onInvalidate: () => runtime.invalidate()
  });

  homeState = homeScreen.init() as HomeState;
  runtime.push(homeScreen);
  runtime.setTopState(homeState);

  const unsubProjection = connection.onProjection((projection: WorkbenchProjection) => {
    if (homeState) homeState = setHomeProjection(homeState, projection);
    if (workState) workState = setWorkProjection(workState, projection);
    if (projection.sessionQuery) {
      for (const event of motionLog.observe(projection.sessionQuery)) {
        if (workState) workState = appendWorkMotion(workState, event);
      }
    }
    if (active === 'home' && homeState) runtime.setTopState(homeState);
    if (active === 'work' && workState) runtime.setTopState(workState);
  });

  const unsubActivity = connection.onActivity((frame) => {
    const event = pulseLog.observe(frame);
    if (workState) {
      workState = appendWorkPulse(workState, event);
      if (active === 'work') runtime.setTopState(workState);
    }
  });

  let previousConnection: WorkbenchProjection['connection'] | null = null;
  const unsubConnection = connection.onConnection((state) => {
    if (workState) {
      if (state === 'disconnected' || state === 'reconnecting') {
        workState = markWorkDisconnect(workState);
      } else if (state === 'connected' && previousConnection !== 'connected') {
        workState = markWorkReconnect(workState);
      }
      if (active === 'work') runtime.setTopState(workState);
    }
    previousConnection = state;
  });

  runtime.start();
  try {
    await connection.open();
  } catch (err) {
    if (options.once) {
      runtime.stop(); await connection.stop(); unsubProjection(); unsubActivity(); unsubConnection();
      process.stderr.write(`temper: ${(err as Error).message}\n`);
      return 1;
    }
  }

  if (options.once) {
    await new Promise((resolve) => setTimeout(resolve, 50));
    const snapshotPath = runtime.snapshot('workbench-open');
    if (snapshotPath) process.stderr.write(`temper: snapshot written: ${snapshotPath}\n`);
    runtime.stop(); await connection.stop(); unsubProjection(); unsubActivity(); unsubConnection();
    return 0;
  }

  await new Promise<void>((resolve) => {
    let settled = false;
    const finish = (): void => {
      if (settled) return;
      settled = true;
      offClose(); process.stdin.off('end', finish); process.off('SIGINT', finish); process.off('SIGTERM', finish);
      resolve();
    };
    const offClose = runtime.onClose(finish);
    process.stdin.once('end', finish);
    process.once('SIGINT', finish);
    process.once('SIGTERM', finish);
  });

  runtime.stop();
  await connection.stop();
  unsubProjection(); unsubActivity(); unsubConnection();
  return 0;
}

export function resolveWorkbenchOptions(
  flags: {
    repository: string; baseUrl?: string; wsUrl?: string; readToken?: string;
    operateToken?: string; snapshotDir?: string; actorId?: string;
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
    repository: flags.repository, baseUrl, wsUrl, readToken, operateToken,
    ...(flags.snapshotDir ? { snapshotDir: flags.snapshotDir } : {}),
    ...(flags.actorId ? { actorId: flags.actorId } : {})
  };
}
