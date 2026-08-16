# LOD-01 — Repository Recon Capability Vertical Slice

**Status:** Owner-approved; launch HOLD pending final simultaneous authorization  
**Repository:** `jenksed/loadout`  
**Expected starting SHA:** `cae07f9364c9a65187a7a6fa68710d72474c5dc8`  
**Branch:** `agent/lod-01-repository-recon`
**Accepted program contract SHA:** `f40d143a2cc47ede625375d16cbdc43eff060414`

## Objective

Prove Loadout is a product experience, not merely a package manager, by implementing one local, reversible Repository Recon Capability from Goal selection through a fixture Work Envelope and truthful Result presentation.

## Required

- Establish the smallest product core: Workspace, Goal, Capability, Skill, Pack, Connector configuration, Run projection, and Result view.
- Define a stable `repository-recon` Capability contract with explicit input, output, optional effects, and evidence expectations.
- Consume the Qualified Method Record fixture without importing Arsenal internals.
- Compile one Goal into a Work Envelope v0 fixture.
- Use a deterministic fake Kiln boundary for the first slice; present Run state/evidence without claiming real Kiln enforcement.
- Support local install, inspect, run, and remove/rollback for one narrow software-engineering Pack or equivalent packaging.
- Include one basic-user path and one power-user inspection path.
- Select the smallest implementation stack justified by the slice and document the decision.

## Authorized discretion

- Choose CLI-first, minimal local UI, or both when justified by fastest product proof.
- Choose internal representations freely if boundary fixtures remain stable.
- Use a fake repository fixture before a real connector.

## Prohibited

- No marketplace, billing, organization administration, or public multi-domain catalog.
- No job-search, writing, or research Pack implementation in this slice.
- No runtime authority grants, effect execution, or acceptance-readiness claims.
- No direct dependency on Arsenal or Kiln implementation repositories.
- No giant generic plugin framework before the vertical slice works.

## Acceptance

- A basic user can select “Understand this repository,” run the fixture-backed capability, inspect the result/evidence, and remove it.
- The Capability contract remains stable when the underlying method fixture is swapped.
- Generated Work Envelope passes fixture validation.
- Fake-Kiln presentation is visibly identified as simulated.
- Verification and closeout are reproducible from a clean checkout.

## Stop conditions

- HEAD differs from the expected SHA.
- The slice requires real Kiln runtime changes.
- The implementation needs a Work Envelope semantic change.
- Product scope expands beyond Repository Recon and its minimum packaging path.
