# Floci Verification Contract

Status: draft

This contract specializes Project Arsenal's three Development Pack verification tiers for Floci-backed cloud work.

The exact commands are repository-specific. The invariant is the evidence sequence.

## Preconditions

Before any tier can produce evidence:

- the provider and local endpoint are explicit;
- the Floci implementation/version is knowable;
- required services/operations have been identified;
- local credentials are synthetic or otherwise non-production;
- state semantics are explicit;
- the environment has a deterministic health/readiness check;
- tests cannot silently fall back to a public provider endpoint.

## Tier 1 — Inner loop

Target: seconds to a few minutes.

Purpose: support rapid implementation without sacrificing basic endpoint safety.

Minimum evidence:

1. local emulator is reachable;
2. endpoint guard confirms the expected local target;
3. smallest relevant fixture exists or is already known-good;
4. targeted test/command exercises the changed behavior;
5. resulting behavior/state is asserted where inexpensive.

Typical AWS shape:

```text
floci status/doctor or health probe
→ endpoint assertion
→ targeted fixture/seed if needed
→ targeted application/integration test
→ material state assertion
```

Do not run a large reset/reseed on every edit unless the behavior specifically depends on startup or clean-state semantics.

## Tier 2 — Slice gate

Target: prove one coherent implementation slice.

Required evidence:

1. identify/pin the Floci version/tag/source revision used for the gate;
2. start from clean state or a documented snapshot/fixture baseline;
3. wait for explicit readiness;
4. apply the complete slice fixture;
5. verify fixture prerequisites;
6. run all targeted tests for the slice;
7. assert externally observable cloud state/effects;
8. record exact service/operation fidelity entries and known deviations;
9. teardown/reset and verify cleanup when cleanup is part of the contract.

The slice gate fails if an emulator limitation affects an acceptance claim and the result is nevertheless reported as proven.

Instead, report the claim as blocked by fidelity and identify the smallest alternate verification surface.

## Tier 3 — Completion gate

Target: evidence strong enough to support a completion claim.

Required evidence:

1. **Provenance**
   - Floci implementation and pinned version/tag/digest/source revision;
   - provider and endpoint;
   - relevant client/IaC tool versions when they affect behavior.

2. **Clean reconstruction**
   - destroy/reset prior local state;
   - recreate from source-controlled fixture or documented snapshot;
   - wait for readiness;
   - verify prerequisite resources/state.

3. **Behavior verification**
   - run the full repository-defined relevant gate;
   - exercise the cloud-dependent path end to end;
   - inspect/assert material resulting state, events, messages, objects, logs, or data-plane behavior.

4. **Fidelity verification**
   - update the fidelity ledger for every material cloud operation/protocol used by the acceptance path;
   - cite current operation-specific Floci evidence;
   - record known unsupported/partial/stubbed semantics;
   - distinguish local evidence labels from any actual real-cloud evidence.

5. **Replayability**
   - demonstrate that the environment can be reset and reconstructed without undocumented manual actions;
   - repeat the critical path when nondeterminism or persisted/container-backed state creates meaningful risk.

6. **Receipt**
   - record commands/gates and exit results;
   - record fixture/snapshot provenance;
   - record state assertions;
   - record fidelity conclusions;
   - list remaining provider-only verification or state `none` with justification.

## Readiness rule

A running process/container is not necessarily a ready cloud fixture.

When Floci initialization hooks are used, wait for the documented initialization status to reach `ready`. If the repository uses another deterministic health gate, document why it is sufficient.

## Storage rule

Completion evidence must name the storage/reset mode.

For ephemeral CI, prefer memory-backed clean state. For persistent/hybrid/WAL development flows, completion gates should still reconstruct from controlled state or explain and verify the retained-state assumptions.

For container-backed services, include managed Docker volumes/processes in reset reasoning when they survive beyond Floci's metadata process.

## Snapshot rule

A snapshot may accelerate the gate but does not eliminate provenance requirements.

Record snapshot identity/version, Floci version compatibility, creation/regeneration source, restore result, and post-restore prerequisite checks.

## IaC rule

A local Terraform/OpenTofu/CloudFormation apply can satisfy local provisioning acceptance only for supported resources/operations and asserted results.

It does not prove:

- provider-side permissions not reproduced locally;
- quotas;
- regional availability;
- billing;
- provider-specific eventual consistency or timing;
- unsupported resource semantics.

Those remain fidelity-ledger entries and may require a scoped remote plan/apply or read-only check.

## Remote verification integration

When an acceptance claim remains outside Floci's fidelity boundary, the completion gate should not automatically fail the whole feature if the project allows staged evidence.

Instead classify it explicitly:

- `BLOCKED — provider verification required`, or
- `PENDING — authorized remote verification not yet executed`.

If the acceptance contract requires that claim before merge/release, it remains a hard gate.

## Receipt template

```text
Local cloud completion receipt
- Provider:
- Floci implementation/version:
- Endpoint:
- Storage/reset mode:
- Fixture/snapshot provenance:
- Readiness evidence:
- Verification commands/results:
- State/effect assertions:
- Fidelity ledger:
  - <service/operation>: <Protocol verified | Behavior verified | Fidelity scoped>
  - Known deviation:
  - Evidence source/date:
- Real-cloud evidence:
- Remaining provider-only verification:
- Cleanup/reset result:
```

## Completion criterion

The Floci completion gate is green only when local state is reproducible, required local behavior is actually asserted, fidelity is scoped at the operation level, and the final receipt makes it impossible to confuse emulator success with unperformed provider verification.