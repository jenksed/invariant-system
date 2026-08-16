import { describe, it, expect } from 'vitest';
import path from 'node:path';
import yaml from 'yaml';
import { WorkEnvelopeV0Schema } from '../../src/core/schemas';

describe('Work Envelope fixture', () => {
  it('parses and validates the bundled v0 fixture', async () => {
    const fs = await import('node:fs/promises');
    const raw = await fs.readFile(
      path.join(__dirname, '..', '..', 'fixtures', 'work-envelope.v0.yaml'),
      'utf8'
    );
    const obj = yaml.parse(raw);
    const env = WorkEnvelopeV0Schema.parse(obj);
    expect(env.producer.product).toBe('loadout');
    expect(env.capability.id).toBe('repository-recon');
  });
});
