# Reality Budget

ARS-05 selects the lowest-blast-radius execution substrate that can legitimately establish one verification claim.

It does not execute the substrate.

## Core command

```bash
python3 scripts/arsenal_substrate.py select \
  --capability capability.tdd \
  --requirement red_observed \
  --authority-profile workspace-safe \
  --availability-profile minimal-local
```

Expected v0 result:

```text
Reality Budget: SELECTED
selected: substrate.in-process-test — In-Process Test
reality rank: 2
```

That means Arsenal found no evidence reason to spend a container, dependency, emulator, cluster, or remote environment on this claim.

## Inspect the contract

```bash
python3 scripts/arsenal_substrate.py validate

python3 scripts/arsenal_substrate.py explain \
  --capability capability.local-cloud-feature-delivery \
  --requirement local_boundary
```

Canonical data:

- `arsenal/substrates/CONTRACT.md`
- `arsenal/substrates/catalog.json`
- `arsenal/substrates/proof-requirements.json`

## Proof requirements are runtime-agnostic

A proof requirement names properties such as:

- `behavior-observation`
- `repeatable-test`
- `network-boundary-observation`
- `provider-behavior-observation`
- `real-provider-semantics`

It does not name Docker, Dagger, Floci, kind, or any substrate ID.

The selector resolves those proof properties against the current substrate catalog.

## Availability profiles

ARS-05 does not assume an execution world exists merely because Arsenal knows about it.

Declare the environment being considered:

- `minimal-local`
- `container-local`
- `dependency-local`
- `floci-local`
- `cluster-local`

For example, Local Cloud boundary proof succeeds only when the local emulator is declared available:

```bash
python3 scripts/arsenal_substrate.py select \
  --capability capability.local-cloud-feature-delivery \
  --requirement local_boundary \
  --authority-profile local-cloud-safe \
  --availability-profile floci-local
```

Expected selection:

`substrate.local-emulator`

Using `container-local` for the same claim returns `SUBSTRATE_GAP` because a normal container does not claim emulated-provider behavior.

## Authority remains separate from availability

A world can exist and still be unauthorized.

Running the Local Cloud boundary selection with `workspace-safe` returns `AUTHORITY_GAP` because `cloud.local` is absent.

ARS-05 reuses the safe authority profiles defined by ARS-04. It does not widen them.

## Ask for stronger proof

The caller may add proof requirements but may never remove canonical ones.

Example:

```bash
python3 scripts/arsenal_substrate.py select \
  --capability capability.local-cloud-feature-delivery \
  --requirement local_boundary \
  --authority-profile local-cloud-safe \
  --availability-profile floci-local \
  --require-trait real-provider-semantics
```

The local emulator is no longer sufficient.

ARS-05 returns `ESCALATION_REQUIRED` and names `substrate.remote-disposable` as the lowest known stronger candidate. It does not execute it, request credentials, or reinterpret emulator success as provider proof.

For the current Local Cloud capability, remote sandbox execution is also prohibited by the capability contract. The report makes that visible. A different separately authorized capability may be required.

## Machine-readable output

Add `--json` to `select`.

The report includes:

- capability and verification requirement;
- proof properties;
- authority profile;
- availability profile;
- verdict;
- selected substrate or escalation candidate;
- reality rank;
- execution surface;
- earned proof traits;
- explicit limitations;
- missing authority where relevant.

This is the surface future Kiln, CI, routing, and execution adapters should consume.

## Verdicts

- `SELECTED` — exit 0
- `AUTHORITY_GAP` — exit 4
- `SUBSTRATE_GAP` — exit 5
- `ESCALATION_REQUIRED` — exit 6
- `EVIDENCE_GAP` — exit 7
- `UNKNOWN` — exit 8

Non-selected verdicts are hard stops for the current execution plan.

## Relationship to Floci

The Floci Development Pack already proved the cloud-specific form of this rule:

> an emulator may prove local behavior without proving every real-provider semantic.

ARS-05 generalizes that into the common substrate contract. Floci is now one adapter family on the ladder rather than a special-case architecture.

## Relationship to ARS-06

ARS-06 should implement a strong reproducible execution adapter—currently planned around Dagger—against this contract.

That means ARS-06 should not decide what evidence a claim deserves. ARS-05 decides the sufficient substrate class; the adapter makes that world real and returns normal Arsenal evidence.
