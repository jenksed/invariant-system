/**
 * Loadout programmatic entry.
 *
 * Re-exports the stable public surface. Internal core modules are not
 * re-exported: consumers should depend on the programmatic API or the CLI.
 */
export { GOAL_CATALOGUE, findGoalById, findGoalByTitle } from './core/goal';
export type { Goal } from './core/goal';

export { compileWorkEnvelope } from './core/compile';
export type { ProjectState } from './core/compile';

export { resolveCapability } from './core/capability-registry';
export type { ResolvedCapability } from './core/capability-registry';

export { parseCapabilityContract } from './core/capability-contract';
export type { CapabilityContract } from './core/capability-contract';

export { invokeFakeKiln } from './core/fake-kiln-boundary';
export type { FakeKilnOptions } from './core/fake-kiln-boundary';

export { buildResultView, formatResultViewText } from './core/result-view';
export type { ResultView } from './core/result-view';

export {
  ensureWorkspace,
  workspacePaths,
  workspaceExists,
  WORKSPACE_DIRNAME
} from './core/workspace';
export type { WorkspacePaths } from './core/workspace';

export { snapshotRepo, computeWorkspaceStateDigest } from './core/snapshot';

export {
  installPack,
  removePack,
  rollbackPack,
  readCatalog,
  listCatalog,
  readPackManifest,
  upsertCatalog,
  writeCatalog
} from './core/pack';
export type { PackManifest, CatalogEntry, InstallResult } from './core/pack';

export { loadQmrFixture, loadSkillDescriptor } from './core/skill';
export type { SkillDescriptor } from './core/skill';

export {
  loadAndValidateQmr,
  checkQmrCapabilityCompatibility,
  isMethodStatusSufficient
} from './core/qmr';
export type { LoadAndValidateQmrArgs } from './core/qmr';
export { QmrError, QmrMissingError, QmrMalformedError, QmrIncompatibilityError } from './core/qmr';

export type {
  WorkEnvelopeV0,
  RunResultEnvelopeV0,
  QualifiedMethodRecordV0,
  CapabilityContractV0,
  SimulatedFlag
} from './core/schemas';
