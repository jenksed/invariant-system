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

import { execFileSync } from 'node:child_process';
import { TuiRuntime } from './tui/tui.js';
import { setInputValue } from './tui/input.js';
import type { ScreenSpec } from './tui/screen.js';
import {
  createHomeScreen,
  setHomeProjection,
  type HomeState
} from './screens/home.js';
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
import { createCommandScreen } from './screens/command.js';
import { WorkbenchConnection } from './workbench/connection.js';
import { CommandExecutor } from './workbench/commands.js';
import { readTemperConfig, resolveTemperConfigPath } from './workbench/config.js';
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
  /** Actor id used for session operations; defaults to "temper_operator". */
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

  // Actor identity is operator configuration, not workflow authority.
  // /config set actor_id changes this value for subsequent real RPCs in
  // this process and persists it for future launches.
  let actorId = options.actorId ?? 'temper_operator';

  const commandExecutor = new CommandExecutor(connection, {
    repository: options.repository,
    baseUrl: options.baseUrl,
    wsUrl: options.wsUrl,
    ...(options.snapshotDir ? { snapshotDir: options.snapshotDir } : {}),
    getActorId: () => actorId,
    setActorId: (value) => {
      actorId = value;
    }
  });

  // Bounded projection vocabulary derived from authoritative sources.
  const motionLog = new MotionLog();
  const pulseLog = new PulseLog();

  // Mutable screen state mirrors; the orchestrator mutates them and
  // pushes the result to the runtime.
  let homeState: HomeState | null = null;
  let workState: WorkState | null = null;
  let active: 'home' | 'work' = 'home';

  function openDiffSurface(): void {
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
        if (stdout.length > 0) return Promise.resolve({ ok: true, text: stdout });
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
        onExit: () => runtime.pop(),
        onResult: (result) => {
          void result;
        }
      })
    );
  }

  function openCommandConsole(initial = '/', executeOnOpen = false): void {
    runtime.push(
      createCommandScreen({
        initial,
        executeOnOpen,
        execute: (input) => commandExecutor.execute(input),
        invalidate: () => runtime.invalidate(),
        onOpenDiff: () => {
          // Replace the command console with the bounded diff instead of
          // stacking a diff over a stale command result.
          runtime.pop();
          openDiffSurface();
        },
        onQuit: () => runtime.stop()
      })
    );
  }

  const baseHomeScreen = createHomeScreen({
    onSubmitIntent: async (intent) => {
      try {
        await connection.startSession(intent, actorId);
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
    },
    onOpenPalette: () => openCommandConsole('/')
  });

  // Home's main text box remains the free-text intent surface, but a
  // leading slash is never allowed to become a Session objective. Enter on
  // `/status` opens the same command console and executes that exact command.
  const homeScreen: ScreenSpec = {
    ...baseHomeScreen,
    update: (state, key, ctx) => {
      const home = state as HomeState;
      if (key.kind === 'enter' && home.submitState === 'idle') {
        const candidate = home.input.value.trim();
        if (candidate.startsWith('/') && candidate.length > 1) {
          openCommandConsole(candidate, true);
          return {
            state: { ...home, input: setInputValue(home.input, '') },
            msgs: []
          };
        }
      }
      return baseHomeScreen.update(state, key, ctx);
    }
  };

  function workScreen(intent: string): ScreenSpec {
    const base = createWorkScreen({
      intent,
      onExit: () => {
        runtime.replace(homeScreen);
        active = 'home';
        if (homeState) runtime.setTopState(homeState);
      },
      onHumanDecide: async (decision) => {
        // N2 (Repair A): invoke the real bounded `human.decide` Kiln RPC.
        // The bounded envelope is constructed ONLY from canonical state.
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
            actorId
          );
          setResult(result);
          if (result.ok) await connection.resync('resync');
          return result;
        } catch (err) {
          const errResult = { ok: false, errorCode: 'E_TRANSPORT', errorReason: (err as Error).message };
          setResult(errResult);
          return errResult;
        }
      },
      onOpenDiff: openDiffSurface
    });

    // Active Work is not an input screen, so intercept `/` and ctrl-k at
    // the screen boundary and open the same command console used by Home.
    return {
      ...base,
      update: (state, key, ctx) => {
        if ((key.kind === 'char' && key.value === '/') || (key.kind === 'ctrl' && key.value === 'k')) {
          openCommandConsole('/');
          return { state, msgs: [] };
        }
        return base.update(state, key, ctx);
      }
    };
  }

  // Keep the orchestration mirror initialized alongside the runtime's copy.
  homeState = homeScreen.init() as HomeState;
  runtime.push(homeScreen);
  runtime.setTopState(homeState);

  // Wire projection updates into the active screen state. Both screens
  // receive the latest projection so the Work screen is ready immediately.
  const unsubProjection = connection.onProjection((projection: WorkbenchProjection) => {
    if (homeState) homeState = setHomeProjection(homeState, projection);
    if (workState) workState = setWorkProjection(workState, projection);
    if (projection.sessionQuery) {
      const emitted = motionLog.observe(projection.sessionQuery);
      for (const ev of emitted) {
        if (workState) workState = appendWorkMotion(workState, ev);
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
    if (snapshotPath) process.stderr.write(`temper: snapshot written: ${snapshotPath}\n`);
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

/** Resolve WorkbenchCliOptions from CLI flags + env + persistent config.
 * Precedence: CLI > environment > persistent non-secret config.
 * Secrets are never read from persistent config. */
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
  const configPath = resolveTemperConfigPath(env);
  const persisted = readTemperConfig(configPath);
  if (persisted.error) return { error: `invalid Temper config ${configPath}: ${persisted.error}` };

  const baseUrl = flags.baseUrl ?? env.KILN_URL ?? persisted.config.kiln_url;
  const wsUrl = flags.wsUrl ?? env.KILN_WS_URL ?? persisted.config.kiln_ws_url;
  const readToken = flags.readToken ?? env.KILN_READ_TOKEN;
  const operateToken = flags.operateToken ?? env.KILN_OPERATE_TOKEN;
  const snapshotDir = flags.snapshotDir ?? env.TEMPER_SNAPSHOT_DIR ?? persisted.config.snapshot_dir;
  const actorId = flags.actorId ?? env.TEMPER_ACTOR_ID ?? persisted.config.actor_id;

  if (!baseUrl) return { error: 'KILN_URL, --kiln-url, or persisted kiln_url is required' };
  if (!wsUrl) return { error: 'KILN_WS_URL, --kiln-ws-url, or persisted kiln_ws_url is required' };
  if (!readToken) return { error: 'KILN_READ_TOKEN (or --kiln-read-token) is required; secrets are not persisted' };
  if (!operateToken) return { error: 'KILN_OPERATE_TOKEN (or --kiln-operate-token) is required; secrets are not persisted' };
  return {
    repository: flags.repository,
    baseUrl,
    wsUrl,
    readToken,
    operateToken,
    ...(snapshotDir ? { snapshotDir } : {}),
    ...(actorId ? { actorId } : {})
  };
}
