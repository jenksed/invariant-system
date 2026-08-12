/**
 * QMR compatibility check unit tests: status ordering, outcome match, and
 * context intersection all reject mismatches.
 */
import { describe, it, expect } from 'vitest';
import { isMethodStatusSufficient, checkQmrCapabilityCompatibility } from '../../src/core/qmr';
import type { ResolvedCapability } from '../../src/index';
import type { QualifiedMethodRecordV0, CapabilityContractV0 } from '../../src/core/schemas';

function qmr(overrides: Partial<QualifiedMethodRecordV0> = {}): QualifiedMethodRecordV0 {
  return {
    schema: 'engineering-system/qualified-method-record/v0',
    method_id: 'test/method',
    method_version: '0.0.0',
    status: 'experimental',
    qualified_for: {
      outcome: 'understand-a-repository',
      contexts: ['local-git-repository'],
      exclusions: []
    },
    inputs: [],
    outputs: [],
    procedure_ref: 'sha256:test',
    evaluation: {
      evidence_refs: [],
      models: [],
      repositories: [],
      observed_strengths: [],
      observed_failures: [],
      confidence: 'unqualified-fixture'
    },
    provenance: { arsenal_commit: null, record_digest: 'sha256:digest' },
    ...overrides
  };
}

function contract(overrides: Partial<CapabilityContractV0> = {}): CapabilityContractV0 {
  return {
    schema: 'loadout/capability-contract/v0',
    id: 'repository-recon',
    contract_version: '0.1.0-fixture',
    goal_outcome: 'understand-a-repository',
    inputs: [],
    outputs: [],
    effects: [],
    evidence_expectations: [],
    failure_shape: [],
    compatibility: {
      min_method_status: 'experimental',
      accepted_contexts: ['local-git-repository']
    },
    ...overrides
  };
}

function cap(contractOverrides: Partial<CapabilityContractV0> = {}): ResolvedCapability {
  return {
    contract: contract(contractOverrides),
    skill: {
      id: 'test/skill',
      qmrFixturePath: 'fixtures/test.yaml',
      procedureEntry: './run.ts'
    },
    capabilityJsonPath: '/cap.json',
    skillJsonPath: '/skill.json'
  };
}

describe('isMethodStatusSufficient', () => {
  it('experimental satisfies min=experimental', () => {
    expect(isMethodStatusSufficient('experimental', 'experimental')).toBe(true);
  });
  it('qualified satisfies min=experimental', () => {
    expect(isMethodStatusSufficient('qualified', 'experimental')).toBe(true);
  });
  it('qualified satisfies min=qualified', () => {
    expect(isMethodStatusSufficient('qualified', 'qualified')).toBe(true);
  });
  it('experimental does not satisfy min=qualified', () => {
    expect(isMethodStatusSufficient('experimental', 'qualified')).toBe(false);
  });
  it('unknown min status refuses closed', () => {
    expect(isMethodStatusSufficient('qualified', 'unrecognized')).toBe(false);
  });
  it('unknown qmr status refuses closed', () => {
    expect(isMethodStatusSufficient('unrecognized', 'experimental')).toBe(false);
  });
});

describe('checkQmrCapabilityCompatibility', () => {
  it('accepts a fully compatible QMR', () => {
    expect(() => checkQmrCapabilityCompatibility(qmr(), cap())).not.toThrow();
  });

  it('rejects insufficient method status', () => {
    expect(() =>
      checkQmrCapabilityCompatibility(
        qmr({ status: 'experimental' }),
        cap({
          compatibility: {
            min_method_status: 'qualified',
            accepted_contexts: ['local-git-repository']
          }
        })
      )
    ).toThrow(/insufficient/);
  });

  it('rejects mismatched outcome', () => {
    expect(() =>
      checkQmrCapabilityCompatibility(
        qmr({
          qualified_for: {
            outcome: 'different',
            contexts: ['local-git-repository'],
            exclusions: []
          }
        }),
        cap()
      )
    ).toThrow(/outcome/);
  });

  it('rejects non-intersecting contexts', () => {
    expect(() =>
      checkQmrCapabilityCompatibility(
        qmr({
          qualified_for: {
            outcome: 'understand-a-repository',
            contexts: ['cloud-runtime'],
            exclusions: []
          }
        }),
        cap()
      )
    ).toThrow(/contexts/);
  });

  it('accepts when contexts intersect on at least one entry', () => {
    expect(() =>
      checkQmrCapabilityCompatibility(
        qmr({
          qualified_for: {
            outcome: 'understand-a-repository',
            contexts: ['cloud-runtime', 'local-git-repository'],
            exclusions: []
          }
        }),
        cap()
      )
    ).not.toThrow();
  });
});
