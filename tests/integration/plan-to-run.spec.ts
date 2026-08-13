/**
 * Plan -> Run integration tests.
 *
 * The key invariant: what the user inspected in `loadout plan` is the
 * exact Work Envelope submitted in `loadout run --plan`. The Plan is
 * not re-resolved, not re-compiled; only its freshness is checked.
 *
 * Also covers the fail-closed path: a stale Plan (different project
 * state) must not silently re-execute against the new state.
 */
import { describe, it, expect, beforeEach } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import {
  installPack,
  findGoalById,
  resolveCapability,
  compileWorkEnvelope,
  loadAndValidateQmr,
  snapshotRepo,
  readPackManifest,
  compileLoadoutPlan,
  loadPlan,
  writePlan,
  verifyPlanIntegrity,
  verifyPlanFreshness,
  invokeFakeKiln,
  buildResultView,
  defaultPlanPath
} from '../../src/index';
import { PlanIntegrityError, PlanStaleError } from '../../src/core/plan';

const PACKS_DIR = path.join(__dirname, '..', '..', 'src', 'packs');
const LOADOUT_ROOT = path.join(__dirname, '..', '..');

async function makeRepo(): Promise<string> {
  const repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-plan-int-'));
  await fs.mkdir(path.join(repoRoot, '.git', 'refs', 'heads'), { recursive: true });
  await fs.writeFile(path.join(repoRoot, '.git', 'HEAD'), 'ref: refs/heads/main\n');
  await fs.writeFile(
    path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
    '5555555555555555555555555555555555555555\n'
  );
  return repoRoot;
}

async function buildPlan(repoRoot: string) {
  // Install FIRST so the snapshot we capture below is the same as the
  // snapshot a subsequent `loadout run --plan` would see.
  await installPack(repoRoot, path.join(PACKS_DIR, 'repository-recon'));
  const goal = findGoalById('understand-a-repository')!;
  const cap = await resolveCapability(path.join(repoRoot, '.loadout', 'packs', 'repository-recon'));
  const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: LOADOUT_ROOT });
  const snap = await snapshotRepo(repoRoot);
  const envelope = compileWorkEnvelope({
    goal,
    capability: cap,
    qmr,
    projectState: {
      repository: repoRoot,
      baseCommit: snap.input.headCommit,
      workspaceStateDigest: snap.digest
    },
    createdAt: '2026-08-12T00:00:00Z'
  });
  const packManifest = await readPackManifest(
    path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
  );
  const plan = compileLoadoutPlan({
    goal,
    capability: cap,
    pack: packManifest,
    qmr,
    workEnvelope: envelope,
    projectState: {
      repository: repoRoot,
      baseCommit: snap.input.headCommit,
      workspaceStateDigest: snap.digest
    },
    createdAt: envelope.created_at
  });
  return { goal, cap, qmr, envelope, plan };
}

describe('plan -> run pipeline', () => {
  let repoRoot: string;

  beforeEach(async () => {
    repoRoot = await makeRepo();
  });

  it('what was inspected in plan is the exact Work Envelope submitted at run', async () => {
    const { plan } = await buildPlan(repoRoot);
    // Persist the plan
    const planPath = defaultPlanPath(repoRoot, plan);
    await writePlan({ plan, outPath: planPath });

    // Load the plan back (this is what `loadout run --plan` does)
    const loaded = await loadPlan(planPath);
    verifyPlanIntegrity(loaded);
    // current state matches plan's project_state
    const snap = await snapshotRepo(repoRoot);
    verifyPlanFreshness(loaded, {
      baseCommit: snap.input.headCommit,
      workspaceStateDigest: snap.digest
    });

    // Run with the loaded plan's envelope (no recompile)
    const result = invokeFakeKiln(loaded.work_envelope);
    const view = buildResultView(result);

    // The submitted envelope's work_id, method_provenance, project_state
    // and capability match the plan exactly.
    expect(result.work_id).toBe(loaded.work_envelope.work_id);
    expect(result.input_state.base_commit).toBe(loaded.work_envelope.project_state.base_commit);
    expect(result.input_state.workspace_state_digest).toBe(
      loaded.work_envelope.project_state.workspace_state_digest
    );
    expect(loaded.work_envelope.capability.method_provenance).toEqual(
      plan.work_envelope.capability.method_provenance
    );
    expect(view.simulated).toBe(true);
  });

  it('fails closed (PlanStaleError) when the repository has changed since the plan', async () => {
    const { plan } = await buildPlan(repoRoot);
    const planPath = defaultPlanPath(repoRoot, plan);
    await writePlan({ plan, outPath: planPath });
    const loaded = await loadPlan(planPath);
    // Mutate the repository: change the HEAD commit. This changes the
    // workspace_state_digest and base_commit.
    await fs.writeFile(
      path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
      '6666666666666666666666666666666666666666\n'
    );
    const currentSnap = await snapshotRepo(repoRoot);
    expect(() =>
      verifyPlanFreshness(loaded, {
        baseCommit: currentSnap.input.headCommit,
        workspaceStateDigest: currentSnap.digest
      })
    ).toThrow(PlanStaleError);
  });

  it('fails closed (PlanIntegrityError) when the plan file has been tampered with', async () => {
    const { plan } = await buildPlan(repoRoot);
    const planPath = defaultPlanPath(repoRoot, plan);
    await writePlan({ plan, outPath: planPath });
    // Mutate the file: rewrite the goal title. plan_id no longer matches.
    const parsed = JSON.parse(await fs.readFile(planPath, 'utf8')) as Record<string, unknown>;
    parsed.goal = { ...(parsed.goal as object), title: 'Tampered' };
    await fs.writeFile(planPath, JSON.stringify(parsed, null, 2));
    const loaded = await loadPlan(planPath);
    expect(() => verifyPlanIntegrity(loaded)).toThrow(PlanIntegrityError);
  });

  it('plan is written into .loadout/plans/ by defaultPlanPath', async () => {
    const { plan } = await buildPlan(repoRoot);
    const planPath = defaultPlanPath(repoRoot, plan);
    expect(planPath).toContain(path.join('.loadout', 'plans'));
    expect(planPath.endsWith(`${plan.plan_id}.json`)).toBe(true);
  });
});
