/**
 * Real Kiln boundary: spawns the Kiln CLI and parses the canonical
 * `engineering-system/run-result-envelope/v0` it returns.
 *
 * Boundary contract (Wave 3 Phase 2):
 *   - Spawn the Kiln CLI as a child process with an EXACT argv (no shell).
 *   - Serialize the Work Envelope to a tempfile so Kiln can read it.
 *   - Pass `--kiln-home`, `--actor-id`, `--work-envelope`, `--format json`.
 *   - Capture stdout (the JSON envelope) and stderr.
 *   - Validate the parsed envelope against `RunResultEnvelopeV0Schema`,
 *     augmented with a `simulated: NEVER` invariant: a real Kiln run
 *     must NOT carry `simulated: true` labels.
 *   - Return the parsed envelope, the raw JSON text, and the run_id
 *     bound by Kiln.
 *
 * Failure behavior (fail closed):
 *   - The Kiln binary is missing or fails to spawn => KilnUnavailableError.
 *   - The Kiln binary exits non-zero with a parseable error payload =>
 *     KilnSupervisionError carrying the structured error.
 *   - The Kiln binary exits non-zero with unparseable output =>
 *     KilnMalformedResponseError (no envelope shape).
 *   - The Kiln binary exits zero with unparseable JSON =>
 *     KilnMalformedResponseError.
 *   - The Kiln binary exits zero with parseable JSON but a misleading
 *     `simulated: true` label => KilnFakeLabelError (Loadout cannot
 *     trust a result that claims to be real but is labeled simulated).
 *
 * Procedure observation flow:
 *   - Wave 3 supervision accepts the procedure completion through the
 *     Work Envelope itself: the supervisor's observation_completion is
 *     currently defaulted to `completed` because Loadout's procedure is
 *     deterministic and read-only. The single-round-trip CLI call
 *     `mix kiln supervise --work-envelope <tempfile>` is therefore the
 *     smallest correct interface: Kiln binds the durable Run identity,
 *     observes the repository, decides authority, and returns the
 *     canonical Run Result Envelope in one process. Loadout invokes the
 *     procedure BEFORE the Kiln call (because the procedure produces
 *     the `repository_recon` summary that is INPUT to the user-facing
 *     presentation). The Kiln-driven envelope is the canonical runtime
 *     facts; the Loadout procedure observation is supplementary.
 *
 *   - This module does NOT spawn the procedure. The procedure is invoked
 *     by the CLI ONLY when the Plan's execution_boundary is `kiln` AND
 *     the Run Result Envelope from Kiln shows `authority.granted.length > 0`.
 *     A sentinel/invocation-count test proves the procedure is NOT
 *     invoked when Kiln denies authority.
 */
import { spawn } from 'node:child_process';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { RunResultEnvelopeV0Schema } from './schemas';
import type { WorkEnvelopeV0, RunResultEnvelopeV0, VerificationChangeV0 } from './schemas';

/**
 * Errors raised by the KilnDriver. Each has a stable `name` and a
 * human-readable `message`. Callers can switch on `instanceof` for
 * fail-closed behavior; no class carries enough information to silently
 * manufacture a successful outcome.
 */
export class KilnError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'KilnError';
  }
}

export class KilnUnavailableError extends KilnError {
  override readonly cause?: Error;
  constructor(message: string, cause?: Error) {
    super(message);
    this.name = 'KilnUnavailableError';
    if (cause !== undefined) {
      this.cause = cause;
    }
  }
}

export class KilnMalformedResponseError extends KilnError {
  readonly reason: string;
  readonly rawOutput: string;
  constructor(reason: string, rawOutput: string) {
    super(`Kiln returned a malformed response: ${reason}`);
    this.name = 'KilnMalformedResponseError';
    this.reason = reason;
    this.rawOutput = rawOutput;
  }
}

export class KilnFakeLabelError extends KilnError {
  constructor(message: string) {
    super(message);
    this.name = 'KilnFakeLabelError';
  }
}

export class KilnSupervisionError extends KilnError {
  readonly exitCode: number;
  readonly stderr: string;
  readonly structured?: unknown;
  constructor(exitCode: number, stderr: string, structured?: unknown) {
    super(
      `Kiln supervision exited with code ${exitCode}: ${
        structured
          ? typeof structured === 'object' && structured !== null && 'message' in structured
            ? String((structured as { message: unknown }).message)
            : stderr.slice(0, 200)
          : stderr.slice(0, 200)
      }`
    );
    this.name = 'KilnSupervisionError';
    this.exitCode = exitCode;
    this.stderr = stderr;
    this.structured = structured;
  }
}

export interface KilnDriverOptions {
  /**
   * The Kiln CLI executable. Defaults to `mix` (the source-development
   * entry point). Power users may override with an explicit path to a
   * compiled Kiln release.
   */
  kilnBinary?: string;
  /**
   * The Kiln home directory. Optional; when omitted, Kiln's own defaults
   * apply (KILN_HOME env var or the canonical default).
   */
  kilnHome?: string;
  /**
   * The actor id to pass to Kiln. Optional; defaults to `loadout` when
   * omitted. Real production should pass a stable identifier.
   */
  actorId?: string;
  /**
   * The Git binary to use for repository observation. Defaults to `git`.
   * Honors the Kiln CLI's own default.
   */
  gitBinary?: string;
  /**
   * Timeout in milliseconds for the Kiln subprocess. Defaults to 60000.
   */
  timeoutMs?: number;
  /**
   * Directory for the tempfile written for the Work Envelope. Defaults
   * to the OS temp directory. The driver creates a uniquely-named file
   * in this directory and removes it after the spawn returns.
   */
  tempDir?: string;
  /**
   * The PATH environment variable passed to the spawned process.
   * Defaults to inheriting the parent's PATH (so `mix` can be found).
   * Pass an explicit value to fully control subprocess environment.
   */
  envPath?: string;
  /** Frozen Plan v1 projection. Required when the Work Envelope capability is verify-change. */
  verificationChange?: VerificationChangeV0;
}

export interface KilnDriverResult {
  envelope: RunResultEnvelopeV0;
  /**
   * The raw JSON text emitted by Kiln on stdout. The CLI writes this
   * verbatim into the run record so a future reviewer can re-validate
   * the envelope shape.
   */
  rawJson: string;
  /**
   * The temporary file path holding the Work Envelope during the spawn.
   * Useful for diagnostic logging; the file is removed before this
   * method returns.
   */
  envelopeTempfilePath: string;
  verificationTempfilePath?: string;
  /**
   * Whether the procedure must run based on the authority decision. True
   * iff any requested authority capability was granted by Kiln. The CLI
   * uses this to gate the procedure invocation.
   */
  procedureShouldRun: boolean;
  /**
   * The exit code of the Kiln subprocess. Always 0 on the success path.
   */
  exitCode: number;
}

/**
 * The fixed CLI entry. The exact argv shape is part of the Wave 3
 * transport boundary:
 *
 *   mix kiln supervise \
 *     --work-envelope <tempfile> \
 *     --format json \
 *     [--kiln-home <path>] \
 *     [--actor-id <id>] \
 *     [--git <path>]
 *
 * No shell, no shell metacharacters, no pipes. The argv array is the
 * only path from Loadout to Kiln.
 */
const KILN_CLI = 'mix';
const KILN_TASK = 'kiln';
const KILN_COMMAND = 'supervise';
const KILN_FLAG_WORK_ENVELOPE = '--work-envelope';
const KILN_FLAG_VERIFICATION_CHANGE = '--verification-change';
const KILN_FLAG_FORMAT = '--format';
const KILN_FORMAT_JSON = 'json';
const KILN_FLAG_KILN_HOME = '--kiln-home';
const KILN_FLAG_ACTOR_ID = '--actor-id';
const KILN_FLAG_GIT = '--git';
const DEFAULT_TIMEOUT_MS = 60_000;
const DEFAULT_ACTOR_ID = 'loadout';

/**
 * Submit a Work Envelope to the real Kiln supervision boundary.
 *
 * Spawns the Kiln CLI with an exact argv, captures stdout, validates the
 * returned envelope, and returns the parsed canonical result. Throws on
 * every failure mode (see the error class definitions above). Never
 * silently substitutes a fake Kiln result.
 */
export async function submitWorkEnvelopeToKiln(
  envelope: WorkEnvelopeV0,
  options: KilnDriverOptions = {}
): Promise<KilnDriverResult> {
  const envJson = JSON.stringify(envelope);
  const tempDir = options.tempDir ?? os.tmpdir();
  const envelopeTempfilePath = path.join(
    tempDir,
    `loadout-work-envelope-${process.pid}-${Date.now()}-${Math.random()
      .toString(36)
      .slice(2, 10)}.json`
  );
  const verificationTempfilePath = options.verificationChange
    ? path.join(
        tempDir,
        `loadout-verification-change-${process.pid}-${Date.now()}-${Math.random()
          .toString(36)
          .slice(2, 10)}.json`
      )
    : undefined;
  // Serialize envelope to the tempfile BEFORE spawn so a partial file
  // never reaches Kiln. utf8 JSON encoding is exactly what Kiln expects.
  await fs.writeFile(envelopeTempfilePath, envJson, 'utf8');
  if (verificationTempfilePath && options.verificationChange) {
    await fs.writeFile(
      verificationTempfilePath,
      JSON.stringify(options.verificationChange),
      'utf8'
    );
  }

  // Build the exact argv. argv[0] is the Kiln CLI executable; by
  // default it is `mix` (the source-development entry point). Power
  // users may override with an explicit path to a packaged release.
  const cli = options.kilnBinary ?? KILN_CLI;
  const argv: string[] = [
    cli,
    KILN_TASK,
    KILN_COMMAND,
    KILN_FLAG_WORK_ENVELOPE,
    envelopeTempfilePath,
    KILN_FLAG_FORMAT,
    KILN_FORMAT_JSON
  ];
  if (verificationTempfilePath) {
    argv.push(KILN_FLAG_VERIFICATION_CHANGE, verificationTempfilePath);
  }
  if (options.kilnHome) {
    argv.push(KILN_FLAG_KILN_HOME, options.kilnHome);
  }
  argv.push(KILN_FLAG_ACTOR_ID, options.actorId ?? DEFAULT_ACTOR_ID);
  if (options.gitBinary) {
    argv.push(KILN_FLAG_GIT, options.gitBinary);
  }

  const env: NodeJS.ProcessEnv = { ...process.env };
  if (options.envPath !== undefined) {
    env.PATH = options.envPath;
  }

  const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;

  let stdout = '';
  let stderr = '';
  let exitCode = -1;

  try {
    ({ stdout, stderr, exitCode } = await runKilnSubprocess(argv, env, timeoutMs));
  } catch (e) {
    // Always remove the tempfile, even on spawn failure.
    await safeUnlink(envelopeTempfilePath);
    if (verificationTempfilePath) await safeUnlink(verificationTempfilePath);
    if (e instanceof KilnUnavailableError) {
      throw e;
    }
    throw new KilnUnavailableError(`Failed to spawn Kiln CLI: ${(e as Error).message}`, e as Error);
  }

  // Always remove the tempfile.
  await safeUnlink(envelopeTempfilePath);
  if (verificationTempfilePath) await safeUnlink(verificationTempfilePath);

  if (exitCode !== 0) {
    // Try to parse the structured error output. Kiln's CLI emits a
    // JSON envelope even on failure when --format json is set.
    let structured: unknown;
    try {
      structured = JSON.parse(stdout);
    } catch {
      structured = undefined;
    }
    if (structured && typeof structured === 'object') {
      throw new KilnSupervisionError(exitCode, stderr, structured);
    }
    throw new KilnSupervisionError(exitCode, stderr);
  }

  // Source-development `mix` may emit a one-time, mechanically-recognizable
  // compile prelude before the CLI JSON. Strip only those exact lines; any
  // other stdout noise remains a fail-closed malformed response.
  const canonicalJson = extractCanonicalKilnJson(stdout);

  // Parse the canonical envelope.
  let parsed: unknown;
  try {
    parsed = JSON.parse(canonicalJson);
  } catch (e) {
    throw new KilnMalformedResponseError(
      `Kiln stdout is not valid JSON: ${(e as Error).message}`,
      stdout
    );
  }

  // Validate the envelope shape against the v0 schema.
  let envelopeShape;
  try {
    envelopeShape = RunResultEnvelopeV0Schema.parse(parsed);
  } catch (e) {
    throw new KilnMalformedResponseError(
      `Kiln envelope failed schema validation: ${(e as Error).message}`,
      canonicalJson
    );
  }

  // Truthful semantic claim: a real Kiln run must NEVER carry a
  // misleading simulated label. The RunResultEnvelopeV0Schema allows
  // `simulated` to be absent or undefined; we explicitly reject the
  // case where Kiln emits `simulated: true` because that would be a
  // contradiction (Kiln cannot label its own durable run as simulated).
  const result = parsed as Record<string, unknown>;
  if (result.simulated !== undefined && result.simulated !== null) {
    throw new KilnFakeLabelError(
      `Kiln envelope carries a 'simulated' label (${JSON.stringify(result.simulated)}); ` +
        `a real Kiln supervision run must not carry a simulated label. ` +
        `Either Kiln emitted the wrong envelope, or this boundary was misconfigured.`
    );
  }

  // The envelope must report its work_id binding back to the producer.
  if (envelopeShape.work_id !== envelope.work_id) {
    throw new KilnMalformedResponseError(
      `Kiln envelope work_id (${envelopeShape.work_id}) does not match submitted work_id (${envelope.work_id}); refusing to bind a mismatched Run.`,
      canonicalJson
    );
  }

  // Determine whether the procedure should run: only when ANY requested
  // authority capability was actually granted by Kiln.
  const procedureShouldRun = envelopeShape.authority.granted.length > 0;

  return {
    envelope: envelopeShape,
    rawJson: canonicalJson,
    envelopeTempfilePath,
    ...(verificationTempfilePath ? { verificationTempfilePath } : {}),
    procedureShouldRun,
    exitCode
  };
}

function extractCanonicalKilnJson(stdout: string): string {
  const trimmed = stdout.trim();
  try {
    JSON.parse(trimmed);
    return trimmed;
  } catch {
    // Continue only for the exact source-launch compile prelude emitted by Mix.
  }

  const lines = trimmed.split(/\r?\n/);
  const jsonIndex = lines.findIndex((line) => line.startsWith('{'));
  if (jsonIndex <= 0) return trimmed;
  const prelude = lines.slice(0, jsonIndex);
  const allowedPrelude = prelude.every(
    (line) => /^Compiling \d+ files? \(.+\)$/.test(line) || line === 'Generated kiln app'
  );
  if (!allowedPrelude) return trimmed;
  return lines.slice(jsonIndex).join('\n').trim();
}

/**
 * Spawn the Kiln subprocess and capture stdout/stderr/exit code.
 *
 * Uses Node's child_process.spawn with an exact argv (no shell). The
 * timeout is enforced via a watchdog timer that SIGTERMs the child and
 * rejects with KilnUnavailableError. The child process is detached
 * from the parent's stdio so the parent's terminal is not affected.
 */
function runKilnSubprocess(
  argv: string[],
  env: NodeJS.ProcessEnv,
  timeoutMs: number
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  return new Promise((resolve, reject) => {
    const child = spawn(argv[0], argv.slice(1), {
      env,
      shell: false,
      stdio: ['ignore', 'pipe', 'pipe']
    });

    let stdout = '';
    let stderr = '';
    let settled = false;

    child.stdout.on('data', (chunk: Buffer) => {
      stdout += chunk.toString('utf8');
    });
    child.stderr.on('data', (chunk: Buffer) => {
      stderr += chunk.toString('utf8');
    });

    const watchdog = setTimeout(() => {
      if (settled) return;
      settled = true;
      try {
        child.kill('SIGTERM');
      } catch {
        // ignore
      }
      reject(
        new KilnUnavailableError(`Kiln subprocess did not exit within ${timeoutMs}ms; terminated.`)
      );
    }, timeoutMs);

    child.on('error', (e: Error) => {
      if (settled) return;
      settled = true;
      clearTimeout(watchdog);
      // ENOENT means the binary is missing.
      const msg =
        (e as NodeJS.ErrnoException).code === 'ENOENT'
          ? `Kiln binary not found at '${argv[0]}'; ensure Elixir/mix is installed and on PATH.`
          : `Kiln spawn error: ${e.message}`;
      reject(new KilnUnavailableError(msg, e));
    });

    child.on('close', (code) => {
      if (settled) return;
      settled = true;
      clearTimeout(watchdog);
      resolve({ stdout, stderr, exitCode: code ?? -1 });
    });
  });
}

async function safeUnlink(p: string): Promise<void> {
  try {
    await fs.unlink(p);
  } catch {
    // ignore: the tempfile may already be gone or unreadable; the
    // important invariant is that Kiln has already read it.
  }
}
