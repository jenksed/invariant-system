export type Focus =
  | 'overview'
  | 'plan'
  | 'run'
  | 'authority'
  | 'evidence'
  | 'artifacts'
  | 'raw'
  | 'help'
  | 'loop';

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

// M0 artifact reference — the bounded {id, digest} pair used across all
// KILN-M0-0X artifacts (intelligence-assignment, eligibility-snapshot,
// worker-output, patch-proposal, patch-decision, patch-application-evidence,
// verification-result, review, human-decision, run-result-projection).
export interface ArtifactRef {
  id: string;
  digest: string;
}

// M0 RunResultProjection (engineering-system/run-result-projection/m0-v1).
// Complements — never rewrites — the v0 RunResultEnvelope. The projection
// is the operator-facing summary of the M0 governed loop: assignment,
// qualification, patch, verification, review, human decision, terminal
// run status.
export interface RunResultProjection {
  schema: 'engineering-system/run-result-projection/m0-v1';
  projection_id: string;
  semantic_digest: string;
  plan_ref: ArtifactRef;
  implementer_assignment_ref: ArtifactRef;
  reviewer_assignment_ref: ArtifactRef;
  patch_ref: ArtifactRef;
  patch_decision_ref: ArtifactRef;
  verification_ref: ArtifactRef;
  review_ref: ArtifactRef | null;
  human_decision_ref: ArtifactRef | null;
  run_result_ref: ArtifactRef;
  truth: {
    run_status:
      | 'completed'
      | 'blocked'
      | 'cancelled'
      | 'failed'
      | 'unknown';
    verification_status: 'PASS' | 'FAIL' | 'TIMEOUT' | 'ERROR';
    review_status: 'APPROVE' | 'REQUEST_REVISION' | 'REJECT';
    human_status: 'ACCEPT' | 'REJECT' | 'REQUEST_REVISION';
    unknown_effects: string[];
  };
  metadata?: {
    fixture_only?: boolean;
    note?: string;
  };
  [key: string]: unknown;
}

export interface M0ArtifactBundle {
  // Discovery paths for the canonical M0 projection + downstream refs.
  projectionPath?: string;
  // Resolved canonical projection (post-validation, post-`fixture_only` check).
  projection?: RunResultProjection;
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
  m0ProjectionPath?: string;
  runRecord?: LoadoutRunRecord;
  result?: RunResultEnvelope;
  plan?: LoadoutPlan;
  m0?: M0ArtifactBundle;
  currentness: 'current' | 'stale' | 'n/a';
  currentnessReason: string;
  errors: string[];
  sources: Record<string, SourceFact>;
}

// =========================================================================
// WP-09 RPC + activity envelopes (contract freeze §1, §2, §7, §9)
// =========================================================================

export type RpcScope =
  | 'orchestration:read'
  | 'orchestration:operate'
  | 'review:write'
  | 'terminal:operate';

export interface RpcRequest<P = Record<string, unknown>> {
  method: string;
  params: P;
  idempotency_key?: string;
  request_digest?: string;
}

export type RpcResponse<R = unknown> =
  | { ok: true; result: R }
  | { ok: false; error: RpcError };

export interface RpcError {
  code: string;
  reason?: string;
  scope?: RpcScope;
  method?: string;
  field?: string;
  fields?: string[];
  details?: Record<string, unknown>;
}

export interface ProjectOpenResult {
  status: 'opened';
  path: string;
  kiln_home: string;
  session_id: string | null;
  canonical_session_revision: number | null;
  orphaned: boolean | null;
  unknowns: string[];
  scope_table_version: string;
}

export interface SessionStartParams {
  objective: string;
  criteria: string[];
  actor_id: string;
  project_observation: {
    repository_root: string;
    repository_fingerprint: string;
    observed_at: string;
  };
  constraints?: string[];
  exclusions?: string[];
  idempotency_key?: string;
  request_digest?: string;
}

export interface ActivitySubscribeFrame {
  type: 'activity.subscribe';
  subscription_id: string;
  filter?: { session_id?: string };
  since_revision?: number;
}

export interface ActivitySnapshotFrame {
  type: 'activity.snapshot';
  subscription_id: string;
  since_revision: number;
  schema_version: string;
}

export interface ActivityNotificationFrame {
  type: 'activity.notification';
  subscription_id: string;
  revision: number;
  emitted_at: string;
  subject: { kind: 'session' | 'run' | 'operation'; id: string };
  event_kind: 'state_changed';
  canonical_session_revision: number;
}

export interface ActivityErrorFrame {
  type: 'activity.error';
  code: string;
  reason: string;
}

export interface ActivityPongFrame {
  type: 'pong';
}

export type ActivityFrame =
  | ActivitySubscribeFrame
  | ActivitySnapshotFrame
  | ActivityNotificationFrame
  | ActivityErrorFrame
  | ActivityPongFrame;

// Client configuration
export interface KilnClientConfig {
  baseUrl: string;
  wsUrl: string;
  readToken: string;
  operateToken: string;
}
