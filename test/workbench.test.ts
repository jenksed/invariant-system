import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { loadWorkbench } from '../src/load.js';
import { renderWorkbench } from '../src/render.js';

async function fixture(): Promise<{
  root: string;
  runPath: string;
  planPath: string;
  commit: string;
}> {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'temper-workbench-'));
  await fs.writeFile(path.join(root, 'README.md'), '# fixture\n');
  execFileSync('git', ['-C', root, 'init', '-q', '--initial-branch=main']);
  execFileSync('git', ['-C', root, '-c', 'user.name=Temper', '-c', 'user.email=temper@local', 'add', '.']);
  execFileSync('git', [
    '-C',
    root,
    '-c',
    'user.name=Temper',
    '-c',
    'user.email=temper@local',
    'commit',
    '-qm',
    'fixture'
  ]);
  const commit = execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  const planPath = path.join(root, '.loadout', 'plans', 'plan.json');
  const runPath = path.join(root, '.loadout', 'runs', 'run.json');
  await fs.mkdir(path.dirname(planPath), { recursive: true });
  await fs.mkdir(path.dirname(runPath), { recursive: true });

  const plan = {
    schema: 'loadout/plan/v0',
    plan_id: 'sha256:plan',
    goal: {
      id: 'understand-a-repository',
      title: 'Understand this repository',
      success_conditions: ['report architecture anchors']
    },
    capability: { id: 'repository-recon', contract_version: '0.1.0-fixture' },
    pack: { id: 'repository-recon', version: '0.1.0-fixture' },
    skill: { id: 'repository-recon/fixture-method' },
    method: {
      method_id: 'repository-recon/fixture-method',
      method_version: '0.0.0-fixture',
      status: 'experimental',
      confidence: 'unqualified-fixture'
    },
    project_state: {
      repository: root,
      base_commit: commit,
      workspace_state_digest: 'sha256:workspace'
    },
    execution_boundary: { boundary: 'kiln', reason: 'test', details: 'real Kiln' }
  };
  const result = {
    schema: 'engineering-system/run-result-envelope/v0',
    work_id: 'work-1',
    run_id: 'run-1',
    status: 'completed',
    input_state: { base_commit: commit, workspace_state_digest: 'sha256:workspace' },
    final_state: { commit, workspace_state_digest: 'sha256:workspace' },
    authority: { requested: ['git.read'], granted: ['git.read'], denied: [] },
    effects: [{ artifact_id: 'artifact-1', kind: 'authority_decision' }],
    evidence: [{ id: 'evidence-1', kind: 'evidence', state_digest: 'sha256:evidence' }],
    proof_obligations: { satisfied: ['repo-state-observed'], unsatisfied: [], invalidated: [] },
    unknowns: ['producer and Kiln digests have different scopes'],
    recovery: null,
    acceptance_readiness: { ready: false, reasons: ['user acceptance remains external'] }
  };
  await fs.writeFile(planPath, JSON.stringify(plan));
  await fs.writeFile(
    runPath,
    JSON.stringify({
      sourcePlan: { plan_id: plan.plan_id, plan_path: planPath },
      runResult: result,
      executionBoundary: 'kiln',
      procedureInvocationCount: 1
    })
  );
  return { root, runPath, planPath, commit };
}

function visibleContent(output: string): string {
  return output
    .split('\n')
    .slice(1, -1)
    .map((line) => line.slice(2, -2).trimEnd())
    .join('');
}

test('overview renders only real discovered Run, Plan, authority, Evidence, and Artifact facts', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const model = await loadWorkbench(data.root);
  const output = renderWorkbench(model, 'overview', 120);

  assert.match(output, /Understand this repository/);
  assert.match(output, /sha256:plan/);
  assert.match(output, /run-1/);
  assert.match(output, /GRANTED: git\.read/);
  assert.match(output, /1 real reference\(s\)/);
  assert.match(output, /NOT READY/);
  assert.match(output, /CURRENT/);
  assert.match(output, /Temper-derived/);
  assert.doesNotMatch(output, /simulated/i);
});

test('raw focus contains the actual canonical Run Result JSON', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const model = await loadWorkbench(data.root);
  const output = renderWorkbench(model, 'raw', 140);

  assert.match(output, /engineering-system\/run-result-envelope\/v0/);
  assert.match(output, /"run_id": "run-1"/);
  assert.match(output, /"state_digest": "sha256:evidence"/);
  assert.match(output, /SOURCE/);
  assert.match(output, /\.loadout\/runs\/run\.json/);
});

test('missing inputs render n/a with explicit reasons rather than invented values', async (t) => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'temper-empty-'));
  t.after(() => fs.rm(root, { recursive: true, force: true }));
  const model = await loadWorkbench(root);
  const output = renderWorkbench(model, 'overview', 100);

  assert.match(output, /n\/a — No Run exists/);
  assert.match(output, /n\/a — Plan missing/);
  assert.match(output, /INPUT GAPS/);
});

test('every unavailable major focus renders a specific n/a reason', async (t) => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'temper-empty-focus-'));
  t.after(() => fs.rm(root, { recursive: true, force: true }));
  const model = await loadWorkbench(root);

  for (const focus of ['plan', 'run', 'authority', 'evidence', 'artifacts', 'raw'] as const) {
    const output = renderWorkbench(model, focus, 80);
    assert.match(output, /n\/a — \S.+/, `${focus} did not explain its unavailable input`);
  }
});

test('incomplete Run input renders n/a instead of crashing or inventing state', async (t) => {
  const root = await fs.mkdtemp(path.join(os.tmpdir(), 'temper-incomplete-'));
  t.after(() => fs.rm(root, { recursive: true, force: true }));
  const runDirectory = path.join(root, '.loadout', 'runs');
  await fs.mkdir(runDirectory, { recursive: true });
  await fs.writeFile(
    path.join(runDirectory, 'run.json'),
    JSON.stringify({
      runResult: {
        schema: 'engineering-system/run-result-envelope/v0',
        run_id: 'incomplete-run'
      }
    })
  );

  const model = await loadWorkbench(root);
  const output = renderWorkbench(model, 'overview', 100);

  assert.match(output, /n\/a — Run record is incompatible/);
  assert.doesNotMatch(output, /incomplete-run/);
});

test('simulated Run input is rejected as real state with an explicit reason', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const record = JSON.parse(await fs.readFile(data.runPath, 'utf8')) as {
    runResult: Record<string, unknown>;
  };
  record.runResult.simulated = true;
  await fs.writeFile(data.runPath, JSON.stringify(record));

  const model = await loadWorkbench(data.root);
  const output = renderWorkbench(model, 'overview', 100);

  assert.match(output, /n\/a — Run Result is simulated/);
  assert.doesNotMatch(output, /run-1/);
  assert.doesNotMatch(output, /real reference/);
});

test('missing referenced Plan is not synthesized from Run facts', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  await fs.rm(data.planPath);

  const model = await loadWorkbench(data.root);
  const planOutput = renderWorkbench(model, 'plan', 100);

  assert.equal(model.plan, undefined);
  assert.match(planOutput, /n\/a — Plan missing/);
  assert.doesNotMatch(planOutput, /Understand this repository/);
});

test('diagnostic summary form remains compatible without replacing the canonical producer form', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const canonical = JSON.parse(await fs.readFile(data.runPath, 'utf8')) as {
    sourcePlan: { plan_id: string; plan_path: string };
    runResult: Record<string, unknown>;
  };
  await fs.writeFile(
    data.runPath,
    JSON.stringify({
      plan_id: canonical.sourcePlan.plan_id,
      sourcePlanPath: canonical.sourcePlan.plan_path,
      result: canonical.runResult,
      executionBoundary: 'kiln'
    })
  );

  const model = await loadWorkbench(data.root);
  assert.equal(model.result?.run_id, 'run-1');
  assert.equal(model.plan?.plan_id, 'sha256:plan');
});

test('repository change marks the Run stale without changing Run facts', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  await fs.writeFile(path.join(data.root, 'changed.txt'), 'changed\n');
  execFileSync('git', ['-C', data.root, 'add', 'changed.txt']);
  execFileSync('git', [
    '-C',
    data.root,
    '-c',
    'user.name=Temper',
    '-c',
    'user.email=temper@local',
    'commit',
    '-qm',
    'change'
  ]);

  const model = await loadWorkbench(data.root);
  assert.equal(model.currentness, 'stale');
  assert.match(model.currentnessReason, /differs from Run final commit/);
  assert.equal(model.result?.run_id, 'run-1');
});

test('every major focus retains its source file and producer command', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const model = await loadWorkbench(data.root);

  for (const focus of ['plan', 'run', 'authority', 'evidence', 'artifacts', 'raw'] as const) {
    const output = renderWorkbench(model, focus, 140);
    assert.match(output, /SOURCE/);
    if (focus === 'plan') {
      assert.match(output, /\.loadout\/plans\/plan\.json/);
      assert.match(output, /loadout plan --goal/);
    } else {
      assert.match(output, /\.loadout\/runs\/run\.json/);
      assert.match(output, /loadout run --plan/);
    }
  }
  const evidence = renderWorkbench(model, 'evidence', 140);
  assert.match(evidence, /freshness.*n\/a/);
  assert.match(evidence, /contradiction.*n\/a/);
});

test('60, 80, 100, and 128-column snapshots preserve truth within terminal width', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const model = await loadWorkbench(data.root);

  for (const width of [60, 80, 100, 128]) {
    for (const focus of ['overview', 'plan', 'run', 'authority', 'evidence', 'artifacts', 'raw'] as const) {
      const output = renderWorkbench(model, focus, width);
      for (const line of output.split('\n')) {
        assert.ok(line.length <= width, `${focus} line exceeded ${width} columns: ${line}`);
      }
    }
  }
});

test('narrow views preserve every major source path and command character', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const model = await loadWorkbench(data.root);
  for (const focus of ['run', 'authority', 'evidence', 'artifacts', 'raw'] as const) {
    const content = visibleContent(renderWorkbench(model, focus, 60));
    assert.ok(content.includes(data.runPath), `${focus} lost its source path`);
    assert.ok(content.includes('loadout run --plan <plan-path>'), `${focus} lost its source command`);
  }

  const plan = visibleContent(renderWorkbench(model, 'plan', 60));
  assert.ok(plan.includes(data.planPath));
  assert.ok(plan.includes('loadout plan --goal "Understand this repository"'));
});

test('acceptance readiness and canonical Raw Result are reproduced without strengthening', async (t) => {
  const data = await fixture();
  t.after(() => fs.rm(data.root, { recursive: true, force: true }));
  const record = JSON.parse(await fs.readFile(data.runPath, 'utf8')) as {
    runResult: Record<string, unknown>;
  };
  const original = structuredClone(record.runResult);

  const model = await loadWorkbench(data.root);
  const overview = renderWorkbench(model, 'overview', 128);
  const rawRows = renderWorkbench(model, 'raw', 240)
    .split('\n')
    .slice(1, -1)
    .map((line) => line.slice(2, -2).trimEnd());
  const jsonStart = rawRows.indexOf(' {');
  const sourceStart = rawRows.indexOf(' SOURCE');
  const jsonRows = rawRows.slice(jsonStart, sourceStart);
  while (jsonRows.at(-1) === '') jsonRows.pop();
  const displayedResult = JSON.parse(jsonRows.map((line) => line.slice(1)).join('\n')) as unknown;

  assert.deepEqual(model.result, original);
  assert.match(overview, /NOT READY — user acceptance remains external/);
  assert.deepEqual(displayedResult, original);
});
