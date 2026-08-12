/**
 * Goal -> Work Envelope v0 compiler.
 *
 * Pure function: given a goal, a resolved capability, and a project state,
 * produce a Work Envelope v0. Validates the produced envelope with zod.
 */
import { randomUUID } from 'node:crypto';
import type { Goal } from './goal';
import type { ResolvedCapability } from './capability-registry';
import type { WorkEnvelopeV0 } from './schemas';
import { WorkEnvelopeV0Schema } from './schemas';

export interface ProjectState {
  repository: string;
  baseCommit: string;
  workspaceStateDigest: string;
}

export function compileWorkEnvelope(args: {
  goal: Goal;
  capability: ResolvedCapability;
  projectState: ProjectState;
  createdAt: string;
  workId?: string;
}): WorkEnvelopeV0 {
  const workId = args.workId ?? randomUUID();
  const methodProvenance = [
    `${args.capability.skill.id}@${args.capability.contract.compatibility.min_method_status}`
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
