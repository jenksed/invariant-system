/**
 * Connector = Loadout-owned discovery/configuration for an external system.
 *
 * In LOD-01 we have NO effectful connector. The connector we expose is
 * a config-only `repository.local` connector that points at a path on
 * disk. It does NOT execute any effects. Any effectful integration would
 * be a Kiln effect driver, which is out of scope.
 */
import { promises as fs } from 'node:fs';

export type ConnectorConfig = { kind: 'repository.local'; path: string; label?: string };

export async function loadConnectorConfig(repoRoot: string): Promise<ConnectorConfig | null> {
  const configPath = `${repoRoot}/.loadout/connector.json`;
  try {
    const raw = await fs.readFile(configPath, 'utf8');
    return JSON.parse(raw) as ConnectorConfig;
  } catch {
    return null;
  }
}

export function describeConnector(c: ConnectorConfig | null): string {
  if (!c) return '(no connector configured)';
  if (c.kind === 'repository.local') {
    return `repository.local at ${c.path}${c.label ? ` (${c.label})` : ''}`;
  }
  return '(unknown connector)';
}
