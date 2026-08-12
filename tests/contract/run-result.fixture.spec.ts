import { describe, it, expect } from 'vitest';
import path from 'node:path';
import yaml from 'yaml';
import { RunResultEnvelopeV0Schema } from '../../src/core/schemas';

describe('Run Result Envelope fixture', () => {
  it('parses and validates the bundled v0 fixture', async () => {
    const fs = await import('node:fs/promises');
    const raw = await fs.readFile(
      path.join(__dirname, '..', '..', 'fixtures', 'run-result-envelope.v0.yaml'),
      'utf8'
    );
    const obj = yaml.parse(raw);
    const result = RunResultEnvelopeV0Schema.parse(obj);
    expect(result.status).toBe('completed');
    expect(result.evidence.every((e) => e.kind === 'simulated')).toBe(true);
  });
});
