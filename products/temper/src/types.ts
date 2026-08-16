export type Focus =
  | 'overview'
  | 'plan'
  | 'run'
  | 'authority'
  | 'evidence'
  | 'artifacts'
  | 'raw'
  | 'help';

export interface RunResultEnvelope {
  schema: 'engineering-system/run-result-envelope/v0';
  work_id: string;
  run_id: string;
  status: 'completed' | 'blocked' | 'cancelled' | 'failed' | 'unknown';
  input_state: { base_commit: string; workspace_state_digest: string };
  final_state: { commit: string; workspace_state_digest: string };
  authority: { requested: string[]; granted: string[]; denied: string[] };
  effects: Array<Record<string, unknown>>;
  evidence: Array<{
    id: string;
    kind: string;
    state_digest: string;
    description?: string;
  }>;
  proof_obligations: {
    satisfied: string[];
    unsatisfied: string[];
    invalidated: string[];
  };
  unknowns: string[];
  recovery: unknown;
  acceptance_readiness: { ready: boolean; reasons: string[] };
  simulated?: unknown;
}

export interface LoadoutPlan {
  schema: 'loadout/plan/v0';
  plan_id: string;
  goal: { id: string; title: string; success_conditions: string[] };
  capability: { id: string; contract_version: string };
  pack: { id: string; version: string };
  skill: { id: string };
  method: {
    method_id: string;
    method_version: string;
    status: string;
    confidence: string;
  };
  project_state: {
    repository: string;
    base_commit: string;
    workspace_state_digest: string;
  };
  execution_boundary: { boundary: string; reason: string; details: string };
  [key: string]: unknown;
}

export interface LoadoutRunRecord {
  plan_id: string;
  result: RunResultEnvelope;
  executionBoundary: string;
  sourcePlanPath?: string;
  raw: Record<string, unknown>;
  [key: string]: unknown;
}

export interface SourceFact {
  value: string;
  sourcePath: string;
  command: string;
}

export interface WorkbenchModel {
  repository: string;
  repositoryName: string;
  runRecordPath?: string;
  planPath?: string;
  runRecord?: LoadoutRunRecord;
  result?: RunResultEnvelope;
  plan?: LoadoutPlan;
  currentness: 'current' | 'stale' | 'n/a';
  currentnessReason: string;
  errors: string[];
  sources: Record<string, SourceFact>;
}
