import { describe, it, expect } from 'vitest';
import path from 'node:path';
import { resolveCapability, loadQmrFixture } from '../../src/index';

describe('skill swap', () => {
  it('keeps the capability contract stable when the QMR fixture is substituted', async () => {
    const cap = await resolveCapability(
      path.join(__dirname, '..', '..', 'src', 'packs', 'repository-recon')
    );
    const originalContractVersion = cap.contract.contract_version;

    const altFixturePath = path.join(
      __dirname,
      '..',
      '..',
      'fixtures',
      'qualified-method-record.v0.alt.yaml'
    );
    const altQmr = await loadQmrFixture(altFixturePath, '.');
    expect(altQmr.schema).toBe('engineering-system/qualified-method-record/v0');

    // Substitute in-memory: capability contract version is unchanged.
    cap.skill.qmrFixturePath = altFixturePath;
    expect(cap.contract.contract_version).toBe(originalContractVersion);
  });
});
