import { execFileSync } from 'node:child_process';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import type {
  LoadoutPlan,
  LoadoutRunRecord,
  M0ArtifactBundle,
  RunResultEnvelope,
  RunResultProjection,
  SourceFact,
  WorkbenchModel
} from './types.js';

export interface LoadOptions {
  runPath?: string;
  planPath?: string;
  m0ProjectionPath?: string;
}

const RESULT_SCHEMA = 'engineering-system/run-result-envelope/v0';
const PLAN_SCHEMA = 'loadout/plan/v0';
const M0_PROJECTION_SCHEMA = 'engineering-system/run-result-projection/m0-v1';

export async function loadWorkbench(
  repositoryInput: string,
  options: LoadOptions = {}
): Promise<WorkbenchModel> {
  const repository = path.resolve(repositoryInput);
  const errors: string[] = [];

  const stat = await fs.stat(repository).catch(() => undefined);
  if (!stat?.isDirectory()) {
    throw new Error(`repository is not a directory: ${repository}`);
  }

  const runRecordPath = options.runPath
    ? path.resolve(options.runPath)
    : await discoverLatestJson(path.join(repository, '.loadout', 'runs'));

  let runRecord: LoadoutRunRecord | undefined;
  let result: RunResultEnvelope | undefined;
  if (runRecordPath) {
    const parsed = await readJson(runRecordPath, 'Run record', errors);
    const normalized = parsed ? normalizeRunRecord(parsed) : undefined;
    if (normalized) {
      runRecord = normalized;
      if (normalized.result.simulated === true) {
        errors.push('Run Result is simulated; Temper only presents real Kiln Run state.');
      } else {
        result = normalized.result;
      }
    } else if (parsed) {
      errors.push(`Run record is incompatible: expected result.schema=${RESULT_SCHEMA}.`);
    }
  } else {
    errors.push('No Run exists: .loadout/runs contains no JSON run record.');
  }

  const planPath = await resolvePlanPath(repository, runRecord, options.planPath);
  let plan: LoadoutPlan | undefined;
  if (planPath) {
    const parsed = await readJson(planPath, 'Plan', errors);
    if (parsed && isPlan(parsed)) {
      plan = parsed;
    } else if (parsed) {
      errors.push(`Plan is incompatible: expected schema=${PLAN_SCHEMA}.`);
    }
  } else {
    errors.push('Plan missing: no readable source Plan is referenced by the latest Run.');
  }

  // M0 RunResultProjection — discovered alongside the v0 Run record.
  // Per M10 doctrine, projection is canonical truth, never inferred.
  // `fixture_only: true` is rejected at this layer (operator must never
  // be shown a fixture as if it were a real Run).
  const m0ProjectionPath =
    options.m0ProjectionPath ??
    (runRecordPath
      ? path.join(path.dirname(path.dirname(runRecordPath)), 'projections')
      : undefined);
  const m0 = await loadM0Bundle(m0ProjectionPath, errors);

  const { currentness, reason } = repositoryCurrentness(repository, result);
  const sources = buildSources(
    repository,
    runRecordPath,
    planPath,
    result,
    plan,
    m0
  );

  return {
    repository,
    repositoryName: path.basename(repository),
    ...(runRecordPath ? { runRecordPath } : {}),
    ...(planPath ? { planPath } : {}),
    ...(m0ProjectionPath ? { m0ProjectionPath } : {}),
    ...(runRecord ? { runRecord } : {}),
    ...(result ? { result } : {}),
    ...(plan ? { plan } : {}),
    ...(m0.projection ? { m0 } : {}),
    currentness,
    currentnessReason: reason,
    errors,
    sources
  };
}

async function loadM0Bundle(
  directory: string | undefined,
  errors: string[]
): Promise<M0ArtifactBundle> {
  if (!directory) return {};
  let names: string[] = [];
  try {
    names = await fs.readdir(directory);
  } catch {
    return {};
  }
  const candidates = names.filter((n) => n.endsWith('.json'));
  if (candidates.length === 0) return {};

  // Discover the most recent M0 projection; canonical name is
  // `<projection_id>.json`; the schema field is the canonical
  // identifier, not the filename.
  let chosen: { path: string; mtimeMs: number } | undefined;
  for (const name of candidates) {
    const candidate = path.join(directory, name);
    const stat = await fs.stat(candidate).catch(() => undefined);
    if (!stat?.isFile()) continue;
    if (!chosen || stat.mtimeMs > chosen.mtimeMs) {
      chosen = { path: candidate, mtimeMs: stat.mtimeMs };
    }
  }
  if (!chosen) return {};

  const parsed = await readJson(chosen.path, 'M0 projection', errors);
  if (!parsed) return { projectionPath: chosen.path };
  if (!isRunResultProjection(parsed)) {
    errors.push(
      `M0 projection at ${chosen.path} is incompatible: expected schema=${M0_PROJECTION_SCHEMA}.`
    );
    return { projectionPath: chosen.path };
  }
  // Reject fixture-only projections at the load layer.
  const meta = parsed.metadata as Record<string, unknown> | undefined;
  if (meta?.fixture_only === true) {
    errors.push(
      `M0 projection at ${chosen.path} is marked fixture_only; Temper only presents real projections.`
    );
    return { projectionPath: chosen.path };
  }
  return { projectionPath: chosen.path, projection: parsed };
}

async function discoverLatestJson(directory: string): Promise<string | undefined> {
  const names = await fs.readdir(directory).catch(() => [] as string[]);
  const candidates = await Promise.all(
    names
      .filter((name) => name.endsWith('.json'))
      .map(async (name) => {
        const candidate = path.join(directory, name);
        const stat = await fs.stat(candidate);
        return { candidate, modified: stat.mtimeMs };
      })
  );
  return candidates.sort((a, b) => b.modified - a.modified)[0]?.candidate;
}

async function resolvePlanPath(
  repository: string,
  runRecord: LoadoutRunRecord | undefined,
  explicit: string | undefined
): Promise<string | undefined> {
  const candidates = [
    explicit ? path.resolve(explicit) : undefined,
    runRecord?.sourcePlanPath ? path.resolve(runRecord.sourcePlanPath) : undefined,
    runRecord?.plan_id
      ? path.join(repository, '.loadout', 'plans', `${runRecord.plan_id}.json`)
      : undefined
  ].filter((candidate): candidate is string => candidate !== undefined);

  for (const candidate of candidates) {
    const stat = await fs.stat(candidate).catch(() => undefined);
    if (stat?.isFile()) return candidate;
  }
  return undefined;
}

async function readJson(
  filePath: string,
  label: string,
  errors: string[]
): Promise<unknown | undefined> {
  try {
    return JSON.parse(await fs.readFile(filePath, 'utf8')) as unknown;
  } catch (error) {
    errors.push(`${label} unavailable at ${filePath}: ${(error as Error).message}`);
    return undefined;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every((item) => typeof item === 'string');
}

function isArtifactRef(value: unknown): boolean {
  return (
    isRecord(value) &&
    typeof value.id === 'string' &&
    typeof value.digest === 'string'
  );
}

function normalizeRunRecord(value: unknown): LoadoutRunRecord | undefined {
  if (!isRecord(value)) return undefined;
  const result = isRecord(value.runResult) ? value.runResult : isRecord(value.result) ? value.result : undefined;
  if (!isRunResult(result)) return undefined;

  const sourcePlan = isRecord(value.sourcePlan) ? value.sourcePlan : undefined;
  const planId =
    typeof sourcePlan?.plan_id === 'string'
      ? sourcePlan.plan_id
      : typeof value.plan_id === 'string'
        ? value.plan_id
        : '';
  const sourcePlanPath =
    typeof sourcePlan?.plan_path === 'string'
      ? sourcePlan.plan_path
      : typeof value.sourcePlanPath === 'string'
        ? value.sourcePlanPath
        : undefined;

  return {
    plan_id: planId,
    result: result as unknown as RunResultEnvelope,
    executionBoundary: typeof value.executionBoundary === 'string' ? value.executionBoundary : 'n/a',
    ...(sourcePlanPath ? { sourcePlanPath } : {}),
    raw: value
  };
}

function isRunResult(value: unknown): value is RunResultEnvelope {
  if (!isRecord(value)) return false;
  const authority = value.authority;
  const inputState = value.input_state;
  const finalState = value.final_state;
  const proof = value.proof_obligations;
  const acceptance = value.acceptance_readiness;
  const evidence = value.evidence;

  return (
    value.schema === RESULT_SCHEMA &&
    typeof value.work_id === 'string' &&
    typeof value.run_id === 'string' &&
    ['completed', 'blocked', 'cancelled', 'failed', 'unknown'].includes(String(value.status)) &&
    isRecord(inputState) &&
    typeof inputState.base_commit === 'string' &&
    typeof inputState.workspace_state_digest === 'string' &&
    isRecord(finalState) &&
    typeof finalState.commit === 'string' &&
    typeof finalState.workspace_state_digest === 'string' &&
    isRecord(authority) &&
    isStringArray(authority.requested) &&
    isStringArray(authority.granted) &&
    isStringArray(authority.denied) &&
    Array.isArray(value.effects) &&
    value.effects.every(isRecord) &&
    Array.isArray(evidence) &&
    evidence.every(
      (item) =>
        isRecord(item) &&
        typeof item.id === 'string' &&
        typeof item.kind === 'string' &&
        typeof item.state_digest === 'string'
    ) &&
    isRecord(proof) &&
    isStringArray(proof.satisfied) &&
    isStringArray(proof.unsatisfied) &&
    isStringArray(proof.invalidated) &&
    isStringArray(value.unknowns) &&
    isRecord(acceptance) &&
    typeof acceptance.ready === 'boolean' &&
    isStringArray(acceptance.reasons)
  );
}

function isPlan(value: unknown): value is LoadoutPlan {
  return (
    isRecord(value) &&
    value.schema === PLAN_SCHEMA &&
    typeof value.plan_id === 'string' &&
    isRecord(value.goal) &&
    typeof value.goal.title === 'string'
  );
}

function isRunResultProjection(value: unknown): value is RunResultProjection {
  if (!isRecord(value)) return false;
  const truth = value.truth;
  return (
    value.schema === M0_PROJECTION_SCHEMA &&
    typeof value.projection_id === 'string' &&
    typeof value.semantic_digest === 'string' &&
    isArtifactRef(value.plan_ref) &&
    isArtifactRef(value.implementer_assignment_ref) &&
    isArtifactRef(value.reviewer_assignment_ref) &&
    isArtifactRef(value.patch_ref) &&
    isArtifactRef(value.patch_decision_ref) &&
    isArtifactRef(value.verification_ref) &&
    (value.review_ref === null || isArtifactRef(value.review_ref)) &&
    (value.human_decision_ref === null || isArtifactRef(value.human_decision_ref)) &&
    isArtifactRef(value.run_result_ref) &&
    isRecord(truth) &&
    [
      'completed',
      'blocked',
      'cancelled',
      'failed',
      'unknown'
    ].includes(String(truth.run_status)) &&
    ['PASS', 'FAIL', 'TIMEOUT', 'ERROR'].includes(String(truth.verification_status)) &&
    ['APPROVE', 'REQUEST_REVISION', 'REJECT'].includes(String(truth.review_status)) &&
    ['ACCEPT', 'REJECT', 'REQUEST_REVISION'].includes(String(truth.human_status)) &&
    Array.isArray(truth.unknown_effects)
  );
}

function repositoryCurrentness(
  repository: string,
  result: RunResultEnvelope | undefined
): { currentness: WorkbenchModel['currentness']; reason: string } {
  if (!result) return { currentness: 'n/a', reason: 'no real Run Result is available' };
  try {
    const head = execFileSync('git', ['-C', repository, 'rev-parse', 'HEAD'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore']
    }).trim();
    if (head === result.final_state.commit) {
      return { currentness: 'current', reason: `repository HEAD matches ${result.final_state.commit}` };
    }
    return {
      currentness: 'stale',
      reason: `repository HEAD ${head} differs from Run final commit ${result.final_state.commit}`
    };
  } catch {
    return { currentness: 'n/a', reason: 'git HEAD could not be read for this repository' };
  }
}

function buildSources(
  repository: string,
  runRecordPath: string | undefined,
  planPath: string | undefined,
  result: RunResultEnvelope | undefined,
  plan: LoadoutPlan | undefined,
  m0: M0ArtifactBundle
): Record<string, SourceFact> {
  const runCommand = `npx loadout run --plan <plan-path> --repository ${repository} --execution kiln`;
  const planCommand = `npx loadout plan --goal "Understand this repository" --repository ${repository} --execution kiln`;
  const m0Command = `mix kiln human-decide --plan <plan-ref> --patch <patch-ref> --result-state-digest <digest> --decision <kind> --out <projection-path>`;
  const sources: Record<string, SourceFact> = {};

  if (runRecordPath && result) {
    const runFacts: Array<[string, string]> = [
      ['run_id', result.run_id],
      ['status', result.status],
      ['authority', JSON.stringify(result.authority)],
      ['evidence', JSON.stringify(result.evidence)],
      ['artifacts', JSON.stringify(result.effects)],
      ['unknowns', JSON.stringify(result.unknowns)],
      ['acceptance_readiness', JSON.stringify(result.acceptance_readiness)],
      ['raw', result.schema]
    ];
    for (const [key, value] of runFacts) {
      sources[key] = { value, sourcePath: runRecordPath, command: runCommand };
    }
  }

  if (planPath && plan) {
    sources.goal = { value: plan.goal.title, sourcePath: planPath, command: planCommand };
    sources.plan = { value: plan.plan_id, sourcePath: planPath, command: planCommand };
  }

  if (m0.projectionPath && m0.projection) {
    const proj = m0.projection;
    const projFacts: Array<[string, string]> = [
      ['m0_projection_id', proj.projection_id],
      ['m0_run_status', proj.truth.run_status],
      ['m0_verification_status', proj.truth.verification_status],
      ['m0_review_status', proj.truth.review_status],
      ['m0_human_status', proj.truth.human_status]
    ];
    for (const [key, value] of projFacts) {
      sources[key] = {
        value,
        sourcePath: m0.projectionPath,
        command: m0Command
      };
    }
  }

  return sources;
}
