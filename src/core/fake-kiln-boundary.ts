/**
 * Deterministic in-process fake Kiln boundary.
 *
 * This is NOT a Kiln implementation. It is a SIMULATED boundary whose
 * every output is labeled `simulated: true` so that no basic user can
 * mistake it for canonical runtime truth.
 *
 * Boundary contract:
 *  - given a Work Envelope, return a Run Result Envelope v0
 *  - status derives deterministically from inputs (we never invent effects)
 *  - evidence items carry `kind: simulated`
 *  - authority.granted mirrors authority.requests; nothing more is granted
 *  - acceptance_readiness.ready is always false with explicit reasons
 */
import { randomUUID } from 'node:crypto';
import type { WorkEnvelopeV0, RunResultEnvelopeV0 } from './schemas';
import { RunResultEnvelopeV0Schema } from './schemas';

export interface FakeKilnOptions {
  runId?: string;
}

export function invokeFakeKiln(
  envelope: WorkEnvelopeV0,
  opts: FakeKilnOptions = {}
): RunResultEnvelopeV0 {
  const runId = opts.runId ?? randomUUID();
  const requestedAuthority = envelope.authority_requests.map((a) => a.capability);

  const result: RunResultEnvelopeV0 = {
    schema: 'engineering-system/run-result-envelope/v0',
    fixture: true,
    work_id: envelope.work_id,
    run_id: runId,
    status: 'completed',
    input_state: {
      base_commit: envelope.project_state.base_commit,
      workspace_state_digest: envelope.project_state.workspace_state_digest
    },
    final_state: {
      commit: envelope.project_state.base_commit,
      workspace_state_digest: envelope.project_state.workspace_state_digest
    },
    authority: {
      requested: requestedAuthority,
      granted: requestedAuthority,
      denied: []
    },
    effects: [],
    evidence: [
      {
        id: 'simulated-commit-observation',
        kind: 'simulated',
        state_digest: envelope.project_state.workspace_state_digest,
        description: `Simulated observation of commit ${envelope.project_state.base_commit}.`
      }
    ],
    proof_obligations: {
      satisfied: envelope.proof_obligations.map((p) => p.id),
      unsatisfied: [],
      invalidated: []
    },
    unknowns: ['this is simulated evidence and not a real Kiln record'],
    recovery: null,
    acceptance_readiness: {
      ready: false,
      reasons: ['simulated run cannot establish real acceptance readiness']
    },
    simulated: {
      simulated: true,
      reason: 'fake-kiln-boundary.ts is an in-process simulator; no real Kiln enforcement occurred.'
    }
  };

  return RunResultEnvelopeV0Schema.parse(result);
}
