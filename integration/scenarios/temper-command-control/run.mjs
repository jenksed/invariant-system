import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const [root, repository, baseUrl, wsUrl, readToken, operateToken, configPath] = process.argv.slice(2);
if (![root, repository, baseUrl, wsUrl, readToken, operateToken, configPath].every(Boolean)) {
  throw new Error('usage: run.mjs ROOT REPOSITORY BASE_URL WS_URL READ_TOKEN OPERATE_TOKEN CONFIG_PATH');
}

const connectionModule = await import(
  pathToFileURL(join(root, 'products/temper/dist/src/workbench/connection.js')).href
);
const commandModule = await import(
  pathToFileURL(join(root, 'products/temper/dist/src/workbench/commands.js')).href
);

const { WorkbenchConnection } = connectionModule;
const { CommandExecutor } = commandModule;

let actorId = 'temper-control-integration';
const connection = new WorkbenchConnection({
  repository,
  baseUrl,
  wsUrl,
  readToken,
  operateToken
});
const commands = new CommandExecutor(connection, {
  repository,
  baseUrl,
  wsUrl,
  configPath,
  getActorId: () => actorId,
  setActorId: (value) => {
    actorId = value;
  }
});

function printResult(input, result) {
  process.stdout.write(`\n${input}\n`);
  process.stdout.write(`${result.ok ? 'OK' : 'REJECTED'} ${result.code ?? ''} ${result.title}\n`);
  for (const line of result.lines) process.stdout.write(`  ${line}\n`);
}

async function execute(input) {
  const result = await commands.execute(input);
  printResult(input, result);
  return result;
}

try {
  const opened = await connection.open();
  assert.equal(opened.connection, 'connected', 'WorkbenchConnection must not claim open before real WS handshake');
  assert.equal(opened.repository, repository);

  const initial = await execute('/status');
  assert.equal(initial.ok, true);
  assert.ok(initial.lines.includes('connection: connected'));

  const created = await execute('/new "real slash command canonical session"');
  assert.equal(created.ok, true, created.lines.join('\n'));
  assert.ok(connection.current().sessionId, 'real /new must produce a canonical session_id');
  assert.equal(
    connection.current().sessionQuery?.objective,
    'real slash command canonical session',
    'real /new objective must round-trip through session.query'
  );

  const session = await execute('/session');
  assert.equal(session.ok, true, session.lines.join('\n'));
  assert.ok(session.lines.some((line) => line.startsWith('session_id: ses_')));

  const next = await execute('/next');
  assert.equal(next.ok, true, next.lines.join('\n'));

  const doctor = await execute('/doctor');
  assert.equal(doctor.ok, true, doctor.lines.join('\n'));
  assert.ok(doctor.lines.some((line) => line === 'PASS Kiln connection: connected'));

  const config = await execute('/config set actor_id slash-vertical-operator');
  assert.equal(config.ok, true, config.lines.join('\n'));
  assert.equal(actorId, 'slash-vertical-operator');
  const persisted = JSON.parse(readFileSync(configPath, 'utf8'));
  assert.equal(persisted.actor_id, 'slash-vertical-operator');
  assert.equal(Object.prototype.hasOwnProperty.call(persisted, 'KILN_READ_TOKEN'), false);
  assert.equal(Object.prototype.hasOwnProperty.call(persisted, 'KILN_OPERATE_TOKEN'), false);

  const provider = await execute('/provider minimax');
  assert.equal(provider.ok, false);
  assert.equal(provider.code, 'E_PROVIDER_CONTROL_UNAVAILABLE');

  const acceptWithoutDecision = await execute('/accept');
  assert.equal(acceptWithoutDecision.ok, false);
  assert.equal(acceptWithoutDecision.code, 'E_DECISION_CONTEXT_UNAVAILABLE');

  const reconnected = await execute('/reconnect');
  assert.equal(reconnected.ok, true, reconnected.lines.join('\n'));
  assert.equal(connection.current().connection, 'connected');
  assert.ok(connection.current().sessionId, 'manual reconnect must preserve canonical Session identity');

  // Exercise a real lifecycle mutation only when Kiln advertises it as a
  // valid next action. Temper does not infer lifecycle legality locally.
  const nextText = next.lines.join('\n').toLowerCase();
  if (nextText.includes('cancel')) {
    const cancelled = await execute('/cancel');
    assert.equal(cancelled.ok, true, cancelled.lines.join('\n'));
    assert.ok(
      cancelled.lines.some((line) => line.includes('canonical_confirmation')),
      'successful lifecycle mutation must include canonical confirmation'
    );
  } else {
    process.stdout.write('\n/cancel not executed: canonical /next did not advertise cancel\n');
  }

  const finalStatus = await execute('/status');
  assert.equal(finalStatus.ok, true);

  process.stdout.write('\ntemper slash-command real-daemon vertical: PASS\n');
} finally {
  await connection.stop();
}
