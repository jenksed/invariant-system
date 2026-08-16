# ARS-01 — Epistemic Lifecycle and Repository Recon Qualification Fixture

**Status:** Owner-approved; launch HOLD pending final simultaneous authorization  
**Repository:** `jenksed/project-arsenal`  
**Expected starting SHA:** `980a58d331f4ed0679e6ae306b9d55b2ee21d179`  
**Branch:** `agent/ars-01-epistemic-lifecycle`
**Accepted program contract SHA:** `f40d143a2cc47ede625375d16cbdc43eff060414`

## Objective

Make Arsenal's R&D role operational by representing method maturity explicitly and emitting one evidence-backed Qualified Method Record for Repository Recon without moving packaging or runtime authority into Arsenal.

## Required

- Reconcile Arsenal's mission around Engineering Intelligence and an experimental-to-qualified lifecycle.
- Define the smallest compatible maturity vocabulary: Idea, Hypothesis, Experimental, Replicated/Evaluated, Qualified, and only the terminal states existing structures require.
- Map existing Arsenal states and qualified artifacts rather than creating a parallel authority system.
- Select one Repository Recon method or selector supported by existing evidence.
- Emit one record compatible with `qualified-method-record/v0`.
- Preserve negative knowledge, exclusions, provenance, and context bounds.
- Add focused tests or validation for invalid transitions/records if code changes are necessary.

## Authorized discretion

- Reuse or extend current capability/source-model structures when that avoids duplication.
- Prefer a selector over a universal winner when repository context changes the best method.
- Name internal types consistently with existing Arsenal terminology.

## Prohibited

- No Loadout installer, catalog, Pack, UI, or connector implementation.
- No Kiln Run, permission, authority, effect, evidence-ledger, or acceptance implementation.
- No broad governance platform or second state machine if existing source-model roles suffice.
- No claim that behavioral efficacy is proved beyond available evidence.
- No direct write to Loadout or Kiln.

## Acceptance

- One canonical lifecycle is documented and mechanically coherent with current Arsenal state.
- One Repository Recon record validates against the v0 fixture semantics.
- Existing Arsenal evidence suite remains green.
- Closeout identifies what evidence is real, inherited, missing, or illustrative.

## Stop conditions

- HEAD differs from the expected SHA.
- Required change conflicts with current source-model authority.
- The only path requires a cross-product contract change or governance rewrite.
- Existing evidence cannot support a Qualified record; emit an Experimental record and report the qualification gap instead.
