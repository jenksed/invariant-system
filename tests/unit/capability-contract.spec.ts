import { describe, it, expect } from 'vitest';
import { parseCapabilityContract } from '../../src/core/capability-contract';

describe('capability contract parser', () => {
  it('accepts the bundled repository-recon capability.json', async () => {
    const fs = await import('node:fs/promises');
    const path = await import('node:path');
    const raw = JSON.parse(
      await fs.readFile(
        path.join(__dirname, '..', '..', 'src', 'packs', 'repository-recon', 'capability.json'),
        'utf8'
      )
    );
    const contract = parseCapabilityContract(raw);
    expect(contract.id).toBe('repository-recon');
    expect(contract.contract_version).toBe('0.1.0-fixture');
    expect(contract.goal_outcome).toBe('understand-a-repository');
  });

  it('rejects an unknown schema', () => {
    expect(() =>
      parseCapabilityContract({ schema: 'unknown', id: 'x', contract_version: '0' })
    ).toThrow();
  });
});
