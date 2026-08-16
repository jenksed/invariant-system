# LOD-01 Writer Prompt

## Role and authority

You are the sole Loadout writer for LOD-01. Use MiniMax M3 with thinking enabled. You may mutate only `jenksed/loadout` on branch `agent/lod-01-repository-recon`. You have no authority in Arsenal, Kiln, or engineering-system.

Start only after verifying:

- `main` and your branch base are exactly `cae07f9364c9a65187a7a6fa68710d72474c5dc8`;
- the checkout is clean;
- you have read `AGENTS.md`, `docs/PRODUCT-BOUNDARY.md`, `docs/PRODUCT-OBJECTS.md`, and `engineering-system/program/work-packages/LOADOUT-01.md` from the accepted contract ref declared in that work package.

Stop on any mismatch.

## Contract inputs

Read these at the accepted engineering-system contract ref:

- `decisions/0001-product-system.md`
- `contracts/qualified-method-record.v0.md`
- `contracts/work-envelope.v0.md`
- `contracts/run-result-envelope.v0.md`
- all three matching v0 fixtures
- `program/work-packages/LOADOUT-01.md`

## Objective

Implement one local, reversible, ordinary-user-legible vertical slice for **Understand this repository**. A user selects the Goal, Loadout resolves a Repository Recon Capability backed by the Qualified Method fixture, compiles a valid Work Envelope, invokes a deterministic fake Kiln boundary, and presents a truthful simulated result and evidence.

## Work sequence

1. Write `docs/architecture/LOD-01.md` before framework code. Choose the smallest stack that proves the slice, state alternatives rejected, and map Workspace, Goal, Capability, Skill, Pack, Connector configuration, Run projection, and Result view without building a generic platform.
2. Prefer a minimal local web surface for the basic-user path and a CLI or structured inspection path for power users. If environment evidence justifies CLI-first, document why and keep it usable without internal product vocabulary.
3. Implement one bundled Repository Recon Pack or equivalent with local install, inspect, run, remove, and rollback behavior.
4. Keep the stable Capability contract independent of the method fixture. Prove it remains unchanged when a second compatible fixture is substituted.
5. Compile the selected Goal to Work Envelope v0 and validate it mechanically.
6. Implement a deterministic in-process fake Kiln boundary. Label every result, authority decision, effect, and evidence item as simulated; never imply real Kiln enforcement.
7. Present success, blocked, and unknown states truthfully, including evidence and unresolved facts.
8. Add focused unit, contract, integration, and basic user-flow tests. Provide one command that runs the full local verification surface.

## Owned paths

Because this is the first implementation slice, you may create the minimum project-scoped source, test, public asset, package-manager, build, and CI files justified by the architecture note. You may update `README.md`, `AGENTS.md`, and `docs/**` only to support LOD-01.

Do not add or copy `.claude/**`, `.agents/**`, `.codex/**`, or homunculus/ECC output from stale PR #2. Declare the exact top-level paths and dependency choices before mutation.

## Prohibited

- No marketplace, billing, organization admin, remote multi-tenant service, or broad non-engineering catalog.
- No real Kiln client, effect driver, authority grant, or acceptance-readiness claim.
- No direct implementation dependency on Arsenal or Kiln.
- No giant plugin framework, universal ontology, or speculative extension system.
- No secrets or user repository contents committed as fixtures.
- No writes to another repository.

## Verification

At minimum:

```text
git diff --check
```

Define project-scoped commands for formatting, linting, type checking, tests, contract/fixture validation, production build, and the basic install/run/remove flow. Run all of them from a clean checkout. Pin dependencies with the chosen package manager and do not rely on global mutable tooling.

## Stop conditions

Stop if HEAD drifts, a shared contract must change, the slice requires real Kiln behavior, product scope expands beyond Repository Recon, a dependency requires credentials, or a basic user cannot distinguish simulated from canonical runtime truth.

## Closeout

Commit coherent checkpoints, push the branch, and open a reviewable PR without merging it. Report starting and ending SHA, chosen stack and why, changed files, commands/results, contract versions consumed/produced, screenshots or interaction evidence when applicable, assumptions, unknowns, negative knowledge, and deferred work without self-authorizing it.
