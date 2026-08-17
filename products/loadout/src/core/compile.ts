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
import type {
  M0ExecutionBinding,
  QualifiedMethodRecordV0,
  VerificationChangeV0,
  WorkEnvelopeV0
} from './schemas';
import { WorkEnvelopeV0Schema } from './schemas';
import { computeVerificationChangeDigest } from './verification';
import { executionBindingContextRef } from './execution-binding';

export interface ProjectState {
  repository: string;
  baseCommit: string;
  workspaceStateDigest: string;
}

export interface CompileWorkEnvelopeArgs {
  goal: Goal;
  capability: ResolvedCapability;
  qmr: QualifiedMethodRecordV0;
  projectState: ProjectState;
  createdAt: string;
  workId?: string;
  verificationChange?: VerificationChangeV0;
  /**
   * Optional M0 Execution Binding (M4 — implement). When supplied
   * alongside `capability.contract.id === 'implement-change'`, the
   * binding's canonical context_refs entry is embedded in the Work
   * Envelope. The binding's `semantic_digest` then propagates into
   * the envelope digest (P02-D015).
   */
  executionBinding?: M0ExecutionBinding;
}

export function compileWorkEnvelope(args: CompileWorkEnvelopeArgs): WorkEnvelopeV0 {
  const workId = args.workId ?? randomUUID();
  const methodProvenance = [
    `${args.qmr.method_id}@${args.qmr.method_version}`,
    `digest:${args.qmr.provenance.record_digest}`
  ];

  const verification = args.verificationChange;
  const executionBinding = args.executionBinding;
  if (args.capability.contract.id === 'verify-change' && verification === undefined) {
    throw new Error('verify-change requires a frozen verification_change projection');
  }
  if (args.capability.contract.id === 'implement-change' && executionBinding === undefined) {
    throw new Error(
      'implement-change requires a frozen Execution Binding (engineering-system/execution-binding/m0-v1).'
    );
  }

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
    scope: verification
      ? {
          included: verification.change.changed_files,
          excluded: verification.skipped_verification.map((item) => item.command_id)
        }
      : { included: ['tracked repository files'], excluded: ['mutation'] },
    constraints: verification
      ? {
          must: [
            'execute only the registered commands frozen in verification_change',
            'bind Evidence only to the obligations each command is declared to prove',
            'report READY only when every obligation is satisfied'
          ],
          must_not: [
            'execute arbitrary shell input',
            'silently reselect verification after Plan creation',
            'manufacture proof from command completion alone'
          ]
        }
      : {
          must: ['distinguish observations from inferences'],
          must_not: ['modify repository state']
        },
    context_refs: collectContextRefs(verification, executionBinding),
    proof_obligations: verification
      ? verification.proof_obligations.map(({ id, kind, requirement }) => ({
          id,
          kind,
          requirement
        }))
      : [
          {
            id: 'repo-state-observed',
            kind: 'evidence',
            requirement: 'report the exact commit inspected'
          }
        ],
    authority_requests: verification
      ? [
          { capability: 'git.read', scope: args.projectState.repository },
          ...verification.selected_verification.map((command) => ({
            capability: `verification.run:${command.command_id}`,
            scope: args.projectState.repository
          }))
        ]
      : [{ capability: 'git.read', scope: args.projectState.repository }]
  };

  // Mechanical validation: the envelope must conform to the v0 schema.
  return WorkEnvelopeV0Schema.parse(envelope);
}

function collectContextRefs(
  verification: VerificationChangeV0 | undefined,
  executionBinding: M0ExecutionBinding | undefined
): string[] {
  const refs: string[] = [];
  if (verification) {
    refs.push(`loadout/verification-change/v0:${computeVerificationChangeDigest(verification)}`);
  }
  if (executionBinding) {
    refs.push(executionBindingContextRef(executionBinding));
  }
  return refs;
}
