# Loadout Agent Instructions

## Mission

Build the product experience through which people select, install, compose, and use capabilities without needing to understand Arsenal research or Kiln internals.

## Ownership

Loadout owns:

- Workspace and Goal;
- stable Capability contracts;
- Skills and Packs as productized composition;
- Catalog, installation, pinning, updates, rollback, and compatibility;
- connector discovery and configuration;
- Run, Result, approval, and evidence presentation sourced from Kiln;
- basic-user and power-user experience.

Loadout does not own:

- Arsenal experiments, qualification truth, or research conclusions;
- runtime permission/authority, effect execution, canonical evidence, recovery, or acceptance readiness;
- human product acceptance;
- repository source truth;
- generic provider infrastructure.

## Boundary rules

1. A Capability says what the user can accomplish; a Skill says how part of it is performed.
2. Users may ignore Skills; power users may inspect, replace, compose, or pin them.
3. A package or connector may request authority but cannot grant it.
4. Loadout owns Result presentation; it must not strengthen Kiln's underlying semantic claim.
5. A normal Work Envelope is produced by Loadout and consumed by Kiln.
6. Qualified Arsenal records are provenance/input, not an online runtime dependency.
7. Effectful integrations require Kiln authority and drivers; Loadout exposes configuration and intent.
8. The first slice remains Repository Recon until its end-to-end product contract works.

## First-wave constraints

- One writing agent.
- No marketplace, billing, organization plane, or multi-domain expansion.
- No direct dependency on Arsenal or Kiln implementation repositories.
- Use fixtures for both boundaries.
- No real effect execution in the first slice.
- Stop on any required cross-product contract change.

## Closeout

Report commit SHA, files, verification, contract versions, user flow demonstrated, simulated versus real behavior, assumptions, unknowns, and excluded follow-ups.

## LOD-01 verification note

The first slice (`agent/lod-01-repository-recon`) adds a single bundled pack, a deterministic fake Kiln boundary, a CLI, and a minimal local web surface. All boundary artifacts are v0 fixtures and every Result view, evidence item, and authority decision is labeled `simulated: true`. The verification surface is `scripts/verify.sh`; see `docs/architecture/LOD-01.md`.
