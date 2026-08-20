import assert from 'node:assert/strict';
import test from 'node:test';
import { normalizeSessionQuery } from '../src/workbench/session_query.js';

test('session.query normalization preserves the canonical objective and criteria', () => {
  const result = normalizeSessionQuery({
    session_id: 'ses_0123456789abcdef0123456789abcdef',
    projection_digest: `sha256:${'a'.repeat(64)}`,
    projection: {
      session_revision: 3,
      objective: 'Inspect this repository and propose one safe improvement.',
      criteria: ['operator-submitted intent'],
      run: { state: 'ready' }
    }
  });

  assert.equal(result.objective, 'Inspect this repository and propose one safe improvement.');
  assert.deepEqual(result.criteria, ['operator-submitted intent']);
  assert.equal(result.run_state, 'ready');
});

test('session.query normalization rejects mixed-type criteria', () => {
  const result = normalizeSessionQuery({
    projection: {
      objective: 'Bounded objective',
      criteria: ['valid', 42]
    }
  });

  assert.equal(result.objective, 'Bounded objective');
  assert.equal(result.criteria, undefined);
});
