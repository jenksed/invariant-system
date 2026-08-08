# Execution Substrate Contract & Reality Budget

Status: ARS-05 v0

Project Arsenal should not spend more reality, authority, cost, or blast radius than a claim requires.

> **Spend only as much reality and authority as the evidence requires.**

ARS-05 turns that principle into a deterministic selection contract.

## Responsibility boundary

```text
Capability verification requirement
        +
runtime-agnostic proof requirement
        +
Capability execution/authority contract
        +
Declared environment availability
        +
Authority profile
        ↓
Reality Budget selector
        ↓
lowest sufficient substrate
or an explicit gap/escalation
```

ARS-05 selects an execution world. It does **not** execute the capability in that world.

Execution adapters such as Dagger, Floci, kind, PostgreSQL, Playwright, or later Kiln integrations must implement this contract rather than redefine it.

## Why proof requirements are separate in v0

Capability Contract v2 already defines verification requirements, evidence kinds, allowed/prohibited execution surfaces, and authority. ARS-05 v0 adds `arsenal/substrates/proof-requirements.json` as a narrow extension keyed to canonical capability verification requirement IDs.

A proof requirement describes **properties the evidence must have**, never a concrete runtime.

Example:

```json
{
  "capability_id": "capability.tdd",
  "verification_requirement_id": "red_observed",
  "required_traits": ["behavior-observation", "repeatable-test"],
  "minimum_isolation": "process",
  "minimum_reproducibility": "resettable"
}
```

It does not say `local-process`, `container`, `Dagger`, or any vendor name.

This is deliberate tracer-before-framework behavior. If the proof vocabulary proves stable across more capabilities, a later Capability Contract revision can absorb it without ARS-05 inventing broad schema churn first.

## Proof ladder

The catalog declares this ordered Reality Budget:

```text
0   deterministic function
1   repository read
2   in-process test
3   local process
4   local container
5   real local dependency
6   local emulator
7   local cluster
8   disposable remote sandbox
9   shared non-production
10  staging
11  production
```

`repository read` is an observation surface inserted between pure deterministic evaluation and runtime execution. The remaining ladder preserves the ARS-05 roadmap ordering.

A lower rank is preferred only when it can actually earn the required proof.

## Substrate contract

Each substrate in `arsenal/substrates/catalog.json` declares:

- stable substrate ID and display name;
- reality rank;
- Capability Contract execution surface;
- selection mode;
- required authority;
- isolation level;
- reproducibility level;
- proof traits it can legitimately earn;
- limitations / claims it cannot establish;
- fixture/reset behavior;
- teardown behavior;
- next escalation candidate.

### Selection mode

`automatic`
: eligible for deterministic selection when declared available and authorized.

`explicit-only`
: may be named as an escalation candidate but is never automatically selected by ARS-05 v0.

Remote disposable sandboxes, shared non-production, staging, and production are explicit-only.

## Availability is an input, not a guess

A substrate catalog entry existing does not mean the current environment has it.

ARS-05 v0 uses declared availability profiles:

- `minimal-local`;
- `container-local`;
- `dependency-local`;
- `floci-local`;
- `cluster-local`.

These profiles are environment contracts, not runtime discovery.

Future adapters may generate availability evidence dynamically. Until then, the selector must not pretend Docker, Floci, kind, a database, or any remote account exists merely because Arsenal knows what those substrates are.

## Authority

ARS-05 reuses ARS-04 authority profiles from `arsenal/graph/graph.json`.

A substrate is authorized only when the selected authority profile contains:

1. every canonical `capability.authority.required` grant; and
2. every substrate-specific authority grant.

Selection never adds authority.

Because ARS-04 v0 intentionally has no remote-cloud, secrets, or production authority profiles, remote/staging/production substrates cannot become silently authorized through ARS-05.

## Capability execution compatibility

A proof-sufficient substrate must also map to a Capability Contract execution surface that appears in the capability's `execution.allowed` set and not in `execution.prohibited`.

Example:

A real-provider semantic claim may require a remote sandbox. If the capability explicitly prohibits `remote-sandbox`, ARS-05 returns an escalation instead of treating the stronger substrate as legal for that capability.

The correct next step may be a separately authorized specialized capability—not a silent widening of the existing contract.

## Selection algorithm

For one capability verification requirement:

1. resolve the canonical capability;
2. resolve the canonical verification requirement;
3. resolve its ARS-05 proof requirement;
4. optionally add stricter caller-required proof traits;
5. find catalog substrates whose declared traits, isolation, and reproducibility satisfy the proof;
6. reject substrates outside the capability's execution contract;
7. restrict automatic candidates to the declared availability profile;
8. enforce capability + substrate authority against the chosen ARS-04 authority profile;
9. select the lowest reality rank that survives;
10. otherwise return a typed gap or escalation with the best next candidate and reason.

The selector may become stricter at call time. It may never remove a canonical proof requirement.

## Verdicts

`SELECTED` — lowest sufficient automatic substrate is available and authorized.

`AUTHORITY_GAP` — an otherwise sufficient automatic substrate is available but required authority is missing.

`SUBSTRATE_GAP` — a sufficient automatic substrate exists but is not declared available in the selected environment profile.

`ESCALATION_REQUIRED` — satisfying the proof requires an explicit-only or capability-prohibited stronger surface.

`EVIDENCE_GAP` — no known substrate can establish the required proof traits.

`UNKNOWN` — canonical metadata cannot be interpreted safely.

Every non-selected verdict is a hard stop for execution under the current Reality Budget.

## Evidence scope

A selected substrate earns only the proof traits declared by that substrate and required by the claim.

The report includes:

- required traits;
- selected substrate;
- reality rank;
- authority used;
- availability profile;
- earned traits;
- substrate limitations;
- next declared escalation candidate.

A local emulator may earn `emulated-provider-behavior`. It does not thereby earn `real-provider-semantics`.

This is the generalized form of the Cloud Fidelity Ledger rule.

## Escalation

Escalation must be explainable.

The selector should name:

- the exact proof property not satisfied locally;
- the lowest known stronger substrate that could satisfy it;
- whether that substrate is explicit-only;
- missing authority;
- whether the capability execution contract currently permits it.

ARS-05 does not authorize or perform the escalation.

## Safety

ARS-05 must not:

- execute a selected substrate;
- discover or read secrets;
- infer remote authority from credentials merely existing;
- automatically select remote sandbox, shared non-production, staging, or production;
- silently broaden a capability's `execution.allowed` set;
- treat emulator evidence as provider evidence;
- treat a catalog substrate as currently available without an availability declaration;
- weaken a canonical proof requirement through CLI overrides.

## Floci tracer relationship

`foundations/cloud_execution_boundary.md` and `foundations/cloud_fidelity_ledger.md` remain the proven cloud-specific lineage.

ARS-05 generalizes their core rules:

- lowest blast radius first;
- unsupported fidelity is a boundary condition, not permission to fall through to a real provider;
- evidence class must remain scoped to the world that produced it;
- escalation requires a named unanswered claim and a stronger justified surface.

Floci becomes one execution-substrate adapter family, not the architecture itself.

## ARS-05 v0 acceptance

ARS-05 is complete when CI proves at least:

1. proof bindings reference real canonical capability verification requirements;
2. proof bindings are runtime-agnostic and contain no substrate IDs;
3. TDD red proof selects the lowest sufficient in-process test under `minimal-local` + `workspace-safe`;
4. removing the in-process test causes deterministic fallback to local process rather than a higher world;
5. Local Cloud provider routing selects deterministic evaluation;
6. Local Cloud boundary proof selects a local emulator under `floci-local` + `local-cloud-safe`;
7. the same cloud proof returns `SUBSTRATE_GAP` when the emulator is not declared available;
8. the same cloud proof returns `AUTHORITY_GAP` without `cloud.local` authority;
9. strengthening that claim to require `real-provider-semantics` returns `ESCALATION_REQUIRED`, never local success or automatic real-cloud selection;
10. malformed catalogs/proof bindings fail closed;
11. ARS-04, ARS-03, ARS-02, ARS-01, ARS-00B, and Arsenal Integrity regressions remain green;
12. final ARS-05 CI is read-only.
