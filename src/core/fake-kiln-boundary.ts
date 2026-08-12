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
 *  - authority decisions default to DENY; callers may opt in to per-request
 *    simulated grants via `simulatedAuthorityDecisions`, but no grant
 *    is automatic
 *  - proof obligation outcomes default to UNSATISFIED; callers may opt in
 *    to per-obligation simulated satisfaction/invalidation via
 *    `simulatedProofDecisions`, but no satisfaction is automatic
 *  - acceptance_readiness.ready is always false with explicit reasons
 *
 * The Work Envelope contract says requests do not grant authority and
 * proof obligations do not claim satisfaction. The default deny/unsatisfy
 * model is the conservative reading of that contract; the optional
 * simulated decisions are an explicit override for tests/inspection only
 * and are still labeled `simulated: true`.
 */
import { randomUUID } from 'node:crypto';
import type { WorkEnvelopeV0, RunResultEnvelopeV0 } from './schemas';
import { RunResultEnvelopeV0Schema } from './schemas';

export interface SimulatedAuthorityDecision {
  /** Must match a capability name in `envelope.authority_requests`. */
  capability: string;
  decision: 'granted' | 'denied';
}

export interface SimulatedProofDecision {
  /** Must match an id in `envelope.proof_obligations`. */
  obligationId: string;
  decision: 'satisfied' | 'invalidated';
}

export interface FakeKilnOptions {
  runId?: string;
  /**
   * Per-request simulated authority decisions. Unknown capabilities are
   * ignored. If absent, every request is denied (conservative default).
   */
  simulatedAuthorityDecisions?: SimulatedAuthorityDecision[];
  /**
   * Per-obligation simulated proof decisions. Unknown obligations are
   * ignored. If absent, every declared obligation is unsatisfied.
   */
  simulatedProofDecisions?: SimulatedProofDecision[];
}

export function invokeFakeKiln(
  envelope: WorkEnvelopeV0,
  opts: FakeKilnOptions = {}
): RunResultEnvelopeV0 {
  const runId = opts.runId ?? randomUUID();
  const requestedAuthority = envelope.authority_requests.map((a) => a.capability);

  // Authority: default DENY for every requested capability. An explicit
  // simulated decision can override the default for that capability only.
  const authorityDecision = new Map<string, 'granted' | 'denied'>();
  for (const cap of requestedAuthority) authorityDecision.set(cap, 'denied');
  if (opts.simulatedAuthorityDecisions) {
    for (const d of opts.simulatedAuthorityDecisions) {
      if (authorityDecision.has(d.capability)) {
        authorityDecision.set(d.capability, d.decision);
      }
    }
  }
  const granted: string[] = [];
  const denied: string[] = [];
  for (const [cap, decision] of authorityDecision.entries()) {
    if (decision === 'granted') granted.push(cap);
    else denied.push(cap);
  }

  // Proof obligations: default UNSATISFIED. An explicit simulated decision
  // can override the default for that obligation only.
  const proofDecision = new Map<string, 'satisfied' | 'unsatisfied' | 'invalidated'>();
  for (const p of envelope.proof_obligations) proofDecision.set(p.id, 'unsatisfied');
  if (opts.simulatedProofDecisions) {
    for (const d of opts.simulatedProofDecisions) {
      if (proofDecision.has(d.obligationId)) {
        proofDecision.set(d.obligationId, d.decision);
      }
    }
  }
  const satisfied: string[] = [];
  const unsatisfied: string[] = [];
  const invalidated: string[] = [];
  for (const [id, decision] of proofDecision.entries()) {
    if (decision === 'satisfied') satisfied.push(id);
    else if (decision === 'invalidated') invalidated.push(id);
    else unsatisfied.push(id);
  }

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
      granted,
      denied
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
      satisfied,
      unsatisfied,
      invalidated
    },
    unknowns: [
      'this is simulated evidence and not a real Kiln record',
      `authority grants are simulated (default deny-all): granted=${granted.length}, denied=${denied.length}`,
      `proof obligations are simulated (default unsatisfy-all): satisfied=${satisfied.length}, unsatisfied=${unsatisfied.length}`
    ],
    recovery: null,
    acceptance_readiness: {
      ready: false,
      reasons: [
        'simulated run cannot establish real acceptance readiness',
        'no real Kiln authority was granted; authority.granted is simulated only'
      ]
    },
    simulated: {
      simulated: true,
      reason:
        'fake-kiln-boundary.ts is an in-process simulator; no real Kiln enforcement occurred. Authority decisions default to deny and proof obligations default to unsatisfied unless explicitly simulated via FakeKilnOptions.'
    }
  };

  return RunResultEnvelopeV0Schema.parse(result);
}
