/**
 * Plan fail-closed tests: `loadout plan` and `loadout run --plan` must
 * not produce a usable plan when the underlying QMR is missing,
 * malformed, or incompatible. The Plan's whole point is to faithfully
 * explain what will happen; if we cannot prove the request, we MUST NOT
 * print or save a superficially usable plan.
 *
 * Scenarios:
 *   1. QMR missing -> plan fails closed
 *   2. QMR malformed -> plan fails closed
 *   3. QMR with wrong outcome -> plan fails closed
 *   4. QMR with non-intersecting contexts -> plan fails closed
 *   5. QMR with insufficient method status -> plan fails closed
 *   6. Plan with unknown goal cannot be created
 *   7. Plan integrity check on a tampered file fails closed
 *   8. Plan freshness check on stale repository state fails closed
 */
import { describe, it, expect, beforeEach } from 'vitest';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import yaml from 'yaml';
import {
  installPack,
  findGoalById,
  resolveCapability,
  compileWorkEnvelope,
  loadAndValidateQmr,
  snapshotRepo,
  compileLoadoutPlan,
  loadPlan,
  writePlan,
  verifyPlanIntegrity,
  verifyPlanFreshness,
  readPackManifest
} from '../../src/index';
import { QmrMissingError, QmrMalformedError, QmrIncompatibilityError } from '../../src/core/qmr';
import { PlanIntegrityError, PlanStaleError } from '../../src/core/plan';

const PACKS_DIR = path.join(__dirname, '..', '..', 'src', 'packs');
const LOADOUT_ROOT = path.join(__dirname, '..', '..');

async function makeRepo(): Promise<string> {
  const repoRoot = await fs.mkdtemp(path.join(os.tmpdir(), 'loadout-plan-fc-'));
  await fs.mkdir(path.join(repoRoot, '.git', 'refs', 'heads'), { recursive: true });
  await fs.writeFile(path.join(repoRoot, '.git', 'HEAD'), 'ref: refs/heads/main\n');
  await fs.writeFile(
    path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
    '7777777777777777777777777777777777777777\n'
  );
  await installPack(repoRoot, path.join(PACKS_DIR, 'repository-recon'));
  return repoRoot;
}

function baseCompatibleQmr(): Record<string, unknown> {
  return {
    schema: 'engineering-system/qualified-method-record/v0',
    fixture: true,
    method_id: 'repository-recon/test-method',
    method_version: '0.0.0-test',
    status: 'experimental',
    qualified_for: {
      outcome: 'understand-a-repository',
      contexts: ['local-git-repository'],
      exclusions: ['this-fixture-does-not-claim-behavioral-qualification']
    },
    inputs: ['repository-state-reference'],
    outputs: ['repository-understanding'],
    procedure_ref: 'sha256:test-procedure',
    evaluation: {
      evidence_refs: [],
      models: [],
      repositories: [],
      observed_strengths: [],
      observed_failures: ['no-real-evaluation-attached'],
      confidence: 'unqualified-fixture'
    },
    provenance: { arsenal_commit: null, record_digest: 'sha256:test-digest' }
  };
}

describe('plan fail-closed behavior', () => {
  let repoRoot: string;
  beforeEach(async () => {
    repoRoot = await makeRepo();
  });

  it('1. missing QMR -> no Plan is produced', async () => {
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
    cap.skill.qmrFixturePath = 'fixtures/does-not-exist.yaml';
    await expect(
      loadAndValidateQmr({ capability: cap, repoRoot: repoRoot })
    ).rejects.toBeInstanceOf(QmrMissingError);
  });

  it('2. malformed QMR -> no Plan is produced', async () => {
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
    const filePath = path.join(repoRoot, 'qmr-bad-yaml.yaml');
    await fs.writeFile(filePath, 'this is: not: valid: yaml: [\n', 'utf8');
    cap.skill.qmrFixturePath = filePath;
    await expect(
      loadAndValidateQmr({ capability: cap, repoRoot: repoRoot })
    ).rejects.toBeInstanceOf(QmrMalformedError);
  });

  it('3. QMR with wrong outcome -> no Plan is produced', async () => {
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
    const filePath = path.join(repoRoot, 'qmr-wrong-outcome.yaml');
    await fs.writeFile(
      filePath,
      yaml.stringify({
        ...baseCompatibleQmr(),
        qualified_for: {
          outcome: 'wrong-outcome',
          contexts: ['local-git-repository'],
          exclusions: []
        }
      }),
      'utf8'
    );
    cap.skill.qmrFixturePath = filePath;
    await expect(
      loadAndValidateQmr({ capability: cap, repoRoot: repoRoot })
    ).rejects.toBeInstanceOf(QmrIncompatibilityError);
  });

  it('4. QMR with non-intersecting contexts -> no Plan is produced', async () => {
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
    const filePath = path.join(repoRoot, 'qmr-wrong-context.yaml');
    await fs.writeFile(
      filePath,
      yaml.stringify({
        ...baseCompatibleQmr(),
        qualified_for: {
          outcome: 'understand-a-repository',
          contexts: ['cloud-runtime'],
          exclusions: []
        }
      }),
      'utf8'
    );
    cap.skill.qmrFixturePath = filePath;
    await expect(
      loadAndValidateQmr({ capability: cap, repoRoot: repoRoot })
    ).rejects.toBeInstanceOf(QmrIncompatibilityError);
  });

  it('5. QMR with insufficient method status -> no Plan is produced', async () => {
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
    // require 'qualified' but the QMR is 'experimental'
    (cap.contract.compatibility as { min_method_status: string }).min_method_status = 'qualified';
    const filePath = path.join(repoRoot, 'qmr-experimental-only.yaml');
    await fs.writeFile(
      filePath,
      yaml.stringify({ ...baseCompatibleQmr(), status: 'experimental' }),
      'utf8'
    );
    cap.skill.qmrFixturePath = filePath;
    await expect(
      loadAndValidateQmr({ capability: cap, repoRoot: repoRoot })
    ).rejects.toBeInstanceOf(QmrIncompatibilityError);
  });

  it('7. Plan integrity check on a tampered file fails closed', async () => {
    const goal = findGoalById('understand-a-repository')!;
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
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
    const plan = await compileLoadoutPlan({
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
      createdAt: envelope.created_at,
      packRoot: path.join(PACKS_DIR, 'repository-recon')
    });
    const planPath = path.join(repoRoot, 'plan.json');
    await writePlan({ plan, outPath: planPath });
    const parsed = JSON.parse(await fs.readFile(planPath, 'utf8')) as Record<string, unknown>;
    parsed.requested_authority = [];
    await fs.writeFile(planPath, JSON.stringify(parsed, null, 2));
    const loaded = await loadPlan(planPath);
    expect(() => verifyPlanIntegrity(loaded)).toThrow(PlanIntegrityError);
  });

  it('8. Plan freshness check on stale state fails closed', async () => {
    const goal = findGoalById('understand-a-repository')!;
    const cap = await resolveCapability(
      path.join(repoRoot, '.loadout', 'packs', 'repository-recon')
    );
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
    const plan = await compileLoadoutPlan({
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
      createdAt: envelope.created_at,
      packRoot: path.join(PACKS_DIR, 'repository-recon')
    });
    // Mutate repo state
    await fs.writeFile(
      path.join(repoRoot, '.git', 'refs', 'heads', 'main'),
      '8888888888888888888888888888888888888888\n'
    );
    const newSnap = await snapshotRepo(repoRoot);
    expect(() =>
      verifyPlanFreshness(plan, {
        baseCommit: newSnap.input.headCommit,
        workspaceStateDigest: newSnap.digest
      })
    ).toThrow(PlanStaleError);
  });
});
