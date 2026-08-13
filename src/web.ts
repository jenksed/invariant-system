/**
 * Minimal local web surface.
 *
 * Serves the static files under /web/ and exposes:
 *   POST /plan  - produce a Loadout Plan v0 (the EXPLAIN path)
 *   POST /run   - execute (either ad-hoc, or with --plan)
 * The page and the server response always carry the `simulated` label.
 */
import http from 'node:http';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import {
  findGoalByTitle,
  compileWorkEnvelope,
  resolveCapability,
  invokeFakeKiln,
  buildResultView,
  workspacePaths,
  snapshotRepo,
  compileLoadoutPlan,
  readPackManifest,
  writePlan,
  defaultPlanPath,
  formatPlanText,
  loadPlan,
  verifyPlanIntegrity,
  verifyPlanFreshness,
  verifyPlanProcedureBinding,
  invokeProcedure,
  computeProcedureInterfaceDigest,
  submitWorkEnvelopeToKiln,
  KilnUnavailableError,
  KilnMalformedResponseError,
  KilnFakeLabelError,
  KilnSupervisionError
} from './index';
import { loadAndValidateQmr } from './core/qmr';
import {
  PlanMalformedError,
  PlanIntegrityError,
  PlanStaleError,
  PlanProcedureBindingError
} from './core/plan';
import { ProcedureResolutionError } from './core/procedure-registry';

export interface WebOptions {
  port: number;
  defaultRepository: string;
  packsDir: string;
}

const WEB_ROOT = path.resolve(__dirname, '..', 'web');
const LOADOUT_ROOT = path.resolve(__dirname, '..');
const TYPES = new Map<string, string>([
  ['.html', 'text/html; charset=utf-8'],
  ['.css', 'text/css; charset=utf-8'],
  ['.js', 'application/javascript; charset=utf-8']
]);

function jsonResponse(res: http.ServerResponse, code: number, body: unknown): void {
  res.writeHead(code, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

async function serveStatic(reqPath: string, res: http.ServerResponse): Promise<void> {
  const safe = reqPath === '/' ? '/index.html' : reqPath;
  const full = path.join(WEB_ROOT, safe);
  if (!full.startsWith(WEB_ROOT)) {
    res.writeHead(403);
    res.end('forbidden');
    return;
  }
  try {
    const buf = await fs.readFile(full);
    const ext = path.extname(full).toLowerCase();
    res.writeHead(200, { 'Content-Type': TYPES.get(ext) ?? 'application/octet-stream' });
    res.end(buf);
  } catch {
    res.writeHead(404);
    res.end('not found');
  }
}

async function readJsonBody(req: http.IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    let buf = '';
    req.setEncoding('utf8');
    req.on('data', (chunk) => (buf += chunk));
    req.on('end', () => {
      if (!buf) return resolve({});
      try {
        resolve(JSON.parse(buf));
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

export async function startWeb(opts: WebOptions): Promise<void> {
  const server = http.createServer(async (req, res) => {
    try {
      const url = new URL(req.url ?? '/', 'http://localhost');
      if (req.method === 'GET' && (url.pathname === '/' || url.pathname.startsWith('/static'))) {
        const rel = url.pathname.replace(/^\/static/, '');
        await serveStatic(rel, res);
        return;
      }
      if (req.method === 'POST' && url.pathname === '/plan') {
        const body = (await readJsonBody(req)) as {
          goal?: string;
          repository?: string;
          execution?: 'kiln' | 'simulate';
        };
        const goalTitle = body.goal ?? 'Understand this repository';
        const repository = body.repository ?? opts.defaultRepository;
        const executionBoundary = body.execution === 'kiln' ? 'kiln' : 'simulated';
        const goal = findGoalByTitle(goalTitle);
        if (!goal) {
          jsonResponse(res, 400, { error: `unknown goal: ${goalTitle}` });
          return;
        }
        const ws = workspacePaths(repository);
        const packRoot = path.join(ws.packs, 'repository-recon');
        try {
          await fs.stat(packRoot);
        } catch {
          jsonResponse(res, 409, {
            error: `pack repository-recon not installed at ${repository}; run 'loadout install repository-recon' first.`
          });
          return;
        }
        const cap = await resolveCapability(packRoot);
        let qmr;
        try {
          qmr = await loadAndValidateQmr({ capability: cap, repoRoot: repository });
        } catch (e) {
          jsonResponse(res, 422, { error: (e as Error).message, simulated: true });
          return;
        }
        const packManifest = await readPackManifest(packRoot);
        const snap = await snapshotRepo(repository);
        const envelope = compileWorkEnvelope({
          goal,
          capability: cap,
          qmr,
          projectState: {
            repository,
            baseCommit: snap.input.headCommit,
            workspaceStateDigest: snap.digest
          },
          createdAt: new Date().toISOString()
        });
        const plan = await compileLoadoutPlan({
          goal,
          capability: cap,
          pack: packManifest,
          qmr,
          workEnvelope: envelope,
          projectState: {
            repository,
            baseCommit: snap.input.headCommit,
            workspaceStateDigest: snap.digest
          },
          createdAt: envelope.created_at,
          packRoot,
          executionBoundary
        });
        const planPath = defaultPlanPath(repository, plan);
        await writePlan({ plan, outPath: planPath });
        jsonResponse(res, 200, {
          plan,
          planText: formatPlanText(plan),
          planPath,
          executionBoundary,
          // The Plan is real and content-addressable regardless of
          // boundary; only the result is labeled simulated when the
          // user explicitly chose the simulated boundary.
          simulated: executionBoundary === 'simulated'
        });
        return;
      }
      if (req.method === 'POST' && url.pathname === '/run-with-plan') {
        const body = (await readJsonBody(req)) as {
          planPath?: string;
          repository?: string;
          execution?: 'kiln' | 'simulate';
        };
        const planPath = body.planPath;
        const repository = body.repository ?? opts.defaultRepository;
        const requestedExecution = body.execution;
        if (!planPath) {
          jsonResponse(res, 400, { error: 'planPath is required' });
          return;
        }
        let plan;
        try {
          plan = await loadPlan(planPath);
        } catch (e) {
          if (e instanceof PlanMalformedError) {
            jsonResponse(res, 422, { error: e.message, simulated: true });
          } else {
            jsonResponse(res, 500, { error: (e as Error).message });
          }
          return;
        }
        try {
          verifyPlanIntegrity(plan);
        } catch (e) {
          if (e instanceof PlanIntegrityError) {
            jsonResponse(res, 422, { error: e.message, simulated: true });
          } else {
            jsonResponse(res, 500, { error: (e as Error).message });
          }
          return;
        }
        const currentSnap = await snapshotRepo(repository);
        const currentProjectState = {
          baseCommit: currentSnap.input.headCommit,
          workspaceStateDigest: currentSnap.digest
        };
        try {
          verifyPlanFreshness(plan, currentProjectState);
        } catch (e) {
          if (e instanceof PlanStaleError) {
            jsonResponse(res, 409, { error: e.message, simulated: true });
          } else {
            jsonResponse(res, 500, { error: (e as Error).message });
          }
          return;
        }
        // Verify the procedure binding: the Plan's recorded QMR
        // procedure_ref + Skill procedureEntry + procedure interface
        // digest must match the currently-loaded QMR, Skill, and
        // procedure module.
        const ws = workspacePaths(repository);
        const packRoot = path.join(ws.packs, plan.pack.id);
        const cap = await resolveCapability(packRoot);
        const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: LOADOUT_ROOT });
        const procedureInterfaceDigest = await computeProcedureInterfaceDigest({
          procedureEntry: cap.skill.procedureEntry,
          packRoot
        });
        try {
          verifyPlanProcedureBinding({
            plan,
            qmr,
            skill: cap.skill,
            procedureInterfaceDigest
          });
        } catch (e) {
          if (e instanceof PlanProcedureBindingError) {
            jsonResponse(res, 422, { error: e.message, simulated: true });
          } else {
            jsonResponse(res, 500, { error: (e as Error).message });
          }
          return;
        }
        let recon: { summary: string; [k: string]: unknown } | null = null;
        let procedureInvocationCount = 0;
        // Honor the Plan's recorded execution boundary; the user can
        // request a mismatch via the `execution` field, but the
        // mismatch MUST match (otherwise we refuse).
        const planBoundary = plan.execution_boundary.boundary;
        if (requestedExecution === 'kiln' && planBoundary !== 'kiln') {
          jsonResponse(res, 422, {
            error: `requested execution='kiln' but Plan's recorded boundary is '${planBoundary}'`,
            simulated: true
          });
          return;
        }
        if (requestedExecution === 'simulate' && planBoundary !== 'simulated') {
          jsonResponse(res, 422, {
            error: `requested execution='simulate' but Plan's recorded boundary is '${planBoundary}'`,
            simulated: true
          });
          return;
        }
        const effectiveMode: 'kiln' | 'simulate' = planBoundary === 'kiln' ? 'kiln' : 'simulate';
        let result;
        let kilnRawJson: string | null = null;
        try {
          if (effectiveMode === 'kiln') {
            const driverResult = await submitWorkEnvelopeToKiln(plan.work_envelope);
            result = driverResult.envelope;
            kilnRawJson = driverResult.rawJson;
            if (driverResult.procedureShouldRun) {
              procedureInvocationCount += 1;
              recon = (await invokeProcedure({
                procedureEntry: cap.skill.procedureEntry,
                packRoot,
                loadoutRoot: LOADOUT_ROOT,
                repoRoot: repository
              })) as { summary: string };
            }
          } else {
            result = invokeFakeKiln(plan.work_envelope);
            procedureInvocationCount += 1;
            recon = (await invokeProcedure({
              procedureEntry: cap.skill.procedureEntry,
              packRoot,
              loadoutRoot: LOADOUT_ROOT,
              repoRoot: repository
            })) as { summary: string };
          }
        } catch (e) {
          if (
            e instanceof KilnUnavailableError ||
            e instanceof KilnMalformedResponseError ||
            e instanceof KilnFakeLabelError ||
            e instanceof KilnSupervisionError
          ) {
            jsonResponse(res, 502, { error: e.message, simulated: false });
          } else if (e instanceof ProcedureResolutionError) {
            jsonResponse(res, 422, { error: e.message, simulated: true });
          } else {
            jsonResponse(res, 500, { error: (e as Error).message });
          }
          return;
        }
        const view = buildResultView(result);
        jsonResponse(res, 200, {
          plan_id: plan.plan_id,
          work_envelope_digest: plan.work_envelope_digest,
          view,
          reconSummary: recon?.summary,
          ...(recon ? { recon } : {}),
          executionBoundary: effectiveMode,
          procedureInvocationCount,
          ...(kilnRawJson ? { kilnRawJson } : {}),
          // The result is labeled simulated only when the user
          // explicitly chose the simulated boundary; a real Kiln run
          // result is NEVER labeled simulated.
          simulated: effectiveMode === 'simulate'
        });
        return;
      }
      if (req.method === 'POST' && url.pathname === '/run') {
        const body = (await readJsonBody(req)) as {
          goal?: string;
          repository?: string;
          execution?: 'kiln' | 'simulate';
        };
        const goalTitle = body.goal ?? 'Understand this repository';
        const repository = body.repository ?? opts.defaultRepository;
        const effectiveMode: 'kiln' | 'simulate' = body.execution === 'kiln' ? 'kiln' : 'simulate';
        const goal = findGoalByTitle(goalTitle);
        if (!goal) {
          jsonResponse(res, 400, { error: `unknown goal: ${goalTitle}` });
          return;
        }
        const ws = workspacePaths(repository);
        const packRoot = path.join(ws.packs, 'repository-recon');
        try {
          await fs.stat(packRoot);
        } catch {
          jsonResponse(res, 409, {
            error: `pack repository-recon not installed at ${repository}; run 'loadout install repository-recon' first.`
          });
          return;
        }
        const cap = await resolveCapability(packRoot);
        let qmr;
        try {
          qmr = await loadAndValidateQmr({ capability: cap, repoRoot: LOADOUT_ROOT });
        } catch (e) {
          jsonResponse(res, 422, { error: (e as Error).message, simulated: true });
          return;
        }
        const snap = await snapshotRepo(repository);
        const envelope = compileWorkEnvelope({
          goal,
          capability: cap,
          qmr,
          projectState: {
            repository,
            baseCommit: snap.input.headCommit,
            workspaceStateDigest: snap.digest
          },
          createdAt: new Date().toISOString()
        });
        let result;
        let recon: { summary: string; [k: string]: unknown } | null = null;
        let procedureInvocationCount = 0;
        let kilnRawJson: string | null = null;
        try {
          if (effectiveMode === 'kiln') {
            const driverResult = await submitWorkEnvelopeToKiln(envelope);
            result = driverResult.envelope;
            kilnRawJson = driverResult.rawJson;
            if (driverResult.procedureShouldRun) {
              procedureInvocationCount += 1;
              recon = (await invokeProcedure({
                procedureEntry: cap.skill.procedureEntry,
                packRoot,
                loadoutRoot: LOADOUT_ROOT,
                repoRoot: repository
              })) as { summary: string };
            }
          } else {
            result = invokeFakeKiln(envelope);
            procedureInvocationCount += 1;
            recon = (await invokeProcedure({
              procedureEntry: cap.skill.procedureEntry,
              packRoot,
              loadoutRoot: LOADOUT_ROOT,
              repoRoot: repository
            })) as { summary: string };
          }
        } catch (e) {
          if (
            e instanceof KilnUnavailableError ||
            e instanceof KilnMalformedResponseError ||
            e instanceof KilnFakeLabelError ||
            e instanceof KilnSupervisionError
          ) {
            jsonResponse(res, 502, { error: e.message, simulated: false });
          } else if (e instanceof ProcedureResolutionError) {
            jsonResponse(res, 422, { error: e.message, simulated: true });
          } else {
            jsonResponse(res, 500, { error: (e as Error).message });
          }
          return;
        }
        const view = buildResultView(result);
        jsonResponse(res, 200, {
          view,
          reconSummary: recon?.summary,
          ...(recon ? { recon } : {}),
          executionBoundary: effectiveMode,
          procedureInvocationCount,
          ...(kilnRawJson ? { kilnRawJson } : {}),
          simulated: effectiveMode === 'simulate'
        });
        return;
      }
      res.writeHead(404);
      res.end('not found');
    } catch (e) {
      jsonResponse(res, 500, { error: (e as Error).message });
    }
  });

  await new Promise<void>((resolve) => server.listen(opts.port, '127.0.0.1', resolve));
  // eslint-disable-next-line no-console
  console.log(`loadout web (SIMULATED) listening on http://127.0.0.1:${opts.port}`);
}
