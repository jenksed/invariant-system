import test from 'node:test';
import assert from 'node:assert/strict';

import {
  commandAvailability,
  commandSpecs,
  formatCommandHelp,
  parseCommand
} from '../src/workbench/commands.js';
import type { WorkbenchProjection } from '../src/workbench/projection.js';

function projection(overrides: Partial<WorkbenchProjection> = {}): WorkbenchProjection {
  return {
    repository: '/tmp/repo',
    repositoryName: 'repo',
    kilnHome: '/tmp/repo/.kiln',
    sessionId: 'ses_0123456789abcdef0123456789abcdef',
    canonicalSessionRevision: 4,
    orphaned: false,
    unknowns: [],
    connection: 'connected',
    builtAt: '2026-08-20T00:00:00Z',
    sessionQuery: {
      session_revision: 4,
      run_state: 'waiting_for_user',
      pending_decision: { id: 'dec_1' },
      references: {
        decision_envelope: {
          plan_ref: { id: 'plan_1', digest: 'sha256:a' },
          patch_ref: { id: 'patch_1', digest: 'sha256:b' },
          result_state_digest: 'sha256:c',
          review_ref: { id: 'review_1', digest: 'sha256:d' }
        }
      }
    },
    ...overrides
  };
}

test('parses canonical command, aliases, and quoted arguments', () => {
  const direct = parseCommand('/new "repair reconnect handling"');
  assert.ok(!('error' in direct));
  assert.equal(direct.spec.id, 'new');
  assert.deepEqual(direct.argv, ['repair reconnect handling']);

  const alias = parseCommand('/proof');
  assert.ok(!('error' in alias));
  assert.equal(alias.spec.id, 'evidence');
});

test('unknown and non-slash input fail closed', () => {
  assert.deepEqual(parseCommand('help'), { error: 'operator commands must begin with /' });
  assert.deepEqual(parseCommand('/nope'), { error: 'unknown command: /nope' });
});

test('session and decision commands become unavailable from canonical state', () => {
  const status = commandSpecs().find((spec) => spec.id === 'status')!;
  const cancel = commandSpecs().find((spec) => spec.id === 'cancel')!;
  const accept = commandSpecs().find((spec) => spec.id === 'accept')!;

  assert.deepEqual(commandAvailability(status, null), { available: true });
  assert.deepEqual(commandAvailability(cancel, projection({ sessionId: null })), {
    available: false,
    reason: 'no canonical Session is open'
  });

  const noDecision = projection({
    sessionQuery: { session_revision: 4, run_state: 'ready' }
  });
  assert.deepEqual(commandAvailability(accept, noDecision), {
    available: false,
    reason: 'no canonical pending decision envelope is available'
  });
});

test('Kiln commands fail unavailable while transport is disconnected', () => {
  const next = commandSpecs().find((spec) => spec.id === 'next')!;
  assert.deepEqual(commandAvailability(next, projection({ connection: 'disconnected' })), {
    available: false,
    reason: 'Kiln is not connected'
  });
});

test('help is generated from the registry and exposes availability', () => {
  const help = formatCommandHelp(projection());
  assert.match(help, /\/graph/);
  assert.match(help, /\/accept/);
  assert.match(help, /available/);
});
