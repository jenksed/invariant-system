/**
 * Contract validation helpers used by `loadout validate-contracts`.
 *
 * - Parses every fixture YAML and validates against the v0 zod schemas.
 * - Compiles a Work Envelope from the Goal catalogue + bundled packs and
 *   validates the produced envelope against the work-envelope fixture
 *   shape (without requiring it to be byte-identical to the fixture).
 * - Compiles a Loadout Plan v0 from the Goal catalogue + bundled packs
 *   and verifies its plan_id is a content-addressable sha256 digest and
 *   its execution_boundary is unmistakably SIMULATED.
 *
 * No network, no mutation. Pure functions over local files.
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';
import yaml from 'yaml';
import {
  QualifiedMethodRecordV0Schema,
  WorkEnvelopeV0Schema,
  RunResultEnvelopeV0Schema
} from './schemas';
import {
  findGoalById,
  compileWorkEnvelope,
  resolveCapability,
  snapshotRepo,
  invokeFakeKiln,
  buildResultView,
  listCatalog,
  loadAndValidateQmr,
  compileLoadoutPlan,
  readPackManifest,
  computePlanId,
  buildVerificationChange,
  runImplementChange,
  type M0ArtifactRef,
  type M0ExecutionBinding,
  type M0IntelligenceRequirement
} from '../index';

export async function validateAllFixtures(fixturesDir: string): Promise<void> {
  const entries = await fs.readdir(fixturesDir);
  const yamlFiles = entries.filter((e) => e.endsWith('.yaml') || e.endsWith('.yml'));
  if (yamlFiles.length === 0) {
    throw new Error(`no fixtures found in ${fixturesDir}`);
  }
  for (const f of yamlFiles) {
    const raw = await fs.readFile(path.join(fixturesDir, f), 'utf8');
    const obj = yaml.parse(raw);
    if (obj?.schema === 'engineering-system/qualified-method-record/v0') {
      QualifiedMethodRecordV0Schema.parse(obj);
    } else if (obj?.schema === 'engineering-system/work-envelope/v0') {
      WorkEnvelopeV0Schema.parse(obj);
    } else if (obj?.schema === 'engineering-system/run-result-envelope/v0') {
      RunResultEnvelopeV0Schema.parse(obj);
    } else {
      throw new Error(`unknown fixture schema in ${f}: ${obj?.schema}`);
    }
  }
}

export async function compileAgainstGoalCatalog(args: {
  fixturesDir: string;
  packsDir: string;
  repoRoot: string;
}): Promise<void> {
  const manifests = await listCatalog(args.packsDir);
  if (manifests.length === 0) {
    throw new Error('no bundled packs to compile against');
  }
  for (const m of manifests) {
    const goalId = capabilityIdToGoalId(m.capability.id);
    const goal = findGoalById(goalId);
    if (!goal) throw new Error(`no goal for capability ${m.capability.id}`);
    const cap = await resolveCapability(path.join(args.packsDir, m.id));
    const qmr = await loadAndValidateQmr({ capability: cap, repoRoot: args.repoRoot });
    const snap = await snapshotRepo(args.repoRoot);
    const verificationChange =
      m.capability.id === 'verify-change'
        ? await buildVerificationChange({ repository: args.repoRoot })
        : undefined;
    const executionBindingArtifacts =
      m.capability.id === 'implement-change'
        ? await buildImplementChangeArtifactsForContractValidation({
            repository: args.repoRoot
          })
        : undefined;
    const envelope = compileWorkEnvelope({
      goal,
      capability: cap,
      qmr,
      projectState: {
        repository: args.repoRoot,
        baseCommit: snap.input.headCommit,
        workspaceStateDigest: snap.digest
      },
      createdAt: '2026-08-12T00:00:00Z',
      ...(verificationChange ? { verificationChange } : {}),
      ...(executionBindingArtifacts
        ? { executionBinding: executionBindingArtifacts.executionBinding }
        : {})
    });
    const result = invokeFakeKiln(envelope);
    const view = buildResultView(result);
    if (!view.simulated) {
      throw new Error('Result view is not labeled simulated; refusing to present it as truthful.');
    }
    // The Plan must be a real artifact: compile it, confirm its
    // plan_id is a sha256 content address and its execution_boundary
    // is unmistakably SIMULATED.
    const packManifest = await readPackManifest(path.join(args.packsDir, m.id));
    const planArgs = {
      goal,
      capability: cap,
      pack: packManifest,
      qmr,
      workEnvelope: envelope,
      projectState: {
        repository: args.repoRoot,
        baseCommit: snap.input.headCommit,
        workspaceStateDigest: snap.digest
      },
      createdAt: envelope.created_at,
      packRoot: path.join(args.packsDir, m.id)
    };
    const plan = verificationChange
      ? await compileLoadoutPlan({ ...planArgs, verificationChange })
      : executionBindingArtifacts
        ? await compileLoadoutPlan({
            ...planArgs,
            implementChange: executionBindingArtifacts.implementChange
          })
        : await compileLoadoutPlan(planArgs);
    if (!plan.plan_id.startsWith('sha256:')) {
      throw new Error('Plan.plan_id is not a sha256 content address; refusing.');
    }
    if (plan.plan_id !== computePlanId(plan)) {
      throw new Error('Plan.plan_id does not match its content; refusing.');
    }
    if (plan.execution_boundary.boundary !== 'simulated') {
      throw new Error(
        `Plan.execution_boundary is '${plan.execution_boundary.boundary}', not 'simulated'; refusing.`
      );
    }
  }
}

/**
 * Build the implement-change Execution Binding artifacts for the
 * contract-validation harness. This is the only place outside of the
 * pack's own procedure that constructs these — and it does so with
 * placeholder refs because the contract validator is read-only.
 *
 * The real Profile/Eligibility/Disclosure/Patch/Contract refs come from
 * the Bench qualification pipeline (M6) at production time.
 */
async function buildImplementChangeArtifactsForContractValidation(_args: {
  repository: string;
}): Promise<{
  executionBinding: M0ExecutionBinding;
  implementChange: {
    m0PlanRef: M0ArtifactRef;
    m0ExecutionBinding: M0ExecutionBinding;
    m0IntelligenceRequirements: M0IntelligenceRequirement[];
  };
}> {
  // The placeholder refs are deterministic fixtures so the contract
  // validator produces a reproducible digest across runs.
  const placeholderPlanRef: M0ArtifactRef = {
    id: 'plan-placeholder-contract-validation',
    digest: 'sha256:0000000000000000000000000000000000000000000000000000000000000001'
  };
  const placeholderProfileRef: M0ArtifactRef = {
    id: 'profile-placeholder-contract-validation',
    digest: 'sha256:0000000000000000000000000000000000000000000000000000000000000002'
  };
  const placeholderEligibilityRef: M0ArtifactRef = {
    id: 'eligibility-placeholder-contract-validation',
    digest: 'sha256:0000000000000000000000000000000000000000000000000000000000000003'
  };
  const placeholderDisclosureRef: M0ArtifactRef = {
    id: 'disclosure-placeholder-contract-validation',
    digest: 'sha256:0000000000000000000000000000000000000000000000000000000000000004'
  };
  const placeholderPatchRef: M0ArtifactRef = {
    id: 'patch-placeholder-contract-validation',
    digest: 'sha256:0000000000000000000000000000000000000000000000000000000000000005'
  };
  const placeholderContractRef: M0ArtifactRef = {
    id: 'contract-placeholder-contract-validation',
    digest: 'sha256:0000000000000000000000000000000000000000000000000000000000000006'
  };

  const { executionBinding, intelligenceRequirements } = runImplementChange({
    planRef: placeholderPlanRef,
    profileRef: placeholderProfileRef,
    eligibilityRef: placeholderEligibilityRef,
    disclosurePolicyRef: placeholderDisclosureRef,
    patchPolicyRef: placeholderPatchRef,
    contractSetRef: placeholderContractRef,
    implementerCapabilities: ['repo.read', 'repo.write'],
    reviewerCapabilities: ['repo.read', 'diff.read']
  });

  return {
    executionBinding,
    implementChange: {
      m0PlanRef: placeholderPlanRef,
      m0ExecutionBinding: executionBinding,
      m0IntelligenceRequirements: intelligenceRequirements
    }
  };
}

/**
 * Map a Capability id to its GOAL_CATALOGUE entry. Centralised so the
 * implement-change and future capabilities keep the catalogue lookup
 * consistent without scattering ad-hoc capability-id switches.
 */
function capabilityIdToGoalId(capabilityId: string): string {
  switch (capabilityId) {
    case 'repository-recon':
      return 'understand-a-repository';
    case 'verify-change':
      return 'verify-this-change';
    case 'implement-change':
      return 'implement-a-bounded-change';
    default:
      throw new Error(`no goal mapping for capability '${capabilityId}'`);
  }
}
