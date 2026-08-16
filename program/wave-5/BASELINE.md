# Wave 5 Capability Evolution Loop — Frozen Baseline

**Status:** FROZEN BEFORE METHOD CHANGES  
**Date:** 2026-08-13  
**Purpose:** Preserve the exact product and evaluation state from which Wave 5
measures capability evolution. Later candidate or product changes must not
rewrite these identities or results.

## Canonical product mains

| Product | Canonical `origin/main` SHA |
|---|---|
| engineering-system | `d37e4a4b15857445801adb1cf7d3deea1e601fee` |
| project-arsenal | `4dcc1b0fe5c6a198c62b4b130fc9ff7c0e1b15e6` |
| loadout | `161946be59960ff8e8a16726ca1dc585abf714ec` |
| kiln | `bd2c9bcf715c99ef4f126179c1739c3b031039fc` |
| temper | `57e78b576105dc9c4051f133d0b4697b2e35a8a0` |

The two older open ECC bundle PRs in Project Arsenal and Kiln are explicitly
excluded. They are generated development-tool configuration, have no review or
CI evidence, and are not part of the Wave 5 product baseline.

## Required baseline identities

```text
BASELINE_METHOD=repository-recon/architecture-anchor-incremental@0.1.0
BASELINE_PLAN_METHOD=repository-recon/fixture-method@0.0.0-fixture
BASELINE_LOADOUT_SHA=161946be59960ff8e8a16726ca1dc585abf714ec
BASELINE_INTERFACE_DIGEST=sha256:32bf4718256a3cb5b4a6b24ad061c0863f582b99e8b71e5dd1a640077df901dd
BASELINE_IMPLEMENTATION_DIGEST=sha256:d3ced041f66938f48d4aa86ee199f9f607184f21a75824c033174309daa5580e
BASELINE_ARSENAL_EVALUATION=sha256:5e66a6da9711a582eca3bc05f0b5ace43253b508a9569b8c7097e92a99a2442a
BASELINE_EVALUATION_ARTIFACT_DIGEST=sha256:208b6dbe871c3460bd6bab0e1496fab3d1231c44d871c83770170de2ad0e0c5f
```

`BASELINE_INTERFACE_DIGEST` is the byte SHA-256 of Loadout's
`src/packs/repository-recon/capability.json` at `BASELINE_LOADOUT_SHA`.
That file owns the stable user-facing `repository-recon` Capability contract.

`BASELINE_IMPLEMENTATION_DIGEST` is the byte SHA-256 of Loadout's
`src/packs/repository-recon/run.ts` at `BASELINE_LOADOUT_SHA`. It identifies
the replaceable implementation below that stable Capability.

The distinction between `BASELINE_METHOD` and `BASELINE_PLAN_METHOD` is an
observed pre-Wave-5 seam, not a normalization error. Arsenal evaluates its
experimental architecture-anchor method through the `loadout-runtime`
adapter, while Loadout's real Plan still records the fixture QMR identity.
Wave 5 must reconcile that provenance truthfully if a winner is adopted.

## Reproduced baseline evaluation

The productized target was rebuilt from canonical Loadout main and evaluated
from canonical Arsenal main:

```text
python3 scripts/arsenal_evaluate.py repository-recon \
  --adapter loadout-runtime \
  --loadout-root <canonical-loadout> \
  --corpus evaluation/method-cases/corpus.manifest.json \
  --out /private/tmp/wave5-baseline-evaluation.json
```

Observed result:

```text
cases_total=3
assertions_evaluated=16
assertions_supported=5
assertions_failed=11
assertions_missed=0
unsupported_claims_documented=2
unknowns_documented=6
epistemic_conclusion=experimental
qualification_gap=experimental-to-experimental
run_digest=sha256:5e66a6da9711a582eca3bc05f0b5ace43253b508a9569b8c7097e92a99a2442a
```

This exactly reproduces the Wave 3 observation. The original 5 supported and
11 failed assertions are therefore frozen as executable baseline Evidence.

## Invariants for Wave 5 comparison

- Goal remains `Understand this repository`.
- Capability remains `repository-recon`.
- Capability interface digest must remain unchanged unless a real contract
  decision blocks the work.
- False factual claims are more costly than honest unknowns.
- Baseline results remain addressable after candidate implementation.
- Arsenal research, Loadout productization, Kiln execution, and Temper
  projection remain separate product boundaries.
