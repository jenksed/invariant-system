#!/usr/bin/env node
import process from 'node:process';
import { loadWorkbench } from './load.js';
import { FOCUSES, renderWorkbench } from './render.js';
import type { Focus } from './types.js';

interface Arguments {
  repository: string;
  snapshot: boolean;
  focus: Focus;
  width?: number;
  runPath?: string;
  planPath?: string;
}

async function main(): Promise<void> {
  const args = parseArguments(process.argv.slice(2));
  const model = await loadWorkbench(args.repository, {
    ...(args.runPath ? { runPath: args.runPath } : {}),
    ...(args.planPath ? { planPath: args.planPath } : {})
  });
  const width = args.width ?? process.stdout.columns ?? 100;

  if (args.snapshot || !process.stdin.isTTY || !process.stdout.isTTY) {
    process.stdout.write(`${renderWorkbench(model, args.focus, width)}\n`);
    return;
  }

  let focus = args.focus;
  const draw = (): void => {
    process.stdout.write('\u001b[2J\u001b[H');
    process.stdout.write(renderWorkbench(model, focus, process.stdout.columns ?? width));
  };
  const finish = (): void => {
    if (process.stdin.isRaw) process.stdin.setRawMode(false);
    process.stdin.pause();
    process.stdout.write('\u001b[?25h\n');
  };

  process.stdout.write('\u001b[?25l');
  process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdin.setEncoding('utf8');
  draw();

  process.stdin.on('data', (key: string) => {
    if (key === 'q' || key === '\u0003') {
      finish();
      return;
    }
    if (key === '\u001b') focus = 'overview';
    else if (key === 'p') focus = 'plan';
    else if (key === 'u') focus = 'run';
    else if (key === 'a') focus = 'authority';
    else if (key === 'e') focus = 'evidence';
    else if (key === 't') focus = 'artifacts';
    else if (key === 'r') focus = 'raw';
    else if (key === '?') focus = 'help';
    else if (key === '\t' || key === '\u001b[C' || key === '\u001b[B') focus = adjacent(focus, 1);
    else if (key === '\u001b[D' || key === '\u001b[A') focus = adjacent(focus, -1);
    draw();
  });
}

function adjacent(focus: Focus, offset: number): Focus {
  const index = FOCUSES.indexOf(focus);
  return FOCUSES[(index + offset + FOCUSES.length) % FOCUSES.length] ?? 'overview';
}

function parseArguments(argv: string[]): Arguments {
  let repository = process.cwd();
  let snapshot = false;
  let focus: Focus = 'overview';
  let width: number | undefined;
  let runPath: string | undefined;
  let planPath: string | undefined;

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (!argument) continue;
    if (argument === '--snapshot') snapshot = true;
    else if (argument === '--help' || argument === '-h') {
      printUsage();
      process.exit(0);
    } else if (argument === '--focus') focus = parseFocus(requireValue(argv, ++index, '--focus'));
    else if (argument === '--width') {
      width = Number.parseInt(requireValue(argv, ++index, '--width'), 10);
      if (!Number.isFinite(width) || width < 48) throw new Error('--width must be an integer >= 48');
    } else if (argument === '--run') runPath = requireValue(argv, ++index, '--run');
    else if (argument === '--plan') planPath = requireValue(argv, ++index, '--plan');
    else if (argument.startsWith('-')) throw new Error(`unknown option: ${argument}`);
    else repository = argument;
  }
  return {
    repository,
    snapshot,
    focus,
    ...(width !== undefined ? { width } : {}),
    ...(runPath ? { runPath } : {}),
    ...(planPath ? { planPath } : {})
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
  process.stdout.write(`  --snapshot       render once without interactive terminal control\n`);
  process.stdout.write(`  --focus <name>   initial focus (${FOCUSES.join(', ')})\n`);
  process.stdout.write(`  --width <cols>   snapshot width (minimum 48)\n`);
  process.stdout.write(`  --run <path>     explicit Loadout Run record\n`);
  process.stdout.write(`  --plan <path>    explicit Loadout Plan\n`);
}

main().catch((error: unknown) => {
  process.stderr.write(`temper: ${(error as Error).message}\n`);
  process.exitCode = 1;
});
