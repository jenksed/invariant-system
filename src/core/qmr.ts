/**
 * Qualified Method Record (QMR) loading and compatibility checks.
 *
 * A QMR is provenance: a record that Arsenal has evaluated a method for a
 * named context. It is NOT runtime authority and NOT a substitute for the
 * Capability contract. Loadout consumes the QMR to:
 *   - verify the referenced file exists and parses;
 *   - verify the QMR is compatible with the selected Capability;
 *   - derive meaningful method_provenance for the Work Envelope.
 *
 * Compatibility checks fail closed. An invalid, missing, or incompatible
 * QMR must NOT silently degrade to "use whatever the skill descriptor says."
 */
import { promises as fs } from 'node:fs';
import path from 'node:path';
import yaml from 'yaml';
import type { ResolvedCapability } from './capability-registry';
import type { QualifiedMethodRecordV0 } from './schemas';
import { QualifiedMethodRecordV0Schema } from './schemas';

export class QmrError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'QmrError';
  }
}

export class QmrMissingError extends QmrError {
  readonly fixturePath: string;
  constructor(fixturePath: string, cause: string) {
    super(`QMR fixture missing or unreadable at ${fixturePath}: ${cause}`);
    this.name = 'QmrMissingError';
    this.fixturePath = fixturePath;
  }
}

export class QmrMalformedError extends QmrError {
  readonly fixturePath: string;
  constructor(fixturePath: string, cause: string) {
    super(`QMR fixture at ${fixturePath} is malformed: ${cause}`);
    this.name = 'QmrMalformedError';
    this.fixturePath = fixturePath;
  }
}

export class QmrIncompatibilityError extends QmrError {
  readonly reason: string;
  constructor(reason: string) {
    super(`QMR is incompatible with the selected Capability: ${reason}`);
    this.name = 'QmrIncompatibilityError';
    this.reason = reason;
  }
}

const METHOD_STATUS_ORDER: Readonly<Record<string, number>> = {
  experimental: 1,
  qualified: 2
};

export function isMethodStatusSufficient(qmrStatus: string, minStatus: string): boolean {
  const qmrRank = METHOD_STATUS_ORDER[qmrStatus] ?? 0;
  const minRank = METHOD_STATUS_ORDER[minStatus] ?? 0;
  if (minRank === 0) {
    // Unknown min status; refuse closed.
    return false;
  }
  return qmrRank >= minRank;
}

export function checkQmrCapabilityCompatibility(
  qmr: QualifiedMethodRecordV0,
  capability: ResolvedCapability
): void {
  // 1. Status check: the QMR's status must be at least the capability's
  //    min_method_status. experimental < qualified.
  if (!isMethodStatusSufficient(qmr.status, capability.contract.compatibility.min_method_status)) {
    throw new QmrIncompatibilityError(
      `method status '${qmr.status}' is insufficient for the capability's required min_method_status '${capability.contract.compatibility.min_method_status}'`
    );
  }
  // 2. Outcome check: the QMR's qualified_for.outcome must match the
  //    capability's goal_outcome.
  if (qmr.qualified_for.outcome !== capability.contract.goal_outcome) {
    throw new QmrIncompatibilityError(
      `QMR outcome '${qmr.qualified_for.outcome}' does not match capability goal_outcome '${capability.contract.goal_outcome}'`
    );
  }
  // 3. Context check: the QMR's qualified_for.contexts must intersect with
  //    the capability's accepted_contexts.
  const accepted = capability.contract.compatibility.accepted_contexts;
  const overlap = qmr.qualified_for.contexts.some((c) => accepted.includes(c));
  if (!overlap) {
    throw new QmrIncompatibilityError(
      `QMR contexts [${qmr.qualified_for.contexts.join(', ')}] do not intersect with capability accepted_contexts [${accepted.join(', ')}]`
    );
  }
}

export interface LoadAndValidateQmrArgs {
  capability: ResolvedCapability;
  repoRoot: string;
}

/**
 * Load the QMR fixture referenced by the resolved capability, validate its
 * schema, and confirm it is compatible with the capability contract.
 *
 * Throws:
 *   - QmrMissingError if the fixture file is not readable.
 *   - QmrMalformedError if the YAML or schema validation fails.
 *   - QmrIncompatibilityError if status/outcome/context checks fail.
 */
export async function loadAndValidateQmr(
  args: LoadAndValidateQmrArgs
): Promise<QualifiedMethodRecordV0> {
  const { capability, repoRoot } = args;
  const fixturePath = capability.skill.qmrFixturePath;
  const resolvedPath = path.isAbsolute(fixturePath)
    ? fixturePath
    : path.join(repoRoot, fixturePath);

  let raw: string;
  try {
    raw = await fs.readFile(resolvedPath, 'utf8');
  } catch (e) {
    const err = e as NodeJS.ErrnoException;
    if (
      err &&
      (err.code === 'ENOENT' ||
        err.code === 'EISDIR' ||
        err.code === 'EACCES' ||
        err.code === 'ENOTDIR')
    ) {
      throw new QmrMissingError(fixturePath, err.message);
    }
    throw new QmrMalformedError(fixturePath, err.message);
  }

  let parsed: unknown;
  try {
    parsed = yaml.parse(raw);
  } catch (e) {
    throw new QmrMalformedError(fixturePath, `yaml parse failed: ${(e as Error).message}`);
  }

  let qmr: QualifiedMethodRecordV0;
  try {
    qmr = QualifiedMethodRecordV0Schema.parse(parsed);
  } catch (e) {
    throw new QmrMalformedError(fixturePath, `schema validation failed: ${(e as Error).message}`);
  }

  checkQmrCapabilityCompatibility(qmr, capability);
  return qmr;
}
