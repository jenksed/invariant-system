#!/usr/bin/env node
/**
 * Loadout CLI.
 *
 * Subcommands for LOD-02:
 *   loadout catalog
 *   loadout install <pack-id>
 *   loadout inspect <pack-id>
 *   loadout plan --goal "<title>" [--repository <path>] [--pack <pack-id>] [--out <path>]
 *   loadout run [--goal "<title>" | --plan <path>] [--repository <path>] [--pack <pack-id>]
 *   loadout remove <pack-id>
 *   loadout rollback <pack-id>
 *   loadout swap <pack-id> --skill <path>
 *   loadout web [--port <n>]
 *   loadout validate-contracts
 *
 * Every command output that contains run results is labeled SIMULATED.
 */
import { Command } from 'commander';
import path from 'node:path';
import { promises as fs } from 'node:fs';
import {
  GOAL_CATALOGUE,
  findGoalByTitle,
  compileWorkEnvelope,
  resolveCapability,
  invokeFakeKiln,
  buildResultView,
  formatResultViewText,
  installPack,
  removePack,
  rollbackPack,
  listCatalog,
  readPackManifest,
  loadQmrFixture,
  workspacePaths,
  ensureWorkspace,
  snapshotRepo,
  loadSkillDescriptor,
  compileLoadoutPlan,
  loadPlan,
  verifyPlanIntegrity,
  verifyPlanFreshness,
  verifyPlanProcedureBinding,
  invokeProcedure,
  computeProcedureInterfaceDigest,
  writePlan,
  defaultPlanPath,
  formatPlanText
} from './index';
import { loadAndValidateQmr } from './core/qmr';
import { validateAllFixtures, compileAgainstGoalCatalog } from './core/contract-validation';
import {
  PlanMalformedError,
  PlanIntegrityError,
  PlanStaleError,
  PlanProcedureBindingError
} from './core/plan';
import { ProcedureResolutionError } from './core/procedure-registry';

const PACKS_DIR = path.resolve(__dirname, 'packs');
// Loadout installation root: the directory containing the dist/ folder.
// Used to resolve bundled v0 fixtures (e.g. fixtures/qualified-method-record.v0.yaml)
// whose path is relative to the loadout installation, not the target repo.
const LOADOUT_ROOT = path.resolve(__dirname, '..');
const DEFAULT_REPO = process.cwd();

const program = new Command();
program
  .name('loadout')
  .description(
    'Loadout: human-facing capability environment (LOD-01 slice). All runs are SIMULATED.'
  )
  .version('0.1.0-fixture');

program
  .command('catalog')
  .description('List available packs (SIMULATED slice: one pack).')
  .action(async () => {
    const manifests = await listCatalog(PACKS_DIR);
    if (manifests.length === 0) {
      console.log('(no packs bundled)');
      return;
    }
    for (const m of manifests) {
      console.log(`${m.id} @ ${m.version}`);
      console.log(`  capability: ${m.capability.id} contract=${m.capability.contract_version}`);
      console.log(`  skill:      ${m.skill.id} qmr=${m.skill.qmr_fixture}`);
      console.log(`  ${m.description}`);
    }
  });

program
  .command('install <packId>')
  .description('Install a pack into the target repository workspace.')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .action(async (packId: string, opts: { repository: string }) => {
    const source = path.join(PACKS_DIR, packId);
    try {
      const manifest = await readPackManifest(source);
      if (manifest.id !== packId) {
        throw new Error(`pack id mismatch: ${manifest.id} != ${packId}`);
      }
    } catch (e) {
      console.error(`install failed: ${(e as Error).message}`);
      process.exit(2);
    }
    const res = await installPack(opts.repository, source);
    console.log(`installed ${packId} at ${res.installedPath}`);
    console.log(`snapshot:    ${res.snapshotPath}`);
  });

program
  .command('inspect <packId>')
  .description('Inspect an installed pack: manifest, capability contract, skill, QMR fixture.')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .action(async (packId: string, opts: { repository: string }) => {
    const ws = workspacePaths(opts.repository);
    const installed = path.join(ws.packs, packId, 'pack.json');
    try {
      await fs.stat(installed);
    } catch {
      console.error(
        `pack ${packId} is not installed at ${opts.repository}; run 'loadout install ${packId}' first.`
      );
      process.exit(2);
    }
    const cap = await resolveCapability(path.join(ws.packs, packId));
    const qmr = await loadQmrFixture(cap.skill.qmrFixturePath, opts.repository);
    console.log('=== Pack Inspection ===');
    console.log(`Pack id:           ${packId}`);
    console.log(`Capability id:     ${cap.contract.id}`);
    console.log(`Contract version:  ${cap.contract.contract_version}`);
    console.log(`Skill id:          ${cap.skill.id}`);
    console.log(`QMR fixture:       ${cap.skill.qmrFixturePath}`);
    console.log(`QMR status:        ${qmr.status}`);
    console.log(`QMR confidence:    ${qmr.evaluation.confidence}`);
    console.log(`Goal outcome:      ${cap.contract.goal_outcome}`);
    console.log(
      `Compatibility:     min_method_status=${cap.contract.compatibility.min_method_status}, contexts=${cap.contract.compatibility.accepted_contexts.join(',')}`
    );
    console.log('NOTE: this is inspection of a SIMULATED slice; no real Kiln enforcement.');
  });

program
  .command('run')
  .description(
    'Run the selected Goal/Capability end-to-end through the SIMULATED boundary. ' +
      'Either --goal or --plan must be supplied. --plan uses the pre-compiled ' +
      'Work Envelope from `loadout plan`; nothing is silently recomputed.'
  )
  .option('-g, --goal <title>', 'Goal title (e.g., "Understand this repository")')
  .option('--plan <path>', 'Path to a Plan v0 file produced by `loadout plan`')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .option('-p, --pack <packId>', 'pack id to use (required with --goal)', '')
  .option(
    '--qmr-fixture <path>',
    'override the QMR fixture path (power user; ignored with --plan)',
    ''
  )
  .option('-o, --out <path>', 'write the run record (JSON) here', '')
  .action(
    async (opts: {
      goal?: string;
      plan?: string;
      repository: string;
      pack: string;
      qmrFixture: string;
      out: string;
    }) => {
      // --plan and --goal are mutually exclusive. Exactly one must be present.
      if (Boolean(opts.plan) === Boolean(opts.goal)) {
        console.error('loadout run: provide exactly one of --goal "<title>" or --plan <path>.');
        process.exit(2);
      }

      // ----- PLAN path: load the plan, verify integrity + freshness, -----
      // ----- then submit the embedded Work Envelope without recompile. -----
      if (opts.plan) {
        let plan;
        try {
          plan = await loadPlan(opts.plan);
        } catch (e) {
          if (e instanceof PlanMalformedError) {
            console.error(`loadout run: ${e.message}`);
          } else {
            console.error(`loadout run: failed to load plan: ${(e as Error).message}`);
          }
          process.exit(1);
        }
        try {
          verifyPlanIntegrity(plan);
        } catch (e) {
          if (e instanceof PlanIntegrityError) {
            console.error(`loadout run: ${e.message}`);
          } else {
            console.error(`loadout run: plan integrity check failed: ${(e as Error).message}`);
          }
          process.exit(1);
        }
        // Re-snapshot the repository; refuse to silently re-resolve if
        // the project state has changed since the plan was created.
        const currentSnap = await snapshotRepo(opts.repository);
        const currentProjectState = {
          baseCommit: currentSnap.input.headCommit,
          workspaceStateDigest: currentSnap.digest
        };
        try {
          verifyPlanFreshness(plan, currentProjectState);
        } catch (e) {
          if (e instanceof PlanStaleError) {
            console.error(`loadout run: ${e.message}`);
          } else {
            console.error(`loadout run: plan freshness check failed: ${(e as Error).message}`);
          }
          process.exit(1);
        }

        // Verify the procedure binding: the Plan's recorded QMR
        // procedure_ref + Skill procedureEntry + procedure interface
        // digest must match the currently-loaded QMR, Skill, and
        // procedure module. This is the mechanical check that makes
        // sure the procedure that runs is the one the Plan describes.
        const ws = workspacePaths(opts.repository);
        const packRoot = path.join(ws.packs, plan.pack.id);
        const cap = await resolveCapability(packRoot);
        const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: LOADOUT_ROOT });
        const procedureEntryResolved = path.resolve(packRoot, cap.skill.procedureEntry);
        void procedureEntryResolved; // referenced for clarity; the registry resolves it independently
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
            console.error(`loadout run: ${e.message}`);
          } else {
            console.error(
              `loadout run: plan procedure binding check failed: ${(e as Error).message}`
            );
          }
          process.exit(1);
        }

        // The Plan's embedded Work Envelope is submitted verbatim. We do
        // NOT re-resolve the Capability, re-load the QMR, or recompile.
        const envelope = plan.work_envelope;
        // Step: invoke the procedure via the registry. This is the
        // SOLE path that calls the Skill procedure; it is not a
        // hardcoded import. The Plan's procedure_binding tells us which
        // procedure entry to invoke; the registry resolves it to the
        // actual function.
        let recon: { notes: string[]; [k: string]: unknown };
        try {
          recon = (await invokeProcedure({
            procedureEntry: cap.skill.procedureEntry,
            packRoot,
            loadoutRoot: LOADOUT_ROOT,
            repoRoot: opts.repository
          })) as { notes: string[] };
        } catch (e) {
          if (e instanceof ProcedureResolutionError) {
            console.error(`loadout run: ${e.message}`);
          } else {
            console.error(`loadout run: procedure invocation failed: ${(e as Error).message}`);
          }
          process.exit(1);
        }
        // Step: invoke the SIMULATED Kiln boundary with the Plan's envelope.
        const result = invokeFakeKiln(envelope);
        const view = buildResultView(result);
        console.log(
          `=== Loaded plan: ${plan.plan_id} (work_envelope_digest=${plan.work_envelope_digest}) ===`
        );
        console.log(
          `=== Plan is FRESH: project_state matches current snapshot (${currentProjectState.baseCommit}) ===`
        );
        console.log(
          `=== Procedure binding verified: qmr_procedure_ref=${plan.procedure_binding.qmr_procedure_ref} ===`
        );
        console.log('');
        console.log(formatResultViewText(view));
        console.log('');
        console.log('Local procedure notes (input to the fake Kiln boundary, not a Kiln record):');
        for (const n of recon.notes) console.log(`  ${n}`);

        // Persist run record (same shape as ad-hoc run path).
        const wsPaths = await ensureWorkspace(opts.repository);
        const recordPath = path.join(wsPaths.runs, `${result.run_id}.json`);
        await fs.writeFile(
          recordPath,
          JSON.stringify(
            {
              sourcePlan: { plan_id: plan.plan_id, plan_path: opts.plan },
              workEnvelope: envelope,
              runResult: result,
              view,
              recon
            },
            null,
            2
          )
        );
        console.log(`run record written: ${recordPath}`);
        if (opts.out) {
          await fs.writeFile(
            opts.out,
            JSON.stringify(
              { plan_id: plan.plan_id, envelope, result, view, sourcePlanPath: opts.plan },
              null,
              2
            )
          );
          console.log(`run summary written: ${opts.out}`);
        }
        return;
      }

      // ----- AD-HOC path: --goal, resolve and run normally. -----
      const goalTitle = opts.goal as string;
      const goal = findGoalByTitle(goalTitle);
      if (!goal) {
        console.error(`unknown goal: ${goalTitle}`);
        console.error(`known goals: ${GOAL_CATALOGUE.map((g) => g.title).join(', ')}`);
        process.exit(2);
      }
      const packId = opts.pack || 'repository-recon';
      const ws = workspacePaths(opts.repository);
      const packRoot = path.join(ws.packs, packId);
      try {
        await fs.stat(packRoot);
      } catch {
        console.error(
          `pack ${packId} not installed at ${opts.repository}; run 'loadout install ${packId}' first.`
        );
        process.exit(2);
      }

      const cap = await resolveCapability(packRoot);
      if (opts.qmrFixture) {
        // Power-user skill swap: re-bind the skill descriptor in-memory only.
        cap.skill.qmrFixturePath = opts.qmrFixture;
      }

      // Step 1: load and validate the QMR the Capability is supposed to
      // back. Missing, malformed, or incompatible QMR fails closed.
      let qmr;
      try {
        qmr = await loadAndValidateQmr({ capability: cap, repoRoot: LOADOUT_ROOT });
      } catch (e) {
        console.error(`loadout run: ${(e as Error).message}`);
        process.exit(1);
      }

      // Step 2: run the deterministic local procedure (read-only) via
      // the registry keyed by the Skill's procedureEntry. This is the
      // same invocation path that `run --plan` uses; the only
      // difference is whether the binding came from a Plan or from a
      // live capability resolution.
      let recon: { notes: string[]; [k: string]: unknown };
      try {
        recon = (await invokeProcedure({
          procedureEntry: cap.skill.procedureEntry,
          packRoot,
          loadoutRoot: LOADOUT_ROOT,
          repoRoot: opts.repository
        })) as { notes: string[] };
      } catch (e) {
        if (e instanceof ProcedureResolutionError) {
          console.error(`loadout run: ${e.message}`);
        } else {
          console.error(`loadout run: procedure invocation failed: ${(e as Error).message}`);
        }
        process.exit(1);
      }
      // Step 3: snapshot the workspace.
      const snap = await snapshotRepo(opts.repository);
      // Step 4: compile the Work Envelope. method_provenance derives from
      // the loaded QMR, not from the Capability's contract metadata.
      const envelope = compileWorkEnvelope({
        goal,
        capability: cap,
        qmr,
        projectState: {
          repository: opts.repository,
          baseCommit: snap.input.headCommit,
          workspaceStateDigest: snap.digest
        },
        createdAt: new Date().toISOString()
      });
      // Step 5: invoke the SIMULATED Kiln boundary. Defaults to deny-all
      // authority and unsatisfy-all proof obligations.
      const result = invokeFakeKiln(envelope);
      // Step 6: build the Result view.
      const view = buildResultView(result);
      // Step 7: print.
      console.log(formatResultViewText(view));
      console.log('');
      console.log('Local procedure notes (input to the fake Kiln boundary, not a Kiln record):');
      for (const n of recon.notes) console.log(`  ${n}`);

      // Step 8: persist the run record.
      const wsPaths = await ensureWorkspace(opts.repository);
      const recordPath = path.join(wsPaths.runs, `${result.run_id}.json`);
      await fs.writeFile(
        recordPath,
        JSON.stringify({ workEnvelope: envelope, runResult: result, view, recon }, null, 2)
      );
      console.log(`run record written: ${recordPath}`);
      if (opts.out) {
        await fs.writeFile(opts.out, JSON.stringify({ envelope, result, view }, null, 2));
        console.log(`run summary written: ${opts.out}`);
      }
    }
  );

program
  .command('plan')
  .description(
    'Produce a Loadout Plan v0 (EXPLAIN). The plan is a real, content-addressable ' +
      'artifact that records exactly what execution will ask Kiln for, including ' +
      'the compiled Work Envelope, the QMR provenance, and the compatibility proof. ' +
      'Pass it to `loadout run --plan <path>` to execute without recomputation.'
  )
  .requiredOption('-g, --goal <title>', 'Goal title (e.g., "Understand this repository")')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .option('-p, --pack <packId>', 'pack id to use', 'repository-recon')
  .option('--qmr-fixture <path>', 'override the QMR fixture path (power user)', '')
  .option(
    '-o, --out <path>',
    'explicit plan output path; default is .loadout/plans/<plan_id>.json',
    ''
  )
  .action(
    async (opts: {
      goal: string;
      repository: string;
      pack: string;
      qmrFixture: string;
      out: string;
    }) => {
      const goal = findGoalByTitle(opts.goal);
      if (!goal) {
        console.error(`unknown goal: ${opts.goal}`);
        console.error(`known goals: ${GOAL_CATALOGUE.map((g) => g.title).join(', ')}`);
        process.exit(2);
      }
      const ws = workspacePaths(opts.repository);
      const packRoot = path.join(ws.packs, opts.pack);
      try {
        await fs.stat(packRoot);
      } catch {
        console.error(
          `pack ${opts.pack} not installed at ${opts.repository}; run 'loadout install ${opts.pack}' first.`
        );
        process.exit(2);
      }

      const cap = await resolveCapability(packRoot);
      if (opts.qmrFixture) {
        // Power-user skill swap: re-bind the skill descriptor in-memory only.
        cap.skill.qmrFixturePath = opts.qmrFixture;
      }

      // Step 1: load and validate the QMR. Missing, malformed, or
      // incompatible QMR fails closed BEFORE we produce a plan.
      let qmr;
      try {
        qmr = await loadAndValidateQmr({ capability: cap, repoRoot: LOADOUT_ROOT });
      } catch (e) {
        console.error(`loadout plan: ${(e as Error).message}`);
        process.exit(1);
      }

      // Step 2: snapshot the workspace so the Plan's project_state is
      // bound to observable repository state at plan time.
      const snap = await snapshotRepo(opts.repository);

      // Step 3: read the pack manifest so the plan records the
      // pack-level id/version (the binding between capability and
      // distribution).
      const packManifest = await readPackManifest(packRoot);

      // Step 4: compile the Work Envelope.
      const envelope = compileWorkEnvelope({
        goal,
        capability: cap,
        qmr,
        projectState: {
          repository: opts.repository,
          baseCommit: snap.input.headCommit,
          workspaceStateDigest: snap.digest
        },
        createdAt: new Date().toISOString()
      });

      // Step 5: build the Plan. Pass packRoot so the procedure
      // binding (QMR procedure_ref + Skill procedureEntry + procedure
      // module interface digest) is computed and recorded in the Plan.
      const plan = await compileLoadoutPlan({
        goal,
        capability: cap,
        pack: packManifest,
        qmr,
        workEnvelope: envelope,
        projectState: {
          repository: opts.repository,
          baseCommit: snap.input.headCommit,
          workspaceStateDigest: snap.digest
        },
        createdAt: envelope.created_at,
        packRoot
      });

      // Step 6: print the plan to the terminal.
      console.log(formatPlanText(plan));

      // Step 7: persist the plan to the workspace.
      await ensureWorkspace(opts.repository);
      const outPath = opts.out ? path.resolve(opts.out) : defaultPlanPath(opts.repository, plan);
      await writePlan({ plan, outPath });
      console.log('');
      console.log(`plan written: ${outPath}`);
      console.log(`plan_id:    ${plan.plan_id}`);
      console.log(`work_envelope_digest: ${plan.work_envelope_digest}`);
      console.log('');
      console.log(
        `Next: 'loadout run --plan ${outPath}' to execute this exact plan without recomputation.`
      );
    }
  );

program
  .command('remove <packId>')
  .description('Remove a pack from the target repository workspace.')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .action(async (packId: string, opts: { repository: string }) => {
    await removePack(opts.repository, packId);
    console.log(`removed ${packId} from ${opts.repository}`);
  });

program
  .command('rollback <packId>')
  .description('Roll back to the pre-install snapshot for a pack.')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .action(async (packId: string, opts: { repository: string }) => {
    await rollbackPack(opts.repository, packId);
    console.log(`rolled back ${packId} in ${opts.repository}`);
  });

program
  .command('swap <packId>')
  .description(
    'Swap the QMR fixture for an installed pack (power user; capability contract unchanged).'
  )
  .requiredOption('--skill <path>', 'new QMR fixture path (relative to repository or absolute)')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .action(async (packId: string, opts: { skill: string; repository: string }) => {
    const ws = workspacePaths(opts.repository);
    const skillJsonPath = path.join(ws.packs, packId, 'skill.json');
    const skill = await loadSkillDescriptor(skillJsonPath);
    skill.qmrFixturePath = opts.skill;
    await fs.writeFile(skillJsonPath, JSON.stringify(skill, null, 2));
    console.log(`swapped QMR fixture for ${packId} to ${opts.skill}`);
    console.log('Capability contract unchanged.');
  });

program
  .command('web')
  .description('Start the minimal local web surface for the basic-user path.')
  .option('-p, --port <n>', 'port', '4173')
  .action(async (opts: { port: string }) => {
    const port = parseInt(opts.port, 10);
    if (Number.isNaN(port)) {
      console.error('invalid port');
      process.exit(2);
    }
    const { startWeb } = await import('./web');
    await startWeb({ port, defaultRepository: DEFAULT_REPO, packsDir: PACKS_DIR });
  });

program
  .command('validate-contracts')
  .description('Parse every v0 fixture and validate the goal-compile pipeline against them.')
  .action(async () => {
    const fixturesDir = path.resolve(__dirname, '..', 'fixtures');
    await validateAllFixtures(fixturesDir);
    await compileAgainstGoalCatalog({
      fixturesDir,
      packsDir: PACKS_DIR,
      repoRoot: DEFAULT_REPO
    });
    console.log(
      'contracts: OK (all v0 fixtures parsed; goal compile produced a valid Work Envelope)'
    );
  });

program.parseAsync(process.argv).catch((err) => {
  console.error(`loadout error: ${(err as Error).message}`);
  process.exit(1);
});
