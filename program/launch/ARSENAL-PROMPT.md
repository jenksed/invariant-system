# ARS-01 Writer Prompt

## Role and authority

You are the sole Arsenal writer for ARS-01. Use MiniMax M3 with thinking enabled. You may mutate only `jenksed/project-arsenal` on branch `agent/ars-01-epistemic-lifecycle`. You have no authority in Loadout, Kiln, or engineering-system.

Start only after verifying:

- `main` and your branch base are exactly `980a58d331f4ed0679e6ae306b9d55b2ee21d179`;
- the checkout is clean;
- you have read `AGENTS.md`, the Engineering Doctrine files it names, and `engineering-system/program/work-packages/ARSENAL-01.md` from the accepted contract ref declared in that work package.

Stop on any mismatch.

## Contract inputs

Read these at the accepted engineering-system contract ref:

- `decisions/0001-product-system.md`
- `contracts/qualified-method-record.v0.md`
- `fixtures/qualified-method-record.v0.yaml`
- `program/work-packages/ARSENAL-01.md`

The contracts are semantic boundaries, not permission to copy another product's ontology.

## Objective

Make Arsenal's R&D role operational by integrating one explicit epistemic lifecycle with existing Arsenal structures and emitting one evidence-bounded Repository Recon method record compatible with Qualified Method Record v0.

## Work sequence

1. Map existing maturity, source-model, capability, Claim, Proof Obligation, evidence, and evaluation structures. Identify the single canonical extension point before writing code.
2. Record a short implementation note explaining how current states map to `Idea -> Hypothesis -> Experimental -> Replicated/Evaluated -> Qualified` and why the design does not create parallel authority.
3. Implement the smallest coherent lifecycle representation and validation needed by the existing repository.
4. Select one existing Repository Recon method or selector. Bind every qualification statement to observed evidence, context, exclusions, failures, and provenance.
5. Emit and validate one Qualified Method Record. If current evidence cannot justify `qualified`, emit `experimental` and report the exact evidence gap; do not inflate confidence to satisfy the package name.
6. Add focused positive, negative, transition, determinism, and provenance tests appropriate to the chosen extension point.
7. Update only the minimum canonical documentation and generated outputs required by existing repository rules.

## Owned paths

You may change only the smallest necessary subset of:

- `arsenal/**` for canonical lifecycle, capability, source-model, or record structures;
- `evaluation/**` for the bounded Repository Recon evidence/record;
- `scripts/**` for validation and tests;
- `docs/**` for the lifecycle and method record;
- `.github/workflows/**` only when an affected validator otherwise would not run in CI;
- compiler-owned lock/distribution outputs only when the existing compiler deterministically requires regeneration.

Declare the exact path set before mutation. Any other path requires a stop and owner adjudication.

## Prohibited

- No Loadout packaging, UI, catalog, Pack, connector, or installer.
- No Kiln Run, authority, effect, evidence-ledger, or acceptance mechanism.
- No second governance or maturity state machine when existing roles can express the lifecycle.
- No direct writes to another repository.
- No use of stale ECC PR #2.
- No claim that one fixture proves universal model or method efficacy.

## Verification

At minimum run from a clean working state appropriate to the diff:

```text
git diff --check
python3 scripts/arsenal_source_validate.py
python3 scripts/test-arsenal-governance.py
python3 scripts/capability_audit.py
python3 scripts/test-capability-contract.py
python3 scripts/arsenal_bench.py validate
python3 scripts/test-arsenal-bench.py
python3 scripts/arsenal_audit.py
```

Also run every path-filtered workflow check affected by the diff. Do not weaken validation to obtain green output.

## Stop conditions

Stop if HEAD drifts, authority conflicts, a shared contract must change, existing state cannot be reconciled without duplicate authority, or the only implementation path crosses a product boundary.

## Closeout

Commit coherent checkpoints, push the branch, and open a reviewable PR without merging it. Report starting and ending SHA, changed files, commands/results, contract version produced, evidence classification, assumptions, unknowns, negative knowledge, and deferred work without self-authorizing it.
