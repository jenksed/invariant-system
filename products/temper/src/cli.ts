#!/usr/bin/env node
import process from 'node:process';
import { loadWorkbench } from './load.js';
import { FOCUSES, renderWorkbench } from './render.js';
import type { Focus, WorkbenchModel } from './types.js';
import { LiveMode } from './live.js';
import { resolveWorkbenchOptions, runWorkbench } from './workbench_cli.js';

interface Arguments {
  repository: string;
  snapshot: boolean;
  live: boolean;
  workbench: boolean;
  once: boolean;
  focus: Focus;
  width?: number;
  runPath?: string;
  planPath?: string;
  kilnUrl?: string;
  kilnWsUrl?: string;
  kilnReadToken?: string;
  kilnOperateToken?: string;
  snapshotDir?: string;
  actorId?: string;
}

const ESC = {
  clear: '[2J[H',
  hideCursor: '[?25l',
  showCursor: '[?25h'
};

async function main(): Promise<void> {
  const args = parseArguments(process.argv.slice(2));
  const width = args.width ?? process.stdout.columns ?? 100;

  // Workbench Alpha default: when no --snapshot/--live flag is given,
  // open the new Workbench TUI against the bounded Kiln daemon.
  // `--workbench` is the explicit form of the same mode.
  if (args.workbench || (!args.snapshot && !args.live)) {
    const resolved = resolveWorkbenchOptions({
      repository: args.repository,
      ...(args.kilnUrl ? { baseUrl: args.kilnUrl } : {}),
      ...(args.kilnWsUrl ? { wsUrl: args.kilnWsUrl } : {}),
      ...(args.kilnReadToken ? { readToken: args.kilnReadToken } : {}),
      ...(args.kilnOperateToken ? { operateToken: args.kilnOperateToken } : {}),
      ...(args.snapshotDir ? { snapshotDir: args.snapshotDir } : {}),
      ...(args.actorId ? { actorId: args.actorId } : {})
    });
    if ('error' in resolved) {
      process.stderr.write(`temper: ${resolved.error}\n`);
      process.exit(2);
    }
    const code = await runWorkbench({ ...resolved, once: args.once });
    process.exit(code);
  }

  if (args.live) {
    await runLive(args, width);
    return;
  }

  const model = await loadWorkbench(args.repository, {
    ...(args.runPath ? { runPath: args.runPath } : {}),
    ...(args.planPath ? { planPath: args.planPath } : {})
  });

  if (args.snapshot || !process.stdin.isTTY || !process.stdout.isTTY) {
    process.stdout.write(`${renderWorkbench(model, args.focus, width)}\n`);
    return;
  }

  let focus = args.focus;
  const draw = (): void => {
    process.stdout.write(ESC.clear);
    process.stdout.write(renderWorkbench(model, focus, process.stdout.columns ?? width));
  };
  const finish = (): void => {
    if (process.stdin.isRaw) process.stdin.setRawMode(false);
    process.stdin.pause();
    process.stdout.write(`${ESC.showCursor}\n`);
  };

  process.stdout.write(ESC.hideCursor);
  process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdin.setEncoding('utf8');
  draw();

  process.stdin.on('data', (key: string) => {
    if (key === 'q' || key === '') {
      finish();
      return;
    }
    if (key === '') focus = 'overview';
    else if (key === 'p') focus = 'plan';
    else if (key === 'u') focus = 'run';
    else if (key === 'a') focus = 'authority';
    else if (key === 'e') focus = 'evidence';
    else if (key === 't') focus = 'artifacts';
    else if (key === 'r') focus = 'raw';
    else if (key === '?') focus = 'help';
    else if (key === '\t' || key === '[C' || key === '[B') focus = adjacent(focus, 1);
    else if (key === '[D' || key === '[A') focus = adjacent(focus, -1);
    draw();
  });
}

// WP-09 Lane 3: live mode. Reads Kiln endpoint + tokens from env
// (KILN_URL, KILN_READ_TOKEN, KILN_OPERATE_TOKEN, KILN_WS_URL),
// opens a project.open RPC for canonical state, subscribes to the
// activity stream, and re-renders on every notification. Snapshot
// mode is preserved for offline use.
async function runLive(args: Arguments, width: number): Promise<void> {
  const baseUrl = process.env.KILN_URL;
  const readToken = process.env.KILN_READ_TOKEN;
  const operateToken = process.env.KILN_OPERATE_TOKEN;
  const wsUrl = process.env.KILN_WS_URL;

  if (!baseUrl || !readToken || !operateToken || !wsUrl) {
    process.stderr.write(
      'temper --live requires KILN_URL, KILN_READ_TOKEN, KILN_OPERATE_TOKEN, KILN_WS_URL\n'
    );
    process.exit(2);
  }

  const live = new LiveMode({
    baseUrl,
    wsUrl,
    readToken,
    operateToken,
    repository: args.repository,
    onProjection: (model) => {
      if (!process.stdout.isTTY) {
        process.stdout.write(`${renderWorkbench(model, focus, width)}\n`);
        return;
      }
      process.stdout.write(ESC.clear);
      process.stdout.write(renderWorkbench(model, focus, process.stdout.columns ?? width));
    }
  });

  let focus: Focus = args.focus;

  const finish = (): void => {
    if (process.stdin.isRaw) process.stdin.setRawMode(false);
    process.stdin.pause();
    process.stdout.write(`${ESC.showCursor}\n`);
    void live.stop();
    process.exit(0);
  };

  try {
    const model = await live.start();

    if (args.snapshot || !process.stdin.isTTY || !process.stdout.isTTY) {
      process.stdout.write(`${renderWorkbench(model, focus, width)}\n`);
      await live.stop();
      return;
    }

    process.stdout.write(ESC.hideCursor);
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.setEncoding('utf8');

    process.stdin.on('data', (key: string) => {
      if (key === 'q' || key === '') {
        finish();
        return;
      }
      if (key === '') focus = 'overview';
      else if (key === 'p') focus = 'plan';
      else if (key === 'u') focus = 'run';
      else if (key === 'a') focus = 'authority';
      else if (key === 'e') focus = 'evidence';
      else if (key === 't') focus = 'artifacts';
      else if (key === 'r') focus = 'raw';
      else if (key === '?') focus = 'help';
      else if (key === '\t' || key === '[C' || key === '[B') focus = adjacent(focus, 1);
      else if (key === '[D' || key === '[A') focus = adjacent(focus, -1);
      const m = live.currentModel as WorkbenchModel | undefined;
      if (m) {
        process.stdout.write(ESC.clear);
        process.stdout.write(renderWorkbench(m, focus, process.stdout.columns ?? width));
      }
    });
  } catch (err) {
    process.stderr.write(`temper --live: ${(err as Error).message}\n`);
    process.exit(1);
  }
}

function adjacent(focus: Focus, offset: number): Focus {
  const index = FOCUSES.indexOf(focus);
  return FOCUSES[(index + offset + FOCUSES.length) % FOCUSES.length] ?? 'overview';
}

function parseArguments(argv: string[]): Arguments {
  let repository = process.cwd();
  let snapshot = false;
  let live = false;
  let workbench = false;
  let once = false;
  let focus: Focus = 'overview';
  let width: number | undefined;
  let runPath: string | undefined;
  let planPath: string | undefined;
  let kilnUrl: string | undefined;
  let kilnWsUrl: string | undefined;
  let kilnReadToken: string | undefined;
  let kilnOperateToken: string | undefined;
  let snapshotDir: string | undefined;
  let actorId: string | undefined;

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (!argument) continue;
    if (argument === '--snapshot') snapshot = true;
    else if (argument === '--live') live = true;
    else if (argument === '--workbench') workbench = true;
    else if (argument === '--once') once = true;
    else if (argument === '--help' || argument === '-h') {
      printUsage();
      process.exit(0);
    } else if (argument === '--focus') focus = parseFocus(requireValue(argv, ++index, '--focus'));
    else if (argument === '--width') {
      width = Number.parseInt(requireValue(argv, ++index, '--width'), 10);
      if (!Number.isFinite(width) || width < 48) throw new Error('--width must be an integer >= 48');
    } else if (argument === '--run') runPath = requireValue(argv, ++index, '--run');
    else if (argument === '--plan') planPath = requireValue(argv, ++index, '--plan');
    else if (argument === '--kiln-url') kilnUrl = requireValue(argv, ++index, '--kiln-url');
    else if (argument === '--kiln-ws-url') kilnWsUrl = requireValue(argv, ++index, '--kiln-ws-url');
    else if (argument === '--kiln-read-token') kilnReadToken = requireValue(argv, ++index, '--kiln-read-token');
    else if (argument === '--kiln-operate-token') kilnOperateToken = requireValue(argv, ++index, '--kiln-operate-token');
    else if (argument === '--snapshot-dir') snapshotDir = requireValue(argv, ++index, '--snapshot-dir');
    else if (argument === '--actor-id') actorId = requireValue(argv, ++index, '--actor-id');
    else if (argument.startsWith('-')) throw new Error(`unknown option: ${argument}`);
    else repository = argument;
  }
  return {
    repository,
    snapshot,
    live,
    workbench,
    once,
    focus,
    ...(width !== undefined ? { width } : {}),
    ...(runPath ? { runPath } : {}),
    ...(planPath ? { planPath } : {}),
    ...(kilnUrl ? { kilnUrl } : {}),
    ...(kilnWsUrl ? { kilnWsUrl } : {}),
    ...(kilnReadToken ? { kilnReadToken } : {}),
    ...(kilnOperateToken ? { kilnOperateToken } : {}),
    ...(snapshotDir ? { snapshotDir } : {}),
    ...(actorId ? { actorId } : {})
  };
}

function requireValue(argv: string[], index: number, flag: string): string {
  const value = argv[index];
  if (!value) throw new Error(`${flag} requires a value`);
  return value;
}

function parseFocus(value: string): Focus {
  if (FOCUSES.includes(value as Focus)) return value as Focus;
  throw new Error(`--focus must be one of: ${FOCUSES.join(', ')}`);
}

function printUsage(): void {
  process.stdout.write(`Usage: temper [repository] [options]\n\n`);
  process.stdout.write(`Options:\n`);
  process.stdout.write(`  --workbench      open the Workbench TUI (default when no other mode is set)\n`);
  process.stdout.write(`  --snapshot       render once without interactive terminal control\n`);
  process.stdout.write(`  --live           legacy live mode (kept for compatibility)\n`);
  process.stdout.write(`  --once           render a single workbench frame and exit (case-study capture)\n`);
  process.stdout.write(`  --kiln-url URL           Kiln daemon base URL (default: $KILN_URL)\n`);
  process.stdout.write(`  --kiln-ws-url URL        Kiln WebSocket URL (default: $KILN_WS_URL)\n`);
  process.stdout.write(`  --kiln-read-token TOKEN  Read-scoped token (default: $KILN_READ_TOKEN)\n`);
  process.stdout.write(`  --kiln-operate-token TKN Operate-scoped token (default: $KILN_OPERATE_TOKEN)\n`);
  process.stdout.write(`  --snapshot-dir PATH      Directory to write milestone snapshots\n`);
  process.stdout.write(`  --actor-id ID            Actor id for session.start (default: temper_operator)\n`);
  process.stdout.write(`  --focus <name>   initial focus (${FOCUSES.join(', ')})\n`);
  process.stdout.write(`  --width <cols>   snapshot width (minimum 48)\n`);
  process.stdout.write(`  --run <path>     explicit Loadout Run record\n`);
  process.stdout.write(`  --plan <path>    explicit Loadout Plan\n`);
}

main().catch((error: unknown) => {
  process.stderr.write(`temper: ${(error as Error).message}\n`);
  process.exitCode = 1;
});
