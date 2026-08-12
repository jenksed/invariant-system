import { describe, it, expect } from 'vitest';
import path from 'node:path';
import yaml from 'yaml';
import { QualifiedMethodRecordV0Schema } from '../../src/core/schemas';

describe('QMR fixture', () => {
  it('parses and validates the bundled v0 fixture', async () => {
    const fs = await import('node:fs/promises');
    const raw = await fs.readFile(
      path.join(__dirname, '..', '..', 'fixtures', 'qualified-method-record.v0.yaml'),
      'utf8'
    );
    const obj = yaml.parse(raw);
    const qmr = QualifiedMethodRecordV0Schema.parse(obj);
    expect(qmr.status).toBe('experimental');
    expect(qmr.qualified_for.outcome).toBe('understand-a-repository');
  });
});
