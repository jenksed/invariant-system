#!/usr/bin/env node
/**
 * Loadout CLI.
 *
 * Subcommands for LOD-01:
 *   loadout catalog
 *   loadout install <pack-id>
 *   loadout inspect <pack-id>
 *   loadout run --goal "<title>" [--repository <path>] [--pack <pack-id>]
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
  loadSkillDescriptor
} from './index';
import { runRepositoryRecon } from './packs/repository-recon/run';
import { validateAllFixtures, compileAgainstGoalCatalog } from './core/contract-validation';

const PACKS_DIR = path.resolve(__dirname, 'packs');
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
  .description('Run the selected Goal/Capability end-to-end through the SIMULATED boundary.')
  .requiredOption('-g, --goal <title>', 'Goal title (e.g., "Understand this repository")')
  .option('-r, --repository <path>', 'target repository path', DEFAULT_REPO)
  .option('-p, --pack <packId>', 'pack id to use', 'repository-recon')
  .option('--qmr-fixture <path>', 'override the QMR fixture path (power user)', '')
  .option('-o, --out <path>', 'write the run record (JSON) here', '')
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

      // Step 1: run the deterministic local procedure (read-only).
      const recon = await runRepositoryRecon(opts.repository);
      // Step 2: snapshot the workspace.
      const snap = await snapshotRepo(opts.repository);
      // Step 3: compile the Work Envelope.
      const envelope = compileWorkEnvelope({
        goal,
        capability: cap,
        projectState: {
          repository: opts.repository,
          baseCommit: snap.input.headCommit,
          workspaceStateDigest: snap.digest
        },
        createdAt: new Date().toISOString()
      });
      // Step 4: invoke the SIMULATED Kiln boundary.
      const result = invokeFakeKiln(envelope);
      // Step 5: build the Result view.
      const view = buildResultView(result);
      // Step 6: print.
      console.log(formatResultViewText(view));
      console.log('');
      console.log('Local procedure notes (input to the fake Kiln boundary, not a Kiln record):');
      for (const n of recon.notes) console.log(`  ${n}`);

      // Step 7: persist the run record.
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
