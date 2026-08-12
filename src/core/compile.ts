/**
 * Goal + Capability + loaded QMR -> Work Envelope v0 compiler.
 *
 * Pure function: given a goal, a resolved capability, a project state, and
 * a QMR that has already been loaded and validated against the capability,
 * produce a Work Envelope v0. The QMR is REQUIRED because the envelope's
 * `method_provenance` must derive from the actually-loaded QMR, not from
 * the capability's contract metadata. The Work Envelope contract says
 * Arsenal is optional provenance, but if a QMR is in scope it must be
 * cited truthfully.
 *
 * Validates the produced envelope with zod.
 */
import { randomUUID } from 'node:crypto';
import type { Goal } from './goal';
import type { ResolvedCapability } from './capability-registry';
import type { QualifiedMethodRecordV0, WorkEnvelopeV0 } from './schemas';
import { WorkEnvelopeV0Schema } from './schemas';

export interface ProjectState {
  repository: string;
  baseCommit: string;
  workspaceStateDigest: string;
}

export function compileWorkEnvelope(args: {
  goal: Goal;
  capability: ResolvedCapability;
  qmr: QualifiedMethodRecordV0;
  projectState: ProjectState;
  createdAt: string;
  workId?: string;
}): WorkEnvelopeV0 {
  const workId = args.workId ?? randomUUID();
  const methodProvenance = [
    `${args.qmr.method_id}@${args.qmr.method_version}`,
    `digest:${args.qmr.provenance.record_digest}`
  ];

  const envelope: WorkEnvelopeV0 = {
    schema: 'engineering-system/work-envelope/v0',
    work_id: workId,
    created_at: args.createdAt,
    producer: {
      product: 'loadout',
      version: '0.1.0-fixture'
    },
    goal: {
      title: args.goal.title,
      success_conditions: args.goal.successConditions
    },
    capability: {
      id: args.capability.contract.id,
      contract_version: args.capability.contract.contract_version,
      method_provenance: methodProvenance
    },
    project_state: {
      repository: args.projectState.repository,
      base_commit: args.projectState.baseCommit,
      workspace_state_digest: args.projectState.workspaceStateDigest
    },
    scope: {
      included: ['tracked repository files'],
      excluded: ['mutation']
    },
    constraints: {
      must: ['distinguish observations from inferences'],
      must_not: ['modify repository state']
    },
    context_refs: [],
    proof_obligations: [
      {
        id: 'repo-state-observed',
        kind: 'evidence',
        requirement: 'report the exact commit inspected'
      }
    ],
    authority_requests: [
      {
        capability: 'git.read',
        scope: args.projectState.repository
      }
    ]
  };

  // Mechanical validation: the envelope must conform to the v0 schema.
  return WorkEnvelopeV0Schema.parse(envelope);
}
