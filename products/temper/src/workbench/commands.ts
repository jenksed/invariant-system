import { existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import type { WorkbenchProjection } from './projection.js';
import {
  TEMPER_CONFIG_KEYS,
  isTemperConfigKey,
  readTemperConfig,
  setTemperConfigValue,
  unsetTemperConfigValue,
  type TemperConfigKey
} from './config.js';

export interface CommandConnection {
  current(): WorkbenchProjection;
  resync(reason?: 'activity' | 'reconnect' | 'resync'): Promise<WorkbenchProjection>;
  reconnect(): Promise<WorkbenchProjection>;
  startSession(intent: string, actorId: string): Promise<WorkbenchProjection>;
  cancelSession(actorId: string): Promise<CommandRpcResult>;
  resumeSession(actorId: string): Promise<CommandRpcResult>;
  nextActions(): Promise<CommandRpcResult>;
  submitHumanDecision(
    decision: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION',
    envelope: {
      plan_ref: { id: string; digest: string };
      patch_ref: { id: string; digest: string };
      result_state_digest: string;
      review_ref?: { id: string; digest: string } | null;
    },
    actorId: string
  ): Promise<CommandRpcResult>;
}

export interface CommandRpcResult {
  ok: boolean;
  result?: Record<string, unknown>;
  errorCode?: string;
  errorReason?: string;
}

export interface CommandRuntimeConfig {
  repository: string;
  baseUrl: string;
  wsUrl: string;
  snapshotDir?: string;
  getActorId: () => string;
  setActorId: (value: string) => void;
  configPath?: string;
  env?: NodeJS.ProcessEnv;
}

export interface CommandResult {
  ok: boolean;
  command: string;
  title: string;
  lines: string[];
  code?: string;
  action?: 'open_diff' | 'quit';
}

export interface CommandDefinition {
  name: string;
  aliases: string[];
  usage: string;
  description: string;
  authority: 'local' | 'kiln:read' | 'kiln:operate';
}

const DEFINITIONS: readonly CommandDefinition[] = [
  { name: 'help', aliases: ['?'], usage: '/help [command]', description: 'show the command registry or one command', authority: 'local' },
  { name: 'status', aliases: [], usage: '/status', description: 'show the current canonical workbench projection', authority: 'kiln:read' },
  { name: 'doctor', aliases: [], usage: '/doctor', description: 'check repository, connection, canonical session, and config health', authority: 'local' },
  { name: 'session', aliases: [], usage: '/session', description: 'resync and show the current canonical Session', authority: 'kiln:read' },
  { name: 'new', aliases: [], usage: '/new <objective>', description: 'start a real Kiln Session', authority: 'kiln:operate' },
  { name: 'next', aliases: [], usage: '/next', description: 'ask Kiln for valid next actions', authority: 'kiln:read' },
  { name: 'resume', aliases: [], usage: '/resume', description: 'resume the active Session through Kiln', authority: 'kiln:operate' },
  { name: 'cancel', aliases: [], usage: '/cancel', description: 'cancel the active Session through Kiln', authority: 'kiln:operate' },
  { name: 'decide', aliases: [], usage: '/decide <accept|reject|revise>', description: 'submit a governed human decision using canonical refs', authority: 'kiln:operate' },
  { name: 'accept', aliases: [], usage: '/accept', description: 'alias for /decide accept', authority: 'kiln:operate' },
  { name: 'reject', aliases: [], usage: '/reject', description: 'alias for /decide reject', authority: 'kiln:operate' },
  { name: 'revise', aliases: [], usage: '/revise', description: 'alias for /decide revise', authority: 'kiln:operate' },
  { name: 'reconnect', aliases: [], usage: '/reconnect', description: 'tear down and re-open the real Kiln connection', authority: 'kiln:read' },
  { name: 'diff', aliases: [], usage: '/diff', description: 'open the bounded repository diff surface', authority: 'local' },
  { name: 'config', aliases: [], usage: '/config [show|get|set|unset|sources] ...', description: 'read or persist non-secret Temper configuration', authority: 'local' },
  { name: 'providers', aliases: [], usage: '/providers', description: 'report provider-control availability at the Workbench boundary', authority: 'local' },
  { name: 'provider', aliases: [], usage: '/provider <name>', description: 'select a provider only when a real Kiln provider-control RPC exists', authority: 'kiln:operate' },
  { name: 'models', aliases: [], usage: '/models', description: 'report model-control availability at the Workbench boundary', authority: 'local' },
  { name: 'model', aliases: [], usage: '/model <name>', description: 'select a model only when a real Kiln provider-control RPC exists', authority: 'kiln:operate' },
  { name: 'quit', aliases: ['exit'], usage: '/quit', description: 'cleanly close Temper', authority: 'local' }
] as const;

export function commandDefinitions(): readonly CommandDefinition[] {
  return DEFINITIONS;
}

export function commandSuggestions(prefix: string): string[] {
  const normalized = prefix.trim().replace(/^\//, '').toLowerCase();
  return DEFINITIONS
    .filter((definition) => normalized.length === 0 || definition.name.startsWith(normalized) || definition.aliases.some((alias) => alias.startsWith(normalized)))
    .map((definition) => `${definition.usage} — ${definition.description}`)
    .slice(0, 10);
}

export function parseCommandLine(input: string): { ok: true; name: string; args: string[] } | { ok: false; reason: string } {
  const source = input.trim();
  if (!source.startsWith('/')) return { ok: false, reason: 'commands must begin with /' };
  const tokens: string[] = [];
  let token = '';
  let quote: '"' | "'" | null = null;
  let escaped = false;
  for (const char of source.slice(1)) {
    if (escaped) {
      token += char;
      escaped = false;
      continue;
    }
    if (char === '\\') {
      escaped = true;
      continue;
    }
    if (quote) {
      if (char === quote) quote = null;
      else token += char;
      continue;
    }
    if (char === '"' || char === "'") {
      quote = char;
      continue;
    }
    if (/\s/.test(char)) {
      if (token.length > 0) {
        tokens.push(token);
        token = '';
      }
      continue;
    }
    token += char;
  }
  if (escaped) token += '\\';
  if (quote) return { ok: false, reason: 'unterminated quote' };
  if (token.length > 0) tokens.push(token);
  const name = (tokens.shift() ?? '').toLowerCase();
  if (name.length === 0) return { ok: false, reason: 'missing command name' };
  return { ok: true, name, args: tokens };
}

export class CommandExecutor {
  constructor(
    private readonly connection: CommandConnection,
    private readonly runtimeConfig: CommandRuntimeConfig
  ) {}

  async execute(input: string): Promise<CommandResult> {
    const parsed = parseCommandLine(input);
    if (!parsed.ok) return failure(input, 'E_COMMAND_PARSE', parsed.reason);
    const definition = lookupDefinition(parsed.name);
    if (!definition) return failure(parsed.name, 'E_COMMAND_UNKNOWN', `unknown command /${parsed.name}; use /help`);
    const name = definition.name;
    try {
      switch (name) {
        case 'help': return this.help(parsed.args);
        case 'status': return this.status(false);
        case 'doctor': return this.doctor();
        case 'session': return this.status(true);
        case 'new': return this.start(parsed.args);
        case 'next': return this.next();
        case 'resume': return this.sessionMutation('resume');
        case 'cancel': return this.sessionMutation('cancel');
        case 'decide': return this.decide(parsed.args[0]);
        case 'accept': return this.decide('accept');
        case 'reject': return this.decide('reject');
        case 'revise': return this.decide('revise');
        case 'reconnect': return this.reconnect();
        case 'diff': return success('diff', 'Repository diff', ['Opening bounded git diff surface.'], 'open_diff');
        case 'config': return this.config(parsed.args);
        case 'providers': return providerBoundary('providers');
        case 'provider': return providerUnavailable('provider');
        case 'models': return providerBoundary('models');
        case 'model': return providerUnavailable('model');
        case 'quit': return success('quit', 'Quit', ['Closing Temper.'], 'quit');
        default: return failure(name, 'E_COMMAND_UNKNOWN', `unknown command /${name}`);
      }
    } catch (err) {
      return failure(name, 'E_COMMAND_FAILED', (err as Error).message);
    }
  }

  private help(args: string[]): CommandResult {
    const requested = args[0]?.replace(/^\//, '').toLowerCase();
    if (requested) {
      const definition = lookupDefinition(requested);
      if (!definition) return failure('help', 'E_COMMAND_UNKNOWN', `unknown command /${requested}`);
      return success('help', definition.usage, [definition.description, `authority: ${definition.authority}`, `aliases: ${definition.aliases.length > 0 ? definition.aliases.map((a) => `/${a}`).join(', ') : 'none'}`]);
    }
    return success('help', 'Temper commands', DEFINITIONS.map((definition) => `${definition.usage.padEnd(32)} ${definition.description}`));
  }

  private async status(forceResync: boolean): Promise<CommandResult> {
    const projection = forceResync ? await this.connection.resync('resync') : this.connection.current();
    const query = projection.sessionQuery;
    return success(forceResync ? 'session' : 'status', forceResync ? 'Canonical Session' : 'Workbench status', [
      `connection: ${projection.connection}`,
      `repository: ${projection.repository}`,
      `session_id: ${projection.sessionId ?? 'none'}`,
      `session_revision: ${query?.session_revision ?? projection.canonicalSessionRevision ?? 'unknown'}`,
      `session_state: ${query?.session_state ?? 'unknown'}`,
      `run_state: ${query?.run_state ?? 'unknown'}`,
      `workflow_step: ${query?.workflow_step ?? 'unknown'}`,
      `verification: ${query?.verification_status ?? 'unknown'}`,
      `review: ${query?.review_status ?? 'unknown'}`,
      `human: ${query?.human_status ?? 'unknown'}`,
      `pending_decision: ${query?.pending_decision == null ? 'no' : 'yes'}`,
      `last_error: ${projection.lastError ?? 'none'}`
    ]);
  }

  private doctor(): CommandResult {
    const projection = this.connection.current();
    const config = readTemperConfig(this.runtimeConfig.configPath);
    const lines: string[] = [];
    lines.push(`${existsSync(this.runtimeConfig.repository) ? 'PASS' : 'FAIL'} repository exists: ${this.runtimeConfig.repository}`);
    lines.push(`${projection.connection === 'connected' ? 'PASS' : 'FAIL'} Kiln connection: ${projection.connection}`);
    lines.push(`${projection.lastError ? 'FAIL' : 'PASS'} canonical projection: ${projection.lastError ?? 'no reported error'}`);
    lines.push(`${config.error ? 'FAIL' : 'PASS'} config file: ${config.error ?? config.path}`);
    try {
      const root = execFileSync('git', ['-C', this.runtimeConfig.repository, 'rev-parse', '--show-toplevel'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
      lines.push(`PASS git worktree: ${root}`);
    } catch (err) {
      lines.push(`FAIL git worktree: ${(err as Error).message}`);
    }
    lines.push('INFO secrets: KILN_READ_TOKEN/KILN_OPERATE_TOKEN are launch-only and are never persisted by /config');
    const ok = lines.every((line) => !line.startsWith('FAIL'));
    return { ok, command: 'doctor', title: ok ? 'Doctor: PASS' : 'Doctor: ATTENTION', lines, ...(ok ? {} : { code: 'E_DOCTOR_FAILED' }) };
  }

  private async start(args: string[]): Promise<CommandResult> {
    const objective = args.join(' ').trim();
    if (!objective) return failure('new', 'E_COMMAND_ARGUMENT', 'usage: /new <objective>');
    const projection = await this.connection.startSession(objective, this.runtimeConfig.getActorId());
    return success('new', 'Session started', [`session_id: ${projection.sessionId ?? 'unknown'}`, `objective: ${objective}`, `actor_id: ${this.runtimeConfig.getActorId()}`]);
  }

  private async next(): Promise<CommandResult> {
    const result = await this.connection.nextActions();
    if (!result.ok) return rpcFailure('next', result);
    return success('next', 'Valid next actions', formatValue(result.result ?? {}));
  }

  private async sessionMutation(kind: 'resume' | 'cancel'): Promise<CommandResult> {
    const result = kind === 'resume'
      ? await this.connection.resumeSession(this.runtimeConfig.getActorId())
      : await this.connection.cancelSession(this.runtimeConfig.getActorId());
    if (!result.ok) return rpcFailure(kind, result);
    await this.connection.resync('resync');
    return success(kind, `Session ${kind} accepted`, formatValue(result.result ?? {}));
  }

  private async decide(raw: string | undefined): Promise<CommandResult> {
    const normalized = raw?.toLowerCase();
    const decision = normalized === 'accept'
      ? 'ACCEPT'
      : normalized === 'reject'
        ? 'REJECT'
        : normalized === 'revise' || normalized === 'request_revision'
          ? 'REQUEST_REVISION'
          : null;
    if (!decision) return failure('decide', 'E_COMMAND_ARGUMENT', 'usage: /decide <accept|reject|revise>');
    const projection = this.connection.current();
    const envelope = decisionEnvelope(projection);
    if (!envelope) {
      return failure('decide', 'E_DECISION_CONTEXT_UNAVAILABLE', 'no canonical pending decision envelope is currently recorded');
    }
    const result = await this.connection.submitHumanDecision(decision, envelope, this.runtimeConfig.getActorId());
    if (!result.ok) return rpcFailure('decide', result);
    await this.connection.resync('resync');
    return success('decide', `Human decision ${decision}`, formatValue(result.result ?? {}));
  }

  private async reconnect(): Promise<CommandResult> {
    const projection = await this.connection.reconnect();
    return success('reconnect', 'Kiln reconnected', [`connection: ${projection.connection}`, `session_id: ${projection.sessionId ?? 'none'}`, `session_revision: ${projection.sessionQuery?.session_revision ?? projection.canonicalSessionRevision ?? 'unknown'}`]);
  }

  private config(args: string[]): CommandResult {
    const verb = (args[0] ?? 'show').toLowerCase();
    const read = readTemperConfig(this.runtimeConfig.configPath);
    if (read.error) return failure('config', 'E_CONFIG_READ_FAILED', read.error);
    if (verb === 'show') {
      return success('config', 'Persisted Temper config', [`path: ${read.path}`, ...TEMPER_CONFIG_KEYS.map((key) => `${key}: ${read.config[key] ?? '(unset)'}`), 'secrets: never persisted']);
    }
    if (verb === 'sources') {
      const env = this.runtimeConfig.env ?? process.env;
      return success('config', 'Effective configuration sources', [
        `actor_id: ${this.runtimeConfig.getActorId()} (CLI/env/config/default resolution)`,
        `kiln_url: ${this.runtimeConfig.baseUrl} (${env.KILN_URL ? 'env/CLI' : read.config.kiln_url ? 'config' : 'CLI/default'})`,
        `kiln_ws_url: ${this.runtimeConfig.wsUrl} (${env.KILN_WS_URL ? 'env/CLI' : read.config.kiln_ws_url ? 'config' : 'CLI/default'})`,
        `snapshot_dir: ${this.runtimeConfig.snapshotDir ?? '(unset)'}`,
        `config_file: ${read.path}`,
        'KILN_READ_TOKEN: launch-only secret',
        'KILN_OPERATE_TOKEN: launch-only secret'
      ]);
    }
    const key = args[1];
    if (!key || !isTemperConfigKey(key)) return failure('config', 'E_CONFIG_KEY_UNKNOWN', `config key must be one of: ${TEMPER_CONFIG_KEYS.join(', ')}`);
    if (verb === 'get') {
      return success('config', `Config ${key}`, [`persisted: ${read.config[key] ?? '(unset)'}`, `effective: ${effectiveValue(key, this.runtimeConfig) ?? '(unset)'}`]);
    }
    if (verb === 'set') {
      const value = args.slice(2).join(' ');
      const result = setTemperConfigValue(key, value, read.path);
      if (!result.ok) return failure('config', result.code, result.reason);
      if (key === 'actor_id') this.runtimeConfig.setActorId(result.value);
      const scope = key === 'actor_id' ? 'applied now and persisted' : 'persisted; applies on next Temper launch';
      return success('config', `Config updated: ${key}`, [`value: ${result.value}`, `path: ${result.path}`, scope]);
    }
    if (verb === 'unset') {
      const result = unsetTemperConfigValue(key, read.path);
      if (!result.ok) return failure('config', result.code, result.reason);
      return success('config', `Config unset: ${key}`, [`path: ${result.path}`, key === 'actor_id' ? 'current process keeps its already-resolved actor_id; next launch will re-resolve' : 'next launch will re-resolve this value']);
    }
    return failure('config', 'E_COMMAND_ARGUMENT', 'usage: /config [show|get <key>|set <key> <value>|unset <key>|sources]');
  }
}

function effectiveValue(key: TemperConfigKey, config: CommandRuntimeConfig): string | undefined {
  if (key === 'actor_id') return config.getActorId();
  if (key === 'kiln_url') return config.baseUrl;
  if (key === 'kiln_ws_url') return config.wsUrl;
  return config.snapshotDir;
}

function lookupDefinition(name: string): CommandDefinition | undefined {
  return DEFINITIONS.find((definition) => definition.name === name || definition.aliases.includes(name));
}

function decisionEnvelope(projection: WorkbenchProjection): {
  plan_ref: { id: string; digest: string };
  patch_ref: { id: string; digest: string };
  result_state_digest: string;
  review_ref?: { id: string; digest: string } | null;
} | null {
  const envelope = projection.sessionQuery?.references?.decision_envelope;
  if (!envelope || projection.sessionQuery?.pending_decision == null) return null;
  return {
    plan_ref: envelope.plan_ref,
    patch_ref: envelope.patch_ref,
    result_state_digest: envelope.result_state_digest,
    ...(envelope.review_ref ? { review_ref: envelope.review_ref } : {})
  };
}

function providerBoundary(command: 'providers' | 'models'): CommandResult {
  return success(command, 'Provider control boundary', [
    'Workbench provider/model control is not exposed by the current Kiln RPC router.',
    'Temper will not invent a selection or claim that a UI preference controls execution.',
    'Existing provider adapters remain outside this Workbench control surface until a bounded registry/selection RPC is added.'
  ]);
}

function providerUnavailable(command: 'provider' | 'model'): CommandResult {
  return failure(command, 'E_PROVIDER_CONTROL_UNAVAILABLE', 'no bounded Kiln provider/model selection RPC is registered; selection unchanged');
}

function formatValue(value: unknown, prefix = ''): string[] {
  if (value == null) return [`${prefix}${String(value)}`];
  if (Array.isArray(value)) {
    if (value.length === 0) return [`${prefix}[]`];
    return value.flatMap((item, index) => formatValue(item, `${prefix}[${index}] `));
  }
  if (typeof value === 'object') {
    const entries = Object.entries(value as Record<string, unknown>);
    if (entries.length === 0) return [`${prefix}{}`];
    return entries.flatMap(([key, item]) => {
      if (item !== null && typeof item === 'object') return formatValue(item, `${prefix}${key}.`);
      return [`${prefix}${key}: ${String(item)}`];
    });
  }
  return [`${prefix}${String(value)}`];
}

function success(command: string, title: string, lines: string[], action?: CommandResult['action']): CommandResult {
  return { ok: true, command, title, lines, ...(action ? { action } : {}) };
}

function failure(command: string, code: string, reason: string): CommandResult {
  return { ok: false, command, title: `${command}: rejected`, lines: [reason], code };
}

function rpcFailure(command: string, result: CommandRpcResult): CommandResult {
  return failure(command, result.errorCode ?? 'E_RPC_FAILED', result.errorReason ?? 'Kiln rejected the operation');
}
