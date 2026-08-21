/**
 * Temper operator command registry.
 *
 * Slash commands are deterministic control operations, never model prompts.
 * This registry owns only syntax, aliases, help text, and coarse availability.
 * Execution remains in the Workbench orchestrator and Kiln remains workflow
 * authority.
 */

import type { WorkbenchProjection } from './projection.js';

export type CommandAuthority = 'temper' | 'kiln-read' | 'kiln-operate';

export type CommandId =
  | 'help'
  | 'status'
  | 'project'
  | 'session'
  | 'new'
  | 'resume'
  | 'cancel'
  | 'next'
  | 'diff'
  | 'evidence'
  | 'why'
  | 'graph'
  | 'accept'
  | 'reject'
  | 'revise'
  | 'reconnect'
  | 'doctor'
  | 'capabilities'
  | 'providers'
  | 'quit';

export interface CommandSpec {
  id: CommandId;
  name: string;
  aliases: string[];
  usage: string;
  summary: string;
  authority: CommandAuthority;
  requiresSession?: boolean;
  requiresPendingDecision?: boolean;
}

export interface ParsedCommand {
  spec: CommandSpec;
  argv: string[];
  raw: string;
}

export interface CommandAvailability {
  available: boolean;
  reason?: string;
}

const SPECS: CommandSpec[] = [
  { id: 'help', name: 'help', aliases: ['?'], usage: '/help [command]', summary: 'show commands and truthful availability', authority: 'temper' },
  { id: 'status', name: 'status', aliases: [], usage: '/status', summary: 'show connection and canonical Session state', authority: 'temper' },
  { id: 'project', name: 'project', aliases: [], usage: '/project', summary: 'show the project opened by Kiln', authority: 'temper' },
  { id: 'session', name: 'session', aliases: [], usage: '/session', summary: 'show the current canonical Session', authority: 'temper', requiresSession: true },
  { id: 'new', name: 'new', aliases: [], usage: '/new <objective>', summary: 'start a real Kiln Session', authority: 'kiln-operate' },
  { id: 'resume', name: 'resume', aliases: [], usage: '/resume', summary: 'resume the current Session through Kiln', authority: 'kiln-operate', requiresSession: true },
  { id: 'cancel', name: 'cancel', aliases: [], usage: '/cancel', summary: 'cancel the current Session through Kiln', authority: 'kiln-operate', requiresSession: true },
  { id: 'next', name: 'next', aliases: [], usage: '/next', summary: 'ask Kiln for valid next actions', authority: 'kiln-read', requiresSession: true },
  { id: 'diff', name: 'diff', aliases: ['d'], usage: '/diff', summary: 'open the bounded repository diff', authority: 'temper', requiresSession: true },
  { id: 'evidence', name: 'evidence', aliases: ['proof'], usage: '/evidence', summary: 'show canonical evidence and decision references', authority: 'temper', requiresSession: true },
  { id: 'why', name: 'why', aliases: [], usage: '/why', summary: 'explain the current frontier from canonical state and next actions', authority: 'kiln-read', requiresSession: true },
  { id: 'graph', name: 'graph', aliases: ['g'], usage: '/graph', summary: 'show the canonical governed-work graph', authority: 'kiln-read', requiresSession: true },
  { id: 'accept', name: 'accept', aliases: [], usage: '/accept', summary: 'submit ACCEPT to the real human.decide RPC', authority: 'kiln-operate', requiresSession: true, requiresPendingDecision: true },
  { id: 'reject', name: 'reject', aliases: [], usage: '/reject', summary: 'submit REJECT to the real human.decide RPC', authority: 'kiln-operate', requiresSession: true, requiresPendingDecision: true },
  { id: 'revise', name: 'revise', aliases: ['request-revision'], usage: '/revise', summary: 'submit REQUEST_REVISION to the real human.decide RPC', authority: 'kiln-operate', requiresSession: true, requiresPendingDecision: true },
  { id: 'reconnect', name: 'reconnect', aliases: [], usage: '/reconnect', summary: 're-establish Kiln transport and rehydrate canonical state', authority: 'temper' },
  { id: 'doctor', name: 'doctor', aliases: [], usage: '/doctor', summary: 'run bounded Workbench health checks', authority: 'temper' },
  { id: 'capabilities', name: 'capabilities', aliases: ['caps'], usage: '/capabilities', summary: 'show implemented controls and current availability', authority: 'temper' },
  { id: 'providers', name: 'providers', aliases: [], usage: '/providers', summary: 'show provider/runtime readiness without claiming selection authority', authority: 'temper' },
  { id: 'quit', name: 'quit', aliases: ['q'], usage: '/quit', summary: 'cleanly stop Temper', authority: 'temper' }
];

const LOOKUP = new Map<string, CommandSpec>();
for (const spec of SPECS) {
  LOOKUP.set(spec.name, spec);
  for (const alias of spec.aliases) LOOKUP.set(alias, spec);
}

export function commandSpecs(): readonly CommandSpec[] {
  return SPECS;
}

export function parseCommand(line: string): ParsedCommand | { error: string } {
  const raw = line.trim();
  if (!raw.startsWith('/')) return { error: 'operator commands must begin with /' };
  const body = raw.slice(1).trim();
  if (body.length === 0) return { error: 'empty operator command' };
  const parts = splitArgs(body);
  const name = (parts.shift() ?? '').toLowerCase();
  const spec = LOOKUP.get(name);
  if (!spec) return { error: `unknown command: /${name}` };
  return { spec, argv: parts, raw };
}

export function commandAvailability(
  spec: CommandSpec,
  projection: WorkbenchProjection | null
): CommandAvailability {
  if (spec.requiresSession && !projection?.sessionId) {
    return { available: false, reason: 'no canonical Session is open' };
  }
  if (spec.requiresPendingDecision) {
    const pending = projection?.sessionQuery?.pending_decision;
    const envelope = projection?.sessionQuery?.references?.decision_envelope;
    if (pending == null || envelope == null) {
      return { available: false, reason: 'no canonical pending decision envelope is available' };
    }
  }
  if (spec.authority !== 'temper' && projection?.connection !== 'connected') {
    return { available: false, reason: 'Kiln is not connected' };
  }
  return { available: true };
}

export function formatCommandHelp(projection: WorkbenchProjection | null): string {
  const lines = ['OPERATOR COMMANDS'];
  for (const spec of SPECS) {
    const availability = commandAvailability(spec, projection);
    const suffix = availability.available ? 'available' : `unavailable — ${availability.reason}`;
    lines.push(`${spec.usage.padEnd(24)} ${suffix}`);
    lines.push(`  ${spec.summary}`);
  }
  return lines.join('\n');
}

function splitArgs(input: string): string[] {
  const out: string[] = [];
  let current = '';
  let quote: '"' | "'" | null = null;
  let escaped = false;
  for (const ch of input) {
    if (escaped) {
      current += ch;
      escaped = false;
      continue;
    }
    if (ch === '\\') {
      escaped = true;
      continue;
    }
    if (quote) {
      if (ch === quote) quote = null;
      else current += ch;
      continue;
    }
    if (ch === '"' || ch === "'") {
      quote = ch;
      continue;
    }
    if (/\s/.test(ch)) {
      if (current.length > 0) {
        out.push(current);
        current = '';
      }
      continue;
    }
    current += ch;
  }
  if (quote) return [input];
  if (escaped) current += '\\';
  if (current.length > 0) out.push(current);
  return out;
}
