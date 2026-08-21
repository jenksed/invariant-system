import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

export interface TemperConfig {
  actor_id?: string;
  kiln_url?: string;
  kiln_ws_url?: string;
  snapshot_dir?: string;
}

export type TemperConfigKey = keyof TemperConfig;

export const TEMPER_CONFIG_KEYS: readonly TemperConfigKey[] = [
  'actor_id',
  'kiln_url',
  'kiln_ws_url',
  'snapshot_dir'
] as const;

export interface ConfigReadResult {
  path: string;
  config: TemperConfig;
  error?: string;
}

export function resolveTemperConfigPath(env: NodeJS.ProcessEnv = process.env): string {
  const base = env.XDG_CONFIG_HOME && env.XDG_CONFIG_HOME.trim().length > 0
    ? env.XDG_CONFIG_HOME
    : join(homedir(), '.config');
  return join(base, 'invariant', 'temper.json');
}

export function readTemperConfig(path = resolveTemperConfigPath()): ConfigReadResult {
  if (!existsSync(path)) return { path, config: {} };
  try {
    const raw = JSON.parse(readFileSync(path, 'utf8')) as unknown;
    if (!isRecord(raw)) return { path, config: {}, error: 'configuration root must be a JSON object' };
    const config: TemperConfig = {};
    for (const key of TEMPER_CONFIG_KEYS) {
      const value = raw[key];
      if (typeof value !== 'string') continue;
      const validation = validateTemperConfigValue(key, value);
      if (validation.ok) config[key] = validation.value;
    }
    return { path, config };
  } catch (err) {
    return { path, config: {}, error: (err as Error).message };
  }
}

export function writeTemperConfig(config: TemperConfig, path = resolveTemperConfigPath()): void {
  mkdirSync(dirname(path), { recursive: true });
  const tmp = `${path}.tmp-${process.pid}`;
  writeFileSync(tmp, `${JSON.stringify(config, null, 2)}\n`, { encoding: 'utf8', mode: 0o600 });
  renameSync(tmp, path);
}

export function setTemperConfigValue(
  key: string,
  value: string,
  path = resolveTemperConfigPath()
): { ok: true; path: string; config: TemperConfig; value: string } | { ok: false; code: string; reason: string } {
  if (!isTemperConfigKey(key)) {
    return { ok: false, code: 'E_CONFIG_KEY_UNKNOWN', reason: `unknown config key ${key}` };
  }
  const validation = validateTemperConfigValue(key, value);
  if (!validation.ok) return validation;
  const current = readTemperConfig(path);
  if (current.error) {
    return { ok: false, code: 'E_CONFIG_READ_FAILED', reason: current.error };
  }
  const config = { ...current.config, [key]: validation.value };
  try {
    writeTemperConfig(config, path);
    return { ok: true, path, config, value: validation.value };
  } catch (err) {
    return { ok: false, code: 'E_CONFIG_WRITE_FAILED', reason: (err as Error).message };
  }
}

export function unsetTemperConfigValue(
  key: string,
  path = resolveTemperConfigPath()
): { ok: true; path: string; config: TemperConfig } | { ok: false; code: string; reason: string } {
  if (!isTemperConfigKey(key)) {
    return { ok: false, code: 'E_CONFIG_KEY_UNKNOWN', reason: `unknown config key ${key}` };
  }
  const current = readTemperConfig(path);
  if (current.error) {
    return { ok: false, code: 'E_CONFIG_READ_FAILED', reason: current.error };
  }
  const config = { ...current.config };
  delete config[key];
  try {
    writeTemperConfig(config, path);
    return { ok: true, path, config };
  } catch (err) {
    return { ok: false, code: 'E_CONFIG_WRITE_FAILED', reason: (err as Error).message };
  }
}

export function isTemperConfigKey(value: string): value is TemperConfigKey {
  return (TEMPER_CONFIG_KEYS as readonly string[]).includes(value);
}

function validateTemperConfigValue(
  key: TemperConfigKey,
  raw: string
): { ok: true; value: string } | { ok: false; code: string; reason: string } {
  const value = raw.trim();
  if (value.length === 0) {
    return { ok: false, code: 'E_CONFIG_VALUE_INVALID', reason: `${key} must not be empty` };
  }
  if (key === 'actor_id' && value.length > 128) {
    return { ok: false, code: 'E_CONFIG_VALUE_INVALID', reason: 'actor_id must be <= 128 characters' };
  }
  if (key === 'kiln_url') {
    try {
      const parsed = new URL(value);
      if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') throw new Error('invalid scheme');
    } catch {
      return { ok: false, code: 'E_CONFIG_VALUE_INVALID', reason: 'kiln_url must be an http(s) URL' };
    }
  }
  if (key === 'kiln_ws_url') {
    try {
      const parsed = new URL(value);
      if (parsed.protocol !== 'ws:' && parsed.protocol !== 'wss:') throw new Error('invalid scheme');
    } catch {
      return { ok: false, code: 'E_CONFIG_VALUE_INVALID', reason: 'kiln_ws_url must be a ws(s) URL' };
    }
  }
  return { ok: true, value };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
